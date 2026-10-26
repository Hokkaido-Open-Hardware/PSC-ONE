#include "tflite_quant.h"
#include "tensorflow/lite/kernels/internal/compatibility.h"
/* Preserve upstream checks, but do not pull an OS abort/stdio implementation
   into firmware. prepare bounds all arguments before the official helpers. */
#undef TFLITE_ABORT
#define TFLITE_ABORT __builtin_trap()
#include "tensorflow/lite/kernels/internal/common.cc"
#include "tensorflow/lite/kernels/internal/quantization_util.cc"
static_assert(TFLITE_SINGLE_ROUNDING == 0, "PSC reference uses double rounding");
extern "C" int psc_tflite_quantize(double scale, int32_t *m, int *s) {
    if (!(scale > 0) || !std::isfinite(scale)) return -203;
    tflite::QuantizeMultiplier(scale, m, s);
    return *s >= -31 && *s <= 30 ? 0 : -202;
}
extern "C" int32_t psc_tflite_requantize(int32_t x, int32_t m, int s) {
    return tflite::MultiplyByQuantizedMultiplier(x, m, s);
}

/* Fixed-point Q4 sigmoid, identical rounding and saturation to the pinned
   reference_integer_ops::Logistic. Build once; invoke is a 256-entry lookup. */
extern "C" int psc_tflite_logistic_lut(double scale, int zero, int8_t *lut) {
    int32_t multiplier; int shift;
    int rc=psc_tflite_quantize(scale * 134217728.0, &multiplier, &shift);
    if(rc)return rc;
    if(shift<0 || shift>30 || zero < -128 || zero > 127 || !lut)return -202;
    int32_t radius=int32_t((int64_t(15)<<27)/(int64_t(1)<<shift));
    for(int v=-128;v<=127;++v) {
        int x=v-zero, y;
        if(x<=-radius)y=-128;
        else if(x>=radius)y=127;
        else {
            auto f=gemmlowp::FixedPoint<int32_t,4>::FromRaw(psc_tflite_requantize(x,multiplier,shift));
            y=gemmlowp::RoundingDivideByPOT(gemmlowp::logistic(f).raw(),23)-128;
            if(y < -128)y=-128;if(y>127)y=127;
        }
        lut[v+128]=int8_t(y);
    }
    return 0;
}

extern "C" int psc_tflite_softmax_lut(double beta,double scale,int32_t *lut) {
    if(!(beta>0)||!std::isfinite(beta)||!(scale>0)||!std::isfinite(scale))return -203;
    double real=beta*scale*67108864.0;
    if(real<1)return -202;
    real=std::min(real,2147483647.0);
    int32_t mult;int shift;tflite::QuantizeMultiplier(real,&mult,&shift);
    if(shift<0||shift>30)return -202;
    int diff_min=-tflite::CalculateInputRadius(5,shift);
    for(int d=0;d<256;++d){
        if(-d<diff_min)lut[d]=0;
        else lut[d]=gemmlowp::exp_on_negative_values(gemmlowp::FixedPoint<int32_t,5>::FromRaw(
            tflite::MultiplyByQuantizedMultiplierGreaterThanOne(-d,mult,shift))).raw();
    }
    return 0;
}
extern "C" void psc_tflite_softmax_scale(int32_t sum,int32_t *multiplier,int *shift){
    int bits;*multiplier=tflite::GetReciprocal(sum,12,&bits);*shift=bits+31-8;
}
extern "C" int32_t psc_tflite_softmax_output(int32_t exponent,int32_t multiplier,int shift){
    using F=gemmlowp::FixedPoint<int32_t,0>;
    return gemmlowp::RoundingDivideByPOT((F::FromRaw(exponent)*F::FromRaw(multiplier)).raw(),shift)-128;
}
