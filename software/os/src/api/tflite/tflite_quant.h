#ifndef PSC_TFLITE_QUANT_H
#define PSC_TFLITE_QUANT_H
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
int psc_tflite_quantize(double scale, int32_t *multiplier, int *shift);
int32_t psc_tflite_requantize(int32_t value, int32_t multiplier, int shift);
int psc_tflite_logistic_lut(double scale, int zero, int8_t *lut);
int psc_tflite_softmax_lut(double beta,double scale,int32_t *lut);
void psc_tflite_softmax_scale(int32_t sum,int32_t *multiplier,int *shift);
int32_t psc_tflite_softmax_output(int32_t exponent,int32_t multiplier,int shift);
#ifdef __cplusplus
}
#endif
#endif
