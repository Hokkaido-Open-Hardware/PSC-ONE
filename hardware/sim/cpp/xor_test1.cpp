#include <cstdint>

/* ---------- PIO 出力 (Byteアドレス) ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

/* ---------- extern ---------- */
extern "C" volatile uint32_t result;

/* ============================================================
   AND / OR / XOR / ANDI / ORI / XORI の PASS/FAIL テスト
   ============================================================ */
extern "C" void run() {

    uint32_t a = 0xA5A5F0F0;
    uint32_t b = 0x0F0FF0AA;

    uint32_t r_and, r_or, r_xor;
    uint32_t r_andi, r_ori, r_xori;

    /* 期待値 */
    uint32_t exp_and  = (a & b);
    uint32_t exp_or   = (a | b);
    uint32_t exp_xor  = (a ^ b);
    uint32_t exp_andi = (a & 0x0FF);
    uint32_t exp_ori  = (a | 0x123);
    uint32_t exp_xori = (a ^ 0x7FF);

    /* 実行値 */
    asm volatile ("and  %0, %1, %2" : "=r"(r_and)  : "r"(a), "r"(b));
    asm volatile ("or   %0, %1, %2" : "=r"(r_or)   : "r"(a), "r"(b));
    asm volatile ("xor  %0, %1, %2" : "=r"(r_xor)  : "r"(a), "r"(b));
    asm volatile ("andi %0, %1, %2" : "=r"(r_andi) : "r"(a), "i"(0x0FF));
    asm volatile ("ori  %0, %1, %2" : "=r"(r_ori)  : "r"(a), "i"(0x123));
    asm volatile ("xori %0, %1, %2" : "=r"(r_xori) : "r"(a), "i"(0x7FF));

    /* ---------------------------------------------------------
       FAIL 判定（どれか1つでも FAIL なら即終了）
       --------------------------------------------------------- */

#define CHECK(expr, failcode)                 \
    do {                                      \
        if(!(expr)) {                         \
            result = failcode;                \
            PIO32 = TEST_END_CODE;            \
            PIO32 = result;                   \
            while(1) {}                       \
        }                                     \
    } while(0)

    CHECK(r_and  == exp_and,  0xBAD00001);
    CHECK(r_or   == exp_or,   0xBAD00002);
    CHECK(r_xor  == exp_xor,  0xBAD00003);
    CHECK(r_andi == exp_andi, 0xBAD00004);
    CHECK(r_ori  == exp_ori,  0xBAD00005);
    CHECK(r_xori == exp_xori, 0xBAD00006);

    /* ---------------------------------------------------------
       全て PASS → 最後に 1 回だけ TEST_END_CODE を出す
       --------------------------------------------------------- */
    result = 0x3344;

    PIO32 = TEST_END_CODE;
    PIO32 = result;

    while (1) {}
}

/* ---------- result 実体 ---------- */
extern "C" {
    volatile uint32_t result = 0;
}
