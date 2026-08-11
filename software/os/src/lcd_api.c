#include "lcd_api.h"
#include "font.h"
#include "boot_logo.h"
#include "kernel.h"
#include "common.h"

#define IPS_MODE 1

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

    // spi_idle=0の場合はwait
    uint32_t timeout = 100000u;
    while ((PSC_LCD_PIXS_ST & 0x01) == 0x00) {
        if (--timeout == 0u) {
            s_printf("spi_idle TIMEOUT\n");
            return;
        }
        __asm__ volatile("nop");
    }
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
    tft_write(0x1E8, 100);

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
    tft_write(0x02A, 500);
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
// LCD出力 : RGB666(RGB111)
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

    for (uint32_t by = 0; by < 320; by += 1) {

        for (uint32_t bx = 0; bx < 480; bx += 1) {

            uint32_t c;
            uint32_t r_buf;
            uint32_t g_buf;
            uint32_t b_buf;

            if (bx < 480 && by < 320) {
                c = boot_logo[by * 480 + bx];
            } else {
                c = 0x07;
            }

            r_buf = (c & 1) ? 255 : 0;
            g_buf = (c & 2) ? 255 : 0;
            b_buf = (c & 4) ? 255 : 0;
            
            if (IPS_MODE==1) {
                tft_write(((255 - r_buf) & 0xFF) | 0x100, 10);
                tft_write(((255 - g_buf) & 0xFF) | 0x100, 10);
                tft_write(((255 - b_buf) & 0xFF) | 0x100, 10);
            } else {
                tft_write((r_buf & 0xFF) | 0x100, 10);
                tft_write((g_buf & 0xFF) | 0x100, 10);
                tft_write((b_buf & 0xFF) | 0x100, 10);
            }
            //tiny_delay(300);
        }
    }

#endif
}

// ------------------------------------------------------------
void lcd_draw_text(void)
{
    s_printf("LCD TEXT Output start.\n");

    tft_init_seq(AFTER_WAIT);

    lcd_clear();

    lcd_set_cursor(0, 0);

    lcd_puts("PSC-ONE\n");
    lcd_puts("PSC-OS\n");
    lcd_puts("RISC-V RV32ISP\n");
    lcd_puts("\n");
    lcd_puts("SYSTEM READY\n");
}

// ============================================================
// LCD TEXT API
// 12x12 font
// ============================================================

#define LCD_WIDTH   480
#define LCD_HEIGHT  320

#define LCD_FONT_W      12
#define LCD_FONT_H      12

static uint32_t lcd_cursor_x = 0;
static uint32_t lcd_cursor_y = 0;


// ============================================================
// lcd_write_rgb
// ============================================================
static void lcd_write_rgb(
    uint32_t r,
    uint32_t g,
    uint32_t b
)
{
    if (IPS_MODE == 1) {
        r = 255 - r;
        g = 255 - g;
        b = 255 - b;
    }

    tft_write((r & 0xFF) | 0x100, 10);
    tft_write((g & 0xFF) | 0x100, 10);
    tft_write((b & 0xFF) | 0x100, 10);
}


// ============================================================
// lcd_set_window
// 描画範囲設定
// ============================================================
static void lcd_set_window(
    uint32_t x_start,
    uint32_t y_start,
    uint32_t x_end,
    uint32_t y_end
)
{
    // Column Address Set
    tft_write(0x02A, 100);

    tft_write(
        0x100 | ((x_start >> 8) & 0xFF),
        100
    );

    tft_write(
        0x100 | (x_start & 0xFF),
        100
    );

    tft_write(
        0x100 | ((x_end >> 8) & 0xFF),
        100
    );

    tft_write(
        0x100 | (x_end & 0xFF),
        100
    );


    // Row Address Set
    tft_write(0x02B, 100);

    tft_write(
        0x100 | ((y_start >> 8) & 0xFF),
        100
    );

    tft_write(
        0x100 | (y_start & 0xFF),
        100
    );

    tft_write(
        0x100 | ((y_end >> 8) & 0xFF),
        100
    );

    tft_write(
        0x100 | (y_end & 0xFF),
        100
    );


    // Memory Write
    tft_write(0x02C, 100);
}


// ============================================================
// lcd_draw_char
//
// 12x12 bitmap font
//
// font12x12[ch - 0x20][row]
//
// bit11 = 左端
// bit0  = 右端
//
// foreground : 白
// background : 黒
// ============================================================
void lcd_draw_char(
    uint32_t x,
    uint32_t y,
    char ch
)
{
    uint32_t px;
    uint32_t py;
    uint16_t bits;

    // ASCII 0x20 ～ 0x7E
    if ((uint8_t)ch < 0x20 ||
        (uint8_t)ch > 0x7E) {
        ch = '?';
    }

    // LCD範囲チェック
    if ((x + LCD_FONT_W) > LCD_WIDTH) {
        return;
    }

    if ((y + LCD_FONT_H) > LCD_HEIGHT) {
        return;
    }

    // 12x12領域
    lcd_set_window(
        x,
        y,
        x + LCD_FONT_W - 1,
        y + LCD_FONT_H - 1
    );

    // 12行
    for (py = 0; py < LCD_FONT_H; py++) {

        // この行の12bitを取得
        bits = font12x12[
            (uint8_t)ch - 0x20
        ][py];

        // 1行12pixel
        for (px = 0; px < LCD_FONT_W; px++) {

                if (bits & (0x800u >> px)) {

                // foreground
                lcd_write_rgb(
                    255,      // reg
                    255,      // green
                    255       // blue
                );

            } else {

                // background
                lcd_write_rgb(
                    0,
                    0,
                    0
                );
            }
        }
    }
}


// ============================================================
// lcd_set_cursor
// ============================================================
void lcd_set_cursor(
    uint32_t x,
    uint32_t y
)
{
    lcd_cursor_x = x;
    lcd_cursor_y = y;
}


// ============================================================
// lcd_get_cursor_x
// ============================================================
uint32_t lcd_get_cursor_x(void)
{
    return lcd_cursor_x;
}


// ============================================================
// lcd_get_cursor_y
// ============================================================
uint32_t lcd_get_cursor_y(void)
{
    return lcd_cursor_y;
}


// ============================================================
// lcd_putc
// ============================================================
void lcd_putc(char ch)
{

    // --------------------------------------------------------
    // LF
    // --------------------------------------------------------
    if (ch == '\n') {

        lcd_cursor_x = 0;

        lcd_cursor_y += LCD_FONT_H;

        // 画面下端
        if (
            (lcd_cursor_y + LCD_FONT_H)
            > LCD_HEIGHT
        ) {
            lcd_cursor_y = 0;
        }

        return;
    }


    // --------------------------------------------------------
    // CR
    // --------------------------------------------------------
    if (ch == '\r') {

        lcd_cursor_x = 0;

        return;
    }


    // --------------------------------------------------------
    // TAB
    // --------------------------------------------------------
    if (ch == '\t') {

        // 4文字分
        uint32_t next_tab;

        next_tab =
            (
                (lcd_cursor_x /
                 (LCD_FONT_W * 4))
                + 1
            )
            * (LCD_FONT_W * 4);

        lcd_cursor_x = next_tab;


        if (
            (lcd_cursor_x + LCD_FONT_W)
            > LCD_WIDTH
        ) {

            lcd_cursor_x = 0;

            lcd_cursor_y += LCD_FONT_H;
        }

        return;
    }


    // --------------------------------------------------------
    // 通常文字
    // --------------------------------------------------------
    lcd_draw_char(
        lcd_cursor_x,
        lcd_cursor_y,
        ch
    );


    lcd_cursor_x += LCD_FONT_W;


    // --------------------------------------------------------
    // 右端で自動改行
    // --------------------------------------------------------
    if (
        (lcd_cursor_x + LCD_FONT_W)
        > LCD_WIDTH
    ) {

        lcd_cursor_x = 0;

        lcd_cursor_y += LCD_FONT_H;
    }


    // --------------------------------------------------------
    // 下端
    // 現状は上端へ戻る
    // --------------------------------------------------------
    if (
        (lcd_cursor_y + LCD_FONT_H)
        > LCD_HEIGHT
    ) {

        lcd_cursor_y = 0;
    }
}


// ============================================================
// lcd_puts
// ============================================================
void lcd_puts(const char *str)
{
    if (str == 0) {
        return;
    }

    while (*str != '\0') {

        lcd_putc(*str);

        str++;
    }
}


// ============================================================
// lcd_clear
// ============================================================
void lcd_clear(void)
{
    uint32_t x;
    uint32_t y;

    lcd_set_window(
        0,
        0,
        LCD_WIDTH - 1,
        LCD_HEIGHT - 1
    );


    for (y = 0; y < LCD_HEIGHT; y++) {

        for (x = 0; x < LCD_WIDTH; x++) {

            lcd_write_rgb(
                0,
                0,
                0
            );
        }
    }


    lcd_cursor_x = 0;
    lcd_cursor_y = 0;
}