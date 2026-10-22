//! Corresponds to lib/common.c and common.h. Raw memory must be valid and
//! hardware access must be serialized by the kernel on this single-core SoC.
use core::fmt::{self, Write};
pub const PAGE_SIZE: usize = 4096;
pub const fn align_up(value: usize, align: usize) -> usize {
    value.wrapping_add(align - 1) & !(align - 1)
}

pub const fn is_aligned(value: usize, align: usize) -> bool {
    value & (align - 1) == 0
}

/// Issue exactly one volatile word store; peripheral side effects must not be optimized away.
pub unsafe fn mmio_w32(addr: u32, value: u32) {
    core::ptr::write_volatile(addr as *mut u32, value);
}

/// Issue exactly one volatile word load from an aligned, mapped peripheral register.
pub unsafe fn mmio_r32(addr: u32) -> u32 {
    core::ptr::read_volatile(addr as *const u32)
}

/// Burn polling iterations without allowing the compiler to remove the wait.
pub fn delay(n: u32) {
    for _ in 0..n {
        core::hint::spin_loop();
    }
}

/// Fill valid writable memory. The caller supplies the raw buffer lifetime and extent.
pub unsafe fn memset(buf: *mut u8, c: u8, n: usize) -> *mut u8 {
    core::ptr::write_bytes(buf, c, n);
    buf
}

/// Copy disjoint valid memory ranges; overlap is forbidden just as in C memcpy.
pub unsafe fn memcpy(dst: *mut u8, src: *const u8, n: usize) -> *mut u8 {
    core::ptr::copy_nonoverlapping(src, dst, n);
    dst
}

/// Return the first byte difference over the common prefix of the two slices.
pub fn memcmp(a: &[u8], b: &[u8]) -> i32 {
    for (&x, &y) in a.iter().zip(b) {
        if x != y {
            return x as i32 - y as i32;
        }
    }
    0
}
pub struct Console;
impl Write for Console {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        for b in s.bytes() {
            unsafe {
                putchar(b);
            }
        }
        Ok(())
    }
}

/// Wait for UART TX to become idle before submitting one byte.
pub unsafe fn putchar(b: u8) {
    #[cfg(all(feature = "user", target_arch = "riscv32"))]
    {
        crate::api::user::putchar(b);
        return;
    }
    #[cfg(not(all(feature = "user", target_arch = "riscv32")))]
    {
        while mmio_r32(0x10000008) & 1 != 0 {
            core::hint::spin_loop();
        }
        mmio_w32(0x10000000, b as u32);
    }
}

/// Format directly into the UART writer without a heap allocation.
pub fn print(args: fmt::Arguments<'_>) {
    let _ = Console.write_fmt(args);
}
#[macro_export]
macro_rules! s_print { ($($arg:tt)*) => { $crate::common::print(core::format_args!($($arg)*)) }; }
/// Print 16 bytes per row and label each row with its original address.
pub fn hexdump(data: &[u8], base: usize) {
    for (i, row) in data.chunks(16).enumerate() {
        crate::s_print!("{:08x}: ", base + i * 16);
        for b in row {
            crate::s_print!("{:02x} ", b);
        }
        crate::s_print!("\n");
    }
}
