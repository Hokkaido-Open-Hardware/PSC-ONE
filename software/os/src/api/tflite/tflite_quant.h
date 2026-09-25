#ifndef PSC_TFLITE_QUANT_H
#define PSC_TFLITE_QUANT_H
#include <stdint.h>
extern "C" int psc_tflite_quantize(double scale, int32_t *multiplier, int *shift);
extern "C" int32_t psc_tflite_requantize(int32_t value, int32_t multiplier, int shift);
#endif
