//! boot/bootloader_entry.S expressed as a Rust naked entry point.
#[unsafe(naked)]
pub unsafe extern "C" fn entry() -> ! {
    core::arch::naked_asm!("la sp, _stack_top","j {main}",main=sym super::bootloader_fat32::bootloader_main);
}
