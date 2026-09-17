#include <cstdint>

/* ---------- PIO ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

/* ---------- result ---------- */
extern "C" volatile uint32_t result_x100;
extern "C" volatile uint32_t result;

/* ---------- Monte Carlo ---------- */
static constexpr uint32_t NUM_SAMPLES = 30;

/* ---------- 乱数 ---------- */
static uint32_t rng_state = 1;

static uint32_t rand32()
{
    uint32_t x = rng_state;

    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;

    rng_state = x;
    return x;
}

/* ---------- MUL direct asm ---------- */
static inline uint32_t alu_mul_asm(uint32_t a, uint32_t b)
{
    uint32_t r;

    __asm__ volatile (
        "mul %0, %1, %2"
        : "=r"(r)
        : "r"(a), "r"(b)
    );

    return r;
}

/* ---------- エントリ ---------- */
extern "C" void run()
{
    /* debug */
    PIO32 = NUM_SAMPLES;
    
    uint32_t inside = 0;

    for (uint32_t i = 0; i < NUM_SAMPLES; i++)
    {
        /*
         * 0～4095
         * 12bit固定小数点相当
         */
        uint32_t x = rand32() >> 20;
        uint32_t y = rand32() >> 20;

        //uint32_t xx = x * x;
        uint32_t xx = alu_mul_asm(x,x);
        //uint32_t yy = y * y;
        uint32_t yy = alu_mul_asm(y,y);

        const uint32_t r2 = 4095u * 4095u;

        if ((xx + yy) <= r2)
        {
            inside++;
        }
    }

    /*
     * π ≒ 4 × inside / NUM_SAMPLES
     *
     * π×10000 を計算
     * 期待値: 31415付近
     */
    result_x100 = (inside * 40000u) / NUM_SAMPLES;
    PIO32 = result_x100;

    if ((result_x100 >= 30000u) &&
        (result_x100 <= 38000u))
    {
        result = 0xBEEF;      // PASS
    }
    else
    {
        result = 0xDEAD;      // FAIL
    }

    /* 終了通知 */
    PIO32 = TEST_END_CODE;

    /* π×10000 */
    PIO32 = result;

    while (1)
    {
    }
}

/* ---------- 定義 ---------- */
extern "C"
{
    volatile uint32_t result_x100   = 0;
    volatile uint32_t result        = 0;
}