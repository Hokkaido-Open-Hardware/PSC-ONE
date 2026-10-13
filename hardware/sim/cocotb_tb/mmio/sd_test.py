from pathlib import Path
import os
import struct

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
CTRL_SOFT_RESET = 0x08
CTRL_WRITE = 0x10

STATUS_BUSY = 0x02
STATUS_READY = 0x04
STATUS_FIFO_EMPTY = 0x08
STATUS_ERROR = 0x20

ST_ERROR = 31


def spi_bypass_enabled(dut):
    return bool(int(dut.spi_bypass_enabled.value))


def spi_activity(dut):
    return (
        int(dut.spi_sck_edges.value),
        int(dut.u_sd_model.command_count.value),
        int(dut.u_sd_model.read_count.value),
        int(dut.u_sd_model.write_count.value),
    )


def assert_spi_unchanged(dut, before):
    assert spi_activity(dut) == before, "SPI activity during a bypass operation"
    assert int(dut.SD_CS_N.value) == 1, "SD card selected during bypass"
    assert int(dut.SD_SCK.value) == 0, "SPI clock not idle during bypass"


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
    if spi_bypass_enabled(dut):
        # READY precedes completion of the last initialization dummy byte.
        # Drain that byte before checking that READ/WRITE generates no clocks.
        for _ in range(2000):
            await RisingEdge(dut.clock)
            await ReadOnly()
            if not int(dut.u_sd.spi_busy.value):
                break
        else:
            raise AssertionError("SPI initialization did not become idle")
        await ClockCycles(dut.clock, 4)


async def recover_bypass(dut):
    await cpu_write(dut, SD_IF_CTRL, CTRL_SOFT_RESET)
    await wait_status(
        dut, STATUS_ERROR | STATUS_READY | STATUS_FIFO_EMPTY | STATUS_BUSY,
        STATUS_FIFO_EMPTY | STATUS_BUSY, "soft reset"
    )
    await initialize_card(dut)


async def expect_bypass_error(dut, before, description):
    status = await wait_status(dut, STATUS_ERROR, STATUS_ERROR, description)
    assert not (status & STATUS_READY)
    assert status & STATUS_FIFO_EMPTY
    assert int(dut.u_sd.state.value) == ST_ERROR
    assert_spi_unchanged(dut, before)


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
    before = spi_activity(dut)
    await cpu_write(dut, SD_IF_CTRL, CTRL_FIFO_FLUSH)
    await cpu_write(dut, SD_IF_SECTOR, lba)
    assert await cpu_read(dut, SD_IF_SECTOR) == lba

    await cpu_write(dut, SD_IF_CTRL, CTRL_READ)
    status = await wait_operation(dut, f"READ LBA 0x{lba:08x}")
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
    if spi_bypass_enabled(dut):
        assert_spi_unchanged(dut, before)
    else:
        assert int(dut.u_sd_model.last_cmd.value) == 0x51
        assert int(dut.u_sd_model.last_cmd_arg.value) == lba
    return data


async def write_sector(dut, lba, data):
    assert len(data) == 512
    before = spi_activity(dut)
    await cpu_write(dut, SD_IF_CTRL, CTRL_FIFO_FLUSH)
    await cpu_write(dut, SD_IF_SECTOR, lba)
    assert await cpu_read(dut, SD_IF_SECTOR) == lba

    for value in data:
        await cpu_write(dut, SD_IF_DATA, value)

    await cpu_write(dut, SD_IF_CTRL, CTRL_WRITE)
    if spi_bypass_enabled(dut):
        await expect_bypass_error(dut, before, "unsupported bypass WRITE")
    else:
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
async def sd_image_read_write_test(dut):
    bypass = spi_bypass_enabled(dut)
    # Bypass WRITE must enter ST_ERROR; read_sector still checks every read.
    await setup_dut(dut, monitor_errors=not bypass)
    await initialize_card(dut)
    with Path(os.environ.get("SDCARD_IMAGE", "sdcard/sdcard.img")).open("rb") as disk:
        def sector(lba):
            disk.seek(lba * 512)
            return disk.read(512)

        def u32(data, offset):
            return struct.unpack_from("<I", data, offset)[0]

        partition = u32(sector(0), 454)
        bpb = sector(partition)
        fat = partition + struct.unpack_from("<H", bpb, 14)[0]
        data = fat + bpb[16] * u32(bpb, 36)
        sectors = disk.seek(0, 2) // 512
        # MBR, empty gap, BPB, both FATs, root and last sector.
        lbas = {0, 1, partition - 1, partition, partition + 1,
                fat, fat + u32(bpb, 36), data, sectors - 1}
        root = sector(data)
        for offset in (0, 32):
            start = (struct.unpack_from("<H", root, offset + 20)[0] << 16 |
                     struct.unpack_from("<H", root, offset + 26)[0])
            size = u32(root, offset + 28)
            if size:
                first = data + start - 2
                lbas.update((first, first + (size - 1) // 512))
                if size > 512:
                    lbas.add(first + 1)
        for lba in sorted(lbas):
            assert_sector_equal(await read_sector(dut, lba), list(sector(lba)), lba)

        # SPI writes persist independently. Bypass writes must be rejected,
        # survive soft-reset recovery, and leave the image contents unchanged.
        written = {}
        for index in range(6):
            lba = sectors - 1 - index
            payload = [(index * 37 + byte) & 255 for byte in range(512)]
            payload[:6] = [0xE1, 0xFE, 0x51, 0x58, 0x69, 0x77]
            payload[-1] = 0xE1 if index % 2 else 0xFE
            written[lba] = list(sector(lba)) if bypass else payload
            await write_sector(dut, lba, payload)
            if bypass:
                await recover_bypass(dut)
        for lba, payload in written.items():
            assert_sector_equal(await read_sector(dut, lba), payload, lba)
            assert sector(lba) == bytes(512)
        assert bytes(await read_sector(dut, 0)) == sector(0)

    if bypass:
        assert int(dut.u_sd_model.write_count.value) == 0
        assert int(dut.u_sd_model.read_count.value) == 0
    else:
        assert int(dut.u_sd_model.write_count.value) >= 6


@cocotb.test()
async def sd_image_out_of_range_test(dut):
    await setup_dut(dut, monitor_errors=False)
    await initialize_card(dut)
    sectors = Path(os.environ.get("SDCARD_IMAGE", "sdcard/sdcard.img")).stat().st_size // 512
    # Also exercise the high bits of the full 32-bit command argument.
    for lba in (sectors, 0x89AB_CDEF):
        for command in (CTRL_READ, CTRL_WRITE):
            before = spi_activity(dut)
            reads_before = int(dut.u_sd_model.read_count.value)
            writes_before = int(dut.u_sd_model.write_count.value)
            await cpu_write(dut, SD_IF_SECTOR, lba)
            await cpu_write(dut, SD_IF_CTRL, command)
            if spi_bypass_enabled(dut):
                await expect_bypass_error(dut, before, f"invalid LBA 0x{lba:08x}")
            else:
                # SPI mode stays in WAIT_R1 on an address error; inspect R1.
                for _ in range(10000):
                    await ClockCycles(dut.clock, 100)
                    await ReadOnly()
                    if int(dut.u_sd.rx_cmd_sd_card.value) == 0x20:
                        break
                else:
                    raise AssertionError(f"No R1 address error for LBA 0x{lba:08x}")
                assert int(dut.u_sd_model.last_cmd_arg.value) == lba
            assert int(dut.u_sd_model.write_state.value) == 0
            assert int(dut.u_sd_model.read_count.value) == reads_before
            assert int(dut.u_sd_model.write_count.value) == writes_before
            await RisingEdge(dut.clock)
            await reset_dut(dut)
            await initialize_card(dut)
