//! Manual equivalent of tflite_quant.cc's double-rounding INT8 helpers.
/// Encode a positive real scale as Q31 multiplier times a power of two.
pub fn quantize(mut scale: f64) -> Result<(i32, i32), i32> {
    if !scale.is_finite() || scale <= 0.0 {
        return Err(-203);
    }
    let mut shift = 0;
    while scale < 0.5 {
        scale *= 2.0;
        shift -= 1;
    }
    while scale >= 1.0 {
        scale *= 0.5;
        shift += 1;
    }
    let mut multiplier = (scale * 2147483648.0 + 0.5) as i64;
    if multiplier == 2147483648 {
        multiplier /= 2;
        shift += 1;
    }
    if shift < -31 {
        multiplier = 0;
        shift = 0;
    }
    if shift > 30 {
        return Err(-202);
    }
    Ok((multiplier as i32, shift))
}

/// Match gemmlowp's saturating high multiply followed by rounding division.
pub fn requantize(x: i32, multiplier: i32, shift: i32) -> i32 {
    let left = shift.max(0) as u32;
    let right = (-shift).max(0) as u32;
    let a = x.wrapping_mul(1i32 << left);
    let high = if a == i32::MIN && multiplier == i32::MIN {
        i32::MAX
    } else {
        let product = a as i64 * multiplier as i64;
        let nudge = if product >= 0 {
            1i64 << 30
        } else {
            1 - (1i64 << 30)
        };
        ((product + nudge) / (1i64 << 31)) as i32
    };
    let mask = ((1u32 << right) - 1) as i32;
    let remainder = high & mask;
    let threshold = (mask >> 1) + i32::from(high < 0);
    (high >> right) + i32::from(remainder > threshold)
}

// Fixed-point transcendental routines below are independently translated from
// gemmlowp/fixedpoint/fixedpoint.h; modified for Rust scalar i32 arithmetic.
// Copyright 2015 The Gemmlowp Authors. All Rights Reserved.
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// Round halfway away from zero without a hosted floating-point library.
pub fn round(x: f64) -> f64 {
    if x.abs() >= 4503599627370496.0 {
        x
    } else {
        (if x < 0.0 {
            (x - 0.5) as i64
        } else {
            (x + 0.5) as i64
        }) as f64
    }
}
fn high(a: i32, b: i32) -> i32 {
    requantize(a, b, 0)
}
pub fn divide_pot(x: i32, n: u32) -> i32 {
    if n == 0 {
        return x;
    }
    let mask = ((1u64 << n) - 1) as i64;
    let rem = x as i64 & mask;
    let threshold = (mask >> 1) + i64::from(x < 0);
    ((x as i64 >> n) + i64::from(rem > threshold)) as i32
}
fn sat_shift(x: i32, n: u32) -> i32 {
    ((x as i64) << n).clamp(i32::MIN as i64, i32::MAX as i64) as i32
}
/// Q0 fixed-point exp for nonpositive Q(integer_bits) input. Constants and
/// rounding follow gemmlowp's polynomial and barrel decomposition.
fn exp_negative(a: i32, bits: u32) -> i32 {
    if a == 0 {
        return i32::MAX;
    }
    let quarter = 1i32 << (29 - bits);
    let reduced = (a & (quarter - 1)) - quarter;
    let x = (reduced << bits) + (1 << 28);
    let x2 = high(x, x);
    let x3 = high(x2, x);
    let x4 = high(x2, x2);
    let tail = divide_pot(
        high(divide_pot(x4, 2).wrapping_add(x3), 715827883).wrapping_add(x2),
        1,
    );
    let mut result = 1895147668i32.wrapping_add(high(1895147668, x.wrapping_add(tail)));
    let remainder = reduced.wrapping_sub(a);
    for (e, c) in [
        (-2, 1672461947),
        (-1, 1302514674),
        (0, 790015084),
        (1, 290630308),
        (2, 39332535),
        (3, 720401),
        (4, 242),
    ] {
        if (bits as i32) > e && remainder & (1i32 << (31 - bits as i32 + e)) != 0 {
            result = high(result, c);
        }
    }
    result
}
fn reciprocal_one_plus(a: i32) -> i32 {
    let half = ((a as i64 + i32::MAX as i64 + 1) / 2) as i32;
    let mut x = 1515870810i32.wrapping_add(high(half, -1010580540));
    for _ in 0..3 {
        let error = (1i32 << 29).wrapping_sub(high(half, x));
        x = x.wrapping_add(sat_shift(high(x, error), 2));
    }
    sat_shift(x, 1)
}
pub fn logistic_params(scale: f64, zero: i32) -> Result<(i32, i32, i32), i32> {
    let (m, s) = quantize(scale * 134217728.0)?;
    if s < 0 || s > 30 || !(-128..=127).contains(&zero) {
        return Err(-202);
    }
    Ok((m, s, ((15i64 << 27) / (1i64 << s)) as i32))
}
pub fn logistic_lut(scale: f64, zero: i32) -> Result<[i8; 256], i32> {
    let (m, s, radius) = logistic_params(scale, zero)?;
    let mut lut = [0; 256];
    for v in -128..=127 {
        let x = v - zero;
        let y = if x <= -radius {
            -128
        } else if x >= radius {
            127
        } else {
            let raw = requantize(x, m, s);
            let positive = reciprocal_one_plus(exp_negative(-raw.abs(), 4));
            let sigmoid = if raw == 0 {
                1 << 30
            } else if raw > 0 {
                positive
            } else {
                i32::MAX - positive
            };
            divide_pot(sigmoid, 23) - 128
        };
        lut[(v + 128) as usize] = y.clamp(-128, 127) as i8;
    }
    Ok(lut)
}
pub fn softmax_params(beta: f64, scale: f64) -> Result<(i32, i32, i32), i32> {
    if !beta.is_finite() || beta <= 0.0 || !scale.is_finite() || scale <= 0.0 {
        return Err(-203);
    }
    let real = beta * scale * 67108864.0;
    if real < 1.0 {
        return Err(-202);
    }
    let (m, s) = quantize(real.min(2147483647.0))?;
    if s < 0 || s > 30 {
        return Err(-202);
    }
    Ok((m, s, ((31i64 << 26) / (1i64 << s)) as i32))
}
pub fn softmax_lut(beta: f64, scale: f64) -> Result<[i32; 256], i32> {
    let (m, s, radius) = softmax_params(beta, scale)?;
    let mut lut = [0; 256];
    for d in 0..256 {
        lut[d] = if d as i32 > radius {
            0
        } else {
            exp_negative(requantize(-(d as i32), m, s), 5)
        };
    }
    Ok(lut)
}
pub fn softmax_scale(sum: i32) -> (i32, u32) {
    let leading = (sum as u32).leading_zeros();
    let normalized = ((sum as u32) << leading).wrapping_sub(1 << 31) as i32;
    (reciprocal_one_plus(normalized), 35 - leading)
}
pub fn softmax_output(exponent: i32, mult: i32, shift: u32) -> i8 {
    (divide_pot(high(exponent, mult), shift) - 128).clamp(-128, 127) as i8
}
