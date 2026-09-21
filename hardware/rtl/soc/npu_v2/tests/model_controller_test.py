"""Deterministic transaction delays for before/after cycle comparisons."""
import json
import os
from pathlib import Path
import random

import cocotb
from cocotb.triggers import Timer
from pot import CODES, quantize
from evaluate_model import requant


@cocotb.test()
async def full_tflite_fc1_fc2_all_samples(dut):
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

    model_dir = Path(os.environ['MODEL_VECTORS']).parent
    layers = json.loads((model_dir/'model.json').read_text())['layers']
    vectors = json.loads(Path(os.environ['MODEL_VECTORS']).read_text())
    samples = [v['activation'] for v in vectors if v['layer']==0 and v['channel']==0]
    import csv
    with (model_dir/'cpu.csv').open() as f:
        cpu = {(int(r['sample']),int(r['layer']),int(r['channel'])):r
               for r in csv.DictReader(f)}
    await tick(reset_n=0,start=0,sa_state_reset=0,sa_clear=0,sa_os_instruction=0,
               signed_mode=1,matrix_size_x=16,matrix_size_y=4,
               BASE_ADDR_A=0x12000,BASE_ADDR_B=0x24000,BASE_ADDR_C=0x48000)
    await tick(reset_n=1)
    for sample,data in enumerate(samples):
        for layer,desc in enumerate(layers):
            outputs=[]
            for channel in range(0,desc['n'],4):
                # Four identical rows of A compute four output channels at once.
                b=[[quantize(desc['weights'][(channel+c)*16+k]) for c in range(4)] for k in range(16)]
                memory={0x12000+r*16+k:data[k]&255 for r in range(4) for k in range(16)}
                memory.update({0x24000+k*4+c:CODES[b[k][c]+128] for k in range(16) for c in range(4)})
                expected={0x48000+(r*4+c)*4:sum(data[k]*b[k][c] for k in range(16))&0xffffffff
                          for r in range(4) for c in range(4)}
                writes,nreads={},0
                await tick(start=1)
                for _ in range(5000):
                    await tick(start=0)
                    if int(dut.done.value):break
                else:assert False,'TFLite Controller timeout'
                assert writes==expected and nreads==32
                for c in range(4):
                    raw=writes[0x48000+c*4]
                    if raw >= 1<<31:raw-=1<<32
                    biased=raw-desc['input_zero']*sum(b[k][c] for k in range(16))+desc['bias'][channel+c]
                    q=requant(biased,desc['multiplier'],desc['shift'])+desc['output_zero']
                    output=max(desc['activation_min'],min(127,q))
                    ref=cpu[sample,layer,channel+c]
                    assert [raw,biased,q,output]==[int(ref[k]) for k in ['raw','biased','requant','output']]
                    outputs.append(output)
                await tick(sa_state_reset=1)
                await tick(sa_state_reset=0)
                assert not int(dut.done.value) and not int(dut.busy.value)
            data=outputs  # Actual RTL FC1 + CPU requant feeds FC2.
        assert max(range(4),key=lambda c:data[c])==max(range(4),key=lambda c:int(cpu[sample,1,c]['output']))
    dut._log.info('Full Controller TFLite: %d samples, %d channels PASS',len(samples),len(samples)*20)
