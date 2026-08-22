#ifndef MICROPY_INCLUDED_PSC_MPHALPORT_H
#define MICROPY_INCLUDED_PSC_MPHALPORT_H

#include <stdint.h>

#include "py/mpconfig.h"


/* ------------------------------------------------------------
 * MicroPython HAL
 * ------------------------------------------------------------ */

static inline mp_uint_t mp_hal_ticks_ms(void)
{
    return 0;
}


static inline void mp_hal_set_interrupt_char(char c)
{
    (void)c;
}


/* ------------------------------------------------------------
 * PSC TIMER API
 * ------------------------------------------------------------ */

void psc_timer_start_api(uint32_t reload);

void psc_timer_start_auto_api(uint32_t reload);

void psc_timer_start_auto_irq_api(uint32_t reload);

void psc_timer_stop_api(void);

uint32_t psc_timer_get_count_api(void);

uint32_t psc_timer_get_status_api(void);

int psc_timer_is_running_api(void);

/* ------------------------------------------------------------
 * PSC TIMER WAIT API
 * ------------------------------------------------------------ */

void psc_timer_wait_us_api(uint32_t us);

void psc_timer_wait_ms_api(uint32_t ms);

#endif