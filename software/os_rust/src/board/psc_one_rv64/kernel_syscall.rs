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
        let Some(pte) = super::sv39::translate((*CURRENT).page_table, va as u64) else {
            return false;
        };
        let required = (PAGE_V | PAGE_U | access) as u64;
        if pte.flags & required != required {
            return false;
        }
        if va == last {
            return true;
        }
        va += 4096;
    }
}

/// Map a Rust result back to the signed status bits used by the existing syscall ABI.
fn status(r: Result<(), i32>) -> u64 {
    r.err().unwrap_or(0) as i64 as u64
}

/// Validate user buffers, snapshot operands, and optionally report copy/execute timings.
unsafe fn sa(f: &mut TrapFrame) {
    let [a0, a1, a2, _a3, a4, a5, a6] =
        [f.a0, f.a1, f.a2, f.a3, f.a4, f.a5, f.a6].map(|x| x as u32);
    use crate::api::sa_transfer::*;
    let rect = a5 & RECT_FLAG != 0;
    let (m, k, n) = if rect {
        ((a4 >> 16) & 255, a4 & 255, (a4 >> 8) & 255)
    } else {
        (a4, a4, a4)
    };
    let profiling = a5 & PROFILE_FLAG != 0;
    if m == 0
        || k == 0
        || n == 0
        || m > 64
        || k > 64
        || n > 64
        || k & 3 != 0
        || n & 3 != 0
        || (rect && a4 >> 24 != 0)
    {
        f.a0 = u64::MAX;
        return;
    }
    if a2 & 3 != 0
        || !user_accessible(a0, m * k, PAGE_R)
        || !user_accessible(a1, k * n, PAGE_R)
        || !user_accessible(a2, m * n * 4, PAGE_W)
        || (profiling && (a6 & 3 != 0 || !user_accessible(a6, 16, PAGE_W)))
    {
        f.a0 = u64::MAX;
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
    core::ptr::copy_nonoverlapping(a0 as *const u8, a.as_mut_ptr(), (m * k) as usize);
    core::ptr::copy_nonoverlapping(a1 as *const u8, b.as_mut_ptr(), (k * n) as usize);
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
        a5 & 1 != 0,
    );
    if let Err(e) = result {
        f.a0 = e as i64 as u64;
        return;
    }
    let t2 = if profiling {
        timer_measure_read_us()
    } else {
        -1
    };
    core::ptr::copy_nonoverlapping(c.as_ptr(), a2 as *mut u32, (m * n) as usize);
    if profiling {
        let t3 = timer_measure_read_us();
        let mut p = Profile::default();
        if t0 >= 0 && t1 >= t0 && t2 >= t1 && t3 >= t2 {
            p.valid = 1;
            p.copy_in_us = (t1 - t0) as u32;
            p.execute_us = (t2 - t1) as u32;
            p.copy_out_us = (t3 - t2) as u32;
        }
        core::ptr::write(a6 as *mut Profile, p);
    }
    f.a0 = (0) as u64;
}

/// Dispatch the a3 service number while enforcing the restricted foreground-ELF API.
pub unsafe fn handle_syscall(f: &mut TrapFrame) {
    let [a0, a1, a2, a3, a4, a5, _a6] =
        [f.a0, f.a1, f.a2, f.a3, f.a4, f.a5, f.a6].map(|x| x as u32);
    // The PSC service protocol keeps 32-bit device values and low user VAs.
    // Never allow a high pointer to alias a mapped low user buffer by truncation.
    let bad_pointer = match a3 {
        SYS_SA_RUN => {
            f.a0 > u32::MAX as u64
                || f.a1 > u32::MAX as u64
                || f.a2 > u32::MAX as u64
                || (a5 & crate::api::sa_transfer::PROFILE_FLAG != 0 && f.a6 > u32::MAX as u64)
        }
        SYS_ELF_RUN | SYS_DUMP => f.a0 > u32::MAX as u64,
        SYS_SD_READ_BUF | SYS_SD_WRITE => f.a1 > u32::MAX as u64,
        SYS_LCD_RGB888_RECT => f.a5 > u32::MAX as u64,
        _ => false,
    };
    if f.a3 > u32::MAX as u64 || bad_pointer {
        f.a0 = u64::MAX;
        return;
    }
    // Foreground applications do not inherit raw-pointer diagnostic privileges.
    if elf_is_running()
        && !matches!(
            a3,
            SYS_PUTCHAR | SYS_GETCHAR | SYS_GETCHAR_TIMEOUT | SYS_PRINT_INT | SYS_EXIT
        )
    {
        f.a0 = u64::MAX;
        return;
    }
    match a3 {
        SYS_MP_CONSOLE => f.a0 = (super::console::control(a0, a1 as i32) as i64) as u64,
        SYS_PUTCHAR => crate::common::putchar(a0 as u8),
        SYS_GETCHAR => f.a0 = (super::kernel::uart_getchar() as i64) as u64,
        SYS_GETCHAR_TIMEOUT => f.a0 = (super::kernel::uart_getchar_timeout(1000) as i64) as u64,
        SYS_PRINT_INT => crate::s_print!("{}", a0 as i32),
        SYS_I2C_CAPTURE => f.a0 = (crate::api::i2c_capture::execute(a0)) as u64,
        SYS_ROBOT_CONTROL => {
            crate::api::robot::robot_control::robot_control();
            f.a0 = (0) as u64;
        }
        SYS_ELF_RUN => elf_run(f),
        SYS_SA_RUN => sa(f),
        I2S_MIC_READ => f.a0 = (s_call_mic_read_samples24(a0 as usize) as i64) as u64,
        I2S_MIC_WRITE => f.a0 = (s_call_mic_write_samples24(a0 as usize, a1) as i64) as u64,
        SYS_SD_READ => s_call_sdcard_read_api(a0),
        SYS_SD_WRITE_TEST => {
            let mut b = [0; 512];
            for (i, v) in b.iter_mut().enumerate() {
                *v = i as u8;
            }
            f.a0 = (status(s_call_sdcard_write_api(a0, &b))) as u64;
        }
        SYS_SD_WRITE => f.a0 = status(sd_write_sector_quiet(a0, &*(a1 as *const [u8; 512]))) as u64,
        SYS_SD_READ_BUF => {
            let mut b = [0; 512];
            let r = sd_read_sector(a0, &mut b);
            if r.is_ok() {
                core::ptr::copy_nonoverlapping(b.as_ptr(), a1 as *mut u8, 512);
            }
            f.a0 = (status(r)) as u64;
        }
        SYS_LCD_RGB888_BEGIN => f.a0 = (status(lcd_begin_rgb888())) as u64,
        SYS_LCD_RGB888_RECT => {
            let (w, h) = (a2, a4);
            if w == 0
                || w > 16
                || h == 0
                || h > 16
                || a0 >= 480
                || a1 >= 320
                || w > 480 - a0
                || h > 320 - a1
                || !user_accessible(a5, w * h * 3, PAGE_R)
            {
                f.a0 = u64::MAX;
                return;
            }
            let mut rgb = [0; 768];
            let n = (w * h * 3) as usize;
            core::ptr::copy_nonoverlapping(a5 as *const u8, rgb.as_mut_ptr(), n);
            f.a0 = (status(lcd_write_rgb888_rect(a0, a1, w, h, &rgb[..n]))) as u64;
        }
        SYS_TIMER_MEASURE_BEGIN => f.a0 = (timer_measure_begin() as i64) as u64,
        SYS_TIMER_MEASURE_END => f.a0 = (timer_measure_end() as i64) as u64,
        SYS_TIMER_MEASURE_END_US => f.a0 = (timer_measure_end_us() as i64) as u64,
        SYS_TIMER_MEASURE_READ_US => f.a0 = (timer_measure_read_us() as i64) as u64,
        SYS_TIMER_START => timer_start(a0),
        SYS_TIMER_START_AUTO => timer_start_auto(a0),
        SYS_TIMER_STOP => timer_stop(),
        SYS_TIMER_GET_COUNT => f.a0 = (timer_get_count()) as u64,
        SYS_TIMER_GET_STATUS => f.a0 = (timer_get_status()) as u64,
        SYS_TIMER_IS_RUNNING => f.a0 = (timer_is_running() as i64) as u64,
        SYS_TIMER_WAIT_US => timer_wait_us(a0),
        SYS_TIMER_WAIT_MS => timer_wait_ms(a0),
        SYS_LED_WRITE => led_write(a0),
        SYS_LED_ON => led_on(a0),
        SYS_LED_OFF => led_off(a0),
        SYS_LED_TOGGLE => led_toggle(a0),
        SYS_LED_ALL_ON => led_all_on(),
        SYS_LED_ALL_OFF => led_all_off(),
        SYS_LED_GET_STATE => f.a0 = (led_get_state()) as u64,
        SYS_DUMP => {
            let len = if a1 == 0 { 256 } else { a1.min(4096) };
            crate::common::hexdump(
                core::slice::from_raw_parts(a0 as *const u8, len as usize),
                a0 as usize,
            );
        }
        SYS_SW_READ => f.a0 = (crate::common::mmio_r32(crate::board::SWITCH_BASE) & 3) as u64,
        SYS_SPEECH_RECOGNITION => {
            f.a0 = crate::api::speech_recognition_api::s_call_speech_recognition_api() as u64
        }
        SYS_EXIT => {
            if elf_is_running() {
                elf_finish(f, 0, a0 as i32);
            } else {
                super::kernel_process::reboot();
            }
        }
        _ => panic!("unexpected syscall a3={:x}", a3),
    }
}
