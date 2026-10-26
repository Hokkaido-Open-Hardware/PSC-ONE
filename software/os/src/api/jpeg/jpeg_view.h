#ifndef PSC_JPEG_VIEW_H
#define PSC_JPEG_VIEW_H
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
/* Synchronous RGB888 sink. Rectangles are packed RGB (stride width*3), at
   most 16x16, in MCU row order. Pixels expire on callback return.
   Callbacks return zero or a negative error; they must not reenter decode.
   begin may be followed by a decode/EOI error: commit results only on success. */
typedef struct {
    int (*begin)(void *user, uint32_t width, uint32_t height);
    int (*rect)(void *user, uint32_t x, uint32_t y, uint32_t width,
                uint32_t height, const uint8_t *rgb);
    void *user;
} jpeg_rgb_sink_t;
int jpeg_decode_rgb(const char *filename, const jpeg_rgb_sink_t *sink);
/* Bounded header-only preflight; no LCD, entropy decode or model IO. */
int jpeg_probe(const char *filename, uint32_t *width, uint32_t *height);
int jpeg_view(const char *filename);
const char *jpeg_error_string(int error);
#ifdef __cplusplus
}
#endif
#endif
