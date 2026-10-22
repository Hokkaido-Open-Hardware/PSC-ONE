//! tflite_synap.cc: pack FC weights into rectangular SynapEngine tiles.
use super::tflite_runtime::Profile;
use crate::api::sa_transfer;
/// Platform operations are explicit so host tests can model device failures.
pub trait Device {
    fn tile(
        &mut self,
        a: &[i8],
        b: &[i8],
        c: &mut [i32],
        m: usize,
        k: usize,
        n: usize,
        profile: Option<&mut sa_transfer::Profile>,
    ) -> i32;
    fn clock_us(&mut self) -> i32;
}
pub struct Scratch {
    a: [i8; 4096],
    b: [i8; 4096],
    c: [i32; 4096],
}
impl Default for Scratch {
    fn default() -> Self {
        Self {
            a: [0; 4096],
            b: [0; 4096],
            c: [0; 4096],
        }
    }
}

fn elapsed(profile: &mut Profile, start: i32, end: i32) -> u32 {
    if start < 0 || end < start {
        profile.valid = false;
        0
    } else {
        (end - start) as u32
    }
}
impl Scratch {
    /// Zero-pad K/N tails, transpose row-major weights, and accumulate partial dots.
    pub fn batch(
        &mut self,
        device: &mut impl Device,
        x: &[i8],
        w: &[i8],
        m: usize,
        k: usize,
        n: usize,
        tile: usize,
        dots: &mut [i32],
        mut profile: Option<&mut Profile>,
    ) -> Result<(), i32> {
        if k == 0
            || k > 8192
            || m == 0
            || m > tile
            || n == 0
            || n > tile
            || tile < 4
            || tile > 64
            || tile % 4 != 0
            || x.len() < m * k
            || w.len() < n * k
            || dots.len() < m * n
        {
            return Err(-203);
        }
        dots[..m * n].fill(0);
        for base in (0..k).step_by(tile) {
            let t0 = if profile.is_some() {
                device.clock_us()
            } else {
                -1
            };
            let count = (k - base).min(tile);
            self.a[..m * tile].fill(0);
            self.b[..tile * tile].fill(0);
            for row in 0..m {
                self.a[row * tile..row * tile + count]
                    .copy_from_slice(&x[row * k + base..row * k + base + count]);
            }
            for row in 0..count {
                for col in 0..n {
                    self.b[row * tile + col] = w[col * k + base + row];
                }
            }
            let t1 = if profile.is_some() {
                device.clock_us()
            } else {
                -1
            };
            let mut device_profile = sa_transfer::Profile::default();
            let rc = device.tile(
                &self.a,
                &self.b,
                &mut self.c,
                m,
                tile,
                tile,
                if profile.is_some() {
                    Some(&mut device_profile)
                } else {
                    None
                },
            );
            let t2 = if profile.is_some() {
                device.clock_us()
            } else {
                -1
            };
            if let Some(p) = profile.as_deref_mut() {
                p.tiles += 1;
                p.device_status = rc;
                p.packing_us += elapsed(p, t0, t1);
                p.syscall_us += elapsed(p, t1, t2);
                if device_profile.valid == 0 {
                    p.valid = false;
                } else {
                    p.copy_in_us += device_profile.copy_in_us;
                    p.execute_us += device_profile.execute_us;
                    p.copy_out_us += device_profile.copy_out_us;
                }
            }
            // Failed hardware calls must never consume stale output or silently use CPU fallback.
            if rc != 0 {
                return Err(match rc {
                    -1 => -208,
                    -2 => -207,
                    -3 => -209,
                    _ => -206,
                });
            }
            for row in 0..m {
                for col in 0..n {
                    dots[row * n + col] =
                        dots[row * n + col].wrapping_add(self.c[row * tile + col]);
                }
            }
            if let Some(p) = profile.as_deref_mut() {
                p.partial_us += elapsed(p, t2, device.clock_us());
            }
        }
        Ok(())
    }
}
