import os
import cocotb
from cocotb.triggers import Timer
from pot import term, decode

@cocotb.test()
async def exhaustive_all_activation_code_pairs(dut):
    lanes=int(os.environ['LANES'])
    async def tick(**values):
        dut.clock.value=0
        for key,val in values.items():getattr(dut,key).value=val
        await Timer(5,unit='ns');dut.clock.value=1;await Timer(5,unit='ns')
    await tick(reset_n=0,capture=0,issue=0,phase=0,group_index=0,signed_mode=0,data_A=0,data_B=0)
    await tick(reset_n=1)
    for mode in (0,1):
        for base in range(0,65536,16):
            a=[(base+i)//256 for i in range(16)]
            b=[(base+i)%256 for i in range(16)]
            await tick(capture=1,issue=0,signed_mode=mode,data_A=sum(v<<(8*i) for i,v in enumerate(a)),data_B=sum(v<<(8*i) for i,v in enumerate(b)))
            assert int(dut.wb_valid.value)==0
            for group in range(16//lanes):
                products=[0]*lanes
                for phase in (0,1):
                    await tick(capture=0,issue=1,phase=phase,group_index=group,data_A=0,data_B=0)
                    assert int(dut.wb_valid.value)==(1<<lanes)-1
                    for lane in range(lanes):
                        index=group*lanes+lane
                        x=a[index]-(256 if mode and a[index]&128 else 0)
                        value=x*(0 if b[index]==0 else term((b[index]>>(4*phase))&15))
                        assert (int(dut.wb_id.value)>>(4*lane))&15==index
                        assert (int(dut.wb_data.value)>>(32*lane))&0xffffffff==value&0xffffffff
                        products[lane]+=value
                for lane in range(lanes):
                    i=group*lanes+lane
                    x=a[i]-(256 if mode and a[i]&128 else 0)
                    assert products[lane]==x*decode(b[i])
    await tick(issue=0)
    assert int(dut.wb_valid.value)==0
