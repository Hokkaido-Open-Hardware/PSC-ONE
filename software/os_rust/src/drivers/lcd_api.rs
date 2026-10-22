//! drivers/lcd_api.c/.h. ILI9488 RGB666, inverted IPS colours.
use crate::common::{delay, mmio_r32, mmio_w32};
const DATA: u32 = 0x10003000;
const STATUS: u32 = 0x10003004;
static mut X: u32 = 0;
static mut Y: u32 = 0;
static mut SCROLL: u32 = 0;
/// Bound the SPI-idle wait so a stalled panel cannot block a checked operation forever.
unsafe fn idle() -> Result<(), i32> {
    let mut timeout = 100000;
    while mmio_r32(STATUS) & 1 == 0 {
        timeout -= 1;
        if timeout == 0 {
            return Err(-1);
        }
    }
    Ok(())
}

/// Submit one command/data word with reset deasserted, then apply the inter-word delay.
pub unsafe fn tft_write_checked(data: u32, wait: u32) -> Result<(), i32> {
    idle()?;
    mmio_w32(DATA, data);
    mmio_w32(STATUS, 3);
    delay(wait);
    Ok(())
}

/// Retain the legacy diagnostic API while the checked variant propagates errors.
pub unsafe fn tft_write(data: u32, wait: u32) {
    if tft_write_checked(data, wait).is_err() {
        crate::s_print!("spi_idle TIMEOUT\n");
    }
}

/// Reset the panel and select RGB666 landscape mode before leaving sleep.
pub unsafe fn tft_init_seq(after_wait: u32) {
    delay(5000);
    mmio_w32(STATUS, 0);
    delay(5000);
    mmio_w32(STATUS, 2);
    delay(1000);
    for d in [0x101, 0, 0x03a, 0x166, 0x036, 0x1e8, 0x011, 0x029] {
        tft_write(d, 100);
    }
    delay(after_wait);
}

/// Program CASET and PASET, then begin a contiguous GRAM write.
unsafe fn window(x: u32, y: u32, end_x: u32, end_y: u32) -> Result<(), i32> {
    for d in [
        0x2a,
        0x100 | (x >> 8),
        0x100 | (x & 255),
        0x100 | (end_x >> 8),
        0x100 | (end_x & 255),
        0x2b,
        0x100 | (y >> 8),
        0x100 | (y & 255),
        0x100 | (end_y >> 8),
        0x100 | (end_y & 255),
        0x2c,
    ] {
        tft_write_checked(d, 100)?;
    }
    Ok(())
}

/// Select the original 480 by 320 landscape drawing window.
pub unsafe fn tft_wire_pix_setting(x: u32, y: u32) {
    let _ = window(x, y, x + 479, y + 319);
}

/// Define the full native 480-row panel as the hardware scrolling area.
unsafe fn scroll_init() {
    for d in [0x33, 0x100, 0x100, 0x101, 0x1e0, 0x100, 0x100] {
        tft_write(d, 100);
    }
}

/// Wrap the scroll origin into the native GRAM row range.
unsafe fn set_scroll(v: u32) {
    let v = v % 480;
    tft_write(0x37, 100);
    tft_write(0x100 | (v >> 8), 100);
    tft_write(0x100 | (v & 255), 100);
}

/// Invert each component for the verified IPS panel, then emit RGB bytes in order.
unsafe fn rgb(r: u8, g: u8, b: u8) {
    for c in [r, g, b] {
        tft_write(0x100 | (255 - c) as u32, 10);
    }
}

/// Decode RGB111 runs while streaming pixels; no framebuffer is allocated.
pub unsafe fn lcd_draw_boot_logo() {
    tft_init_seq(50000);
    scroll_init();
    tft_wire_pix_setting(0, 0);
    for (n, c) in crate::boot::boot_logo::runs() {
        for _ in 0..n {
            rgb(
                if c & 1 != 0 { 255 } else { 0 },
                if c & 2 != 0 { 255 } else { 0 },
                if c & 4 != 0 { 255 } else { 0 },
            );
        }
    }
}

/// Restore landscape orientation and clear text scrolling state before JPEG output.
pub unsafe fn lcd_begin_rgb888() -> Result<(), i32> {
    for d in [
        0x3a, 0x166, 0x36, 0x1e8, 0x33, 0x100, 0x100, 0x101, 0x1e0, 0x100, 0x100, 0x37, 0x100,
        0x100,
    ] {
        tft_write_checked(d, 100)?;
    }
    SCROLL = 0;
    X = 0;
    Y = 0;
    Ok(())
}

/// Validate a small RGB888 tile and wait for the final transmitted byte.
pub unsafe fn lcd_write_rgb888_rect(
    x: u32,
    y: u32,
    w: u32,
    h: u32,
    data: &[u8],
) -> Result<(), i32> {
    if w == 0
        || h == 0
        || x >= 480
        || y >= 320
        || w > 480 - x
        || h > 320 - y
        || w > 16
        || h > 16
        || data.len() < (w * h * 3) as usize
    {
        return Err(-1);
    }
    window(x, y, x + w - 1, y + h - 1)?;
    for &c in &data[..(w * h * 3) as usize] {
        tft_write_checked(0x100 | (255 - c) as u32, 10)?;
    }
    idle()
}

/// Translate visible Y through the scrolling ring before drawing a 12 by 12 glyph.
pub unsafe fn lcd_draw_char(x: u32, y: u32, ch: u8) {
    if x > 308 || y > 468 {
        return;
    }
    let draw_y = (y + 480 - SCROLL) % 480;
    let _ = window(x, draw_y, x + 11, draw_y + 11);
    for py in 0..12 {
        let bits = super::font::row(ch, py);
        for px in 0..12 {
            let c = if bits & (0x800 >> px) != 0 { 255 } else { 0 };
            rgb(c, c, c);
        }
    }
}

/// Set the logical text cursor; clipping remains the draw operation responsibility.
pub unsafe fn lcd_set_cursor(x: u32, y: u32) {
    X = x;
    Y = y;
}

/// Return the logical horizontal text cursor in pixels.
pub unsafe fn lcd_get_cursor_x() -> u32 {
    X
}

/// Return the logical vertical text cursor in pixels.
pub unsafe fn lcd_get_cursor_y() -> u32 {
    Y
}

/// Clear the recycled physical GRAM row using the same mapping as glyph drawing.
unsafe fn clear_text_line(y: u32) {
    let y = (y + 480 - SCROLL) % 480;
    let _ = window(0, y, 319, y + 11);
    for _ in 0..12 * 320 {
        rgb(0, 0, 0);
    }
}

/// Advance one text row; at the bottom, scroll upward and clear the newly exposed row.
unsafe fn line_feed() {
    X = 0;
    Y += 12;
    if Y + 12 > 480 {
        SCROLL = if SCROLL >= 12 { SCROLL - 12 } else { 468 };
        set_scroll(SCROLL);
        Y = 468;
        clear_text_line(Y);
    }
}

/// Handle line endings, four-character tabs, and automatic right-edge wrapping.
pub unsafe fn lcd_putc(ch: u8) {
    match ch {
        b'\n' => line_feed(),
        b'\r' => X = 0,
        b'\t' => {
            X = (X / 48 + 1) * 48;
            if X + 12 > 320 {
                line_feed();
            }
        }
        _ => {
            lcd_draw_char(X, Y, ch);
            X += 12;
            if X + 12 > 320 {
                line_feed();
            }
        }
    }
}

/// Send each string byte through the text cursor and scrolling logic.
pub unsafe fn lcd_puts(s: &str) {
    for c in s.bytes() {
        lcd_putc(c);
    }
}

/// Reset the scroll origin, fill the portrait screen black, and home the cursor.
pub unsafe fn lcd_clear() {
    SCROLL = 0;
    set_scroll(0);
    let _ = window(0, 0, 319, 479);
    for _ in 0..320 * 480 {
        rgb(0, 0, 0);
    }
    X = 0;
    Y = 0;
}

/// Initialize the portrait console and render the original startup banner.
pub unsafe fn lcd_draw_text() {
    tft_init_seq(50000);
    tft_write(0x36, 100);
    tft_write(0x188, 100);
    scroll_init();
    set_scroll(0);
    lcd_clear();
    lcd_set_cursor(0, 0);
    lcd_puts("PSC-ONE\nPSC-OS\nRISC-V RV32ISP\n\nSYSTEM READY\n");
}

/// Use Rust formatting instead of a C variadic parser; write directly to the panel.
pub unsafe fn lcd_printf(args: core::fmt::Arguments<'_>) {
    use core::fmt::Write;
    struct Lcd;
    impl Write for Lcd {
        fn write_str(&mut self, s: &str) -> core::fmt::Result {
            unsafe {
                lcd_puts(s);
            }
            Ok(())
        }
    }
    let _ = Lcd.write_fmt(args);
}
