"""Real PSC-OS shell + FAT32 + official parser on CPU v1, via UART/SPI."""
from collections import deque
from pathlib import Path
import os
import struct
import csv
import re

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, FallingEdge, RisingEdge, with_timeout


def sd_sectors(model):
    disk = {i: bytearray(512) for i in [0, 1, 2, 10]}
    def w16(b, p, n): struct.pack_into('<H', b, p, n)
    def w32(b, p, n): struct.pack_into('<I', b, p, n)
    w16(disk[0], 510, 0xaa55); w32(disk[0], 0x1c6, 1)
    b = disk[1]
    w16(b, 510, 0xaa55); w16(b, 11, 512); b[13] = 1
    w16(b, 14, 1); b[16] = 1
    w32(b, 32, 1023); w32(b, 36, 8); w32(b, 44, 2)
    w32(disk[2], 8, 0x0fffffff)
    disk[10][:11] = b'MODEL   TFL'; disk[10][11] = 0x20
    w16(disk[10], 26, 3); w32(disk[10], 28, len(model))
    for i, offset in enumerate(range(0, len(model), 512)):
        cluster = 3 + 2*i
        w32(disk[2], 4*cluster, cluster+2 if offset+512 < len(model) else 0x0fffffff)
        disk[cluster+8] = bytearray(model[offset:offset+512]).ljust(512, b'\0')
    return disk


async def receive(tx, queue):
    while True:
        await FallingEdge(tx)
        await Timer(20, unit='ns')
        if int(tx.value): continue
        value = 0
        for bit in range(8):
            await Timer(40, unit='ns')
            value |= int(tx.value) << bit
        await Timer(40, unit='ns')
        assert int(tx.value) == 1, 'UART framing error'
        queue.append(value)


async def send(dut, text):
    for c in text.encode():
        dut.uart_rx.value = 0
        await Timer(40, unit='ns')
        for bit in range(8):
            dut.uart_rx.value = (c >> bit) & 1
            await Timer(40, unit='ns')
        dut.uart_rx.value = 1
        # Match the existing PSCONE_os_test sender: the shell polls switches and
        # UART through syscalls and cannot consume back-to-back serial bytes.
        await Timer(2, unit='ms')


@cocotb.test()
async def inspect_from_sd(dut):
    queue = deque()
    cocotb.start_soon(Clock(dut.clock, 10, unit='ns').start())
    cocotb.start_soon(receive(dut.uart_tx, queue))
    dut.uart_rx.value = 1; dut.PSCONE_SW1.value = 1; dut.PSCONE_SW2.value = 1
    dut.rst.value = 0
    await Timer(20, unit='ns')
    disk = sd_sectors(Path(os.environ['PSC_TFLITE_MODEL']).read_bytes())
    sd = dut.u_sd_model
    assert len(disk) <= len(sd.stored_valid)
    for slot, (lba, data) in enumerate(sorted(disk.items())):
        sd.stored_lba[slot].value = lba
        sd.stored_valid[slot].value = 1
        for i, byte in enumerate(data): sd.stored_data[512*slot+i].value = byte
    dut.rst.value = 1
    await Timer(500, unit='ns')
    dut.rst.value = 0
    uart = Path(os.environ['PSC_TFLITE_UART'])
    uart.write_text('')
    async def heartbeat():
        while True:
            await Timer(50, unit='ms')
            dut._log.info('boot/run progress: pc=0x%08x', int(dut.u_chip.u_core_axi.u_core.pc.value))
    cocotb.start_soon(heartbeat())
    async def until(token):
        text = ''
        while token not in text:
            await Timer(1000, unit='ns')
            chunk = ''.join(chr(queue.popleft()) for _ in range(len(queue)))
            if chunk:
                text += chunk
                with uart.open('a') as f: f.write(chunk)
            assert 'PANIC' not in text, text[-500:]
        return text
    # Full boot draws 480x320 pixels and copies the complete MicroPython shell.
    await with_timeout(until('PSC_OS>'), 3000, 'ms')
    await Timer(20000, unit='ns')
    await send(dut, 'tflite_info MODEL.TFL\r')
    text = await with_timeout(until('PSC_OS>'), 500, 'ms')
    assert 'Profile compatible: INT8 FC v4' in text, text
    assert 'tensors=7 operators=2 inputs=[0] outputs=[6]' in text, text
    assert 'Buffer data bytes=400' in text, text
    assert 'float32=0x3e000000 zero_point=-3' in text, text
    await send(dut, 'tflite_info ABSENT.TFL\r')
    text = await with_timeout(until('PSC_OS>'), 100, 'ms')
    assert 'file not found' in text, text
    await send(dut, 'tflite_run MODEL.TFL\r')
    text = await with_timeout(until('PSC_OS>'), 500, 'ms')
    assert 'Validation (demo oracle): PASS' in text, text
    assert 'Output: [-36,27,18,8]' in text, text
    with Path(os.environ['PSC_TFLITE_MODEL']).with_name('reference.csv').open() as reference_file:
        expected = list(csv.DictReader(reference_file))
    observed = re.findall(r'FC(\d+) channel=(\d+) acc=(-?\d+) requant=(-?\d+) output=(-?\d+)', text)
    assert len(observed) == len(expected) == 20
    for row, ref in zip(observed, expected):
        assert tuple(map(int, row)) == (int(ref['layer'])+1, int(ref['channel']),
            int(ref['accumulator']), int(ref['requant_with_zero_point']), int(ref['clamped_output']))
    times = re.search(r'Time us: load=(\d+) prepare=(\d+) invoke=(\d+) FC1=(\d+) FC2=(\d+)', text)
    assert times and all(int(t) > 0 for t in times.groups()), text
    assert 'Arena: 116 / 4096 bytes' in text, text
    # Monitor actual CSR start edges (no software mock in this test).
    launches=[]
    async def watch_synap():
        core=dut.u_chip.u_core_axi
        while True:
            await RisingEdge(core.sa_start)
            control=int(core.csr_SA_CTRL.value)
            assert control & 8, 'NPU must receive signed INT8'
            assert 0x200000 <= int(core.csr_SA_ADDR_A.value) < 0x400000
            assert 0x200000 <= int(core.csr_SA_ADDR_B.value) < 0x400000
            launches.append((control >> 16) & 255)
    cocotb.start_soon(watch_synap())
    await send(dut, 'tflite_run MODEL.TFL cpu\r')
    text=await with_timeout(until('PSC_OS>'),500,'ms')
    assert 'Validation (demo oracle): PASS' in text and not launches,text
    await send(dut, 'tflite_run MODEL.TFL npu\r')
    text=await with_timeout(until('PSC_OS>'),1000,'ms')
    assert 'Validation (demo oracle): PASS' in text and 'Output: [-36,27,18,8]' in text,text
    assert len(launches)==60 and set(launches)=={4},launches
    launches.clear()
    await send(dut, 'tflite_bench MODEL.TFL\r')
    text=await with_timeout(until('PSC_OS>'),3000,'ms')
    assert 'Comparison: PASS' in text and 'Output: [-36,27,18,8]' in text,text
    assert 'FAIL' not in text,text
    assert len(launches)==170,launches
    assert {n:launches.count(n) for n in [4,8,12,16]}=={4:100,8:30,12:30,16:10}
    matches=re.findall(r'MATCH tile=(\d+) FC(\d+) channel=(\d+) raw=(-?\d+) corrected=(-?\d+) bias=(-?\d+) requant=(-?\d+) output=(-?\d+)',text)
    assert len(matches)==80
    for i,row in enumerate(matches):
        tile,layer,channel,raw,corrected,bias,quant,out=map(int,row)
        ref=expected[i%20]
        assert tile==4*(i//20+1)
        assert (layer,channel,bias,quant,out)==(int(ref['layer'])+1,int(ref['channel']),int(ref['accumulator']),int(ref['requant_with_zero_point']),int(ref['clamped_output']))
    benches=re.findall(r'BENCH backend=(cpu|npu) tile=(\d+) invoke=(\d+) FC1=(\d+) FC2=(\d+) us',text)
    assert len(benches)==5 and all(int(row[2])>0 for row in benches),text
    profiles=re.findall(r'PROFILE tile=(\d+) total=(\d+) tiles=(\d+) pack=(\d+) syscall=(\d+) copy_in=(\d+) run=(\d+) copy_out=(\d+) partial=(\d+) post=(\d+) valid=1 us',text)
    assert len(profiles)==4,text
    assert [int(row[2]) for row in profiles]==[20,6,6,2],profiles
    # Existing commands and the SD reader's real CRC verification after invoke.
    for command, token in [('hello', 'Hello world from shell!'),
                           ('primes 30', 'total primes: 10 (0..30)'),
                           ('sd_read 11', 'CRC OK')]:
        await send(dut, command+'\r')
        text = await with_timeout(until('PSC_OS>'), 200, 'ms')
        assert token in text, text
        assert 'CRC NG' not in text and 'CRC FAILED' not in text, text
    await send(dut, 'tflite_run ABSENT.TFL\r')
    text = await with_timeout(until('PSC_OS>'), 100, 'ms')
    assert 'file not found' in text, text
    dut._log.info('PASS: CPU v1 SD inference, all 20 intermediate channels, timing, CRC and shell regression')
