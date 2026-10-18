#![no_std]
#![no_main]

// PSC-ONE Sv32 translation smoke test, ported from mmu_test1.cpp.
// Build: riscv32im-unknown-none-elf, panic=abort, existing rust_tests.x.
// Start in M-mode. Requires S-mode, Sv32, Zicsr and Zifencei.
// Same success result as C++: 0x33 (NOT 0x12345678).
// This tests a valid alias mapping, not permission faults or TLB replacement.
// No initialized statics, heap, runtime startup, or BSS clearing required.
// Reserved physical RAM (must not overlap program/other allocations):
//   0x00300000 L1 root, 0x00301000 L0 identity, 0x00302000 L0 PIO,
//   0x00303000 test page, 0x00304000 L0 alias, each 4096 bytes.
// Stack top 0x003ff000, grows down within the identity-mapped first 4 MiB.
// Unlike original VA=0x1000, VA=0x00401000 cannot remap code at 0x1000.
// Program and trap handlers must be in first 4 MiB; boot image <=16 KiB.
// PIO: original progress markers; EF01/cause, EF02/epc, EF03/tval.
// EF00 indicates S trap; EF10 indicates M trap. Both handlers terminate.
// Finish: EE01 followed by 33, BAD01000, EF12/EF13/EF15, or EFFF.
// PMP setup is intentionally unchanged from C++: platform must permit S access.

use core::arch::{asm, global_asm};
use core::panic::PanicInfo;

const PIO: *mut u32 = 0x1000_1000 as *mut u32;
const L1: usize = 0x0030_0000;
const IDENTITY: usize = 0x0030_1000;
const PIO_PT: usize = 0x0030_2000;
const TEST_PAGE: usize = 0x0030_3000;
const ALIAS_PT: usize = 0x0030_4000;
const VA: usize = 0x0040_1000;
const PATTERN: u32 = 0xA5A5_A5A5;
const V: u32 = 1;
const RWAD: u32 = 1 | 2 | 4 | 64 | 128;
const RWXAD: u32 = RWAD | 8;

global_asm!(r#"
    .section .text.start,"ax",@progbits
    .option push
    .option arch, +zicsr, +zifencei
    .option norvc
    .option norelax
    .global _start
_start:
    li sp, 0x003ff000
    j rust_main
    .balign 4
    .global s_trap_entry
s_trap_entry:
    csrr a0, scause
    csrr a1, sepc
    csrr a2, stval
    li a3, 0
    tail trap_handler
    .balign 4
    .global m_trap_entry
m_trap_entry:
    csrr a0, mcause
    csrr a1, mepc
    csrr a2, mtval
    li a3, 1
    tail trap_handler
    .option pop
"#);

unsafe extern "C" {
    fn s_trap_entry();
    fn m_trap_entry();
}

macro_rules! read_csr {
    ($csr:literal) => {{
        let value: u32;
        unsafe {
            asm!(".option push", ".option arch, +zicsr",
                concat!("csrr {v}, ", $csr), ".option pop",
                v = out(reg) value, options(nostack));
        }
        value
    }};
}
macro_rules! write_csr {
    ($csr:literal, $value:expr) => {{
        let value: u32 = $value;
        unsafe {
            asm!(".option push", ".option arch, +zicsr",
                concat!("csrw ", $csr, ", {v}"), ".option pop",
                v = in(reg) value, options(nostack));
        }
    }};
}

#[inline(always)]
fn pio(v: u32) { unsafe { core::ptr::write_volatile(PIO, v); } }
#[inline(always)]
fn store(addr: usize, v: u32) {
    unsafe { core::ptr::write_volatile(addr as *mut u32, v); }
}
#[inline(always)]
fn load(addr: usize) -> u32 {
    unsafe { core::ptr::read_volatile(addr as *const u32) }
}
#[inline(always)]
fn pte(pa: usize, flags: u32) -> u32 { ((pa as u32 >> 12) << 10) | flags }
fn finish(result: u32) -> ! {
    pio(0xEE01);
    pio(result);
    loop { unsafe { asm!("j .", options(nomem, nostack)); } }
}

// Never returns: no trap-frame register save or sret/mret is necessary.
#[unsafe(no_mangle)]
pub extern "C" fn trap_handler(cause: u32, epc: u32, tval: u32, machine: u32) -> ! {
    pio(if machine == 0 { 0xEF00 } else { 0xEF10 });
    pio(0xEF01); pio(cause);
    pio(0xEF02); pio(epc);
    pio(0xEF03); pio(tval);
    finish(match cause {
        12 => 0xEF12,
        13 => 0xEF13,
        15 => 0xEF15,
        _ => 0xEFFF,
    })
}

#[unsafe(no_mangle)]
pub extern "C" fn s_mode_entry() -> ! {
    pio(0xEE61);
    // TEST_PAGE is accessed through its identity VA, not a paging bypass.
    store(TEST_PAGE, PATTERN);
    let read_back = load(VA);
    pio(0xEE08);
    finish(if read_back == PATTERN { 0x33 } else { 0xBAD01000 })
}

#[unsafe(no_mangle)]
pub extern "C" fn rust_main() -> ! {
    // Interrupts stay off throughout this standalone test.
    let mut status = read_csr!("mstatus");
    status &= !((1 << 3) | (1 << 1) | (1 << 7) | (1 << 17)); // MIE,SIE,MPIE,MPRV
    write_csr!("mstatus", status);
    write_csr!("mie", 0);
    write_csr!("mtvec", m_trap_entry as *const () as usize as u32);
    write_csr!("stvec", s_trap_entry as *const () as usize as u32);
    pio(0xEE20);
    let initial_satp = read_csr!("satp");
    pio(0xEE02); pio(initial_satp);
    write_csr!("satp", 0);
    unsafe { asm!("sfence.vma zero, zero", options(nostack)); }

    // Volatile loops avoid compiler-generated memset/runtime dependencies.
    for i in 0..1024 {
        store(L1 + i * 4, 0);
        store(IDENTITY + i * 4, 0);
        store(PIO_PT + i * 4, 0);
        store(ALIAS_PT + i * 4, 0);
    }
    store(TEST_PAGE, 0);
    pio(0xEE03);

    // First 4 MiB identity-mapped: code, tables, test data and stack.
    for i in 0..1024 { store(IDENTITY + i * 4, ((i as u32) << 10) | RWXAD); }
    store(L1, pte(IDENTITY, V));
    pio(0xEE04);

    // PIO VA=PA=0x10001000: vpn1=64, vpn0=1.
    pio(64); pio(1);
    store(L1 + 64 * 4, pte(PIO_PT, V));
    store(PIO_PT + 4, pte(PIO as usize, RWAD));
    pio(0xEE41);

    // Alias VA=0x00401000 -> PA=0x00303000: vpn1=1, vpn0=1.
    store(L1 + 4, pte(ALIAS_PT, V));
    store(ALIAS_PT + 4, pte(TEST_PAGE, RWXAD));
    pio(0xEE05);

    // Delegate S-mode page faults; other exceptions are reported by M handler.
    write_csr!("medeleg", (1 << 12) | (1 << 13) | (1 << 15));
    write_csr!("mideleg", 0);
    let satp = 0x8000_0000 | ((L1 as u32 >> 12) & 0x003F_FFFF);
    pio(0xEE06); pio(satp);
    write_csr!("satp", satp);
    unsafe {
        asm!("sfence.vma zero, zero", ".option push",
             ".option arch, +zifencei", "fence.i", ".option pop", options(nostack));
    }
    status = read_csr!("mstatus");
    status = (status & !(3 << 11)) | (1 << 11); // MPP=S
    write_csr!("mstatus", status);
    write_csr!("mepc", s_mode_entry as *const () as usize as u32);
    pio(0xEE07);
    // Abandon M-mode Rust stack frame; S entry starts with a fresh aligned stack.
    unsafe { asm!("li sp, 0x003ff000", "mret", options(noreturn)); }
}

#[panic_handler]
fn panic(_: &PanicInfo) -> ! { finish(0xEFFF) }
