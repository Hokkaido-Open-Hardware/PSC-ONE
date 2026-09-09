# int8_PE_test.py

import os
import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer


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
    
    signed_mode = get_sig(dut, "signed_mode")

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

    signed_mode.value = 0

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

    # ========================================================
    # Signed multiplication test
    # ========================================================

    dut._log.info(
        "============================================================"
    )
    dut._log.info("Starting signed multiplication test")

    signed_mode.value = 1

    signed_min = -(1 << (DW - 1))
    signed_max =  (1 << (DW - 1)) - 1

    signed_base_tests = [
        (0, 0),
        (1, 1),
        (-1, 1),
        (1, -1),
        (-1, -1),
        (2, -3),
        (-3, 3),
        (13, -22),
        (-13, 22),
        (signed_max, 1),
        (signed_min, 1),
        (signed_max, -1),
        (signed_min, -1),
        (signed_max, signed_max),
        (signed_min, signed_min),
        (signed_min, signed_max),
        (-5, 7),
        (5, -7),
    ]

    for _ in range(8):
        signed_base_tests.append((
            random.randint(signed_min, signed_max),
            random.randint(signed_min, signed_max),
        ))

    signed_tests = []

    for case_index in range(len(signed_base_tests)):
        thread_case = []

        for thread in range(THREADS):
            pattern_index = (
                case_index + thread * 3
            ) % len(signed_base_tests)

            thread_case.append(
                signed_base_tests[pattern_index]
            )

        signed_tests.append(thread_case)

    # ========================================================
    # Signed independent multiplication test
    # ========================================================

    for case_index, thread_values in enumerate(signed_tests):

        data_clear.value = 1
        await RisingEdge(clk_sig)

        data_clear.value = 0
        await RisingEdge(clk_sig)

        await run_operation(thread_values)

        packed_acc = int_resolved(ps_acc)
        got_values = unpack_lanes(
            packed_acc,
            THREADS,
            SW,
        )

        for thread in range(THREADS):
            aval, bval = thread_values[thread]

            # signed multiplication result
            expected_signed = aval * bval

            # accumulator上では2の補数SW bitとして比較
            expected = expected_signed & maskSW

            got = got_values[thread]

            assert got == expected, (
                f"signed case={case_index} "
                f"thread={thread}: "
                f"a={aval} b={bval} "
                f"got=0x{got:X} "
                f"expected=0x{expected:X} "
                f"({expected_signed}); "
                f"packed_acc=0x{packed_acc:X}"
            )

        expressions = ", ".join(
            f"T{thread}: {a}*{b}={a*b}"
            for thread, (a, b)
            in enumerate(thread_values)
        )

        dut._log.info(
            f"✅ Signed independent pattern "
            f"{case_index} passed: "
            f"{expressions}"
        )

    # ========================================================
    # Signed accumulation test
    # ========================================================

    dut._log.info(
        "============================================================"
    )
    dut._log.info(
        "Starting signed multi-thread accumulation test"
    )

    data_clear.value = 1
    await RisingEdge(clk_sig)

    data_clear.value = 0
    await RisingEdge(clk_sig)

    expected_acc_signed = [
        0 for _ in range(THREADS)
    ]

    for case_index, thread_values in enumerate(signed_tests):

        await run_operation(thread_values)

        for thread in range(THREADS):
            aval, bval = thread_values[thread]

            expected_acc_signed[thread] += (
                aval * bval
            )

        packed_acc = int_resolved(ps_acc)
        got_acc = unpack_lanes(
            packed_acc,
            THREADS,
            SW,
        )

        for thread in range(THREADS):

            expected = (
                expected_acc_signed[thread]
                & maskSW
            )

            assert got_acc[thread] == expected, (
                f"signed acc case={case_index} "
                f"thread={thread}: "
                f"got=0x{got_acc[thread]:X} "
                f"expected=0x{expected:X} "
                f"({expected_acc_signed[thread]}); "
                f"packed_acc=0x{packed_acc:X}"
            )

        expressions = ", ".join(
            f"T{thread}: "
            f"acc={expected_acc_signed[thread]}"
            for thread in range(THREADS)
        )

        dut._log.info(
            f"✅ Signed accumulation pattern "
            f"{case_index} passed: "
            f"{expressions}"
        )

    dut._log.info(
        f"All signed patterns passed: "
        f"THREADS={THREADS}, "
        f"DW={DW}, SW={SW}."
    )


@cocotb.test()
async def test_pe_cycle_contract(dut):
    """Check atomic accumulation and input capture, including busy-time changes.

    Model the public contract: start, two cycles to operand capture, fixed
    groups of multiplications, then an atomic accumulator commit. In
    particular, input shifts/clear and mode changes during a batch must
    not alter already captured operands or expose partially updated sums.
    """
    dw = int(os.getenv("PE_DW", "8"))
    pw = int(os.getenv("PE_PW", "32"))
    threads = len(dut.a_in) // dw
    sw = len(dut.ps_acc) // threads
    parallel = max(1, min(threads, int(os.getenv("PE_MUL_NUM", "1"))))
    groups = (threads + parallel - 1) // parallel
    mask = (1 << sw) - 1
    dw_mask = (1 << dw) - 1
    rng = random.Random(0x4D4143)

    def pack(values, width):
        return sum((v & ((1 << width) - 1)) << (i * width)
                   for i, v in enumerate(values))

    def signed(value, width):
        return value - (1 << width) if value & (1 << (width - 1)) else value

    cocotb.start_soon(Clock(dut.clock, 10, unit="ns").start())
    a = [0] * threads
    b = [0] * threads
    acc = [0] * threads
    pending = [0] * threads
    phase = 0
    pe_signed = 0
    completed = 0
    for cycle in range(2500):
        await FallingEdge(dut.clock)
        reset_n = int(cycle > 2 and cycle not in (731, 1703))
        clear = int(rng.randrange(19) == 0)
        start = int(rng.randrange(3) != 0)
        mode = rng.randrange(2)
        shift_a, shift_b = rng.randrange(2), rng.randrange(2)
        a_in = [rng.randrange(dw_mask + 1) for _ in a]
        b_in = [rng.randrange(dw_mask + 1) for _ in b]
        dut.reset_n.value = reset_n
        dut.data_clear.value = clear
        dut.start.value = start
        dut.signed_mode.value = mode
        dut.en_shift_right.value = shift_a
        dut.en_b_shift_bottom.value = shift_b
        dut.a_in.value = pack(a_in, dw)
        dut.b_in.value = pack(b_in, dw)

        done = 0
        if not reset_n:
            a, b, acc = [0] * threads, [0] * threads, [0] * threads
            phase = 0
        else:
            # Capture uses the operands from before this clock's shifts.
            if phase == 2:
                pending = []
                for x, y in zip(a, b):
                    product = signed(x, dw) * signed(y, dw) if mode else x * y
                    product &= (1 << pw) - 1
                    pending.append(signed(product, pw) if pe_signed else product)
            if phase == groups + 4:
                acc = [(x + y) & mask for x, y in zip(acc, pending)]
                phase, done = 0, 1
                completed += 1
            elif phase:
                phase += 1
            elif clear:
                acc = [0] * threads
            elif start:
                phase, pe_signed = 1, mode
            if clear:
                a, b = [0] * threads, [0] * threads
            else:
                if shift_a:
                    a = a_in
                if shift_b:
                    b = b_in

        await RisingEdge(dut.clock)
        await Timer(1, unit="ns")
        assert int(dut.busy.value) == int(phase != 0), f"busy cycle={cycle}"
        assert int(dut.done.value) == done, f"done cycle={cycle}"
        assert int(dut.ps_acc.value) == pack(acc, sw), f"acc cycle={cycle}"
        assert int(dut.a_shift_to_right.value) == pack(a, dw), f"A cycle={cycle}"
        assert int(dut.b_shift_to_bottom.value) == pack(b, dw), f"B cycle={cycle}"
    assert completed > 20, "insufficient completed transactions"
