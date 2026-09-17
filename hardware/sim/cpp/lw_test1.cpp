// lw_rd_check.cpp
#include <cstdint>

/* ===== MMIO ===== */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000))

/* ===== テスト用 ===== */
static constexpr uint32_t TEST_ADDR = 0x00423000;
static constexpr uint32_t TEST_VAL  = 0xDEADBEEF;

/* PIO codes */
static constexpr uint32_t PASS = 0xC0DEC0DE;
static constexpr uint32_t FAIL = 0xBAD0BAD0;

extern "C" void run() {
    volatile uint32_t* mem = reinterpret_cast<volatile uint32_t*>(TEST_ADDR);

    /* 1) メモリに書く（sw） */
    *mem = TEST_VAL;
    asm volatile ("" ::: "memory");

    /* -------------------------------------------------
     * 2) rd = x5 (t0) を明示的に使って lw
     * ------------------------------------------------- */
    uint32_t rd_x5;
    asm volatile (
        "lw x5, 0(%1)\n"   // rd = x5 を明示
        "mv %0, x5\n"      // x5 を C++ 変数へ READ
        : "=r"(rd_x5)
        : "r"(mem)
        : "x5", "memory"
    );

    /* 比較 */
    if (rd_x5 == TEST_VAL) {
        PIO32 = 0xA0050000 | (rd_x5 & 0xFFFF); // x5 OK の印
    } else {
        PIO32 = FAIL;
        while (1) {}
    }

    /* -------------------------------------------------
     * 3) rd = x1 (ra) を明示的に使って lw
     * ------------------------------------------------- */
    uint32_t rd_x1;
    asm volatile (
        "lw x1, 0(%1)\n"   // rd = x1 (ra)
        "mv %0, x1\n"      // x1 を READ
        : "=r"(rd_x1)
        : "r"(mem)
        : "x1", "memory"
    );

    if (rd_x1 == TEST_VAL) {
        PIO32 = 0xA0010000 | (rd_x1 & 0xFFFF); // ra OK の印
    } else {
        PIO32 = FAIL;
        while (1) {}
    }

    /* -------------------------------------------------
     * 4) rd = x0 (zero) を指定した lw（結果は捨てられる）
     *    → その後 x0 を READ して 0 のままか確認
     * ------------------------------------------------- */
    uint32_t rd_x0;
    asm volatile (
        "lw x0, 0(%1)\n"   // rd = x0（仕様上、書いても無効）
        "mv %0, x0\n"
        : "=r"(rd_x0)
        : "r"(mem)
        : "memory"
    );

    if (rd_x0 == 0) {
        PIO32 = 0xEE01;
        PIO32 = PASS;      // rd=0 の扱いも正しい
    } else {
        PIO32 = 0xEE01;
        PIO32 = FAIL;
        while (1) {}
    }

    while (1) {}
}
