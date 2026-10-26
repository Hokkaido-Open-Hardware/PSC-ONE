#ifndef PSC_YOLO_PREPROCESS_H
#define PSC_YOLO_PREPROCESS_H
#include "yolo.h"
#ifdef __cplusplus
extern "C" {
#endif
/* Streaming state is static, not on the 128KiB user stack. A new begin resets
   incomplete work. finish is mandatory; output is invalid on any error.
   Feed packed RGB MCU rectangles in row order, with a constant band height. */
int yolo_preprocess_begin(uint32_t width, uint32_t height, float *input, size_t bytes);
int yolo_preprocess_rect(uint32_t x, uint32_t y, uint32_t width,
                         uint32_t height, const uint8_t *rgb);
int yolo_preprocess_finish(yolo_geometry_t *geometry);
int yolo_prepare_jpeg(const char *name, float *input, size_t bytes,
                      yolo_geometry_t *geometry);
#ifdef __cplusplus
}
#endif
#endif
