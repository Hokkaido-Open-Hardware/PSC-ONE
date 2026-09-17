#include <cstdint>

/* ---------- PIO ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))

static constexpr uint32_t MARK_M_BEFORE_MRET = 0xD001u;
static constexpr uint32_t MARK_S_ENTER       = 0xD002u;
static constexpr uint32_t MARK_S_BEFORE_ECALL= 0xA1u;
static constexpr uint32_t MARK_S_AFTER_SRET  = 0xA2u;
static constexpr uint32_t MARK_S_TRAP        = 0xEEEE0001u;
static constexpr uint32_t MARK_M_TRAP        = 0xEEEE0002u;
static constexpr uint32_t TEST_END_CODE      = 0xEE01u;

/* ---------- 共有出力 ---------- */
extern "C" volatile uint32_t result;
extern "C" volatile uint32_t results[12];

/* ---------- CSR番号 ---------- */
/* Supervisor */
#define CSR_SSTATUS   0x100u
#define CSR_SIE       0x104u
#define CSR_STVEC     0x105u
#define CSR_SSCRATCH  0x140u
#define CSR_SEPC      0x141u
#define CSR_SCAUSE    0x142u
#define CSR_STVAL     0x143u
#define CSR_SATP      0x180u

/* Machine */
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

/* ---------- CSRユーティリティ ---------- */
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
#define SSTATUS_SIE       (1u << 1)
#define SIE_STIE          (1u << 5)

#define MSTATUS_MPP_SHIFT 11u
#define MSTATUS_MPP_MASK  (3u << MSTATUS_MPP_SHIFT)
#define MSTATUS_MPP_S     (1u << MSTATUS_MPP_SHIFT)   // 01 = S-mode

/* medeleg bit for exception code 9 = ecall from S */
#define MEDELEG_ECALL_S   (1u << 9)

/* ---------- 期待値 ---------- */
static constexpr uint32_t EXPECT_SCAUSE_S_ECALL = 9u;

/* ---------- アサート補助 ---------- */
static inline void note_fail(uint32_t &fail, uint32_t bit) {
    fail |= bit;
}

/* ========== S-Mode Trap Handler ==========
   - scause/sepc/stval を記録
   - sepc += 4
   - sret
*/
extern "C" void sv_trap_handler(void);
asm(
".section .text                    \n"
".align  2                         \n"
".globl  sv_trap_handler           \n"
".type   sv_trap_handler, @function\n"
"sv_trap_handler:                  \n"
"    la    t3, results             \n"
"    csrr  t0, scause              \n"
"    sw    t0, 24(t3)              \n" /* results[6] = scause */
"    csrr  t1, sepc                \n"
"    sw    t1, 28(t3)              \n" /* results[7] = sepc(before) */
"    csrr  t2, stval               \n"
"    sw    t2, 32(t3)              \n" /* results[8] = stval */

"    li    t0, 0x10001000          \n"
"    li    t2, 0xEEEE0001          \n"
"    sw    t2, 0(t0)               \n"

"    csrr  t1, sepc                \n"
"    addi  t1, t1, 4               \n"
"    csrw  sepc, t1                \n"
"    sret                          \n"
".size sv_trap_handler, .-sv_trap_handler\n"
);

/* ========== M-Mode Trap Handler ==========
   S-mode ecall テスト中にここへ来たらおかしいので、印を残して停止
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
"    sw    t0, 36(t3)              \n" /* results[9]  = mcause */
"    csrr  t1, mepc                \n"
"    sw    t1, 40(t3)              \n" /* results[10] = mepc */
"    csrr  t2, mtval               \n"
"    sw    t2, 44(t3)              \n" /* results[11] = mtval */

"    li    t0, 0x10001000          \n"
"    li    t2, 0xEEEE0002          \n"
"    sw    t2, 0(t0)               \n"

"1:  j     1b                      \n"
".size mv_trap_handler, .-mv_trap_handler\n"
);

/* ---------- S-mode 本体 ---------- */
extern "C" void s_mode_main() {
    uint32_t fail = 0;

    PIO32 = MARK_S_ENTER;

    // 1) 初期CSR読み出し
    results[0] = read_csr<CSR_SSTATUS>();
    results[1] = read_csr<CSR_SSCRATCH>();
    results[5] = read_csr<CSR_SATP>();

    // 2) sscratch RW
    write_csr<CSR_SSCRATCH>(0xA5A5A5A5u);
    results[1] = read_csr<CSR_SSCRATCH>();
    if (results[1] != 0xA5A5A5A5u) note_fail(fail, 1u << 0);

    // 3) sstatus.SIE RS/RC
    set_csr<CSR_SSTATUS>(SSTATUS_SIE);
    uint32_t sstatus1 = read_csr<CSR_SSTATUS>();
    if ((sstatus1 & SSTATUS_SIE) == 0) note_fail(fail, 1u << 1);

    set_csr<CSR_SSTATUS>(0u); // RS(zero) -> no side effect
    uint32_t sstatus2 = read_csr<CSR_SSTATUS>();
    (void)sstatus2;

    clr_csr<CSR_SSTATUS>(SSTATUS_SIE);
    uint32_t sstatus3 = read_csr<CSR_SSTATUS>();
    if ((sstatus3 & SSTATUS_SIE) != 0) note_fail(fail, 1u << 2);

    // 4) sie.STIE
    set_csr<CSR_SIE>(SIE_STIE);
    uint32_t sie1 = read_csr<CSR_SIE>();
    if ((sie1 & SIE_STIE) == 0) note_fail(fail, 1u << 3);

    // 5) S-mode ecall -> S trap -> sret
    volatile uint32_t marker_before = 0xDEAD0000u;
    volatile uint32_t marker_after  = 0u;
    (void)marker_before;

    PIO32 = MARK_S_BEFORE_ECALL;
    asm volatile ("ecall");
    PIO32 = MARK_S_AFTER_SRET;
    marker_after = 0xBEEF1234u;

    const uint32_t scause = results[6];
    const uint32_t sepc_b = results[7];

    if (scause != EXPECT_SCAUSE_S_ECALL) note_fail(fail, 1u << 4);
    if (marker_after != 0xBEEF1234u)     note_fail(fail, 1u << 5);

    // ログ保存
    results[2] = sstatus1;
    results[3] = sstatus3;
    results[4] = sie1;
    results[6] = scause;
    results[7] = sepc_b;

    // 合否
    if (fail == 0) {
        result = 0x0321u;
    } else {
        result = 0xBAD00000u | fail;
    }

    PIO32 = TEST_END_CODE;
    PIO32 = result;

    while (1) { }
}

/* ---------- エントリ（M-mode 開始） ---------- */
extern "C" void run() {
    // 0) M trap handler 設定
    const uint32_t m_handler_addr = reinterpret_cast<uint32_t>(&mv_trap_handler);
    write_csr<CSR_MTVEC>(m_handler_addr);

    // 1) S trap handler 設定
    const uint32_t s_handler_addr = reinterpret_cast<uint32_t>(&sv_trap_handler);
    write_csr<CSR_STVEC>(s_handler_addr);

    // 2) ecall from S を S-mode に delegation
    uint32_t medeleg = read_csr<CSR_MEDELEG>();
    medeleg |= MEDELEG_ECALL_S;
    write_csr<CSR_MEDELEG>(medeleg);

    // 3) mstatus.MPP = S
    uint32_t mstatus = read_csr<CSR_MSTATUS>();
    mstatus &= ~MSTATUS_MPP_MASK;
    mstatus |= MSTATUS_MPP_S;
    write_csr<CSR_MSTATUS>(mstatus);

    // 4) mepc = s_mode_main
    const uint32_t s_entry = reinterpret_cast<uint32_t>(&s_mode_main);
    write_csr<CSR_MEPC>(s_entry);

    // 5) M->S へ降りる
    PIO32 = MARK_M_BEFORE_MRET;
    asm volatile ("mret");

    // ここには戻らない想定
    PIO32 = 0xDEAD0001u;
    while (1) { }
}

/* ---------- 実体 ---------- */
extern "C" {
    volatile uint32_t result = 0;
    volatile uint32_t results[12] = {0};
}