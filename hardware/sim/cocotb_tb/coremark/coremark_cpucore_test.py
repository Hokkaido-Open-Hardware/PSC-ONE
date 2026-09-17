"""Core-only CoreMark, with zero-wait memory at the CPU cache interfaces.

A request raised by RTL at edge N is sampled at the following falling edge;
response data/ready are then stable for edge N+1 (no added wait cycles).
Instruction bursts return eight words at consecutive rising edges. Instruction,
data and page-table ports share one little-endian, initially zero RAM image.
The MMIO stopwatch retains the firmware's 1 us ticks and 50 ms IRQ accounting.
"""
import json
import os
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Event, FallingEdge, RisingEdge, Timer, with_timeout
from cocotb.utils import get_sim_time
from cocotb_tb.cpu.RV32ISP_core_test import (
    initialize_dut_inputs, load_word_memory, read_word, write_word,
)


def now_ns():
    return int(get_sim_time(unit="ns"))


class Memory:
    """Shared RAM and the MMIO subset used by the unchanged CoreMark ELF."""

    def __init__(self, dut, stream):
        self.dut = dut
        self.ram = load_word_memory(os.environ["PROGRAM_FILE"])
        self.stream = stream
        self.done = Event()
        self.running = self.auto = self.irq_enable = self.pending = False
        self.reload = self.count = 0
        self.start_ns = 0
        self.windows = []
        self.timer_task = None

    def counter(self):
        if not self.running:
            return self.count
        ticks = (now_ns() - self.start_ns) // 1000
        return self.reload - (ticks % (self.reload + 1))

    async def expire(self):
        while self.running:
            await Timer((self.reload + 1) * 1000, unit="ns")
            self.pending = True
            self.dut.timer_irq_ext.value = int(self.irq_enable)
            if not self.auto:
                self.count = 0
                self.running = False

    def timer_write(self, value):
        count = self.counter()
        self.auto = bool(value & (1 << 17))
        self.irq_enable = bool(value & (1 << 18))
        if value & (1 << 20):
            self.pending = False
        if value & ((1 << 16) | (1 << 19)):
            if self.timer_task is not None:
                self.timer_task.cancel()
                self.timer_task = None
            if self.running:
                self.windows.append(now_ns() - self.start_ns)
            self.running = False
            self.count = count
        # Firmware preserves reload for IRQ acknowledgement and writes zero
        # only after stopping. No timer period is restarted by acknowledgement.
        self.reload = (value & 0xFFFF) or 1
        if value & (1 << 16):
            self.running = True
            self.pending = False
            self.start_ns = now_ns()
            self.timer_task = cocotb.start_soon(self.expire())
        self.dut.timer_irq_ext.value = int(self.irq_enable and self.pending)

    def read(self, address):
        if address == 0x10002004:
            return self.counter()
        if address == 0x10002008:
            return (99 << 11) | (int(self.pending) << 10) | (int(self.irq_enable) << 9) | (int(self.auto) << 8) | (int(self.running) << 7)
        if address in (0x10000004, 0x10000008, 0x10002000):
            return 0  # UART RX empty, TX immediately available
        assert address < 0x10000000, f"Unmodelled MMIO read: {address:#x}"
        return read_word(self.ram, address)

    def write(self, address, data, select):
        if address == 0x10000000:
            self.stream.write(chr(data & 0xFF))
            if data & 0xFF == 10:
                self.stream.flush()
        elif address == 0x10002000:
            assert select == 2, "Timer requires word writes"
            self.timer_write(data)
        elif address == 0x10001000:
            if data == 0xEE01:
                self.done.set()
        else:
            assert address < 0x10000000, f"Unmodelled MMIO write: {address:#x}"
            assert select in (0, 1, 2), f"Unsupported store width: {select}"
            write_word(self.ram, address, data, select)


async def read_port(dut, memory, prefix, burst=False):
    valid = getattr(dut, prefix + "_read_valid")
    address = getattr(dut, prefix + "_read_address")
    data = getattr(dut, prefix + "_read_data")
    ready = getattr(dut, prefix + "_read_ready")
    while True:
        await RisingEdge(valid)
        await FallingEdge(dut.clock)
        base = int(address.value)
        words = 8 if burst and int(dut.program_mem_burst_mode.value) else 1
        for index in range(words):
            data.value = memory.read(base + 4 * index)
            ready.value = 1
            await FallingEdge(dut.clock)
        ready.value = 0


async def write_port(dut, memory):
    while True:
        await RisingEdge(dut.data_mem_write_valid)
        await FallingEdge(dut.clock)
        memory.write(int(dut.mem_write_address.value),
                     int(dut.mem_write_data.value), int(dut.mem_write_sel.value))
        dut.data_mem_write_ready.value = 1
        await FallingEdge(dut.clock)
        dut.data_mem_write_ready.value = 0


async def progress(dut):
    while True:
        await Timer(100_000_000, unit="ns")
        dut._log.info("CoreMark core: %.3f target seconds", now_ns() / 1e9)


@cocotb.test()
async def coremark_cpucore(dut):
    assert int(os.environ.get("CLK_PERIOD_NS", "10")) == 10, "Firmware requires 100 MHz"
    output = Path(os.environ["PSC_UART_LOGFILE"])
    result_dir = Path(os.environ["COREMARK_RESULT_DIR"])
    (result_dir / "result.json").write_text(json.dumps({"status": "running", "uart_log": str(output)}) + "\n")
    initialize_dut_inputs(dut)
    cocotb.start_soon(Clock(dut.clock, 10, unit="ns", impl="gpi").start())
    with output.open("w") as stream:
        memory = Memory(dut, stream)
        cocotb.start_soon(read_port(dut, memory, "program_mem", burst=True))
        cocotb.start_soon(read_port(dut, memory, "data_mem"))
        cocotb.start_soon(read_port(dut, memory, "mmu_data_mem"))
        cocotb.start_soon(write_port(dut, memory))
        cocotb.start_soon(progress(dut))
        await Timer(500, unit="ns")
        await FallingEdge(dut.clock)
        dut.reset_n.value = 1
        await with_timeout(memory.done.wait(), int(os.environ["RUN_CYCLES"]) * 10, "ns")
        # Allow the final write acknowledgement to be sampled by the core.
        await Timer(10, unit="ns")
    (result_dir / "timer.json").write_text(json.dumps({"timer_windows_ns": memory.windows}) + "\n")
    text = output.read_text()
    dut._log.info("\n%s", text)
    assert "Correct operation validated." in text, "CoreMark validation failed (including minimum 10 s rule)"
    assert "ERROR!" not in text, "CoreMark reported an error"
