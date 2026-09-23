#ifndef PSC_TFLITE_PULP_FC_H
#define PSC_TFLITE_PULP_FC_H

#include <stdint.h>

// Opt in only on a CPU implementing signed cv.dotsp.b. Generic RV32IM and
// host builds stay scalar. PSC_PULP_TEST_EMULATE is for host verification only.
#ifndef PSC_HAS_CV_DOTSP_B
#define PSC_HAS_CV_DOTSP_B 0
#endif
#if PSC_HAS_CV_DOTSP_B && (!defined(__riscv) || __riscv_xlen != 32)
#error "PSC_HAS_CV_DOTSP_B requires RV32"
#endif

namespace psc_tflite_pulp {
#if PSC_HAS_CV_DOTSP_B || defined(PSC_PULP_TEST_EMULATE)
static inline int32_t cv_dotsp_b(uint32_t a, uint32_t b) {
#if PSC_HAS_CV_DOTSP_B
    int32_t result;
    asm volatile(".insn r 0x7b, 1, 0x48, %0, %1, %2"
                 : "=r"(result) : "r"(a), "r"(b));
    return result;
#else
    int32_t result=0;
    for (unsigned lane=0; lane<4; ++lane) {
        int32_t x=(a>>(lane*8))&255, w=(b>>(lane*8))&255;
        result+=(x<128?x:x-256)*(w<128?w:w-256);
    }
    return result;
#endif
}

template<bool aligned> static inline uint32_t load_i8x4(const int8_t *p) {
    uint32_t value;
    // memcpy preserves effective type. The aligned specialization is reached
    // only after BOTH addresses have been checked, and advances by four.
    const void *src=aligned ? __builtin_assume_aligned(p,4) : p;
    __builtin_memcpy(&value,src,sizeof(value));
    return value;
}

template<bool aligned> static inline int32_t dot(const int8_t *x,const int8_t *w,int k) {
    int32_t acc=0;
    int i=0;
    for (;i+4<=k;i+=4)
        acc+=cv_dotsp_b(load_i8x4<aligned>(x+i),load_i8x4<aligned>(w+i));
    for (;i<k;++i) acc+=int32_t(x[i])*int32_t(w[i]);
    return acc;
}
#endif

// A raw-dot primitive, not another quantization implementation. Caller must
// provide k readable bytes for each pointer and validated INT8 FC metadata.
// False leaves result untouched: caller executes its existing scalar path.
// k<=8192 bounds EVERY partial raw sum by 8192*16384=134217728, so grouping
// four products cannot introduce signed overflow (including -128 weights).
static inline bool try_dot(const int8_t *x,const int8_t *w,int k,
                           int weight_zero,bool int8_tensors,int32_t *result) {
#if PSC_HAS_CV_DOTSP_B || defined(PSC_PULP_TEST_EMULATE)
    if (!x || !w || !result || !int8_tensors || weight_zero || k<4 || k>8192)
        return false;
    if (((reinterpret_cast<uintptr_t>(x)|reinterpret_cast<uintptr_t>(w))&3)==0)
        *result=dot<true>(x,w,k);
    else
        *result=dot<false>(x,w,k);
    return true;
#else
    (void)x; (void)w; (void)k; (void)weight_zero; (void)int8_tensors; (void)result;
    return false;
#endif
}
} // namespace psc_tflite_pulp
#endif
