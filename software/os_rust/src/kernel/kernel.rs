//! kernel/kernel.c: console, physical allocator, Sv32 mappings and startup.
use super::types::*;
use crate::common::*;
use core::arch::asm;
extern "C" {
    pub static __free_ram: u8;
    pub static __free_ram_end: u8;
    pub static __kernel_base: u8;
    static mut __bss: u8;
    static mut __bss_end: u8;
    static mut __data: u8;
    static mut __data_end: u8;
    static mut __data_initial: u8;
    static _binary_shell_bin_start: u8;
    static _binary_shell_bin_end: u8;
}
static mut NEXT: usize = 0;
/// Allocate zeroed physical pages from linker-owned free RAM; pages are never reclaimed.
pub unsafe fn alloc_pages(n: usize) -> u32 {
    // Initialize lazily so warm-boot BSS clearing also resets the allocation cursor.
    if NEXT == 0 {
        NEXT = core::ptr::addr_of!(__free_ram) as usize;
    }
    let start = NEXT;
    let size = n.checked_mul(4096).expect("page count overflow");
    let end = start.checked_add(size).expect("page address overflow");
    assert!(
        end <= core::ptr::addr_of!(__free_ram_end) as usize,
        "out of memory"
    );
    // Commit the cursor only after overflow and linker-region checks have succeeded.
    NEXT = end;
    core::ptr::write_bytes(start as *mut u8, 0, size);
    start as u32
}

/// Create the Sv32 leaf table on demand and install one aligned 4 KiB mapping.
pub unsafe fn map_page(root: *mut u32, va: u32, pa: u32, flags: u32) {
    assert!(va & 4095 == 0 && pa & 4095 == 0, "unaligned page");
    // Sv32 uses VPN[1] for the root and VPN[0] for the 1024-entry leaf table.
    let entry = root.add((va >> 22) as usize & 1023);
    if *entry & PAGE_V == 0 {
        *entry = ((alloc_pages(1) / 4096) << 10) | PAGE_V;
    }
    // PTE bits 31:10 hold the physical page number, not a byte address.
    let leaf = ((*entry >> 10) * 4096) as *mut u32;
    *leaf.add((va >> 12) as usize & 1023) = ((pa / 4096) << 10) | flags | PAGE_V;
}

/// Write back the data cache before invalidating stale instruction-cache contents.
pub unsafe fn sync_user_code() {
    // The serial load cannot finish until the cache-maintenance sweep completes.
    // A fence alone would not publish dirty D-cache data to instruction fetch.
    asm!(
        "fence rw, rw",
        "li t0, 2",
        "csrw 0x7f0, t0",
        "csrw 0x7f0, zero",
        "lw zero, 0({p})",
        "fence rw, rw",
        "fence.i",
        p = in(reg) core::ptr::addr_of!(__kernel_base),
        out("t0") _,
    );
}

/// Return one byte, or -1 after the bounded polling window expires.
pub unsafe fn uart_getchar_timeout(timeout: u32) -> i32 {
    for _ in 0..timeout {
        if mmio_r32(0x10000008) & 2 != 0 {
            return (mmio_r32(0x10000004) & 255) as i32;
        }
        delay(1);
    }
    -1
}

/// Wait until a UART byte is available by repeating the bounded reader.
pub unsafe fn uart_getchar() -> i32 {
    loop {
        let c = uart_getchar_timeout(1000);
        if c >= 0 {
            return c;
        }
    }
}

#[unsafe(naked)]
#[unsafe(no_mangle)]
#[unsafe(link_section = ".text.boot")]
pub unsafe extern "C" fn boot() -> ! {
    core::arch::naked_asm!("la sp, __kernel_stack_top", "li a0, 0", "j kernel_main");
}

#[unsafe(naked)]
#[unsafe(no_mangle)]
pub unsafe extern "C" fn kernel_warm_boot() -> ! {
    core::arch::naked_asm!("la sp, __kernel_stack_top", "li a0, 1", "j kernel_main");
}

#[unsafe(no_mangle)]
/// Restore writable initialized data on warm boot, clear BSS, and launch the shell process.
pub unsafe extern "C" fn kernel_main(warm: u32) -> ! {
    // Keep a pristine .data image for warm restarts, which retain SDRAM contents.
    let data = core::ptr::addr_of_mut!(__data);
    let initial = core::ptr::addr_of_mut!(__data_initial);
    let size = core::ptr::addr_of!(__data_end) as usize - data as usize;
    if warm != 0 {
        core::ptr::copy_nonoverlapping(initial, data, size);
    } else {
        core::ptr::copy_nonoverlapping(data, initial, size);
    }
    // Volatile word stores clear large buffers without depending on a C runtime.
    let mut bss = core::ptr::addr_of_mut!(__bss) as usize;
    let end = core::ptr::addr_of!(__bss_end) as usize;
    while end - bss >= 4 {
        core::ptr::write_volatile(bss as *mut u32, 0);
        bss += 4;
    }
    while bss < end {
        core::ptr::write_volatile(bss as *mut u8, 0);
        bss += 1;
    }
    crate::s_print!("PSC-ONE / PSC-OS Rust\n");
    asm!("csrw stvec, {}",in(reg) super::kernel_trap::kernel_entry as *const () as u32);
    // The idle page table provides the supervisor-only template for foreground ELFs.
    let idle = super::kernel_process::create_process(&[]);
    (*idle).pid = 0;
    super::kernel_process::IDLE = idle;
    super::kernel_process::CURRENT = idle;
    let shell = core::ptr::addr_of!(_binary_shell_bin_start);
    let size = core::ptr::addr_of!(_binary_shell_bin_end) as usize - shell as usize;
    #[cfg(feature = "sd-user")]
    if warm == 0 {
        // Cold SD boot stages USER.MEM at the same physical address used by RTL.
        // Warm restart retains this immutable source image and avoids another SD read.
        crate::s_print!("KERNEL: initializing SD for USER.MEM\n");
        let mut sd = crate::boot::bootloader_fat32::BootSd::init().expect("SD init failed");
        let volume =
            crate::boot::boot_fat32::BootFat32::mount(&mut sd).expect("FAT32 mount failed");
        let words = (size + 3) / 4;
        crate::s_print!("KERNEL: reading USER.MEM from SD ({} words)\n", words);
        let image = core::slice::from_raw_parts_mut(shell as *mut u32, words);
        let actual = volume
            .load_mem_file_bounded(&mut sd, "USER.MEM", image)
            .expect("USER.MEM load failed");
        assert_eq!(
            actual as usize, words,
            "USER.MEM does not match this kernel build"
        );
        crate::s_print!("KERNEL: USER.MEM loaded ({} bytes)\n", actual * 4);
    }
    #[cfg(not(feature = "sd-user"))]
    crate::s_print!("KERNEL: using RTL-preloaded user image (SD loading disabled)\n");
    super::kernel_process::create_process(core::slice::from_raw_parts(shell, size));
    asm!("fence.i");
    super::kernel_process::yield_now();
    panic!("switched to idle process")
}
