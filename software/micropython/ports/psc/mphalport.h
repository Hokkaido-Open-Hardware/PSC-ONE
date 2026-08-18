#ifndef MICROPY_INCLUDED_PSC_MPHALPORT_H
#define MICROPY_INCLUDED_PSC_MPHALPORT_H

#include "py/mpconfig.h"

static inline mp_uint_t mp_hal_ticks_ms(void) {
    return 0;
}

static inline void mp_hal_set_interrupt_char(char c) {
    (void)c;
}

#endif
