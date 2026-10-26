//! kernel/kernel_syscall.c. Dispatch the historical shell ABI and restrict ELFs.
use super::{kernel_elf::*, kernel_process::CURRENT, syscall::*, types::*, user_memory::*};
use crate::drivers::{
    lcd_api::*, led_api::*, mic_api::*, sdcard_api::*, timer_api::*, timer_measure::*,
};
/// Check the complete user span and require valid user leaf permissions on every page.
pub unsafe fn user_accessible(address: u32, bytes: u32, access: u32) -> bool {
    // Validate every leaf before touching user memory, including cross-page spans.
    if CURRENT.is_null() || !user_span(address, bytes) {
        return false;
    }
    let last = (address + bytes - 1) & !4095;
    let mut va = address & !4095;
    loop {
        let entry = *(*CURRENT).page_table.add((va >> 22) as usize);
        if entry & PAGE_V == 0 || entry & (PAGE_R | PAGE_W | PAGE_X) != 0 {
            return false;
        }
        let leaf = ((entry >> 10) << 12) as *const u32;
        let pte = *leaf.add(((va >> 12) & 1023) as usize);
        let required = PAGE_V | PAGE_U | access;
        if pte & required != required {
            return false;
        }
        if va == last {
            return true;
        }
        va += 4096;
    }
}

/// Map a Rust result back to the signed status bits used by the existing syscall ABI.
fn status(r: Result<(), i32>) -> u32 {
    r.err().unwrap_or(0) as u32
}

/// Validate user buffers, snapshot operands, and optionally report copy/execute timings.
unsafe fn sa(f: &mut TrapFrame) {
    use crate::api::sa_transfer::*;
    let rect = f.a5 & RECT_FLAG != 0;
    let (m, k, n) = if rect {
        ((f.a4 >> 16) & 255, f.a4 & 255, (f.a4 >> 8) & 255)
    } else {
        (f.a4, f.a4, f.a4)
    };
    let profiling = f.a5 & PROFILE_FLAG != 0;
    if m == 0
        || k == 0
        || n == 0
        || m > 64
        || k > 64
        || n > 64
        || k & 3 != 0
        || n & 3 != 0
        || (rect && f.a4 >> 24 != 0)
    {
        f.a0 = u32::MAX;
        return;
    }
    if f.a2 & 3 != 0
        || !user_accessible(f.a0, m * k, PAGE_R)
        || !user_accessible(f.a1, k * n, PAGE_R)
        || !user_accessible(f.a2, m * n * 4, PAGE_W)
        || (profiling && (f.a6 & 3 != 0 || !user_accessible(f.a6, 16, PAGE_W)))
    {
        f.a0 = u32::MAX;
        return;
    }
    // Copy inputs into kernel-owned buffers before issuing asynchronous hardware work.
    #[repr(align(4))]
    struct Bytes([u8; 4096]);
    static mut A: Bytes = Bytes([0; 4096]);
    static mut B: Bytes = Bytes([0; 4096]);
    static mut C: [u32; 4096] = [0; 4096];
    let a = &mut *core::ptr::addr_of_mut!(A.0);
    let b = &mut *core::ptr::addr_of_mut!(B.0);
    let c = &mut *core::ptr::addr_of_mut!(C);
    let t0 = if profiling {
        timer_measure_read_us()
    } else {
        -1
    };
    core::ptr::copy_nonoverlapping(f.a0 as *const u8, a.as_mut_ptr(), (m * k) as usize);
    core::ptr::copy_nonoverlapping(f.a1 as *const u8, b.as_mut_ptr(), (k * n) as usize);
    c[..(m * n) as usize].fill(0);
    let t1 = if profiling {
        timer_measure_read_us()
    } else {
        -1
    };
    let result = crate::api::synap_api::sa_run_rect_checked(
        a,
        b,
        m as usize,
        k as usize,
        n as usize,
        c,
        f.a5 & 1 != 0,
    );
    if let Err(e) = result {
        f.a0 = e as u32;
        return;
    }
    let t2 = if profiling {
        timer_measure_read_us()
    } else {
        -1
    };
    core::ptr::copy_nonoverlapping(c.as_ptr(), f.a2 as *mut u32, (m * n) as usize);
    if profiling {
        let t3 = timer_measure_read_us();
        let mut p = Profile::default();
        if t0 >= 0 && t1 >= t0 && t2 >= t1 && t3 >= t2 {
            p.valid = 1;
            p.copy_in_us = (t1 - t0) as u32;
            p.execute_us = (t2 - t1) as u32;
            p.copy_out_us = (t3 - t2) as u32;
        }
        core::ptr::write(f.a6 as *mut Profile, p);
    }
    f.a0 = 0;
}

/// Dispatch the a3 service number while enforcing the restricted foreground-ELF API.
pub unsafe fn handle_syscall(f: &mut TrapFrame) {
    // Foreground applications do not inherit raw-pointer diagnostic privileges.
    if elf_is_running()
        && !matches!(
            f.a3,
            SYS_PUTCHAR | SYS_GETCHAR | SYS_GETCHAR_TIMEOUT | SYS_PRINT_INT | SYS_EXIT
        )
    {
        f.a0 = u32::MAX;
        return;
    }
    match f.a3 {
        SYS_MP_CONSOLE => f.a0 = super::console::control(f.a0, f.a1 as i32) as u32,
        SYS_PUTCHAR => crate::common::putchar(f.a0 as u8),
        SYS_GETCHAR => f.a0 = super::kernel::uart_getchar() as u32,
        SYS_GETCHAR_TIMEOUT => f.a0 = super::kernel::uart_getchar_timeout(1000) as u32,
        SYS_PRINT_INT => crate::s_print!("{}", f.a0 as i32),
        SYS_I2C_CAPTURE => f.a0 = crate::api::i2c_capture::execute(f.a0),
        SYS_ROBOT_CONTROL => {
            crate::api::robot::robot_control::robot_control();
            f.a0 = 0;
        }
        SYS_ELF_RUN => elf_run(f),
        SYS_SA_RUN => sa(f),
        I2S_MIC_READ => f.a0 = s_call_mic_read_samples24(f.a0 as usize) as u32,
        I2S_MIC_WRITE => f.a0 = s_call_mic_write_samples24(f.a0 as usize, f.a1) as u32,
        SYS_SD_READ => s_call_sdcard_read_api(f.a0),
        SYS_SD_WRITE_TEST => {
            let mut b = [0; 512];
            for (i, v) in b.iter_mut().enumerate() {
                *v = i as u8;
            }
            f.a0 = status(s_call_sdcard_write_api(f.a0, &b));
        }
        SYS_SD_WRITE => f.a0 = status(sd_write_sector_quiet(f.a0, &*(f.a1 as *const [u8; 512]))),
        SYS_SD_READ_BUF => {
            let mut b = [0; 512];
            let r = sd_read_sector(f.a0, &mut b);
            if r.is_ok() {
                core::ptr::copy_nonoverlapping(b.as_ptr(), f.a1 as *mut u8, 512);
            }
            f.a0 = status(r);
        }
        SYS_LCD_RGB888_BEGIN => f.a0 = status(lcd_begin_rgb888()),
        SYS_LCD_RGB888_RECT => {
            let (w, h) = (f.a2, f.a4);
            if w == 0
                || w > 16
                || h == 0
                || h > 16
                || f.a0 >= 480
                || f.a1 >= 320
                || w > 480 - f.a0
                || h > 320 - f.a1
                || !user_accessible(f.a5, w * h * 3, PAGE_R)
            {
                f.a0 = u32::MAX;
                return;
            }
            let mut rgb = [0; 768];
            let n = (w * h * 3) as usize;
            core::ptr::copy_nonoverlapping(f.a5 as *const u8, rgb.as_mut_ptr(), n);
            f.a0 = status(lcd_write_rgb888_rect(f.a0, f.a1, w, h, &rgb[..n]));
        }
        SYS_TIMER_MEASURE_BEGIN => f.a0 = timer_measure_begin() as u32,
        SYS_TIMER_MEASURE_END => f.a0 = timer_measure_end() as u32,
        SYS_TIMER_MEASURE_END_US => f.a0 = timer_measure_end_us() as u32,
        SYS_TIMER_MEASURE_READ_US => f.a0 = timer_measure_read_us() as u32,
        SYS_TIMER_START => timer_start(f.a0),
        SYS_TIMER_START_AUTO => timer_start_auto(f.a0),
        SYS_TIMER_STOP => timer_stop(),
        SYS_TIMER_GET_COUNT => f.a0 = timer_get_count(),
        SYS_TIMER_GET_STATUS => f.a0 = timer_get_status(),
        SYS_TIMER_IS_RUNNING => f.a0 = timer_is_running() as u32,
        SYS_TIMER_WAIT_US => timer_wait_us(f.a0),
        SYS_TIMER_WAIT_MS => timer_wait_ms(f.a0),
        SYS_LED_WRITE => led_write(f.a0),
        SYS_LED_ON => led_on(f.a0),
        SYS_LED_OFF => led_off(f.a0),
        SYS_LED_TOGGLE => led_toggle(f.a0),
        SYS_LED_ALL_ON => led_all_on(),
        SYS_LED_ALL_OFF => led_all_off(),
        SYS_LED_GET_STATE => f.a0 = led_get_state(),
        SYS_DUMP => {
            let len = if f.a1 == 0 { 256 } else { f.a1.min(4096) };
            crate::common::hexdump(
                core::slice::from_raw_parts(f.a0 as *const u8, len as usize),
                f.a0 as usize,
            );
        }
        SYS_SW_READ => f.a0 = crate::common::mmio_r32(0x10001000) & 3,
        SYS_SPEECH_RECOGNITION => {
            f.a0 = crate::api::speech_recognition_api::s_call_speech_recognition_api() as u32
        }
        SYS_EXIT => {
            if elf_is_running() {
                elf_finish(f, 0, f.a0 as i32);
            } else {
                super::kernel_process::reboot();
            }
        }
        _ => panic!("unexpected syscall a3={:x}", f.a3),
    }
}
