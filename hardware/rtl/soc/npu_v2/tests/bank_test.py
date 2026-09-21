import os
import random
import cocotb
from cocotb.triggers import Timer

@cocotb.test()
async def wrapping_clear_priority_lane_ownership(dut):
    lanes=int(os.environ['LANES']); rng=random.Random(17); expected=[0]*16
    async def tick(**values):
        dut.clock.value=0
        for k,v in values.items():getattr(dut,k).value=v
        await Timer(5,unit='ns');dut.clock.value=1;await Timer(5,unit='ns')
    await tick(reset_n=0,clear=0,wb_valid=0,wb_id=0,wb_data=0)
    await tick(reset_n=1)
    for iteration in range(2000):
        ids=[rng.randrange(16) for _ in range(lanes)]
        data=[rng.choice([0xffffffff,0x7fffffff,0x80000000,1,rng.getrandbits(32)]) for _ in range(lanes)]
        valid=rng.getrandbits(lanes);clear=int(iteration%101==0)
        if clear: expected=[0]*16
        else:
            for lane,(i,d) in enumerate(zip(ids,data)):
                if i%lanes==lane and valid&(1<<lane):expected[i]=(expected[i]+d)&0xffffffff
        await tick(clear=clear,wb_valid=valid,wb_id=sum(v<<(4*i) for i,v in enumerate(ids)),wb_data=sum(v<<(32*i) for i,v in enumerate(data)))
        assert [(int(dut.ps_acc.value)>>(32*i))&0xffffffff for i in range(16)]==expected
