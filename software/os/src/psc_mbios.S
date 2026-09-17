/* ============================================================
 * PSC_OS BootROM / Minimal SBI
 *  - Boot M-mode
 *  - Jump to S-mode at 0x00200000 (kernel_main)
 *  - Provide SBI console (putchar / getchar)
 * ============================================================
 */

    .section .text
    .globl _start
    .align 4

/* ------------------------------------------------------------
 * M-mode Boot Entry
 * ------------------------------------------------------------ */
_start:
    la      sp, _mstack_top

    # mtvec = trap handler
    la      t0, m_trap_vector
    csrw    mtvec, t0

    # Disable MMU
    csrw    satp, zero

    # Delegate U-mode ECALL to S-mode
    li      t0, (1 << 8)
    csrw    medeleg, t0

    # mstatus.MPP = S-mode (01)
    csrr    t0, mstatus
    li      t1, ~(3 << 11)     # MPP mask clear
    and     t0, t0, t1
    li      t1, (1 << 11)      # MPP = S
    or      t0, t0, t1
    csrw    mstatus, t0

    # mepc = S kernel entry (0x00200000)
#ifdef USE_BOOTLOADER
    li t0, 0x00100000
#else
    li t0, 0x00200000
#endif

    csrw mepc, t0
    mret

/* ------------------------------------------------------------
 * M-mode trap handler
 * ------------------------------------------------------------ */
m_trap_vector:
    addi    sp, sp, -128
    sw      ra,   0(sp)
    sw      t0,   4(sp)
    sw      t1,   8(sp)
    sw      t2,  12(sp)
    sw      a0,  16(sp)
    sw      a1,  20(sp)
    sw      a2,  24(sp)
    sw      a3,  28(sp)
    sw      a4,  32(sp)
    sw      a5,  36(sp)
    sw      a6,  40(sp)
    sw      a7,  44(sp)

    csrr    t0, mcause
    li      t1, 9              # S-mode ECALL
    beq     t0, t1, sbi_ecall

illegal:
    j       illegal


/* ------------------------------------------------------------
 * SBI Dispatcher
 * a7 = ext (1=putchar, 2=getchar)
 * ------------------------------------------------------------ */
sbi_ecall:
    li t1, 1
    beq a7, t1, sbi_putchar

    li t1, 2
    beq a7, t1, sbi_getchar

    j illegal


/* ------------------------------------------------------------
 * UART base (0x10000000)
 * ------------------------------------------------------------ */
uart_base:
    .word 0x10000000

/* ------------------------------------------------------------
 * SBI console putchar
 * ------------------------------------------------------------ */
sbi_putchar:
    la t1, uart_base
    lw t1, 0(t1)

1:
    lw t2, 8(t1)   # UART_ST
    andi t2, t2, 1 # TX busy
    bnez t2, 1b

    sb a0, 0(t1)   # UART_TX
    li a0, 0       # return OK
    j sbi_ret

/* ------------------------------------------------------------
 * SBI console getchar
 * ------------------------------------------------------------ */
sbi_getchar:
    la t1, uart_base
    lw t1, 0(t1)

2:
    lw t2, 8(t1)    # UART_ST
    andi t2, t2, 2  # RX available
    beqz t2, 2b

    lb a0, 4(t1)    # UART_RX
    j sbi_ret

/* ------------------------------------------------------------
 * SBI return
 * ------------------------------------------------------------ */
sbi_ret:
    csrr t0, mepc
    addi t0, t0, 4
    csrw mepc, t0

    lw      ra,   0(sp)
    lw      t0,   4(sp)
    lw      t1,   8(sp)
    lw      t2,  12(sp)
    lw      a0,  16(sp)
    lw      a1,  20(sp)
    lw      a2,  24(sp)
    lw      a3,  28(sp)
    lw      a4,  32(sp)
    lw      a5,  36(sp)
    lw      a6,  40(sp)
    lw      a7,  44(sp)
    addi    sp, sp, 128

    mret


/* ------------------------------------------------------------
 * M-mode stack (4KB)
 * ------------------------------------------------------------ */
    .section .bss
    .align 4
_mstack:
    .skip 4096
_mstack_top:
