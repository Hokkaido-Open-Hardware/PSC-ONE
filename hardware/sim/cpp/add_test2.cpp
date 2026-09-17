#include <cstdint>

/* ---------- PIO ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

/* ---------- result ---------- */
extern "C" volatile uint32_t result;

/* ---------- テストパターン ---------- */
static const int32_t test_vals[] = {
    0,
    1,
    -1,
    2,
    -2,
    0x7FFFFFFF,
    (int32_t)0x80000000u,
};

/* ---------- エントリ ---------- */
extern "C" void run() {
    uint32_t error_count = 0;

    const int N = sizeof(test_vals) / sizeof(test_vals[0]);

    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            int32_t a = test_vals[i];
            int32_t b = test_vals[j];

            int32_t c = a + b;

            // 期待値（C++同士だが重要なのはCPUの演算結果）
            int32_t expected = a + b;

            if (c != expected) {
                error_count++;
            }
        }
    }

    result = error_count;

    // 終了通知
    PIO32 = TEST_END_CODE;

    // エラー数出力
    PIO32 = result;

    while (1) { }
}

/* ---------- 定義 ---------- */
extern "C" {
    volatile uint32_t result = 0;
}