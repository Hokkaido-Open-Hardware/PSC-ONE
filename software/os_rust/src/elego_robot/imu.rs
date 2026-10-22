//! elego_robot/imu.c/.h: passive MPU6050 decoding and the Tumbller angle filter.
#[derive(Default, Debug, Clone, Copy)]
pub struct Sample {
    pub ax: i16,
    pub ay: i16,
    pub az: i16,
    pub temperature: i16,
    pub gx: i16,
    pub gy: i16,
    pub gz: i16,
    pub address: u32,
    pub repeated_start: bool,
}
#[derive(Default, Debug, Clone, Copy)]
pub struct Filter {
    pub angle: f32,
    pub q_bias: f32,
    pub p00: f32,
    pub p01: f32,
    pub p10: f32,
    pub p11: f32,
}
#[derive(Default)]
pub struct Tracker {
    pub filter: Filter,
    pub previous_us: u32,
    pub initialized: bool,
}

/// Decode only a complete STOP-delimited transaction within one frozen capture.
pub fn imu_decode(events: &[u32], cursor: &mut usize) -> Option<Sample> {
    if events.len() > 64 {
        return None;
    }
    while *cursor < events.len() {
        let i = *cursor;
        *cursor += 1;
        if events.len() - i < 20 || events[i] != 0x200 {
            continue;
        }
        let address = events[i + 1];
        if !matches!(address, 0x8d0 | 0x8d2) || events[i + 2] != 0xa3b {
            continue;
        }
        let mut j = i + 3;
        let repeated = events[j] == 0x400;
        if repeated {
            j += 1;
        } else {
            if events[j] != 0x600 || events[j + 1] != 0x200 {
                continue;
            }
            j += 2;
        }
        if events.len() - j < 16 || events[j] != address | 1 {
            continue;
        }
        j += 1;
        let data = j;
        for k in 0..14 {
            if events[j] & !255 != if k == 13 { 0xb00 } else { 0xa00 } {
                break;
            }
            j += 1;
        }
        if j != data + 14 || events[j] != 0x600 {
            continue;
        }
        let word = |offset: usize| {
            i16::from_be_bytes([events[data + offset] as u8, events[data + offset + 1] as u8])
        };
        *cursor = j + 1;
        return Some(Sample {
            ax: word(0),
            ay: word(2),
            az: word(4),
            temperature: word(6),
            gx: word(8),
            gy: word(10),
            gz: word(12),
            address: (address & 255) >> 1,
            repeated_start: repeated,
        });
    }
    None
}

// Reduce to |z| <= tan(pi/8) before the alternating atan series.
// This keeps the software-only RV32 implementation accurate without libm.
/// Use reciprocal and pi/4 reductions to keep the atan series within a rapidly converging interval.
fn atan_positive(x: f64) -> f64 {
    if x > 1.0 {
        return core::f64::consts::FRAC_PI_2 - atan_positive(1.0 / x);
    }
    let (z, offset) = if x > 0.414213562373095 {
        ((x - 1.0) / (x + 1.0), core::f64::consts::FRAC_PI_4)
    } else {
        (x, 0.0)
    };
    let mut term = z;
    let mut sum = z;
    for n in 1..20 {
        term *= -z * z;
        sum += term / (2 * n + 1) as f64;
    }
    offset + sum
}

/// Reconstruct the angle quadrant after evaluating the positive reduced ratio.
fn atan2(y: f32, x: f32) -> f32 {
    if x == 0.0 {
        return if y > 0.0 {
            core::f32::consts::FRAC_PI_2
        } else if y < 0.0 {
            -core::f32::consts::FRAC_PI_2
        } else {
            0.0
        };
    }
    let mut angle = atan_positive((y as f64 / x as f64).abs());
    if x < 0.0 {
        angle = core::f64::consts::PI - angle;
    }
    if y < 0.0 {
        angle = -angle;
    }
    angle as f32
}

/// Apply the original accelerometer angle and calibrated gyroscope conversion.
fn measurements(s: &Sample) -> (f32, f32) {
    (
        atan2(s.ay as f32, s.az as f32) * 57.3,
        (s.gx as f32 - 128.1) / 131.0,
    )
}

/// Restore zero bias and identity covariance before a fresh estimate.
pub fn imu_reset(f: &mut Filter) {
    *f = Filter {
        p00: 1.0,
        p11: 1.0,
        ..Filter::default()
    };
}

/// Predict angle/covariance, then apply the accelerometer correction gain.
pub fn imu_update(f: &mut Filter, s: &Sample, dt: f32) -> (f32, f32) {
    let (acc, gyro) = measurements(s);
    f.angle += (gyro - f.q_bias) * dt;
    let error = acc - f.angle;
    // Covariance derivatives must use the old p11, before the process-noise update.
    let d00 = 0.001 - f.p01 - f.p10;
    let d01 = -f.p11;
    f.p00 += d00 * dt;
    f.p01 += d01 * dt;
    f.p10 += d01 * dt;
    f.p11 += 0.005 * dt;
    let k0 = f.p00 / (0.5 + f.p00);
    let k1 = f.p10 / (0.5 + f.p00);
    let (t0, t1) = (f.p00, f.p01);
    f.p00 -= k0 * t0;
    f.p01 -= k0 * t1;
    f.p10 -= k1 * t0;
    f.p11 -= k1 * t1;
    f.angle += k0 * error;
    f.q_bias += k1 * error;
    (acc, gyro)
}

/// Reject invalid angle inputs and avoid integrating across zero or excessively long time steps.
pub fn imu_track(t: &mut Tracker, s: &Sample, now: u32) -> (i32, f32, f32, f32) {
    if s.ay == 0 && s.az == 0 {
        return (-1, 0.0, 0.0, 0.0);
    }
    let (acc, gyro) = measurements(s);
    if !t.initialized {
        imu_reset(&mut t.filter);
        t.filter.angle = acc;
        t.previous_us = now;
        t.initialized = true;
        return (1, 0.0, acc, gyro);
    }
    // Receipt timestamps wrap modulo 2^32; long gaps rebase time without filtering.
    let elapsed = now.wrapping_sub(t.previous_us);
    let dt = elapsed as f32 / 1_000_000.0;
    if elapsed == 0 {
        return (0, dt, acc, gyro);
    }
    t.previous_us = now;
    if elapsed > 250_000 {
        return (0, dt, acc, gyro);
    }
    let (acc, gyro) = imu_update(&mut t.filter, s, dt);
    (1, dt, acc, gyro)
}

/// Compare one deterministic update against the original reference values.
pub fn imu_self_test() -> bool {
    let s = Sample {
        ay: 2845,
        az: 16135,
        gx: 1441,
        ..Sample::default()
    };
    let mut f = Filter::default();
    imu_reset(&mut f);
    let (acc, gyro) = imu_update(&mut f, &s, 0.005);
    let actual = [acc, gyro, f.angle, f.q_bias, f.p00, f.p01, f.p10, f.p11];
    let expected = [
        10.000613, 10.022137, 6.683790, -0.033168, 0.333334, -0.001667, -0.001667, 1.000008,
    ];
    actual
        .iter()
        .zip(expected)
        .all(|(a, b)| (*a - b).abs() < 0.0001)
}
