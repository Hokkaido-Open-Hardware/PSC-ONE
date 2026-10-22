//! api/synap_api.c/.h. Rectangular INT8 SynapEngine driver.
use core::arch::asm;
pub const SA_MAT_MAX: usize = 64;
static mut ACTIVE: bool = false;
/// Validate M/K/N and retain exclusive ownership until results are copied or a timeout resets the engine.
pub unsafe fn sa_run_rect_checked(
    a: &[u8],
    b: &[u8],
    m: usize,
    k: usize,
    n: usize,
    c: &mut [u32],
    signed: bool,
) -> Result<(), i32> {
    if m == 0
        || k == 0
        || n == 0
        || m > 64
        || k > 64
        || n > 64
        || k & 3 != 0
        || n & 3 != 0
        || a.len() < m * k
        || b.len() < k * n
        || c.len() < m * n
    {
        return Err(-1);
    }
    if ACTIVE {
        return Err(-3);
    }
    ACTIVE = true;
    let config = 16 | if signed { 8 } else { 0 };
    let size = ((m << 16) | (n << 8) | k) as u32;
    asm!("csrw 0x7d0, {a}","csrw 0x7d4, {b}","csrw 0x7d8, {c}","csrw 0x7c4, {size}","fence rw, rw",a=in(reg) a.as_ptr(),b=in(reg) b.as_ptr(),c=in(reg) 0x30000u32,size=in(reg) size);
    for value in [config | 2, config, config | 4, config, config | 1] {
        asm!("csrw 0x7c0, {}",in(reg) value);
    }
    let mut timeout = 10000000;
    loop {
        let status: u32;
        asm!("csrr {}, 0x7c8",out(reg) status);
        if status & 1 != 0 {
            break;
        }
        timeout -= 1;
        if timeout == 0 {
            asm!("csrw 0x7c0, {reset}","csrw 0x7c0, {config}","fence rw, rw",reset=in(reg) config|2,config=in(reg) config);
            ACTIVE = false;
            return Err(-2);
        }
        asm!("nop");
    }
    asm!("csrw 0x7c0, {}","fence rw, rw",in(reg) config);
    for (i, out) in c[..m * n].iter_mut().enumerate() {
        *out = core::ptr::read_volatile((0x30000 as *const u32).add(i));
    }
    ACTIVE = false;
    Ok(())
}

/// Adapt the legacy square-matrix interface to the rectangular hardware command.
pub unsafe fn sa_run_checked(
    a: &[u8],
    b: &[u8],
    n: usize,
    c: &mut [u32],
    signed: bool,
) -> Result<(), i32> {
    sa_run_rect_checked(a, b, n, n, n, c, signed)
}

/// Keep the original fire-and-report interface; use the checked form to handle errors.
pub unsafe fn sa_run(a: &[u8], b: &[u8], n: usize, c: &mut [u32], signed: bool) {
    let _ = sa_run_checked(a, b, n, c, signed);
}

/// Generate deterministic operands and optionally compare every hardware result with a CPU dot product.
pub unsafe fn s_call_sa_api(n: usize, verify: bool, signed: bool) {
    #[repr(align(4))]
    struct Bytes([u8; 4096]);
    static mut A: Bytes = Bytes([0; 4096]);
    static mut B: Bytes = Bytes([0; 4096]);
    static mut C: [u32; 4096] = [0; 4096];
    if n == 0 || n > 64 || n & 3 != 0 {
        crate::s_print!("SA invalid matrix size: {}\n", n);
        return;
    }
    let a = &mut *core::ptr::addr_of_mut!(A.0);
    let b = &mut *core::ptr::addr_of_mut!(B.0);
    let c = &mut *core::ptr::addr_of_mut!(C);
    let mut rng = 143253719u32;
    for i in 0..n * n {
        for dst in [&mut a[i], &mut b[i]] {
            rng ^= rng << 13;
            rng ^= rng >> 17;
            rng ^= rng << 5;
            *dst = (rng & if signed { 255 } else { 15 }) as u8;
        }
        c[i] = 0;
    }
    if let Err(e) = sa_run_checked(a, b, n, c, signed) {
        crate::s_print!("SA ERROR {}\n", e);
        return;
    }
    let mut errors = 0;
    for i in 0..n {
        for j in 0..n {
            let mut sum = 0i32;
            if verify {
                for k in 0..n {
                    let x = if signed {
                        a[i * n + k] as i8 as i32
                    } else {
                        a[i * n + k] as i32
                    };
                    let y = if signed {
                        b[k * n + j] as i8 as i32
                    } else {
                        b[k * n + j] as i32
                    };
                    sum = sum.wrapping_add(x * y);
                }
            }
            crate::s_print!("[{}][{}] SA={} CPU={}\n", i, j, c[i * n + j] as i32, sum);
            if verify && c[i * n + j] != sum as u32 {
                errors += 1;
            }
        }
    }
    if verify {
        crate::s_print!("SA VERIFY errors={}\n", errors);
    }
}
