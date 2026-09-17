#include <cstdint>

/* ---------- PIO ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

/* ---------- result ---------- */
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
struct Complex {
    int32_t re;
    int32_t im;
};

static inline Complex cadd(Complex a, Complex b)
{
    return {a.re + b.re, a.im + b.im};
}

static inline Complex csub(Complex a, Complex b)
{
    return {a.re - b.re, a.im - b.im};
}

static inline Complex cmul_q15(Complex a, Complex b)
{
    int32_t ac = alu_mul_asm(a.re, b.re);
    int32_t bd = alu_mul_asm(a.im, b.im);
    int32_t ad = alu_mul_asm(a.re, b.im);
    int32_t bc = alu_mul_asm(a.im, b.re);

    return {
        (ac - bd) >> 15,
        (ad + bc) >> 15
    };
}

/* ---------- bit reverse N=8 ---------- */
static void bit_reverse8(Complex x[8])
{
    Complex t;

    t = x[1]; x[1] = x[4]; x[4] = t;
    t = x[3]; x[3] = x[6]; x[6] = t;
}

/* ---------- FFT Q15 N=8 ---------- */
static void fft8_q15(Complex x[8])
{
    bit_reverse8(x);

    const Complex W0 = { 32767,      0 };
    const Complex W1 = { 23170, -23170 };
    const Complex W2 = {     0, -32768 };
    const Complex W3 = {-23170, -23170 };

    /* stage 1: len=2 */
    for (int i = 0; i < 8; i += 2) {
        Complex a = x[i];
        Complex b = x[i + 1];

        x[i]     = cadd(a, b);
        x[i + 1] = csub(a, b);
    }

    /* stage 2: len=4 */
    for (int i = 0; i < 8; i += 4) {
        Complex a0 = x[i + 0];
        Complex a1 = x[i + 1];
        Complex a2 = x[i + 2];
        Complex a3 = x[i + 3];

        Complex t0 = cmul_q15(a2, W0);
        Complex t1 = cmul_q15(a3, W2);

        x[i + 0] = cadd(a0, t0);
        x[i + 2] = csub(a0, t0);
        x[i + 1] = cadd(a1, t1);
        x[i + 3] = csub(a1, t1);
    }

    /* stage 3: len=8 */
    {
        Complex a0 = x[0];
        Complex a1 = x[1];
        Complex a2 = x[2];
        Complex a3 = x[3];
        Complex a4 = x[4];
        Complex a5 = x[5];
        Complex a6 = x[6];
        Complex a7 = x[7];

        Complex t0 = cmul_q15(a4, W0);
        Complex t1 = cmul_q15(a5, W1);
        Complex t2 = cmul_q15(a6, W2);
        Complex t3 = cmul_q15(a7, W3);

        x[0] = cadd(a0, t0);
        x[4] = csub(a0, t0);

        x[1] = cadd(a1, t1);
        x[5] = csub(a1, t1);

        x[2] = cadd(a2, t2);
        x[6] = csub(a2, t2);

        x[3] = cadd(a3, t3);
        x[7] = csub(a3, t3);
    }
}

/* ---------- entry ---------- */
extern "C" void run()
{
    Complex x[8] = {
        {32767, 0},
        {    0, 0},
        {    0, 0},
        {    0, 0},
        {    0, 0},
        {    0, 0},
        {    0, 0},
        {    0, 0},
    };

    fft8_q15(x);

    uint32_t err = 0;

    for (int i = 0; i < 8; i++) {
        if (x[i].re != 32767) {
            err++;
        }
        if (x[i].im != 0) {
            err++;
        }
    }

    if (err == 0) {
        result = 0xBEEF;
    } else {
        result = 0xDEAD;
    }

    PIO32 = TEST_END_CODE;
    PIO32 = result;

    while (1) { }
}

/* ---------- 定義 ---------- */
extern "C" {
    volatile uint32_t result = 0;
}