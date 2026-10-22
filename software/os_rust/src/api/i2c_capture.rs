//! api/i2c_capture.h; command implementation from kernel_syscall.c.
use crate::common::{mmio_r32, mmio_w32};
pub const ARM: u32 = 0;
pub const STATUS: u32 = 1;
pub const COUNT: u32 = 2;
pub const POP: u32 = 3;
pub const ABORT: u32 = 4;
pub const ARM_SELF: u32 = 5;
pub const ARM_PWM: u32 = 6;
pub const PWM_SUPPORTED: u32 = 1 << 18;
pub const PWM_MODE: u32 = 1 << 19;
pub const SELF_SUPPORTED: u32 = 1 << 16;
pub const SELF_MODE: u32 = 1 << 17;
pub const LIMIT: u32 = 1 << 6;
pub const MULTI: u32 = 1 << 7;
pub const TIMEOUT: u32 = 1 << 5;
pub const DONE: u32 = 1 << 2;
pub const OVERFLOW: u32 = 1 << 3;
pub const ABORTED: u32 = 1 << 4;
/// Access dedicated capture registers; never modify the independent I2C slave control flags.
pub unsafe fn execute(op: u32) -> u32 {
    match op {
        ARM_PWM => {
            if mmio_r32(0x10009014) & PWM_SUPPORTED == 0 {
                return u32::MAX;
            }
            mmio_w32(0x10009014, 13);
            0
        }
        ARM_SELF => {
            if mmio_r32(0x10009014) & SELF_SUPPORTED == 0 {
                return u32::MAX;
            }
            mmio_w32(0x10009014, 5);
            0
        }
        ARM | ABORT => {
            mmio_w32(0x10009014, if op == ARM { 1 } else { 2 });
            0
        }
        STATUS => mmio_r32(0x10009014),
        COUNT => mmio_r32(0x10009018),
        POP => mmio_r32(0x1000901c),
        _ => u32::MAX,
    }
}
