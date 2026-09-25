#ifndef PSC_ELF_APPS_SYSCALL_HPP
#define PSC_ELF_APPS_SYSCALL_HPP

#include "kernel/syscall.h"

namespace psc {

// PSC-OS uses a3 for the syscall number and a0 for the argument/result.
// Match tests/elf/hello.c; the kernel trap frame preserves other registers.
inline void putchar(char value)
{
    register unsigned int a0 __asm__("a0") = static_cast<unsigned char>(value);
    register unsigned int a3 __asm__("a3") = SYS_PUTCHAR;
    __asm__ volatile("ecall" : "+r"(a0) : "r"(a3) : "memory");
}

inline void print(const char *text)
{
    while (*text) putchar(*text++);
}

inline void print_int(int value)
{
    register int a0 __asm__("a0") = value;
    register unsigned int a3 __asm__("a3") = SYS_PRINT_INT;
    __asm__ volatile("ecall" : "+r"(a0) : "r"(a3) : "memory");
}

} // namespace psc

#endif
