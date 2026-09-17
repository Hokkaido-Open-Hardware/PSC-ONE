# int8_PE_test.py

import os
import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer


# ============================================================
# Utility functions
# ============================================================

def int_resolved(sig) -> int:
    try:
        return int(sig.value)
    except (ValueError, TypeError):
        return 0


def get_sig(dut, *names):
    """dutから最初に見つかったシグナルを返す。"""
    for name in names:
        if hasattr(dut, name):
            return getattr(dut, name)

    raise AttributeError(f"Signal not found among: {names}")


async def wait_level(
    sig,
    level: int,
    clock,
    timeout_cycles: int | None = None,
) -> bool:
    """sigが指定レベルになるまで待つ。"""
    expected = 1 if level else 0
    waited = 0

    while int_resolved(sig) != expected:
        await RisingEdge(clock)
        waited += 1

        if timeout_cycles is not None and waited >= timeout_cycles:
            return False

    return True


def pack_lanes(values, width: int) -> int:
    """
    values[0]を最下位レーンとしてパックする。

    lane 0 = packed[width-1:0]
    lane 1 = packed[2*width-1:width]
    """
    mask = (1 << width) - 1
    packed = 0

    for lane, value in enumerate(values):
        packed |= (int(value) & mask) << (lane * width)

    return packed


def unpack_lane(packed: int, lane: int, width: int) -> int:
    """パック信号から指定レーンを取り出す。"""
    mask = (1 << width) - 1
    return (packed >> (lane * width)) & mask


def unpack_lanes(packed: int, lanes: int, width: int) -> list[int]:
    """パック信号を全レーンに分解する。"""
    return [
        unpack_lane(packed, lane, width)
        for lane in range(lanes)
    ]


# ============================================================
# Main test
# ============================================================

@cocotb.test()
async def test_pe_seri_nbit_multiple(dut):
    """
    THREADS個のPEコンテキストを同時に検証する。

    各演算:
        ps_acc[t] = ps_acc[t] + A[t] * B[t]

    unsigned演算。
    """

    # --------------------------------------------------------
    # Configuration
    # --------------------------------------------------------

    THREADS = int(os.getenv("PE_THREADS", "2"))

    # --------------------------------------------------------
    # Clock
    # --------------------------------------------------------

    clk_sig = get_sig(dut, "clock", "Clock")
    clock = Clock(clk_sig, 10, unit="ns")
    cocotb.start_soon(clock.start())

    # --------------------------------------------------------
    # DUT signals
    # --------------------------------------------------------

    reset_n = get_sig(dut, "reset_n")

    data_clear = get_sig(dut, "data_clear")
    en_b_shift_bottom = get_sig(dut, "en_b_shift_bottom")
    en_shift_right = get_sig(dut, "en_shift_right")
    start = get_sig(dut, "start")

    a_in = get_sig(dut, "a_in")
    b_in = get_sig(dut, "b_in")

    ps_acc = get_sig(dut, "ps_acc")

    busy = get_sig(dut, "busy")
    done = get_sig(dut, "done")

    # --------------------------------------------------------
    # Reset
    # --------------------------------------------------------

    reset_n.value = 0
    data_clear.value = 0

    en_b_shift_bottom.value = 0
    en_shift_right.value = 0
    start.value = 0

    a_in.value = 0
    b_in.value = 0

    await Timer(50, unit="ns")

    reset_n.value = 1
    await RisingEdge(clk_sig)

    # --------------------------------------------------------
    # Per-thread widths
    # --------------------------------------------------------

    assert len(a_in) % THREADS == 0, (
        f"a_in width {len(a_in)} is not divisible by THREADS={THREADS}"
    )

    assert len(b_in) % THREADS == 0, (
        f"b_in width {len(b_in)} is not divisible by THREADS={THREADS}"
    )

    assert len(ps_acc) % THREADS == 0, (
        f"ps_acc width {len(ps_acc)} is not divisible by THREADS={THREADS}"
    )

    DW = len(a_in) // THREADS
    SW = len(ps_acc) // THREADS
    PW = 2 * DW

    maskDW = (1 << DW) - 1
    maskSW = (1 << SW) - 1

    dut._log.info(
        f"Detected configuration: "
        f"THREADS={THREADS}, DW={DW}, PW={PW}, SW={SW}"
    )

    # --------------------------------------------------------
    # Test patterns
    # --------------------------------------------------------

    random.seed(int(os.getenv("PE_SEED", "1234")))

    base_tests = [
        (0, 0),
        (1, 1),
        (2, 3),
        (3, 3),
        (13, 22),
        (maskDW, 1),
        (1, maskDW),
        (1, 1),
        (3, 3),
        ((1 << (DW - 1)) - 1, 2),
        (maskDW, maskDW),
        (5, 7),
    ]

    for _ in range(8):
        base_tests.append((
            random.randint(0, maskDW),
            random.randint(0, maskDW),
        ))

    # 各ケースでスレッドごとに異なるパターンを割り当てる
    tests = []

    for case_index in range(len(base_tests)):
        thread_case = []

        for thread in range(THREADS):
            pattern_index = (
                case_index + thread * 3
            ) % len(base_tests)

            thread_case.append(base_tests[pattern_index])

        tests.append(thread_case)

    # ========================================================
    # Helper: one multi-thread operation
    # ========================================================

    async def run_operation(thread_values):
        """
        thread_values:
            [
                (a0, b0),
                (a1, b1),
                ...
            ]
        """

        assert len(thread_values) == THREADS

        a_values = [item[0] for item in thread_values]
        b_values = [item[1] for item in thread_values]

        # A/Bを全スレッド分パック
        a_in.value = pack_lanes(a_values, DW)
        b_in.value = pack_lanes(b_values, DW)

        # A/Bシフトレジスタへ取り込み
        en_shift_right.value = 1
        en_b_shift_bottom.value = 1
        start.value = 0

        await RisingEdge(clk_sig)

        en_shift_right.value = 0
        en_b_shift_bottom.value = 0

        # startを1クロックだけアサート
        start.value = 1
        await RisingEdge(clk_sig)
        start.value = 0

        # 共通FSMのdoneを待つ
        completed = await wait_level(
            done,
            1,
            clk_sig,
            timeout_cycles=30,
        )

        assert completed, (
            f"Timeout waiting for done: "
            f"busy={int_resolved(busy)} "
            f"a={a_values}, b={b_values}"
        )

        # NBAによるps_acc更新を確実に観測する
        await RisingEdge(clk_sig)

    # ========================================================
    # Independent multiplication test
    # ========================================================

    for case_index, thread_values in enumerate(tests):

        # 各ケースでaccumulatorをクリア
        data_clear.value = 1
        await RisingEdge(clk_sig)

        data_clear.value = 0
        await RisingEdge(clk_sig)

        await run_operation(thread_values)

        packed_acc = int_resolved(ps_acc)
        got_values = unpack_lanes(packed_acc, THREADS, SW)

        for thread in range(THREADS):
            aval, bval = thread_values[thread]

            expected = (aval * bval) & maskSW
            got = got_values[thread]

            assert got == expected, (
                f"case={case_index} thread={thread}: "
                f"a={aval} b={bval} "
                f"got={got} expected={expected}; "
                f"packed_acc=0x{packed_acc:X}"
            )

        expressions = ", ".join(
            f"T{thread}: {a}*{b}={got_values[thread]}"
            for thread, (a, b) in enumerate(thread_values)
        )

        dut._log.info(
            f"✅ Independent pattern {case_index} passed: "
            f"{expressions}"
        )

    # ========================================================
    # Accumulation test
    # ========================================================

    dut._log.info(
        "============================================================"
    )
    dut._log.info("Starting multi-thread accumulation test")

    # 全スレッドのaccumulatorをクリア
    data_clear.value = 1
    await RisingEdge(clk_sig)

    data_clear.value = 0
    await RisingEdge(clk_sig)

    expected_acc = [0 for _ in range(THREADS)]

    for case_index, thread_values in enumerate(tests):

        await run_operation(thread_values)

        for thread in range(THREADS):
            aval, bval = thread_values[thread]

            expected_acc[thread] = (
                expected_acc[thread] + aval * bval
            ) & maskSW

        packed_acc = int_resolved(ps_acc)
        got_acc = unpack_lanes(packed_acc, THREADS, SW)

        for thread in range(THREADS):
            assert got_acc[thread] == expected_acc[thread], (
                f"acc case={case_index} thread={thread}: "
                f"got={got_acc[thread]} "
                f"expected={expected_acc[thread]}; "
                f"packed_acc=0x{packed_acc:X}"
            )

        expressions = ", ".join(
            f"T{thread}: acc={got_acc[thread]}"
            for thread in range(THREADS)
        )

        dut._log.info(
            f"✅ Accumulation pattern {case_index} passed: "
            f"{expressions}"
        )

    dut._log.info(
        f"All patterns passed: THREADS={THREADS}, unsigned."
    )