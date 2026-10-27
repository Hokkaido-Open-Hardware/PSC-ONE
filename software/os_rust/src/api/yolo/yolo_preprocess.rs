//! 17 RGB rows, rational half-pixel bilinear resize, centered RGB=114 letterbox.
use super::*;
use crate::api::jpeg::RgbSink;
#[derive(Clone, Copy)]
struct Axis {
    lo: u16,
    hi: u16,
    fraction: u16,
}
impl Axis {
    const ZERO: Self = Self {
        lo: 0,
        hi: 0,
        fraction: 0,
    };
}
pub struct Workspace {
    rows: [[u8; 480 * 3]; 17],
    xs: [Axis; SIDE],
    ys: [Axis; SIDE],
}
impl Workspace {
    pub const fn new() -> Self {
        Self {
            rows: [[0; 480 * 3]; 17],
            xs: [Axis::ZERO; SIDE],
            ys: [Axis::ZERO; SIDE],
        }
    }
    pub fn stream<'a>(&'a mut self, input: &'a mut [u8]) -> Preprocessor<'a> {
        Preprocessor {
            work: self,
            input,
            geometry: Geometry::ZERO,
            next_x: 0,
            band_y: 0,
            band_height: 0,
            output_y: 0,
            active: false,
        }
    }
}
impl Default for Workspace {
    fn default() -> Self {
        Self::new()
    }
}
pub struct Preprocessor<'a> {
    work: &'a mut Workspace,
    input: &'a mut [u8],
    geometry: Geometry,
    next_x: u32,
    band_y: u32,
    band_height: u32,
    output_y: usize,
    active: bool,
}
fn round_even(n: u32, d: u32) -> u32 {
    let (q, r) = (n / d, n % d);
    q + (2 * r > d || (2 * r == d && q & 1 != 0)) as u32
}
fn axis(table: &mut [Axis; SIDE], source: u32, dest: u32) {
    let den = 2 * dest;
    for d in 0..dest {
        let n = (((2 * d + 1) * source) as i32 - dest as i32).clamp(0, ((source - 1) * den) as i32)
            as u32;
        let lo = n / den;
        table[d as usize] = Axis {
            lo: lo as u16,
            hi: (lo + 1).min(source - 1) as u16,
            fraction: (n % den) as u16,
        };
    }
}
impl RgbSink for Preprocessor<'_> {
    fn begin(&mut self, width: u32, height: u32) -> Result<(), i32> {
        self.active = false;
        if self.input.len() != INPUT_BYTES
            || width == 0
            || width > 480
            || height == 0
            || height > 320
        {
            return Err(ARGUMENT);
        }
        let longest = width.max(height);
        let nw = round_even(width * SIDE as u32, longest).max(1);
        let nh = round_even(height * SIDE as u32, longest).max(1);
        self.geometry = Geometry {
            width,
            height,
            resized_width: nw,
            resized_height: nh,
            left: (SIDE as u32 - nw) / 2,
            top: (SIDE as u32 - nh) / 2,
            scale: SIDE as f32 / longest as f32,
        };
        axis(&mut self.work.xs, width, nw);
        axis(&mut self.work.ys, height, nh);
        self.next_x = 0;
        self.band_y = 0;
        self.band_height = 0;
        self.output_y = 0;
        for v in self.input.chunks_exact_mut(4) {
            v.copy_from_slice(&(114.0f32 / 255.0).to_le_bytes());
        }
        self.active = true;
        Ok(())
    }
    fn rect(&mut self, x: u32, y: u32, width: u32, height: u32, rgb: &[u8]) -> Result<(), i32> {
        let g = self.geometry;
        if !self.active
            || width == 0
            || width > 16
            || height == 0
            || height > 16
            || x != self.next_x
            || y != self.band_y
            || x >= g.width
            || y >= g.height
            || width > g.width - x
            || height > g.height - y
            || (x != 0 && height != self.band_height)
            || rgb.len() != (width * height * 3) as usize
        {
            self.active = false;
            return Err(PREPROCESS);
        }
        if x == 0 {
            self.band_height = height;
        }
        for row in 0..height as usize {
            self.work.rows[(y as usize + row) % 17][x as usize * 3..(x + width) as usize * 3]
                .copy_from_slice(&rgb[row * width as usize * 3..(row + 1) * width as usize * 3]);
        }
        self.next_x += width;
        if self.next_x == g.width {
            self.emit_rows(y + height - 1);
            self.band_y += height;
            self.next_x = 0;
        }
        Ok(())
    }
}
impl Preprocessor<'_> {
    fn emit_rows(&mut self, available: u32) {
        let g = self.geometry;
        let dx = 2 * g.resized_width;
        let dy = 2 * g.resized_height;
        let den = dx * dy;
        while self.output_y < g.resized_height as usize
            && self.work.ys[self.output_y].hi as u32 <= available
        {
            let ay = self.work.ys[self.output_y];
            let a = &self.work.rows[ay.lo as usize % 17];
            let b = &self.work.rows[ay.hi as usize % 17];
            for x in 0..g.resized_width as usize {
                let ax = self.work.xs[x];
                for c in 0..3 {
                    let h0 = a[ax.lo as usize * 3 + c] as u32 * (dx - ax.fraction as u32)
                        + a[ax.hi as usize * 3 + c] as u32 * ax.fraction as u32;
                    let h1 = b[ax.lo as usize * 3 + c] as u32 * (dx - ax.fraction as u32)
                        + b[ax.hi as usize * 3 + c] as u32 * ax.fraction as u32;
                    let pixel =
                        (h0 * (dy - ay.fraction as u32) + h1 * ay.fraction as u32 + den / 2) / den;
                    let offset = 4
                        * (c * SIDE * SIDE
                            + (self.output_y + g.top as usize) * SIDE
                            + x
                            + g.left as usize);
                    self.input[offset..offset + 4]
                        .copy_from_slice(&(pixel as f32 / 255.0).to_le_bytes());
                }
            }
            self.output_y += 1;
        }
    }
    pub fn finish(mut self) -> Result<Geometry, i32> {
        let ok = self.active
            && self.next_x == 0
            && self.band_y == self.geometry.height
            && self.output_y == self.geometry.resized_height as usize;
        self.active = false;
        if ok {
            Ok(self.geometry)
        } else {
            Err(PREPROCESS)
        }
    }
}
