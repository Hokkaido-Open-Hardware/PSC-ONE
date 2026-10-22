//! Minimal M-mode SBI in Rust naked functions; CSR entry/return requires assembly.
use core::arch::naked_asm;
#[repr(align(16))]
struct Stack {
    _bytes: [u8; 4096],
}
static mut STACK: Stack = Stack { _bytes: [0; 4096] };

#[unsafe(naked)]
#[no_mangle]
#[link_section = ".text.mbios"]
/// Address 0 is cold boot; address 4 accepts the trusted restart target in a1.
pub unsafe extern "C" fn mbios_entry() -> ! {
    naked_asm!(
        ".option norvc",
        "j 2f", "j 3f",
        "2: li a1, 0x00200000",
        "3: la sp, {stack}", "li t0, 4096", "add sp, sp, t0",
        "csrw mscratch, sp", "la t0, {trap}", "csrw mtvec, t0",
        "csrw satp, zero", "li t0, 0xb1ff", "csrw medeleg, t0",
        "li t0, 0x800", "csrw mstatus, t0", "csrw mepc, a1", "mret",
        stack = sym STACK, trap = sym trap,
    );
}

#[unsafe(naked)]
/// Save every register used here; preserve a0 as the SBI result on return.
unsafe extern "C" fn trap() -> ! {
    naked_asm!(
        ".balign 4",
        "addi sp, sp, -16",
        "sw t0, 0(sp)",
        "sw t1, 4(sp)",
        "sw t2, 8(sp)",
        "csrr t0, mcause",
        "li t1, 9",
        "bne t0, t1, 9f",
        "li t1, 7",
        "beq a7, t1, 8f",
        "li t1, 3",
        "beq a7, t1, 5f",
        "li t1, 1",
        "beq a7, t1, 2f",
        "li t1, 2",
        "beq a7, t1, 4f",
        "j 9f",
        // UART output waits for TX idle; input waits for RX available.
        "2: li t1, 0x10000000",
        "3: lw t2, 8(t1)",
        "andi t2, t2, 1",
        "bnez t2, 3b",
        "sb a0, 0(t1)",
        "li a0, 0",
        "j 6f",
        "4: li t1, 0x10000000",
        "7: lw t2, 8(t1)",
        "andi t2, t2, 2",
        "beqz t2, 7b",
        "lbu a0, 4(t1)",
        "j 6f",
        // mret copies MPIE to MIE, so setup enables both bits.
        "5: csrw mtvec, a0",
        "csrw mscratch, a1",
        "li t1, 128",
        "csrs mie, t1",
        "li t1, 136",
        "csrs mstatus, t1",
        "li a0, 0",
        "6: csrr t0, mepc",
        "addi t0, t0, 4",
        "csrw mepc, t0",
        "lw t0, 0(sp)",
        "lw t1, 4(sp)",
        "lw t2, 8(sp)",
        "addi sp, sp, 16",
        "mret",
        // The trusted restart routine installs a fresh stack; discard this frame.
        "8: jr a0",
        "9: j 9b",
    );
}
