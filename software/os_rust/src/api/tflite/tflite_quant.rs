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
