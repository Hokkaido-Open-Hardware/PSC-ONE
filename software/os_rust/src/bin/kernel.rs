//! Link the supervisor kernel with a separately loaded user.mem image.
#![no_std]
#![no_main]

// Keep boot reachable from the Rust archive as well as the linker entry point.
#[used]
static BOOT: unsafe extern "C" fn() -> ! = psc_os::kernel::kernel::boot;

#[panic_handler]
fn panic(info: &core::panic::PanicInfo<'_>) -> ! {
    psc_os::common::print(format_args!("kernel panic: {info}\n"));
    loop {
        core::hint::spin_loop();
    }
}
