//! drivers/timer_api.c/.h
use crate::common::{mmio_r32, mmio_w32};
pub const CTRL: u32 = 0x10002000;
pub const COUNT: u32 = 0x10002004;
pub const STATUS: u32 = 0x10002008;
pub const TIMER_ST_RUNNING: u32 = 1 << 7;
pub const TIMER_ST_IRQ_ENABLE: u32 = 1 << 9;
pub const TIMER_ST_IRQ_PENDING: u32 = 1 << 10;
/// Start a one-shot timer using the low 16 reload bits.
pub unsafe fn timer_start(reload: u32) {
    mmio_w32(CTRL, (reload & 0xffff) | (1 << 16));
}

/// Start periodic operation with the hardware autoreload bit set.
pub unsafe fn timer_start_auto(reload: u32) {
    mmio_w32(CTRL, (reload & 0xffff) | (1 << 16) | (1 << 17));
}

/// A reload of 999 expires after 1000 one-microsecond ticks.
pub unsafe fn timer_start_scheduler_tick() {
    mmio_w32(CTRL, 999 | (1 << 16) | (1 << 17) | (1 << 18));
}

/// Acknowledge W1C pending status while retaining autoreload and IRQ enable.
pub unsafe fn timer_clear_scheduler_irq() {
    mmio_w32(CTRL, 999 | (1 << 17) | (1 << 18) | (1 << 20));
}

/// Stop counting through the command register rather than modifying status.
pub unsafe fn timer_stop() {
    mmio_w32(CTRL, 1 << 19);
}

/// Mask out non-counter bits from the live count register.
pub unsafe fn timer_get_count() -> u32 {
    mmio_r32(COUNT) & 0xffff
}

/// Return the full hardware status snapshot for callers that inspect several flags.
pub unsafe fn timer_get_status() -> u32 {
    mmio_r32(STATUS)
}

/// Test the running flag rather than inferring completion from the counter value.
pub unsafe fn timer_is_running() -> bool {
    timer_get_status() & TIMER_ST_RUNNING != 0
}

/// Split long waits into chunks that fit the 16-bit reload field.
pub unsafe fn timer_wait_us(mut us: u32) {
    while us != 0 {
        let count = us.min(0xffff);
        timer_start(count);
        while timer_is_running() {
            core::hint::spin_loop();
        }
        us -= count;
    }
}

/// Repeat a one-millisecond wait without overflowing a microsecond conversion.
pub unsafe fn timer_wait_ms(ms: u32) {
    for _ in 0..ms {
        timer_wait_us(1000);
    }
}
