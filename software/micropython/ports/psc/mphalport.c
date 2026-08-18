#include <stdint.h>
#include <stddef.h>

#include "py/mphal.h"
#include "mphalport.h"
#include "../../../os/src/syscall.h"

static inline long psc_syscall1(long num, long arg0)
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

mp_uint_t mp_hal_stdout_tx_strn(const char *str, size_t len)
{
    for (size_t i = 0; i < len; i++) {
        psc_syscall1(SYS_PUTCHAR, (unsigned char)str[i]);
    }

    return (mp_uint_t)len;
}

int mp_hal_stdin_rx_chr(void)
{
    return (int)psc_syscall1(SYS_GETCHAR, 0);
}