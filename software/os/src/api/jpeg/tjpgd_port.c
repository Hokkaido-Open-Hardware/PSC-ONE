#include "tjpgd_port.h"

/* Track the entropy stream through read-ahead as well as consumed bytes.
   jd_decomp stops after the expected MCU count; it does not require EOI. */
static void check_entropy(jpeg_session_t *s, const uint8_t *p, uint32_t pos, uint32_t n)
{
    for (uint32_t i = 0; i < n; i++) {
        if (pos + i < s->scan_offset || s->eoi) continue;
        uint8_t c = p[i];
        if (s->entropy_ff) {
            if (c == 0xd9) s->eoi = 1;
            else if (c != 0 && c != 255 && (c < 0xd0 || c > 0xd7))
                s->error = JPEG_ERR_FORMAT;
            s->entropy_ff = c == 255;
        } else s->entropy_ff = c == 255;
    }
}
size_t jpeg_input(JDEC *jd, uint8_t *buffer, size_t count)
{
    jpeg_session_t *s = jd->device;
    uint32_t got = 0, pos = s->file.file_pos;
    if (s->error) return 0;
    int rc = buffer ? fat32_stream_read(&s->file, buffer, count, &got)
                    : fat32_skip(&s->file, count, &got);
    if (rc) { s->error = rc; return 0; }
    if (buffer) check_entropy(s, buffer, pos, got);
    return s->error ? 0 : got;
}
int jpeg_output(JDEC *jd, void *bitmap, JRECT *rect)
{
    jpeg_session_t *s = jd->device;
    if (s->error) return 0;
    if (rect->right < rect->left || rect->bottom < rect->top ||
        rect->right >= s->width || rect->bottom >= s->height) {
        s->error = JPEG_ERR_FORMAT; return 0;
    }
    if (call_lcd_rgb888_rect(rect->left, rect->top, rect->right - rect->left + 1,
                            rect->bottom - rect->top + 1, bitmap)) {
        s->error = JPEG_ERR_LCD; return 0;
    }
    return 1;
}
int jpeg_finish_input(jpeg_session_t *s)
{
    uint8_t tail[32];
    while (!s->eoi && !s->error) {
        if (!jpeg_input(&s->decoder, tail, sizeof(tail)))
            return s->error ? s->error : JPEG_ERR_EOF;
    }
    return s->error;
}
