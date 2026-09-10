/* JPEG total-time measurement using the existing 1us MMIO timer.
   Borrow only an idle timer; never replace a running scheduler/user timer.
   50ms IRQs extend the 16-bit counter without polling inside the decoder. */
#include "kernel.h"
#include "timer_api.h"

#define MEASURE_PERIOD_US 50000u
#define MEASURE_CTRL (*(volatile uint32_t *)0x10002000u)
#define MEASURE_RELOAD (MEASURE_PERIOD_US - 1u)
#define MEASURE_RUN (MEASURE_RELOAD | (1u << 17) | (1u << 18))
static volatile uint32_t measure_active, measure_us, measure_stopping;

int timer_measure_begin(void)
{
    if (measure_active || (timer_get_status() &
        (TIMER_ST_RUNNING | TIMER_ST_IRQ_ENABLE | TIMER_ST_IRQ_PENDING))) return -1;
    enable_machine_timer_trap();
    measure_us = 0;
    measure_stopping = 0;
    measure_active = 1;
    MEASURE_CTRL = MEASURE_RUN | (1u << 16) | (1u << 20);
    return 0;
}

int timer_measure_irq(void)
{
    if (!measure_active) return 0;
    if (timer_get_status() & TIMER_ST_IRQ_PENDING) {
        measure_us += MEASURE_PERIOD_US;
        MEASURE_CTRL = measure_stopping ? ((1u << 19) | (1u << 20))
                                        : (MEASURE_RUN | (1u << 20));
    }
    return 1;
}

int timer_measure_end(void)
{
    if (!measure_active) return -1;
    /* Stop and mask IRQ first; preserve the counter and pending status. */
    measure_stopping = 1;
    timer_stop();
    uint32_t before, after, pending, count;
    do {
        before = measure_us;
        pending = timer_get_status() & TIMER_ST_IRQ_PENDING;
        count = timer_get_count();
        after = measure_us;
    } while (before != after);
    uint32_t elapsed = before + (pending ? MEASURE_PERIOD_US : 0)
                       + MEASURE_RELOAD - count;
    MEASURE_CTRL = (1u << 19) | (1u << 20);
    while (timer_get_status() & TIMER_ST_IRQ_PENDING) { }
    measure_active = 0;
    return (int)(elapsed / 1000u);
}
