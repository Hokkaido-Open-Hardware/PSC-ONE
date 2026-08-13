# ===============================================================
# NISHIHARU sim_sdram_controller TEST
# ===============================================================

import cocotb
from cocotb.triggers import Timer, RisingEdge, ReadOnly

CLK_NS = 12.5     # 80MHz


# ------------------------------------------------
# clock
# ------------------------------------------------
async def gen_clock(dut):
    while True:
        dut.clock.value = 0
        await Timer(CLK_NS / 2, unit="ns")

        dut.clock.value = 1
        await Timer(CLK_NS / 2, unit="ns")


# ------------------------------------------------
# wait SDRAM init
# ------------------------------------------------
async def wait_sdram_init(dut):

    dut._log.info("Waiting SDRAM initialization...")

    timeout = 100000

    for i in range(timeout):

        await RisingEdge(dut.clock)

        # sim_sdram_controller
        #   └─ u_sdram_controller
        #        └─ sdram_init_fin
        if int(dut.u_sdram_controller.sdram_init_fin.value) == 1:
            dut._log.info(
                f"SDRAM initialization finished. cycle={i}"
            )
            return

    assert False, "SDRAM initialization timeout"


# ------------------------------------------------
# SDRAM WRITE
# ------------------------------------------------
async def sdram_write(
    dut,
    bank,
    row,
    col,
    data
):

    dut._log.info(
        f"WRITE request "
        f"BA={bank} ROW=0x{row:03x} COL=0x{col:02x} "
        f"DATA=0x{data:04x}"
    )

    dut.write_addr_ba.value  = bank
    dut.write_addr_row.value = row
    dut.write_addr_col.value = col
    dut.write_data.value     = data

    dut.write_valid.value = 1

    timeout = 10000

    for _ in range(timeout):

        await RisingEdge(dut.clock)
        await ReadOnly()

        if int(dut.write_ready.value) == 1:
            break

    else:
        assert False, "WRITE timeout"

    # ReadOnly phase から抜ける
    await RisingEdge(dut.clock)

    dut.write_valid.value = 0

    dut._log.info("WRITE DONE")

    # 少し待つ
    for _ in range(10):
        await RisingEdge(dut.clock)


# ------------------------------------------------
# SDRAM READ
# ------------------------------------------------
async def sdram_read(
    dut,
    bank,
    row,
    col
):

    dut._log.info(
        f"READ request "
        f"BA={bank} ROW=0x{row:03x} COL=0x{col:02x}"
    )

    dut.read_addr_ba.value  = bank
    dut.read_addr_row.value = row
    dut.read_addr_col.value = col
    dut.read_valid.value    = 1

    timeout = 10000

    for _ in range(timeout):

        await RisingEdge(dut.clock)

        if int(dut.read_ready.value) == 1:

            data = int(dut.read_data.value)

            dut.read_valid.value = 0

            dut._log.info(
                f"READ DONE DATA=0x{data:04x}"
            )

            return data

    assert False, "READ timeout"

# ------------------------------------------------
# common init
# ------------------------------------------------
async def sdram_init(dut):

    cocotb.start_soon(gen_clock(dut))

    dut.reset_n.value = 0

    dut.rw_length.value = 1

    dut.read_valid.value = 0
    dut.read_addr_ba.value = 0
    dut.read_addr_row.value = 0
    dut.read_addr_col.value = 0

    dut.write_valid.value = 0
    dut.write_addr_ba.value = 0
    dut.write_addr_row.value = 0
    dut.write_addr_col.value = 0
    dut.write_data.value = 0

    for _ in range(10):
        await RisingEdge(dut.clock)

    dut.reset_n.value = 1

    dut._log.info("RESET RELEASE")

    await wait_sdram_init(dut)

# ------------------------------------------------
# SDRAM BURST WRITE
# ------------------------------------------------
async def sdram_burst_write(
    dut,
    bank,
    row,
    col,
    data_list
):

    length = len(data_list)

    assert length in (1, 4, 8)

    dut._log.info(
        f"BURST WRITE START "
        f"LEN={length} BA={bank} "
        f"ROW=0x{row:03x} COL=0x{col:02x}"
    )

    dut.rw_length.value      = length
    dut.write_addr_ba.value  = bank
    dut.write_addr_row.value = row
    dut.write_valid.value    = 1

    # --------------------------------------------
    # 1CLKごとに別COL / DATAを投入
    # --------------------------------------------
    for idx in range(length):

        dut.write_addr_col.value = col + idx
        dut.write_data.value     = data_list[idx]

        dut._log.info(
            f"BURST WRITE INPUT [{idx}] "
            f"COL=0x{col + idx:02x} "
            f"DATA=0x{data_list[idx]:04x}"
        )

        await RisingEdge(dut.clock)

    # 入力終了
    dut.write_valid.value = 0

    # controllerのburst処理完了待ち
    timeout = 10000

    for _ in range(timeout):

        await RisingEdge(dut.clock)

        # write_ready が実行中に立つ設計なので、
        # 最終的に state が WRITE_DONE -> IDLE へ戻るのを待つ
        if int(dut.u_sdram_controller.req_ready.value) == 1:
            break

    else:
        assert False, "BURST WRITE timeout"

    dut.rw_length.value = 1

    for _ in range(10):
        await RisingEdge(dut.clock)

    dut._log.info(
        f"BURST WRITE DONE LEN={length}"
    )

# ------------------------------------------------
# SDRAM BURST READ
# ------------------------------------------------
async def sdram_burst_read(
    dut,
    bank,
    row,
    col,
    length
):

    assert length in (1, 4, 8)

    dut._log.info(
        f"BURST READ START "
        f"LEN={length} BA={bank} "
        f"ROW=0x{row:03x} COL=0x{col:02x}"
    )

    dut.rw_length.value     = length
    dut.read_addr_ba.value  = bank
    dut.read_addr_row.value = row
    dut.read_valid.value    = 1

    # --------------------------------------------
    # 1CLKごとに別COLを投入
    # --------------------------------------------
    for idx in range(length):

        dut.read_addr_col.value = col + idx

        dut._log.info(
            f"BURST READ INPUT [{idx}] "
            f"COL=0x{col + idx:02x}"
        )

        await RisingEdge(dut.clock)

    dut.read_valid.value = 0

    # --------------------------------------------
    # read_readyごとに結果取得
    # --------------------------------------------
    result = []

    timeout = 10000

    for _ in range(timeout):

        await RisingEdge(dut.clock)

        if int(dut.read_ready.value) == 1:

            data = int(dut.read_data.value)

            result.append(data)

            dut._log.info(
                f"BURST READ [{len(result)-1}] "
                f"= 0x{data:04x}"
            )

            if len(result) >= length:
                break

    else:
        assert False, "BURST READ timeout"

    dut.rw_length.value = 1

    dut._log.info(
        f"BURST READ DONE LEN={length}"
    )

    return result
    

# ------------------------------------------------
# TEST
# ------------------------------------------------
@cocotb.test()
async def sdram_test1(dut):

    dut._log.info(
        "==== sim_sdram_controller TEST START ===="
    )

    # clock start
    cocotb.start_soon(gen_clock(dut))

    # ------------------------------------------------
    # initial value
    # ------------------------------------------------

    dut.reset_n.value = 0

    dut.read_valid.value = 0
    dut.read_addr_ba.value = 0
    dut.read_addr_row.value = 0
    dut.read_addr_col.value = 0

    dut.write_valid.value = 0
    dut.write_addr_ba.value = 0
    dut.write_addr_row.value = 0
    dut.write_addr_col.value = 0
    dut.write_data.value = 0

    dut.rw_length.value = 1

    # ------------------------------------------------
    # reset
    # ------------------------------------------------

    for _ in range(10):
        await RisingEdge(dut.clock)

    dut.reset_n.value = 1

    dut._log.info("RESET RELEASE")

    # ------------------------------------------------
    # wait SDRAM initialization
    # ------------------------------------------------

    await wait_sdram_init(dut)

    # ------------------------------------------------
    # TEST 1
    # ------------------------------------------------

    test_bank = 0
    test_row  = 0x001
    test_col  = 0x10

    test_data = 0x1234

    # WRITE
    await sdram_write(
        dut,
        test_bank,
        test_row,
        test_col,
        test_data
    )

    # READ
    read_data = await sdram_read(
        dut,
        test_bank,
        test_row,
        test_col
    )

    # CHECK
    assert read_data == test_data, \
        (
            f"Mismatch!\n"
            f"READ = 0x{read_data:04x}\n"
            f"EXP  = 0x{test_data:04x}"
        )

    dut._log.info(
        "==== TEST1 PASS ===="
    )


    # ------------------------------------------------
    # TEST 2
    # 別アドレス
    # ------------------------------------------------

    test_bank = 1
    test_row  = 0x012
    test_col  = 0x20

    test_data = 0xA5A5

    await sdram_write(
        dut,
        test_bank,
        test_row,
        test_col,
        test_data
    )

    read_data = await sdram_read(
        dut,
        test_bank,
        test_row,
        test_col
    )

    assert read_data == test_data, \
        (
            f"Mismatch!\n"
            f"READ = 0x{read_data:04x}\n"
            f"EXP  = 0x{test_data:04x}"
        )

    dut._log.info(
        "==== TEST2 PASS ===="
    )


    # ------------------------------------------------
    # TEST 3
    # 0xFFFF
    # ------------------------------------------------

    test_bank = 2
    test_row  = 0x100
    test_col  = 0x40

    test_data = 0xFFFF

    await sdram_write(
        dut,
        test_bank,
        test_row,
        test_col,
        test_data
    )

    read_data = await sdram_read(
        dut,
        test_bank,
        test_row,
        test_col
    )

    assert read_data == test_data, \
        (
            f"Mismatch!\n"
            f"READ = 0x{read_data:04x}\n"
            f"EXP  = 0x{test_data:04x}"
        )

    dut._log.info(
        "==== TEST3 PASS ===="
    )

    dut._log.info(
        "==== sim_sdram_controller ALL PASS ===="
    )

    # ------------------------------------------------
    # TEST 4
    # 0x0000
    # ------------------------------------------------

    test_bank = 3
    test_row  = 0x055
    test_col  = 0x7F

    test_data = 0x0000

    await sdram_write(
        dut,
        test_bank,
        test_row,
        test_col,
        test_data
    )

    read_data = await sdram_read(
        dut,
        test_bank,
        test_row,
        test_col
    )

    assert read_data == test_data, \
        (
            f"Mismatch!\n"
            f"READ = 0x{read_data:04x}\n"
            f"EXP  = 0x{test_data:04x}"
        )

    dut._log.info(
        "==== TEST4 PASS ===="
    )


    # ------------------------------------------------
    # TEST 5
    # alternating pattern
    # ------------------------------------------------

    test_bank = 0
    test_row  = 0x200
    test_col  = 0x01

    test_data = 0xAAAA

    await sdram_write(
        dut,
        test_bank,
        test_row,
        test_col,
        test_data
    )

    read_data = await sdram_read(
        dut,
        test_bank,
        test_row,
        test_col
    )

    assert read_data == test_data

    dut._log.info(
        "==== TEST5 PASS ===="
    )


    # ------------------------------------------------
    # TEST 6
    # inverse alternating pattern
    # ------------------------------------------------

    test_bank = 0
    test_row  = 0x200
    test_col  = 0x02

    test_data = 0x5555

    await sdram_write(
        dut,
        test_bank,
        test_row,
        test_col,
        test_data
    )

    read_data = await sdram_read(
        dut,
        test_bank,
        test_row,
        test_col
    )

    assert read_data == test_data

    dut._log.info(
        "==== TEST6 PASS ===="
    )


    # ------------------------------------------------
    # TEST 7
    # walking 1
    # ------------------------------------------------

    test_bank = 1
    test_row  = 0x300

    for bit in range(16):

        test_col  = bit
        test_data = 1 << bit

        await sdram_write(
            dut,
            test_bank,
            test_row,
            test_col,
            test_data
        )

        read_data = await sdram_read(
            dut,
            test_bank,
            test_row,
            test_col
        )

        assert read_data == test_data, \
            (
                f"WALK1 mismatch bit={bit}\n"
                f"READ = 0x{read_data:04x}\n"
                f"EXP  = 0x{test_data:04x}"
            )

    dut._log.info(
        "==== TEST7 WALKING-1 PASS ===="
    )


    # ------------------------------------------------
    # TEST 8
    # walking 0
    # ------------------------------------------------

    test_bank = 2
    test_row  = 0x301

    for bit in range(16):

        test_col  = bit
        test_data = 0xFFFF ^ (1 << bit)

        await sdram_write(
            dut,
            test_bank,
            test_row,
            test_col,
            test_data
        )

        read_data = await sdram_read(
            dut,
            test_bank,
            test_row,
            test_col
        )

        assert read_data == test_data, \
            (
                f"WALK0 mismatch bit={bit}\n"
                f"READ = 0x{read_data:04x}\n"
                f"EXP  = 0x{test_data:04x}"
            )

    dut._log.info(
        "==== TEST8 WALKING-0 PASS ===="
    )


    # ------------------------------------------------
    # TEST 9
    # same row, sequential columns
    # ------------------------------------------------

    test_bank = 0
    test_row  = 0x123

    seq_data = [
        0x1001,
        0x2002,
        0x3003,
        0x4004,
        0x5005,
        0x6006,
        0x7007,
        0x8008
    ]

    # WRITE
    for col, data in enumerate(seq_data):

        await sdram_write(
            dut,
            test_bank,
            test_row,
            col,
            data
        )

    # READ CHECK
    for col, expected in enumerate(seq_data):

        read_data = await sdram_read(
            dut,
            test_bank,
            test_row,
            col
        )

        assert read_data == expected, \
            (
                f"SEQ mismatch COL={col}\n"
                f"READ = 0x{read_data:04x}\n"
                f"EXP  = 0x{expected:04x}"
            )

    dut._log.info(
        "==== TEST9 SEQUENTIAL COLUMN PASS ===="
    )


    # ------------------------------------------------
    # TEST 10
    # same column, different rows
    # ------------------------------------------------

    test_bank = 1
    test_col  = 0x20

    row_data = [
        (0x010, 0x1111),
        (0x011, 0x2222),
        (0x012, 0x3333),
        (0x013, 0x4444)
    ]

    for row, data in row_data:

        await sdram_write(
            dut,
            test_bank,
            row,
            test_col,
            data
        )

    for row, expected in row_data:

        read_data = await sdram_read(
            dut,
            test_bank,
            row,
            test_col
        )

        assert read_data == expected, \
            (
                f"ROW mismatch ROW=0x{row:03x}\n"
                f"READ = 0x{read_data:04x}\n"
                f"EXP  = 0x{expected:04x}"
            )

    dut._log.info(
        "==== TEST10 ROW SWITCH PASS ===="
    )


    # ------------------------------------------------
    # TEST 11
    # same row/column, different banks
    # ------------------------------------------------

    test_row = 0x077
    test_col = 0x33

    bank_data = [
        (0, 0x0A0A),
        (1, 0x1B1B),
        (2, 0x2C2C),
        (3, 0x3D3D)
    ]

    for bank, data in bank_data:

        await sdram_write(
            dut,
            bank,
            test_row,
            test_col,
            data
        )

    for bank, expected in bank_data:

        read_data = await sdram_read(
            dut,
            bank,
            test_row,
            test_col
        )

        assert read_data == expected, \
            (
                f"BANK mismatch BANK={bank}\n"
                f"READ = 0x{read_data:04x}\n"
                f"EXP  = 0x{expected:04x}"
            )

    dut._log.info(
        "==== TEST11 BANK SELECT PASS ===="
    )


    # ------------------------------------------------
    # TEST 12
    # overwrite same address
    # ------------------------------------------------

    test_bank = 2
    test_row  = 0x321
    test_col  = 0x55

    overwrite_data = [
        0x1234,
        0xABCD,
        0x0000,
        0xFFFF,
        0x55AA
    ]

    for expected in overwrite_data:

        await sdram_write(
            dut,
            test_bank,
            test_row,
            test_col,
            expected
        )

        read_data = await sdram_read(
            dut,
            test_bank,
            test_row,
            test_col
        )

        assert read_data == expected, \
            (
                f"OVERWRITE mismatch\n"
                f"READ = 0x{read_data:04x}\n"
                f"EXP  = 0x{expected:04x}"
            )

    dut._log.info(
        "==== TEST12 OVERWRITE PASS ===="
    )


    # ------------------------------------------------
    # TEST 13
    # pseudo random address/data
    # ------------------------------------------------

    import random

    random.seed(12345)

    random_tests = []

    for _ in range(32):

        bank = random.randrange(0, 4)
        row  = random.randrange(0, 1 << 11)
        col  = random.randrange(0, 1 << 8)
        data = random.randrange(0, 1 << 16)

        random_tests.append(
            (bank, row, col, data)
        )

    # WRITE
    for bank, row, col, data in random_tests:

        await sdram_write(
            dut,
            bank,
            row,
            col,
            data
        )

    # READ CHECK
    for bank, row, col, expected in random_tests:

        read_data = await sdram_read(
            dut,
            bank,
            row,
            col
        )

        assert read_data == expected, \
            (
                f"RANDOM mismatch "
                f"BA={bank} ROW=0x{row:03x} COL=0x{col:02x}\n"
                f"READ = 0x{read_data:04x}\n"
                f"EXP  = 0x{expected:04x}"
            )

    dut._log.info(
        "==== TEST13 RANDOM PASS ===="
    )


    dut._log.info(
        "==== sim_sdram_controller ALL PASS ===="
    )

# ==============================================================
# TEST 14
# BURST LENGTH = 4
# ==============================================================
@cocotb.test()
async def sdram_test14_burst4(dut):

    dut._log.info(
        "==== TEST14 BURST4 START ===="
    )

    await sdram_init(dut)

    burst_data = [
        0x1111,
        0x2222,
        0x3333,
        0x4444
    ]

    await sdram_burst_write(
        dut,
        bank=0,
        row=0x400,
        col=0x20,
        data_list=burst_data
    )

    read_data = await sdram_burst_read(
        dut,
        bank=0,
        row=0x400,
        col=0x20,
        length=4
    )

    assert read_data == burst_data, \
        (
            f"BURST4 mismatch\n"
            f"READ={read_data}\n"
            f"EXP ={burst_data}"
        )

    dut._log.info(
        "==== TEST14 BURST4 PASS ===="
    )


# ==============================================================
# TEST 15
# BURST LENGTH = 8
# ==============================================================
@cocotb.test()
async def sdram_test15_burst8(dut):

    dut._log.info(
        "==== TEST15 BURST8 START ===="
    )

    await sdram_init(dut)

    burst_data = [
        0x1001,
        0x2002,
        0x3003,
        0x4004,
        0x5005,
        0x6006,
        0x7007,
        0x8008
    ]

    await sdram_burst_write(
        dut,
        bank=1,
        row=0x401,
        col=0x40,
        data_list=burst_data
    )

    read_data = await sdram_burst_read(
        dut,
        bank=1,
        row=0x401,
        col=0x40,
        length=8
    )

    assert read_data == burst_data, \
        (
            f"BURST8 mismatch\n"
            f"READ={read_data}\n"
            f"EXP ={burst_data}"
        )

    dut._log.info(
        "==== TEST15 BURST8 PASS ===="
    )


# ==============================================================
# TEST 16
# REFRESH LONG RUN
# ==============================================================
@cocotb.test()
async def sdram_test16_refresh(dut):

    dut._log.info(
        "==== TEST16 REFRESH START ===="
    )

    await sdram_init(dut)

    refresh_test = [
        (0, 0x500, 0x10, 0x1357),
        (1, 0x501, 0x20, 0x2468),
        (2, 0x502, 0x30, 0xAAAA),
        (3, 0x503, 0x40, 0x5555),
    ]

    # WRITE
    for bank, row, col, data in refresh_test:

        await sdram_write(
            dut,
            bank,
            row,
            col,
            data
        )

    dut._log.info(
        "Waiting 500us for refresh..."
    )

    # 80MHz × 40000CLK = 500us
    for _ in range(40000):
        await RisingEdge(dut.clock)

    # READ CHECK
    for bank, row, col, expected in refresh_test:

        read_data = await sdram_read(
            dut,
            bank,
            row,
            col
        )

        assert read_data == expected, \
            (
                f"REFRESH mismatch "
                f"BA={bank} "
                f"ROW=0x{row:03x} "
                f"COL=0x{col:02x}\n"
                f"READ=0x{read_data:04x}\n"
                f"EXP =0x{expected:04x}"
            )

    dut._log.info(
        "==== TEST16 REFRESH PASS ===="
    )


# ==============================================================
# TEST 17
# ACCESS WHILE REFRESHING
# ==============================================================
@cocotb.test()
async def sdram_test17_refresh_access(dut):

    import random

    dut._log.info(
        "==== TEST17 REFRESH + ACCESS START ===="
    )

    await sdram_init(dut)

    random.seed(777)

    reference = {}

    # WRITEしながら時間を進める
    for _ in range(128):

        bank = random.randrange(0, 4)
        row  = random.randrange(0, 1 << 11)
        col  = random.randrange(0, 1 << 8)
        data = random.randrange(0, 1 << 16)

        await sdram_write(
            dut,
            bank,
            row,
            col,
            data
        )

        reference[(bank, row, col)] = data

        # refreshが割り込む機会を作る
        for _ in range(100):
            await RisingEdge(dut.clock)

    # READ BACK
    for (bank, row, col), expected in reference.items():

        read_data = await sdram_read(
            dut,
            bank,
            row,
            col
        )

        assert read_data == expected, \
            (
                f"REFRESH ACCESS mismatch "
                f"BA={bank} "
                f"ROW=0x{row:03x} "
                f"COL=0x{col:02x}\n"
                f"READ=0x{read_data:04x}\n"
                f"EXP =0x{expected:04x}"
            )

    dut._log.info(
        "==== TEST17 REFRESH + ACCESS PASS ===="
    )