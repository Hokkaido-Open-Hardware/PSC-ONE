#include <cstdint>

/* ---------- アサーション用PIO出力 ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

/* ---------- 宣言 ---------- */
extern "C" volatile uint32_t result;

/* ---------- MUL direct asm ---------- */
static inline int32_t alu_mul_asm(int32_t a, int32_t b)
{
    int32_t r;

    __asm__ volatile (
        "mul %0, %1, %2"
        : "=r"(r)
        : "r"(a), "r"(b)
    );

    return r;
}

/* ---------- complex ---------- */
struct Complex
{
    int32_t re;
    int32_t im;
};

static inline Complex cadd(const Complex a, const Complex b)
{
    return {a.re + b.re, a.im + b.im};
}

static inline Complex csub(const Complex a, const Complex b)
{
    return {a.re - b.re, a.im - b.im};
}

/* (a + jb) × (-j) = (b) + j(-a) */
static inline Complex mul_minus_j(const Complex a)
{
    return {a.im, -a.re};
}

/* ---------- エントリ ---------- */
extern "C" void run()
{
    constexpr int N = 4;

    Complex x[N] = {
        {1,0},
        {2,0},
        {3,0},
        {4,0}
    };

    Complex y[N];

    /* Stage 1 */

    Complex s0 = cadd(x[0], x[1]);   // 3
    Complex d0 = csub(x[0], x[1]);   // -1

    Complex s1 = cadd(x[2], x[3]);   // 7
    Complex d1 = csub(x[2], x[3]);   // -1

    /* Stage 2 */

    Complex t = mul_minus_j(d1);

    y[0] = cadd(s0, s1);
    y[2] = csub(s0, s1);
    y[1] = cadd(d0, t);
    y[3] = csub(d0, t);

    /*
        Expected

        y0 = (10,  0)
        y1 = (-1,  1)
        y2 = (-4,  0)
        y3 = (-1, -1)
    */

    if ((y[0].re == 10) && (y[0].im == 0) &&
        (y[1].re == -1) && (y[1].im == 1) &&
        (y[2].re == -4) && (y[2].im == 0) &&
        (y[3].re == -1) && (y[3].im == -1))
    {
        result = 0xBEEF;
    }
    else
    {
        result = 0xDEAD;
    }

    PIO32 = TEST_END_CODE;
    PIO32 = result;

    while (1) { }
}

/* ---------- 定義 ---------- */
extern "C"
{
    volatile uint32_t result = 0;
}