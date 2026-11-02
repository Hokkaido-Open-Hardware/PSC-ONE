//! kernel/kernel_trap.c. Register-save ordering is kept identical to C.
use super::types::*;
use core::arch::naked_asm;
#[unsafe(naked)]
pub unsafe extern "C" fn machine_trap_entry() -> ! {
    naked_asm!(r#"
    .balign 4
    csrrw sp, mscratch, sp
    addi sp, sp, -320
    sd zero, 0(sp)
    sd ra, 8(sp)
    sd gp, 24(sp)
    sd tp, 32(sp)
    sd t0, 40(sp)
    sd t1, 48(sp)
    sd t2, 56(sp)
    sd s0, 64(sp)
    sd s1, 72(sp)
    sd a0, 80(sp)
    sd a1, 88(sp)
    sd a2, 96(sp)
    sd a3, 104(sp)
    sd a4, 112(sp)
    sd a5, 120(sp)
    sd a6, 128(sp)
    sd a7, 136(sp)
    sd s2, 144(sp)
    sd s3, 152(sp)
    sd s4, 160(sp)
    sd s5, 168(sp)
    sd s6, 176(sp)
    sd s7, 184(sp)
    sd s8, 192(sp)
    sd s9, 200(sp)
    sd s10, 208(sp)
    sd s11, 216(sp)
    sd t3, 224(sp)
    sd t4, 232(sp)
    sd t5, 240(sp)
    sd t6, 248(sp)
    csrr t0, mscratch
    sd t0, 16(sp)
    csrr t0, mepc
    sd t0, 256(sp)
    csrr t0, mstatus
    sd t0, 264(sp)
    csrr t0, mcause
    sd t0, 272(sp)
    csrr t0, sscratch
    sd t0, 280(sp)
    csrr t0, sepc
    sd t0, 288(sp)
    csrr t0, sstatus
    sd t0, 296(sp)
    csrr t0, scause
    sd t0, 304(sp)
    csrr t0, stval
    sd t0, 312(sp)
    mv a0, sp
    call {handler}
    ld t0, 256(sp)
    csrw mepc, t0
    ld t0, 264(sp)
    csrw mstatus, t0
    ld t0, 280(sp)
    csrw sscratch, t0
    ld t0, 288(sp)
    csrw sepc, t0
    ld t0, 296(sp)
    csrw sstatus, t0
    ld t0, 304(sp)
    csrw scause, t0
    ld t0, 312(sp)
    csrw stval, t0
    ld t0, 16(sp)
    csrw mscratch, t0
    ld ra, 8(sp)
    ld gp, 24(sp)
    ld tp, 32(sp)
    ld t0, 40(sp)
    ld t1, 48(sp)
    ld t2, 56(sp)
    ld s0, 64(sp)
    ld s1, 72(sp)
    ld a0, 80(sp)
    ld a1, 88(sp)
    ld a2, 96(sp)
    ld a3, 104(sp)
    ld a4, 112(sp)
    ld a5, 120(sp)
    ld a6, 128(sp)
    ld a7, 136(sp)
    ld s2, 144(sp)
    ld s3, 152(sp)
    ld s4, 160(sp)
    ld s5, 168(sp)
    ld s6, 176(sp)
    ld s7, 184(sp)
    ld s8, 192(sp)
    ld s9, 200(sp)
    ld s10, 208(sp)
    ld s11, 216(sp)
    ld t3, 224(sp)
    ld t4, 232(sp)
    ld t5, 240(sp)
    ld t6, 248(sp)
    addi sp, sp, 320
    csrrw sp, mscratch, sp
    mret
    "#,handler=sym handle_machine_trap);
}

/// Distinguish shared timer IRQs from supervisor ECALL services before scheduling.
unsafe extern "C" fn handle_machine_trap(c: &mut MachineContext) {
    use crate::drivers::{timer_api::*, timer_measure::*};
    if c.mcause == 0x8000000000000007 {
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
                c.x[10] = super::kernel::uart_getchar() as i64 as u64;
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
        "li sp, {stack}",
        "li t0, {user}",
        "csrw sepc, t0",
        "li t0, 32",
        "csrw sstatus, t0",
        "sret",
        stack = const crate::board::USER_STACK_TOP,
        user = const crate::board::USER_BASE,
    );
}

#[unsafe(naked)]
pub unsafe extern "C" fn kernel_entry() -> ! {
    naked_asm!(r#"
    .balign 4
    csrrw sp, sscratch, sp
    bnez sp, 2f
    csrrw sp, sscratch, sp
2:  addi sp, sp, -288
    sd ra, 0(sp)
    sd gp, 8(sp)
    sd tp, 16(sp)
    sd t0, 24(sp)
    sd t1, 32(sp)
    sd t2, 40(sp)
    sd t3, 48(sp)
    sd t4, 56(sp)
    sd t5, 64(sp)
    sd t6, 72(sp)
    sd a0, 80(sp)
    sd a1, 88(sp)
    sd a2, 96(sp)
    sd a3, 104(sp)
    sd a4, 112(sp)
    sd a5, 120(sp)
    sd a6, 128(sp)
    sd a7, 136(sp)
    sd s0, 144(sp)
    sd s1, 152(sp)
    sd s2, 160(sp)
    sd s3, 168(sp)
    sd s4, 176(sp)
    sd s5, 184(sp)
    sd s6, 192(sp)
    sd s7, 200(sp)
    sd s8, 208(sp)
    sd s9, 216(sp)
    sd s10, 224(sp)
    sd s11, 232(sp)
    csrr a0, sstatus
    andi a0, a0, 256
    bnez a0, 3f
    csrr a0, sscratch
    j 4f
3:  addi a0, sp, 288
4:  sd a0, 240(sp)
    csrw sscratch, zero
    csrr a0, sepc
    sd a0, 248(sp)
    csrr a0, sstatus
    sd a0, 256(sp)
    csrr a0, scause
    sd a0, 264(sp)
    csrr a0, stval
    sd a0, 272(sp)
    li a0, 262144
    csrs sstatus, a0
    mv a0, sp
    call {handler}
    ld t0, 248(sp)
    csrw sepc, t0
    ld t0, 256(sp)
    csrw sstatus, t0
    andi t0, t0, 256
    bnez t0, 5f
    addi t0, sp, 288
    csrw sscratch, t0
5:  ld ra, 0(sp)
    ld gp, 8(sp)
    ld tp, 16(sp)
    ld t0, 24(sp)
    ld t1, 32(sp)
    ld t2, 40(sp)
    ld t3, 48(sp)
    ld t4, 56(sp)
    ld t5, 64(sp)
    ld t6, 72(sp)
    ld a0, 80(sp)
    ld a1, 88(sp)
    ld a2, 96(sp)
    ld a3, 104(sp)
    ld a4, 112(sp)
    ld a5, 120(sp)
    ld a6, 128(sp)
    ld a7, 136(sp)
    ld s0, 144(sp)
    ld s1, 152(sp)
    ld s2, 160(sp)
    ld s3, 168(sp)
    ld s4, 176(sp)
    ld s5, 184(sp)
    ld s6, 192(sp)
    ld s7, 200(sp)
    ld s8, 208(sp)
    ld s9, 216(sp)
    ld s10, 224(sp)
    ld s11, 232(sp)
    ld sp, 240(sp)
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
    if f.sstatus & 256 == 0
        && f.scause & 0x8000000000000000 == 0
        && super::kernel_elf::elf_is_running()
    {
        super::kernel_elf::elf_finish(f, -11, f.scause as i32);
        return;
    }
    panic!(
        "unexpected S trap {:x} pc={:x} value={:x}",
        f.scause, f.sepc, f.stval
    )
}
