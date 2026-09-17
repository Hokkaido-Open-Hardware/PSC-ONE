#include <cstdint>

/* ---------- アサーション用PIO出力 (Byteアドレス) ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

/* ---------- 宣言 ---------- */
extern "C" volatile uint32_t result;

/* ---------- スタートアップから呼ばれるエントリ ---------- */
extern "C" void run()
{
    uint32_t r1;
    uint32_t r2;
    uint32_t r3;
    uint32_t r4;
    uint32_t r5;

    /*
     * Forwarding test
     *
     * 依存関係:
     *
     *   r1 = 1
     *   r2 = r1 + 2   // r1 forwarding
     *   r3 = r2 + 4   // r2 forwarding
     *   r4 = r3 + r2  // rs1/rs2 両方 dependency
     *   r5 = r4 + r3  // 連続 dependency
     *
     * expected:
     *
     *   r1 = 1
     *   r2 = 3
     *   r3 = 7
     *   r4 = 10
     *   r5 = 17 = 0x00000011
     */

    asm volatile(
        "addi %0, zero, 1"
        : "=r"(r1)
    );

    asm volatile(
        "addi %0, %1, 2"
        : "=r"(r2)
        : "r"(r1)
    );

    asm volatile(
        "addi %0, %1, 4"
        : "=r"(r3)
        : "r"(r2)
    );

    asm volatile(
        "add %0, %1, %2"
        : "=r"(r4)
        : "r"(r3), "r"(r2)
    );

    asm volatile(
        "add %0, %1, %2"
        : "=r"(r5)
        : "r"(r4), "r"(r3)
    );

    result = r5;

    /* テスト終了コード */
    PIO32 = TEST_END_CODE;

    /* cocotb側で比較する結果 */
    PIO32 = result;

    while (1) {
    }
}

/* ---------- result実体 ---------- */
extern "C" {
    volatile uint32_t result = 0;
}