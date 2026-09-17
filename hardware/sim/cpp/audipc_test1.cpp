#include <cstdint>

/* ---------- アサーション用PIO出力 --------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

/* ---------- 結果 ---------- */
extern "C" volatile uint32_t result;

/* ---------- エントリ ---------- */
extern "C" void run() {
    uint32_t pc1 = 0;
    uint32_t pc2 = 0;

    /*
     * auipc_test:
     *   pc1 = PC (auipc)
     *   pc2 = PC (次のラベル)
     *   result = pc1 - pc2
     */
    asm volatile (
        "auipc %[p1], 0\n"      // p1 = PC of this instruction
        "addi  %[p2], %[p1], 8\n" // p2 = PC + 8（次の命令位置を想定）
        : [p1] "=r"(pc1),
          [p2] "=r"(pc2)
        :
        : "memory"
    );

    result = pc1 - pc2;

    /* ---- テスト終了 ---- */
    PIO32 = TEST_END_CODE;
    PIO32 = result;

    while (1) { }
}

/* ---------- 実体 ---------- */
extern "C" {
    volatile uint32_t result = 0;
}
