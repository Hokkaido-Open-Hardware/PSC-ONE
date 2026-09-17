# ===============================================================
#  NISHIHARU PSC_ONE_LCD cocotb TEST
# ===============================================================
import cocotb
from cocotb.triggers import Timer, RisingEdge, ReadOnly

CLK_NS = 10

I2S_ADDR_RX = 0x1000_7000
I2S_ADDR_ST = 0x1000_7004


# ------------------------------------------------
# clock
# ------------------------------------------------
async def gen_clock(dut):
    while True:
        dut.clock.value = 0
        await Timer(CLK_NS // 2, unit="ns")
        dut.clock.value = 1
        await Timer(CLK_NS // 2, unit="ns")


# ------------------------------------------------
# reset
# ------------------------------------------------
async def reset_dut(dut):
    dut.reset_n.value = 0
    dut.cpu_rvalid.value = 0
    dut.cpu_raddr.value = 0
    dut.cpu_rdata.value = 0

    for _ in range(10):
        await RisingEdge(dut.clock)

    dut.reset_n.value = 1

    for _ in range(10):
        await RisingEdge(dut.clock)

# ------------------------------------------------
# CPU MMIO read
# ------------------------------------------------
async def cpu_read(dut, addr, timeout=100):
    dut.cpu_raddr.value = addr

    dut.cpu_rvalid.value = 1
    await RisingEdge(dut.clock)
    dut.cpu_rvalid.value = 0

    for _ in range(timeout):
        await RisingEdge(dut.clock)
        await ReadOnly()

        if int(dut.cpu_rready.value) == 1:
            data = int(dut.cpu_rdata.value)
            break
    else:
        raise AssertionError(f"cpu_rready timeout addr=0x{addr:08x}")

    await RisingEdge(dut.clock)

    return data

# ------------------------------------------------
# TEST 1: reset / basic pins
# ------------------------------------------------
@cocotb.test()
async def mic_reset_test(dut):
    dut._log.info("==== PSC_ONE_LCD reset test start ====")

    cocotb.start_soon(gen_clock(dut))
    await reset_dut(dut)

    for _ in range(10000):
        await RisingEdge(dut.clock)

    value = await cpu_read(dut, I2S_ADDR_RX)
    value = await cpu_read(dut, I2S_ADDR_RX)

    dut._log.info(f"Read = 0x{value:08X}")

    raw = int(dut.u_mic_model.sample_l.value) + (1 << 8)

    # RTLに合わせる（24bitデータを上位から取り出す）
    model_value = (raw >> 8) & 0x00FFFFFF

    # 24bit -> 32bit 符号拡張
    if model_value & 0x00800000:
        model_value |= 0xFF000000

    model_value &= 0xFFFFFFFF

    assert value == model_value, \
        f"pix_waddr mismatch: got=0x{value:08X}, exp=0x{model_value:08X}"

    for _ in range(100):
        await RisingEdge(dut.clock)

    dut._log.info("==== PASS reset test ====")