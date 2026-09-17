"""Independent cycle model for the fixed-four MAC and unchanged shift path."""
import json
import os
from pathlib import Path
import random

import cocotb
from cocotb.triggers import Timer


def pack(values, width=8):
    return sum((v & ((1 << width)-1)) << (i*width) for i,v in enumerate(values))


@cocotb.test()
async def snapshot_drain_and_streaming(dut):
    baseline = bool(int(os.getenv('NPU_BASELINE','0')))
    rng = random.Random(0x4acc)
    a,b,acc = [0]*16,[0]*16,[0]*16
    products = [0]*16
    phase = 0
    completed = 0
    for cycle in range(1400):
        dut.clock.value = 0
        reset = cycle < 3 or cycle in (317,911)
        clear = rng.randrange(23) == 0
        start = rng.randrange(3) != 0
        shift_a,shift_b = rng.randrange(2),rng.randrange(2)
        mode = rng.randrange(2)
        left,top = [rng.randrange(256) for _ in range(4)],[rng.randrange(256) for _ in range(4)]
        dut.reset_n.value = int(not reset)
        dut.data_clear.value = int(clear)
        dut.start_pulse.value = int(start)
        dut.signed_mode.value = mode
        dut.en_shift_right.value = shift_a
        dut.en_b_shift_bottom.value = shift_b
        dut.a_left_in_bus.value = pack(left)
        dut.b_top_in_bus.value = pack(top)
        dut.ps_select.value = 0
        await Timer(5,unit='ns')
        done = 0
        if reset:
            a,b,acc,phase = [0]*16,[0]*16,[0]*16,0
        else:
            if phase == 2:
                def operand(v):
                    return v-256 if mode and v & 128 else v
                products = [operand(x)*operand(y) for x,y in zip(a,b)]
            if not baseline and 4 <= phase <= 7:
                group = phase-4
                assert int(dut.wb_valid.value) == 15
                for lane in range(4):
                    dest = group*4+lane
                    assert (int(dut.wb_id.value) >> (lane*4)) & 15 == dest
                    assert (int(dut.wb_data.value) >> (lane*32)) & 0xffffffff == products[dest] & 0xffffffff
                    acc[dest] = (acc[dest]+products[dest]) & 0xffffffff
            elif not baseline:
                assert int(dut.wb_valid.value) == 0
            if phase == 8:
                if baseline:
                    acc = [(x+y)&0xffffffff for x,y in zip(acc,products)]
                phase,done = 0,1
                completed += 1
            elif phase:
                phase += 1
            elif clear:
                acc = [0]*16
            elif start:
                phase = 1
            if clear:
                a,b = [0]*16,[0]*16
            else:
                if shift_a:
                    a = [left[i//4] if i%4 == 0 else a[i-1] for i in range(16)]
                if shift_b:
                    b = [top[i] if i<4 else b[i-4] for i in range(16)]
        dut.clock.value = 1
        await Timer(1,unit='ns')
        assert int(dut.busy_out.value) == int(phase != 0), cycle
        assert int(dut.done_out.value) == done, cycle
        for index in range(16):
            dut.ps_select.value = index
            await Timer(1,unit='ns')
            assert int(dut.ps_acc_out.value) == acc[index], (cycle,index)
    assert completed > 100


@cocotb.test()
async def padded_2x2_and_k_accumulation(dut):
    """Compute actual 2x2 matrices on the new 4x4 array, then accumulate K."""
    async def tick(**signals):
        dut.clock.value = 0
        for name,value in signals.items(): getattr(dut,name).value = value
        await Timer(5,unit='ns'); dut.clock.value = 1; await Timer(5,unit='ns')

    await tick(reset_n=0,data_clear=0,start_pulse=0,signed_mode=0,
               en_shift_right=0,en_b_shift_bottom=0,a_left_in_bus=0,b_top_in_bus=0,ps_select=0)
    await tick(reset_n=1)
    timings = []
    for mode in (0,1):
        await tick(data_clear=1)
        await tick(data_clear=0)
        expected = [0]*16
        for batch in range(3):
            a = [[0]*4 for _ in range(4)]; b = [[0]*4 for _ in range(4)]
            a[0][:2],a[1][:2] = ([-128,127],[-1,1]) if mode else ([255,128],[1,0])
            b[0][:2],b[1][:2] = ([127,-128],[1,-1]) if mode else ([128,255],[255,1])
            for r in range(4):
                for c in range(4):
                    expected[r*4+c] = (expected[r*4+c]+sum(a[r][k]*b[k][c] for k in range(4))) & 0xffffffff
            for step in range(12):
                left = [a[r][step-r] if 0 <= step-r < 4 else 0 for r in range(4)]
                top = [b[step-c][c] if 0 <= step-c < 4 else 0 for c in range(4)]
                await tick(signed_mode=mode,a_left_in_bus=pack(left),b_top_in_bus=pack(top),
                           en_shift_right=1,en_b_shift_bottom=1)
                await tick(en_shift_right=0,en_b_shift_bottom=0,start_pulse=1)
                elapsed = 0
                while not int(dut.done_out.value):
                    await tick(start_pulse=0); elapsed += 1
                    assert elapsed < 20
                timings.append(elapsed)
                await tick()
            for index in range(16):
                dut.ps_select.value = index; await Timer(1,unit='ns')
                assert int(dut.ps_acc_out.value) == expected[index], (mode,batch,index)
    assert set(timings) == {8}
    Path(os.environ['NPU_CYCLE_RESULTS']).write_text(json.dumps({'mac_start_to_done':8,'batches':len(timings)})+'\n')
