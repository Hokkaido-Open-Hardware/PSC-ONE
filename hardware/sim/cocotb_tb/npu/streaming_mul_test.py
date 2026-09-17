import cocotb
from cocotb.triggers import Timer


@cocotb.test()
async def exhaustive_signed_unsigned(dut):
    async def tick(**values):
        dut.clock.value = 0
        for name,value in values.items(): getattr(dut,name).value = value
        await Timer(5,unit='ns'); dut.clock.value = 1; await Timer(5,unit='ns')

    await tick(reset_n=0,capture=0,issue=0,group_index=0,signed_mode=0,data_A=0,data_B=0)
    await tick(reset_n=1)
    for mode in (0,1):
        for base in range(0,65536,16):
            a = [(base+i)//256 for i in range(16)]
            b = [(base+i)%256 for i in range(16)]
            await tick(capture=1,issue=0,signed_mode=mode,
                       data_A=sum(v << (i*8) for i,v in enumerate(a)),
                       data_B=sum(v << (i*8) for i,v in enumerate(b)))
            assert int(dut.wb_valid.value) == 0
            for group in range(4):
                # Change external operands to verify the captured snapshot.
                await tick(capture=0,issue=1,group_index=group,data_A=0,data_B=0)
                assert int(dut.wb_valid.value) == 15
                for lane in range(4):
                    index = group*4+lane
                    av,bv = a[index],b[index]
                    if mode:
                        av = av-256 if av&128 else av
                        bv = bv-256 if bv&128 else bv
                    assert (int(dut.wb_id.value) >> (lane*4)) & 15 == index
                    assert (int(dut.wb_data.value) >> (lane*32)) & 0xffffffff == (av*bv)&0xffffffff
        await tick(issue=0)
        assert int(dut.wb_valid.value) == 0
