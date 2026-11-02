//! kernel/kernel.c: console, physical allocator, Sv39 mappings and startup.
use crate::common::*;
use core::arch::asm;
// Match kernel.c: initialize the LCD without drawing the boot logo by default.
const PSC_LOGOMODE: bool = false;
extern "C" {
    pub static __free_ram: u8;
    pub static __free_ram_end: u8;
    pub static __kernel_base: u8;
    static mut __bss: u8;
    static mut __bss_end: u8;
    static mut __data: u8;
    static mut __data_end: u8;
    static mut __data_initial: u8;
    static __shell_image_size: u8;
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

/// Install a 4 KiB Sv39 leaf; the allocator zeroes intermediate tables.
pub unsafe fn map_page(root: *mut u64, va: u32, pa: u32, flags: u32) {
    super::sv39::map_page(root, va as u64, pa as u64, flags as u64, || {
        alloc_pages(1) as *mut u64
    });
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
        if mmio_r32(crate::board::UART_BASE + 8) & 2 != 0 {
            return (mmio_r32(crate::board::UART_BASE + 4) & 255) as i32;
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
    asm!("csrw stvec, {}",in(reg) super::kernel_trap::kernel_entry as *const () as usize);
    if PSC_LOGOMODE {
        crate::s_print!("Draw PSC Logo\n");
        crate::drivers::lcd_api::lcd_draw_boot_logo();
    } else {
        crate::s_print!("tft init\n");
        crate::drivers::lcd_api::tft_init_seq(crate::drivers::lcd_api::AFTER_WAIT);
    }
    crate::s_print!(
        concat!(
            "PSC_OS Boot Start.........\n",
            "--- memset done ---\n",
            "Test Ver: test_1.8.0\n",
            "\n",
            "  PSC-ONE / PSC-OS\n",
            "  RISC-V Operating System\n",
            "  --------------------------------------------------\n",
            "  Build     PSC-OS Rust {}\n",
            "  CPU       PSC_RV64 / Sv39 MMU\n",
            "  Console   SBI or MMIO UART\n",
            "\n",
            "  SYSTEM    hello, primes, dump\n",
            "  COMPUTE   sa_start, speech\n",
            "  ROBOT     robot_control\n",
            "  STORAGE   sd_read, sd_write\n",
            "  AUDIO     mic_read, mic_write\n",
            "  FILES     fat32_info, fat32_ls, fat32_cat,\n",
            "            fat32_touch\n",
            "  RUNTIME   run (.ELF)\n",
            "\n",
            "  QEMU exit        : Ctrl+A, C -> q\n",
            "  --------------------------------------------------\n",
            "\n",
        ),
        env!("CARGO_PKG_VERSION")
    );
    #[cfg(feature = "micropython")]
    crate::s_print!(
        "  MicroPython: microPython / micropython; reset Ctrl+D; exit import psc; psc.exit()\n"
    );
    // The idle page table provides the supervisor-only template for foreground ELFs.
    let idle = super::kernel_process::create_process(&[]);
    (*idle).pid = 0;
    super::kernel_process::IDLE = idle;
    super::kernel_process::CURRENT = idle;
    let size = core::ptr::addr_of!(__shell_image_size) as usize;
    super::kernel_process::create_process_from_sd(size);
    asm!("fence.i");
    super::kernel_process::yield_now();
    panic!("switched to idle process")
}
