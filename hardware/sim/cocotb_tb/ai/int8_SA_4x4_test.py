import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import numpy as np

N = 4
DW = 8

ASSERT_MODE = 1


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
            "  " + " ".join(f"{int(v):6d}" for v in row)
        )


# ==============================
# PE累積値読み出し
# ==============================
async def read_ps_acc_matrix(dut):
    """
    ps_select/ps_acc_outから4×4の累積値を読み出す。

    ps_select:
         0  1  2  3
         4  5  6  7
         8  9 10 11
        12 13 14 15
    """

    acc = np.zeros((N, N), dtype=np.int64)

    for row in range(N):
        for col in range(N):
            index = row * N + col

            # 書き込み可能フェーズでセレクタを変更
            dut.ps_select.value = index

            # 組み合わせ回路の伝搬と次タイムステップへの移行
            await Timer(1, unit="ns")

            acc[row, col] = int(dut.ps_acc_out.value)

    return acc


async def log_pe(dut):
    acc = await read_ps_acc_matrix(dut)

    dut._log.info("PE:")

    for row in acc:
        dut._log.info(
            "  " + " ".join(f"{int(v):6d}" for v in row)
        )


# ==============================
# ユーティリティ
# ==============================
def pack_bus(values, width):
    """
    values[0]をバスの最下位側へ格納する。

    例:
        values = [A0, A1, A2, A3]
        bus[7:0]   = A0
        bus[15:8]  = A1
        bus[23:16] = A2
        bus[31:24] = A3
    """

    bus = 0
    mask = (1 << width) - 1

    for index, value in enumerate(values):
        bus |= (int(value) & mask) << (index * width)

    return bus


def python_model(A, B):
    """
    通常の4×4行列積

        C[i,j] = Σ A[i,k] * B[k,j]
                  k=0..3
    """

    C = np.zeros((N, N), dtype=np.int64)

    for row in range(N):
        for col in range(N):
            acc = 0

            for k in range(N):
                acc += int(A[row, k]) * int(B[k, col])

            C[row, col] = acc

    return C


# ==============================
# 1ステップ分の実行
# ==============================
async def execute_mac_step(dut, a_values, b_values):
    """
    A/Bを1回シフトし、その後16論理PEのMAC処理を開始する。
    """

    dut.a_left_in_bus.value = pack_bus(a_values, DW)
    dut.b_top_in_bus.value = pack_bus(b_values, DW)

    # --------------------------------
    # A/Bシフト
    # --------------------------------
    dut.en_shift_right.value = 1
    dut.en_b_shift_bottom.value = 1

    await RisingEdge(dut.clock)

    dut.en_shift_right.value = 0
    dut.en_b_shift_bottom.value = 0

    # --------------------------------
    # MAC開始
    # --------------------------------
    dut.start_pulse.value = 1

    await RisingEdge(dut.clock)

    dut.start_pulse.value = 0

    # --------------------------------
    # 共通FSM完了待ち
    # --------------------------------
    while int(dut.done_out.value) == 0:
        await RisingEdge(dut.clock)

    # done_outがLowへ戻るまで待つ
    await RisingEdge(dut.clock)


# ==============================
# テスト本体
# ==============================
@cocotb.test()
async def test_systolic_array_4x4(dut):

    # ==============================
    # Clock
    # ==============================
    clock = Clock(dut.clock, 10, unit="ns")
    cocotb.start_soon(clock.start())

    # ==============================
    # Reset
    # ==============================
    dut.reset_n.value = 0

    dut.data_clear.value = 1
    dut.en_b_shift_bottom.value = 0
    dut.en_shift_right.value = 0
    dut.start_pulse.value = 0
    dut.ps_select.value = 0

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
    A = np.random.randint(
        low=0,
        high=64,
        size=(N, N),
        dtype=np.int64,
    )

    B = np.random.randint(
        low=0,
        high=32,
        size=(N, N),
        dtype=np.int64,
    )

    C_expected = python_model(A, B)

    log_section(dut, "Test Vectors")
    log_matrix(dut, "A", A)
    log_matrix(dut, "B", B)
    log_matrix(dut, "Expected", C_expected)

    # ==============================
    # A/B同時ストリーム
    #
    # A[i,k]は時刻 t=i+k に投入
    # B[k,j]は時刻 t=k+j に投入
    #
    # PE(i,j)には両方が時刻
    # t=i+j+k で到着する。
    # ==============================
    log_section(dut, "Stream")

    total_steps = 2 * N - 1

    for t in range(total_steps):

        # --------------------------------
        # 左端から入れるA
        # --------------------------------
        a_values = []

        for row in range(N):
            k = t - row

            if 0 <= k < N:
                a_values.append(int(A[row, k]))
            else:
                a_values.append(0)

        # --------------------------------
        # 上端から入れるB
        # --------------------------------
        b_values = []

        for col in range(N):
            k = t - col

            if 0 <= k < N:
                b_values.append(int(B[k, col]))
            else:
                b_values.append(0)

        dut._log.debug(
            f"stream t={t}: "
            f"A_LEFT={a_values}, "
            f"B_TOP={b_values}"
        )

        await execute_mac_step(
            dut,
            a_values,
            b_values,
        )

        # 必要なら各ステップの累積値を表示
        # await log_pe(dut)

    # ==============================
    # Flush
    #
    # 最後に投入したデータが右下PEまで
    # 到達するためのゼロ入力。
    #
    # 4×4では最大伝搬距離は
    # (N-1)+(N-1)=6段だが、
    # Stream側ですでに斜め投入しているため、
    # 元コードと同様にN回のflushで確認する。
    # ==============================
    log_section(dut, "Flush")

    zero_values = [0] * N

    for flush_index in range(N):
        dut._log.debug(f"flush={flush_index}")

        await execute_mac_step(
            dut,
            zero_values,
            zero_values,
        )

        # await log_pe(dut)

    # ==============================
    # 結果取得
    # ==============================
    log_section(dut, "Result")

    C_hw = await read_ps_acc_matrix(dut)

    log_matrix(dut, "HW", C_hw)

    ok = np.array_equal(C_hw, C_expected)

    if not ok:
        log_matrix(dut, "DIFF", C_hw - C_expected)

    if ASSERT_MODE == 1:
        assert ok, (
            "\n"
            f"Matrix mismatch\n"
            f"A=\n{A}\n"
            f"B=\n{B}\n"
            f"Expected=\n{C_expected}\n"
            f"HW=\n{C_hw}\n"
            f"DIFF=\n{C_hw - C_expected}\n"
        )

    dut._log.info("✅ PASS")

    for _ in range(5):
        await RisingEdge(dut.clock)