import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, ReadOnly, RisingEdge


CLK_NS = 10

SD_IF_DATA = 0x1000_6000
SD_IF_SECTOR = 0x1000_6004
SD_IF_CTRL = 0x1000_6008

CTRL_INIT = 0x01
CTRL_READ = 0x02
CTRL_FIFO_FLUSH = 0x04
CTRL_WRITE = 0x10

STATUS_BUSY = 0x02
STATUS_READY = 0x04
STATUS_FIFO_EMPTY = 0x08
STATUS_ERROR = 0x20

ST_ERROR = 31


async def reset_dut(dut):
    dut.reset_n.value = 0
    dut.cpu_rvalid.value = 0
    dut.cpu_raddr.value = 0
    dut.cpu_rdata.value = 0
    dut.cpu_wvalid.value = 0
    dut.cpu_waddr.value = 0
    dut.cpu_wdata.value = 0

    await ClockCycles(dut.clock, 10)
    dut.reset_n.value = 1
    await ClockCycles(dut.clock, 10)


async def setup_dut(dut, monitor_errors=True):
    cocotb.start_soon(Clock(dut.clock, CLK_NS, unit="ns").start())
    if monitor_errors:
        cocotb.start_soon(monitor_no_sd_error(dut))
    await reset_dut(dut)


async def monitor_no_sd_error(dut):
    while True:
        await RisingEdge(dut.clock)
        await ReadOnly()
        state = int(dut.u_sd.state.value)
        if state == ST_ERROR:
            raise AssertionError(
                "SD controller entered ST_ERROR at "
                f"{cocotb.utils.get_sim_time('ns')} ns"
            )


async def cpu_read(dut, address, timeout_cycles=100):
    dut.cpu_raddr.value = address
    dut.cpu_rvalid.value = 1
    await RisingEdge(dut.clock)
    dut.cpu_rvalid.value = 0

    for _ in range(timeout_cycles):
        await RisingEdge(dut.clock)
        await ReadOnly()
        if int(dut.cpu_rready.value):
            data = int(dut.cpu_rdata.value)
            await RisingEdge(dut.clock)
            return data

    raise AssertionError(f"cpu_rready timeout at address 0x{address:08x}")


async def cpu_write(dut, address, value, timeout_cycles=100):
    dut.cpu_waddr.value = address
    dut.cpu_wdata.value = value
    dut.cpu_wvalid.value = 1
    await RisingEdge(dut.clock)
    dut.cpu_wvalid.value = 0

    for _ in range(timeout_cycles):
        await RisingEdge(dut.clock)
        await ReadOnly()
        if int(dut.cpu_wready.value):
            await RisingEdge(dut.clock)
            return

    raise AssertionError(f"cpu_wready timeout at address 0x{address:08x}")


async def wait_status(dut, mask, expected, description, polls=10000):
    last_status = 0
    for _ in range(polls):
        last_status = await cpu_read(dut, SD_IF_CTRL)
        if (last_status & mask) == expected:
            return last_status
        await ClockCycles(dut.clock, 100)

    state = int(dut.u_sd.state.value)
    raise AssertionError(
        f"timeout waiting for {description}: "
        f"status=0x{last_status:08x}, state={state}"
    )


async def initialize_card(dut):
    await cpu_write(dut, SD_IF_CTRL, CTRL_FIFO_FLUSH)
    await cpu_write(dut, SD_IF_CTRL, CTRL_INIT)
    status = await wait_status(
        dut, STATUS_READY | STATUS_ERROR, STATUS_READY, "card initialization"
    )
    assert not (status & STATUS_ERROR), f"initialization error: 0x{status:08x}"


async def wait_operation(dut, description):
    # READY can remain asserted briefly while the MMIO start pulse propagates.
    await wait_status(dut, STATUS_READY, 0, f"{description} start")
    status = await wait_status(
        dut, STATUS_READY | STATUS_ERROR, STATUS_READY, description
    )
    assert not (status & STATUS_ERROR), f"{description} failed: 0x{status:08x}"
    return status


def crc16_sd(data):
    crc = 0
    for value in data:
        crc ^= value << 8
        for _ in range(8):
            if crc & 0x8000:
                crc = ((crc << 1) ^ 0x1021) & 0xFFFF
            else:
                crc = (crc << 1) & 0xFFFF
    return crc


async def read_sector(dut, lba):
    await cpu_write(dut, SD_IF_CTRL, CTRL_FIFO_FLUSH)
    await cpu_write(dut, SD_IF_SECTOR, lba)
    assert await cpu_read(dut, SD_IF_SECTOR) == lba

    await cpu_write(dut, SD_IF_CTRL, CTRL_READ)
    status = await wait_operation(dut, f"CMD17 LBA 0x{lba:08x}")
    assert not (status & STATUS_FIFO_EMPTY), "read completed with an empty FIFO"

    data = [await cpu_read(dut, SD_IF_DATA) & 0xFF for _ in range(512)]

    final_status = await cpu_read(dut, SD_IF_CTRL)
    assert final_status & STATUS_FIFO_EMPTY, "FIFO did not empty after 512 reads"
    assert not (final_status & STATUS_BUSY), "busy remained set after FIFO drain"

    received_crc = (status >> 16) & 0xFFFF
    expected_crc = crc16_sd(data)
    assert received_crc == expected_crc, (
        f"CRC mismatch for LBA 0x{lba:08x}: "
        f"got 0x{received_crc:04x}, expected 0x{expected_crc:04x}"
    )
    return data


async def write_sector(dut, lba, data):
    assert len(data) == 512
    await cpu_write(dut, SD_IF_CTRL, CTRL_FIFO_FLUSH)
    await cpu_write(dut, SD_IF_SECTOR, lba)
    assert await cpu_read(dut, SD_IF_SECTOR) == lba

    for value in data:
        await cpu_write(dut, SD_IF_DATA, value)

    await cpu_write(dut, SD_IF_CTRL, CTRL_WRITE)
    await wait_operation(dut, f"CMD24 LBA 0x{lba:08x}")


def assert_sector_equal(actual, expected, lba):
    if actual != expected:
        mismatch = next(
            index
            for index, (got, want) in enumerate(zip(actual, expected))
            if got != want
        )
        raise AssertionError(
            f"LBA 0x{lba:08x} byte {mismatch}: "
            f"got 0x{actual[mismatch]:02x}, expected 0x{expected[mismatch]:02x}"
        )


@cocotb.test()
async def sd_reset_status_test(dut):
    await setup_dut(dut)

    status = await cpu_read(dut, SD_IF_CTRL)
    assert status & STATUS_BUSY
    assert status & STATUS_FIFO_EMPTY
    assert not (status & STATUS_READY)
    assert not (status & STATUS_ERROR)


@cocotb.test()
async def sd_initialization_protocol_test(dut):
    await setup_dut(dut)
    commands_before = int(dut.u_sd_model.command_count.value)

    await initialize_card(dut)

    commands_after = int(dut.u_sd_model.command_count.value)
    assert int(dut.u_sd_model.ready.value) == 1
    assert commands_after - commands_before >= 7
    assert int(dut.u_sd_model.acmd41_count.value) == 1


@cocotb.test()
async def sd_default_sector_and_crc_test(dut):
    await setup_dut(dut)
    await initialize_card(dut)

    lba = 0x1234_5678
    expected = [index & 0xFF for index in range(512)]
    actual = await read_sector(dut, lba)
    assert_sector_equal(actual, expected, lba)

    assert int(dut.u_sd_model.last_cmd.value) == 0x51
    assert int(dut.u_sd_model.last_cmd_arg.value) == lba


@cocotb.test()
async def sd_write_readback_and_lba_isolation_test(dut):
    await setup_dut(dut)
    await initialize_card(dut)

    lba_a = 0x0000_1001
    lba_b = 0x89AB_CDEF
    data_a = [((index * 73) + 0x40) & 0xFF for index in range(512)]
    data_b = [(((index ^ (index >> 3)) * 29) + 7) & 0xFF for index in range(512)]

    # Exercise values which the previous model incorrectly treated as special
    # command/end markers when they appeared inside a write payload.
    data_a[0:6] = [0xE1, 0xFE, 0x51, 0x58, 0x69, 0x77]
    data_a[-1] = 0xE1
    data_b[0:6] = [0x40, 0x48, 0x55, 0xAA, 0x00, 0xFF]
    data_b[-1] = 0xFE

    await write_sector(dut, lba_a, data_a)
    await write_sector(dut, lba_b, data_b)

    actual_b = await read_sector(dut, lba_b)
    actual_a = await read_sector(dut, lba_a)
    assert_sector_equal(actual_b, data_b, lba_b)
    assert_sector_equal(actual_a, data_a, lba_a)

    assert int(dut.u_sd_model.write_count.value) >= 2
    assert int(dut.u_sd_model.read_count.value) >= 2
