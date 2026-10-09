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
