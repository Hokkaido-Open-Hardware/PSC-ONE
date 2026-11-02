#pragma once

/* Host tests and the existing RV32 builds default to PSC-ONE / PSC_RV32.
 * Makefile selects the profile explicitly; an RV64 compiler must not silently
 * use the RV32 board profile. Keep this header usable by assembly too. */
#if defined(PSC_BOARD_PSC_ONE) && defined(PSC_BOARD_PSC_ONE_RV64)
#error "Select only one PSC board"
#endif
#if defined(PSC_BOARD_PSC_ONE_RV64) || \
    (!defined(PSC_BOARD_PSC_ONE) && defined(__riscv_xlen) && __riscv_xlen == 64)
#include "psc_one_rv64/config.h"
#else
#include "psc_one/config.h"
#endif

#if defined(__riscv_xlen) && __riscv_xlen != PSC_BOARD_XLEN
#error "Selected board does not match the RISC-V compiler XLEN"
#endif
#if !PSC_BOARD_OS_SUPPORTED
#error "PSC-OS for PSC_RV64 is not implemented yet"
#endif
