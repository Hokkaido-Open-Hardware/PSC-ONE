#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// a * b
uint32_t __mulsi3(uint32_t a, uint32_t b)
{
    uint32_t r = 0;
    while (b) {
        if (b & 1u) r += a;
        a <<= 1;
        b >>= 1;
    }
    return r;
}

#ifdef __cplusplus
}
#endif
