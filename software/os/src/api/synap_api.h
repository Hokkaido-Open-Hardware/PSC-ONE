// synap_api.h
#pragma once

#include "sa_limits.h"

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
#define CSR_SA_SIZE       0x7C4
#define CSR_SA_STATUS     0x7C8
#define CSR_SA_ADDR_A     0x7D0
#define CSR_SA_ADDR_B     0x7D4
#define CSR_SA_ADDR_C     0x7D8

/* CTRL: start[0], state reset[1], clear[2], signed[3], OS mode[4],
   instruction[11:8] (0 for matrix multiplication).
   SIZE: X/K[7:0], Y/N[15:8], M[23:16]; A[M][K] * B[K][N] = C[M][N].
   The square-matrix API programs X=Y=M=matrix_N explicitly. */

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
    uint32_t *out_C,
    bool signed_mode
);
/* Status-returning variant: 0 success, -1 arguments, -2 timeout, -3 busy.
   Legacy sa_run remains source compatible. Output is untouched on failure. */
int sa_run_checked(const uint8_t *in_A, const uint8_t *in_B,
                   uint8_t matrix_N, uint32_t *out_C, bool signed_mode);

/* A[m][k] * B[k][n] = C[m][n]. m: 1..SA_MAT_MAX;
   k/n: nonzero multiples of four up to SA_MAT_MAX. Same status codes. */
int sa_run_rect_checked(const uint8_t *a, const uint8_t *b,
                        uint32_t m, uint32_t k, uint32_t n,
                        uint32_t *c, bool signed_mode);

void s_call_sa_api(
    uint8_t matrix_N,
    bool verify,
    bool signed_mode)
;
