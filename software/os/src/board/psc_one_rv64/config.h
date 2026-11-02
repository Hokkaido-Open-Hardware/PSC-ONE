#pragma once

/* PSC_RV64 is a distinct CPU/ABI target, not the RV32 v2 implementation.
 * Add verified wiring/memory settings here when the RV64 OS port is added. */
#define PSC_BOARD_NAME         "PSC-ONE / PSC_RV64"
#define PSC_BOARD_XLEN         64
#define PSC_BOARD_OS_SUPPORTED 0
