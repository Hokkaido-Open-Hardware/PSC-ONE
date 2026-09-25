#ifndef PSC_JPEG_DISPLAY_H
#define PSC_JPEG_DISPLAY_H

/* JPEG RGB888 logical coordinates. Text retains its own portrait geometry. */
#define JPEG_LCD_WIDTH  480u
#define JPEG_LCD_HEIGHT 320u
/* Same landscape orientation as tft_init_seq()/boot logo; BGR stays set. */
#define JPEG_LCD_MADCTL 0xE8u

#endif
