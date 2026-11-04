//! kernel/kernel_elf.c: fixed foreground-ELF pages and restoration of shell state.
use super::{elf_loader::*, kernel::*, kernel_process::*, types::*, user_memory::*};
use core::{
    arch::asm,
    ptr::{addr_of_mut, copy_nonoverlapping, write_bytes},
};
#[repr(align(4096))]
struct Table([u64; 512]);
#[repr(align(4096))]
struct Pages([[u8; 4096]; 20]);
static mut ROOT: Table = Table([0; 512]);
static mut MIDDLE: Table = Table([0; 512]);
static mut LEAF: Table = Table([0; 512]);
static mut PAGES: Pages = Pages([[0; 4096]; 20]);
static mut OWNER: *mut Process = core::ptr::null_mut();
static mut SHELL_TABLE: *mut u64 = core::ptr::null_mut();
static mut SHELL_FRAME: TrapFrame = unsafe { core::mem::zeroed() };
/// An ELF is active only in its owner process, not merely because a global owner exists.
pub unsafe fn elf_is_running() -> bool {
    !OWNER.is_null() && CURRENT == OWNER
}

/// Switch the owner page table and synchronize both address translation and instruction fetch.
unsafe fn activate(table: *mut u64) {
    (*CURRENT).page_table = table;
    super::sv39::activate(table as u64);
    asm!("fence.i");
}

/// Validate first, populate fixed ELF pages, and save the shell frame before entering user code.
pub unsafe fn elf_run(f: &mut TrapFrame) {
    if !OWNER.is_null() {
        f.a0 = Error::Busy as i64 as u64;
        return;
    }
    if f.a1 > FILE_MAX as u64 {
        f.a0 = Error::Limit as i64 as u64;
        return;
    }
    if !super::kernel_syscall::user_accessible(f.a0 as u32, f.a1 as u32, PAGE_R) {
        f.a0 = Error::Pointer as i64 as u64;
        return;
    }
    let image = core::slice::from_raw_parts(f.a0 as *const u8, f.a1 as usize);
    let plan = match psc_elf_validate(image) {
        Ok(p) => p,
        Err(e) => {
            f.a0 = e as i64 as u64;
            return;
        }
    };
    // Clone the root and its low-address middle table. Share only supervisor
    // leaf tables; the foreground ELF gets a private 4 MiB user subtree.
    let root = addr_of_mut!(ROOT.0).cast::<u64>();
    let middle = addr_of_mut!(MIDDLE.0).cast::<u64>();
    let leaf = addr_of_mut!(LEAF.0).cast::<u64>();
    let pages = addr_of_mut!(PAGES.0).cast::<u8>();
    copy_nonoverlapping((*IDLE).page_table, root, 512);
    let idle_middle = ((*root >> 10) << 12) as *const u64;
    copy_nonoverlapping(idle_middle, middle, 512);
    assert!(*middle.add((USER_BASE >> 21) as usize) & PAGE_V as u64 == 0);
    write_bytes(leaf, 0, 512);
    *root = ((middle as u64 >> 12) << 10) | PAGE_V as u64;
    *middle.add((USER_BASE >> 21) as usize) = ((leaf as u64 >> 12) << 10) | PAGE_V as u64;
    let mut index = 0;
    for s in &plan.segments[..plan.count as usize] {
        let first = s.vaddr & !4095;
        let end = (s.vaddr + s.memsz + 4095) & !4095;
        let mut flags = PAGE_U | 64 | 128;
        if s.flags & 4 != 0 {
            flags |= PAGE_R;
        }
        if s.flags & 2 != 0 {
            flags |= PAGE_W;
        }
        if s.flags & 1 != 0 {
            flags |= PAGE_X;
        }
        let destination = pages.add(index * 4096 + (s.vaddr - first) as usize);
        for va in (first..end).step_by(4096) {
            let page = pages.add(index * 4096);
            index += 1;
            write_bytes(page, 0, 4096);
            map_page(root, va, page as u32, flags);
        }
        copy_nonoverlapping(
            image.as_ptr().add(s.offset as usize),
            destination,
            s.filesz as usize,
        );
    }
    for i in 0..STACK_PAGES {
        let page = pages.add((LOAD_PAGES + i) as usize * 4096);
        write_bytes(page, 0, 4096);
        map_page(
            root,
            STACK_BOTTOM + i * 4096,
            page as u32,
            PAGE_U | PAGE_R | PAGE_W | 64 | 128,
        );
    }
    SHELL_FRAME = *f;
    SHELL_TABLE = (*CURRENT).page_table;
    OWNER = CURRENT;
    sync_user_code();
    activate(root);
    *f = TrapFrame::default();
    f.sp = USER_STACK_TOP as u64;
    f.sepc = plan.entry as u64;
    f.sstatus = 32;
}

/// Restore the exact shell trap frame and return both loader status and application exit code.
pub unsafe fn elf_finish(f: &mut TrapFrame, result: i32, exit_code: i32) {
    activate(SHELL_TABLE);
    *f = SHELL_FRAME;
    f.a0 = result as i64 as u64;
    f.a1 = exit_code as i64 as u64;
    OWNER = core::ptr::null_mut();
}
