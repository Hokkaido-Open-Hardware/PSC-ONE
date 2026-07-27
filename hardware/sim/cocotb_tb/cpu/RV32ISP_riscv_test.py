import os
from pathlib import Path
import random

import cocotb
from cocotb.triggers import Timer, RisingEdge
from cocotb.triggers import FallingEdge, ReadOnly

# ------------------------------------------------
# 設定
# ------------------------------------------------
Assert = 0

CLK_PERIOD_NS = int(os.getenv("CLK_PERIOD_NS", "10"))  # 100 MHz
RUN_CYCLES = int(os.getenv("RUN_CYCLES", "200000"))
PROGRAM_FILE = os.getenv("PROGRAM_FILE", "./mem/test_program.mem")
TOHOST_ADDR = int(os.getenv("TOHOST_ADDR", "0x00001000"), 0) & 0xFFFF_FFFF

PROGRAM_READ_CYCLE  = 50
DATA_READ_CYCLE     = 50
DATA_WRITE_CYCLE    = 50

# ------------------------------------------------
# wait
# ------------------------------------------------
async def ncycles(clock, n: int):
    for _ in range(max(0, n)):
        await RisingEdge(clock)


# ------------------------------------------------
# clock
# ------------------------------------------------
async def generate_clock(dut, period_ns=CLK_PERIOD_NS):
    """Free-running clock."""
    while True:
        dut.clock.value = 0
        await Timer(period_ns // 2, unit="ns")

        dut.clock.value = 1
        await Timer(period_ns // 2, unit="ns")


# ------------------------------------------------
# reset DUT
# ------------------------------------------------
async def reset_dut(dut, reset_cycle=50):
    """Reset DUT."""
    dut.reset_n.value = 0

    await ncycles(dut.clock, reset_cycle)

    dut.reset_n.value = 1
    await RisingEdge(dut.clock)


# ------------------------------------------------
# メモリファイル読み込み
# ------------------------------------------------
def load_word_memory(filename: str) -> dict[int, int]:
    """
    $readmemh形式のファイルを読み込む。

    通常の1行1ワード形式:
        00000013
        00100093

    @アドレス形式にも簡易対応:
        @00000010
        12345678

    辞書のキーはバイトアドレス。
    """
    path = Path(filename)

    if not path.exists():
        raise FileNotFoundError(f"Program file not found: {filename}")

    memory: dict[int, int] = {}
    word_index = 0

    with path.open("r", encoding="utf-8") as file:
        for raw_line in file:
            # コメント除去
            line = raw_line.split("//", 1)[0]
            line = line.split("#", 1)[0]
            line = line.strip()

            if not line:
                continue

            # readmemhのアドレス指定
            if line.startswith("@"):
                word_index = int(line[1:], 16)
                continue

            # 1行に複数ワードがあっても処理する
            for token in line.split():
                value = int(token.replace("_", ""), 16) & 0xFFFF_FFFF
                byte_address = word_index * 4

                memory[byte_address] = value
                word_index += 1

    return memory


# ------------------------------------------------
# 32bitメモリアクセス
# ------------------------------------------------
def read_word(memory: dict[int, int], address: int) -> int:
    """
    32bitワードを読み出す。

    メモリ辞書はワード境界アドレスで保持する。
    """
    aligned_address = address & 0xFFFF_FFFC
    return memory.get(aligned_address, 0) & 0xFFFF_FFFF


def write_word(
    memory: dict[int, int],
    address: int,
    data: int,
    write_sel: int,
):
    """
    mem_write_selをRISC-V funct3として処理する。

    000: SB
    001: SH
    010: SW

    それ以外は安全のため32bit書き込みとして扱う。
    """
    address &= 0xFFFF_FFFF
    data &= 0xFFFF_FFFF
    write_sel &= 0x7

    aligned_address = address & 0xFFFF_FFFC
    old_word = memory.get(aligned_address, 0)

    byte_offset = address & 0x3

    if write_sel == 0b000:
        # SB
        shift = byte_offset * 8
        mask = 0xFF << shift

        new_word = (
            (old_word & ~mask)
            | ((data & 0xFF) << shift)
        )

    elif write_sel == 0b001:
        # SH
        shift = (byte_offset & 0x2) * 8
        mask = 0xFFFF << shift

        new_word = (
            (old_word & ~mask)
            | ((data & 0xFFFF) << shift)
        )

    else:
        # SW: mem_write_sel == 010
        # 不明な値も32bit書き込みとして扱う
        new_word = data

    memory[aligned_address] = new_word & 0xFFFF_FFFF

# ------------------------------------------------
# PIO32への書き込みを監視
#
# 0xEE01が書かれるまでは無視する。
# 0xEE01の次のPIO32書き込みを期待値と比較する。
# ------------------------------------------------
async def watch_pio32_result(
    dut,
    pio32_address: int,
    expected_value: int,
    timeout_cycles: int = 3_500_000,
):
    pio32_address &= 0xFFFF_FFFF
    expected_value &= 0xFFFF_FFFF

    marker_detected = False
    valid_seen = False
    pio_write_count = 0

    for cycle in range(timeout_cycles):
        await FallingEdge(dut.clock)
        await ReadOnly()

        if not bool(dut.reset_n.value):
            marker_detected = False
            valid_seen = False
            pio_write_count = 0
            continue

        write_valid = bool(dut.data_mem_write_valid.value)

        if not write_valid:
            valid_seen = False
            continue

        # validが複数サイクル継続した場合の重複防止
        if valid_seen:
            continue

        valid_seen = True

        address = int(dut.mem_write_address.value) & 0xFFFF_FFFF
        data = int(dut.mem_write_data.value) & 0xFFFF_FFFF
        write_sel = int(dut.mem_write_sel.value) & 0x7

        if address != pio32_address:
            continue

        pio_write_count += 1

        dut._log.info(
            "PIO32 write #%d cycle=%d "
            "addr=0x%08X data=0x%08X sel=0x%X",
            pio_write_count,
            cycle,
            address,
            data,
            write_sel,
        )

        # 完了マーカーが来るまではPIO書き込みを無視
        if not marker_detected:
            if data == 0x0000_EE01:
                marker_detected = True

                dut._log.info(
                    "PIO32 marker detected at cycle %d: 0x%08X",
                    cycle,
                    data,
                )

            continue

        # 0xEE01検出後、次のPIO32書き込みを結果として扱う
        assert data == expected_value, (
            f"PIO32 result mismatch: "
            f"expected=0x{expected_value:08X}, "
            f"actual=0x{data:08X}, "
            f"cycle={cycle}"
        )

        dut._log.info(
            "PIO32 result PASS: expected=0x%08X actual=0x%08X",
            expected_value,
            data,
        )

        return data

    if marker_detected:
        raise TimeoutError(
            f"PIO32 result timeout: "
            f"marker 0x0000EE01 was detected, "
            f"but no result was written within "
            f"{timeout_cycles} cycles"
        )

    raise TimeoutError(
        f"PIO32 marker timeout: "
        f"0x0000EE01 was not written to "
        f"0x{pio32_address:08X} within "
        f"{timeout_cycles} cycles"
    )


# ------------------------------------------------
# RISC-V official ISA test: tohost監視
#
# tohost == 1       : PASS
# tohost == (N<<1)|1: test_NでFAIL
# ------------------------------------------------
async def watch_tohost_result(
    dut,
    tohost_address: int = 0x0000_1000,
    expected_value: int = 0x0000_0001,
    timeout_cycles: int = 3_500_000,
):
    tohost_address &= 0xFFFF_FFFF
    expected_value &= 0xFFFF_FFFF

    valid_seen = False

    for cycle in range(timeout_cycles):
        await FallingEdge(dut.clock)
        await ReadOnly()

        if not bool(dut.reset_n.value):
            valid_seen = False
            continue

        write_valid = bool(dut.data_mem_write_valid.value)

        if not write_valid:
            valid_seen = False
            continue

        # validが複数サイクル継続した場合の重複防止
        if valid_seen:
            continue

        valid_seen = True

        address = int(dut.mem_write_address.value) & 0xFFFF_FFFF
        data = int(dut.mem_write_data.value) & 0xFFFF_FFFF
        write_sel = int(dut.mem_write_sel.value) & 0x7

        if address != tohost_address:
            continue

        dut._log.info(
            "tohost write cycle=%d addr=0x%08X data=0x%08X sel=0x%X",
            cycle,
            address,
            data,
            write_sel,
        )

        if data == expected_value:
            dut._log.info(
                "RISC-V ISA test PASS: expected=0x%08X actual=0x%08X",
                expected_value,
                data,
            )
            return data

        # riscv-testsのFAIL値は通常 (test_number << 1) | 1
        if data & 1:
            failed_test = data >> 1
            raise AssertionError(
                f"RISC-V ISA test FAIL: "
                f"test_{failed_test}, "
                f"tohost=0x{data:08X}, "
                f"expected=0x{expected_value:08X}, "
                f"cycle={cycle}"
            )

        raise AssertionError(
            f"RISC-V ISA test unexpected tohost value: "
            f"expected=0x{expected_value:08X}, "
            f"actual=0x{data:08X}, "
            f"cycle={cycle}"
        )

    raise TimeoutError(
        f"RISC-V ISA test timeout: "
        f"tohost 0x{tohost_address:08X} was not written within "
        f"{timeout_cycles} cycles"
    )


# ------------------------------------------------
# DUT入力初期化
# ------------------------------------------------
def initialize_dut_inputs(dut):
    dut.reset_n.value = 0
    dut.cpu_stop.value = 0
    dut.irq_ext.value = 0

    # Program memory
    dut.program_mem_read_ready.value = 0
    dut.program_mem_read_data.value = 0
    dut.program_mem_req_ready.value = 1

    # Data memory
    dut.data_mem_read_ready.value = 0
    dut.data_mem_read_data.value = 0
    dut.data_mem_req_ready.value = 1

    dut.data_mem_write_ready.value = 0

    # MMU memory
    dut.mmu_data_mem_read_ready.value = 0
    dut.mmu_data_mem_read_data.value = 0
    dut.mmu_data_req_ready.value = 1

    # CSR inputs
    dut.csr_DMA_STATUS.value = 0
    dut.csr_SA_STATUS.value = 0
    dut.csr_CPU_MON_CYCLE.value = 0

# ------------------------------------------------
# Program memory model
# ------------------------------------------------
async def program_memory_model(
    dut,
    memory: dict[int, int],
    read_delay_cycles: int = 1,
):
    """
    program_mem_read_validを受信してから、
    1〜read_delay_cyclesクロック後に
    program_mem_read_readyとprogram_mem_read_dataを返す。

    read_delay_cycles:
        0以下 : valid検出時に即時応答
        1     : 1クロック後に応答
        N     : 1〜Nクロック後にランダム応答
    """
    pending = False
    pending_address = 0
    delay_count = 0
    request_seen = False

    dut.program_mem_read_ready.value = 0
    dut.program_mem_read_data.value = 0
    dut.program_mem_req_ready.value = 1

    while True:
        await RisingEdge(dut.clock)

        # readyは1クロックパルス
        dut.program_mem_read_ready.value = 0
        dut.program_mem_req_ready.value = 1

        if not bool(dut.reset_n.value):
            pending = False
            pending_address = 0
            delay_count = 0
            request_seen = False

            dut.program_mem_read_ready.value = 0
            dut.program_mem_read_data.value = 0
            continue

        read_valid = bool(
            dut.program_mem_read_valid.value
        )

        # validが下がったら次の要求を受付可能にする
        if not read_valid:
            request_seen = False

        # ------------------------------------------------
        # 保留中の要求へ応答
        # ------------------------------------------------
        if pending:
            if delay_count == 0:
                read_data = read_word(
                    memory,
                    pending_address,
                )

                dut.program_mem_read_data.value = read_data
                dut.program_mem_read_ready.value = 1

                pending = False
            else:
                delay_count -= 1

        # ------------------------------------------------
        # 新しい要求を受付
        # ------------------------------------------------
        if (
            read_valid
            and not request_seen
            and not pending
        ):
            pending_address = int(
                dut.program_mem_read_address.value
            ) & 0xFFFF_FFFF

            request_seen = True

            if read_delay_cycles <= 0:
                read_data = read_word(
                    memory,
                    pending_address,
                )

                dut.program_mem_read_data.value = read_data
                dut.program_mem_read_ready.value = 1
            else:
                # 1〜read_delay_cyclesの範囲で、
                # 要求ごとにランダムな応答遅延を選択
                selected_delay = random.randint(
                    1,
                    read_delay_cycles,
                )

                pending = True
                delay_count = selected_delay - 1

# ------------------------------------------------
# Data memory read model
# ------------------------------------------------
async def data_memory_read_model(
    dut,
    memory: dict[int, int],
    read_delay_cycles: int = 1,
):
    """
    data_mem_read_validを受信してから、
    1〜read_delay_cyclesクロック後に
    data_mem_read_readyとdata_mem_read_dataを返す。

    read_delay_cycles:
        0以下 : valid検出時に即時応答
        1     : 1クロック後に応答
        N     : 1〜Nクロック後にランダム応答
    """
    pending = False
    pending_address = 0
    delay_count = 0
    request_seen = False

    dut.data_mem_read_ready.value = 0
    dut.data_mem_read_data.value = 0
    dut.data_mem_req_ready.value = 1

    while True:
        await RisingEdge(dut.clock)

        dut.data_mem_read_ready.value = 0
        dut.data_mem_req_ready.value = 1

        if not dut.reset_n.value:
            pending = False
            pending_address = 0
            delay_count = 0
            request_seen = False

            dut.data_mem_read_ready.value = 0
            dut.data_mem_read_data.value = 0
            continue

        read_valid = bool(dut.data_mem_read_valid.value)

        # validが下がったら次の要求を受付可能にする
        if not read_valid:
            request_seen = False

        # ------------------------------------------------
        # 保留中の読み出し要求
        # ------------------------------------------------
        if pending:
            if delay_count == 0:
                read_data = read_word(
                    memory,
                    pending_address,
                )

                dut.data_mem_read_data.value = read_data
                dut.data_mem_read_ready.value = 1

                pending = False
            else:
                delay_count -= 1

        # ------------------------------------------------
        # 新しい読み出し要求
        # ------------------------------------------------
        if (
            read_valid
            and not request_seen
            and not pending
        ):
            pending_address = int(
                dut.data_mem_read_address.value
            ) & 0xFFFF_FFFF

            request_seen = True

            if read_delay_cycles <= 0:
                read_data = read_word(
                    memory,
                    pending_address,
                )

                dut.data_mem_read_data.value = read_data
                dut.data_mem_read_ready.value = 1
            else:
                # 1〜read_delay_cyclesの範囲で、
                # 要求ごとにランダムな応答遅延を選択
                selected_delay = random.randint(
                    1,
                    read_delay_cycles,
                )

                pending = True
                delay_count = selected_delay - 1

# ------------------------------------------------
# Data memory write model
# ------------------------------------------------
async def data_memory_write_model(
    dut,
    memory: dict[int, int],
    write_delay_cycles: int = 1,
):
    """
    data_mem_write_validを受信してから、
    1〜write_delay_cyclesクロック後にメモリを書き換え、
    data_mem_write_readyを1クロック通知する。

    write_delay_cycles:
        0以下 : valid検出時に即時書き込み・応答
        1     : 1クロック後に書き込み・応答
        N     : 1〜Nクロック後にランダム応答
    """
    pending = False
    pending_address = 0
    pending_data = 0
    pending_write_sel = 0
    delay_count = 0
    request_seen = False

    dut.data_mem_write_ready.value = 0

    while True:
        await RisingEdge(dut.clock)

        dut.data_mem_write_ready.value = 0

        if not dut.reset_n.value:
            pending = False
            pending_address = 0
            pending_data = 0
            pending_write_sel = 0
            delay_count = 0
            request_seen = False

            dut.data_mem_write_ready.value = 0
            continue

        write_valid = bool(dut.data_mem_write_valid.value)

        # validが下がったら次の要求を受付可能にする
        if not write_valid:
            request_seen = False

        # ------------------------------------------------
        # 保留中の書き込み要求
        # ------------------------------------------------
        if pending:
            if delay_count == 0:
                write_word(
                    memory=memory,
                    address=pending_address,
                    data=pending_data,
                    write_sel=pending_write_sel,
                )

                dut.data_mem_write_ready.value = 1

                pending = False
            else:
                delay_count -= 1

        # ------------------------------------------------
        # 新しい書き込み要求
        # ------------------------------------------------
        if (
            write_valid
            and not request_seen
            and not pending
        ):
            pending_address = int(
                dut.mem_write_address.value
            ) & 0xFFFF_FFFF

            pending_data = int(
                dut.mem_write_data.value
            ) & 0xFFFF_FFFF

            pending_write_sel = int(
                dut.mem_write_sel.value
            ) & 0x7

            request_seen = True

            if write_delay_cycles <= 0:
                write_word(
                    memory=memory,
                    address=pending_address,
                    data=pending_data,
                    write_sel=pending_write_sel,
                )

                dut.data_mem_write_ready.value = 1
            else:
                # 1〜write_delay_cyclesの範囲で、
                # 要求ごとにランダムな応答遅延を選択
                selected_delay = random.randint(
                    1,
                    write_delay_cycles,
                )

                pending = True
                delay_count = selected_delay - 1

# ------------------------------------------------
# MMU memory model
# ------------------------------------------------
async def mmu_memory_model(
    dut,
    memory: dict[int, int],
):
    """
    MMUのページテーブルアクセス用メモリモデル。

    mmu_data_mem_read_validを受信し、
    1クロック後にread_readyとread_dataを返す。
    """
    pending = False
    pending_address = 0

    dut.mmu_data_mem_read_ready.value = 0
    dut.mmu_data_mem_read_data.value = 0
    dut.mmu_data_req_ready.value = 1

    while True:
        await RisingEdge(dut.clock)

        dut.mmu_data_mem_read_ready.value = 0
        dut.mmu_data_req_ready.value = 1

        if not dut.reset_n.value:
            pending = False
            pending_address = 0
            dut.mmu_data_mem_read_data.value = 0
            continue

        # 前サイクルの要求へ応答
        if pending:
            read_data = read_word(memory, pending_address)

            dut.mmu_data_mem_read_data.value = read_data
            dut.mmu_data_mem_read_ready.value = 1

            pending = False

        # 新しい要求を受け付ける
        if dut.mmu_data_mem_read_valid.value:
            pending_address = int(
                dut.mmu_data_mem_read_address.value
            ) & 0xFFFF_FFFF

            pending = True


# ------------------------------------------------
# CPU cycle counter
# ------------------------------------------------
async def cpu_cycle_counter(dut):
    cycle = 0

    while True:
        await RisingEdge(dut.clock)

        if not dut.reset_n.value:
            cycle = 0
        else:
            cycle = (cycle + 1) & 0xFFFF_FFFF

        dut.csr_CPU_MON_CYCLE.value = cycle


# ------------------------------------------------
# Test
# ------------------------------------------------
@cocotb.test()
async def RV32ISP_CPU_core_test(dut):
    dut._log.info("Start PSC_RV32ISP test")
    dut._log.info("TOHOST_ADDR=0x%08X", TOHOST_ADDR)

    initialize_dut_inputs(dut)
    memory = load_word_memory(PROGRAM_FILE)

    random.seed(12345)

    cocotb.start_soon(generate_clock(dut, CLK_PERIOD_NS))
    cocotb.start_soon(program_memory_model(dut, memory, read_delay_cycles=PROGRAM_READ_CYCLE,))
    cocotb.start_soon(data_memory_read_model(dut, memory, read_delay_cycles=DATA_READ_CYCLE,))
    cocotb.start_soon(data_memory_write_model(dut, memory, write_delay_cycles=DATA_WRITE_CYCLE,))
    cocotb.start_soon(mmu_memory_model(dut, memory))

    await reset_dut(dut)

    expected_result = int(
        os.getenv("EXPECTED_RESULT", "0x00000001"),
        0,
    ) & 0xFFFF_FFFF

    result = await watch_tohost_result(
        dut,
        tohost_address=TOHOST_ADDR,
        expected_value=expected_result,
        timeout_cycles=RUN_CYCLES,
    )

    result &= 0xFFFF_FFFF

    assert result == expected_result, (
        f"RISC-V ISA test failed: "
        f"expected=0x{expected_result:08X}, "
        f"actual=0x{result:08X}, "
        f"diff=0x{(expected_result - result) & 0xFFFF_FFFF:08X}"
    )

    dut._log.info(
        "RISC-V ISA test PASS: "
        "expected=0x%08X actual=0x%08X",
        expected_result,
        result,
    )