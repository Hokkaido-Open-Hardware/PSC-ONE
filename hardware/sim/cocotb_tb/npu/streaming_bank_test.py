import random

import cocotb
from cocotb.triggers import Timer


@cocotb.test()
async def independent_acc_scoreboard(dut):
    rng = random.Random(0xacca)
    expected = [0]*16
    for cycle in range(1800):
        dut.clock.value = 0
        reset = cycle < 2 or cycle == 911
        clear = cycle%197 == 0
        mask = rng.randrange(16)
        ids = [rng.randrange(4)*4+lane for lane in range(4)]
        values = [rng.choice([0,1,0xffffffff,0x7fffffff,0x80000000,rng.getrandbits(32)]) for _ in range(4)]
        dut.reset_n.value = int(not reset)
        dut.clear.value = int(clear)
        dut.wb_valid.value = mask
        dut.wb_id.value = sum(v << (i*4) for i,v in enumerate(ids))
        dut.wb_data.value = sum(v << (i*32) for i,v in enumerate(values))
        if reset or clear:
            expected = [0]*16
        else:
            for lane in range(4):
                if mask >> lane & 1:
                    expected[ids[lane]] = (expected[ids[lane]]+values[lane]) & 0xffffffff
        await Timer(5,unit='ns'); dut.clock.value = 1; await Timer(5,unit='ns')
        assert int(dut.ps_acc.value) == sum(v << (i*32) for i,v in enumerate(expected)), cycle
