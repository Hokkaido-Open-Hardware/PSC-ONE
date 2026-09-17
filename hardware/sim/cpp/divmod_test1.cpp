#include <cstdint>

/* ---------- PIO ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

/* ---------- extern result ---------- */
extern "C" volatile uint32_t result;

/* ---------- entry ---------- */
extern "C" void run()
{
    uint32_t a = 100;
    uint32_t b = 7;

    // ★ 必ず __udivsi3 が呼ばれる
    uint32_t q = a / b;   // 100 / 7 = 14

    // ★ 必ず __umodsi3 が呼ばれる
    uint32_t r = a % b;   // 100 % 7 = 2

    // 確認用に順番に PIO 出力
    PIO32 = q;            // 14
    PIO32 = r;            // 2

    // result には (q << 8) | r を入れる（確認しやすく）
    uint32_t packed = (q << 8) | r; // 0x0E02
    result = packed;

    // 終了コード
    PIO32 = TEST_END_CODE;
    PIO32 = result;

    while (1) { }
}

/* ---------- storage ---------- */
extern "C" {
    volatile uint32_t result = 0;
}
