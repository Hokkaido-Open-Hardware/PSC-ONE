//! drivers/led_api.c/.h. The kernel must serialize access to LED state.
use crate::common::mmio_w32;
pub const PSC_LED_BASE_ADDR: u32 = 0x10004000;
pub const PSC_LED_MASK: u32 = 0x3f;
static mut LED_STATE: u32 = 0;
/// Keep the software shadow and the six physical LED bits in agreement.
pub unsafe fn led_write(value: u32) {
    LED_STATE = value & PSC_LED_MASK;
    mmio_w32(PSC_LED_BASE_ADDR, LED_STATE);
}

/// Set one valid LED bit without disturbing the other five outputs.
pub unsafe fn led_on(led: u32) {
    if led < 6 {
        led_write(LED_STATE | (1 << led));
    }
}

/// Clear one valid LED bit while preserving the rest of the shadow register.
pub unsafe fn led_off(led: u32) {
    if led < 6 {
        led_write(LED_STATE & !(1 << led));
    }
}

/// Invert a single LED; indices outside 0..6 have no effect.
pub unsafe fn led_toggle(led: u32) {
    if led < 6 {
        led_write(LED_STATE ^ (1 << led));
    }
}

/// Drive all six LED outputs high through the shared shadow-update path.
pub unsafe fn led_all_on() {
    led_write(PSC_LED_MASK);
}

/// Clear every LED output and its software shadow.
pub unsafe fn led_all_off() {
    led_write(0);
}

/// Read the software shadow because the hardware register is used as an output.
pub unsafe fn led_get_state() -> u32 {
    LED_STATE
}
