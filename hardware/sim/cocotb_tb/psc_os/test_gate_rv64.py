"""RV64 entry point for the shared board-pin gate boot test."""
import cocotb

from cocotb_tb.psc_os.gate_common import run_gate_boot


@cocotb.test()
async def gate_sd_pscos_rv64(dut):
    await run_gate_boot(dut)
