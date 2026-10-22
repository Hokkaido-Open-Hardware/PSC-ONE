//! drivers/timer_measure.c. Shared state uses volatile accesses across IRQs.
use super::timer_api::*;
use crate::common::mmio_w32;
use core::ptr::{addr_of, addr_of_mut, read_volatile as read, write_volatile as write};
const PERIOD: u32 = 50000;
const RUN: u32 = 49999 | (1 << 17) | (1 << 18);
static mut ACTIVE: u32 = 0;
static mut US: u32 = 0;
static mut STOPPING: u32 = 0;
/// Borrow only an idle timer; install the machine trap before enabling measurement IRQs.
pub unsafe fn timer_measure_begin() -> i32 {
    if read(addr_of!(ACTIVE)) != 0
        || timer_get_status() & (TIMER_ST_RUNNING | TIMER_ST_IRQ_ENABLE | TIMER_ST_IRQ_PENDING) != 0
    {
        return -1;
    }
    crate::kernel::kernel_process::enable_machine_timer_trap();
    write(addr_of_mut!(US), 0);
    write(addr_of_mut!(STOPPING), 0);
    write(addr_of_mut!(ACTIVE), 1);
    mmio_w32(CTRL, RUN | (1 << 16) | (1 << 20));
    0
}

/// Extend the 16-bit counter by 50000 microseconds for each pending expiry.
pub unsafe fn timer_measure_irq() -> bool {
    if read(addr_of!(ACTIVE)) == 0 {
        return false;
    }
    if timer_get_status() & TIMER_ST_IRQ_PENDING != 0 {
        write(addr_of_mut!(US), read(addr_of!(US)).wrapping_add(PERIOD));
        mmio_w32(
            CTRL,
            if read(addr_of!(STOPPING)) != 0 {
                (1 << 19) | (1 << 20)
            } else {
                RUN | (1 << 20)
            },
        );
    }
    true
}

/// Stop first, take a stable snapshot, then clear the IRQ before releasing ownership.
unsafe fn end(divisor: u32) -> i32 {
    if read(addr_of!(ACTIVE)) == 0 {
        return -1;
    }
    write(addr_of_mut!(STOPPING), 1);
    timer_stop();
    let elapsed = loop {
        let before = read(addr_of!(US));
        let pending = timer_get_status() & TIMER_ST_IRQ_PENDING;
        let count = timer_get_count();
        let after = read(addr_of!(US));
        if before == after {
            break before
                .wrapping_add(if pending != 0 { PERIOD } else { 0 })
                .wrapping_add(49999)
                .wrapping_sub(count);
        }
    };
    mmio_w32(CTRL, (1 << 19) | (1 << 20));
    while timer_get_status() & TIMER_ST_IRQ_PENDING != 0 {}
    write(addr_of_mut!(ACTIVE), 0);
    (elapsed / divisor) as i32
}

/// Finish the stopwatch and convert elapsed microseconds to milliseconds.
pub unsafe fn timer_measure_end() -> i32 {
    end(1000)
}

/// Finish the stopwatch while preserving microsecond resolution.
pub unsafe fn timer_measure_end_us() -> i32 {
    end(1)
}

/// Retry if an IRQ or wrap races the snapshot; do not stop an active measurement.
pub unsafe fn timer_measure_read_us() -> i32 {
    if read(addr_of!(ACTIVE)) == 0 || read(addr_of!(STOPPING)) != 0 {
        return -1;
    }
    loop {
        let before = read(addr_of!(US));
        let pending = timer_get_status() & TIMER_ST_IRQ_PENDING;
        let count = timer_get_count();
        let after_pending = timer_get_status() & TIMER_ST_IRQ_PENDING;
        let after = read(addr_of!(US));
        if before == after && pending == after_pending {
            return before
                .wrapping_add(if pending != 0 { PERIOD } else { 0 })
                .wrapping_add(49999)
                .wrapping_sub(count) as i32;
        }
    }
}
