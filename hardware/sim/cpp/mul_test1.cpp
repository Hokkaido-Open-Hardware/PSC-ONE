#include <cstdint>

/* ---------- アサーション用PIO出力 ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

/* ---------- 宣言（extern：初期化しない） ---------- */
extern "C" volatile uint32_t result;

/* ---------- ソフトウェア乗算（シフト加算） ---------- */
uint32_t multiply(uint32_t a, uint32_t b) {
    uint32_t res = 0;
    while (b != 0) {
        if (b & 1) {
            res += a;
        }
        a <<= 1;
        b >>= 1;
    }
    return res;
}

/* ---------- スタートアップから呼ばれるエントリ ---------- */
extern "C" void run() {
    constexpr int N = 4;

    // test 
    PIO32 = N;

    uint32_t a[N] = {3, 2, 3, 4};
    uint32_t b[N] = {33, 20, 30, 40};
    uint32_t c[N];

    for (int i = 0; i < N; ++i) {
        c[i] = multiply(a[i], b[i]);  // 要素ごとの乗算（ソフトウェア）
    }

    result = c[0];  // デバッグ出力（3×33 = 99 = 0x63）

    // テスト終了のコード送信
    PIO32 = TEST_END_CODE;

    if ((c[0] == 99u) & (c[1] == 40u) & (c[2] == 90u) & (c[3] == 160u)) {
        PIO32 = 0x63u;
    } else {
        PIO32 = 0xEEu;
    }

    while (1) { }  // 無限ループで停止
}

/* ---------- 定義（実体）：extern を外す ---------- */
extern "C" {
    volatile uint32_t result = 0;
}
