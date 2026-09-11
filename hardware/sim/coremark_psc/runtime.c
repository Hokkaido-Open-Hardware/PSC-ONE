/* Glue for the existing RAM startup, PSC-OS UART and timer stopwatch.
 * The firmware starts in M mode, so install the OS trap entry directly
 * instead of calling its S-mode SBI setup service. */
#include "kernel.h"
#include "timer_api.h"

extern int main(void);

void enable_machine_timer_trap(void)
{
    uint32_t handler = (uint32_t)machine_trap_entry;
    uint32_t stack = (uint32_t)(machine_interrupt_stack + 4096);
    __asm__ __volatile__(
        "csrw mtvec, %0\n"
        "csrw mscratch, %1\n"
        "csrs mie, %2\n"
        "csrs mstatus, %3\n"
        : : "r"(handler), "r"(stack), "r"(1u << 7), "r"(1u << 3)
        : "memory");
}

/* There is no scheduler in this bare-metal image. This branch must never
 * be reached: the stopwatch owns every enabled timer interrupt. */
void schedule_from_machine_trap(struct machine_context *context)
{
    (void)context;
    s_printf("ERROR! Unexpected scheduler interrupt\n");
    for (;;) { }
}

void run(void)
{
    main();
    /* Existing chip test completion protocol. UART decoder drains separately. */
    mmio_w32(0x10001000u, 0xEE01u);
    for (;;) { }
}
