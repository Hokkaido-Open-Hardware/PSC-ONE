//! api/fft_api.c/.h; fixed-point arithmetic preserves RV32 low-word products.
#[derive(Default, Clone, Copy, Debug, PartialEq, Eq)]
#[repr(C)]
pub struct Complex {
    pub re: i32,
    pub im: i32,
}
const TWIDDLE: &[u8; 4096] = include_bytes!("../../assets/fft_twiddle.bin");
/// Retain the low product word, as the original RV32 MUL instruction does.
pub fn fft_mul(a: i32, b: i32) -> i32 {
    a.wrapping_mul(b)
}

/// Add real and imaginary components with explicit two-complement wrapping.
pub fn fft_add(a: Complex, b: Complex) -> Complex {
    Complex {
        re: a.re.wrapping_add(b.re),
        im: a.im.wrapping_add(b.im),
    }
}

/// Subtract components without debug-build overflow panics.
pub fn fft_sub(a: Complex, b: Complex) -> Complex {
    Complex {
        re: a.re.wrapping_sub(b.re),
        im: a.im.wrapping_sub(b.im),
    }
}

/// Form the complex product and restore the Q15 binary point after low-word arithmetic.
pub fn fft_mul_q15(a: Complex, b: Complex) -> Complex {
    Complex {
        re: fft_mul(a.re, b.re).wrapping_sub(fft_mul(a.im, b.im)) >> 15,
        im: fft_mul(a.re, b.im).wrapping_add(fft_mul(a.im, b.re)) >> 15,
    }
}

/// Read the original immutable twiddle table without relying on asset alignment.
fn twiddle(i: usize) -> Complex {
    let p = i * 8;
    Complex {
        re: i32::from_le_bytes(TWIDDLE[p..p + 4].try_into().unwrap()),
        im: i32::from_le_bytes(TWIDDLE[p + 4..p + 8].try_into().unwrap()),
    }
}

/// Perform in-place radix-2 butterflies after bit reversal; input length must be a power of two.
pub fn fft_q15(x: &mut [Complex]) -> Result<(), i32> {
    let n = x.len();
    if !n.is_power_of_two() || n > 1024 {
        return Err(-1);
    }
    let mut j = 0;
    for i in 1..n {
        let mut k = n >> 1;
        while j >= k {
            j -= k;
            k >>= 1;
        }
        j += k;
        if i < j {
            x.swap(i, j);
        }
    }
    let mut len = 2;
    while len <= n {
        let half = len / 2;
        let step = 1024 / len;
        for i in (0..n).step_by(len) {
            for j in 0..half {
                let u = x[i + j];
                let t = fft_mul_q15(x[i + j + half], twiddle(j * step));
                x[i + j] = fft_add(u, t);
                x[i + j + half] = fft_sub(u, t);
            }
        }
        len *= 2;
    }
    Ok(())
}
