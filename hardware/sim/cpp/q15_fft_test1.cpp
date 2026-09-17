#include <cstdint>

/* ---------- PIO ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

/* ---------- result ---------- */
extern "C" volatile uint32_t result;

/* ---------- MUL ---------- */
static inline int32_t alu_mul_asm(int32_t a, int32_t b)
{
    int32_t r;

    __asm__ volatile (
        "mul %0,%1,%2"
        : "=r"(r)
        : "r"(a), "r"(b)
    );

    return r;
}

/* ---------- Complex ---------- */
struct Complex
{
    int32_t re;
    int32_t im;
};

static inline Complex cadd(const Complex a,const Complex b)
{
    return {a.re+b.re,a.im+b.im};
}

static inline Complex csub(const Complex a,const Complex b)
{
    return {a.re-b.re,a.im-b.im};
}

/* ---------- Q15 Complex Multiply ---------- */

static inline Complex cmul_q15(const Complex a,const Complex b)
{
    Complex r;

    int32_t ac = alu_mul_asm(a.re,b.re);
    int32_t bd = alu_mul_asm(a.im,b.im);
    int32_t ad = alu_mul_asm(a.re,b.im);
    int32_t bc = alu_mul_asm(a.im,b.re);

    r.re = (ac-bd)>>15;
    r.im = (ad+bc)>>15;

    return r;
}

/* ---------- FFT ---------- */

extern "C" void run()
{
    constexpr int N=4;

    Complex x[N]={
        {32767,0},   // 1.0
        {16384,0},   // 0.5
        {8192 ,0},   // 0.25
        {4096 ,0},   // 0.125
    };

    Complex y[N];

    Complex s0=cadd(x[0],x[1]);
    Complex d0=csub(x[0],x[1]);

    Complex s1=cadd(x[2],x[3]);
    Complex d1=csub(x[2],x[3]);

    /* -j */
    const Complex W1={
        0,
        -32768
    };

    Complex t=cmul_q15(d1,W1);

    y[0]=cadd(s0,s1);
    y[2]=csub(s0,s1);
    y[1]=cadd(d0,t);
    y[3]=csub(d0,t);

    /*
        Expected

        y0=(61439,0)
        y1=(16383,4096)
        y2=(20479,0)
        y3=(16383,-4096)
    */

    if ((y[0].re == 61439) && (y[0].im == 0) &&
        (y[1].re == 16383) && (y[1].im == -4096) &&
        (y[2].re == 36863) && (y[2].im == 0) &&
        (y[3].re == 16383) && (y[3].im == 4096))
    {
        result = 0xBEEF;
    }
    else
    {
        result = 0xDEAD;
    }
    
    PIO32 = (uint32_t)y[0].re;
    PIO32 = (uint32_t)y[0].im;
    PIO32 = (uint32_t)y[1].re;
    PIO32 = (uint32_t)y[1].im;
    PIO32 = (uint32_t)y[2].re;
    PIO32 = (uint32_t)y[2].im;
    PIO32 = (uint32_t)y[3].re;
    PIO32 = (uint32_t)y[3].im;

    PIO32=TEST_END_CODE;
    PIO32=result;

    while(1){}
}

/* ---------- 定義 ---------- */

extern "C"
{
    volatile uint32_t result=0;
}