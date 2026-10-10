#pragma once

/* PSC-private S -> M service. a0 is a trusted, physical, non-returning
 * kernel restart entry, like service 3's trusted machine-trap entry.
 * U ECALL remains delegated to S; this does not change SYS_EXIT's ABI. */
#define PSC_SBI_RESTART 7

/* Skip only _start's cold-boot target selection, then reuse MBIOS setup.
 * Enter in M-mode, with a1 = physical S-mode warm-boot entry. */
#define PSC_MBIOS_WARM_ENTRY 4
