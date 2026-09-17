# =========================================================
# PSC_RV32ISP: cocotb top test 
#   - 安全な int 変換 (X/Z 解決)
#   - レベル待ち + タイムアウト
#   - ユーティリティ関数で見通し改善
# =========================================================
import os
import cocotb
from cocotb.triggers import Timer, RisingEdge
from cocotb.handle import SimHandleBase
from cocotb.types import LogicArray

# ------------------------------------------------
# 設定
# ------------------------------------------------
Assert = 0

# ---------- ★ ログ書き込み（append） ----------
logfile = os.getenv("PSC_LOGFILE", "./log/test_result_default.log")
os.makedirs("./log", exist_ok=True)

# ★ MEM_FILE > PROGRAM_FILE > 既定値 の優先順に変更
MEM_FILE_ENV   = os.getenv("MEM_FILE", "").strip()
PROGRAM_FILE   = (MEM_FILE_ENV if MEM_FILE_ENV else
                  os.getenv("PROGRAM_FILE", "./mem/test_program.mem"))

EXPECTED_STR = os.getenv("EXPECTED_RESULT", "").strip()
CLK_PERIOD_NS = int(os.getenv("CLK_PERIOD_NS", "10"))     # 100 MHz

# === RUN CYCLE Setting.
#RUN_CYCLES    = int(os.getenv("RUN_CYCLES", "50000"))   # run_test_P setting
#RUN_CYCLES    = int(os.getenv("RUN_CYCLES", "800000"))   # sd_read setting
#RUN_CYCLES    = int(os.getenv("RUN_CYCLES", "3500000"))
RUN_CYCLES    = int(os.getenv("RUN_CYCLES", "5000000000"))  # sa_matrix_test

SDRAM_INIT_TIMEOUT = int(os.getenv("SDRAM_INIT_TIMEOUT", "500000"))  # cycles
BOOT_ROM_TIMEOUT   = int(os.getenv("SDRAM_INIT_TIMEOUT", "5000000"))  # cycles

# ======================
val_str = os.getenv("EXPECTED_RESULT")
if not val_str or val_str.strip() == "":
    EXPECTED_VALUE = 0x0000001e
else:
    EXPECTED_VALUE = int(val_str, 0)

# ------------------------------------------------
# Utils
# ------------------------------------------------
def int_resolved(x, xfill: str = "0") -> int:
    """
    cocotb の値を安全に int 化（X/Z を xfill で解決）。
    - x: SimHandle -> x.value(BinaryValue)
    - x: BinaryValue -> そのまま
    - x: int/他 -> int(x)
    """
    if isinstance(x, SimHandleBase):
        bv: BinaryValue = x.value
    elif isinstance(x, BinaryValue):
        bv = x
    else:
        return int(x)

    s = str(bv)
    if s is None:
        return 0
    s = s.lower().replace('x', xfill).replace('z', xfill)
    try:
        return int(s, 2)
    except ValueError:
        return 0


# ------------------------------------------------
# wait
# ------------------------------------------------
async def ncycles(clock, n: int):
    for _ in range(max(0, n)):
        await RisingEdge(clock)


# ------------------------------------------------
# wait sdram init fin.
# ------------------------------------------------
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
# reset dut
# ------------------------------------------------
async def reset_dut(dut, reset_cycle=50):
    """reset dut"""
    await ncycles(dut.clock, 2)
    dut.rst.value              = 1
    await ncycles(dut.clock, reset_cycle)
    dut.rst.value              = 0

# ------------------------------------------------
# WRITE SDRAM
# ------------------------------------------------
def GW2AR_sdram_read32(dut, paddr):
    """GW2AR の SDRAM の物理アドレス paddr から 32bit を読む"""
    index = paddr      # 32bit 単位
    # mem[] が dut.sdram_inst.mem などの場合は適宜修正
    data = dut.u_sdram_model.mem[index].value.to_unsigned()

    return data

# ------------------------------------------------
# READ SDRAM
# ------------------------------------------------
def sdram_read32(dut, paddr):
    """SDRAM の物理アドレス paddr から 32bit を読む"""
    index = paddr >> 1      # 16bit 単位
    # mem[] が dut.sdram_inst.mem などの場合は適宜修正
    lo = dut.u_sdram_model.mem[index].value.to_unsigned()
    hi = dut.u_sdram_model.mem[index + 1].value.to_unsigned()

    return (hi << 16) | lo

# ------------------------------------------------
# dump SDRAM data
# ------------------------------------------------
def dump_sdram_mem(dut, mode, start_addr, datanum=16):
    print("\n===== MEM DUMP (from SDRAM) =====")
    log = None
    if logfile is not None:
        log = open(logfile, "a")

    try:
        log.write("===== MEM DUMP (from SDRAM) =====\n")
        for i in range(datanum):
            if mode == "GW2AR":
                raddr = start_addr + i
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

# ------------------------------------------------
# Test
# ------------------------------------------------
@cocotb.test()
async def RV32IS_chip_test1(dut):
    dut._log.info("==============================================================")
    dut._log.info("Start PSC_RV32IS Chip test")
    dut._log.info("Boot from ROM")

    dut._log.info("==============================================================")
    dut._log.info("Start PSC_RV32IS Chip test")
    dut._log.info(f"[CONF] PROGRAM_FILE={PROGRAM_FILE}")
    if not os.path.exists(PROGRAM_FILE):
        dut._log.info(f"[FAIL] PROGRAM_FILE not found: {PROGRAM_FILE}")

    rom_write_num = dut.u_chip.u_bt_rom.ROM_WORD.value.to_unsigned()
    dut._log.info(f"PSC_RV32IS_Boot_axi ROM_WORD : {rom_write_num}")

    # ---- clock, rst ----
    cocotb.start_soon(generate_clock(dut, CLK_PERIOD_NS))
    await reset_dut(dut)

    # ---- SDRAM init level wait (timeout 付き) ----
    ok_init = await wait_level(dut.u_chip.sdram_init_fin, 1, dut.clock, timeout_cycles=SDRAM_INIT_TIMEOUT)

    # ---- Boot_rom_done wait (timeout 付き) ----
    ok_init = await wait_level(dut.u_chip.Boot_rom_done, 1, dut.clock, timeout_cycles=BOOT_ROM_TIMEOUT)
    await ncycles(dut.clock, 100)

    # ---- SDRAM Data Dump ----
    #dump_sdram_mem(dut, "GW2AR", 0x0000_0000, 16)
    #dump_sdram_mem(dut, 0x0002_0000, 16)
    #dump_sdram_mem(dut, 0x0002_1200, 4)

    # ---- Run CPU ----
    dut._log.info("Boot_rom_done=H. Start CPU")

    # ---- PIOに0xEE01が出力されるまでウェイト ----
    dut._log.info("Waiting for PIO_out_reg == 0xEE01 ...")
    timeout_cycles = RUN_CYCLES
    waited = 0
    page_falut_str = " NONE "
    page_falut = False
    found = False

    while waited < timeout_cycles:
        await RisingEdge(dut.clock)

        page_fault_i = dut.u_chip.u_core_axi.u_core.i_pf.value
        page_fault_d = dut.u_chip.u_core_axi.u_core.d_pf.value

        # PageFaultでbreak
        if page_fault_i or page_fault_d:
            # 初回のみログ出力
            if(page_falut == False):
                dut._log.info(f"Page Fault detected: I={page_fault_i}, D={page_fault_d}")
            page_falut = True
            page_falut_str = " PF  "
            #found = True
            #break

        # PIO32 = 0xEE01を検出
        pio_val = safe_peek(dut.u_chip.u_mmap_io.PIO_out_reg, 0)
        if pio_val == 0xEE01:
            dut._log.info(f"PIO matched 0xEE01 at cycle {waited}")
            found = True
            break
        elif dut.u_chip.u_mmap_io.cpu_wready.value == 1:    # cpu_wvalid=1より1clk遅れだがOK
            dut._log.info(f"PIO data at cycle {waited} = {pio_val:08x}")

        # waited counter
        waited += 1

    # =====================================
    # ---- Timeout → FAILログ書き込み ----
    # =====================================

    if not found:
        status_str = " FAIL"

        # ヘッダがまだ書かれていなければ追加
        if not os.path.exists(logfile) or os.path.getsize(logfile) == 0:
            with open(logfile, "w") as f:
                f.write("+-----------------------+------------------+------------------+----------+-----------+\n")
                f.write("|   PROGRAM_FILE        |    EXPECTED      |      RESULT      |   PF     |  STATUS   |\n")
                f.write("+-----------------------+------------------+------------------+----------+-----------+\n")

        # RESULT は取得不能なので 0 固定
        with open(logfile, "a") as f:
            f.write("| {:<21} | 0x{:08x}       | 0x{:08x}       | {:<7}  | {:<6}  |\n".format(
                os.path.basename(PROGRAM_FILE),
                EXPECTED_VALUE,
                0,
                page_falut_str,
                status_str
            ))
            f.write("+-----------------------+------------------+------------------+----------+----------+\n")

        dut._log.error("[LOG] Timeout → FAIL written to logfile")

        raise cocotb.result.TestFailure(
            f"[FAIL] Timeout waiting for PIO_out_reg == 0xEE01 (waited {waited} cycles)"
        )

    # 1000 clockウェイト
    await ncycles(dut.clock, 1000)  
    
    # ---- Stop & settle ----
    dut._log.info("Stop CPU")
    await ncycles(dut.clock, 20)

    # ---------- PIO read ----------
    pio_word = None
    try:
        pio_word = int(dut.u_chip.u_mmap_io.PIO_out_reg.value)
        pio_word &= 0xFFFFFFFF
    except Exception as e:
        dut._log.warning(f"[WARN] pio skipped: {e}")

    dut._log.info(
        f"pio.word0={('0x%08x' % pio_word) if pio_word is not None else 'N/A'}, "
        f"expected=0x{EXPECTED_VALUE:08x}"
    )

    ok = (pio_word is not None and pio_word == EXPECTED_VALUE)

    # ★ 追加：PASS/FAIL 判定文字列
    status_str = " ✅ PASS " if ok else " ❌ FAIL"

    # =====================================
    # ---- 結果 → ログ書き込み ----
    # =====================================

    # ヘッダがまだ書かれていなければ追加
    if not os.path.exists(logfile) or os.path.getsize(logfile) == 0:
        with open(logfile, "w") as f:
            f.write("+-----------------------+------------------+------------------+----------+-------------+\n")
            f.write("|   PROGRAM_FILE        |    EXPECTED      |      RESULT      |   PF     |   STATUS    |\n")
            f.write("+-----------------------+------------------+------------------+----------+-------------+\n")

    # 1行追記
    with open(logfile, "a") as f:
        f.write("| {:<21} | 0x{:08x}       | 0x{:08x}       | {:<7}  | {:<6}  |\n".format(
            os.path.basename(PROGRAM_FILE),
            EXPECTED_VALUE,
            pio_word if pio_word is not None else 0,
            page_falut_str,
            status_str
        ))
        f.write("+-----------------------+------------------+------------------+----------+-------------+\n")

    dut._log.info(f"[LOG] Appended to {logfile}")

    # ---------- ★ ここまで ----------
    
    if ok:
        dut._log.info(
            f"[PASS] PIO holds expected 0x{EXPECTED_VALUE:08x}"
        )
    else:
        dut._log.error(
            f"[FAIL] expected=0x{EXPECTED_VALUE:08x}, got=0x{pio_word:08x}"
        )

    if Assert:
        assert ok, (
            f"[FAIL] pio data has expected value: "
            f"pio_word=0x{pio_word:08x}, "
            f"exp=0x{EXPECTED_VALUE:08x}"
        )

    await ncycles(dut.clock, 1000)
