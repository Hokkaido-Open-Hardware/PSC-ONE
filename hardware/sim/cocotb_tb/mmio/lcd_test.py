# ===============================================================
#  NISHIHARU PSC_ONE_LCD cocotb TEST
# ===============================================================
import cocotb
from cocotb.triggers import Timer, RisingEdge, ReadOnly

CLK_NS = 10

LCD_PIXS_DATA = 0x1000_3000
LCD_PIXS_ST   = 0x1000_3004


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
    dut.cpu_wvalid.value = 0
    dut.cpu_raddr.value = 0
    dut.cpu_waddr.value = 0
    dut.cpu_wdata.value = 0

    for _ in range(10):
        await RisingEdge(dut.clock)

    dut.reset_n.value = 1

    for _ in range(10):
        await RisingEdge(dut.clock)


# ------------------------------------------------
# CPU MMIO write
# ------------------------------------------------
async def cpu_write(dut, addr, data, timeout=100):
    dut.cpu_waddr.value = addr
    dut.cpu_wdata.value = data

    dut.cpu_wvalid.value = 1
    await RisingEdge(dut.clock)
    dut.cpu_wvalid.value = 0

    for _ in range(timeout):
        await RisingEdge(dut.clock)
        await ReadOnly()

        if int(dut.cpu_wready.value) == 1:
            #dut._log.info(f"CPU WRITE addr=0x{addr:08x} data=0x{data:08x}")
            break
    else:
        raise AssertionError(f"cpu_wready timeout addr=0x{addr:08x}")

    await RisingEdge(dut.clock)
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
            cpu_read_data = int(dut.cpu_rdata.value)

            '''
            dut._log.info(
                f"CPU READ addr=0x{addr:08x} "
                f"data=0x{cpu_read_data:08x}"
            )
            '''

            await RisingEdge(dut.clock)
            return cpu_read_data

    raise AssertionError(
        f"cpu_rready timeout addr=0x{addr:08x}"
    )

# ------------------------------------------------
# wait_status_bit_set
# ------------------------------------------------
async def wait_status_bit_set(
    dut,
    address: int,
    mask: int,
    timeout: int = 5_000_000,
) -> int:
    """指定されたステータスビットが1になるまで待つ。"""
    for _ in range(timeout):
        st = await cpu_read(dut, address)

        if st & mask:
            return st

        await RisingEdge(dut.clock)

    raise TimeoutError(
        f"Status timeout: address=0x{address:08X}, "
        f"mask=0x{mask:08X}, timeout={timeout}"
    )


# ------------------------------------------------
# tft write
# ------------------------------------------------
async def tft_write(dut, data, tft_reset=1, wait=500):

    dut.cpu_waddr.value = LCD_PIXS_DATA
    dut.cpu_wdata.value = data

    await cpu_write(dut, LCD_PIXS_DATA, data)
    await cpu_write(dut, LCD_PIXS_ST, 0x01 | (tft_reset<<1))

    for _ in range(wait):
        await RisingEdge(dut.clock)


# ------------------------------------------------
# tft init sequence
# ------------------------------------------------
async def tft_init_seq(dut, timeout=100):

    for _ in range(5000):
        await RisingEdge(dut.clock)

    # Software Reset
    # NOP
    await cpu_write(dut, LCD_PIXS_ST, 0x00 | (0x00<<1))

    for _ in range(5000):
        await RisingEdge(dut.clock)

    # NOP
    await cpu_write(dut, LCD_PIXS_ST, 0x00 | (0x01<<1))

    for _ in range(1000):
        await RisingEdge(dut.clock)

    # Software Reset
    await tft_write(dut, 0x101)

    # NOP
    await tft_write(dut, 0x000)

    # Pixel Format = RGB666
    await tft_write(dut, 0x03A)
    await tft_write(dut, 0x166)

    # Memory Access Control
    await tft_write(dut, 0x036)
    await tft_write(dut, 0x1C8)

    # Sleep Out
    await tft_write(dut, 0x011)

    # Display ON
    await tft_write(dut, 0x029)

    for _ in range(5000):
        await RisingEdge(dut.clock)


# ------------------------------------------------
# tft write pix data settiing
# ------------------------------------------------
async def tft_wire_pix_setting(dut, x_start, y_start, wait=500):

    x_end = x_start + 31
    y_end = y_start + 31

    # Column Address Set
    await tft_write(dut, 0x029)
    await tft_write(dut, 0x100 | ((x_start & 0x1FF) >> 8))
    await tft_write(dut, 0x100 | (x_start & 0xFF))
    await tft_write(dut, 0x100 | ((x_end & 0x1FF) >> 8))
    await tft_write(dut, 0x100 | (x_end & 0xFF))

    # Row Address Set
    await tft_write(dut, 0x02B)
    await tft_write(dut, 0x100 | ((y_start & 0x1FF) >> 8))
    await tft_write(dut, 0x100 | (y_start & 0xFF))
    await tft_write(dut, 0x100 | ((y_end & 0x1FF) >> 8))
    await tft_write(dut, 0x100 | (y_end & 0xFF))

    # Memory Write
    await tft_write(dut, 0x02C)


# ------------------------------------------------
# TEST 1: reset / basic pins
# ------------------------------------------------
@cocotb.test()
async def lcd_reset_test(dut):
    dut._log.info("==== PSC_ONE_LCD reset test start ====")

    cocotb.start_soon(gen_clock(dut))
    await reset_dut(dut)

    for _ in range(2000):
        await RisingEdge(dut.clock)

    await cpu_write(dut, LCD_PIXS_DATA, 0x1234)
    await cpu_write(dut, LCD_PIXS_DATA, 0x2345)

    await cpu_write(dut, LCD_PIXS_ST, 0x01)
    await cpu_write(dut, LCD_PIXS_ST, 0x00)
    
    await cpu_read(dut, LCD_PIXS_ST)

    for _ in range(20):
        await RisingEdge(dut.clock)

    assert int(dut.cpu_wready.value) == 0

    dut._log.info(f"tft_cs    = {dut.PSCONE_LCD_CS.value}")
    dut._log.info(f"tft_dc    = {dut.PSCONE_LCD_DC.value}")
    dut._log.info(f"tft_sck   = {dut.PSCONE_LCD_SCK.value}")
    dut._log.info(f"tft_sdi   = {dut.PSCONE_LCD_SDI.value}")
    dut._log.info(f"tft_reset = {dut.PSCONE_LCD_RST.value}")

    for _ in range(500):
        await RisingEdge(dut.clock)

    dut._log.info("==== PASS reset test ====")

# ------------------------------------------------
# TEST 2: invalid address should not assert ready
# ------------------------------------------------
@cocotb.test()
async def lcd_invalid_addr_test(dut):
    dut._log.info("==== PSC_ONE_LCD invalid address test start ====")

    cocotb.start_soon(gen_clock(dut))
    await reset_dut(dut)

    for _ in range(2000):
        await RisingEdge(dut.clock)

    await cpu_write(dut, LCD_PIXS_ST, 0x01)
    await cpu_write(dut, LCD_PIXS_ST, 0x00)

    for _ in range(20):
        await RisingEdge(dut.clock)

    dut.cpu_waddr.value = 0x1000_3010
    dut.cpu_wdata.value = 0x12345678
    dut.cpu_wvalid.value = 1

    ready_seen = False

    for _ in range(20):
        await RisingEdge(dut.clock)
        await ReadOnly()
        if int(dut.cpu_wready.value) == 1:
            ready_seen = True

    await RisingEdge(dut.clock)
    dut.cpu_wvalid.value = 0

    assert ready_seen is False, "cpu_wready asserted for invalid address"

    dut._log.info("==== PASS invalid address test ====")

    for _ in range(2000):
        await RisingEdge(dut.clock)

# ------------------------------------------------
# TEST 3: color pattern sanity check
# ------------------------------------------------
@cocotb.test()
async def lcd_color_pattern_test(dut):
    dut._log.info("==== PSC_ONE_LCD color pattern test start ====")

    cocotb.start_soon(gen_clock(dut))
    await reset_dut(dut)

    # tft_init_start
    await tft_init_seq(dut)

    # tft write pix data setting
    await tft_wire_pix_setting(dut, 0, 0)

    # tft write pix data 
    for y in range(32):
        for x in range(32):
            await tft_write(dut, (x & 0xFF), wait=200)

    dut._log.info("==== PASS color pattern test ====")

    for _ in range(2000):
        await RisingEdge(dut.clock)
