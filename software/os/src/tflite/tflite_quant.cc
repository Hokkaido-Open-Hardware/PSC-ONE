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
