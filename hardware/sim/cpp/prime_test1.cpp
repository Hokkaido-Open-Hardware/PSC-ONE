#include <cstdint>

/* ---------- PIO --------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

extern "C" volatile uint32_t result;

/* ---------- n % d == 0 を判定（* % 不使用・高速） ---------- */
static inline bool is_divisible(uint32_t n, uint32_t d)
{
    if (d == 0) return false;

    uint32_t dd = d;

    /* d を n 以下の最大の 2^k 倍にする */
    while ((dd << 1) <= n) {
        dd <<= 1;
    }

    /* ビット減算 */
    while (n >= d) {
        if (n >= dd) {
            n -= dd;
        }
        dd >>= 1;
    }

    return (n == 0);
}

/* ---------- 素数判定（一般・* % 不使用） ---------- */
static inline bool is_prime(uint32_t n)
{
    if (n < 2) return false;
    if (n == 2) return true;
    if ((n & 1u) == 0) return false;

    uint32_t i = 3;
    uint32_t acc = 9;   // i*i = 3*3 を加算で表現

    while (acc <= n) {
        if (is_divisible(n, i)) {
            return false;
        }

        /* 次の平方を生成：
           (i+2)^2 = i^2 + 4i + 4
           ただし * は使えないので加算展開 */
        acc = acc + i + i + i + i + 4;
        i   = i + 2;
    }

    return true;
}

/* ---------- entry ---------- */
extern "C" void run()
{
    uint32_t last_prime = 0;

    // 100までの素数をPIOに出力.
    for (uint32_t n = 2; n <= 100; n = n + 1) {
        if (is_prime(n)) {
            last_prime = n;
            PIO32 = n;
        }
    }

    result = last_prime;

    PIO32 = TEST_END_CODE;
    PIO32 = result;

    while (1) {}
}

/* ---------- storage ---------- */
extern "C" {
    volatile uint32_t result = 0;
}