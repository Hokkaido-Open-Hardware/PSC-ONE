#ifndef PSC_TFLITE_CPU_H
#define PSC_TFLITE_CPU_H
#include <stddef.h>
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
/* Prepared, bounds-checked NHWC/OHWI geometry. No heap or im2col workspace. */
typedef struct {
    int32_t kind, in[4], out[4], filter[4];
    int32_t stride_h, stride_w, dilation_h, dilation_w, pad_h, pad_w;
    int32_t input_zero, second_zero, output_zero, minimum, maximum;
    int32_t multiplier[3], shift[3], broadcast_a[4], broadcast_b[4];
    const int32_t *channel_multiplier, *channel_shift;
    const int8_t *lut;
    int32_t rank, type, width, axis, aux[4], begin[4], input_count, concat_size[16];
    float input_scale, output_scale;
    const int32_t *exp_lut;
} psc_tflite_cpu_op;
void psc_tflite_cpu_conv(const psc_tflite_cpu_op *, const int8_t *, const int8_t *, const uint8_t *, int8_t *);
void psc_tflite_cpu_binary(const psc_tflite_cpu_op *, const int8_t *, const int8_t *, int8_t *);
void psc_tflite_cpu_logistic(const psc_tflite_cpu_op *, const int8_t *, int8_t *);
int psc_tflite_cpu_transform(const psc_tflite_cpu_op *,const void *const *,void *);
void psc_tflite_cpu_pool(const psc_tflite_cpu_op *, const int8_t *, int8_t *);
#ifdef __cplusplus
}
#endif
#endif
