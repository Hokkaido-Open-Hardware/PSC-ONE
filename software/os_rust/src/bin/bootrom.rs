#![no_std]
#![no_main]
#[used]
static ENTRY: unsafe extern "C" fn() -> ! = psc_os::boot::psc_mbios::mbios_entry;
#[panic_handler]
fn panic(_: &core::panic::PanicInfo<'_>) -> ! {
    loop {
        core::hint::spin_loop();
    }
}
