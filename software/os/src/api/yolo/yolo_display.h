#ifndef PSC_YOLO_DISPLAY_H
#define PSC_YOLO_DISPLAY_H
#include "yolo.h"
#ifdef __cplusplus
extern "C" {
#endif
/* Re-decode at (0,0), 1:1, then draw saved original-image detections.
   Does not invoke/reset inference or modify result. Synchronous, no heap.
   A JPEG/LCD error may leave a partial image; no overlays until EOI passes. */
int yolo_display(const char *jpeg, const yolo_result_t *result);
/* Remove an old result before starting a new shell inference. */
int yolo_display_clear(void);
/* Bounded RGB label primitive, also used by host edge/long-name replay.
   Requires landscape RGB begin first. Coordinates are clamped to the LCD.
   No portrait text API, scrolling or framebuffer; not reentrant. */
int yolo_display_label(unsigned x, unsigned y, const char *name, float score);
#ifdef __cplusplus
}
#endif
#endif
