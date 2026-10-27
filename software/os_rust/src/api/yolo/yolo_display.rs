//! Bounded RGB888 overlay, corresponding to yolo_display.c; no framebuffer.
use super::{yolo_postprocess::class_name, *};
use crate::{
    api::jpeg::{jpeg_headers::LCD, RgbSink},
    drivers::font,
};
const HEIGHT: u32 = 14;
const BACKGROUND: [u8; 3] = [16, 16, 16];
pub trait Lcd {
    fn begin(&mut self) -> Result<(), i32>;
    fn rect(&mut self, x: u32, y: u32, w: u32, h: u32, rgb: &[u8]) -> Result<(), i32>;
}
pub struct Renderer {
    tile: [u8; 16 * 16 * 3],
}
impl Renderer {
    pub const fn new() -> Self {
        Self {
            tile: [0; 16 * 16 * 3],
        }
    }
    fn tile(&self, lcd: &mut impl Lcd, x: u32, y: u32, w: u32, h: u32) -> Result<(), i32> {
        lcd.rect(x, y, w, h, &self.tile[..(w * h * 3) as usize])
            .map_err(|_| LCD)
    }
    fn fill(
        &mut self,
        lcd: &mut impl Lcd,
        x: u32,
        y: u32,
        w: u32,
        h: u32,
        color: [u8; 3],
    ) -> Result<(), i32> {
        if x >= 480 || y >= 320 {
            return Ok(());
        }
        let w = w.min(480 - x);
        let h = h.min(320 - y);
        for p in self.tile.chunks_exact_mut(3) {
            p.copy_from_slice(&color);
        }
        for row in (0..h).step_by(16) {
            for col in (0..w).step_by(16) {
                self.tile(lcd, x + col, y + row, 16.min(w - col), 16.min(h - row))?;
            }
        }
        Ok(())
    }
    pub fn clear(&mut self, lcd: &mut impl Lcd) -> Result<(), i32> {
        lcd.begin().map_err(|_| LCD)?;
        self.fill(lcd, 0, 0, 480, 320, BACKGROUND)
    }
    pub fn label(
        &mut self,
        lcd: &mut impl Lcd,
        x: u32,
        y: u32,
        name: &str,
        score: f32,
    ) -> Result<(), i32> {
        if !score.is_finite() || !(0.0..=1.0).contains(&score) {
            return Err(ARGUMENT);
        }
        let mut label = [0u8; 39];
        let mut n = name.len().min(32);
        label[..n].copy_from_slice(&name.as_bytes()[..n]);
        if name.len() > 32 {
            label[n - 3..n].copy_from_slice(b"...");
        }
        let value = (score * 1000.0 + 0.5) as u32;
        label[n] = b' ';
        n += 1;
        if value >= 1000 {
            label[n] = b'1';
            n += 1;
        }
        if value >= 100 {
            label[n] = b'0' + ((value / 100) % 10) as u8;
            n += 1;
        }
        label[n] = b'0' + ((value / 10) % 10) as u8;
        n += 1;
        label[n] = b'.';
        label[n + 1] = b'0' + (value % 10) as u8;
        label[n + 2] = b'%';
        n += 3;
        let width = n as u32 * font::FONT_WIDTH as u32 + 4;
        let x = x.min(480 - width);
        let y = y.min(320 - HEIGHT);
        self.fill(lcd, x, y, width, HEIGHT, BACKGROUND)?;
        for (i, &ch) in label[..n].iter().enumerate() {
            for row in 0..font::FONT_HEIGHT {
                for col in 0..font::FONT_WIDTH {
                    let color = if font::row(ch, row) & (1 << (11 - col)) != 0 {
                        [255; 3]
                    } else {
                        BACKGROUND
                    };
                    let at = (row * font::FONT_WIDTH + col) * 3;
                    self.tile[at..at + 3].copy_from_slice(&color);
                }
            }
            self.tile(lcd, x + 2 + i as u32 * 12, y + 1, 12, 12)?;
        }
        Ok(())
    }
    /// Validate before the JPEG/LCD is touched. Call overlays only after full EOI success.
    pub fn validate(r: &YoloResult) -> Result<(), i32> {
        let g = r.geometry;
        if g.width == 0
            || g.width > 480
            || g.height == 0
            || g.height > 320
            || r.count > MAX_DETECTIONS as u32
        {
            return Err(ARGUMENT);
        }
        for d in &r.detections[..r.count as usize] {
            if ![d.x1, d.y1, d.x2, d.y2, d.score]
                .iter()
                .all(|v| v.is_finite())
                || !(0.0..=1.0).contains(&d.score)
                || d.class_id >= CLASSES as u16
                || d.x2 <= d.x1
                || d.y2 <= d.y1
            {
                return Err(ARGUMENT);
            }
        }
        Ok(())
    }
    pub fn overlays(&mut self, lcd: &mut impl Lcd, r: &YoloResult) -> Result<(), i32> {
        Self::validate(r)?;
        for d in &r.detections[..r.count as usize] {
            let Some(p) = box_pixels(d, r.geometry) else {
                continue;
            };
            let w = p[2] - p[0] + 1;
            let h = p[3] - p[1] + 1;
            let bw = 2.min(w);
            let bh = 2.min(h);
            let color = [255, 224, 0];
            self.fill(lcd, p[0], p[1], w, bh, color)?;
            self.fill(lcd, p[0], p[3] + 1 - bh, w, bh, color)?;
            self.fill(lcd, p[0], p[1], bw, h, color)?;
            self.fill(lcd, p[2] + 1 - bw, p[1], bw, h, color)?;
        }
        for d in &r.detections[..r.count as usize] {
            let Some(p) = box_pixels(d, r.geometry) else {
                continue;
            };
            let y = if p[1] >= HEIGHT {
                p[1] - HEIGHT
            } else {
                p[1] + 2
            };
            self.label(lcd, p[0], y, class_name(d.class_id as usize), d.score)?;
        }
        Ok(())
    }
}
impl Default for Renderer {
    fn default() -> Self {
        Self::new()
    }
}
fn box_pixels(d: &Detection, g: Geometry) -> Option<[u32; 4]> {
    let v = [
        d.x1.clamp(0.0, g.width as f32),
        d.y1.clamp(0.0, g.height as f32),
        d.x2.clamp(0.0, g.width as f32),
        d.y2.clamp(0.0, g.height as f32),
    ];
    if v[2] <= v[0] || v[3] <= v[1] {
        return None;
    }
    let mut p = [0; 4];
    for i in 0..4 {
        let q = v[i] as u32;
        p[i] = if i < 2 {
            q
        } else {
            q + (v[i] > q as f32) as u32 - 1
        };
    }
    Some(p)
}
pub struct ImageSink<'a, L: Lcd> {
    pub lcd: &'a mut L,
    pub geometry: Geometry,
}
impl<L: Lcd> RgbSink for ImageSink<'_, L> {
    fn begin(&mut self, w: u32, h: u32) -> Result<(), i32> {
        if w != self.geometry.width || h != self.geometry.height {
            return Err(ARGUMENT);
        }
        self.lcd.begin().map_err(|_| LCD)
    }
    fn rect(&mut self, x: u32, y: u32, w: u32, h: u32, rgb: &[u8]) -> Result<(), i32> {
        self.lcd.rect(x, y, w, h, rgb).map_err(|_| LCD)
    }
}
#[cfg(target_arch = "riscv32")]
pub struct PlatformLcd;
#[cfg(target_arch = "riscv32")]
impl Lcd for PlatformLcd {
    fn begin(&mut self) -> Result<(), i32> {
        if crate::api::user::call_lcd_rgb888_begin() == 0 {
            Ok(())
        } else {
            Err(LCD)
        }
    }
    fn rect(&mut self, x: u32, y: u32, w: u32, h: u32, rgb: &[u8]) -> Result<(), i32> {
        if crate::api::user::call_lcd_rgb888_rect(x, y, w, h, rgb) == 0 {
            Ok(())
        } else {
            Err(LCD)
        }
    }
}
