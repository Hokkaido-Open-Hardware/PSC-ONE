#include <cstdint>

/* ---------- アサーション用PIO出力 ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

/* ---------- 共有出力 ---------- */
extern "C" volatile uint32_t result;
extern "C" volatile uint32_t results[8];

/* ---------- CSR番号 ---------- */
#define CSR_SSTATUS   0x100u
#define CSR_STVEC     0x105u
#define CSR_SEPC      0x141u
#define CSR_SCAUSE    0x142u
#define CSR_SATP      0x180u

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

/* ---------- fail ビット ---------- */
static inline void note_fail(uint32_t &fail, uint32_t bit) {
    fail |= bit;
}

/* ---------- エントリ ---------- */
extern "C" void run() {
    uint32_t fail = 0;

    /* 0) 初期CSRログ */
    results[0] = read_csr<CSR_SSTATUS>();
    results[1] = read_csr<CSR_SCAUSE>();
    results[2] = read_csr<CSR_SEPC>();
    results[3] = read_csr<CSR_SATP>();

    /* 1) sfence 前マーカー */
    volatile uint32_t marker_before = 0x11112222u;
    volatile uint32_t marker_after  = 0;
    (void)marker_before;   // ★ これを追加

    PIO32 = 0xB1;   // before sfence

    /* 2) sfence.vma 実行 */
    asm volatile ("sfence.vma");

    PIO32 = 0xB2;   // after sfence
    marker_after = 0x33334444u;

    /* 3) sfence 後CSR確認 */
    uint32_t scause_after = read_csr<CSR_SCAUSE>();
    uint32_t sepc_after   = read_csr<CSR_SEPC>();

    results[4] = scause_after;
    results[5] = sepc_after;

    /* ---------- 検証 ---------- */

    // (a) trap が起きていない → scause は変化しない
    if (scause_after != results[1]) {
        note_fail(fail, 1u << 0);
    }

    // (b) sepc が勝手に書き換わっていない
    if (sepc_after != results[2]) {
        note_fail(fail, 1u << 1);
    }

    // (c) sfence 後の命令が実行されている
    if (marker_after != 0x33334444u) {
        note_fail(fail, 1u << 2);
    }

    /* ---------- 結果 ---------- */
    if (fail == 0) {
        result = 0x0F01;   // PASS (識別用)
    } else {
        result = 0xBAD00000u | fail;
    }

    /* 終了通知 */
    PIO32 = TEST_END_CODE;
    PIO32 = result;

    while (1) { }
}

/* ---------- 実体 ---------- */
extern "C" {
    volatile uint32_t result = 0;
    volatile uint32_t results[8] = {0};
}
