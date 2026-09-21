import json
import os
from pathlib import Path
import random
import cocotb
from cocotb.triggers import Timer
from pot import CODES, decode, term

MASK=(1<<32)-1

def pack(values):return sum((v&255)<<(8*i) for i,v in enumerate(values))

@cocotb.test()
async def phases_accumulator_reset_snapshot_back_to_back(dut):
    lanes=int(os.environ['LANES']); count=32//lanes; rng=random.Random(9)
    async def tick(**values):
        dut.clock.value=0
        for k,v in values.items():getattr(dut,k).value=v
        await Timer(5,unit='ns');dut.clock.value=1;await Timer(5,unit='ns')
    def check(expected):
        actual=int(dut.ps_acc.value)
        assert [(actual>>(32*i))&MASK for i in range(16)]==[x&MASK for x in expected]
    await tick(reset_n=0,start=0,data_clear=0,signed_mode=1,data_A=0,data_B=0)
    await tick(reset_n=1)
    expected=[0]*16
    for iteration in range(300):
        a=[rng.randrange(-128,128) for _ in range(16)]
        b=[CODES[rng.randrange(256)] for _ in range(16)]
        await tick(start=1,data_clear=0,data_A=0,data_B=0)
        assert int(dut.busy.value) and not int(dut.done.value)
        for edge in range(1,count+5):
            if edge==2:
                await tick(start=0,data_clear=0,data_A=pack(a),data_B=pack(b),signed_mode=1)
            else:
                # Active start/clear cannot overwrite ACC or snapshots.
                await tick(start=int(edge==4),data_clear=int(edge==5),data_A=rng.getrandbits(128),data_B=rng.getrandbits(128),signed_mode=0)
            if 4<=edge<=count+3:
                phase=(edge-4)%2; group=(edge-4)//2
                for lane in range(lanes):
                    i=group*lanes+lane
                    expected[i]+=a[i]*(0 if b[i]==0 else term((b[i]>>(4*phase))&15))
            check(expected)
            assert int(dut.done.value)==int(edge==count+4)
            assert int(dut.busy.value)==int(edge!=count+4)
        # The next iteration starts on the very next clock (no idle bubble).
    await tick(start=1,data_clear=1)
    check([0]*16); assert not int(dut.busy.value)
    # Abort at every edge, including both phases and pending final WB.
    for abort_edge in range(count+4):
        await tick(reset_n=0,start=0,data_clear=0);check([0]*16)
        await tick(reset_n=1)
        await tick(start=1,data_A=pack([-128]*16),data_B=pack([CODES[0]]*16))
        for _ in range(abort_edge): await tick(start=0)
        await tick(reset_n=0);check([0]*16)
        assert not int(dut.busy.value) and not int(dut.done.value)
        await tick(reset_n=1,start=0)
        for _ in range(count+5):await tick();check([0]*16)

@cocotb.test()
async def actual_tflite_all_channels(dut):
    lanes=int(os.environ['LANES']); count=32//lanes
    async def tick(**values):
        dut.clock.value=0
        for k,v in values.items():getattr(dut,k).value=v
        await Timer(5,unit='ns');dut.clock.value=1;await Timer(5,unit='ns')
    await tick(reset_n=0,start=0,data_clear=0,signed_mode=1,data_A=0,data_B=0)
    await tick(reset_n=1)
    vectors=json.loads(Path(os.environ['MODEL_VECTORS']).read_text())
    for vector in vectors:
        await tick(data_clear=1,start=0)
        a,b=vector['activation'],vector['codes']
        await tick(data_clear=0,start=1,data_A=pack(a),data_B=pack(b))
        for _ in range(count+4):await tick(start=0)
        assert int(dut.done.value)
        values=[(int(dut.ps_acc.value)>>(32*i))&MASK for i in range(16)]
        expected=[x*decode(code)&MASK for x,code in zip(a,b)]
        assert values==expected
        assert sum(v if v<1<<31 else v-(1<<32) for v in values)==vector['raw']
