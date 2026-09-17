#include <cstdint>

/* ---------- アサーション用PIO出力 ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

/* ---------- 宣言（extern：初期化しない） ---------- */
extern "C" volatile uint32_t result;

/* ---------- スタートアップから呼ばれるエントリ ---------- */
extern "C" void run() {
    uint32_t a = 330;
    uint32_t b = 220;
    uint32_t f = 0;
    uint32_t c;

    //c = a - b;
    asm volatile ("sub %0, %1, %2" : "=r"(c) : "r"(a), "r"(b));
    asm volatile ("sub %0, %1, %2" : "=r"(c) : "r"(c), "r"(f));     // 2回連続 & 0x00

    // 結果 110 を result に格納
    result = c;  

    // テスト終了のコード送信
    PIO32 = TEST_END_CODE;

    // PIO データによるアサーション用書き込み
    if (result == 110u) {
        PIO32 = 110u;
    } else {
        PIO32 = result;
    }

    while (1) { }  // 無限ループで終了
}

/* ---------- 定義（実体）：extern を外す ---------- */
extern "C" {
    volatile uint32_t result = 0;
}
