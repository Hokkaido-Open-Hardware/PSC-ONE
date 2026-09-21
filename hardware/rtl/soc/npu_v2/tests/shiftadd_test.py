import cocotb
from cocotb.triggers import Timer
from pot import decode

@cocotb.test()
async def exhaustive_independent_shiftadd(dut):
    for mode in (0,1):
        dut.signed_mode.value=mode
        for a in range(256):
            dut.activation.value=a
            x=a-(256 if mode and a&128 else 0)
            for code in range(256):
                dut.weight_code.value=code
                await Timer(1,unit='ns')
                # Independent decode -> integer multiply oracle.
                assert int(dut.product.value)==(x*decode(code))&0x1ffff
