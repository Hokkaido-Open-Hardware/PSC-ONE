# test_systolic_driver_2x2.py

import os
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
import numpy as np

BASE_ADDR_A = 0x02000
BASE_ADDR_B = 0x04000
BASE_ADDR_C = 0x08000

# ------------------------------
# formatting
# ------------------------------

def section(title):
    bar = "═" * len(title)
    return f"\n╔{bar}╗\n║{title}║\n╚{bar}╝"

def fmt_mat(name, mat):
    return f"{name} =\n{np.array(mat, dtype=int)}"

def fmt_list(lst):
    return "[" + " ".join(f"{v:>5d}" for v in lst) + "]"

# ------------------------------
# python model (2x2)
# ------------------------------

def python_systolic_model(A,B):
    A = np.array(A,dtype=int)
    B = np.array(B,dtype=int)

    C = np.zeros((N,N),dtype=int)

    for i in range(N):
        for j in range(N):
            C[i,j] = int(sum(A[i,k]*B[k,j] for k in range(N)))

    return C

# ------------------------------
# memory_driver
# ------------------------------

async def memory_driver(dut, mem, dump=False):
    pending = False
    pending_addr = 0

    while True:
        await RisingEdge(dut.clock)

        # デフォルトは応答なし
        dut.rd_read_ready.value = 0
        dut.c_write_ready.value = 0

        # --------------------------------
        # READ response
        # 1クロック遅延で応答
        # --------------------------------
        if pending:
            dut.rd_read_data.value = mem.get(pending_addr, 0)
            dut.rd_read_ready.value = 1
            pending = False

        # 新しいREAD要求を受け付ける
        if int(dut.rd_read_valid.value):
            pending_addr = int(dut.rd_read_addr.value)
            pending = True

        # --------------------------------
        # WRITE
        # --------------------------------
        if int(dut.c_write_valid.value):
            addr = int(dut.c_write_addr.value)
            data = int(dut.c_write_wdata.value)

            mem[addr] = data
            dut.c_write_ready.value = 1

            if dump==True:
                dut._log.info(
                    f"MEM WRITE addr=0x{addr:08X} "
                    f"data=0x{data:08X}"
                )

# ------------------------------
# packing helpers
# ------------------------------

def pack_u8x4(values):
    assert len(values) == 4

    return sum(
        (int(value) & 0xFF) << (8 * index)
        for index, value in enumerate(values)
    )

def unpack_frame_to_list(frame):
    c0 = (frame >> 0) & 0xFFFF
    c1 = (frame >> 16) & 0xFFFF
    return [c0,c1]

async def dump_mem(dut, mem, MATRIX_N):
    dut._log.info(section("Memory A"))

    for i in range(MATRIX_N):
        addr = BASE_ADDR_A + 4 * i

        if addr in mem:
            dut._log.info(
                f"A[{i}]  addr=0x{addr:08X}  data=0x{mem[addr]:08X}"
            )

    dut._log.info(section("Memory B"))

    for i in range(MATRIX_N):
        addr = BASE_ADDR_B + 4 * i

        if addr in mem:
            dut._log.info(
                f"B[{i}]  addr=0x{addr:08X}  data=0x{mem[addr]:08X}"
            )

    dut._log.info(section("Memory C"))

    for i in range(MATRIX_N * MATRIX_N):
        addr = BASE_ADDR_C + 4 * i

        if addr in mem:
            dut._log.info(
                f"C[{i}]  addr=0x{addr:08X}  data=0x{mem[addr]:08X}"
            )


# ------------------------------
# main test
# ------------------------------

# =============================================
# 1st test
# =============================================
@cocotb.test()
async def test_systolic_array_driver_4x4(dut):

    dut._log.info("=============================================")

    # ==================
    MATRIX_N = 4
    CYCLE_N  = 2
    dut.matrix_size_x.value  = 4
    dut.matrix_size_y.value  = 4
    # ==================

    clock = Clock(dut.clock,10,unit="ns")
    cocotb.start_soon(clock.start())

    # reset
    dut.reset_n.value       = 0
    dut.sa_clear.value      = 0
    dut.rd_read_ready.value = 0
    dut.sa_state_reset.value = 0
    dut.sa_req_ready.value  = 1

    # mode
    dut.sa_os_instruction.value = 0b0000

    dut.BASE_ADDR_A.value = BASE_ADDR_A
    dut.BASE_ADDR_B.value = BASE_ADDR_B
    dut.BASE_ADDR_C.value = BASE_ADDR_C

    # start
    dut.start.value = 0

    for _ in range(5):
        await RisingEdge(dut.clock)

    dut.reset_n.value = 1

    for _ in range(5):
        await RisingEdge(dut.clock)

    # ------------------------------
    # generate matrices
    # ------------------------------

    A_np = np.random.randint(1,10,(MATRIX_N,MATRIX_N))
    B_np = np.random.randint(1,10,(MATRIX_N,MATRIX_N))
    
    dut._log.info(section("Memory A"))
    dut._log.info(fmt_mat("A_np",A_np))
    
    dut._log.info(section("Memory B"))
    dut._log.info(fmt_mat("B_np",B_np))

    C_expected_blocks = np.zeros((MATRIX_N, MATRIX_N), dtype=int)
    dut._log.info(section("Memory C"))
    dut._log.info(fmt_mat("Memory C",C_expected_blocks))

    # ------------------------------
    # memory model
    # ------------------------------

    mem = {}

    # A: 4×4、1行 = 32bit
    for row in range(4):
        mem[BASE_ADDR_A + row * 4] = pack_u8x4([
            A_np[row][0],
            A_np[row][1],
            A_np[row][2],
            A_np[row][3],
        ])

    # B: 4×4、1行 = 32bit
    for row in range(4):
        mem[BASE_ADDR_B + row * 4] = pack_u8x4([
            B_np[row][0],
            B_np[row][1],
            B_np[row][2],
            B_np[row][3],
        ])

    # C
    for i in range(MATRIX_N*MATRIX_N):
        mem[BASE_ADDR_C + 4*i] = 0

    cocotb.start_soon(memory_driver(dut, mem))

    # ------------------------------
    # start DUT
    # ------------------------------

    dut.start.value = 1
    await RisingEdge(dut.clock)
    dut.start.value = 0

    outputs = []
    prev_valid = 0

    timeout = 2000

    for _ in range(timeout):
        if dut.done.value == 1:
            break
        await RisingEdge(dut.clock)

    # ------------------------------
    # assemble matrix
    # ------------------------------

    # dump
    await dump_mem(dut, mem, MATRIX_N)

    # Assert
    C_dut = np.zeros((MATRIX_N,MATRIX_N), dtype=int)

    for row in range(MATRIX_N):
        for col in range(MATRIX_N):
            addr = BASE_ADDR_C + (row * MATRIX_N + col) * 4
            word = mem[addr]

            # 演算結果が16bitの場合
            C_dut[row, col] = word & 0xFFFF

    # ------------------------------
    # result
    # ------------------------------

    for _ in range(10):
        await RisingEdge(dut.clock)

    C_exp = (
        A_np
        @ B_np
    )

    C_hw = C_dut

    dut._log.info(section("assert"))

    dut._log.info(fmt_mat("Expected",C_exp))
    dut._log.info(fmt_mat("HW",C_hw))

    assert np.array_equal(C_hw, C_exp)

    dut._log.info("✅ PASS")

    for _ in range(100):
        await RisingEdge(dut.clock)

# =============================================
# 2nd test
# =============================================
@cocotb.test()
async def test_systolic_array_driver_8x8(dut):

    dut._log.info("\n")
    dut._log.info("=============================================")

    # ==================
    MATRIX_N = 8
    CYCLE_N  = 2
    dut.matrix_size_x.value  = 8
    dut.matrix_size_y.value  = 8
    # ==================

    clock = Clock(dut.clock,10,unit="ns")
    cocotb.start_soon(clock.start())

    # reset
    dut.reset_n.value       = 0
    dut.sa_clear.value      = 0
    dut.rd_read_ready.value = 0
    dut.sa_state_reset.value = 0
    dut.sa_req_ready.value  = 1

    # mode
    dut.sa_os_instruction.value = 0b0000

    dut.BASE_ADDR_A.value = BASE_ADDR_A
    dut.BASE_ADDR_B.value = BASE_ADDR_B
    dut.BASE_ADDR_C.value = BASE_ADDR_C

    # start
    dut.start.value = 0

    for _ in range(5):
        await RisingEdge(dut.clock)

    dut.reset_n.value = 1

    for _ in range(5):
        await RisingEdge(dut.clock)

    # ------------------------------
    # generate matrices
    # ------------------------------

    A_np = np.random.randint(1,10,(MATRIX_N,MATRIX_N))
    B_np = np.random.randint(1,10,(MATRIX_N,MATRIX_N))
    
    dut._log.info(section("Memory A"))
    dut._log.info(fmt_mat("A_np",A_np))
    
    dut._log.info(section("Memory B"))
    dut._log.info(fmt_mat("B_np",B_np))

    C_expected_blocks = np.zeros((MATRIX_N, MATRIX_N), dtype=int)
    dut._log.info(section("Memory C"))
    dut._log.info(fmt_mat("Memory C",C_expected_blocks))

    # ------------------------------
    # memory model
    # ------------------------------

    mem = {}

    # A: 8×8、1行 = 2×32bit
    for row in range(8):
        # A[row][0:4]
        mem[BASE_ADDR_A + row * 8 + 0x00] = pack_u8x4([
            A_np[row][0],
            A_np[row][1],
            A_np[row][2],
            A_np[row][3],
        ])

        # A[row][4:8]
        mem[BASE_ADDR_A + row * 8 + 0x04] = pack_u8x4([
            A_np[row][4],
            A_np[row][5],
            A_np[row][6],
            A_np[row][7],
        ])

    # B: 8×8、1行 = 2×32bit
    for row in range(8):
        # A[row][0:4]
        mem[BASE_ADDR_B + row * 8 + 0x00] = pack_u8x4([
            B_np[row][0],
            B_np[row][1],
            B_np[row][2],
            B_np[row][3],
        ])

        # A[row][4:8]
        mem[BASE_ADDR_B + row * 8 + 0x04] = pack_u8x4([
            B_np[row][4],
            B_np[row][5],
            B_np[row][6],
            B_np[row][7],
        ])


    # C
    for i in range(MATRIX_N*MATRIX_N):
        mem[BASE_ADDR_C + 4*i] = 0

    cocotb.start_soon(memory_driver(dut, mem))

    # ------------------------------
    # start DUT
    # ------------------------------

    dut.start.value = 1
    await RisingEdge(dut.clock)
    dut.start.value = 0

    outputs = []
    prev_valid = 0

    timeout = 5000

    for _ in range(timeout):
        if dut.done.value == 1:
            break
        await RisingEdge(dut.clock)

    # ------------------------------
    # assemble matrix
    # ------------------------------

    # dump
    await dump_mem(dut, mem, MATRIX_N*2)

    # Assert
    C_dut = np.zeros((MATRIX_N,MATRIX_N), dtype=int)

    # C_dut
    for r in range(MATRIX_N):
        for c in range(MATRIX_N):
            offset = (r * MATRIX_N + c) * 4
            word = mem[BASE_ADDR_C + offset]
            C_dut[r, c] = word & 0xFFFF

    dut._log.info(section("assert"))

    C_exp = (
        A_np[0:MATRIX_N, 0:MATRIX_N]
        @ B_np[0:MATRIX_N, 0:MATRIX_N]
    )

    C_hw = C_dut[0:MATRIX_N, 0:MATRIX_N]

    for _ in range(100):
        await RisingEdge(dut.clock)

    dut._log.info(fmt_mat("Expected",C_exp))
    dut._log.info(fmt_mat("HW",C_hw))

    assert np.array_equal(C_hw, C_exp)

    dut._log.info("✅ PASS")

# =============================================
# 3rd test
# =============================================
@cocotb.test()
async def test_systolic_array_driver_32x32(dut):

    dut._log.info("\n")
    dut._log.info("=============================================")

    # ==================
    MATRIX_N = 32
    WORDS_PER_ROW = MATRIX_N // 4
    dut.matrix_size_x.value = MATRIX_N
    dut.matrix_size_y.value = MATRIX_N
    # ==================

    clock = Clock(dut.clock, 10, unit="ns")
    cocotb.start_soon(clock.start())

    # reset
    dut.reset_n.value = 0
    dut.sa_clear.value = 0
    dut.rd_read_ready.value = 0
    dut.c_write_ready.value = 0
    dut.sa_state_reset.value = 0
    dut.sa_req_ready.value = 1

    # mode
    dut.sa_os_instruction.value = 0b0000

    dut.BASE_ADDR_A.value = BASE_ADDR_A
    dut.BASE_ADDR_B.value = BASE_ADDR_B
    dut.BASE_ADDR_C.value = BASE_ADDR_C

    dut.start.value = 0

    for _ in range(5):
        await RisingEdge(dut.clock)

    dut.reset_n.value = 1

    for _ in range(5):
        await RisingEdge(dut.clock)

    # ------------------------------
    # generate deterministic matrices
    # ------------------------------
    rng = np.random.default_rng(0x3232)

    A_np = rng.integers(
        1, 10, size=(MATRIX_N, MATRIX_N), dtype=np.uint8
    )
    B_np = rng.integers(
        1, 10, size=(MATRIX_N, MATRIX_N), dtype=np.uint8
    )

    # Python/NumPy reference.
    # uint8のまま積和すると型の影響を受ける可能性があるため、
    # 明示的に64bitへ拡張する。
    C_exp = (
        A_np.astype(np.int64)
        @ B_np.astype(np.int64)
    )

    dut._log.info(section("32x32 Matrix Test"))
    dut._log.info(
        f"A checksum = {int(A_np.sum())}, "
        f"B checksum = {int(B_np.sum())}, "
        f"C checksum = {int(C_exp.sum())}"
    )

    # ------------------------------
    # memory model
    # ------------------------------
    mem = {}

    # A/B:
    # 32要素/行 = 8ワード/行
    # 各ワードにはuint8_tを4要素ずつ格納する。
    for row in range(MATRIX_N):
        for word_index in range(WORDS_PER_ROW):
            col_base = word_index * 4
            byte_offset = (
                row * MATRIX_N
                + col_base
            )

            mem[BASE_ADDR_A + byte_offset] = pack_u8x4(
                A_np[row, col_base:col_base + 4]
            )
            mem[BASE_ADDR_B + byte_offset] = pack_u8x4(
                B_np[row, col_base:col_base + 4]
            )

    # C: 32x32 uint32_t
    for index in range(MATRIX_N * MATRIX_N):
        mem[BASE_ADDR_C + (index * 4)] = 0

    cocotb.start_soon(memory_driver(dut, mem))

    # ------------------------------
    # start DUT
    # ------------------------------
    dut.start.value = 1
    await RisingEdge(dut.clock)
    dut.start.value = 0

    timeout = 200_000

    for cycle in range(timeout):
        if int(dut.done.value) == 1:
            dut._log.info(
                f"32x32 operation completed after {cycle} cycles"
            )
            break

        await RisingEdge(dut.clock)
    else:
        raise AssertionError(
            f"32x32 operation timeout after {timeout} cycles"
        )

    # 書き込み完了を確実に観測するため少し待つ。
    for _ in range(10):
        await RisingEdge(dut.clock)

    # ------------------------------
    # assemble C matrix
    # ------------------------------
    C_hw = np.zeros(
        (MATRIX_N, MATRIX_N),
        dtype=np.uint32
    )

    for row in range(MATRIX_N):
        for col in range(MATRIX_N):
            index = row * MATRIX_N + col
            addr = BASE_ADDR_C + (index * 4)
            C_hw[row, col] = mem.get(addr, 0) & 0xFFFFFFFF

    # ------------------------------
    # result
    # ------------------------------
    dut._log.info(section("32x32 Assert"))
    dut._log.info(
        f"Expected checksum = {int(C_exp.sum())}"
    )
    dut._log.info(
        f"HW checksum       = {int(C_hw.astype(np.uint64).sum())}"
    )

    if not np.array_equal(C_hw, C_exp):
        mismatch = np.argwhere(
            C_hw.astype(np.int64) != C_exp
        )

        first_row = int(mismatch[0][0])
        first_col = int(mismatch[0][1])

        dut._log.error(
            "First mismatch: "
            f"C[{first_row}][{first_col}] "
            f"expected={int(C_exp[first_row, first_col])} "
            f"got={int(C_hw[first_row, first_col])}"
        )

        # 不一致行だけを表示し、巨大な32x32ログを避ける。
        dut._log.error(
            fmt_list(
                [
                    int(value)
                    for value in C_exp[first_row]
                ]
            )
        )
        dut._log.error(
            fmt_list(
                [
                    int(value)
                    for value in C_hw[first_row]
                ]
            )
        )

    assert np.array_equal(C_hw, C_exp)

    dut._log.info("✅ 32x32 PASS")

# =============================================
# 4th test
# =============================================
@cocotb.test()
async def test_systolic_array_driver_64x64(dut):

    dut._log.info("\n")
    dut._log.info("=============================================")

    # ==================
    MATRIX_N = 64
    WORDS_PER_ROW = MATRIX_N // 4
    dut.matrix_size_x.value = MATRIX_N
    dut.matrix_size_y.value = MATRIX_N
    # ==================

    clock = Clock(dut.clock, 10, unit="ns")
    cocotb.start_soon(clock.start())

    # reset
    dut.reset_n.value = 0
    dut.sa_clear.value = 0
    dut.rd_read_ready.value = 0
    dut.c_write_ready.value = 0
    dut.sa_state_reset.value = 0
    dut.sa_req_ready.value = 1

    # Output-Stationary mode
    dut.sa_os_instruction.value = 0b0000

    dut.BASE_ADDR_A.value = BASE_ADDR_A
    dut.BASE_ADDR_B.value = BASE_ADDR_B
    dut.BASE_ADDR_C.value = BASE_ADDR_C

    dut.start.value = 0

    for _ in range(5):
        await RisingEdge(dut.clock)

    dut.reset_n.value = 1

    for _ in range(5):
        await RisingEdge(dut.clock)

    # ------------------------------
    # generate deterministic matrices
    # ------------------------------
    rng = np.random.default_rng(0x6464)

    A_np = rng.integers(
        1, 10, size=(MATRIX_N, MATRIX_N), dtype=np.uint8
    )
    B_np = rng.integers(
        1, 10, size=(MATRIX_N, MATRIX_N), dtype=np.uint8
    )

    # uint8のまま積和せず、64bitへ拡張して参照値を作る。
    C_exp = (
        A_np.astype(np.int64)
        @ B_np.astype(np.int64)
    )

    dut._log.info(section("64x64 Matrix Test"))
    dut._log.info(
        f"A checksum = {int(A_np.sum())}, "
        f"B checksum = {int(B_np.sum())}, "
        f"C checksum = {int(C_exp.sum())}"
    )

    # ------------------------------
    # memory model
    # ------------------------------
    mem = {}

    # A/B:
    # 64要素/行 = 16ワード/行。
    # 各ワードへuint8_tを4要素ずつ格納する。
    for row in range(MATRIX_N):
        for word_index in range(WORDS_PER_ROW):
            col_base = word_index * 4
            byte_offset = row * MATRIX_N + col_base

            mem[BASE_ADDR_A + byte_offset] = pack_u8x4(
                A_np[row, col_base:col_base + 4]
            )
            mem[BASE_ADDR_B + byte_offset] = pack_u8x4(
                B_np[row, col_base:col_base + 4]
            )

    # C: 64x64 uint32_t = 16 KiB
    for index in range(MATRIX_N * MATRIX_N):
        mem[BASE_ADDR_C + (index * 4)] = 0

    cocotb.start_soon(memory_driver(dut, mem))

    # ------------------------------
    # start DUT
    # ------------------------------
    dut.start.value = 1
    await RisingEdge(dut.clock)
    dut.start.value = 0

    # 32x32実測のおよそ8倍を見込み、余裕を持たせる。
    timeout = 1_500_000

    for cycle in range(timeout):
        if int(dut.done.value) == 1:
            dut._log.info(
                f"64x64 operation completed after {cycle} cycles"
            )
            break

        await RisingEdge(dut.clock)
    else:
        raise AssertionError(
            f"64x64 operation timeout after {timeout} cycles"
        )

    # 最後のC書き込みを確実に取り込む。
    for _ in range(10):
        await RisingEdge(dut.clock)

    # ------------------------------
    # assemble C matrix
    # ------------------------------
    C_hw = np.zeros(
        (MATRIX_N, MATRIX_N),
        dtype=np.uint32
    )

    for row in range(MATRIX_N):
        for col in range(MATRIX_N):
            index = row * MATRIX_N + col
            addr = BASE_ADDR_C + (index * 4)
            C_hw[row, col] = mem.get(addr, 0) & 0xFFFFFFFF

    # ------------------------------
    # result
    # ------------------------------
    dut._log.info(section("64x64 Assert"))
    dut._log.info(
        f"Expected checksum = {int(C_exp.sum())}"
    )
    dut._log.info(
        f"HW checksum       = {int(C_hw.astype(np.uint64).sum())}"
    )

    if not np.array_equal(C_hw, C_exp):
        mismatch = np.argwhere(
            C_hw.astype(np.int64) != C_exp
        )

        first_row = int(mismatch[0][0])
        first_col = int(mismatch[0][1])

        dut._log.error(
            "First mismatch: "
            f"C[{first_row}][{first_col}] "
            f"expected={int(C_exp[first_row, first_col])} "
            f"got={int(C_hw[first_row, first_col])}"
        )

        # 巨大な64x64行列全体は出さず、不一致行のみ表示する。
        dut._log.error(
            "Expected row: "
            + fmt_list([int(value) for value in C_exp[first_row]])
        )
        dut._log.error(
            "HW row      : "
            + fmt_list([int(value) for value in C_hw[first_row]])
        )

    assert np.array_equal(C_hw, C_exp)

    dut._log.info("✅ 64x64 PASS")


# =============================================
# 5th test
# matrix_size_x = 4
# matrix_size_y = 8
# A: 8x4
# B: 4x8
# C: 8x8
# =============================================
@cocotb.test()
async def test_systolic_array_driver_4x8(dut):

    dut._log.info("\n")
    dut._log.info("=============================================")

    # ==================
    MATRIX_X = 4
    MATRIX_Y = 8

    A_ROWS = MATRIX_Y
    A_COLS = MATRIX_X

    B_ROWS = MATRIX_X
    B_COLS = MATRIX_Y

    C_ROWS = MATRIX_Y
    C_COLS = MATRIX_Y

    A_WORDS_PER_ROW = A_COLS // 4
    B_WORDS_PER_ROW = B_COLS // 4

    dut.matrix_size_x.value = MATRIX_X
    dut.matrix_size_y.value = MATRIX_Y
    # ==================

    clock = Clock(dut.clock, 10, unit="ns")
    cocotb.start_soon(clock.start())

    # reset
    dut.reset_n.value = 0
    dut.sa_clear.value = 0
    dut.rd_read_ready.value = 0
    dut.c_write_ready.value = 0
    dut.sa_state_reset.value = 0
    dut.sa_req_ready.value = 1

    # Output-Stationary mode
    dut.sa_os_instruction.value = 0b0000

    dut.BASE_ADDR_A.value = BASE_ADDR_A
    dut.BASE_ADDR_B.value = BASE_ADDR_B
    dut.BASE_ADDR_C.value = BASE_ADDR_C

    dut.start.value = 0

    for _ in range(5):
        await RisingEdge(dut.clock)

    dut.reset_n.value = 1

    for _ in range(5):
        await RisingEdge(dut.clock)

    # ------------------------------
    # generate deterministic matrices
    # ------------------------------
    rng = np.random.default_rng(0x0408)

    # A: 8x4
    A_np = rng.integers(
        1,
        10,
        size=(A_ROWS, A_COLS),
        dtype=np.uint8
    )

    # B: 4x8
    B_np = rng.integers(
        1,
        10,
        size=(B_ROWS, B_COLS),
        dtype=np.uint8
    )

    # C: 8x8
    # uint8のまま積和せず、64bitへ拡張して参照値を作る。
    C_exp = (
        A_np.astype(np.int64)
        @ B_np.astype(np.int64)
    )

    dut._log.info(section("4x8 Matrix Test"))
    dut._log.info(
        f"matrix_size_x = {MATRIX_X}, "
        f"matrix_size_y = {MATRIX_Y}"
    )
    dut._log.info(
        f"A shape = {A_np.shape}, "
        f"B shape = {B_np.shape}, "
        f"C shape = {C_exp.shape}"
    )
    dut._log.info(
        f"A checksum = {int(A_np.sum())}, "
        f"B checksum = {int(B_np.sum())}, "
        f"C checksum = {int(C_exp.sum())}"
    )

    dut._log.info(fmt_mat("A", A_np))
    dut._log.info(fmt_mat("B", B_np))

    # ------------------------------
    # memory model
    # ------------------------------
    mem = {}

    # ------------------------------
    # A: 8x4 uint8
    #
    # 4要素/行 = 1ワード/行
    # メモリ上の行サイズは4 byte
    # ------------------------------
    for row in range(A_ROWS):
        for word_index in range(A_WORDS_PER_ROW):
            col_base = word_index * 4

            byte_offset = (
                row * A_COLS
                + col_base
            )

            mem[BASE_ADDR_A + byte_offset] = pack_u8x4(
                A_np[row, col_base:col_base + 4]
            )

    # ------------------------------
    # B: 4x8 uint8
    #
    # 8要素/行 = 2ワード/行
    # メモリ上の行サイズは8 byte
    # ------------------------------
    for row in range(B_ROWS):
        for word_index in range(B_WORDS_PER_ROW):
            col_base = word_index * 4

            byte_offset = (
                row * B_COLS
                + col_base
            )

            mem[BASE_ADDR_B + byte_offset] = pack_u8x4(
                B_np[row, col_base:col_base + 4]
            )

    # C: 8x8 uint32_t
    for index in range(C_ROWS * C_COLS):
        mem[BASE_ADDR_C + (index * 4)] = 0

    cocotb.start_soon(memory_driver(dut, mem))

    # ------------------------------
    # start DUT
    # ------------------------------
    dut.start.value = 1
    await RisingEdge(dut.clock)
    dut.start.value = 0

    timeout = 10_000

    for cycle in range(timeout):
        if int(dut.done.value) == 1:
            dut._log.info(
                f"4x8 operation completed after {cycle} cycles"
            )
            break

        await RisingEdge(dut.clock)
    else:
        raise AssertionError(
            f"4x8 operation timeout after {timeout} cycles"
        )

    # 最後のC書き込みを確実に取り込む。
    for _ in range(10):
        await RisingEdge(dut.clock)

    # ------------------------------
    # assemble C matrix
    # ------------------------------
    C_hw = np.zeros(
        (C_ROWS, C_COLS),
        dtype=np.uint32
    )

    for row in range(C_ROWS):
        for col in range(C_COLS):
            index = row * C_COLS + col
            addr = BASE_ADDR_C + (index * 4)

            C_hw[row, col] = (
                mem.get(addr, 0)
                & 0xFFFFFFFF
            )

    # ------------------------------
    # result
    # ------------------------------
    dut._log.info(section("4x8 Assert"))

    dut._log.info(
        f"Expected checksum = {int(C_exp.sum())}"
    )
    dut._log.info(
        f"HW checksum       = "
        f"{int(C_hw.astype(np.uint64).sum())}"
    )

    dut._log.info(fmt_mat("Expected", C_exp))
    dut._log.info(fmt_mat("HW", C_hw))

    if not np.array_equal(C_hw, C_exp):
        mismatch = np.argwhere(
            C_hw.astype(np.int64) != C_exp
        )

        first_row = int(mismatch[0][0])
        first_col = int(mismatch[0][1])

        dut._log.error(
            "First mismatch: "
            f"C[{first_row}][{first_col}] "
            f"expected={int(C_exp[first_row, first_col])} "
            f"got={int(C_hw[first_row, first_col])}"
        )

        dut._log.error(
            "Expected row: "
            + fmt_list(
                [
                    int(value)
                    for value in C_exp[first_row]
                ]
            )
        )

        dut._log.error(
            "HW row      : "
            + fmt_list(
                [
                    int(value)
                    for value in C_hw[first_row]
                ]
            )
        )

    assert np.array_equal(C_hw, C_exp)

    dut._log.info("✅ 4x8 PASS")