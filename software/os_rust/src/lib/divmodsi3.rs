//! lib/divmodsi3.c; preserves the PSC software builtins' zero-divisor result.
/// Perform restoring binary division from the most significant bit to the least.
pub fn udivmod32(n: u32, d: u32) -> (u32, u32) {
    if d == 0 {
        return (0, 0);
    }
    let (mut q, mut r) = (0, 0u32);
    for i in (0..32).rev() {
        r = (r << 1) | ((n >> i) & 1);
        if r >= d {
            r -= d;
            q |= 1 << i;
        }
    }
    (q, r)
}

/// Return the unsigned quotient; PSC software builtins define division by zero as zero.
pub fn udivsi3(a: u32, b: u32) -> u32 {
    udivmod32(a, b).0
}

/// Return the remainder from the same division pass used for the quotient.
pub fn umodsi3(a: u32, b: u32) -> u32 {
    udivmod32(a, b).1
}

/// Divide unsigned magnitudes, then restore the sign without overflowing on INT_MIN.
pub fn divsi3(a: i32, b: i32) -> i32 {
    let q = udivsi3(a.unsigned_abs(), b.unsigned_abs()) as i32;
    if (a ^ b) < 0 {
        q.wrapping_neg()
    } else {
        q
    }
}

/// The signed remainder follows the dividend sign, matching the C implementation.
pub fn modsi3(a: i32, b: i32) -> i32 {
    let r = umodsi3(a.unsigned_abs(), b.unsigned_abs()) as i32;
    if a < 0 {
        r.wrapping_neg()
    } else {
        r
    }
}
