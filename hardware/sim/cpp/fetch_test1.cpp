#include <cstdint>

/* ---------- アサーション用PIO出力 ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

/* ---------- 宣言 ---------- */
extern "C" volatile uint32_t result;

/* ---------- 関数群 ---------- */

static uint32_t foo(uint32_t x)
{
    return (x + 3) ^ 0x55;
}

static uint32_t bar(uint32_t x)
{
    return (x ^ 0x1234) + 5;
}

static uint32_t baz(uint32_t x)
{
    return (x + 7) ^ 0xAA;
}

static uint32_t qux(uint32_t x)
{
    return (x ^ 0xAAAA) + 9;
}

/* ---------- エントリ ---------- */

extern "C" void run()
{
    uint32_t acc = 0;
    uint32_t i;

    for (i = 0; i < 100; i++) {

        PIO32 = i;

        /* ===============================
           R / I pipeline burst
           =============================== */

        uint32_t t0 = acc + 1;          // I
        uint32_t t1 = t0 + acc;         // R (RAW)
        uint32_t t2 = t1 ^ 0x1234;      // I
        uint32_t t3 = t2 + t1;          // R
        uint32_t t4 = t3 + 7;           // I
        uint32_t t5 = t4 ^ t2;          // R
        uint32_t t6 = t5 + t3;          // R
        uint32_t t7 = t6 ^ 0xAAAA;      // I

        acc = t7;

        /* ===============================
           nested call (jal / jalr)
           =============================== */

        acc = foo(acc);
        acc = bar(acc);
        acc = baz(acc);

        /* ===============================
           indirect call (jalr)
           =============================== */

        uint32_t (*fn)(uint32_t);

        if (i & 1)
            fn = foo;
        else
            fn = baz;

        acc = fn(acc);

        /* ===============================
           branch storm
           =============================== */

        if (i & 2) acc ^= 0x1111;
        if (i & 4) acc ^= 0x2222;
        if (i & 8) acc ^= 0x4444;
        if (i & 16) acc ^= 0x8888;

        /* ===============================
           I / R chain
           =============================== */

        acc += i;          // I
        acc ^= (i << 3);   // R
        acc += 13;         // I
        acc ^= acc >> 2;   // R

        /* ===============================
           tight loop
           =============================== */

        for (int k = 0; k < 3; k++) {

            uint32_t p0 = acc + (uint32_t)k;    // I
            uint32_t p1 = p0 + acc;             // R
            uint32_t p2 = p1 ^ p0;              // R

            acc = qux(p2);
        }

        PIO32 = acc;
    }

    result = acc ^ 0xCAFEBABE;

    PIO32 = TEST_END_CODE;
    PIO32 = result;

    while (1) {}
}

/* ---------- 定義 ---------- */

extern "C" {
    volatile uint32_t result = 0;
}