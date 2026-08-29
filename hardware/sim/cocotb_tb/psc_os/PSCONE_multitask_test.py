import os

import cocotb
from cocotb.handle import SimHandleBase
from cocotb.triggers import RisingEdge, Timer


CLK_PERIOD_NS = int(os.getenv("CLK_PERIOD_NS", "10"))
RUN_CYCLES = int(os.getenv("RUN_CYCLES", "12000000"))
SDRAM_INIT_TIMEOUT = int(os.getenv("SDRAM_INIT_TIMEOUT", "500000"))
BOOT_ROM_TIMEOUT = int(os.getenv("BOOT_ROM_TIMEOUT", "6000000"))


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
async def two_dummy_processes_yield_alternately(dut):
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
    # Start collecting UART immediately after SDRAM init.  The dummy kernel
    # may emit its short marker sequence immediately after boot completes.
    expected = [
        "DUMMY_A_0", "DUMMY_B_0",
        "DUMMY_A_1", "DUMMY_B_1",
        "DUMMY_A_2", "DUMMY_B_2",
        "DUMMY_A_3", "DUMMY_B_3",
    ]
    seen = ""
    markers = []

    for _ in range(RUN_CYCLES):
        await RisingEdge(dut.clock)
        if resolved(dut.u_chip.u_uart.w_tx_wr) == 1:
            ch = resolved(dut.u_chip.u_uart.cpu_wdata) & 0xFF
            if 0x20 <= ch <= 0x7E or ch in (0x0A, 0x0D):
                seen += chr(ch)
                for marker in expected[len(markers):]:
                    if marker in seen:
                        markers.append(marker)
                        seen = seen[seen.rfind(marker) + len(marker):]
                        break
        if len(markers) == len(expected):
            break

    if markers != expected:
        raise AssertionError(
            "dummy process sequence mismatch: " + repr(markers)
        )
