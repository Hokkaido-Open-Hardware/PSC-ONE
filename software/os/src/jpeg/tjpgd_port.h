#ifndef PSC_TJPGD_PORT_H
#define PSC_TJPGD_PORT_H
#include "fat32.h"
#include "tjpgd.h"

/* Also includes the decoder's input/MCU/RGB scratch allocations. */
#define JPEG_WORK_BYTES 4096
/* Bound header work/IO on malformed files, not a compressed-image RAM limit. */
#define JPEG_HEADER_LIMIT (128u * 1024u)
enum { JPEG_ERR_FORMAT = -100, JPEG_ERR_UNSUPPORTED = -101,
       JPEG_ERR_LARGE = -102, JPEG_ERR_EOF = -103,
       JPEG_ERR_LCD = -104, JPEG_ERR_WORK = -105 };
typedef struct {
    fat32_file_t file;
    JDEC decoder;
    uint32_t work[JPEG_WORK_BYTES / 4];
    uint32_t scan_offset;
    uint16_t width, height;
    int error;
    uint8_t entropy_ff, eoi;
} jpeg_session_t;
int jpeg_check_headers(jpeg_session_t *s);
size_t jpeg_input(JDEC *jd, uint8_t *buffer, size_t count);
int jpeg_output(JDEC *jd, void *bitmap, JRECT *rect);
int jpeg_finish_input(jpeg_session_t *s);
#endif
