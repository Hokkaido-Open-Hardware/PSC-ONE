#include <cstdint>

/* ---------- PIO ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

/* ---------- グローバル ---------- */
extern "C" volatile uint32_t result;

/* ---------- ret 成功時の到達先 ---------- */
extern "C" __attribute__((naked)) void ret_target() {
    asm volatile (
        /* スタックから値を取得 */
        "lw t0,  0(sp)\n"     /* v0 */
        "lw t1,  4(sp)\n"     /* v1 */
        "lw t2,  8(sp)\n"     /* v2 */
        "lw t3, 12(sp)\n"     /* v3 */

        /* スタック解放 */
        "addi sp, sp, 16\n"

        /* 期待値チェック */
        "li t4, 0x11111111\n"
        "bne t0, t4, bad\n"
        "li t4, 0x22222222\n"
        "bne t1, t4, bad\n"
        "li t4, 0x33333333\n"
        "bne t2, t4, bad\n"
        "li t4, 0x44444444\n"
        "bne t3, t4, bad\n"

        /* 成功 */
        "li t5, 0x12345678\n"
        "la t6, result\n"
        "sw t5, 0(t6)\n"

        "li t5, %0\n"
        "li t6, 0x10001000\n"
        "sw t5, 0(t6)\n"      /* TEST_END_CODE */
        "li t5, 0x12345678\n"
        "sw t5, 0(t6)\n"

        "j .\n"

        /* 失敗 */
        "bad:\n"
        "li t5, 0xBAD0BAD0\n"
        "la t6, result\n"
        "sw t5, 0(t6)\n"

        "li t5, %0\n"
        "li t6, 0x10001000\n"
        "sw t5, 0(t6)\n"
        "li t5, 0xBAD0BAD0\n"
        "sw t5, 0(t6)\n"

        "j .\n"
        :
        : "i"(TEST_END_CODE)
        : "memory"
    );
}

/* ---------- エントリ ---------- */
extern "C" __attribute__((naked)) void run() {
    asm volatile (
        /* sa (s0–s3) に既知の値を設定 */
        "li s0, 0x11111111\n"
        "li s1, 0x22222222\n"
        "li s2, 0x33333333\n"
        "li s3, 0x44444444\n"

        /* sp を使ってスタックへ保存（sp0–sp3 相当） */
        "addi sp, sp, -16\n"
        "sw s0,  0(sp)\n"
        "sw s1,  4(sp)\n"
        "sw s2,  8(sp)\n"
        "sw s3, 12(sp)\n"

        /* ra を設定して ret */
        "la ra, ret_target\n"
        "ret\n"

        /* ここに来たら ret 失敗 */
        "li t0, 0xDEADBEEF\n"
        "la t1, result\n"
        "sw t0, 0(t1)\n"

        "li t0, %0\n"
        "li t1, 0x10001000\n"
        "sw t0, 0(t1)\n"
        "li t0, 0xDEADBEEF\n"
        "sw t0, 0(t1)\n"

        "j .\n"
        :
        : "i"(TEST_END_CODE)
        : "memory"
    );
}

/* ---------- 実体 ---------- */
extern "C" {
    volatile uint32_t result = 0;
}
