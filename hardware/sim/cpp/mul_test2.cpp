#include <cstdint>

/* ---------- アサーション用PIO出力 ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

/* ---------- 宣言（extern：初期化しない） ---------- */
extern "C" volatile uint32_t result;

/* ---------- スタートアップから呼ばれるエントリ ---------- */
extern "C" void run() {

    // test. これで10倍になる
    uint32_t a = 7;
    uint32_t r0 = (a << 3) + (a << 1);

    uint32_t b = 9;
    uint32_t r1 = (b << 3) + (b << 1);

    // 別のやり方で10倍にする.
    uint32_t c = 0;
    uint32_t d = 5;

    c += d;
    c += d;
    c += d;
    c += d;
    c += d;
    c += d;
    c += d;
    c += d;
    c += d;
    c += d;

    result = r0;  // デバッグ出力（3×33 = 99 = 0x63）

    // テスト終了のコード送信
    PIO32 = TEST_END_CODE;

    if (r0==70 && r1==90 && c==50) {
        PIO32 = 0x33u;
    } else {
        PIO32 = result;
    }

    while (1) { }  // 無限ループで停止
}

/* ---------- 定義（実体）：extern を外す ---------- */
extern "C" {
    volatile uint32_t result = 0;
}
