#include "common.h"
#include "kernel.h"
#include "timer_api.h"

#define MACHINE_CONTEXT_SIZE 144

uint8_t machine_interrupt_stack[4096] __attribute__((aligned(16)));

_Static_assert(sizeof(struct machine_context) == MACHINE_CONTEXT_SIZE,
               "machine context assembly layout mismatch");

/*
 * All integer registers are captured before C code runs.  mscratch contains
 * the dedicated M-mode stack top while S/U code is executing; swapping it
 * with sp preserves the interrupted task's stack even for a user-mode IRQ.
 */
__attribute__((naked, aligned(4)))
void machine_trap_entry(void) {
    __asm__ __volatile__(
        "csrrw sp, mscratch, sp\n"
        "addi sp, sp, -144\n"
        "sw zero,   0(sp)\n"
        "sw ra,     4(sp)\n"
        "sw gp,    12(sp)\n"
        "sw tp,    16(sp)\n"
        "sw t0,    20(sp)\n"
        "sw t1,    24(sp)\n"
        "sw t2,    28(sp)\n"
        "sw s0,    32(sp)\n"
        "sw s1,    36(sp)\n"
        "sw a0,    40(sp)\n"
        "sw a1,    44(sp)\n"
        "sw a2,    48(sp)\n"
        "sw a3,    52(sp)\n"
        "sw a4,    56(sp)\n"
        "sw a5,    60(sp)\n"
        "sw a6,    64(sp)\n"
        "sw a7,    68(sp)\n"
        "sw s2,    72(sp)\n"
        "sw s3,    76(sp)\n"
        "sw s4,    80(sp)\n"
        "sw s5,    84(sp)\n"
        "sw s6,    88(sp)\n"
        "sw s7,    92(sp)\n"
        "sw s8,    96(sp)\n"
        "sw s9,   100(sp)\n"
        "sw s10,  104(sp)\n"
        "sw s11,  108(sp)\n"
        "sw t3,   112(sp)\n"
        "sw t4,   116(sp)\n"
        "sw t5,   120(sp)\n"
        "sw t6,   124(sp)\n"
        "csrr t0, mscratch\n"
        "sw t0,     8(sp)\n"
        "csrr t0, mepc\n"
        "sw t0,   128(sp)\n"
        "csrr t0, mstatus\n"
        "sw t0,   132(sp)\n"
        "csrr t0, mcause\n"
        "sw t0,   136(sp)\n"
        "sw zero, 140(sp)\n"
        "mv a0, sp\n"
        "call handle_machine_trap\n"
        "lw t0,   128(sp)\n"
        "csrw mepc, t0\n"
        "lw t0,   132(sp)\n"
        "csrw mstatus, t0\n"
        "lw t0,     8(sp)\n"
        "csrw mscratch, t0\n"
        "lw ra,     4(sp)\n"
        "lw gp,    12(sp)\n"
        "lw tp,    16(sp)\n"
        "lw t0,    20(sp)\n"
        "lw t1,    24(sp)\n"
        "lw t2,    28(sp)\n"
        "lw s0,    32(sp)\n"
        "lw s1,    36(sp)\n"
        "lw a0,    40(sp)\n"
        "lw a1,    44(sp)\n"
        "lw a2,    48(sp)\n"
        "lw a3,    52(sp)\n"
        "lw a4,    56(sp)\n"
        "lw a5,    60(sp)\n"
        "lw a6,    64(sp)\n"
        "lw a7,    68(sp)\n"
        "lw s2,    72(sp)\n"
        "lw s3,    76(sp)\n"
        "lw s4,    80(sp)\n"
        "lw s5,    84(sp)\n"
        "lw s6,    88(sp)\n"
        "lw s7,    92(sp)\n"
        "lw s8,    96(sp)\n"
        "lw s9,   100(sp)\n"
        "lw s10,  104(sp)\n"
        "lw s11,  108(sp)\n"
        "lw t3,   112(sp)\n"
        "lw t4,   116(sp)\n"
        "lw t5,   120(sp)\n"
        "lw t6,   124(sp)\n"
        "addi sp, sp, 144\n"
        "csrrw sp, mscratch, sp\n"
        "mret\n"
    );
}

__attribute__((used)) void handle_machine_trap(struct machine_context *context)
{
    if (context->mcause == MCAUSE_TIMER_IRQ) {
        schedule_from_machine_trap(context);
        timer_clear_scheduler_irq();
        return;
    }

    if (context->mcause == MCAUSE_ECALL_S) {
        uint32_t extension = context->x[17]; /* a7 */

        /* An ECALL is synchronous: resume at the following instruction. */
        context->mepc += 4u;
        if (extension == 1u) {
            uart_putchar((char)context->x[10]);
            context->x[10] = 0u;
            return;
        }
        if (extension == 2u) {
            context->x[10] = (uint32_t)uart_getchar();
            return;
        }
        if (extension == 6u) {
            schedule_from_machine_trap(context);
            return;
        }
    }

    s_printf("UNEXPECTED_M_TRAP cause=%x mepc=%x mstatus=%x\n",
             context->mcause, context->mepc, context->mstatus);
    for (;;) {
        __asm__ __volatile__("nop");
    }
}

__attribute__((naked)) void user_entry(void) {
    __asm__ __volatile__(
        "mv sp, %[user_sp]\n"
        "csrw sepc, %[entry]\n"
        "li   t0, (1 << 5)\n"
        "csrw sstatus, t0\n"
        "sret\n"
        :
        : [user_sp] "r" (USER_STACK_TOP),
          [entry]   "r" (USER_BASE)
        : "t0", "memory"
    );
}

__attribute__((naked))
__attribute__((aligned(4)))
void kernel_entry(void) {
    __asm__ __volatile__(
        "csrw sscratch, sp\n"
        "addi sp, sp, -4 * 31\n"
        "nop\n"
        "sw ra,  4 * 0(sp)\n"
        "sw gp,  4 * 1(sp)\n"
        "sw tp,  4 * 2(sp)\n"
        "sw t0,  4 * 3(sp)\n"
        "sw t1,  4 * 4(sp)\n"
        "sw t2,  4 * 5(sp)\n"
        "sw t3,  4 * 6(sp)\n"
        "sw t4,  4 * 7(sp)\n"
        "sw t5,  4 * 8(sp)\n"
        "sw t6,  4 * 9(sp)\n"
        "sw a0,  4 * 10(sp)\n"
        "sw a1,  4 * 11(sp)\n"
        "sw a2,  4 * 12(sp)\n"
        "sw a3,  4 * 13(sp)\n"
        "sw a4,  4 * 14(sp)\n"
        "sw a5,  4 * 15(sp)\n"
        "sw a6,  4 * 16(sp)\n"
        "sw a7,  4 * 17(sp)\n"
        "sw s0,  4 * 18(sp)\n"
        "sw s1,  4 * 19(sp)\n"
        "sw s2,  4 * 20(sp)\n"
        "sw s3,  4 * 21(sp)\n"
        "sw s4,  4 * 22(sp)\n"
        "sw s5,  4 * 23(sp)\n"
        "sw s6,  4 * 24(sp)\n"
        "sw s7,  4 * 25(sp)\n"
        "sw s8,  4 * 26(sp)\n"
        "sw s9,  4 * 27(sp)\n"
        "sw s10, 4 * 28(sp)\n"
        "sw s11, 4 * 29(sp)\n"
        "csrr a0, sscratch\n"
        "sw a0, 4 * 30(sp)\n"
        "mv a0, sp\n"
        "call handle_trap\n"
        "lw ra,  4 * 0(sp)\n"
        "lw gp,  4 * 1(sp)\n"
        "lw tp,  4 * 2(sp)\n"
        "lw t0,  4 * 3(sp)\n"
        "lw t1,  4 * 4(sp)\n"
        "lw t2,  4 * 5(sp)\n"
        "lw t3,  4 * 6(sp)\n"
        "lw t4,  4 * 7(sp)\n"
        "lw t5,  4 * 8(sp)\n"
        "lw t6,  4 * 9(sp)\n"
        "lw a0,  4 * 10(sp)\n"
        "lw a1,  4 * 11(sp)\n"
        "lw a2,  4 * 12(sp)\n"
        "lw a3,  4 * 13(sp)\n"
        "lw a4,  4 * 14(sp)\n"
        "lw a5,  4 * 15(sp)\n"
        "lw a6,  4 * 16(sp)\n"
        "lw a7,  4 * 17(sp)\n"
        "lw s0,  4 * 18(sp)\n"
        "lw s1,  4 * 19(sp)\n"
        "lw s2,  4 * 20(sp)\n"
        "lw s3,  4 * 21(sp)\n"
        "lw s4,  4 * 22(sp)\n"
        "lw s5,  4 * 23(sp)\n"
        "lw s6,  4 * 24(sp)\n"
        "lw s7,  4 * 25(sp)\n"
        "lw s8,  4 * 26(sp)\n"
        "lw s9,  4 * 27(sp)\n"
        "lw s10, 4 * 28(sp)\n"
        "lw s11, 4 * 29(sp)\n"
        "lw sp,  4 * 30(sp)\n"
        "sret\n"
    );
}

__attribute__((used)) void handle_trap(struct trap_frame *f)
{
    uint32_t scause = READ_CSR(scause);
    uint32_t stval  = READ_CSR(stval);
    uint32_t sepc   = READ_CSR(sepc);
    uint32_t sstatus = READ_CSR(sstatus);

    if (scause == SCAUSE_ECALL) {
        handle_syscall(f);
        sepc += 4;
        WRITE_CSR(sepc, sepc);
        return;
    }

    if (scause == SCAUSE_INST_MISALIGNED) {
        PANIC("PC misaligned sepc=%x stval=%x sstatus=%x\n",
              sepc, stval, sstatus);
    }

    /* Future timer/external interrupt dispatch belongs here. */
    PANIC("unexpected trap scause=%x stval=%x sepc=%x\n",
          scause, stval, sepc);
}
