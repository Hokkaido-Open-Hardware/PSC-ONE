#include <cstdint>

/* ---------- アサーション用PIO出力 (Byteアドレス) --------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

/* ---------- 宣言（extern：初期化しない） ---------- */
extern "C" volatile uint32_t result;

/* ---------- スタートアップから呼ばれるエントリ ---------- */
extern "C" void run() {
    uint32_t a[10] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10};
    uint32_t f1 = 0x0000FF00;
    uint32_t f2 = 0xFF000000;
    uint32_t c;

    asm volatile ("add %0, %1, %2" : "=r"(c) : "r"(a[0]), "r"(a[9]));
    asm volatile ("add %0, %1, %2" : "=r"(c) : "r"(c), "r"(f1));     // 2回連続 ADD命令実行
    asm volatile ("add %0, %1, %2" : "=r"(c) : "r"(c), "r"(f2));     // 3回連続 ADD命令実行

    // 結果 30 を result に格納
    result = c;  

    // メモリ可視性保証（任意）
    // asm volatile ("fence rw, rw" ::: "memory");

    // テスト終了のコード送信
    PIO32 = TEST_END_CODE;

    // PIO データによるアサーション用書き込み
    PIO32 = result;

    while (1) { }  // 無限ループで終了
}

/* ---------- 定義（実体）：extern を外す ---------- */
extern "C" {
    volatile uint32_t result = 0;
}