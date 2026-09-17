# =========================================================
# PSC_RV32IS: cocotb top test 
#   - 安全な int 変換 (X/Z 解決)
#   - レベル待ち + タイムアウト
#   - ユーティリティ関数で見通し改善
# =========================================================
import os
import cocotb
from cocotb.triggers import Timer, RisingEdge
from cocotb.handle import SimHandleBase

# prev Bus
from cocotb_tb.rv32_write_mem_data import push_words_to_sdram_from_file
from cocotb_tb.rv32_read_mem_data  import read_words_from_addrs
# AXI4 Bus
from cocotb_tb.rv32_axi_write_mem_data import push_words_to_axi16_from_file
from cocotb_tb.rv32_axi_read_mem_data  import read_words_from_axi16_addrs

# ========= 設定 =========
Assert = 1
col_mismatch_Assert = 0
logfile = os.getenv("PSC_UART_LOGFILE", "./log/default_uart_log.txt")

# ★ MEM_FILE > PROGRAM_FILE > 既定値 の優先順に変更
MEM_FILE_ENV   = os.getenv("MEM_FILE", "").strip()
PROGRAM_FILE   = (MEM_FILE_ENV if MEM_FILE_ENV else
                  os.getenv("PROGRAM_FILE", "./mem_16bit/psc_os.mem"))

EXPECTED_STR = os.getenv("EXPECTED_RESULT", "").strip()
CLK_PERIOD_NS = int(os.getenv("CLK_PERIOD_NS", "10"))     # 100 MHz
#RUN_CYCLES    = int(os.getenv("RUN_CYCLES", "500000"))  # addi Debug
RUN_CYCLES    = int(os.getenv("RUN_CYCLES", "200000000"))
SDRAM_INIT_TIMEOUT = int(os.getenv("SDRAM_INIT_TIMEOUT", "500000"))  # cycles
BOOT_ROM_TIMEOUT   = int(os.getenv("BOOT_ROM_TIMEOUT", "5000000"))  # cycles
# ======================
val_str = os.getenv("EXPECTED_RESULT")
if not val_str or val_str.strip() == "":
    EXPECTED_VALUE = 0x0000001e
else:
    EXPECTED_VALUE = int(val_str, 0)

# ---------- Utils ----------
def int_resolved(x, xfill: str = "0") -> int:
    """
    cocotb 2.0対応: 安全に int 変換（X/Z を解決）
    """
    # Handleの場合
    if isinstance(x, SimHandleBase):
        v = x.value
    else:
        v = x

    # すでに int の場合
    if isinstance(v, int):
        return v
    # LogicArray / Logic の場合
    try:
        s = str(v)   # ← ここがポイント（binstrではない）
    except Exception:
        return 0

    if not s:
        return 0
    # X/Z 解決
    s = s.lower().replace('x', xfill).replace('z', xfill)

    try:
        return int(s, 2)
    except ValueError:
        return 0

async def ncycles(clock, n: int):
    for _ in range(max(0, n)):
        await RisingEdge(clock)


async def wait_level(sig, level: int, clock, timeout_cycles: int | None = None) -> bool:
    """
    sig の値が level(0/1) になるまで待つ。timeout_cycles が None でない場合、超えたら False を返す。
    """
    waited = 0
    while int_resolved(sig) != (1 if level else 0):
        await RisingEdge(clock)
        waited += 1
        if timeout_cycles is not None and waited >= timeout_cycles:
            return False
    return True


def safe_peek(handle: SimHandleBase, default: int = 0) -> int:
    """X/Z 解決付きでハンドル値を int 取得（失敗は default）。"""
    try:
        return int_resolved(handle)
    except Exception:
        return default
# -------------------------

async def generate_clock(dut, period_ns=CLK_PERIOD_NS):
    """Free-running clock."""
    while True:
        dut.clock.value = 0
        await Timer(period_ns // 2, unit="ns")
        dut.clock.value = 1
        await Timer(period_ns // 2, unit="ns")

def GW2AR_sdram_read32(dut, paddr):
    """GW2AR の SDRAM の物理アドレス paddr から 32bit を読む"""
    index = paddr >> 2      # 32bit 単位
    # mem[] が dut.sdram_inst.mem などの場合は適宜修正
    data = dut.u_sdram_model.mem[index].value.to_unsigned()

    return data

def sdram_read32(dut, paddr):
    """SDRAM の物理アドレス paddr から 32bit を読む"""
    index = paddr >> 1      # 16bit 単位
    # mem[] が dut.sdram_inst.mem などの場合は適宜修正
    lo = dut.u_sdram_model.mem[index].value.to_unsigned()
    hi = dut.u_sdram_model.mem[index + 1].value.to_unsigned()

    return (hi << 16) | lo

def dump_page_table(dut, root_pt_paddr):
    print("\n===== PAGE TABLE DUMP (from SDRAM) =====")
    log = None
    if logfile is not None:
        log = open(logfile, "a")

    line = f"L1 root @ 0x{root_pt_paddr:08x}"
    print(line)
    if log:
        log.write("\n===== PAGE TABLE DUMP (from SDRAM) =====\n")
        log.write(line + "\n")

    try:
        # L1 = 1024 entries
        for vpn1 in range(1024):

            l1_pte_addr = root_pt_paddr + vpn1 * 4
            l1_pte = sdram_read32(dut, l1_pte_addr)

            if (l1_pte & 0x1) == 0:
                continue  # invalid entry

            ppn1 = (l1_pte >> 10) & 0xFFFFF
            l0_addr = ppn1 << 12

            line = f"\nL1[{vpn1:03}] PTE={l1_pte:08x}  → L0 @ 0x{l0_addr:08x}"
            print(line)
            log.write(line + "\n")

            # L0 を走査
            for vpn0 in range(1024):

                l0_pte_addr = l0_addr + vpn0 * 4
                l0_pte = sdram_read32(dut, l0_pte_addr)

                if (l0_pte & 0x1) == 0:
                    continue

                ppn0 = (l0_pte >> 10) & 0xFFFFF
                phys = ppn0 << 12

                flags = l0_pte & 0x3FF

                line = f"  L0[{vpn0:03}] PTE={l0_pte:08x}  → PADDR=0x{phys:08x} flags={flags:03x}"
                print(line)
                log.write(line + "\n")
    finally:
        log.write("\n")
        log.close()

    print("===== PAGE TABLE END =====\n")

def dump_sdram_mem(dut, mode, start_addr, datanum=16):
    print("\n===== MEM DUMP (from SDRAM) =====")
    log = None
    if logfile is not None:
        log = open(logfile, "a")

    try:
        log.write("===== MEM DUMP (from SDRAM) =====\n")
        for i in range(datanum):
            if mode == "GW2AR":
                raddr = start_addr + i * 4
                rdata = GW2AR_sdram_read32(dut, raddr)
                line = f"raddr = {raddr:08x} : rdata = {rdata:08x}"
                print(line)
                log.write(line + "\n")
            else :
                raddr = start_addr + i * 4
                rdata = sdram_read32(dut, raddr)
                line = f"raddr = {raddr:08x} : rdata = {rdata:08x}"
                print(line)
                log.write(line + "\n")
    finally:
        log.write("\n")
        log.close()

    print("===== MEM DUMP END =====\n")

# ---------- メインテスト ---------------
@cocotb.test()
async def RV32IS_chip_test1(dut):
    dut._log.info("==============================================================")
    dut._log.info("Start PSC_RV32IS PSC_OS test")
    dut._log.info("Boot from ROM")

    dut._log.info("==============================================================")
    dut._log.info("Start PSC_RV32IS Chip test")
    dut._log.info(f"[CONF] PROGRAM_FILE={PROGRAM_FILE}")
    if not os.path.exists(PROGRAM_FILE):
        dut._log.info(f"[FAIL] PROGRAM_FILE not found: {PROGRAM_FILE}")

    rom_write_num = dut.u_chip.u_bt_rom.ROM_WORD.value
    dut._log.info(f"PSC_RV32IS_Boot_axi ROM_WORD : {rom_write_num}")

    cocotb.start_soon(generate_clock(dut, CLK_PERIOD_NS))

    # ---- reset & hold CPU ----
    dut.PIO_external_in.value  = 3          # PIO_IN = 3 for PIO_test1.cpp　　
    dut.uart_rx.value          = 0
    dut.rst.value              = 0

    #dump_sdram_mem(dut, 0x0000_0000, 24)
    #dump_page_table(dut, 0x024)

    # ---- reset ----
    await ncycles(dut.clock, 2)
    dut.rst.value              = 1
    await ncycles(dut.clock, 50)
    dut.rst.value              = 0

    # ---- SDRAM init level wait (timeout 付き) ----
    ok_init = await wait_level(dut.sdram_init_fin, 1, dut.clock, timeout_cycles=SDRAM_INIT_TIMEOUT)
    if not ok_init:
        raise cocotb.result.TestFailure("[FAIL] Timeout waiting for sdram_init_fin == 1")
    await ncycles(dut.clock, 100)

    # ---- Boot_rom_done wait (timeout 付き) ----
    ok_init = await wait_level(dut.Boot_rom_done, 1, dut.clock, timeout_cycles=BOOT_ROM_TIMEOUT)
    await ncycles(dut.clock, 100)

    # ---- Run CPU ----
    dut._log.info("Boot_rom_done=H. Start CPU")

    # ---- uart_txをキャプチャしながらウェイト ----
    dut._log.info("Waiting for Uart tx data...")
    timeout_cycles = RUN_CYCLES
    waited = 0

    #dump_sdram_mem(dut, "GW2AR", 0x0000_0000, 24)
    #dump_sdram_mem(dut, 0x0010_0000, 24)
    #dump_sdram_mem(dut, 0x0010_4440, 24)
    
    #dump_sdram_mem(dut, "GW2AR", 0x0020_0000, 24)
    #dump_sdram_mem(dut, 0x0020_1400, 84)
    #dump_sdram_mem(dut, "GW2AR", 0x0040_0000, 24)
    #dump_page_table(dut, 0x024)

    while waited < timeout_cycles:
        await RisingEdge(dut.clock)

        page_fault_i = dut.u_chip.u_core_axi.u_core.i_pf.value
        page_fault_d = dut.u_chip.u_core_axi.u_core.d_pf.value

        # PageFaultでbreak
        if page_fault_i or page_fault_d:
            dut._log.info("==============================================================")
            dut._log.info(f"Page Fault detected: I={page_fault_i}, D={page_fault_d}")
            dump_sdram_mem(dut, 0x0020_0000, 64)
            dump_sdram_mem(dut, 0x0040_0000, 64)
            dump_sdram_mem(dut, 0x0025_B000, 64)
            # SP
            dump_sdram_mem(dut, 0x0027_E000, 1024)

            # 正しい page table の物理アドレスを取得
            satp_val = int(dut.u_chip.u_core_axi.u_core.csr_satp.value)
            ppn = satp_val & 0b11_1111_1111_1111_1111_1111    # 22bit and
            root_pt = ppn << 12

            dut._log.info(f"SATP = 0x{satp_val:08x} → root PT = 0x{root_pt:08x}")
            dump_page_table(dut, root_pt)
            break

        # PIO
        pio_val = safe_peek(dut.u_chip.u_mmap_io.PIO_out_reg, 0)
        if dut.u_chip.u_mmap_io.cpu_wready.value == 1:    # cpu_wvalid=1より1clk遅れだがOK
            dut._log.info(f"PIO data at cycle {waited} = {pio_val:08x}")

        if col_mismatch_Assert == 1:
            col_rmismatch = dut.u_chip.u_4port_sdram_axi.u_sdram_controller.col_rmismatch.value
            col_wmismatch = dut.u_chip.u_4port_sdram_axi.u_sdram_controller.col_wmismatch.value
        else:
            col_rmismatch = 0
            col_wmismatch = 0

        # Burst仕様違反
        if col_rmismatch or col_wmismatch:
            dut._log.info(f"Burst Fault detected: rmismatch={col_rmismatch}, wmismatch={col_wmismatch}")
            break

        uart_val = safe_peek(dut.u_chip.u_uart.cpu_wdata, 0)
        uart_valid = dut.u_chip.u_uart.w_tx_wr.value

        if uart_valid == 1:
            ch = uart_val & 0xFF
            # 表示用文字
            if ch in (0x0A, 0x0D):
                ch_str = "\\n" if ch == 0x0A else "\\r"
                ch_out = "\n"  # ファイルにはそのまま改行
            elif 0x20 <= ch <= 0x7E:
                ch_str = chr(ch)
                ch_out = chr(ch)
            else:
                ch_str = f"\\x{ch:02x}"
                ch_out = ""  # ファイルに入れない（必要なら変更可）
            # UART表示
            dut._log.info(f"uart_tx=0x{uart_val:04x} ({ch_str})")
            # ----------- ファイルを1文字ごとに追記して閉じる -----------
            with open(logfile, "a") as f:
                f.write(ch_out)
            # ----------------------------------------------------------

        # ↓デバッグログ
        if ((waited % 10000000) == 0):
            pc_val  = safe_peek(dut.u_chip.u_core_axi.u_core.pc, 0)
            adr_val = safe_peek(dut.u_chip.u_core_axi.cpu_data_addr, 0)
            dut._log.info(
                f"[dbg] cycle={waited}, uart_tx=0x{uart_val:04x}, "
                f"pc=0x{pc_val:04x}, data_addr=0x{adr_val:08x}"
            )
            log = None
            if logfile is not None:
                log = open(logfile, "a")
                log.write(f"[dbg] cycle={waited}, uart_tx=0x{uart_val:04x}, ")
                log.write(f"pc=0x{pc_val:08x}, data_addr=0x{adr_val:08x}\n")
                log.close()
        
        # waited インクリメント
        waited += 1

    await ncycles(dut.clock, 100000)  # 100000 clockウェイト

    # ---- Stop & settle ----
    dut._log.info("Uart tx-rx wait.")
    await ncycles(dut.clock, 50000)

    # Simulation End
    dut._log.info("Simulation End.")