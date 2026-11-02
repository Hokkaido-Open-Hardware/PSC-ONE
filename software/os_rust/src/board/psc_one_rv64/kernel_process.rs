//! kernel/kernel_process.c. Single-core scheduler; globals require serialization.
use super::{kernel::*, types::*, user_memory::*};
use core::{
    arch::{asm, naked_asm},
    ptr::{addr_of, addr_of_mut},
};
static mut PROCS: [Process; 8] = unsafe { core::mem::zeroed() };
pub static mut CURRENT: *mut Process = core::ptr::null_mut();
pub static mut IDLE: *mut Process = core::ptr::null_mut();
pub static mut PREEMPTION_TICKS: u32 = 0;
static mut PREEMPTION_ACTIVE: bool = false;
#[repr(align(16))]
pub struct InterruptStack(pub [u8; 4096]);
pub static mut MACHINE_STACK: InterruptStack = InterruptStack([0; 4096]);
// Only the shell receives these user pages. Foreground ELF roots inherit idle
// supervisor mappings, so extending syscall span checks grants no new ELF access.
unsafe fn map_inference(root: *mut u64) {
    extern "C" {
        static __model_low: u8;
        static __model_low_end: u8;
        static __model_high: u8;
        static __arena_start: u8;
    }
    let low = addr_of!(__model_low) as u32;
    let low_size = addr_of!(__model_low_end) as u32 - low;
    for offset in (0..USER_MODEL_SIZE).step_by(4096) {
        let pa = if offset < low_size {
            low + offset
        } else {
            addr_of!(__model_high) as u32 + offset - low_size
        };
        map_page(root, USER_MODEL_BASE + offset, pa, PAGE_U | PAGE_R | PAGE_W);
    }
    for offset in (0..USER_ARENA_SIZE).step_by(4096) {
        map_page(
            root,
            USER_ARENA_BASE + offset,
            addr_of!(__arena_start) as u32 + offset,
            PAGE_U | PAGE_R | PAGE_W,
        );
    }
}

/// Find a previously unused process slot; exhausted slots are a kernel invariant failure.
unsafe fn slot() -> (*mut Process, usize) {
    let base = addr_of_mut!(PROCS).cast::<Process>();
    for i in 0..8 {
        let p = base.add(i);
        if (*p).state == PROC_UNUSED {
            return (p, i);
        }
    }
    panic!("no free process slots")
}

/// Construct an S-mode resume frame with a private stack, inherited gp, and M interrupts enabled.
pub unsafe fn init_process_machine_context(p: *mut Process, entry: unsafe extern "C" fn() -> !) {
    let top = addr_of_mut!((*p).stack.0).cast::<u8>().add(8192) as u64;
    let gp: u64;
    asm!("mv {}, gp",out(reg) gp);
    (*p).context = MachineContext::default();
    (*p).context.x[2] = top;
    (*p).context.x[3] = gp;
    (*p).context.mepc = entry as *const () as u64;
    (*p).context.mstatus = (1 << 11) | (1 << 7);
    (*p).context.sscratch = top;
    (*p).context_valid = 1;
}

/// Seed the callee-saved switch frame so its first return enters the selected task.
unsafe fn initialize_stack(p: *mut Process, entry: unsafe extern "C" fn() -> !) {
    let sp = addr_of_mut!((*p).stack.0).cast::<u64>().add(1024 - 14);
    core::ptr::write_bytes(sp, 0, 14);
    *sp = entry as *const () as u64;
    (*p).sp = sp as u64;
    init_process_machine_context(p, entry);
}

/// Build a process from an in-memory image (the idle process uses an empty slice).
pub unsafe fn create_process(image: &[u8]) -> *mut Process {
    create_process_image(image, image.len(), false)
}

/// Like the C OS: read USER.MEM from SD into final allocated process pages.
pub unsafe fn create_process_from_sd(size: usize) -> *mut Process {
    assert!(size != 0, "empty USER.MEM image");
    create_process_image(&[], size, true)
}

unsafe fn create_process_image(image: &[u8], size: usize, from_sd: bool) -> *mut Process {
    let (p, i) = slot();
    initialize_stack(p, super::kernel_trap::user_entry);
    let root = alloc_pages(1) as *mut u64;
    for pa in (addr_of!(__kernel_base) as u32..addr_of!(__free_ram_end) as u32).step_by(4096) {
        map_page(root, pa, pa, PAGE_R | PAGE_W | PAGE_X);
    }
    for pa in
        (crate::board::MMIO_BASE..crate::board::MMIO_BASE + crate::board::MMIO_SIZE).step_by(4096)
    {
        map_page(root, pa, pa, PAGE_R | PAGE_W);
    }
    map_page(
        root,
        crate::board::SYNAP_DATA_BASE,
        crate::board::SYNAP_DATA_BASE,
        PAGE_R | PAGE_W,
    );
    for pa in (crate::board::SYNAP_RESULT_BASE
        ..crate::board::SYNAP_RESULT_BASE + crate::board::SYNAP_RESULT_SIZE)
        .step_by(4096)
    {
        map_page(root, pa, pa, PAGE_R | PAGE_W);
    }
    if size != 0 {
        assert!(
            size <= (USER_STACK_TOP - USER_STACK_SIZE - USER_STACK_GUARD - USER_BASE) as usize,
            "user image overlaps stack"
        );
        // Allocate one contiguous run in the kernel page pool. There is no
        // fixed physical staging address and no second image copy.
        let pages = crate::common::align_up(size, 4096) / 4096;
        let base = alloc_pages(pages);
        if from_sd {
            crate::s_print!("KERNEL: reading USER.MEM from SD into process pages\n");
            let mut sd = crate::boot::bootloader_fat32::BootSd::init().expect("SD init failed");
            let volume =
                crate::boot::boot_fat32::BootFat32::mount(&mut sd).expect("FAT32 mount failed");
            let expected = (size + 3) / 4;
            let destination = core::slice::from_raw_parts_mut(base as *mut u32, expected);
            let words = volume
                .load_mem_file_bounded(&mut sd, "USER.MEM", destination)
                .expect("USER.MEM load failed");
            assert_eq!(words as usize, expected, "USER.MEM size mismatch");
            crate::s_print!(
                "KERNEL: USER.MEM loaded ({} bytes) at {:08x}\n",
                words * 4,
                base
            );
        } else {
            crate::drivers::dma::memcpy_dma(base as *mut u8, image.as_ptr(), size);
        }
        for i in 0..pages {
            map_page(
                root,
                USER_BASE + i as u32 * 4096,
                base + i as u32 * 4096,
                PAGE_U | PAGE_R | PAGE_W | PAGE_X,
            );
        }
        for va in (USER_STACK_TOP - USER_STACK_SIZE..USER_STACK_TOP).step_by(4096) {
            let page = alloc_pages(1);
            map_page(root, va, page, PAGE_U | PAGE_R | PAGE_W);
        }
        map_inference(root);
        sync_user_code();
    }
    (*p).pid = (i + 1) as i32;
    (*p).state = PROC_RUNNABLE;
    (*p).page_table = root;
    p
}

/// Create a supervisor task that shares the idle process page table.
pub unsafe fn create_kernel_task(entry: unsafe extern "C" fn() -> !) -> *mut Process {
    let (p, i) = slot();
    core::ptr::write_bytes(p, 0, 1);
    initialize_stack(p, entry);
    (*p).pid = (i + 1) as i32;
    (*p).state = PROC_RUNNABLE;
    (*p).page_table = (*IDLE).page_table;
    p
}

/// Use an M-mode scheduling ECALL when preemption is active; otherwise switch cooperatively.
pub unsafe fn yield_now() {
    if PREEMPTION_ACTIVE {
        asm!("ecall",inout("a7") 6u32=>_);
        return;
    }
    let mut next = IDLE;
    let base = addr_of_mut!(PROCS).cast::<Process>();
    for i in 0..8 {
        let p = base.add(((*CURRENT).pid as usize + i) % 8);
        if (*p).state == PROC_RUNNABLE && (*p).pid > 0 {
            next = p;
            break;
        }
    }
    if next == CURRENT {
        return;
    }
    let prev = CURRENT;
    CURRENT = next;
    asm!("sfence.vma","csrw satp, {satp}","sfence.vma","csrw sscratch, {scratch}",satp=in(reg) super::sv39::satp((*next).page_table as u64),scratch=in(reg) addr_of_mut!((*next).stack.0).cast::<u8>().add(8192));
    switch_context(addr_of_mut!((*prev).sp), addr_of!((*next).sp));
}

/// Save the interrupted register frame and select the next runnable non-idle task.
pub unsafe fn schedule_from_machine_trap(context: &mut MachineContext) {
    PREEMPTION_TICKS = PREEMPTION_TICKS.wrapping_add(1);
    let base = addr_of_mut!(PROCS).cast::<Process>();
    let mut current_slot = 0;
    if !CURRENT.is_null() {
        (*CURRENT).context = *context;
        (*CURRENT).context_valid = 1;
        current_slot = CURRENT.offset_from(base) as usize;
    }
    let mut next = IDLE;
    for i in 1..=8 {
        let p = base.add((current_slot + i) % 8);
        if (*p).state == PROC_RUNNABLE && (*p).pid > 0 {
            next = p;
            break;
        }
    }
    if next.is_null() || next == CURRENT {
        return;
    }
    assert!((*next).context_valid != 0, "invalid process context");
    CURRENT = next;
    *context = (*next).context;
    asm!("sfence.vma","csrw satp, {}","sfence.vma",in(reg) super::sv39::satp((*next).page_table as u64));
}

/// Install the full M-mode trap entry once, using the trusted MBIOS service.
pub unsafe fn enable_machine_timer_trap() {
    static mut INSTALLED: bool = false;
    if INSTALLED {
        return;
    }
    asm!("ecall",inout("a0") super::kernel_trap::machine_trap_entry as *const () as u64=>_,inout("a1") addr_of_mut!(MACHINE_STACK.0).cast::<u8>().add(4096)=>_,inout("a7") 3u32=>_);
    INSTALLED = true;
}

/// Enable trap handling before starting the 1 ms scheduler timer.
pub unsafe fn preemption_start() {
    enable_machine_timer_trap();
    PREEMPTION_TICKS = 0;
    PREEMPTION_ACTIVE = true;
    crate::drivers::timer_api::timer_start_scheduler_tick();
}

#[unsafe(naked)]
pub unsafe extern "C" fn switch_context(_prev: *mut u64, _next: *const u64) {
    naked_asm!(
        r#"
    addi sp, sp, -112
    sd ra, 0(sp)
    sd s0, 8(sp)
    sd s1, 16(sp)
    sd s2, 24(sp)
    sd s3, 32(sp)
    sd s4, 40(sp)
    sd s5, 48(sp)
    sd s6, 56(sp)
    sd s7, 64(sp)
    sd s8, 72(sp)
    sd s9, 80(sp)
    sd s10, 88(sp)
    sd s11, 96(sp)
    sd sp, 0(a0)
    ld sp, 0(a1)
    ld ra, 0(sp)
    ld s0, 8(sp)
    ld s1, 16(sp)
    ld s2, 24(sp)
    ld s3, 32(sp)
    ld s4, 40(sp)
    ld s5, 48(sp)
    ld s6, 56(sp)
    ld s7, 64(sp)
    ld s8, 72(sp)
    ld s9, 80(sp)
    ld s10, 88(sp)
    ld s11, 96(sp)
    addi sp, sp, 112
    ret
    "#
    );
}

/// Provide the original secondary kernel task for scheduler experiments.
pub unsafe extern "C" fn shell_idle_task() -> ! {
    loop {
        crate::common::delay(1000000);
    }
}

/// Ask MBIOS to abandon the current stacks and enter the physical restart routine.
pub unsafe fn reboot() -> ! {
    asm!("ecall",inout("a0") machine_restart as *const () as u64=>_,inout("a7") 7u32=>_);
    panic!("restart service returned")
}

#[unsafe(naked)]
pub unsafe extern "C" fn machine_restart() -> ! {
    naked_asm!("csrw mie, zero","csrw mstatus, zero","csrw sie, zero","csrw sstatus, zero","csrw satp, zero","sfence.vma","la sp, __kernel_stack_top","j {finish}",finish=sym machine_restart_finish);
}

/// Drain DMA, quiesce peripherals, and reenter MBIOS after cache maintenance.
unsafe extern "C" fn machine_restart_finish() -> ! {
    use crate::common::{mmio_r32, mmio_w32};
    loop {
        let status: u32;
        asm!("csrr {}, 0x7f0",out(reg) status);
        if status & 2 == 0 {
            break;
        }
    }
    asm!("csrw 0x7e0, zero","csrw 0x7e4, zero","csrw 0x7e8, zero","csrw 0x7ec, zero","csrw 0x7c0, {reset}","csrw 0x7c0, zero","csrw 0x7c4, zero",reset=in(reg) 2u32);
    mmio_w32(crate::board::TIMER_BASE, 1 << 19);
    mmio_w32(crate::board::TIMER_BASE, (1 << 19) | (1 << 20));
    while mmio_r32(crate::board::TIMER_BASE + 0x8) & ((1 << 7) | (1 << 10)) != 0 {}
    mmio_w32(crate::board::LED_BASE, 0);
    mmio_w32(crate::board::MIC_BASE + 0x4, 1);
    while mmio_r32(crate::board::UART_BASE + 0x8) & 1 != 0 {}
    while mmio_r32(crate::board::UART_BASE + 0x8) & 2 != 0 {
        mmio_r32(crate::board::UART_BASE + 0x4);
    }
    asm!(
        "csrw mip, zero",
        "csrw medeleg, zero",
        "csrw sscratch, zero",
        "csrw sepc, zero",
        "csrw scause, zero",
        "csrw stval, zero",
        "csrw stvec, zero",
        "csrw mcause, zero",
        "csrw mtval, zero",
        "la t2, __kernel_base",
        "fence rw, rw",
        "li t0, 2",
        "csrw 0x7f0, t0",
        "csrw 0x7f0, zero",
        "lw zero, 0(t2)",
        "li t0, 1",
        "csrw 0x7f0, t0",
        "csrw 0x7f0, zero",
        "lw zero, 0(t2)",
        "fence rw, rw",
        "fence.i",
        "la a1, kernel_warm_boot",
        "li t0, 4",
        "jr t0",
        options(noreturn)
    );
}
