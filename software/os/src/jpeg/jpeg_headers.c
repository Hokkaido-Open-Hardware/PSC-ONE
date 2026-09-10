/* Validate segment bounds and Phase-1 syntax before the unchanged upstream
   parser sees them. Its small-memory parser assumes well-formed tables.
   Only headers are read twice; entropy data is streamed once. */
#include "tjpgd_port.h"
#include "jpeg_display.h"

static unsigned be16(const uint8_t *p) { return ((unsigned)p[0] << 8) | p[1]; }
static int read_exact(jpeg_session_t *s, void *p, uint32_t n) {
    uint32_t got;
    int rc = fat32_stream_read(&s->file, p, n, &got);
    return rc ? rc : got == n ? 0 : JPEG_ERR_EOF;
}
int jpeg_check_headers(jpeg_session_t *s)
{
    uint8_t *b = (uint8_t *)s->work;
    unsigned components = 0, quant_mask = 0, huff_mask = 0;
    uint8_t qid[3] = {0};
    int rc = read_exact(s, b, 2);
    if (rc) return rc;
    if (b[0] != 255 || b[1] != 0xd8) return JPEG_ERR_FORMAT;
    for (;;) {
        if (s->file.file_pos > JPEG_HEADER_LIMIT) return JPEG_ERR_UNSUPPORTED;
        if ((rc = read_exact(s, b, 4))) return rc;
        if (b[0] != 255 || be16(b + 2) < 2) return JPEG_ERR_FORMAT;
        unsigned marker = b[1], n = be16(b + 2) - 2;
        if (n > s->file.file_size - s->file.file_pos) return JPEG_ERR_EOF;
        if ((marker >= 0xe0 && marker <= 0xef) || marker == 0xfe) {
            /* Adobe transform=0 denotes RGB, transform=2 YCCK: unsupported. */
            if (marker == 0xee && n >= 12) {
                if ((rc = read_exact(s, b, 12))) return rc;
                n -= 12;
                if (b[0] == 'A' && b[1] == 'd' && b[2] == 'o' &&
                    b[3] == 'b' && b[4] == 'e' && b[11] != 1)
                    return JPEG_ERR_UNSUPPORTED;
            }
            if ((rc = read_exact(s, 0, n))) return rc;
            continue;
        }
        if (marker != 0xc0 && marker != 0xc4 && marker != 0xdb &&
            marker != 0xdd && marker != 0xda) return JPEG_ERR_UNSUPPORTED;
        if (!n || n > JD_SZBUF) return JPEG_ERR_UNSUPPORTED;
        if ((rc = read_exact(s, b, n))) return rc;
        if (marker == 0xc0) {
            if (components || n < 6) return JPEG_ERR_FORMAT;
            if (b[0] != 8 || (b[5] != 1 && b[5] != 3)) return JPEG_ERR_UNSUPPORTED;
            components = b[5];
            if (n != 6 + 3 * components) return JPEG_ERR_FORMAT;
            s->height = be16(b + 1); s->width = be16(b + 3);
            if (!s->width || !s->height) return JPEG_ERR_FORMAT;
            if (s->width > JPEG_LCD_WIDTH || s->height > JPEG_LCD_HEIGHT) return JPEG_ERR_LARGE;
            for (unsigned i = 0; i < components; i++) {
                unsigned sample = b[7 + 3 * i];
                if (b[6 + 3 * i] != i + 1 || b[8 + 3 * i] > 3)
                    return JPEG_ERR_UNSUPPORTED;
                if (i || components == 1) {
                    if (sample != 0x11) return JPEG_ERR_UNSUPPORTED;
                } else if (sample != 0x11 && sample != 0x21 && sample != 0x22)
                    return JPEG_ERR_UNSUPPORTED;
                qid[i] = b[8 + 3 * i];
            }
        } else if (marker == 0xdb) {
            if (n % 65) return JPEG_ERR_FORMAT;
            for (unsigned p = 0; p < n; p += 65) {
                if (b[p] > 3) return JPEG_ERR_UNSUPPORTED;
                if (quant_mask & (1u << b[p])) return JPEG_ERR_UNSUPPORTED;
                quant_mask |= 1u << b[p];
                for (unsigned j = 1; j <= 64; j++) if (!b[p + j]) return JPEG_ERR_FORMAT;
            }
        } else if (marker == 0xc4) {
            for (unsigned p = 0; p < n;) {
                if (n - p < 17) return JPEG_ERR_FORMAT;
                unsigned type = b[p++], count = 0;
                if (type != 0 && type != 1 && type != 0x10 && type != 0x11)
                    return JPEG_ERR_UNSUPPORTED;
                unsigned bit = (type & 1) * 2 + (type >> 4);
                if (huff_mask & (1u << bit)) return JPEG_ERR_UNSUPPORTED;
                huff_mask |= 1u << bit;
                int slots = 1;
                for (unsigned i = 0; i < 16; i++) {
                    unsigned c = b[p++]; count += c; slots = slots * 2 - (int)c;
                    /* JPEG disallows an all-ones Huffman code. */
                    if (slots <= 0) return JPEG_ERR_FORMAT;
                }
                if (!count || count > 256 || count > n - p) return JPEG_ERR_FORMAT;
                for (unsigned i = 0; i < count; i++) {
                    unsigned symbol = b[p++];
                    if (type < 16) { if (symbol > 11) return JPEG_ERR_FORMAT; }
                    else if ((symbol & 15) > 10 ||
                             (!(symbol & 15) && symbol != 0 && symbol != 0xf0))
                        return JPEG_ERR_FORMAT;
                }
            }
        } else if (marker == 0xdd) {
            if (n != 2) return JPEG_ERR_FORMAT;
        } else { /* Single interleaved baseline scan. */
            if (!components || n != 4 + 2 * components || b[0] != components)
                return JPEG_ERR_UNSUPPORTED;
            if (b[n - 3] != 0 || b[n - 2] != 63 || b[n - 1] != 0)
                return JPEG_ERR_UNSUPPORTED;
            for (unsigned i = 0; i < components; i++) {
                if (b[1 + 2 * i] != i + 1 || b[2 + 2 * i] != (i ? 0x11 : 0))
                    return JPEG_ERR_UNSUPPORTED;
                unsigned required = i ? 12 : 3;
                if (!(quant_mask & (1u << qid[i])) || (huff_mask & required) != required)
                    return JPEG_ERR_FORMAT;
            }
            s->scan_offset = s->file.file_pos;
            return 0;
        }
    }
}
