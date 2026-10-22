//! U-mode shell entry. The kernel maps and zero-fills the user image and stack.
#![no_std]
#![no_main]
use core::arch::naked_asm;

#[unsafe(naked)]
#[no_mangle]
#[link_section = ".text.start"]
pub unsafe extern "C" fn start() -> ! {
    // Assembly establishes the stack before Rust can emit any local spills.
    naked_asm!("la sp, __user_stack_top", "j {main}", main = sym shell_main);
}

extern "C" fn shell_main() -> ! {
    psc_os::shell::shell::main()
}

#[panic_handler]
fn panic(info: &core::panic::PanicInfo<'_>) -> ! {
    psc_os::api::user::print(format_args!("shell panic: {info}\n"));
    psc_os::api::user::exit()
}
