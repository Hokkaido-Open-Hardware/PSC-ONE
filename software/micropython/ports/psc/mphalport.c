#include <stdint.h>
#include <stddef.h>

#include "py/mphal.h"
#include "mphalport.h"
#include "../../../os/src/syscall.h"


/* ------------------------------------------------------------
 * PSC syscall
 * ------------------------------------------------------------ */

static inline long psc_syscall1(
    long num,
    long arg0
)
{
    register long a0 __asm__("a0") = arg0;
    register long a3 __asm__("a3") = num;

    __asm__ volatile (
        "ecall"
        : "+r"(a0)
        : "r"(a3)
        : "memory"
    );

    return a0;
}


/* ------------------------------------------------------------
 * UART
 * ------------------------------------------------------------ */

mp_uint_t mp_hal_stdout_tx_strn(
    const char *str,
    size_t len
)
{
    for (size_t i = 0; i < len; i++) {
        psc_syscall1(
            SYS_PUTCHAR,
            (unsigned char)str[i]
        );
    }

    return (mp_uint_t)len;
}


int mp_hal_stdin_rx_chr(void)
{
    return (int)psc_syscall1(
        SYS_GETCHAR,
        0
    );
}


/* ------------------------------------------------------------
 * TIMER API
 * ------------------------------------------------------------ */

void psc_timer_start_api(uint32_t reload)
{
    (void)psc_syscall1(
        SYS_TIMER_START,
        (long)reload
    );
}


void psc_timer_start_auto_api(uint32_t reload)
{
    (void)psc_syscall1(
        SYS_TIMER_START_AUTO,
        (long)reload
    );
}


void psc_timer_stop_api(void)
{
    (void)psc_syscall1(
        SYS_TIMER_STOP,
        0
    );
}


uint32_t psc_timer_get_count_api(void)
{
    return (uint32_t)psc_syscall1(
        SYS_TIMER_GET_COUNT,
        0
    );
}


uint32_t psc_timer_get_status_api(void)
{
    return (uint32_t)psc_syscall1(
        SYS_TIMER_GET_STATUS,
        0
    );
}


int psc_timer_is_running_api(void)
{
    return (int)psc_syscall1(
        SYS_TIMER_IS_RUNNING,
        0
    );
}


void psc_timer_wait_us_api(uint32_t us)
{
    (void)psc_syscall1(
        SYS_TIMER_WAIT_US,
        (long)us
    );
}


void psc_timer_wait_ms_api(uint32_t ms)
{
    (void)psc_syscall1(
        SYS_TIMER_WAIT_MS,
        (long)ms
    );
}
