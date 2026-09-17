#include <cstdint>

/* ---------- アサーション用PIO出力 ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

/* ---------- 宣言（extern：初期化しない） ---------- */
extern "C" volatile uint32_t result;

/* ---------- スタートアップから呼ばれるエントリ ---------- */
extern "C" void run() {
    constexpr int N = 4;

    uint32_t a[N] = {22, 2, 3, 4};
    uint32_t b[N] = {33, 20, 30, 40};
    uint32_t c[N];

    //PIO32 = 55u;

    for (int i = 0; i < N; ++i) {
        c[i] = a[i] + b[i];  // 要素ごとの加算
    }

    result = c[0];  // デバッグ出力（必要に応じて変更）

    // テスト終了のコード送信
    PIO32 = TEST_END_CODE;

    // PIO データによるアサーション用書き込み
    if ((c[0] == 55u) & (c[1] == 22u) & (c[2] == 33u) & (c[3] == 44u)) {
        PIO32 = 0xABCD;
    } else {
        PIO32 = result;
    }

    while (1) { }  // 無限ループで停止
}

/* ---------- 定義（実体）：extern を外す ---------- */
extern "C" {
    volatile uint32_t result = 0;
}
