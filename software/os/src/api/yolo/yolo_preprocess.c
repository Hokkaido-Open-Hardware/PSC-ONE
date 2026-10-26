#include "yolo_preprocess.h"
#include "../jpeg/jpeg_view.h"
#include "../jpeg_display.h"
#include <string.h>

typedef struct { uint16_t lo, hi, fraction; } axis_t;
static struct {
    uint8_t rows[17][JPEG_LCD_WIDTH * 3];
    axis_t xs[YOLO_SIDE], ys[YOLO_SIDE];
    yolo_geometry_t geometry;
    float *input;
    unsigned next_x, band_y, band_height, output_y;
    int active;
} work;

/* Exact rational ties-to-even for resize dimensions (no float ambiguity). */
static unsigned round_even(unsigned numerator, unsigned denominator)
{
    unsigned q = numerator / denominator, r = numerator % denominator;
    return q + (2*r > denominator || (2*r == denominator && (q & 1)));
}
static void axis(axis_t *table, unsigned source, unsigned dest)
{
    int den = 2 * (int)dest;
    for (unsigned d = 0; d < dest; ++d) {
        int n = (int)((2*d+1)*source) - (int)dest;
        if (n < 0) n = 0;
        if (n > (int)(source-1)*den) n = (int)(source-1)*den;
        unsigned lo = (unsigned)n / (unsigned)den;
        table[d] = (axis_t){lo, lo+1 < source ? lo+1 : lo, (unsigned)n % (unsigned)den};
    }
}
int yolo_preprocess_begin(uint32_t width, uint32_t height, float *input, size_t bytes)
{
    work.active = 0;
    work.input = 0;
    if (!input || ((uintptr_t)input & 3) || bytes != YOLO_INPUT_BYTES ||
        !width || width > JPEG_LCD_WIDTH || !height || height > JPEG_LCD_HEIGHT)
        return YOLO_ERR_ARGUMENT;
    unsigned longest = width > height ? width : height;
    unsigned nw = round_even(width * YOLO_SIDE, longest);
    unsigned nh = round_even(height * YOLO_SIDE, longest);
    if (!nw) nw = 1;
    if (!nh) nh = 1;
    work.geometry = (yolo_geometry_t){width, height, nw, nh,
        (YOLO_SIDE-nw)/2, (YOLO_SIDE-nh)/2, (float)YOLO_SIDE/(float)longest};
    axis(work.xs, width, nw); axis(work.ys, height, nh);
    work.next_x = work.band_y = work.band_height = work.output_y = 0;
    work.input = input;
    for (unsigned i = 0; i < YOLO_INPUT_BYTES / sizeof(float); ++i) input[i] = 114.0f / 255.0f;
    work.active = 1;
    return 0;
}

static void emit_rows(unsigned available_y)
{
    const yolo_geometry_t *g = &work.geometry;
    unsigned dx = 2*g->resized_width, dy = 2*g->resized_height, den = dx*dy;
    while (work.output_y < g->resized_height && work.ys[work.output_y].hi <= available_y) {
        axis_t ay = work.ys[work.output_y];
        const uint8_t *a = work.rows[ay.lo % 17], *b = work.rows[ay.hi % 17];
        for (unsigned x = 0; x < g->resized_width; ++x) {
            axis_t ax = work.xs[x];
            for (unsigned c = 0; c < 3; ++c) {
                unsigned h0 = a[ax.lo*3+c]*(dx-ax.fraction) + a[ax.hi*3+c]*ax.fraction;
                unsigned h1 = b[ax.lo*3+c]*(dx-ax.fraction) + b[ax.hi*3+c]*ax.fraction;
                /* Half-pixel bilinear, exact integer weights, uint8 half-up.
                   Maximum numerator < 255*320*320: safe in uint32_t.
                   This explicit rounding is shared with the PC oracle; OpenCV
                   INTER_LINEAR may differ by one RGB level. */
                unsigned pixel = (h0*(dy-ay.fraction) + h1*ay.fraction + den/2) / den;
                unsigned offset = c*YOLO_SIDE*YOLO_SIDE +
                    (work.output_y+g->top)*YOLO_SIDE + x+g->left;
                work.input[offset] = (float)pixel / 255.0f;
            }
        }
        ++work.output_y;
    }
}
int yolo_preprocess_rect(uint32_t x, uint32_t y, uint32_t width,
                         uint32_t height, const uint8_t *rgb)
{
    const yolo_geometry_t *g = &work.geometry;
    if (!work.active || !rgb || !width || width > 16 || !height || height > 16 ||
        x != work.next_x || y != work.band_y || x >= g->width || y >= g->height ||
        width > g->width-x || height > g->height-y ||
        (x && height != work.band_height)) {
        work.active = 0;
        return YOLO_ERR_PREPROCESS;
    }
    if (!x) work.band_height = height;
    for (unsigned row = 0; row < height; ++row)
        memcpy(work.rows[(y+row)%17] + x*3, rgb + row*width*3, width*3);
    work.next_x += width;
    if (work.next_x == g->width) {
        emit_rows(y+height-1);
        work.band_y += height;
        work.next_x = 0;
    }
    return 0;
}
int yolo_preprocess_finish(yolo_geometry_t *geometry)
{
    int rc = !geometry || !work.active || work.next_x ||
        work.band_y != work.geometry.height || work.output_y != work.geometry.resized_height
        ? YOLO_ERR_PREPROCESS : 0;
    if (geometry) *geometry = rc ? (yolo_geometry_t){0} : work.geometry;
    work.active = 0;
    work.input = 0;
    return rc;
}
typedef struct { float *input; size_t bytes; } jpeg_input_t;
static int begin(void *user, uint32_t width, uint32_t height)
{
    jpeg_input_t *in = user;
    return yolo_preprocess_begin(width, height, in->input, in->bytes);
}
static int rect(void *user, uint32_t x, uint32_t y, uint32_t width,
                 uint32_t height, const uint8_t *rgb)
{
    (void)user;
    return yolo_preprocess_rect(x, y, width, height, rgb);
}
int yolo_prepare_jpeg(const char *name, float *input, size_t bytes, yolo_geometry_t *geometry)
{
    if (!geometry) return YOLO_ERR_ARGUMENT;
    *geometry = (yolo_geometry_t){0};
    jpeg_input_t in = {input, bytes};
    const jpeg_rgb_sink_t sink = {begin, rect, &in};
    int rc = jpeg_decode_rgb(name, &sink);
    if (rc) { work.active = 0; work.input = 0; return rc; }
    return yolo_preprocess_finish(geometry);
}
