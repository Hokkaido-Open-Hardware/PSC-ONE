#include <cstdint>

/* ---------- アサーション用PIO出力 (Byteアドレス) --------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

/* ---------- 宣言（extern：初期化しない） ---------- */
extern "C" volatile uint32_t result;

/* ---------- スタートアップから呼ばれるエントリ ---------- */
extern "C" void run()
{
    uint32_t value = 0xABCD5678;

    // データ書き込み
    result = value;

    // 命令フェンス
    asm volatile ("fence.i" ::: "memory");

    // 正常にここまで実行できればPASS
    PIO32 = TEST_END_CODE;
    PIO32 = result;

    while (1) { }
}

/* ---------- 定義（実体） ---------- */
extern "C" {
    volatile uint32_t result = 0;
}