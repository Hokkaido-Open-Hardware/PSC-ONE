//! boot/bootloader.c: legacy fixed-LBA image loader, separate from FAT32 boot.
#[cfg(any(target_arch = "riscv32", target_arch = "riscv64"))]
use crate::common::mmio_r32;
use crate::fs::fat32::BlockDevice;
/// Copy the requested fixed-LBA sectors into physical memory using volatile stores.
pub unsafe fn sd_load_image(
    dev: &mut impl BlockDevice,
    start: u32,
    count: u32,
    dst: *mut u8,
) -> Result<(), i32> {
    let mut b = [0; 512];
    for sector in 0..count {
        dev.read(start + sector, &mut b)?;
        for (i, &v) in b.iter().enumerate() {
            core::ptr::write_volatile(dst.add(sector as usize * 512 + i), v);
        }
    }
    Ok(())
}

#[cfg(any(target_arch = "riscv32", target_arch = "riscv64"))]
/// Run the legacy memory diagnostic and load 128 sectors starting at LBA 100.
pub unsafe extern "C" fn bootloader_main() -> ! {
    crate::s_print!("boot start\n");
    crate::drivers::mem_test::random_mem_check(
        crate::board::MEMORY_TEST_START,
        crate::board::MEMORY_TEST_END,
    );
    let mut dev = super::bootloader_fat32::BootSd::init().expect("SD init failed");
    sd_load_image(&mut dev, 100, 128, crate::board::KERNEL_BASE as *mut u8)
        .expect("kernel load failed");
    crate::s_print!("kernel[0]={:08x}\n", mmio_r32(crate::board::KERNEL_BASE));
    core::arch::asm!("fence rw, rw","fence.i","jr {entry}",entry=in(reg) crate::board::KERNEL_BASE,options(noreturn));
}
