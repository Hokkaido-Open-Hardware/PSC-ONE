#include "common.h"
#include "kernel.h"
#include "timer_api.h"

/*
 * Small supervisor-mode scheduler smoke test.
 * The normal PSC-OS image never calls this code; it is enabled only by
 * PSC_OS_DUMMY_TEST from the dedicated Makefile target.
 */
static void dummy_finish(char name)
{
    s_printf("DUMMY_%c_DONE\n", name);
    current_proc->state = PROC_EXITED;

    /* A timer IRQ must preempt this busy loop; there is no cooperative yield. */
    for (;;) {
        __asm__ __volatile__("nop");
    }
}

static struct process *dummy_process(int slot, int pid,
                                     void (*entry)(void))
{
    struct process *proc = &procs[slot];
    uint32_t *sp;

    memset(proc, 0, sizeof(*proc));
    sp = (uint32_t *)&proc->stack[sizeof(proc->stack)];
    *--sp = 0;  /* s11 */
    *--sp = 0;  /* s10 */
    *--sp = 0;  /* s9 */
    *--sp = 0;  /* s8 */
    *--sp = 0;  /* s7 */
    *--sp = 0;  /* s6 */
    *--sp = 0;  /* s5 */
    *--sp = 0;  /* s4 */
    *--sp = 0;  /* s3 */
    *--sp = 0;  /* s2 */
    *--sp = 0;  /* s1 */
    *--sp = 0;  /* s0 */
    *--sp = (uint32_t)entry;

    proc->pid = pid;
    proc->state = PROC_RUNNABLE;
    proc->sp = (uint32_t)sp;
    /* All three supervisor-only test processes use the idle page table. */
    proc->page_table = idle_proc->page_table;
    init_process_machine_context(proc, entry);
    return proc;
}

static void wait_for_next_quantum(void)
{
    uint32_t resume_tick = preemption_ticks + 2u;
    while (preemption_ticks < resume_tick) {
        __asm__ __volatile__("nop");
    }
}

void proc_a_entry(void)
{
    for (int i = 0; i < 4; ++i) {
        s_printf("DUMMY_A_%d\n", i);
        wait_for_next_quantum();
    }
    dummy_finish('A');
}

void proc_b_entry(void)
{
    for (int i = 0; i < 4; ++i) {
        s_printf("DUMMY_B_%d\n", i);
        wait_for_next_quantum();
    }
    dummy_finish('B');
}

void run_multitask_dummy_test(void)
{
    struct process *a;
    struct process *b;

    idle_proc = create_process(NULL, 0);
    idle_proc->pid = 0;
    current_proc = idle_proc;

    /* Avoid three full VM construction passes; this test targets yield(). */
    a = dummy_process(1, 2, proc_a_entry);
    b = dummy_process(2, 3, proc_b_entry);
    (void)a;
    (void)b;

    s_printf("DUMMY_TEST_START\n");
    preemption_start();

    /* The first timer IRQ starts A; this idle loop is itself preempted. */
    while (a->state != PROC_EXITED || b->state != PROC_EXITED) {
        __asm__ __volatile__("nop");
    }

    timer_stop();
    s_printf("DUMMY_TIMER_DONE ticks=%d\n", (int)preemption_ticks);

    for (;;) {
        __asm__ __volatile__("nop");
    }
}
