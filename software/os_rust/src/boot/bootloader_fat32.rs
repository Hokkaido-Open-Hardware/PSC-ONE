//! boot/bootloader_fat32.c: CRC-checked SD boot into the supervisor kernel.
use crate::{common::*, drivers::sdcard_api::sd_crc16, fs::fat32::BlockDevice};
pub struct BootSd;
impl BootSd {
    /// Flush the FIFO, trigger card initialization, and bound the busy wait.
    pub unsafe fn init() -> Result<Self, i32> {
        mmio_w32(0x10006008, 4);
        delay(100);
        mmio_w32(0x10006008, 1);
        delay(100);
        let mut timeout = 50000;
        while mmio_r32(0x10006008) & 2 != 0 {
            delay(100);
            timeout -= 1;
            if timeout == 0 {
                return Err(-1);
            }
        }
        delay(100);
        Ok(Self)
    }

    /// Wait for a boot-controller status transition with a finite polling limit.
    unsafe fn wait(mask: u32, set: bool) -> Result<(), i32> {
        let mut timeout = 50000;
        while (mmio_r32(0x10006008) & mask != 0) == set {
            timeout -= 1;
            if timeout == 0 {
                return Err(-1);
            }
            delay(1);
        }
        Ok(())
    }
}
impl BlockDevice for BootSd {
    fn read(&mut self, lba: u32, b: &mut [u8; 512]) -> Result<(), i32> {
        unsafe {
            for _ in 0..3 {
                mmio_w32(0x10006008, 4);
                delay(50);
                mmio_w32(0x10006004, lba);
                mmio_w32(0x10006008, 2);
                Self::wait(4, true)?;
                Self::wait(4, false)?;
                delay(20);
                for chunk in b.chunks_exact_mut(4) {
                    Self::wait(8, true)?;
                    chunk.copy_from_slice(&mmio_r32(0x10006000).to_le_bytes());
                }
                if sd_crc16(b) == (mmio_r32(0x10006008) >> 16) as u16 {
                    return Ok(());
                }
                delay(100);
            }
            Err(-1)
        }
    }

    fn write(&mut self, _lba: u32, _b: &[u8; 512]) -> Result<(), i32> {
        Err(-1)
    } // Boot media is read-only.
}

#[cfg(target_arch = "riscv32")]
/// Load CRC-verified KERNEL.MEM words, then jump to the supervisor entry address.
pub unsafe extern "C" fn bootloader_main() -> ! {
    let mut dev = BootSd::init().expect("SD init failed");
    let fs = super::boot_fat32::BootFat32::mount(&mut dev).expect("FAT32 mount failed");
    // Bound every store below the user-image staging region.
    let dst =
        core::slice::from_raw_parts_mut(0x00200000 as *mut u32, (0x00400000 - 0x00200000) / 4);
    let words = fs
        .load_mem_file_bounded(&mut dev, "KERNEL.MEM", dst)
        .expect("KERNEL.MEM load failed");
    crate::s_print!("kernel words={}\nUSER.MEM deferred to kernel\n", words);
    core::arch::asm!("fence rw, rw","fence.i","jr {entry}",entry=in(reg) 0x00200000u32,options(noreturn));
}
