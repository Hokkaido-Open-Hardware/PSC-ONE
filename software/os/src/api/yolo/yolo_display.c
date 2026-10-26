#include "yolo_display.h"
#include "../jpeg/jpeg_view.h"
#include "../jpeg_display.h"
#include "../user.h"
#include "../../drivers/font.h"

/* One packed transfer tile, reused for fills and glyphs. Never a frame. */
static uint8_t overlay_tile[16 * 16 * 3];
enum { LCD_ERROR = -104, LABEL_CHARS = 39, LABEL_HEIGHT = 14 };
static const uint8_t ink[3] = {255, 255, 255};
static const uint8_t background[3] = {16, 16, 16};
static const uint8_t border[3] = {255, 224, 0};

static int finite(float v) { return __builtin_isfinite(v); }
static unsigned minimum(unsigned a, unsigned b) { return a < b ? a : b; }
static int tile(unsigned x, unsigned y, unsigned w, unsigned h)
{
    return call_lcd_rgb888_rect(x, y, w, h, overlay_tile) ? LCD_ERROR : 0;
}
static int fill(unsigned x, unsigned y, unsigned w, unsigned h, const uint8_t *color)
{
    if (x >= JPEG_LCD_WIDTH || y >= JPEG_LCD_HEIGHT) return 0;
    w = minimum(w, JPEG_LCD_WIDTH - x); h = minimum(h, JPEG_LCD_HEIGHT - y);
    for (unsigned i = 0; i < sizeof(overlay_tile); i += 3)
        for (unsigned c = 0; c < 3; ++c) overlay_tile[i+c] = color[c];
    for (unsigned row = 0; row < h; row += 16)
        for (unsigned col = 0; col < w; col += 16) {
            int rc = tile(x+col, y+row, minimum(16, w-col), minimum(16, h-row));
            if (rc) return rc;
        }
    return 0;
}
int yolo_display_clear(void)
{
    if (call_lcd_rgb888_begin()) return LCD_ERROR;
    return fill(0, 0, JPEG_LCD_WIDTH, JPEG_LCD_HEIGHT, background);
}
int yolo_display_label(unsigned x, unsigned y, const char *name, float score)
{
    if (!name || !finite(score) || score < 0 || score > 1) return YOLO_ERR_ARGUMENT;
    /* Reserve space for " 100.0%" and NUL, even with an arbitrary long name.
       Bounded reads; ASCII-only font maps unsupported bytes to '?'. */
    char label[LABEL_CHARS+1];
    unsigned n = 0, limit = LABEL_CHARS-7;
    while (n < limit && name[n]) { label[n] = name[n]; ++n; }
    if (n == limit && name[n]) label[n-1] = label[n-2] = label[n-3] = '.';
    unsigned value = (unsigned)(score * 1000.0f + 0.5f);
    label[n++] = ' ';
    if (value >= 1000) label[n++] = '1';
    if (value >= 100) label[n++] = (char)('0' + (value/100)%10);
    label[n++] = (char)('0' + (value/10)%10);
    label[n++] = '.'; label[n++] = (char)('0' + value%10); label[n++] = '%'; label[n] = 0;
    unsigned width = n*FONT_WIDTH+4;
    x = minimum(x, JPEG_LCD_WIDTH-width); y = minimum(y, JPEG_LCD_HEIGHT-LABEL_HEIGHT);
    int rc = fill(x, y, width, LABEL_HEIGHT, background);
    if (rc) return rc;
    for (unsigned i = 0; i < n; ++i) {
        unsigned ch = (unsigned char)label[i];
        if (ch < 32 || ch > 126) ch = '?';
        for (unsigned row = 0; row < FONT_HEIGHT; ++row)
            for (unsigned col = 0; col < FONT_WIDTH; ++col) {
                const uint8_t *color = font12x12[ch-32][row] & (1u << (11-col)) ? ink : background;
                for (unsigned c = 0; c < 3; ++c)
                    overlay_tile[(row*FONT_WIDTH+col)*3+c] = color[c];
            }
        rc = tile(x+2+i*FONT_WIDTH, y+1, FONT_WIDTH, FONT_HEIGHT);
        if (rc) return rc;
    }
    return 0;
}
/* Half-open continuous xyxy -> inclusive raster pixels: floor(start),
   ceil(end)-1. Clamp BEFORE float-to-integer conversion (480 -> 479).
   A box wholly outside the image produces no pixels or label. */
static int box_pixels(const yolo_detection_t *d, const yolo_geometry_t *g, unsigned *p)
{
    const float v[4] = {d->x1, d->y1, d->x2, d->y2};
    const unsigned bound[4] = {g->width, g->height, g->width, g->height};
    float clipped[4];
    for (unsigned i = 0; i < 4; ++i)
        clipped[i] = v[i] < 0 ? 0 : v[i] > bound[i] ? (float)bound[i] : v[i];
    if (clipped[2] <= clipped[0] || clipped[3] <= clipped[1]) return 0;
    for (unsigned i = 0; i < 4; ++i) {
        unsigned q = (unsigned)clipped[i];
        p[i] = i < 2 ? q : q + (clipped[i] > (float)q) - 1;
    }
    return 1;
}
static int image_begin(void *user, uint32_t w, uint32_t h)
{
    const yolo_result_t *r = user;
    if (w != r->geometry.width || h != r->geometry.height) return YOLO_ERR_ARGUMENT;
    /* Resets MADCTL, pixel mode AND scroll offset, even after shell text. */
    return call_lcd_rgb888_begin() ? LCD_ERROR : 0;
}
static int image_rect(void *user, uint32_t x, uint32_t y, uint32_t w, uint32_t h, const uint8_t *rgb)
{
    (void)user;
    return call_lcd_rgb888_rect(x, y, w, h, rgb) ? LCD_ERROR : 0;
}
int yolo_display(const char *jpeg, const yolo_result_t *r)
{
    if (!jpeg || !r || !r->geometry.width || !r->geometry.height ||
        r->geometry.width > JPEG_LCD_WIDTH || r->geometry.height > JPEG_LCD_HEIGHT ||
        r->count > YOLO_MAX_DETECTIONS) return YOLO_ERR_ARGUMENT;
    for (unsigned i = 0; i < r->count; ++i) {
        const yolo_detection_t *d = &r->detections[i];
        if (!finite(d->x1) || !finite(d->y1) || !finite(d->x2) || !finite(d->y2) ||
            !finite(d->score) || d->score < 0 || d->score > 1 || d->class_id >= YOLO_CLASSES ||
            d->x2 <= d->x1 || d->y2 <= d->y1) return YOLO_ERR_ARGUMENT;
    }
    const jpeg_rgb_sink_t sink = {image_begin, image_rect, (void *)r};
    int rc = jpeg_decode_rgb(jpeg, &sink);
    if (rc) return rc;
    for (unsigned i = 0; i < r->count; ++i) {
        unsigned p[4];
        if (!box_pixels(&r->detections[i], &r->geometry, p)) continue;
        unsigned w = p[2]-p[0]+1, h = p[3]-p[1]+1;
        unsigned bw = minimum(2, w), bh = minimum(2, h);
        rc = fill(p[0], p[1], w, bh, border); if (rc) return rc;
        rc = fill(p[0], p[3]+1-bh, w, bh, border); if (rc) return rc;
        rc = fill(p[0], p[1], bw, h, border); if (rc) return rc;
        rc = fill(p[2]+1-bw, p[1], bw, h, border); if (rc) return rc;
    }
    /* Labels last: later frames cannot erase the text/background. */
    for (unsigned i = 0; i < r->count; ++i) {
        unsigned p[4]; const yolo_detection_t *d = &r->detections[i];
        if (!box_pixels(d, &r->geometry, p)) continue;
        unsigned y = p[1] >= LABEL_HEIGHT ? p[1]-LABEL_HEIGHT : p[1]+2;
        rc = yolo_display_label(p[0], y, yolo_class_name(d->class_id), d->score);
        if (rc) return rc;
    }
    return 0;
}
