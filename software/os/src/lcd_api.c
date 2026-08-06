#include "lcd_api.h"
#include "boot_logo.h"
#include "kernel.h"
#include "common.h"

#define AFTER_WAIT  50000

static inline void tiny_delay(unsigned n){
    while (n--) {
        __asm__ __volatile__("nop");
    }
}

// ============================================================
// tft_write
// ============================================================
void tft_write(uint32_t data, uint32_t wait)
{
    uint32_t tft_reset = 0x01;

    PSC_LCD_PIXS_DATA   = data;
    PSC_LCD_PIXS_ST     = 0x01 | (tft_reset << 1);

    tiny_delay(wait);
}

// ============================================================
// tft_init
// ============================================================
void tft_init_seq(uint32_t after_wait)
{

    tiny_delay(5000);

    // Software Reset
    // tft_reset=L
    PSC_LCD_PIXS_ST = 0x00 | (0x00 << 1);

    tiny_delay(5000);

    // NOP
    // tft_reset=H
    PSC_LCD_PIXS_ST = 0x00 | (0x01 << 1);

    tiny_delay(1000);

    // Software Reset
    tft_write(0x101, 100);

    // NOP
    tft_write(0x000, 100);

    // Pixel Format = RGB666
    tft_write(0x03A, 100);
    tft_write(0x166, 100);

    // Memory Access Control
    tft_write(0x036, 100);
    tft_write(0x1C8, 100);

    // Sleep Out
    tft_write(0x011, 100);

    // Display ON
    tft_write(0x029, 100);

    // after wait
    tiny_delay(after_wait);

}

// ============================================================
// tft write pix data settiing
// ============================================================
void tft_wire_pix_setting(uint32_t x_start, uint32_t y_start)
{
    uint32_t x_end = x_start + 479;
    uint32_t y_end = y_start + 319;

    // Column Address Set
    tft_write(0x029, 500);
    tft_write(0x100 | ((x_start & 0x1FF) >> 8), 100);
    tft_write(0x100 | (x_start & 0x0FF), 100);
    tft_write(0x100 | ((x_end & 0x1FF) >> 8), 100);
    tft_write(0x100 | (x_end & 0x0FF), 100);

    // Row Address Set
    tft_write(0x02B, 500);
    tft_write(0x100 | ((y_start & 0x1FF) >> 8), 100);
    tft_write(0x100 | (y_start & 0x0FF), 100);
    tft_write(0x100 | ((y_end & 0x1FF) >> 8), 100);
    tft_write(0x100 | (y_end & 0x0FF), 100);
    
    // Memory Write
    tft_write(0x02C, 500);
}

// ------------------------------------------------------------
// PSC-ONE Boot Logo Display
//
// boot_logo[] : 240x160
// 1pixel = 3bit RGB
//
// bit0 = Red
// bit1 = Green
// bit2 = Blue
//
// LCD出力 : RGB666
// ------------------------------------------------------------
void lcd_draw_boot_logo(void)
{
    s_printf("IMG BOOT LOGO start.\n");

    // tft_init
    tft_init_seq(AFTER_WAIT);

    // tft write pix data settiing
    tft_wire_pix_setting(0, 0);

#if 1
    // boot_logo[] = 480 x 320

    for (uint32_t by = 0; by < 480; by += 1) {

        for (uint32_t bx = 0; bx < 320; bx += 1) {

            uint32_t c;
            uint32_t r_buf;
            uint32_t g_buf;
            uint32_t b_buf;

            if (bx < 320 && by < 480) {
                c = boot_logo[bx * 480 + by];
            } else {
                c = 0x07;
            }

            r_buf = (c & 1) ? 63 : 0;
            g_buf = (c & 2) ? 63 : 0;
            b_buf = (c & 4) ? 63 : 0;
            
            tft_write((r_buf & 0xFF) | 0x100, 10);
            tft_write((g_buf & 0xFF) | 0x100, 10);
            tft_write((b_buf & 0xFF) | 0x100, 10);
            //tiny_delay(300);
        
        }
    }

#endif
}
