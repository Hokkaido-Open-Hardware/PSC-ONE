#include "lcd_api.h"
#include "font.h"
#include "boot_logo.h"
#include "kernel.h"
#include "common.h"
#include <stdarg.h>

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
static void lcd_scroll_init(void)
{
    // Vertical Scrolling Definition
    tft_write(0x033, 100);

    // TFA = 0
    tft_write(0x100 | 0x00, 100);
    tft_write(0x100 | 0x00, 100);

    // VSA = 480 = 0x01E0
    tft_write(0x100 | 0x01, 100);
    tft_write(0x100 | 0xE0, 100);

    // BFA = 0
    tft_write(0x100 | 0x00, 100);
    tft_write(0x100 | 0x00, 100);
}

// ------------------------------------------------------------
static void lcd_set_scroll(uint32_t vsp)
{
    vsp %= 480;

    tft_write(0x037, 100);

    tft_write(
        0x100 | ((vsp >> 8) & 0xFF),
        100
    );

    tft_write(
        0x100 | (vsp & 0xFF),
        100
    );
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

    // scroll_init
    lcd_scroll_init();

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

#if 0
    // scroll lcd

    lcd_set_scroll(0);
    tiny_delay(1000000);

    lcd_set_scroll(12);
    tiny_delay(1000000);

    lcd_set_scroll(24);
    tiny_delay(1000000);

    lcd_set_scroll(36);
#endif
}

// ------------------------------------------------------------
// LCD text mode : 90 degree rotation from landscape mode
//
// landscape MADCTL = 0xE8
// text portrait    = 0x88
//
// 0x88 is the experimentally verified portrait setting:
//   - 90 degree text orientation
//   - left/right mirror corrected
//
// Boot logo keeps using the original landscape setting in
// tft_init_seq(); this setting is applied only for text mode.
// ------------------------------------------------------------
static void lcd_set_text_rotate90(void)
{
    // Memory Access Control
    tft_write(0x036, 100);
    // Portrait + horizontal mirror correction
    // 0xC8 -> 0x88 : toggle MX(bit6)
    tft_write(0x188, 100);
}

// ------------------------------------------------------------
void lcd_draw_text(void)
{
    s_printf("LCD TEXT Output start.\n");

    tft_init_seq(AFTER_WAIT);

    // Text display only: rotate 90 degrees.
    lcd_set_text_rotate90();

    // In portrait mode the ILI9488 vertical scroll direction
    // matches the text screen vertical direction.
    lcd_scroll_init();
    lcd_set_scroll(0);

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

#define LCD_WIDTH   320
#define LCD_HEIGHT  480

#define LCD_FONT_W      12
#define LCD_FONT_H      12

static uint32_t lcd_cursor_x = 0;
static uint32_t lcd_cursor_y = 0;

// ILI9488 GRAM vertical scroll start address.
// Text mode is 320x480 portrait, 12-pixel line pitch.
static uint32_t lcd_scroll_y = 0;


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
    uint32_t draw_y;

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

    // Logical screen Y -> physical GRAM Y.
    //
    // On the verified MADCTL=0x88 setting, visible upward scrolling
    // is obtained by DECREASING VSP.  Therefore the logical-to-GRAM
    // conversion must use the opposite sign from VSP.
    //
    // lcd_scroll_y is always a multiple of 12, and text rows are
    // 12 pixels high, so draw_y is also a multiple of 12 and the
    // 12-pixel window never crosses 479 -> 0.
    draw_y =
        (y + LCD_HEIGHT - lcd_scroll_y)
        % LCD_HEIGHT;

    // 12x12領域
    lcd_set_window(
        x,
        draw_y,
        x + LCD_FONT_W - 1,
        draw_y + LCD_FONT_H - 1
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
// lcd_clear_text_line
//
// logical_y : visible screen coordinate (0..479)
//
// Clear one 12-pixel text row in the physical GRAM ring buffer.
// ============================================================
static void lcd_clear_text_line(uint32_t logical_y)
{
    uint32_t draw_y;

    // Must use exactly the same logical->GRAM transform as
    // lcd_draw_char(), otherwise the recycled line is not cleared.
    draw_y =
        (logical_y + LCD_HEIGHT - lcd_scroll_y)
        % LCD_HEIGHT;

    lcd_set_window(
        0,
        draw_y,
        LCD_WIDTH - 1,
        draw_y + LCD_FONT_H - 1
    );

    for (uint32_t py = 0; py < LCD_FONT_H; py++) {
        for (uint32_t px = 0; px < LCD_WIDTH; px++) {
            lcd_write_rgb(0, 0, 0);
        }
    }
}

// ============================================================
// lcd_scroll_one_line
//
// Visible behavior:
//   old lines move upward by one text row,
//   and a blank new row appears at the bottom.
//
// MADCTL=0x88 was verified on the real LCD.
// For this orientation, VSP must DECREASE by 12 pixels.
// ============================================================
static void lcd_scroll_one_line(void)
{
    // --------------------------------------------------------
    // Move VSP by one 12-pixel text row.
    // --------------------------------------------------------
    if (lcd_scroll_y >= LCD_FONT_H) {
        lcd_scroll_y -= LCD_FONT_H;
    } else {
        lcd_scroll_y = LCD_HEIGHT - LCD_FONT_H;
    }

    // --------------------------------------------------------
    // Apply hardware scroll.
    // --------------------------------------------------------
    lcd_set_scroll(lcd_scroll_y);

    // --------------------------------------------------------
    // Cursor remains at the last visible text row.
    // --------------------------------------------------------
    lcd_cursor_y = LCD_HEIGHT - LCD_FONT_H;

    // --------------------------------------------------------
    // Clear the GRAM row that is now the new bottom row.
    //
    // lcd_clear_text_line() uses the same logical->GRAM mapping
    // as lcd_draw_char(), so the row cleared here is exactly the
    // row into which the next text will be written.
    // --------------------------------------------------------
    lcd_clear_text_line(lcd_cursor_y);
}


// ============================================================
// lcd_line_feed
// ============================================================
static void lcd_line_feed(void)
{
    lcd_cursor_x = 0;
    lcd_cursor_y += LCD_FONT_H;

    if ((lcd_cursor_y + LCD_FONT_H) > LCD_HEIGHT) {
        lcd_scroll_one_line();
    }
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

        lcd_line_feed();

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
            lcd_line_feed();
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
        lcd_line_feed();
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

    // Return the GRAM ring buffer to its initial position.
    lcd_scroll_y = 0;
    lcd_set_scroll(0);

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

// ============================================================
// lcd_printf
// ============================================================
void lcd_printf(const char *fmt, ...)
{
    va_list vargs;
    va_start(vargs, fmt);

    while (*fmt) {

        if (*fmt == '%') {

            fmt++;

            switch (*fmt) {

                case '\0':
                    lcd_putc('%');
                    goto end;

                case '%':
                    lcd_putc('%');
                    break;

                case 's': {
                    const char *s =
                        va_arg(vargs, const char *);

                    while (*s) {
                        lcd_putc(*s);
                        s++;
                    }

                    break;
                }

                case 'd': {
                    int value =
                        va_arg(vargs, int);

                    unsigned int u;

                    if (value < 0) {

                        lcd_putc('-');

                        u =
                            (unsigned int)
                            (-(value + 1))
                            + 1;

                    } else {

                        u =
                            (unsigned int)value;
                    }

                    char buf[11];
                    int i = 0;

                    if (u == 0) {
                        lcd_putc('0');
                        break;
                    }

                    while (u > 0) {
                        buf[i++] =
                            '0' + (u % 10);
                        u /= 10;
                    }

                    while (i > 0) {
                        lcd_putc(buf[--i]);
                    }

                    break;
                }

                case 'x': {

                    unsigned value =
                        va_arg(vargs, unsigned);

                    for (int i = 7; i >= 0; i--) {

                        unsigned nibble =
                            (value >> (i * 4))
                            & 0x0f;

                        lcd_putc(
                            "0123456789abcdef"
                            [nibble]
                        );
                    }

                    break;
                }

                default:
                    lcd_putc('%');
                    lcd_putc(*fmt);
                    break;
            }

        } else {

            lcd_putc(*fmt);
        }

        fmt++;
    }

end:
    va_end(vargs);
}