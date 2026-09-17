#include <cstdint>

/* ---------- アサーション用PIO出力 (Byteアドレス) --------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

/* ---------- 宣言（extern：初期化しない） ---------- */
extern "C" volatile uint32_t result;

/* ---------- スタートアップから呼ばれるエントリ ---------- */
extern "C" void run() {

    uint32_t a = 10;
    uint32_t b = 20;
    uint32_t c;
    uint32_t d;

    /* =====================================================
       Test 1: 純R-type RAW hazard
       ===================================================== */

    asm volatile ("add %0, %1, %2" : "=r"(c) : "r"(a), "r"(b));
    asm volatile ("add %0, %1, %2" : "=r"(c) : "r"(c), "r"(b));
    asm volatile ("add %0, %1, %2" : "=r"(c) : "r"(c), "r"(b));
    asm volatile ("add %0, %1, %2" : "=r"(d) : "r"(c), "r"(b));

    // ここで d = 90

    /* =====================================================
       Test 2: パイプライン破壊テスト
       R → ADDI → R
       ===================================================== */

    uint32_t e;

    asm volatile ("add  %0, %1, %2" : "=r"(e) : "r"(d), "r"(b));   // R
    asm volatile ("addi %0, %1, 5"  : "=r"(e) : "r"(e));           // OP-IMM
    asm volatile ("add  %0, %1, %2" : "=r"(e) : "r"(e), "r"(b));   // R

    // 期待値:
    // d = 90
    // +20 = 110
    // +5  = 115
    // +20 = 135

    /* =====================================================
       Test 3: パイプライン完全停止確認
       ADDI → ADDI → ADD
       ===================================================== */

    uint32_t f;

    asm volatile ("addi %0, %1, 1" : "=r"(f) : "r"(e));
    asm volatile ("addi %0, %1, 1" : "=r"(f) : "r"(f));
    asm volatile ("add  %0, %1, %2" : "=r"(f) : "r"(f), "r"(b));

    // 期待:
    // 135 +1 +1 +20 = 157

    result = f;

    /* ---------- テスト終了通知 ---------- */
    PIO32 = TEST_END_CODE;
    PIO32 = result;

    while (1) { }
}

/* ---------- 定義（実体） ---------- */
extern "C" {
    volatile uint32_t result = 0;
}
