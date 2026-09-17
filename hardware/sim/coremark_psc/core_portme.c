#include "coremark.h"
#include "timer_api.h"

#if VALIDATION_RUN
volatile ee_s32 seed1_volatile = 0x3415;
volatile ee_s32 seed2_volatile = 0x3415;
#else
volatile ee_s32 seed1_volatile = 0;
volatile ee_s32 seed2_volatile = 0;
#endif
volatile ee_s32 seed3_volatile = 0x66;
volatile ee_s32 seed4_volatile = ITERATIONS;
volatile ee_s32 seed5_volatile = 0;
ee_u32 default_num_contexts = 1;
static CORE_TICKS elapsed_ms;

void start_time(void)
{
    if (timer_measure_begin() != 0) {
        ee_printf("ERROR! Target timer is busy\n");
        for (;;) { }
    }
}

void stop_time(void)
{
    int ticks = timer_measure_end();
    if (ticks <= 0) {
        ee_printf("ERROR! Target timer did not advance\n");
        for (;;) { }
    }
    elapsed_ms = (CORE_TICKS)ticks;
}

CORE_TICKS get_time(void) { return elapsed_ms; }
secs_ret time_in_secs(CORE_TICKS ticks) { return ticks / 1000u; }

void portable_init(core_portable *p, int *argc, char *argv[])
{
    (void)argc;
    (void)argv;
    _Static_assert(sizeof(ee_ptr_int) == sizeof(void *), "pointer width");
    _Static_assert(sizeof(ee_u32) == 4, "32-bit integers required");
    ee_printf("PSC CoreMark: 100 MHz, MMIO timer, 1 tick = 1 ms\n");
    p->portable_id = 1;
}

void portable_fini(core_portable *p) { p->portable_id = 0; }
