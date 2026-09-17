#include <cstdint>

/* ---------- アサーション用PIO出力 ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

/* ---------- 宣言（extern：初期化しない） ---------- */
extern "C" volatile uint32_t result;

static inline void store_result_to(uintptr_t addr, uint32_t v) {
    *reinterpret_cast<volatile uint32_t*>(addr) = v;
}

/* ---------- スタートアップから呼ばれるエントリ ---------- */
extern "C" void run() {
    uint32_t sum = 0;
    for (uint32_t i = 0; i < 11; ++i) sum += i;   // 0x37

    // result 
    result = sum;
    store_result_to(0x00001000u, result);
    //asm volatile ("fence rw, rw" ::: "memory");

    uint32_t mem_read_data;
    mem_read_data = *reinterpret_cast<volatile uint32_t*>(0x00001000u);

    // テスト終了のコード送信
    PIO32 = TEST_END_CODE;

    // PIO データによるアサーション用書き込み
    if (mem_read_data == 55u) {
        PIO32 = 55u;
    } else {
        PIO32 = mem_read_data;
    }

    while (1) { }      // 戻らない
}

/* ---------- 定義（実体）：extern を外す ---------- */
extern "C" {                 // C リンケージを維持
    volatile uint32_t result = 0;   // ← ここで初期化（or 省略でもOK）
}
