// synap_api.h
#pragma once

#define SA_MAT_MAX 16u

/* ============================================================
   MMIO definitions used by kernel.c
   ============================================================ */
#define PSC_SA_CTRL       0x10005000u
#define PSC_SA_DATA_BASE  0x00020000u
#define PSC_SA_DATA_WB    0x00030000u

/* Current RTL result buffer address */
#define PSC_SA_ADDR_C     0x00030000u

/* ============================================================
   SynapEngine CSR addresses
   ============================================================ */
#define CSR_SA_CTRL       0x7C0
#define CSR_SA_MODE       0x7C4
#define CSR_SA_STATUS     0x7C8
#define CSR_SA_ADDR_A     0x7D0
#define CSR_SA_ADDR_B     0x7D4
#define CSR_SA_ADDR_C     0x7D8

/* Project-local freestanding types */
typedef int bool;
typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int uint32_t;
typedef unsigned long long uint64_t;
typedef uint32_t size_t;
typedef uint32_t uintptr_t;
typedef uint32_t paddr_t;
typedef uint32_t vaddr_t;

#define true  1
#define false 0

void sa_run(
    const uint8_t *in_A,
    const uint8_t *in_B,
    uint8_t matrix_N,
    uint32_t *out_C
);

void s_call_sa_api(uint8_t matrix_N, bool verify);