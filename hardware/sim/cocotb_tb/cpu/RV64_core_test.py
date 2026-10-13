"""RV64 bare-core C++ tests using the existing PIO32 result protocol.

The bus uses request pulses issued after req_ready, and separate response
pulses named read_ready/write_ready. Instructions remain 32 bits; memory
responses are aligned little-endian 64-bit beats. No SoC or MMU emulation.
"""
import os
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, ReadOnly, RisingEdge, Timer, with_timeout

ADDRESS_BITS = 64
DATA_BITS = 64
MASK = (1 << DATA_BITS) - 1
NOP = 0x00000013
PIO32_ADDRESS = 0x10001000
TEST_END_CODE = 0xEE01
PIO32_MASK = 0xFFFFFFFF


def setting(name, default, minimum=1):
    value = int(os.environ.get(name, str(default)), 0)
    if value < minimum:
        raise ValueError(f"{name} must be >= {minimum}")
    return value


class Memory:
    """Shared sparse byte memory, with explicit errors for unsupported accesses."""
    def __init__(self, nop_fill=False):
        self.bytes = {}
        self.nop_fill = nop_fill

    @staticmethod
    def check_address(address, size=1):
        if not 0 <= address <= (1 << ADDRESS_BITS) - size:
            raise ValueError(f"Address outside {ADDRESS_BITS}-bit bus: {address:#x}")

    def load_program(self, filename, base=0):
        """Read 32-bit readmemh words; @ indexes are WORD offsets from base.

        Accepts whitespace, underscores, // and # comments. ELF/binary loading
        and linker handling are TODO; never silently truncate an oversized word.
        """
        self.check_address(base)
        if base % 4:
            raise ValueError("PROGRAM_BASE must be instruction aligned")
        index = 0
        for line in Path(filename).read_text(encoding="utf-8").splitlines():
            for token in line.split("//", 1)[0].split("#", 1)[0].split():
                if token.startswith("@"):
                    index = int(token[1:].replace("_", ""), 16)
                else:
                    value = int(token.replace("_", ""), 16)
                    if not 0 <= value < (1 << 32):
                        raise ValueError(f"Not a 32-bit instruction/data word: {token}")
                    self.write(base + index * 4, value, 2)
                    index += 1

    def read(self, address, size=8, instruction=False):
        self.check_address(address, size)
        return sum(self.bytes.get(address + i,
                   ((NOP >> (((address + i) % 4) * 8)) & 255)
                   if instruction and self.nop_fill else 0) << (8 * i)
                   for i in range(size))

    def read_beat(self, address, instruction=False):
        self.check_address(address)
        return self.read(address & ~7, instruction=instruction)

    def write(self, address, data, funct3):
        if funct3 not in (0, 1, 2, 3):
            raise ValueError(f"Unsupported store funct3: {funct3}")
        size = 1 << funct3  # SB, SH, SW, SD; data is unshifted rs2.
        self.check_address(address, size)
        if address % size:
            raise ValueError(f"Misaligned {size}-byte store: {address:#x}")
        for i in range(size):
            self.bytes[address + i] = (data >> (8 * i)) & 255


def initialize_dut_inputs(dut):
    for name in ("clock", "reset_n", "cpu_stop", "timer_irq_ext",
                 "program_mem_read_ready", "program_mem_read_data",
                 "data_mem_read_ready", "data_mem_read_data", "data_mem_write_ready",
                 "mmu_data_mem_read_ready", "mmu_data_mem_read_data",
                 "mmu_data_req_ready", "csr_DMA_STATUS", "csr_SA_STATUS",
                 "csr_CPU_MON_CYCLE"):
        getattr(dut, name).value = 0
    dut.program_mem_req_ready.value = 1
    dut.data_mem_req_ready.value = 1
    for name in ("program_mem_read_address", "program_mem_read_data",
                 "data_mem_read_address", "data_mem_read_data",
                 "mem_write_address", "mem_write_data",
                 "mmu_data_mem_read_address", "mmu_data_mem_read_data"):
        assert len(getattr(dut, name)) == 64, f"Update model for changed port {name}"
    assert len(dut.mem_write_sel) == 3


class PIO32Result:
    """Compare the first SW after the completion marker, not intermediate output."""
    def __init__(self, expected):
        if not 0 <= expected <= PIO32_MASK:
            raise ValueError("EXPECTED_RESULT must be a 32-bit unsigned value")
        self.expected = expected
        self.marker_detected = False
        self.actual = None
        self.write_count = 0
        self.last_value = None

    def observe_write(self, address, data, funct3):
        if address != PIO32_ADDRESS or self.actual is not None:
            return
        assert funct3 == 2, f"PIO32 requires a 32-bit SW, got funct3={funct3}"
        # SW writes only the low 32 bits of the RV64 register.
        value = data & PIO32_MASK
        self.write_count += 1
        self.last_value = value
        if self.marker_detected:
            self.actual = value
        elif value == TEST_END_CODE:
            self.marker_detected = True

    def check(self, cycles):
        if self.actual is None:
            phase = "result after marker" if self.marker_detected else "marker 0x0000EE01"
            last = "none" if self.last_value is None else f"0x{self.last_value:08X}"
            raise TimeoutError(
                f"PIO32 {phase} timeout after {cycles} cycles: "
                f"address=0x{PIO32_ADDRESS:08X}, writes={self.write_count}, last={last}"
            )
        assert self.actual == self.expected, (
            f"PIO32 result mismatch: expected=0x{self.expected:08X}, "
            f"actual=0x{self.actual:08X}, cycle={cycles}"
        )


class MemoryBus:
    """Always accepts requests, with deterministic >=1-cycle response latency.

    Requests are sampled at falling-edge ReadOnly (stable across the following
    rising edge). Responses are driven 1 ps after that rising edge and consumed
    by RTL on the next rising edge. No RTL/cocotb same-edge write race.
    A program burst returns four beats (+0,+8,+16,+24), one per cycle.
    """
    def __init__(self, dut, memory, latency, result):
        self.dut, self.memory, self.latency = dut, memory, latency
        self.result = result
        self.requests = dict(program=0, read=0, write=0)
        self.responses = dict(program=0, read=0, write=0)

    async def run(self):
        dut = self.dut
        cycle = 0
        pending = []
        while True:
            await FallingEdge(dut.clock)
            await ReadOnly()
            reset = not int(dut.reset_n.value)
            requests = []
            if not reset:
                if int(dut.mmu_data_mem_read_valid.value):
                    raise AssertionError("MMU request outside Bare-only test scope")
                if int(dut.program_mem_read_valid.value):
                    address = int(dut.program_mem_read_address.value)
                    burst = int(dut.program_mem_burst_mode.value)
                    if address % (32 if burst else 8):
                        raise AssertionError(f"Unaligned instruction bus request: {address:#x}")
                    requests.append(("program", address, 4 if burst else 1, 0))
                if int(dut.data_mem_read_valid.value):
                    requests.append(("read", int(dut.data_mem_read_address.value), 1, 0))
                if int(dut.data_mem_write_valid.value):
                    requests.append(("write", int(dut.mem_write_address.value),
                                     int(dut.mem_write_data.value), int(dut.mem_write_sel.value)))
            await RisingEdge(dut.clock)
            await Timer(1, unit="ps")
            dut.program_mem_read_ready.value = 0
            dut.data_mem_read_ready.value = 0
            dut.data_mem_write_ready.value = 0
            if reset:
                cycle = 0
                pending.clear()
                dut.program_mem_read_data.value = 0
                dut.data_mem_read_data.value = 0
            else:
                cycle += 1
                for kind, address, data, sel in requests:
                    self.requests[kind] += 1
                    if kind == "program":
                        for beat in range(data):
                            pending.append((cycle + self.latency - 1 + beat,
                                            kind, address + beat * 8, 0, 0))
                    else:
                        pending.append((cycle + self.latency - 1, kind, address, data, sel))
                due = [item for item in pending if item[0] == cycle]
                pending = [item for item in pending if item[0] != cycle]
                channels = set()
                for _, kind, address, data, sel in due:
                    assert kind not in channels, f"Overlapping {kind} responses"
                    channels.add(kind)
                    self.responses[kind] += 1
                    if kind == "write":
                        self.memory.write(address, data, sel)
                        marker_detected = self.result.marker_detected
                        write_count = self.result.write_count
                        self.result.observe_write(address, data, sel)
                        if self.result.write_count != write_count:
                            dut._log.info(
                                "PIO32 write #%d cycle=%d "
                                "addr=0x%08X data=0x%08X sel=0x%X",
                                self.result.write_count, cycle, address,
                                self.result.last_value, sel,
                            )
                        if self.result.marker_detected and not marker_detected:
                            dut._log.info(
                                "PIO32 marker detected at cycle %d: 0x%08X",
                                cycle, self.result.last_value,
                            )
                        dut.data_mem_write_ready.value = 1
                    else:
                        prefix = "program" if kind == "program" else "data"
                        getattr(dut, f"{prefix}_mem_read_data").value = self.memory.read_beat(
                            address, instruction=(kind == "program"))
                        getattr(dut, f"{prefix}_mem_read_ready").value = 1
            dut.csr_CPU_MON_CYCLE.value = cycle & MASK


async def reset_dut(dut, cycles):
    dut.reset_n.value = 0
    for _ in range(cycles):
        await RisingEdge(dut.clock)
        await ReadOnly()
        for name in ("program_mem_read_valid", "data_mem_read_valid", "data_mem_write_valid"):
            assert int(getattr(dut, name).value) == 0, f"Request during reset: {name}"
    await FallingEdge(dut.clock)
    dut.reset_n.value = 1


async def run_until_result(dut, result, count):
    for cycle in range(count):
        await RisingEdge(dut.clock)
        await ReadOnly()
        assert int(dut.reset_n.value) == 1, "Unexpected reset during run"
        if result.actual is not None:
            return cycle + 1
    return count


@cocotb.test()
async def RV64_core_test(dut):
    """Require completion and the program-specific expected PIO32 result."""
    dut._log.info("Start PSC_RV64 test")
    period = setting("CLK_PERIOD_NS", 10, 2)
    reset_cycles = setting("RESET_CYCLES", 10)
    cycles = setting("RUN_CYCLES", 500000)
    timeout_ns = setting("TIMEOUT_NS", (reset_cycles + cycles + 10) * period * 2)
    program = os.environ.get("PROGRAM_FILE", "")
    if not program:
        raise ValueError("PROGRAM_FILE is required for PASS/FAIL testing")
    expected = os.environ.get("EXPECTED_RESULT", "")
    if not expected:
        raise ValueError("EXPECTED_RESULT is required for PASS/FAIL testing")
    result = PIO32Result(int(expected, 0))
    memory = Memory()
    memory.load_program(program, setting("PROGRAM_BASE", 0, 0))
    initialize_dut_inputs(dut)
    bus = MemoryBus(dut, memory, setting("MEM_LATENCY", 2), result)
    tasks = [cocotb.start_soon(Clock(dut.clock, period, unit="ns").start()),
             cocotb.start_soon(bus.run())]

    async def scenario():
        await reset_dut(dut, reset_cycles)
        return await run_until_result(dut, result, cycles)

    try:
        completed = await with_timeout(scenario(), timeout_ns, "ns")
        result.check(completed)
        dut._log.info("PIO32 result PASS: expected=0x%08X actual=0x%08X",
                      result.expected, result.actual)
        dut._log.info("RV64 CPU test PASS: expected=0x%08X actual=0x%08X",
                      result.expected, result.actual)
    finally:
        for task in tasks:
            task.cancel()
