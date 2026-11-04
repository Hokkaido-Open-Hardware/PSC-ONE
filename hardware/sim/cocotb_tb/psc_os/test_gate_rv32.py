"""RV32 entry point for the shared board-pin gate boot test."""
import cocotb

from cocotb_tb.psc_os.gate_common import run_gate_boot


@cocotb.test()
async def gate_sd_pscos(dut):
    # The shared test only uses board pins and model activity counters.
    await run_gate_boot(dut)
