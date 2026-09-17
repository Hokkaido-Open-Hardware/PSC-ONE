#include "user.h"
#include "syscall.h"

/* Simulation-only user image.  Keep it independent of MicroPython and libc. */
static void sim_putchar(char ch)
{
    register unsigned int a0 __asm__("a0") = (unsigned char)ch;
    register unsigned int a3 __asm__("a3") = SYS_PUTCHAR;
    __asm__ __volatile__("ecall"
                         : "+r"(a0)
                         : "r"(a3)
                         : "memory");
}

void main(void)
{
    const char *message = "simulation shell start.\n";
    for (const char *p = message; *p != '\0'; ++p)
        sim_putchar(*p);
    for (;;) {
        __asm__ __volatile__("nop");
    }
}
