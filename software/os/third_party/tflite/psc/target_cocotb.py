"""PIO packets from target_test.cc; all mismatches and timeouts fail the test."""
import json
import os
from pathlib import Path
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ReadOnly, with_timeout


@cocotb.test()
async def validate(dut):
    build=Path(os.environ['PSC_PULP_BUILD'])
    dut.rst.value=1;dut.uart_rx.value=1;dut.PSCONE_SW1.value=1;dut.PSCONE_SW2.value=1
    cocotb.start_soon(Clock(dut.clock,10,unit='ns').start())
    words=[]
    mmio=dut.u_chip.u_soc.u_mmap_io
    async def receive():
        while True:
            await RisingEdge(mmio.cpu_wready)
            await ReadOnly()
            word=int(mmio.PIO_out_reg.value)
            words.append(word)
            with (build/'pio.log').open('a') as out:out.write(f'{word:08x}\n')
            assert word!=0xbad0bad0,'firmware failure; see pio.log (source line follows BAD00001)'
            if len(words)>=2 and words[-2:]==[0xee01,0x600d600d]:return
    receiver=cocotb.start_soon(receive())
    await Timer(500,unit='ns')
    # Use the existing SDRAM model's word array; no RTL or ROM sizing changes.
    # The stock boot ROM rewrites the identical first 16 KiB before CPU start.
    data=(build/'pulp_fc.bin').read_bytes()
    for i in range(0,len(data),4):
        dut.u_sdram_model.mem[i//4].value=int.from_bytes(data[i:i+4],'little')
    dut.rst.value=0
    await with_timeout(receiver,300,'ms')
    samples=[];pos=0
    while words[pos]==0xee40:
        sample,mode,tile,total,fc1,fc2=words[pos+1:pos+7]
        assert total>=fc1+fc2>0
        samples.append(dict(sample=sample,mode=mode,tile=tile,invoke_us=total,fc1_us=fc1,fc2_us=fc2))
        pos+=7
    assert len(samples)==30 and words[pos]==0xee50
    values=words[pos+1:pos+101]
    assert len(values)==100 and words[pos+101:]==[0xee01,0x600d600d]
    signed=lambda x:x if x<2**31 else x-2**32
    rows=[list(map(signed,values[i:i+5])) for i in range(0,100,5)]
    assert [r[-1] for r in rows[-4:]]==[-36,27,18,8]
    best=[]
    for mode in range(6):
        selected=[r for r in samples if r['mode']==mode]
        assert sorted(r['sample'] for r in selected)==list(range(5))
        best.append(min(selected,key=lambda r:r['invoke_us']))
    report=dict(clock_mhz=100,cpu='v1',npu='legacy',platform='bare metal, original sa_run_checked driver; no OS syscall',
                cache='same ELF/data; warm each backend immediately before every timed invoke',
                best=best,samples=samples,rows=rows,output=[-36,27,18,8],bit_exact=True)
    (build/'timing.json').write_text(json.dumps(report,indent=2)+'\n')
    dut._log.info('PASS full model five-stage FC1/FC2 comparison; best samples %s',best)
