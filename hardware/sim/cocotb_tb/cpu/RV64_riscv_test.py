"""RV64 riscv-tests in the bare-metal p environment, using tohost results."""
import os

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import with_timeout

# Import the module, not its decorated test, so only this ISA test is collected.
from cocotb_tb.cpu import RV64_core_test as core


class TohostResult:
    """Observe completed stores through the existing RV64 MemoryBus interface."""

    # Disable the bus's PIO-specific logging; log tohost writes here instead.
    marker_detected = False
    write_count = 0

    def __init__(self, dut, address, expected):
        core.Memory.check_address(address, 8)
        if expected != 1:
            raise ValueError("riscv-tests requires EXPECTED_RESULT=1")
        self.dut = dut
        self.address = address
        self.expected = expected
        self.actual = None

    def observe_write(self, address, data, funct3):
        if address != self.address or self.actual is not None:
            return
        assert funct3 in (2, 3), f"Invalid tohost store funct3={funct3}"
        self.actual = data & ((1 << (8 * (1 << funct3))) - 1)
        self.dut._log.info("tohost write addr=0x%016X data=0x%016X",
                           address, self.actual)

    def check(self, cycles):
        if self.actual is None:
            raise TimeoutError(
                f"RISC-V ISA test timeout: tohost {self.address:#x} "
                f"was not written within {cycles} cycles"
            )
        assert self.actual == self.expected, (
            f"RISC-V ISA test FAIL: test_{self.actual >> 1}, "
            f"tohost={self.actual:#x}, expected={self.expected:#x}, cycle={cycles}"
        )


@cocotb.test()
async def RV64_riscv_test(dut):
    period = core.setting("CLK_PERIOD_NS", 10, 2)
    reset_cycles = core.setting("RESET_CYCLES", 10)
    cycles = core.setting("RUN_CYCLES", 200000)
    timeout_ns = core.setting("TIMEOUT_NS", (reset_cycles + cycles + 10) * period * 2)
    result = TohostResult(dut, int(os.environ["TOHOST_ADDR"], 0),
                         int(os.environ.get("EXPECTED_RESULT", "1"), 0))
    memory = core.Memory()
    memory.load_program(os.environ["PROGRAM_FILE"])
    core.initialize_dut_inputs(dut)  # Also checks instruction/data port widths.
    bus = core.MemoryBus(dut, memory, core.setting("MEM_LATENCY", 2), result)
    tasks = [cocotb.start_soon(Clock(dut.clock, period, unit="ns").start()),
             cocotb.start_soon(bus.run())]

    async def scenario():
        await core.reset_dut(dut, reset_cycles)
        return await core.run_until_result(dut, result, cycles)

    try:
        completed = await with_timeout(scenario(), timeout_ns, "ns")
        result.check(completed)
        dut._log.info("RISC-V ISA test PASS: expected=0x%X actual=0x%X",
                      result.expected, result.actual)
    finally:
        for task in tasks:
            task.cancel()
