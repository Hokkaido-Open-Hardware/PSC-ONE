"""Standalone cocotb v2 testbench for PSC_RV32_I2C.sv.

Requirements: cocotb 2.x, Verilator (or another cocotb-capable simulator).
Run from /mnt/data (or wherever these three files are copied):
    make -f Makefile.i2c_cocotb SIM=verilator

DUT is an I2C *slave*; this file provides an I2C master and a CPU MMIO master.
The wrapper models the open-drain SDA line without unresolved 'Z' values.
This does NOT test the full PSC-ONE AXI/cache/address decoder.
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

I2C_ADDR = 0x42
BASE = 0x1000_2000
REG_INPUT = BASE + 0x00
REG_STATUS = BASE + 0x04
REG_OUTPUT = BASE + 0x08
REG_CONTROL = BASE + 0x0C
REG_SEQ = BASE + 0x10

# 100 kHz I2C. Each half period is deliberately far longer than the
# 10 ns core clock so the RTL's two-stage synchronization settles.
HALF_NS = 5_000


async def wait_ns(ns: int = HALF_NS):
    await Timer(ns, unit="ns")


async def initialize(dut):
    dut.reset_n.value = 0
    dut.scl_master.value = 1
    dut.master_sda_low.value = 0
    dut.cpu_wvalid.value = 0
    dut.cpu_waddr.value = 0
    dut.cpu_wdata.value = 0
    dut.cpu_rvalid.value = 0
    dut.cpu_raddr.value = 0
    cocotb.start_soon(Clock(dut.clock, 10, unit="ns").start())
    for _ in range(8):
        await RisingEdge(dut.clock)
    await Timer(1, unit="ns")
    dut.reset_n.value = 1
    for _ in range(8):
        await RisingEdge(dut.clock)
    await Timer(1, unit="ns")
    assert int(dut.sda_bus.value) == 1, "SDA not released after reset"


class I2CMaster:
    def __init__(self, dut):
        self.dut = dut

    def scl(self, high: bool):
        self.dut.scl_master.value = int(high)

    def sda(self, drive_low: bool):
        # 1 actively pulls low; 0 releases. Never actively drive high.
        self.dut.master_sda_low.value = int(drive_low)

    async def start(self):
        # Repeated START is also legal here (previous operation ends SCL low).
        self.sda(False)
        self.scl(False)
        await wait_ns()
        self.scl(True)
        await wait_ns()
        assert int(self.dut.sda_bus.value) == 1, "SDA stuck low before START"
        self.sda(True)
        await wait_ns()
        self.scl(False)
        await wait_ns()

    async def stop(self):
        # STOP: SDA low -> high while SCL is high.
        self.scl(False)
        self.sda(True)
        await wait_ns()
        self.scl(True)
        await wait_ns()
        self.sda(False)
        await wait_ns()
        assert int(self.dut.sda_bus.value) == 1, "SDA stuck low after STOP"

    async def write_bit(self, bit: int):
        self.scl(False)
        self.sda(bit == 0)
        await wait_ns()
        self.scl(True)
        await wait_ns()
        self.scl(False)
        await wait_ns()

    async def read_bit(self) -> int:
        self.scl(False)
        self.sda(False)  # Release SDA for slave's data or ACK.
        await wait_ns()
        self.scl(True)
        await wait_ns()
        bit = int(self.dut.sda_bus.value)
        self.scl(False)
        await wait_ns()
        return bit

    async def write_byte(self, data: int) -> bool:
        for shift in range(7, -1, -1):
            await self.write_bit((data >> shift) & 1)
        ack = await self.read_bit()
        return ack == 0

    async def read_byte(self, acknowledge: bool) -> int:
        result = 0
        for _ in range(8):
            result = (result << 1) | await self.read_bit()
        # Ninth bit is the master's ACK (0), or NACK (1).
        await self.write_bit(0 if acknowledge else 1)
        self.sda(False)
        return result

    async def write_registers(self, reg: int, data: list[int], addr=I2C_ADDR):
        await self.start()
        assert await self.write_byte((addr << 1) | 0), "SLA+W NACK"
        assert await self.write_byte(reg), "register pointer NACK"
        for index, byte in enumerate(data):
            assert await self.write_byte(byte & 0xFF), f"data[{index}] NACK"
        await self.stop()

    async def read_registers(self, reg: int, size: int, addr=I2C_ADDR) -> list[int]:
        await self.start()
        assert await self.write_byte((addr << 1) | 0), "pointer SLA+W NACK"
        assert await self.write_byte(reg), "register pointer NACK"
        await self.start()  # repeated START, preserve pointer
        assert await self.write_byte((addr << 1) | 1), "SLA+R NACK"
        values = []
        for i in range(size):
            values.append(await self.read_byte(acknowledge=(i < size - 1)))
        await self.stop()
        return values


async def mmio_write(dut, addr: int, data: int):
    # RTL accepts a rising cpu_wvalid edge and responds with wready pulse.
    dut.cpu_waddr.value = addr
    dut.cpu_wdata.value = data & 0xFFFF_FFFF
    dut.cpu_wvalid.value = 1
    await RisingEdge(dut.clock)
    await Timer(1, unit="ns")
    assert int(dut.cpu_wready.value) == 1, f"MMIO write no ACK: {addr:#x}"
    dut.cpu_wvalid.value = 0
    await RisingEdge(dut.clock)
    await Timer(1, unit="ns")


async def mmio_read(dut, addr: int) -> int:
    dut.cpu_raddr.value = addr
    dut.cpu_rvalid.value = 1
    await RisingEdge(dut.clock)
    await Timer(1, unit="ns")
    assert int(dut.cpu_rready.value) == 1, f"MMIO read no ACK: {addr:#x}"
    value = int(dut.cpu_rdata.value)
    dut.cpu_rvalid.value = 0
    await RisingEdge(dut.clock)
    await Timer(1, unit="ns")
    return value


@cocotb.test()
async def test_address_and_mmio_reset(dut):
    """Check address ACK/NACK and CPU MMIO reset values."""
    await initialize(dut)
    assert await mmio_read(dut, REG_INPUT) == 0
    assert await mmio_read(dut, REG_STATUS) == 0
    assert await mmio_read(dut, REG_OUTPUT) == 0
    assert await mmio_read(dut, REG_CONTROL) == 0
    assert await mmio_read(dut, REG_SEQ) == 0

    master = I2CMaster(dut)
    await master.start()
    assert await master.write_byte(I2C_ADDR << 1), "0x42 did not ACK"
    await master.stop()

    await master.start()
    assert not await master.write_byte(0x43 << 1), "unknown address ACKed"
    await master.stop()
    dut._log.info("PASS: slave address / unknown address / MMIO reset")


@cocotb.test()
async def test_four_inputs_irq_overrun_and_clear(dut):
    """I2C writes four INT8 values; CPU sees packed input, seq and ready."""
    await initialize(dut)
    master = I2CMaster(dut)
    await mmio_write(dut, REG_CONTROL, 1)  # enable irq
    assert await mmio_read(dut, REG_CONTROL) == 1

    # A partial input must not set the input_ready bit.
    await master.write_registers(0x00, [0x12, 0xFE, 0x80])
    assert (await mmio_read(dut, REG_STATUS) & 1) == 0
    assert (await mmio_read(dut, REG_SEQ) & 0xFF) == 0

    data = [0x11, 0xFE, 0x80, 0x7F]
    await master.write_registers(0x00, data)
    got = await mmio_read(dut, REG_INPUT)
    assert got == 0x7F80FE11, f"Packed input mismatch: {got:#010x}"
    status = await mmio_read(dut, REG_STATUS)
    assert status & 0b111 == 1, f"STATUS expected input_ready: {status:#x}"
    assert int(dut.irq_rx.value) == 1, "IRQ not asserted"
    assert (await mmio_read(dut, REG_SEQ) & 0xFF) == 1

    # Second frame before CPU clears ready -> overrun.
    await master.write_registers(0x00, [1, 2, 3, 4])
    status = await mmio_read(dut, REG_STATUS)
    assert status & 0b111 == 0b101, f"overrun not raised: {status:#x}"
    assert (await mmio_read(dut, REG_SEQ) & 0xFF) == 2

    await mmio_write(dut, REG_STATUS, 0b101)  # W1C input_ready/overrun
    assert (await mmio_read(dut, REG_STATUS) & 0b111) == 0
    assert int(dut.irq_rx.value) == 0
    dut._log.info("PASS: INT8 x4 / input_ready / sequence / overrun / IRQ / W1C")


@cocotb.test()
async def test_cpu_output_to_i2c_master(dut):
    """CPU produces INT8 result, I2C master reads it through repeated START."""
    await initialize(dut)
    master = I2CMaster(dut)
    # The CPU writes 0xA6 (-90 as signed int8).
    await mmio_write(dut, REG_OUTPUT, 0xA6)
    assert await mmio_read(dut, REG_OUTPUT) == 0xA6
    assert (await mmio_read(dut, REG_STATUS) & 0b010) == 0b010

    result = await master.read_registers(0x08, 1)
    assert result == [0xA6], f"I2C read expected 0xA6, got {result}"
    # Read-only 0x09 is the sequence counter; it starts at zero.
    seq = await master.read_registers(0x09, 1)
    assert seq == [0x00], f"I2C seq read mismatch: {seq}"

    # Read itself does not clear output_ready; CPU clears W1C.
    assert (await mmio_read(dut, REG_STATUS) & 0b010) == 0b010
    await mmio_write(dut, REG_STATUS, 0b010)
    assert (await mmio_read(dut, REG_STATUS) & 0b010) == 0
    dut._log.info("PASS: CPU output / repeated START / NACK / W1C")

# Capture is passive: emulate the resolved external 0x68 slave data/ACK on
# master_sda_low. Assert that PSC-ONE never drives this foreign transaction.
CAP_CTRL = BASE + 0x14
CAP_COUNT = BASE + 0x18
CAP_DATA = BASE + 0x1C


async def observed_byte(master, byte, nack=False):
    for bit in range(7, -1, -1):
        await master.write_bit((byte >> bit) & 1)
        assert int(master.dut.slave_sda_low.value) == 0
    await master.write_bit(int(nack))
    assert int(master.dut.slave_sda_low.value) == 0


async def capture_events(dut):
    count = await mmio_read(dut, CAP_COUNT)
    result = [await mmio_read(dut, CAP_DATA) for _ in range(count)]
    assert await mmio_read(dut, CAP_DATA) == 0
    return result


@cocotb.test()
async def test_capture_0x68_repeated_start(dut):
    await initialize(dut)
    master = I2CMaster(dut)
    assert (await mmio_read(dut, CAP_CTRL) & 0x3F) == 0
    assert await mmio_read(dut, CAP_COUNT) == 0
    assert await mmio_read(dut, CAP_DATA) == 0
    await mmio_write(dut, REG_CONTROL, 1)
    await mmio_write(dut, REG_OUTPUT, 0xA5)
    await mmio_write(dut, CAP_CTRL, 1)
    await master.start()
    await observed_byte(master, 0xD0)
    await observed_byte(master, 0x3B)
    await master.start()
    await observed_byte(master, 0xD1)
    await observed_byte(master, 0x12)
    await observed_byte(master, 0x34, nack=True)
    await master.stop()
    assert (await mmio_read(dut, CAP_CTRL) & 0x3F) == 1
    # STOP releases active state, but keeps listening for a normal START.
    await master.start()
    await observed_byte(master, 0xD0, nack=True)
    await master.stop()
    assert await capture_events(dut) == [
        0x200, 0x800 | 0xD0, 0xA00 | 0x3B, 0x400,
        0x800 | 0xD1, 0xA00 | 0x12, 0xB00 | 0x34, 0x600,
        0x200, 0x9D0, 0x600]
    assert await mmio_read(dut, REG_INPUT) == 0
    assert await mmio_read(dut, REG_SEQ) == 0
    assert await mmio_read(dut, REG_CONTROL) == 1
    assert await mmio_read(dut, REG_OUTPUT) == 0xA5
    assert await mmio_read(dut, REG_STATUS) == 2


@cocotb.test()
async def test_capture_abort_overflow_rearm_and_slave(dut):
    await initialize(dut)
    master = I2CMaster(dut)
    await mmio_write(dut, CAP_CTRL, 1)
    await mmio_write(dut, CAP_CTRL, 2)
    assert (await mmio_read(dut, CAP_CTRL) & 0x3F) == 20
    assert await capture_events(dut) == []
    await mmio_write(dut, CAP_CTRL, 1)
    await master.start()
    await observed_byte(master, 0xD0, nack=True)
    # Abort while the bus is stuck: retain only completed events.
    await master.write_bit(1)
    await mmio_write(dut, CAP_CTRL, 2)
    assert (await mmio_read(dut, CAP_CTRL) & 0x3F) == 20
    assert await capture_events(dut) == [0x200, 0x9D0]
    await master.stop()
    await mmio_write(dut, CAP_CTRL, 1)
    await master.start()
    await observed_byte(master, 0xD0)
    for byte in range(62):
        await observed_byte(master, byte)
    # Exactly 64 events: completion must not need event 65 or STOP.
    assert (await mmio_read(dut, CAP_CTRL) & 0x3F) == 12
    assert await mmio_read(dut, CAP_COUNT) == 64
    for byte in (62, 63):
        await observed_byte(master, byte)
    await master.stop()
    assert (await mmio_read(dut, CAP_CTRL) & 0x3F) == 12
    assert await capture_events(dut) == [0x200, 0x8D0] + [0xA00 | n for n in range(62)]
    # Capture also suppresses ACK at our own address.
    await mmio_write(dut, CAP_CTRL, 1)
    await master.start()
    assert not await master.write_byte(I2C_ADDR << 1)
    await master.stop()
    await mmio_write(dut, CAP_CTRL, 2)
    assert await capture_events(dut) == [0x200, 0x984, 0x600]
    # The ordinary slave resumes after capture, including register writes/ACKs.
    await master.write_registers(0, [1, 2, 3, 4])
    assert await mmio_read(dut, REG_INPUT) == 0x04030201
    assert await mmio_read(dut, REG_SEQ) == 1
    assert (await mmio_read(dut, CAP_CTRL) & 0x3F) == 20


@cocotb.test()
async def test_capture_stop_start_read14(dut):
    await initialize(dut)
    master = I2CMaster(dut)
    await mmio_write(dut, CAP_CTRL, 1)
    await master.start()
    await observed_byte(master, 0xD0)
    await observed_byte(master, 0x3B)
    await master.stop()
    assert (await mmio_read(dut, CAP_CTRL) & 0x3F) == 1
    assert await mmio_read(dut, CAP_CTRL) == (0x50000 | 0x181)  # armed, 1 STOP, no DONE
    await Timer(2, unit="ms")  # substantial STOP-to-START idle gap
    assert await mmio_read(dut, CAP_CTRL) == (0x50000 | 0x181)
    assert await mmio_read(dut, CAP_COUNT) == 4
    assert await mmio_read(dut, CAP_DATA) == 0  # no early pop
    await master.start()
    await observed_byte(master, 0xD1)
    values = [0x12, 0x34, 0x00, 0xFF, 0x80, 0x01, 0x55,
              0xAA, 0xFE, 0x7F, 0x42, 0x68, 0x9A, 0x56]
    for i, value in enumerate(values):
        await observed_byte(master, value, nack=(i == 13))
    await master.stop()
    assert (await mmio_read(dut, CAP_CTRL) & 0x3F) == 4
    assert await mmio_read(dut, CAP_CTRL) == (0x50000 | 0x2C4)  # 2 STOPs, limit, DONE
    # Later traffic cannot overwrite a completed capture.
    await master.start()
    await observed_byte(master, 0xD0, nack=True)
    await master.stop()
    expected = [0x200, 0x8D0, 0xA3B, 0x600, 0x200, 0x8D1]
    expected += [(0xB00 if i == 13 else 0xA00) | v for i, v in enumerate(values)]
    assert await capture_events(dut) == expected + [0x600]


@cocotb.test()
async def test_capture_timeout_idle_and_partial(dut):
    await initialize(dut)
    master = I2CMaster(dut)
    for partial in (False, True):
        await mmio_write(dut, CAP_CTRL, 1)
        if partial:
            await master.start()
            await observed_byte(master, 0xD1)
            await master.write_bit(1)  # stuck bus in an unfinished byte
        await Timer(11, unit="ms")
        assert (await mmio_read(dut, CAP_CTRL) & 0x3F) == 36
        assert await capture_events(dut) == ([0x200, 0x8D1] if partial else [])
        assert int(dut.slave_sda_low.value) == 0


@cocotb.test()
async def test_capture_repeated_start_then_idle(dut):
    """A combined WRITE/READ is one STOP; idle deadline preserves the read."""
    await initialize(dut)
    master = I2CMaster(dut)
    await mmio_write(dut, CAP_CTRL, 1)
    await master.start()
    await observed_byte(master, 0xD0)
    await observed_byte(master, 0x3B)
    await master.start()
    await observed_byte(master, 0xD1)
    await observed_byte(master, 0x12)
    await observed_byte(master, 0x34, nack=True)
    await master.stop()
    assert await mmio_read(dut, CAP_CTRL) == (0x50000 | 0x181)
    await Timer(11, unit="ms")
    assert await mmio_read(dut, CAP_CTRL) == (0x50000 | 0x1A4)  # timeout, not STOP limit
    assert await capture_events(dut) == [
        0x200, 0x8D0, 0xA3B, 0x400, 0x8D1, 0xA12, 0xB34, 0x600]


@cocotb.test()
async def test_capture_self_filter_and_live_slave(dut):
    await initialize(dut)
    master = I2CMaster(dut)
    assert await mmio_read(dut, CAP_CTRL) & 0x10000
    await mmio_write(dut, REG_OUTPUT, 0xA5)
    await mmio_write(dut, CAP_CTRL, 5)
    # Foreign traffic consumes neither event storage nor STOP budget.
    for _ in range(3):
        await master.start()
        await observed_byte(master, 0xD0)
        await observed_byte(master, 0x77)
        await master.stop()
    assert await mmio_read(dut, CAP_COUNT) == 0
    assert await mmio_read(dut, CAP_CTRL) == 0x70081
    await master.write_registers(0, [1, 2, 3, 4])
    assert await mmio_read(dut, REG_INPUT) == 0x04030201
    assert await mmio_read(dut, REG_SEQ) == 1
    assert await mmio_read(dut, CAP_CTRL) == 0x70181
    assert await master.read_registers(8, 1) == [0xA5]
    assert await mmio_read(dut, CAP_CTRL) == 0x702C4
    assert await capture_events(dut) == [
        0x200, 0x884, 0xA00, 0xA01, 0xA02, 0xA03, 0xA04, 0x600,
        0x200, 0x884, 0xA08, 0x400, 0x885, 0xBA5, 0x600]
    # Rearming in full-bus mode clears self mode and preserves old behavior.
    await mmio_write(dut, CAP_CTRL, 1)
    await master.start()
    assert not await master.write_byte(0x84)
    await master.stop()
    await mmio_write(dut, CAP_CTRL, 2)
    assert await capture_events(dut) == [0x200, 0x984, 0x600]


@cocotb.test()
async def test_capture_self_mixed_restarts_and_abort(dut):
    await initialize(dut)
    master = I2CMaster(dut)
    await mmio_write(dut, CAP_CTRL, 5)
    await master.start()
    await observed_byte(master, 0xD0)
    await master.start()
    assert await master.write_byte(0x84)
    assert await master.write_byte(0x08)
    await master.start()
    await observed_byte(master, 0xD0)
    await observed_byte(master, 0x77)
    await master.stop()
    assert await mmio_read(dut, CAP_CTRL) == 0x70181
    await mmio_write(dut, CAP_CTRL, 2)
    assert await capture_events(dut) == [0x400, 0x884, 0xA08, 0x600]
    # Foreign-only traffic still ends by the absolute hardware timeout.
    await mmio_write(dut, CAP_CTRL, 5)
    await master.start()
    await observed_byte(master, 0xD0)
    await master.stop()
    await Timer(11, unit="ms")
    assert await mmio_read(dut, CAP_CTRL) == 0x700A4
    assert await capture_events(dut) == []


@cocotb.test()
async def test_capture_self_overflow_keeps_slave_running(dut):
    await initialize(dut)
    master = I2CMaster(dut)
    await mmio_write(dut, CAP_CTRL, 5)
    await master.start()
    assert await master.write_byte(0x84)
    # The pointer plus 61 data bytes fill the 64-event buffer.
    assert await master.write_byte(0)
    for value in range(61):
        assert await master.write_byte(value)
    assert await mmio_read(dut, CAP_CTRL) == 0x7008C
    # Overflow must freeze only the monitor, not the responding slave.
    assert await master.write_byte(0xEE)
    await master.stop()
    assert await capture_events(dut) == [0x200, 0x884, 0xA00] + [0xA00 | n for n in range(61)]
    await master.write_registers(0, [9, 8, 7, 6])
    assert await mmio_read(dut, REG_INPUT) == 0x06070809


async def pwm_write(master, data):
    await master.start()
    assert await master.write_byte(0x84)
    for byte in data:
        assert await master.write_byte(byte)
    await master.stop()


async def pwm_read(master, size=4):
    await master.start()
    assert await master.write_byte(0x85)
    values = [await master.read_byte(i < size - 1) for i in range(size)]
    await master.stop()
    return values


@cocotb.test()
async def test_pwm_round_trip_and_register_isolation(dut):
    """Actual Arduino v1 report, raw signed PWMs, MPU traffic, frozen events."""
    await initialize(dut)
    m = I2CMaster(dut)
    await m.write_registers(0, [1, 2, 3, 4])
    await mmio_write(dut, REG_OUTPUT, 0x7f)
    before = [await mmio_read(dut, a) for a in
              (REG_INPUT, REG_STATUS, REG_OUTPUT, REG_SEQ)]
    assert await mmio_read(dut, REG_SEQ + 4) & (1 << 18)
    await mmio_write(dut, REG_SEQ + 4, 13)
    expected = []
    for raw in ([0xf5, 0xff, 0xf7, 0xff], [0, 0x80, 0xff, 0x7f]):
        # Another slave is never ACKed or driven by PSC-ONE.
        await m.start()
        assert not await m.write_byte(0xd0)
        await m.stop()
        await pwm_write(m, raw)
        expected += [0x200, 0x884] + [0xa00 | b for b in raw] + [0x600]
        response = await pwm_read(m)
        assert response == [20, 0, 20, 0]
        expected += [0x200, 0x885, 0xa14, 0xa00, 0xa14, 0xb00, 0x600]
        report = [0xa5, 1, 0x80, 4, 4] + response
        await pwm_write(m, report)
        expected += [0x200, 0x884] + [0xa00 | b for b in report] + [0x600]
    status = await mmio_read(dut, REG_SEQ + 4)
    assert status & 4 and status & 64 and not status & 0x39
    assert (status >> 8) & 255 == 6
    captured = await capture_events(dut)
    assert captured == expected
    # Optional artifact consumed by the production C decoder host test.
    import os
    from pathlib import Path
    if os.environ.get("PWM_TRACE_FILE"):
        Path(os.environ["PWM_TRACE_FILE"]).write_text(
            "\n".join(f"{event:x}" for event in captured) + "\n")
    assert [await mmio_read(dut, a) for a in
            (REG_INPUT, REG_STATUS, REG_OUTPUT, REG_SEQ)] == before
    assert await m.read_registers(8, 1) == [0x7f]
    # Frozen capture survives later legacy traffic.
    assert await mmio_read(dut, REG_SEQ + 8) == 52
    await mmio_write(dut, REG_SEQ + 4, 5)
    await m.write_registers(0, [5, 6, 7, 8])
    assert await mmio_read(dut, REG_INPUT) == 0x08070605
    await mmio_write(dut, REG_SEQ + 4, 2)


@cocotb.test()
async def test_pwm_timeout_abort_and_read_latch(dut):
    await initialize(dut)
    m = I2CMaster(dut)
    await mmio_write(dut, REG_OUTPUT, 0x37)
    await mmio_write(dut, REG_SEQ + 4, 13)
    await m.start()
    assert await m.write_byte(0x85)
    assert await m.read_byte(True) == 20
    # Aborting capture must not switch an in-flight READ to legacy registers.
    await mmio_write(dut, REG_SEQ + 4, 2)
    assert [await m.read_byte(i < 2) for i in range(3)] == [0, 20, 0]
    await m.stop()
    assert await m.read_registers(8, 1) == [0x37]
    await mmio_write(dut, REG_SEQ + 4, 13)
    assert await pwm_read(m, 6) == [20, 0, 20, 0, 0, 0]
    await Timer(11, unit="ms")
    status = await mmio_read(dut, REG_SEQ + 4)
    assert status & 0x24 == 0x24 and not status & 1
    assert await m.read_registers(8, 1) == [0x37]
