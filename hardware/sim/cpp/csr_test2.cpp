#include <cstdint>

/* ---------- アサーション用PIO出力 ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

/* ---------- 共有出力 ---------- */
extern "C" volatile uint32_t result;
extern "C" volatile uint32_t results[8];

/* ---------- CSR番号 ---------- */
#define CSR_MSTATUS   0x300u
#define CSR_MISA      0x301u
#define CSR_MEDELEG   0x302u
#define CSR_MIE       0x304u
#define CSR_MTVEC     0x305u
#define CSR_MSCRATCH  0x340u
#define CSR_MEPC      0x341u
#define CSR_MCAUSE    0x342u
#define CSR_MTVAL     0x343u
#define CSR_MIP       0x344u

/* ---------- CSRユーティリティ（CSR番号はテンプレート即値） ---------- */
template <uint32_t CSR>
static inline uint32_t read_csr() {
    uint32_t v;
    asm volatile ("csrr %0, %1" : "=r"(v) : "i"(CSR));
    return v;
}

template <uint32_t CSR>
static inline void write_csr(uint32_t v) {
    asm volatile ("csrw %0, %1" :: "i"(CSR), "r"(v));
}

template <uint32_t CSR>
static inline void set_csr(uint32_t mask) {
    asm volatile ("csrs %0, %1" :: "i"(CSR), "r"(mask));
}

template <uint32_t CSR>
static inline void clr_csr(uint32_t mask) {
    asm volatile ("csrc %0, %1" :: "i"(CSR), "r"(mask));
}

/* ---------- ビット定義 ---------- */
#define MSTATUS_MIE   (1u << 3)   // mstatus.MIE
#define MIE_MTIE      (1u << 7)   // mie.MTIE

/* ---------- 期待値 ---------- */
static constexpr uint32_t EXPECT_MCAUSE_M_ECALL = 11u;   // ECALL from M-mode

/* ========== M-Mode Trap ハンドラ ==========
   ・mcause/mepc を results[6], results[7] に保存
   ・mepc += 4 して元の次命令へ戻る（mret）
*/
extern "C" void mv_trap_handler(void);
asm(
".section .text                    \n"
".align  2                         \n"
".globl  mv_trap_handler           \n"
".type   mv_trap_handler, @function\n"
"mv_trap_handler:                  \n"
"    la    t3, results             \n"
"    csrr  t0, mcause              \n"
"    sw    t0, 24(t3)              \n" /* results[6] = mcause */
"    csrr  t1, mepc                \n"
"    sw    t1, 28(t3)              \n" /* results[7] = mepc(before) */
"    addi  t1, t1, 4               \n"
"    csrw  mepc, t1                \n" /* 次命令へ戻す */
"    li    t0, 0x10001000          \n"
"    li    t2, 0xEEEE0001          \n"
"    sw    t2, 0(t0)               \n"
"    mret                          \n"
".size mv_trap_handler, .-mv_trap_handler\n"
);

/* ---------- アサート補助 ---------- */
static inline void note_fail(uint32_t &fail, uint32_t bit) {
    fail |= bit;
}

/* ---------- エントリ ---------- */
extern "C" void run() {
    uint32_t fail = 0;

    // 0) mtvec を M-Mode direct ハンドラに設定
    const uint32_t handler_addr = reinterpret_cast<uint32_t>(&mv_trap_handler);
    write_csr<CSR_MTVEC>(handler_addr);

    // 1) 初期CSR読み出し（ログ用）
    results[0] = read_csr<CSR_MSTATUS>();
    results[1] = read_csr<CSR_MSCRATCH>();
    results[5] = read_csr<CSR_MISA>();

    // 2) mscratch RW テスト
    write_csr<CSR_MSCRATCH>(0xA5A5A5A5u);
    results[1] = read_csr<CSR_MSCRATCH>();
    if (results[1] != 0xA5A5A5A5u) {
        note_fail(fail, 1u << 0);
    }

    // 3) mstatus.MIE の RS/RC テスト
    set_csr<CSR_MSTATUS>(MSTATUS_MIE);
    uint32_t mstatus1 = read_csr<CSR_MSTATUS>();
    if ((mstatus1 & MSTATUS_MIE) == 0) {
        note_fail(fail, 1u << 1);
    }

    set_csr<CSR_MSTATUS>(0u);
    uint32_t mstatus2 = read_csr<CSR_MSTATUS>();
    if (mstatus2 != mstatus1) {
        // no-side-effect 前提なら等しい
    }

    PIO32 = 0x00C1;

    clr_csr<CSR_MSTATUS>(MSTATUS_MIE);
    uint32_t mstatus3 = read_csr<CSR_MSTATUS>();
    if ((mstatus3 & MSTATUS_MIE) != 0) {
        note_fail(fail, 1u << 2);
    }

    PIO32 = 0x00C2;

    // 4) mie.MTIE の RS テスト
    set_csr<CSR_MIE>(MIE_MTIE);
    uint32_t mie1 = read_csr<CSR_MIE>();
    if ((mie1 & MIE_MTIE) == 0) {
        note_fail(fail, 1u << 3);
    }

    PIO32 = 0x00C3;

    // 5) ecall → M-mode trap → mret の往復確認
    volatile uint32_t marker_before = 0xDEAD0000u;
    volatile uint32_t marker_after  = 0;
    (void)marker_before;

    PIO32 = 0x00C4;

    PIO32 = 0x00A1;
    asm volatile ("ecall");
    PIO32 = 0x00A2;
    marker_after = 0xBEEF1234u;

    const uint32_t mcause = results[6];
    const uint32_t mepc_b = results[7];

    if (mcause != EXPECT_MCAUSE_M_ECALL) {
        note_fail(fail, 1u << 4);
    }
    if (marker_after != 0xBEEF1234u) {
        note_fail(fail, 1u << 5);
    }

    // 6) ログ保存
    results[2] = mstatus1;
    results[3] = mstatus3;
    results[4] = mie1;
    results[6] = mcause;
    results[7] = mepc_b;

    // ===== 合否書き込み =====
    if (fail == 0) {
        result = 0x0321u;
    } else {
        result = 0xBAD00000u | fail;
    }

    // テスト終了通知
    PIO32 = TEST_END_CODE;
    PIO32 = result;

    while (1) { }
}

/* ---------- 実体 ---------- */
extern "C" {
    volatile uint32_t result = 0;
    volatile uint32_t results[8] = {0};
}