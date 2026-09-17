#include <cstdint>

/* ---------- PIO ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

/* ---------- extern result ---------- */
extern "C" volatile uint32_t result;

/* ---------- entry ---------- */
extern "C" void run()
{
    uint32_t a = 3;
    uint32_t b = 7;

    // ★ ここで必ず __mulsi3 が呼ばれる
    uint32_t c = a * b;

    // 結果確認（3 * 7 = 21）
    PIO32 = c;
    result = c;

    // 終了コード
    PIO32 = TEST_END_CODE;
    PIO32 = result;

    while (1) { }
}

/* ---------- storage ---------- */
extern "C" {
    volatile uint32_t result = 0;
}
