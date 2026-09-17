/* The existing PSC-OS freestanding headers define their integer types in
 * common.h. GCC's stdint.h chooses long for uint32_t, while PSC-OS uses int;
 * both are 32 bits on this ABI. Use the OS definitions consistently when
 * linking its unchanged drivers with GCC. */
#ifndef COREMARK_OS_STDINT_H
#define COREMARK_OS_STDINT_H
#include "common.h"
typedef signed short int16_t;
typedef signed long long int64_t;
#endif
