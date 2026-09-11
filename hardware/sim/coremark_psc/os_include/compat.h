/* PSC-OS is normally built with Clang. Supply its alignment builtin's
 * equivalent for GCC; the OS sources themselves remain untouched. */
#ifndef PSC_COREMARK_OS_COMPAT_H
#define PSC_COREMARK_OS_COMPAT_H
#define __builtin_is_aligned(value, alignment) \
    (((unsigned int)(value) & ((unsigned int)(alignment) - 1u)) == 0u)
#define __builtin_align_up(value, alignment) \
    (((unsigned int)(value) + (unsigned int)(alignment) - 1u) \
     & ~((unsigned int)(alignment) - 1u))
#endif
