#include "jpeg_view.h"
#include "tjpgd_port.h"

static jpeg_session_t session;
static int busy;

const char *jpeg_error_string(int error)
{
    switch (error) {
    case FAT32_ERR_NAME: return "use uppercase 8.3 filename";
    case FAT32_ERR_NOT_FOUND: return "file not found";
    case FAT32_ERR_SD: return "sd read error";
    case FAT32_ERR_FORMAT: return "fat error";
    case FAT32_ERR_CHAIN: return "broken FAT chain";
    case JPEG_ERR_UNSUPPORTED: return "unsupported jpeg";
    case JPEG_ERR_LARGE: return "image too large";
    case JPEG_ERR_EOF: return "unexpected EOF";
    case JPEG_ERR_LCD: return "lcd error";
    case JPEG_ERR_WORK: return "jpeg work area exhausted";
    default: return "decode error";
    }
}
static int decoder_error(JRESULT result)
{
    if (session.error) return session.error;
    if (result == JDR_OK) return 0;
    if (result == JDR_INP) return JPEG_ERR_EOF;
    if (result == JDR_FMT2 || result == JDR_FMT3 || result == JDR_MEM2)
        return JPEG_ERR_UNSUPPORTED;
    if (result == JDR_MEM1) return JPEG_ERR_WORK;
    return JPEG_ERR_FORMAT;
}
int jpeg_view(const char *filename)
{
    if (busy) return FAT32_ERR_STATE;
    busy = 1;
    session.error = 0; session.entropy_ff = session.eoi = 0;
    int rc = fat32_open(&session.file, filename);
    if (rc) goto done;
    rc = jpeg_check_headers(&session);
    if (rc) goto done;
    /* Reopen after the bounded header check; no backward-seek API needed. */
    fat32_close(&session.file);
    rc = fat32_open(&session.file, filename);
    if (rc) goto done;
    rc = decoder_error(jd_prepare(&session.decoder, jpeg_input, session.work,
                                  sizeof(session.work), &session));
    if (rc) goto done;
    if (session.decoder.width != session.width || session.decoder.height != session.height) {
        rc = JPEG_ERR_FORMAT; goto done;
    }
    printf("JPEG %dx%d\n", (int)session.width, (int)session.height);
    if (call_lcd_rgb888_begin()) { rc = JPEG_ERR_LCD; goto done; }
    rc = decoder_error(jd_decomp(&session.decoder, jpeg_output, 0));
    if (!rc) rc = jpeg_finish_input(&session);
done:
    fat32_close(&session.file);
    busy = 0;
    return rc;
}
