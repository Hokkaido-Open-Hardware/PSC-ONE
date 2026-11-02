#![no_std]
#![no_main]
#[unsafe(naked)]
#[no_mangle]
#[link_section = ".text.bootloader"]
pub unsafe extern "C" fn bootloader_entry() -> ! {
    core::arch::naked_asm!("la sp, _stack_top", "j {main}", main = sym main);
}
unsafe extern "C" fn main() -> ! {
    extern "C" {
        static mut __bss: u8;
        static __bss_end: u8;
    }
    let mut p = core::ptr::addr_of_mut!(__bss);
    while p < core::ptr::addr_of!(__bss_end) as *mut u8 {
        p.write_volatile(0);
        p = p.add(1);
    }
    psc_os::boot::bootloader_fat32::bootloader_main()
}
#[panic_handler]
fn panic(info: &core::panic::PanicInfo<'_>) -> ! {
    psc_os::common::print(format_args!("bootloader panic: {info}\n"));
    loop {
        core::hint::spin_loop();
    }
}
