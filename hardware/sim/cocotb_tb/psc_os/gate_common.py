"""Gowin functional netlist test using board pins, without RTL backdoors.

The normal test requires PSC_OS> before its deadline. GATE_CHECK_US selects
an explicit, shorter clock/reset check; it does not claim an OS boot PASS.
UART helpers and the optional console are shared with the RTL simulation.
"""
import os
from decimal import Decimal
from pathlib import Path
from queue import Empty, Queue
import sys
import threading

import cocotb
from cocotb.triggers import Event, FallingEdge, RisingEdge, Timer, with_timeout

from cocotb_tb.psc_os import PSCONE_os_test as uart


async def receive_uart(dut, log, ready, gui):
    """Decode 8N1, rejecting X/Z and malformed frames rather than hiding them."""
    bit_ns = uart.UART_BIT_NS
    tail = ""
    line = ""
    while True:
        await FallingEdge(dut.uart_tx)
        await Timer(bit_ns / 2, unit="ns")
        if str(dut.uart_tx.value) != "0":
            continue
        value = 0
        valid = True
        for bit in range(8):
            await Timer(bit_ns, unit="ns")
            sample = str(dut.uart_tx.value)
            valid &= sample in ("0", "1")
            value |= (sample == "1") << bit
        await Timer(bit_ns, unit="ns")
        if not valid or str(dut.uart_tx.value) != "1":
            dut._log.warning("[GATE UART] Invalid 8N1 frame; check UART bit period")
            continue
        char = chr(value)
        log.write(char)
        log.flush()
        if gui is not None:
            gui.write_byte(value)
        line += char
        if char == "\n":
            dut._log.info("[UART] %s", line.rstrip())
            line = ""
        tail = (tail + char)[-len(uart.BOOT_MARKER):]
        if tail == uart.BOOT_MARKER and not ready.is_set():
            dut._log.info("[GATE BOOT PASS] UART marker: %s", uart.BOOT_MARKER)
            ready.set()
            if gui is not None:
                gui.prompt_ready()


async def send_uart(dut, queue, ready):
    await ready.wait()
    while True:
        try:
            source, text = queue.get_nowait()
        except Empty:
            await Timer(uart.UART_BIT_NS * 10, unit="ns")
            continue
        if source == "notice":
            dut._log.info("[UART input] %s", text)
        else:
            # Synthesized RX register names are not part of the interface.
            await uart.uart_serial_send(dut, dut.uart_rx, text)


async def run_gate_boot(dut):
    clock_ns = Decimal(os.environ.get("GATE_CLOCK_PERIOD_NS", "37.038"))
    check_us = Decimal(os.environ.get("GATE_CHECK_US", "0"))
    run_cycles = int(os.environ.get("RUN_CYCLES", "1500000000"))
    assert clock_ns.is_finite() and check_us.is_finite()
    assert clock_ns > 0 and check_us >= 0 and run_cycles > 0
    # Avoid binary float error for long deadlines (37.038 ns * 1.5e9).
    # The HDL oscillator rounds each half-period to the 1 ps time precision.
    clock_ps = 2 * int((clock_ns * 500).to_integral_value(rounding="ROUND_HALF_UP"))
    assert clock_ps > 0
    timeout_ps = run_cycles * clock_ps
    assert uart.UART_BIT_NS > 0
    ready = Event()
    queue = Queue()
    stop_stdin = threading.Event()
    gui = None
    tasks = []
    log_path = Path(uart.logfile)
    log_path.parent.mkdir(parents=True, exist_ok=True)
    dut.rst.value = 1
    dut.uart_rx.value = 1
    try:
        if uart.UART_GUI:
            try:
                gui = uart.UartGui(queue, str(log_path))
            except (OSError, RuntimeError) as exc:
                if "PSC_UART_GUI" in os.environ:
                    raise
                dut._log.warning("[UART GUI] %s; using terminal/log output", exc)
        if uart.UART_INTERACTIVE:
            threading.Thread(target=uart.uart_stdin_reader,
                             args=(sys.stdin, queue, stop_stdin), daemon=True).start()
        if uart.env_flag("PSC_UART_AUTO_PROMPT", not (uart.UART_INTERACTIVE or gui)):
            queue.put(("auto", uart.PROMPT_TEXT))
        with log_path.open("w", encoding="utf-8") as log:
            tasks.append(cocotb.start_soon(receive_uart(dut, log, ready, gui)))
            tasks.append(cocotb.start_soon(send_uart(dut, queue, ready)))
            # The Gowin rPLL model needs about 50 us to lock at 27 MHz.
            # Keep reset asserted until the actual output clock starts.
            await with_timeout(RisingEdge(dut.sdram_clk), 1, "ms")
            await Timer(10, unit="us")
            dut.rst.value = 0
            dut._log.info("[GATE] Reset released; input period=%s ns, UART bit=%s ns",
                          clock_ns, uart.UART_BIT_NS)
            if check_us:
                await Timer(check_us, unit="us", round_mode="ceil")
                assert int(dut.sdram_clock_edges.value) > 100, "PLL/SDRAM clock did not start"
                assert str(dut.uart_tx.value) in ("0", "1"), "UART TX is unresolved"
                dut._log.info("[GATE CLOCK/RESET PASS] OS boot was not checked")
            elif uart.STOP_AFTER_BOOT:
                await with_timeout(ready.wait(), timeout_ps, "ps")
            else:
                await Timer(timeout_ps, unit="ps")
                assert ready.is_set(), f"OS boot marker {uart.BOOT_MARKER!r} not received"
            dut._log.info("[GATE] SDRAM clocks=%s commands=%s; SD commands=%s reads=%s",
                          int(dut.sdram_clock_edges.value), int(dut.sdram_commands.value),
                          int(dut.u_sd_model.command_count.value), int(dut.u_sd_model.read_count.value))
    finally:
        stop_stdin.set()
        for task in tasks:
            task.cancel()
        if gui is not None:
            gui.close()
