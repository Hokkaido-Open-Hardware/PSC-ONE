#include <cstdint>

/* ---------- アサーション用PIO出力 (Byteアドレス) --------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

/* ---------- 宣言（extern：初期化しない） ---------- */
extern "C" volatile uint32_t result;

/* ---------- スタートアップから呼ばれるエントリ ---------- */
extern "C" void run() {
    uint32_t v;

    /*
     * LUI + ADDI テスト
     * 期待値：0x12345000
     */
    asm volatile (
        "lui  %0, 0x12345\n"
        "addi %0, %0, 0\n"
        : "=r"(v)
        :
        : 
    );

    // 結果をメモリに保存
    result = v;

    // テスト終了コード
    PIO32 = TEST_END_CODE;

    // 結果を PIO に出力（下位32bitそのまま）
    PIO32 = result;

    while (1) { }
}

/* ---------- 定義（実体）：extern を外す ---------- */
extern "C" {
    volatile uint32_t result = 0;
}
