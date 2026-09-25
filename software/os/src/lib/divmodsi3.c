#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// 基本アルゴリズム
static uint32_t udivmod32(uint32_t n, uint32_t d, uint32_t *rem)
{
    uint32_t q = 0;
    uint32_t r = 0;

    for (int i = 31; i >= 0; i--) {
        r = (r << 1) | ((n >> i) & 1u);
        if (r >= d) {
            r -= d;
            q |= (1u << i);
        }
    }

    if (rem) *rem = r;
    return q;
}

// a / b
uint32_t __udivsi3(uint32_t a, uint32_t b)
{
    if (b == 0) return 0;
    return udivmod32(a, b, 0);
}

// a % b
uint32_t __umodsi3(uint32_t a, uint32_t b)
{
    uint32_t r;
    if (b == 0) return 0;
    udivmod32(a, b, &r);
    return r;
}

// a / b (int32)
int32_t __divsi3(int32_t a, int32_t b)
{
    if (b == 0) return 0;

    uint32_t ua = (a < 0) ? -(uint32_t)a : (uint32_t)a;
    uint32_t ub = (b < 0) ? -(uint32_t)b : (uint32_t)b;

    uint32_t q = udivmod32(ua, ub, 0);
    return ((a ^ b) < 0) ? -(int32_t)q : (int32_t)q;
}

// a % b (int32)
int32_t __modsi3(int32_t a, int32_t b)
{
    if (b == 0) return 0;

    uint32_t ua = (a < 0) ? -(uint32_t)a : (uint32_t)a;
    uint32_t ub = (b < 0) ? -(uint32_t)b : (uint32_t)b;

    uint32_t r;
    udivmod32(ua, ub, &r);
    return (a < 0) ? -(int32_t)r : (int32_t)r;
}

#ifdef __cplusplus
}
#endif
