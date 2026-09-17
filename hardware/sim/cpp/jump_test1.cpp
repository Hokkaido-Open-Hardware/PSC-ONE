#include <cstdint>

/* ---------- アサーション用PIO出力 ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

/* ---------- 宣言（extern：初期化しない） ---------- */
extern "C" volatile uint32_t result;

/* ---------- スタートアップから呼ばれるエントリ ---------- */
extern "C" void run() {
    uint32_t c = 0;

    asm volatile (
        "auipc t0, 0\n\t"          // 現在のPCを取得（t0にベースアドレス）
        "jal t1, 1f\n\t"           // ラベル1にジャンプし、t1=戻りアドレス
        "li %[output], 0xBAD\n\t" // 万一ジャンプしなかったらバグ
        "j 2f\n"                   // ラベル2にスキップ（ジャンプ失敗防止）
        "1:\n\t"
        "li %[output], 0x12345678\n\t"  // ジャンプ先で値をセット
        "2:\n\t"
        : [output] "=r"(c)
        :
        : "t0", "t1"
    );

    result = c;

    // テスト終了のコード送信
    PIO32 = TEST_END_CODE;

    // PIO データによるアサーション用書き込み
    if (result == 0x12345678u) {
        PIO32 = 0x12345678u;
    } else {
        PIO32 = result;
    }

    while (1) {}
}

/* ---------- 定義（実体）：extern を外す ---------- */
extern "C" {
    volatile uint32_t result = 0;
}
