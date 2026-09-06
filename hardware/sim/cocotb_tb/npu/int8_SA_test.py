import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
import numpy as np

N = 2

ASSER_MODE = 1


# ==============================
# ログ整形
# ==============================
def log_section(dut, title):
    dut._log.info("")
    dut._log.info(f"=== {title} ===")


def log_matrix(dut, name, mat):
    dut._log.info(f"{name}:")
    for row in mat:
        dut._log.info(
            "  " + " ".join(f"{int(v):4d}" for v in row)
        )


def read_ps_acc_matrix(dut):
    """
    4スレッド版SystolicArray2x2のトップ出力から
    2×2のps_acc行列を取得する。

        ps_acc_0 = PE(0,0)
        ps_acc_1 = PE(0,1)
        ps_acc_2 = PE(1,0)
        ps_acc_3 = PE(1,1)
    """
    return np.array(
        [
            [
                int(dut.ps_acc_0.value),
                int(dut.ps_acc_1.value),
            ],
            [
                int(dut.ps_acc_2.value),
                int(dut.ps_acc_3.value),
            ],
        ],
        dtype=int,
    )


def log_pe(dut):
    acc = read_ps_acc_matrix(dut)

    dut._log.info("PE:")
    for row in acc:
        dut._log.info(
            "  " + " ".join(f"{int(v):4d}" for v in row)
        )


# ==============================
# ユーティリティ
# ==============================
def pack_bus(values, width):
    bus = 0
    mask = (1 << width) - 1

    for i, value in enumerate(values):
        bus |= (int(value) & mask) << (i * width)

    return bus


def python_model(A, B):
    C = np.zeros((N, N), dtype=int)

    for i in range(N):
        for j in range(N):
            C[i, j] = int(
                A[i, 0] * B[0, j]
                + A[i, 1] * B[1, j]
            )

    return C


# ==============================
# テスト本体
# ==============================
@cocotb.test()
async def test_systolic_array_2x2(dut):

    # Clock
    clock = Clock(dut.clock, 10, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.reset_n.value = 0
    dut.data_clear.value = 1
    dut.en_b_shift_bottom.value = 0
    dut.en_shift_right.value = 0
    dut.start_pulse.value = 0

    dut.a_left_in_bus.value = 0
    dut.b_top_in_bus.value = 0

    for _ in range(5):
        await RisingEdge(dut.clock)

    dut.reset_n.value = 1
    dut.data_clear.value = 0

    for _ in range(3):
        await RisingEdge(dut.clock)

    # ==============================
    # データ生成
    # ==============================
    A = np.random.randint(0, 64, (N, N))
    B = np.random.randint(0, 32, (N, N))

    C_expected = python_model(A, B)

    log_section(dut, "Test Vectors")
    log_matrix(dut, "A", A)
    log_matrix(dut, "B", B)
    log_matrix(dut, "Expected", C_expected)

    # ==============================
    # A/B 同時ストリーム（OS）
    # ==============================
    log_section(dut, "Stream")

    total_steps = 2 * N - 1

    for t in range(total_steps):

        # A input
        a_vals = []

        for i in range(N):
            k = t - i

            if 0 <= k < N:
                a_vals.append(int(A[i][k]))
            else:
                a_vals.append(0)

        dut.a_left_in_bus.value = pack_bus(a_vals, 8)

        # B input
        b_vals = []

        for j in range(N):
            k = t - j

            if 0 <= k < N:
                b_vals.append(int(B[k][j]))
            else:
                b_vals.append(0)

        dut.b_top_in_bus.value = pack_bus(b_vals, 8)

        # A/B shift
        dut.en_shift_right.value = 1
        dut.en_b_shift_bottom.value = 1

        await RisingEdge(dut.clock)

        dut.en_shift_right.value = 0
        dut.en_b_shift_bottom.value = 0

        # MAC start
        dut.start_pulse.value = 1
        await RisingEdge(dut.clock)
        dut.start_pulse.value = 0

        # 共通FSMの完了待ち
        while int(dut.done_out.value) == 0:
            await RisingEdge(dut.clock)

        # doneは1クロックパルスなので、
        # 次の処理開始前にLowへ戻るのを待つ
        await RisingEdge(dut.clock)

        log_pe(dut)

    # ==============================
    # Flush
    # ==============================
    log_section(dut, "Flush")

    for _ in range(N):

        dut.a_left_in_bus.value = 0
        dut.b_top_in_bus.value = 0

        dut.en_shift_right.value = 1
        dut.en_b_shift_bottom.value = 1

        await RisingEdge(dut.clock)

        dut.en_shift_right.value = 0
        dut.en_b_shift_bottom.value = 0

        dut.start_pulse.value = 1
        await RisingEdge(dut.clock)
        dut.start_pulse.value = 0

        while int(dut.done_out.value) == 0:
            await RisingEdge(dut.clock)

        await RisingEdge(dut.clock)

        log_pe(dut)

    # ==============================
    # 結果取得
    # ==============================
    log_section(dut, "Result")

    C_hw = read_ps_acc_matrix(dut)

    log_matrix(dut, "HW", C_hw)

    ok = np.array_equal(C_hw, C_expected)

    if not ok:
        log_matrix(dut, "DIFF", C_hw - C_expected)

    if ASSER_MODE == 1:
        assert ok, "Matrix mismatch"

    dut._log.info("PASS")

    for _ in range(5):
        await RisingEdge(dut.clock)