# cocotb_tb/mmu/mmu_bare_test.py

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb.utils import get_sim_time


CLOCK_PERIOD_NS = 10


async def reset_dut(dut):
    """DUTをリセットする。"""

    dut.reset_n.value = 0

    dut.MMU_enb.value = 0
    dut.vaddr.value = 0
    dut.satp.value = 0
    dut.priv_mode.value = 0

    dut.access_r.value = 0
    dut.access_w.value = 0
    dut.access_x.value = 0

    dut.mem_req_ready.value = 0
    dut.mem_rdata.value = 0
    dut.mem_ready.value = 0

    dut.cpu_state_done.value = 0
    dut.sfence_vma.value = 0

    for _ in range(5):
        await RisingEdge(dut.clk)

    dut.reset_n.value = 1

    for _ in range(2):
        await RisingEdge(dut.clk)


async def mmu_translate(
    dut,
    vaddr: int,
    satp: int,
    priv_mode: int,
    access_r: int = 1,
    access_w: int = 0,
    access_x: int = 0,
    timeout_cycles: int = 20,
) -> int:

    dut.vaddr.value = vaddr
    dut.satp.value = satp
    dut.priv_mode.value = priv_mode

    dut.access_r.value = access_r
    dut.access_w.value = access_w
    dut.access_x.value = access_x

    dut.MMU_enb.value = 1
    await RisingEdge(dut.clk)
    dut.MMU_enb.value = 0

    for _ in range(timeout_cycles):
        await RisingEdge(dut.clk)

        assert int(dut.mem_valid.value) == 0, (
            "Bare/bypass mode must not issue a PTE memory request"
        )

        if int(dut.mmu_done.value):
            return int(dut.paddr.value)

    raise TimeoutError(
        f"MMU translation timed out: "
        f"vaddr=0x{vaddr:08X}, "
        f"satp=0x{satp:08X}, "
        f"priv_mode={priv_mode:02b}"
    )

async def respond_pte_read(
    dut,
    expected_addr: int,
    pte_data: int,
    timeout_cycles: int = 20,
):
    """
    MMUのPTE読出し要求を待ち、PTEデータを返す。

    mem_valid:
        MMUが出力する1クロックの読出し要求

    mem_ready:
        テスト側が返すPTE応答
    """

    for _ in range(timeout_cycles):
        await RisingEdge(dut.clk)

        if int(dut.mem_valid.value):
            actual_addr = int(dut.mem_addr.value)

            assert actual_addr == expected_addr, (
                f"PTE address mismatch: "
                f"expected=0x{expected_addr:08X}, "
                f"actual=0x{actual_addr:08X}"
            )

            dut.mem_rdata.value = pte_data
            dut.mem_ready.value = 1

            await RisingEdge(dut.clk)

            dut.mem_ready.value = 0
            dut.mem_rdata.value = 0
            return

    raise TimeoutError(
        f"PTE read request timeout: "
        f"expected_addr=0x{expected_addr:08X}"
    )

# ------------------------------------------------
# TEST 1: bare test.
# ------------------------------------------------
@cocotb.test()
async def mmu_bare_mode_test1(dut):
    """
    satp.MODE=0のBareモードテスト。

    確認項目:
      - mode_sv32 == 0
      - mem_validが立たない
      - page_faultが立たない
      - paddr == vaddr
      - mmu_doneが返る
    """

    cocotb.start_soon(
        Clock(
            dut.clk,
            CLOCK_PERIOD_NS,
            unit="ns",
        ).start()
    )

    await reset_dut(dut)

    test_addresses = [
        0x0000_0000,
        0x0000_0278,
        0x0012_3456,
        0x0040_0000,
        0x8000_0000,
        0xFFFF_FFFC,
    ]

    for vaddr in test_addresses:
        paddr = await mmu_translate(
            dut,
            vaddr=vaddr,
            satp=0x0000_0000,
            priv_mode=0b01,
        )

        assert int(dut.mode_sv32.value) == 0, (
            "mode_sv32 must be 0 when satp.MODE=0"
        )

        assert int(dut.page_fault.value) == 0, (
            f"Unexpected page fault in Bare mode: "
            f"vaddr=0x{vaddr:08X}"
        )

        assert paddr == vaddr, (
            f"Bare address mismatch: "
            f"vaddr=0x{vaddr:08X}, "
            f"paddr=0x{paddr:08X}"
        )

        dut.cpu_state_done.value = 1
        await RisingEdge(dut.clk)
        dut.cpu_state_done.value = 0
        await RisingEdge(dut.clk)

        dut._log.info(
            "Bare translation PASS: "
            f"VA=0x{vaddr:08X} -> PA=0x{paddr:08X} "
            f"time={get_sim_time(unit='ns')} ns"
        )

# ------------------------------------------------
# TEST 2: M-mode bypass test
# ------------------------------------------------
@cocotb.test()
async def mmu_m_mode_bypass_test(dut):
    """
    satp.MODE=1でもM-modeではアドレス変換を行わない。

    確認項目:
      - mode_sv32 == 1
      - mem_validが立たない
      - page_faultが立たない
      - paddr == vaddr
      - mmu_doneが返る
    """

    cocotb.start_soon(
        Clock(
            dut.clk,
            CLOCK_PERIOD_NS,
            unit="ns",
        ).start()
    )

    await reset_dut(dut)

    test_addresses = [
        0x0000_0000,
        0x0000_0278,
        0x0012_3456,
        0x0040_0000,
        0x8000_0000,
        0xFFFF_FFFC,
    ]

    for vaddr in test_addresses:
        paddr = await mmu_translate(
            dut,
            vaddr=vaddr,
            satp=0x8000_0000,  # MODE=1
            priv_mode=0b11,    # M-mode
        )

        assert int(dut.mode_sv32.value) == 1, (
            "mode_sv32 must reflect satp.MODE=1"
        )

        assert int(dut.page_fault.value) == 0, (
            f"Unexpected page fault in M-mode: "
            f"vaddr=0x{vaddr:08X}"
        )

        assert paddr == vaddr, (
            f"M-mode bypass mismatch: "
            f"vaddr=0x{vaddr:08X}, "
            f"paddr=0x{paddr:08X}"
        )

        dut.cpu_state_done.value = 1
        await RisingEdge(dut.clk)
        dut.cpu_state_done.value = 0
        await RisingEdge(dut.clk)

        dut._log.info(
            "M-mode bypass PASS: "
            f"VA=0x{vaddr:08X} -> PA=0x{paddr:08X}"
        )

# ------------------------------------------------
# TEST 3: Sv32 L1 leaf / 4MiB superpage
# ------------------------------------------------
@cocotb.test()
async def mmu_sv32_l1_leaf_test(dut):
    """
    Sv32 L1 Leaf PTEによる4MiBスーパーページ変換。

    VA = 0x12345678
    PA = 0x80745678

    確認項目:
      - mode_sv32 == 1
      - L1 PTEアドレスが正しい
      - PTE読出しが1回だけ
      - page_fault == 0
      - paddrが期待値と一致
      - mmu_doneが返る
    """

    cocotb.start_soon(
        Clock(
            dut.clk,
            CLOCK_PERIOD_NS,
            unit="ns",
        ).start()
    )

    await reset_dut(dut)

    # ------------------------------------------------
    # 仮想アドレス
    # ------------------------------------------------
    vaddr = 0x1234_5678

    vpn1 = (vaddr >> 22) & 0x3FF
    vpn0 = (vaddr >> 12) & 0x3FF
    page_offset = vaddr & 0xFFF

    # ------------------------------------------------
    # SATP
    # ------------------------------------------------
    # ルートページテーブル物理アドレス:
    #   root_ppn << 12 = 0x00100000
    root_ppn = 0x0001_00

    satp = (
        0x8000_0000       # MODE=Sv32
        | root_ppn
    )

    # L1 PTE格納アドレス:
    # root_page_table + vpn1 * 4
    expected_l1_pte_addr = (
        (root_ppn << 12)
        + (vpn1 << 2)
    ) & 0xFFFF_FFFF

    # ------------------------------------------------
    # L1 Leaf PTE
    # ------------------------------------------------
    # PAの4MiBページベースを0x80400000にする。
    #
    # PTE.PPN1 = 0x201
    # PTE.PPN0 = 0
    #
    # V=1
    # R=1
    # W=0
    # X=0
    target_ppn1 = 0x201

    l1_pte = (
        (target_ppn1 << 20)
        | (1 << 1)        # R
        | (1 << 0)        # V
    )

    # L1 Leaf:
    # PA[31:22] = PTE.PPN1
    # PA[21:12] = VA.VPN0
    # PA[11:0]  = VA.offset
    expected_paddr = (
        (target_ppn1 << 22)
        | (vpn0 << 12)
        | page_offset
    ) & 0xFFFF_FFFF

    dut._log.info(
        "Sv32 L1 leaf test start: "
        f"VA=0x{vaddr:08X}, "
        f"VPN1=0x{vpn1:03X}, "
        f"VPN0=0x{vpn0:03X}, "
        f"PTE_ADDR=0x{expected_l1_pte_addr:08X}, "
        f"PTE=0x{l1_pte:08X}, "
        f"EXPECTED_PA=0x{expected_paddr:08X}"
    )

    # ------------------------------------------------
    # MMU入力
    # ------------------------------------------------
    dut.vaddr.value = vaddr
    dut.satp.value = satp
    dut.priv_mode.value = 0b01  # S-mode

    dut.access_r.value = 1
    dut.access_w.value = 0
    dut.access_x.value = 0

    # MMUがPTE要求を発行可能
    dut.mem_req_ready.value = 1

    # ------------------------------------------------
    # MMU要求開始
    # ------------------------------------------------
    dut.MMU_enb.value = 1
    await RisingEdge(dut.clk)
    dut.MMU_enb.value = 0

    # L1 PTEを返す
    await respond_pte_read(
        dut,
        expected_addr=expected_l1_pte_addr,
        pte_data=l1_pte,
    )

    # ------------------------------------------------
    # 完了待ち
    # ------------------------------------------------
    for _ in range(20):
        await RisingEdge(dut.clk)

        if int(dut.mmu_done.value):
            actual_paddr = int(dut.paddr.value)

            assert int(dut.mode_sv32.value) == 1, (
                "mode_sv32 must be 1 in Sv32 mode"
            )

            assert int(dut.page_fault.value) == 0, (
                "Unexpected page fault in L1 leaf translation"
            )

            assert actual_paddr == expected_paddr, (
                f"L1 leaf address mismatch: "
                f"VA=0x{vaddr:08X}, "
                f"expected PA=0x{expected_paddr:08X}, "
                f"actual PA=0x{actual_paddr:08X}"
            )

            # L1 LeafなのでL0 PTE要求は発生しない
            await RisingEdge(dut.clk)

            assert int(dut.mem_valid.value) == 0, (
                "L1 leaf must not issue an L0 PTE request"
            )

            dut._log.info(
                "Sv32 L1 leaf PASS: "
                f"VA=0x{vaddr:08X} -> "
                f"PA=0x{actual_paddr:08X}"
            )

            return

    raise TimeoutError(
        f"Sv32 L1 leaf translation timeout: "
        f"VA=0x{vaddr:08X}"
    )

# ------------------------------------------------
# TEST 4: Sv32 L0 leaf / 4KiB page
# ------------------------------------------------
@cocotb.test()
async def mmu_sv32_l0_leaf_test(dut):
    """
    Sv32 L0 Leaf PTEによる4KiBページ変換。

    処理:
      1. L1 PTEを読み出す
      2. L1 PTEをページテーブルポインタとして解釈
      3. L0 PTEを読み出す
      4. L0 Leaf PTEから物理アドレスを生成

    確認項目:
      - mode_sv32 == 1
      - L1 PTEアドレスが正しい
      - L0 PTEアドレスが正しい
      - PTE読出しが2回発生する
      - page_fault == 0
      - paddrが期待値と一致
      - mmu_doneが返る
    """

    cocotb.start_soon(
        Clock(
            dut.clk,
            CLOCK_PERIOD_NS,
            unit="ns",
        ).start()
    )

    await reset_dut(dut)

    # ------------------------------------------------
    # 仮想アドレス
    # ------------------------------------------------
    vaddr = 0x1234_5678

    vpn1 = (vaddr >> 22) & 0x3FF
    vpn0 = (vaddr >> 12) & 0x3FF
    page_offset = vaddr & 0xFFF

    # ------------------------------------------------
    # SATP / ルートページテーブル
    # ------------------------------------------------
    # root page table base:
    #   0x00000100 << 12 = 0x00100000
    root_ppn = 0x0001_00

    satp = (
        0x8000_0000
        | root_ppn
    )

    expected_l1_pte_addr = (
        (root_ppn << 12)
        + (vpn1 << 2)
    ) & 0xFFFF_FFFF

    # ------------------------------------------------
    # L1 Pointer PTE
    # ------------------------------------------------
    # L0ページテーブルを物理アドレス0x00200000へ配置
    l0_table_ppn = 0x0002_00

    # Pointer PTE:
    # PPN = l0_table_ppn
    # V=1
    # R=0, W=0, X=0
    #
    # R=0かつX=0なのでLeafではなくPointerとして扱われる
    l1_pte = (
        (l0_table_ppn << 10)
        | (1 << 0)       # V
    )

    expected_l0_pte_addr = (
        (l0_table_ppn << 12)
        + (vpn0 << 2)
    ) & 0xFFFF_FFFF

    # ------------------------------------------------
    # L0 Leaf PTE
    # ------------------------------------------------
    # 変換先4KiB物理ページ:
    #   PPN = 0x34567
    #   page base = 0x34567000
    target_ppn = 0x34567

    # Leaf PTE:
    # V=1
    # R=1
    # W=0
    # X=0
    l0_pte = (
        (target_ppn << 10)
        | (1 << 1)       # R
        | (1 << 0)       # V
    )

    expected_paddr = (
        (target_ppn << 12)
        | page_offset
    ) & 0xFFFF_FFFF

    dut._log.info(
        "Sv32 L0 leaf test start: "
        f"VA=0x{vaddr:08X}, "
        f"VPN1=0x{vpn1:03X}, "
        f"VPN0=0x{vpn0:03X}, "
        f"L1_ADDR=0x{expected_l1_pte_addr:08X}, "
        f"L1_PTE=0x{l1_pte:08X}, "
        f"L0_ADDR=0x{expected_l0_pte_addr:08X}, "
        f"L0_PTE=0x{l0_pte:08X}, "
        f"EXPECTED_PA=0x{expected_paddr:08X}"
    )

    # ------------------------------------------------
    # MMU入力
    # ------------------------------------------------
    dut.vaddr.value = vaddr
    dut.satp.value = satp
    dut.priv_mode.value = 0b01  # S-mode

    dut.access_r.value = 1
    dut.access_w.value = 0
    dut.access_x.value = 0

    dut.mem_req_ready.value = 1

    # ------------------------------------------------
    # MMU要求開始
    # ------------------------------------------------
    dut.MMU_enb.value = 1
    await RisingEdge(dut.clk)
    dut.MMU_enb.value = 0

    # L1 Pointer PTEを返す
    await respond_pte_read(
        dut,
        expected_addr=expected_l1_pte_addr,
        pte_data=l1_pte,
    )

    # L0 Leaf PTEを返す
    await respond_pte_read(
        dut,
        expected_addr=expected_l0_pte_addr,
        pte_data=l0_pte,
    )

    # ------------------------------------------------
    # MMU完了待ち
    # ------------------------------------------------
    for _ in range(20):
        await RisingEdge(dut.clk)

        if int(dut.mmu_done.value):
            actual_paddr = int(dut.paddr.value)

            assert int(dut.mode_sv32.value) == 1, (
                "mode_sv32 must be 1 in Sv32 mode"
            )

            assert int(dut.page_fault.value) == 0, (
                "Unexpected page fault in L0 leaf translation"
            )

            assert actual_paddr == expected_paddr, (
                f"L0 leaf address mismatch: "
                f"VA=0x{vaddr:08X}, "
                f"expected PA=0x{expected_paddr:08X}, "
                f"actual PA=0x{actual_paddr:08X}"
            )

            dut._log.info(
                "Sv32 L0 leaf PASS: "
                f"VA=0x{vaddr:08X} -> "
                f"PA=0x{actual_paddr:08X}"
            )

            return

    raise TimeoutError(
        f"Sv32 L0 leaf translation timeout: "
        f"VA=0x{vaddr:08X}"
    )

# ------------------------------------------------
# TEST 5: Sv32 L1 invalid PTE page fault
# ------------------------------------------------
@cocotb.test()
async def mmu_sv32_l1_invalid_pte_test(dut):
    """
    Sv32 L1 PTEが無効な場合のPage Faultテスト。

    処理:
      1. L1 PTE読出し要求を受ける
      2. V=0の無効PTEを返す
      3. MMUがPage Faultを返す

    確認項目:
      - mode_sv32 == 1
      - L1 PTEアドレスが正しい
      - page_fault == 1
      - mmu_done == 1
      - L0 PTE読出しが発生しない
    """

    cocotb.start_soon(
        Clock(
            dut.clk,
            CLOCK_PERIOD_NS,
            unit="ns",
        ).start()
    )

    await reset_dut(dut)

    # ------------------------------------------------
    # 仮想アドレス
    # ------------------------------------------------
    vaddr = 0x1234_5678

    vpn1 = (vaddr >> 22) & 0x3FF

    # ------------------------------------------------
    # SATP / ルートページテーブル
    # ------------------------------------------------
    root_ppn = 0x0001_00

    satp = (
        0x8000_0000
        | root_ppn
    )

    expected_l1_pte_addr = (
        (root_ppn << 12)
        + (vpn1 << 2)
    ) & 0xFFFF_FFFF

    # ------------------------------------------------
    # Invalid L1 PTE
    # ------------------------------------------------
    # V=0なので、他のビットに関係なく無効PTE
    invalid_l1_pte = 0x0000_0000

    dut._log.info(
        "Sv32 L1 invalid PTE test start: "
        f"VA=0x{vaddr:08X}, "
        f"VPN1=0x{vpn1:03X}, "
        f"PTE_ADDR=0x{expected_l1_pte_addr:08X}, "
        f"PTE=0x{invalid_l1_pte:08X}"
    )

    # ------------------------------------------------
    # MMU入力
    # ------------------------------------------------
    dut.vaddr.value = vaddr
    dut.satp.value = satp
    dut.priv_mode.value = 0b01  # S-mode

    dut.access_r.value = 1
    dut.access_w.value = 0
    dut.access_x.value = 0

    dut.mem_req_ready.value = 1

    # ------------------------------------------------
    # MMU要求開始
    # ------------------------------------------------
    dut.MMU_enb.value = 1
    await RisingEdge(dut.clk)
    dut.MMU_enb.value = 0

    # V=0の無効PTEを返す
    await respond_pte_read(
        dut,
        expected_addr=expected_l1_pte_addr,
        pte_data=invalid_l1_pte,
    )

    # ------------------------------------------------
    # Page Fault完了待ち
    # ------------------------------------------------
    for _ in range(20):
        await RisingEdge(dut.clk)

        if int(dut.mmu_done.value):
            assert int(dut.mode_sv32.value) == 1, (
                "mode_sv32 must be 1 in Sv32 mode"
            )

            assert int(dut.page_fault.value) == 1, (
                "Invalid L1 PTE must cause a page fault"
            )

            # Invalid L1 PTEなのでL0へ進んではならない
            await RisingEdge(dut.clk)

            assert int(dut.mem_valid.value) == 0, (
                "Invalid L1 PTE must not issue an L0 PTE request"
            )

            dut._log.info(
                "Sv32 L1 invalid PTE PASS: "
                f"VA=0x{vaddr:08X}, "
                f"page_fault={int(dut.page_fault.value)}"
            )

            return

    raise TimeoutError(
        f"Sv32 L1 invalid PTE test timeout: "
        f"VA=0x{vaddr:08X}"
    )

# ------------------------------------------------
# TEST 6: sfence.vma cache flush and re-walk
# ------------------------------------------------
@cocotb.test()
async def mmu_sfence_vma_rewalk_test(dut):
    """
    sfence.vma後にPTEキャッシュが無効化され、
    同じ仮想アドレスでもページウォークが再実行されることを確認する。

    確認手順:
      1. 最初の変換でL1/L0 PTEを読み出す
      2. 同じVAを再変換し、キャッシュヒットする
      3. sfence.vmaを発行する
      4. 同じVAを再変換し、L1/L0 PTEを再び読み出す
    """

    cocotb.start_soon(
        Clock(
            dut.clk,
            CLOCK_PERIOD_NS,
            unit="ns",
        ).start()
    )

    await reset_dut(dut)

    # ------------------------------------------------
    # アドレス設定
    # ------------------------------------------------
    vaddr = 0x1234_5678

    vpn1 = (vaddr >> 22) & 0x3FF
    vpn0 = (vaddr >> 12) & 0x3FF
    page_offset = vaddr & 0xFFF

    # ルートページテーブル
    root_ppn = 0x0001_00
    satp = 0x8000_0000 | root_ppn

    expected_l1_pte_addr = (
        (root_ppn << 12)
        + (vpn1 << 2)
    ) & 0xFFFF_FFFF

    # L0ページテーブル
    l0_table_ppn = 0x0002_00

    l1_pte = (
        (l0_table_ppn << 10)
        | (1 << 0)       # V
    )

    expected_l0_pte_addr = (
        (l0_table_ppn << 12)
        + (vpn0 << 2)
    ) & 0xFFFF_FFFF

    # 最終物理ページ
    target_ppn = 0x34567

    l0_pte = (
        (target_ppn << 10)
        | (1 << 1)       # R
        | (1 << 0)       # V
    )

    expected_paddr = (
        (target_ppn << 12)
        | page_offset
    ) & 0xFFFF_FFFF

    # ------------------------------------------------
    # 共通入力
    # ------------------------------------------------
    dut.vaddr.value = vaddr
    dut.satp.value = satp
    dut.priv_mode.value = 0b01

    dut.access_r.value = 1
    dut.access_w.value = 0
    dut.access_x.value = 0

    dut.mem_req_ready.value = 1

    dut._log.info(
        "sfence.vma re-walk test start: "
        f"VA=0x{vaddr:08X}, "
        f"L1_ADDR=0x{expected_l1_pte_addr:08X}, "
        f"L0_ADDR=0x{expected_l0_pte_addr:08X}, "
        f"EXPECTED_PA=0x{expected_paddr:08X}"
    )

    # ============================================================
    # 1回目：通常のページウォーク
    # ============================================================
    dut.MMU_enb.value = 1
    await RisingEdge(dut.clk)
    dut.MMU_enb.value = 0

    await respond_pte_read(
        dut,
        expected_addr=expected_l1_pte_addr,
        pte_data=l1_pte,
    )

    await respond_pte_read(
        dut,
        expected_addr=expected_l0_pte_addr,
        pte_data=l0_pte,
    )

    for _ in range(20):
        await RisingEdge(dut.clk)

        if int(dut.mmu_done.value):
            actual_paddr = int(dut.paddr.value)

            assert int(dut.page_fault.value) == 0
            assert actual_paddr == expected_paddr

            dut._log.info(
                "First page walk PASS: "
                f"VA=0x{vaddr:08X} -> PA=0x{actual_paddr:08X}"
            )
            break
    else:
        raise TimeoutError("First page walk timed out")

    # MMUをIDLEへ戻す
    dut.cpu_state_done.value = 1
    await RisingEdge(dut.clk)
    dut.cpu_state_done.value = 0
    await RisingEdge(dut.clk)

    # ============================================================
    # 2回目：キャッシュヒット
    # ============================================================
    dut.MMU_enb.value = 1
    await RisingEdge(dut.clk)
    dut.MMU_enb.value = 0

    cache_hit_done = False

    for _ in range(20):
        await RisingEdge(dut.clk)

        assert int(dut.mem_valid.value) == 0, (
            "Second translation should hit the PTE cache"
        )

        if int(dut.mmu_done.value):
            actual_paddr = int(dut.paddr.value)

            assert int(dut.page_fault.value) == 0
            assert actual_paddr == expected_paddr

            cache_hit_done = True

            dut._log.info(
                "PTE cache hit PASS: "
                f"VA=0x{vaddr:08X} -> PA=0x{actual_paddr:08X}"
            )
            break

    assert cache_hit_done, (
        "Second translation did not complete by cache hit"
    )

    # MMUをIDLEへ戻す
    dut.cpu_state_done.value = 1
    await RisingEdge(dut.clk)
    dut.cpu_state_done.value = 0
    await RisingEdge(dut.clk)

    # ============================================================
    # sfence.vma発行
    # ============================================================
    dut.sfence_vma.value = 1
    await RisingEdge(dut.clk)
    dut.sfence_vma.value = 0

    # キャッシュ無効化が反映されるまで1クロック待つ
    await RisingEdge(dut.clk)

    dut._log.info("sfence.vma issued")

    # ============================================================
    # 3回目：sfence.vma後の再ウォーク
    # ============================================================
    dut.MMU_enb.value = 1
    await RisingEdge(dut.clk)
    dut.MMU_enb.value = 0

    # キャッシュが無効化されているため、
    # 再びL1 PTE要求が発生する
    await respond_pte_read(
        dut,
        expected_addr=expected_l1_pte_addr,
        pte_data=l1_pte,
    )

    # 再びL0 PTE要求も発生する
    await respond_pte_read(
        dut,
        expected_addr=expected_l0_pte_addr,
        pte_data=l0_pte,
    )

    for _ in range(20):
        await RisingEdge(dut.clk)

        if int(dut.mmu_done.value):
            actual_paddr = int(dut.paddr.value)

            assert int(dut.page_fault.value) == 0, (
                "Unexpected page fault after sfence.vma"
            )

            assert actual_paddr == expected_paddr, (
                f"Re-walk address mismatch: "
                f"expected=0x{expected_paddr:08X}, "
                f"actual=0x{actual_paddr:08X}"
            )

            dut._log.info(
                "sfence.vma re-walk PASS: "
                f"VA=0x{vaddr:08X} -> PA=0x{actual_paddr:08X}"
            )

            return

    raise TimeoutError(
        "Page-table re-walk after sfence.vma timed out"
    )