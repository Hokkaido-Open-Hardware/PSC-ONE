"""CoreMark completion/console checks on the existing PSC-ONE chip testbench."""
from collections import deque
import json
import os
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge
from cocotb.utils import get_sim_time
from cocotb_tb.cpu.RV32ISP_chip_test import reset_dut, wait_level
from cocotb_tb.psc_os.PSCONE_os_test import uart_serial_decoder


async def observe_timer(dut, windows):
    """Independent check of the target timer against RTL simulated time."""
    while True:
        await RisingEdge(dut.u_chip.u_timer.running)
        start = int(get_sim_time(unit='ns'))
        await FallingEdge(dut.u_chip.u_timer.running)
        windows.append(int(get_sim_time(unit='ns')) - start)


@cocotb.test()
async def coremark(dut):
    output = Path(os.environ['PSC_UART_LOGFILE'])
    queue = deque()
    timer_windows = []
    result_dir = Path(os.environ['COREMARK_RESULT_DIR'])
    (result_dir / 'result.json').write_text(json.dumps({'status': 'running', 'uart_log': str(output)}) + '\n')
    dut.rst.value = 1
    dut.uart_rx.value = 1
    dut.PSCONE_SW1.value = 0
    dut.PSCONE_SW2.value = 0
    cocotb.start_soon(Clock(dut.clock, 10, unit='ns', impl='gpi').start())
    cocotb.start_soon(uart_serial_decoder(dut.uart_tx, queue))
    cocotb.start_soon(observe_timer(dut, timer_windows))
    await reset_dut(dut)
    assert await wait_level(dut.u_chip.sdram_init_fin, 1, dut.clock, 500000), 'SDRAM init timeout'
    assert await wait_level(dut.u_chip.Boot_rom_done, 1, dut.clock, 5000000), 'Boot timeout'
    dut._log.info('SDRAM boot complete')
    cycles = int(os.environ['RUN_CYCLES'])
    complete = False
    with output.open('w') as stream:
        for elapsed in range(0, cycles, 10000):
            await Timer(100000, unit='ns')
            while queue:
                stream.write(chr(queue.popleft()))
            stream.flush()
            if int(dut.u_chip.u_mmap_io.PIO_out_reg.value) == 0xEE01:
                complete = True
                break
            if elapsed and elapsed % 10000000 == 0:
                dut._log.info('CoreMark running: %d target cycles', elapsed)
        # Finish transmitting the last UART byte before validation.
        await Timer(10000, unit='ns')
        while queue:
            stream.write(chr(queue.popleft()))
    assert complete, f'CoreMark completion timeout (see {output})'
    text = output.read_text()
    (result_dir / 'timer.json').write_text(json.dumps({'timer_windows_ns': timer_windows}) + '\n')
    dut._log.info('\n%s', text)
    assert 'Correct operation validated.' in text, 'CoreMark validation failed'
    assert 'ERROR!' not in text, 'CoreMark reported an error'
