//! api/user.c/.h: user-mode wrappers for the PSC a3 syscall ABI.
use crate::kernel::syscall::*;
use core::arch::asm;
/// a3 carries the service number; a0/a1 carry the result pair.
/// Pointer arguments must satisfy the selected service's buffer contract.
pub unsafe fn syscall(number: u32, args: [u32; 6]) -> (u32, u32) {
    let mut a0 = args[0];
    let mut a1 = args[1];
    asm!("ecall",inout("a0") a0,inout("a1") a1,in("a2") args[2],in("a3") number,in("a4") args[3],in("a5") args[4],in("a6") args[5]);
    (a0, a1)
}

pub fn call(number: u32, arg: u32) -> u32 {
    unsafe { syscall(number, [arg, 0, 0, 0, 0, 0]).0 }
}

pub fn putchar(ch: u8) {
    call(SYS_PUTCHAR, ch as u32);
}

pub fn getchar() -> i32 {
    call(SYS_GETCHAR, 0) as i32
}

pub fn getchar_timeout() -> i32 {
    call(SYS_GETCHAR_TIMEOUT, 0) as i32
}

pub fn print_int(value: i32) {
    call(SYS_PRINT_INT, value as u32);
}

pub fn exit() -> ! {
    call(SYS_EXIT, 0);
    loop {
        core::hint::spin_loop();
    }
}

pub fn print(args: core::fmt::Arguments<'_>) {
    use core::fmt::Write;
    struct Output;
    impl Write for Output {
        fn write_str(&mut self, s: &str) -> core::fmt::Result {
            for c in s.bytes() {
                putchar(c);
            }
            Ok(())
        }
    }
    let _ = Output.write_fmt(args);
}

pub fn call_i2c_capture(op: u32) -> u32 {
    call(SYS_I2C_CAPTURE, op)
}

pub fn call_robot_control() {
    call(SYS_ROBOT_CONTROL, 0);
}

pub fn poll_switch_api() -> u32 {
    call(SYS_SW_READ, 0)
}

pub fn call_timer_measure_begin() -> i32 {
    call(SYS_TIMER_MEASURE_BEGIN, 0) as i32
}

pub fn call_timer_measure_end() -> i32 {
    call(SYS_TIMER_MEASURE_END, 0) as i32
}

pub fn call_timer_measure_end_us() -> i32 {
    call(SYS_TIMER_MEASURE_END_US, 0) as i32
}

pub fn call_timer_measure_read_us() -> i32 {
    call(SYS_TIMER_MEASURE_READ_US, 0) as i32
}

pub fn call_speech_recognition_api() -> i32 {
    call(SYS_SPEECH_RECOGNITION, 0) as i32
}

pub fn call_mic_api(count: u32) {
    call(I2S_MIC_READ, count);
}

pub fn call_sd_read_api(sector: u32) {
    call(SYS_SD_READ, sector);
}

pub fn call_sd_write_test_api(sector: u32) {
    call(SYS_SD_WRITE_TEST, sector);
}

pub fn call_sd_read_buf_api(sector: u32, buf: &mut [u8; 512]) -> Result<(), i32> {
    let rc = unsafe {
        syscall(
            SYS_SD_READ_BUF,
            [sector, buf.as_mut_ptr() as u32, 0, 0, 0, 0],
        )
        .0 as i32
    };
    if rc == 0 {
        Ok(())
    } else {
        Err(rc)
    }
}

pub fn call_sd_write_buf_api(sector: u32, buf: &[u8; 512]) -> Result<(), i32> {
    let rc = unsafe { syscall(SYS_SD_WRITE, [sector, buf.as_ptr() as u32, 0, 0, 0, 0]).0 as i32 };
    if rc == 0 {
        Ok(())
    } else {
        Err(rc)
    }
}
pub struct UserSd;
impl crate::fs::fat32::BlockDevice for UserSd {
    fn read(&mut self, lba: u32, b: &mut [u8; 512]) -> Result<(), i32> {
        call_sd_read_buf_api(lba, b)
    }

    fn write(&mut self, lba: u32, b: &[u8; 512]) -> Result<(), i32> {
        call_sd_write_buf_api(lba, b)
    }
}

pub fn call_mic_write_file(count: u32) -> Result<u32, i32> {
    let fs = crate::fs::fat32::Fat32::mount(&mut UserSd)?;
    let (c, _) = fs.find(&mut UserSd, "MIC.TXT")?;
    if c < 2 {
        return Err(-1);
    }
    Ok(unsafe { syscall(I2S_MIC_WRITE, [count, fs.cluster_to_lba(c), 0, 0, 0, 0]).0 })
}

pub unsafe fn call_dump_api(addr: u32, len: u32) {
    syscall(SYS_DUMP, [addr, len, 0, 0, 0, 0]);
}

pub fn call_lcd_rgb888_begin() -> i32 {
    call(SYS_LCD_RGB888_BEGIN, 0) as i32
}

pub fn call_lcd_rgb888_rect(x: u32, y: u32, w: u32, h: u32, rgb: &[u8]) -> i32 {
    if w == 0 || h == 0 || w > 16 || h > 16 || rgb.len() < (w * h * 3) as usize {
        return -1;
    }
    unsafe { syscall(SYS_LCD_RGB888_RECT, [x, y, w, h, rgb.as_ptr() as u32, 0]).0 as i32 }
}

pub fn call_sa_matmul_int8_rect(
    a: &[i8],
    b: &[i8],
    c: &mut [i32],
    m: usize,
    k: usize,
    n: usize,
    profile: Option<&mut super::sa_transfer::Profile>,
) -> i32 {
    use super::sa_transfer::*;
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
        return -1;
    }
    let ptr = profile.map_or(0, |p| p as *mut Profile as u32);
    unsafe {
        syscall(
            SYS_SA_RUN,
            [
                a.as_ptr() as u32,
                b.as_ptr() as u32,
                c.as_mut_ptr() as u32,
                dims(m as u32, k as u32, n as u32),
                1 | RECT_FLAG | if ptr != 0 { PROFILE_FLAG } else { 0 },
                ptr,
            ],
        )
        .0 as i32
    }
}

pub fn call_sa_api(n: usize, signed: bool) {
    if n == 0 || n > 64 || n & 3 != 0 {
        print(format_args!("invalid matrix size\n"));
        return;
    }
    let mut a = [0u8; 4096];
    let mut b = [0u8; 4096];
    let mut c = [0u32; 4096];
    for i in 0..n {
        for j in 0..n {
            a[i * n + j] = (2 * i + 2 * j + 2) as u8;
            b[i * n + j] = (3 * i + j + 5) as u8;
        }
    }
    unsafe {
        syscall(
            SYS_SA_RUN,
            [
                a.as_ptr() as u32,
                b.as_ptr() as u32,
                c.as_mut_ptr() as u32,
                n as u32,
                signed as u32,
                0,
            ],
        );
    }
    for (name, data) in [("A", &a[..n * n]), ("B", &b[..n * n])] {
        print(format_args!("{}\n", name));
        for row in data.chunks(n) {
            for v in row {
                print(format_args!("{} ", v));
            }
            putchar(b'\n');
        }
    }
    print(format_args!("C\n"));
    for row in c[..n * n].chunks(n) {
        for v in row {
            print(format_args!("{} ", *v as i32));
        }
        putchar(b'\n');
    }
}

pub fn parse_u32(s: &str) -> u32 {
    let (base, s) = if s.starts_with("0x") || s.starts_with("0X") {
        (16, &s[2..])
    } else {
        (10, s)
    };
    let mut value = 0u32;
    for c in s.chars() {
        let Some(d) = c.to_digit(base) else {
            break;
        };
        value = value.wrapping_mul(base).wrapping_add(d);
    }
    value
}

pub fn is_prime(n: u32) -> bool {
    if n < 2 {
        return false;
    }
    let mut i = 2;
    while i <= n / i {
        if n % i == 0 {
            return false;
        }
        i += 1;
    }
    true
}
