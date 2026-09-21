import random
import cocotb
from cocotb.triggers import Timer


@cocotb.test()
async def every_acc_id_and_out_of_range(dut):
    rng = random.Random(42)
    for _ in range(50):
        words = [rng.getrandbits(32) for _ in range(16)]
        dut.accumulators.value = sum(w << (32*i) for i, w in enumerate(words))
        for index in range(64):
            dut.select_id.value = index
            await Timer(1, unit='ns')
            assert int(dut.value.value) == (words[index] if index < 16 else 0)
