//! api/i2c_api.c/.h. All accesses are aligned volatile 32-bit operations.
use crate::common::{mmio_r32, mmio_w32};
pub const INPUT: u32 = 0x10009000;
pub const STATUS: u32 = 0x10009004;
pub const OUTPUT: u32 = 0x10009008;
pub const CONTROL: u32 = 0x1000900c;
pub const SEQ: u32 = 0x10009010;
pub const INPUT_READY: u32 = 1;
pub const OUTPUT_READY: u32 = 2;
pub const OVERRUN: u32 = 4;
/// Disable receive IRQs and clear old W1C flags without resetting payload or sequence.
pub unsafe fn i2c_init() {
    i2c_set_irq_enabled(false);
    i2c_clear_status(7);
}

/// Expose only the three documented slave status flags.
pub unsafe fn i2c_get_status() -> u32 {
    mmio_r32(STATUS) & 7
}

/// Write only requested W1C bits; a read-modify-write would acknowledge unrelated events.
pub unsafe fn i2c_clear_status(mask: u32) {
    mmio_w32(STATUS, mask & 7);
}

/// Control the peripheral IRQ request independently of receive-ready state.
pub unsafe fn i2c_set_irq_enabled(enabled: bool) {
    mmio_w32(CONTROL, enabled as u32);
}

/// Read back the IRQ-enable bit from the control register.
pub unsafe fn i2c_get_irq_enabled() -> bool {
    mmio_r32(CONTROL) & 1 != 0
}

/// Return the eight-bit counter that increments after each complete input frame.
pub unsafe fn i2c_get_sequence() -> u8 {
    mmio_r32(SEQ) as u8
}

/// Unpack four signed bytes without acknowledging input-ready or overrun.
pub unsafe fn i2c_read_input(input: &mut [i8; 4]) -> Result<(), i32> {
    if i2c_get_status() & INPUT_READY == 0 {
        return Err(-2);
    }
    let packed = mmio_r32(INPUT);
    for (i, b) in input.iter_mut().enumerate() {
        *b = (packed >> (8 * i)) as i8;
    }
    Ok(())
}

/// Poll at most max_polls times; this bound is an iteration count, not elapsed time.
pub unsafe fn i2c_wait_input(max_polls: u32) -> Result<(), i32> {
    for _ in 0..max_polls {
        if i2c_get_status() & INPUT_READY != 0 {
            return Ok(());
        }
    }
    Err(-3)
}

/// Publish only the low output byte; hardware sets output-ready.
pub unsafe fn i2c_write_output(output: i8) {
    mmio_w32(OUTPUT, output as u8 as u32);
}

/// Interpret the low output byte as a signed two-complement value.
pub unsafe fn i2c_read_output() -> i8 {
    mmio_r32(OUTPUT) as i8
}
