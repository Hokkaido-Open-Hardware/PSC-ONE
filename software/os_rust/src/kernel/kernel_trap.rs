//! kernel/kernel_trap.c. Register-save ordering is kept identical to C.
use super::types::*;
use core::arch::naked_asm;
#[unsafe(naked)]
pub unsafe extern "C" fn machine_trap_entry() -> ! {
    naked_asm!(r#"
    .balign 4
    csrrw sp, mscratch, sp
    addi sp, sp, -160
    sw zero, 0(sp)
    sw ra, 4(sp)
    sw gp, 12(sp)
    sw tp, 16(sp)
    sw t0, 20(sp)
    sw t1, 24(sp)
    sw t2, 28(sp)
    sw s0, 32(sp)
    sw s1, 36(sp)
    sw a0, 40(sp)
    sw a1, 44(sp)
    sw a2, 48(sp)
    sw a3, 52(sp)
    sw a4, 56(sp)
    sw a5, 60(sp)
    sw a6, 64(sp)
    sw a7, 68(sp)
    sw s2, 72(sp)
    sw s3, 76(sp)
    sw s4, 80(sp)
    sw s5, 84(sp)
    sw s6, 88(sp)
    sw s7, 92(sp)
    sw s8, 96(sp)
    sw s9, 100(sp)
    sw s10, 104(sp)
    sw s11, 108(sp)
    sw t3, 112(sp)
    sw t4, 116(sp)
    sw t5, 120(sp)
    sw t6, 124(sp)
    csrr t0, mscratch
    sw t0, 8(sp)
    csrr t0, mepc
    sw t0, 128(sp)
    csrr t0, mstatus
    sw t0, 132(sp)
    csrr t0, mcause
    sw t0, 136(sp)
    csrr t0, sscratch
    sw t0, 140(sp)
    csrr t0, sepc
    sw t0, 144(sp)
    csrr t0, sstatus
    sw t0, 148(sp)
    csrr t0, scause
    sw t0, 152(sp)
    csrr t0, stval
    sw t0, 156(sp)
    mv a0, sp
    call {handler}
    lw t0, 128(sp)
    csrw mepc, t0
    lw t0, 132(sp)
    csrw mstatus, t0
    lw t0, 140(sp)
    csrw sscratch, t0
    lw t0, 144(sp)
    csrw sepc, t0
    lw t0, 148(sp)
    csrw sstatus, t0
    lw t0, 152(sp)
    csrw scause, t0
    lw t0, 156(sp)
    csrw stval, t0
    lw t0, 8(sp)
    csrw mscratch, t0
    lw ra, 4(sp)
    lw gp, 12(sp)
    lw tp, 16(sp)
    lw t0, 20(sp)
    lw t1, 24(sp)
    lw t2, 28(sp)
    lw s0, 32(sp)
    lw s1, 36(sp)
    lw a0, 40(sp)
    lw a1, 44(sp)
    lw a2, 48(sp)
    lw a3, 52(sp)
    lw a4, 56(sp)
    lw a5, 60(sp)
    lw a6, 64(sp)
    lw a7, 68(sp)
    lw s2, 72(sp)
    lw s3, 76(sp)
    lw s4, 80(sp)
    lw s5, 84(sp)
    lw s6, 88(sp)
    lw s7, 92(sp)
    lw s8, 96(sp)
    lw s9, 100(sp)
    lw s10, 104(sp)
    lw s11, 108(sp)
    lw t3, 112(sp)
    lw t4, 116(sp)
    lw t5, 120(sp)
    lw t6, 124(sp)
    addi sp, sp, 160
    csrrw sp, mscratch, sp
    mret
    "#,handler=sym handle_machine_trap);
}

/// Distinguish shared timer IRQs from supervisor ECALL services before scheduling.
unsafe extern "C" fn handle_machine_trap(c: &mut MachineContext) {
    use crate::drivers::{timer_api::*, timer_measure::*};
    if c.mcause == 0x80000007 {
        super::console::irq();
        let mask = TIMER_ST_IRQ_PENDING | TIMER_ST_IRQ_ENABLE;
        if timer_get_status() & mask != mask {
            return;
        }
        if timer_measure_irq() {
            return;
        }
        super::kernel_process::schedule_from_machine_trap(c);
        timer_clear_scheduler_irq();
        return;
    }
    if c.mcause == 9 {
        let extension = c.x[17];
        if extension == 7 {
            super::kernel_process::machine_restart();
        }
        c.mepc = c.mepc.wrapping_add(4);
        match extension {
            1 => {
                crate::common::putchar(c.x[10] as u8);
                c.x[10] = 0;
                return;
            }
            2 => {
                c.x[10] = super::kernel::uart_getchar() as u32;
                return;
            }
            6 => {
                super::kernel_process::schedule_from_machine_trap(c);
                return;
            }
            _ => {}
        }
    }
    panic!("unexpected M trap {:x}", c.mcause)
}

#[unsafe(naked)]
pub unsafe extern "C" fn user_entry() -> ! {
    naked_asm!(
        "li sp, 0x00500000",
        "li t0, 0x00400000",
        "csrw sepc, t0",
        "li t0, 32",
        "csrw sstatus, t0",
        "sret"
    );
}

#[unsafe(naked)]
pub unsafe extern "C" fn kernel_entry() -> ! {
    naked_asm!(r#"
    .balign 4
    csrrw sp, sscratch, sp
    bnez sp, 2f
    csrrw sp, sscratch, sp
2:  addi sp, sp, -144
    sw ra, 0(sp)
    sw gp, 4(sp)
    sw tp, 8(sp)
    sw t0, 12(sp)
    sw t1, 16(sp)
    sw t2, 20(sp)
    sw t3, 24(sp)
    sw t4, 28(sp)
    sw t5, 32(sp)
    sw t6, 36(sp)
    sw a0, 40(sp)
    sw a1, 44(sp)
    sw a2, 48(sp)
    sw a3, 52(sp)
    sw a4, 56(sp)
    sw a5, 60(sp)
    sw a6, 64(sp)
    sw a7, 68(sp)
    sw s0, 72(sp)
    sw s1, 76(sp)
    sw s2, 80(sp)
    sw s3, 84(sp)
    sw s4, 88(sp)
    sw s5, 92(sp)
    sw s6, 96(sp)
    sw s7, 100(sp)
    sw s8, 104(sp)
    sw s9, 108(sp)
    sw s10, 112(sp)
    sw s11, 116(sp)
    csrr a0, sstatus
    andi a0, a0, 256
    bnez a0, 3f
    csrr a0, sscratch
    j 4f
3:  addi a0, sp, 144
4:  sw a0, 120(sp)
    csrw sscratch, zero
    csrr a0, sepc
    sw a0, 124(sp)
    csrr a0, sstatus
    sw a0, 128(sp)
    csrr a0, scause
    sw a0, 132(sp)
    csrr a0, stval
    sw a0, 136(sp)
    li a0, 262144
    csrs sstatus, a0
    mv a0, sp
    call {handler}
    lw t0, 124(sp)
    csrw sepc, t0
    lw t0, 128(sp)
    csrw sstatus, t0
    andi t0, t0, 256
    bnez t0, 5f
    addi t0, sp, 144
    csrw sscratch, t0
5:  lw ra, 0(sp)
    lw gp, 4(sp)
    lw tp, 8(sp)
    lw t0, 12(sp)
    lw t1, 16(sp)
    lw t2, 20(sp)
    lw t3, 24(sp)
    lw t4, 28(sp)
    lw t5, 32(sp)
    lw t6, 36(sp)
    lw a0, 40(sp)
    lw a1, 44(sp)
    lw a2, 48(sp)
    lw a3, 52(sp)
    lw a4, 56(sp)
    lw a5, 60(sp)
    lw a6, 64(sp)
    lw a7, 68(sp)
    lw s0, 72(sp)
    lw s1, 76(sp)
    lw s2, 80(sp)
    lw s3, 84(sp)
    lw s4, 88(sp)
    lw s5, 92(sp)
    lw s6, 96(sp)
    lw s7, 100(sp)
    lw s8, 104(sp)
    lw s9, 108(sp)
    lw s10, 112(sp)
    lw s11, 116(sp)
    lw sp, 120(sp)
    sret
    "#,handler=sym handle_trap);
}

/// Advance user ECALL return PCs; terminate a faulting foreground ELF and restore its shell.
unsafe extern "C" fn handle_trap(f: &mut TrapFrame) {
    if f.scause == 8 {
        f.sepc = f.sepc.wrapping_add(4);
        super::kernel_syscall::handle_syscall(f);
        return;
    }
    if f.sstatus & 256 == 0 && f.scause & 0x80000000 == 0 && super::kernel_elf::elf_is_running() {
        super::kernel_elf::elf_finish(f, -11, f.scause as i32);
        return;
    }
    panic!(
        "unexpected S trap {:x} pc={:x} value={:x}",
        f.scause, f.sepc, f.stval
    )
}
