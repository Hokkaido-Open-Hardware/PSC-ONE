"""Deterministic transaction delays for before/after cycle comparisons."""
import json
import os
from pathlib import Path
import random

import cocotb
from cocotb.triggers import Timer
from pot import CODES, quantize


@cocotb.test()
async def matrix_cycles_and_transactions(dut):
    rng = random.Random(0x1234)
    cycle = 0
    pending_read = pending_write = None
    memory,expected,writes = {},{},{}
    nreads = 0
    delay = 1
    async def tick(**values):
        nonlocal cycle,pending_read,pending_write,nreads
        cycle += 1
        dut.clock.value = 0
        for name,value in values.items(): getattr(dut,name).value = value
        read_ack = pending_read is not None and pending_read[0] == cycle
        write_ack = pending_write == cycle
        dut.rd_read_ready.value = int(read_ack)
        dut.rd_read_data.value = pending_read[1] if read_ack else 0xdeadbeef
        dut.c_write_ready.value = int(write_ack)
        ready = delay == 1 or cycle%5 not in (0,1)
        dut.sa_req_ready.value = int(ready)
        if read_ack: pending_read = None
        if write_ack: pending_write = None
        await Timer(5,unit='ns'); dut.clock.value = 1; await Timer(5,unit='ns')
        if int(dut.rd_read_valid.value):
            assert pending_read is None
            addr = int(dut.rd_read_addr.value)
            data = sum(memory[addr+i] << (8*i) for i in range(4))
            pending_read = (cycle+delay,data)
            nreads += 1
        if int(dut.c_write_valid.value):
            assert ready and pending_write is None
            addr,data = int(dut.c_write_addr.value),int(dut.c_write_wdata.value)
            assert addr in expected and addr not in writes
            assert data == expected[addr], (hex(addr),hex(data),hex(expected[addr]))
            writes[addr] = data
            pending_write = cycle+delay

    await tick(reset_n=0,start=0,sa_state_reset=0,sa_clear=0,sa_os_instruction=0,
               signed_mode=0,matrix_size_x=4,matrix_size_y=4,
               BASE_ADDR_A=0x12000,BASE_ADDR_B=0x24000,BASE_ADDR_C=0x48000)
    await tick(reset_n=1)
    results=[]
    for x,y,mode,delay in [(4,4,0,1),(4,4,1,1),(8,4,1,1),(4,8,0,5),(12,20,0,5),(20,12,1,5)]:
        values = [-128,-1,0,1,127] if mode else [0,1,127,128,255]
        a = [[rng.choice(values) for _ in range(x)] for _ in range(y)]
        b = [[rng.randrange(-128,128) for _ in range(y)] for _ in range(x)]
        memory = {0x12000+r*x+k:a[r][k]&255 for r in range(y) for k in range(x)}
        memory.update({0x24000+k*y+c:CODES[b[k][c]+128] for k in range(x) for c in range(y)})
        expected = {0x48000+(r*y+c)*4:sum(a[r][k]*quantize(b[k][c]) for k in range(x))&0xffffffff
                    for r in range(y) for c in range(y)}
        writes,nreads = {},0
        await tick(matrix_size_x=x,matrix_size_y=y,signed_mode=mode,start=1)
        start_cycle = cycle
        for _ in range(200000):
            await tick(start=0)
            if int(dut.done.value): break
        else: assert False,'timeout'
        assert writes == expected
        assert nreads == (x//4)*(y//4)**2*8
        assert pending_read is None and pending_write is None
        results.append({'x':x,'y':y,'signed':mode,'delay':delay,'cycles':cycle-start_cycle})
        for _ in range(3):
            await tick(); assert int(dut.done.value)
        await tick(sa_state_reset=1)
        await tick(sa_state_reset=0)
        assert not int(dut.done.value) and not int(dut.busy.value)
    Path(os.environ['NPU_CYCLE_RESULTS']).write_text(json.dumps(results,indent=2)+'\n')
