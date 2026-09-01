import os

import cocotb
from cocotb.handle import SimHandleBase
from cocotb.triggers import RisingEdge, Timer


CLK_PERIOD_NS = int(os.getenv("CLK_PERIOD_NS", "10"))
RUN_CYCLES = int(os.getenv("RUN_CYCLES", "12000000"))
SDRAM_INIT_TIMEOUT = int(os.getenv("SDRAM_INIT_TIMEOUT", "500000"))
BOOT_ROM_TIMEOUT = int(os.getenv("BOOT_ROM_TIMEOUT", "20000000"))


def resolved(value):
    if isinstance(value, SimHandleBase):
        value = value.value
    if isinstance(value, int):
        return value
    text = str(value).lower().replace("x", "0").replace("z", "0")
    try:
        return int(text, 2)
    except ValueError:
        return 0


async def cycles(clock, count):
    for _ in range(count):
        await RisingEdge(clock)


async def wait_level(signal, level, clock, timeout):
    for _ in range(timeout):
        if resolved(signal) == level:
            return True
        await RisingEdge(clock)
    return False


async def clock(dut):
    while True:
        dut.clock.value = 0
        await Timer(CLK_PERIOD_NS // 2, unit="ns")
        dut.clock.value = 1
        await Timer(CLK_PERIOD_NS // 2, unit="ns")


@cocotb.test()
async def two_busy_processes_are_preempted_by_1ms_timer_irq(dut):
    cocotb.start_soon(clock(dut))
    dut.uart_rx.value = 0
    dut.rst.value = 0
    await cycles(dut.clock, 2)
    dut.rst.value = 1
    await cycles(dut.clock, 50)
    dut.rst.value = 0

    if not await wait_level(dut.u_chip.sdram_init_fin, 1, dut.clock,
                            SDRAM_INIT_TIMEOUT):
        raise AssertionError("timeout waiting for sdram_init_fin")
    if not await wait_level(dut.u_chip.Boot_rom_done, 1, dut.clock,
                            BOOT_ROM_TIMEOUT):
        raise AssertionError("timeout waiting for Boot_rom_done")
    await cycles(dut.clock, 100)
    # Start collecting UART immediately after the boot transfer completes.
    expected = [
        "DUMMY_A_0", "DUMMY_B_0",
        "DUMMY_A_1", "DUMMY_B_1",
        "DUMMY_A_2", "DUMMY_B_2",
        "DUMMY_A_3", "DUMMY_B_3",
    ]
    seen = ""
    markers = []
    irq_rise_cycles = []
    previous_irq = 0
    timer_done = False

    for cycle in range(RUN_CYCLES):
        await RisingEdge(dut.clock)
        irq = resolved(dut.u_chip.irq_tx)
        if irq == 1 and previous_irq == 0:
            irq_rise_cycles.append(cycle)
        previous_irq = irq
        if resolved(dut.u_chip.u_uart.w_tx_wr) == 1:
            ch = resolved(dut.u_chip.u_uart.cpu_wdata) & 0xFF
            if 0x20 <= ch <= 0x7E or ch in (0x0A, 0x0D):
                seen += chr(ch)
                if "DUMMY_TIMER_DONE" in seen:
                    timer_done = True
                for marker in expected[len(markers):]:
                    if marker in seen:
                        markers.append(marker)
                        seen = seen[seen.rfind(marker) + len(marker):]
                        break
        if (len(markers) == len(expected) and timer_done and
                len(irq_rise_cycles) >= 10):
            break

    if markers != expected:
        core = dut.u_chip.u_core_axi.u_core
        csr = core.u_csr
        debug = {
            "boot_done": resolved(dut.u_chip.Boot_rom_done),
            "pc": hex(resolved(core.pc)),
            "i_pf": resolved(core.i_pf),
            "d_pf": resolved(core.d_pf),
            "mtvec": hex(resolved(csr.csr_mtvec)),
            "mepc": hex(resolved(csr.csr_mepc)),
            "mcause": hex(resolved(csr.csr_mcause)),
            "mstatus": hex(resolved(csr.csr_mstatus)),
            "mie": hex(resolved(csr.csr_mie)),
        }
        raise AssertionError(
            "dummy process sequence mismatch: " + repr(markers) +
            "; irq rises=" + repr(irq_rise_cycles) +
            "; uart tail=" + repr(seen[-1000:]) +
            "; debug=" + repr(debug)
        )
    if not timer_done:
        raise AssertionError("scheduler did not return to idle after busy tasks")
    if len(irq_rise_cycles) < 10:
        raise AssertionError(
            "too few timer_irq_ext rising edges: " + repr(irq_rise_cycles)
        )

    # Input clock and SoC timer clock are both 100MHz in this simulation.
    # reload=999 with the timer's 100-cycle prescaler must produce one IRQ
    # every 1000us, i.e. 100,000 input clock cycles.  Allow a tiny sampling
    # tolerance around the registered level output.
    periods = [b - a for a, b in zip(irq_rise_cycles, irq_rise_cycles[1:])]
    bad_periods = [period for period in periods if not 99998 <= period <= 100002]
    if bad_periods:
        raise AssertionError(
            "timer_irq_ext is not 1ms periodic: " + repr(periods)
        )
    dut._log.info("preempted task markers: %s", markers)
    dut._log.info("timer_irq_ext rising cycles: %s", irq_rise_cycles)
    dut._log.info("timer_irq_ext periods: %s cycles (100MHz)", periods)
