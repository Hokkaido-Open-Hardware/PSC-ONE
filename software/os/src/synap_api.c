#include "synap_api.h"
#include "kernel.h"
#include "common.h"

#ifndef SA_DEBUG
#define SA_DEBUG 0
#endif

#if SA_DEBUG
#define SA_LOG(...) s_printf(__VA_ARGS__)
#else
#define SA_LOG(...) ((void)0)
#endif

/* ============================================================
   CSR helpers
   ============================================================ */
#define STRINGIFY_INNER(x) #x
#define STRINGIFY(x) STRINGIFY_INNER(x)

#define CSR_WRITE(csr, val)                           \
    do {                                              \
        const uint32_t csr_value_ = (uint32_t)(val); \
        __asm__ volatile (                            \
            "csrw " STRINGIFY(csr) ", %0"            \
            :                                         \
            : "r"(csr_value_)                         \
            : "memory"                                \
        );                                            \
    } while (0)

#define CSR_READ(csr)                                 \
    ({                                                \
        uint32_t csr_value_;                          \
        __asm__ volatile (                            \
            "csrr %0, " STRINGIFY(csr)                \
            : "=r"(csr_value_)                        \
            :                                         \
            : "memory"                                \
        );                                            \
        csr_value_;                                   \
    })

/* ============================================================
   SynapEngine execution

   A/B are tightly packed matrix_N x matrix_N arrays.
   RTL performs all 4x4 tiling internally.
   C is returned as a tightly packed matrix_N x matrix_N array.
   ============================================================ */
#ifndef SA_DEBUG
#define SA_DEBUG 0
#endif

#if SA_DEBUG
#define SA_LOG(...) s_printf(__VA_ARGS__)
#else
#define SA_LOG(...) ((void)0)
#endif

void sa_run(
    const uint8_t *in_A,
    const uint8_t *in_B,
    uint8_t matrix_N,
    uint32_t *out_C)
{
    const uint32_t config =
        ((uint32_t)matrix_N << 24) |
        ((uint32_t)matrix_N << 16);

    volatile const uint32_t *const result =
        (volatile const uint32_t *)(uintptr_t)PSC_SA_ADDR_C;

    SA_LOG(
        "SA A=%x B=%x C=%x N=%d\n",
        (uint32_t)(uintptr_t)in_A,
        (uint32_t)(uintptr_t)in_B,
        (uint32_t)PSC_SA_ADDR_C,
        (int)matrix_N
    );

    CSR_WRITE(
        CSR_SA_ADDR_A,
        (uint32_t)(uintptr_t)in_A
    );

    CSR_WRITE(
        CSR_SA_ADDR_B,
        (uint32_t)(uintptr_t)in_B
    );

    CSR_WRITE(
        CSR_SA_ADDR_C,
        PSC_SA_ADDR_C
    );

    __asm__ volatile("fence rw, rw" ::: "memory");

    SA_LOG(
        "SA status initial=%x\n",
        CSR_READ(CSR_SA_STATUS)
    );

    CSR_WRITE(CSR_SA_CTRL, config | 0x02u);
    CSR_WRITE(CSR_SA_CTRL, config);

    SA_LOG(
        "SA status reset=%x\n",
        CSR_READ(CSR_SA_STATUS)
    );

    CSR_WRITE(CSR_SA_CTRL, config | 0x04u);
    CSR_WRITE(CSR_SA_CTRL, config);

    SA_LOG(
        "SA status clear=%x\n",
        CSR_READ(CSR_SA_STATUS)
    );

    CSR_WRITE(CSR_SA_CTRL, config | 0x01u);

    SA_LOG(
        "SA started ctrl=%x status=%x\n",
        config | 0x01u,
        CSR_READ(CSR_SA_STATUS)
    );

    uint32_t timeout = 10000000u;

    while ((CSR_READ(CSR_SA_STATUS) & 0x01u) == 0u) {
        if (--timeout == 0u) {
            SA_LOG(
                "SA TIMEOUT status=%x\n",
                CSR_READ(CSR_SA_STATUS)
            );

            CSR_WRITE(CSR_SA_CTRL, config);
            return;
        }

        __asm__ volatile("nop");
    }

    SA_LOG(
        "SA DONE status=%x\n",
        CSR_READ(CSR_SA_STATUS)
    );

    CSR_WRITE(CSR_SA_CTRL, config);

    __asm__ volatile("fence rw, rw" ::: "memory");

    const uint32_t count =
        (uint32_t)matrix_N *
        (uint32_t)matrix_N;

    for (uint32_t index = 0u;
         index < count;
         ++index) {

#if SA_DEBUG
        SA_LOG(
            "COPY index=%d src=%x dst=%x\n",
            (int)index,
            (uint32_t)(uintptr_t)&result[index],
            (uint32_t)(uintptr_t)&out_C[index]
        );
#endif

        out_C[index] = result[index];
    }

    SA_LOG("SA run complete\n");
}

/* ============================================================
   Test data generator
   ============================================================ */
static uint32_t lfsr;

static uint32_t rand32(void)
{
    if (lfsr == 0u) {
        lfsr = 143253719u;
    }

    lfsr ^= lfsr << 13;
    lfsr ^= lfsr >> 17;
    lfsr ^= lfsr << 5;
    return lfsr;
}

/* ============================================================
   Public test entry
   ============================================================ */
void s_call_sa_api(uint8_t matrix_N, bool verify)
{
    static uint8_t A_mat[SA_MAT_MAX * SA_MAT_MAX];
    static uint8_t B_mat[SA_MAT_MAX * SA_MAT_MAX];
    static uint32_t C_mat[SA_MAT_MAX * SA_MAT_MAX];
    static uint32_t C_ref[SA_MAT_MAX * SA_MAT_MAX];

    const uint32_t n = (uint32_t)matrix_N;

    if ((n == 0u) ||
        (n > SA_MAT_MAX) ||
        ((n & 3u) != 0u)) {
        s_printf("SA invalid matrix size: %d\n", (int)n);
        return;
    }

    for (uint32_t i = 0u; i < n; ++i) {
        for (uint32_t j = 0u; j < n; ++j) {
            const uint32_t index = i * n + j;

            A_mat[index] = (uint8_t)(rand32() & 0x0fu);
            B_mat[index] = (uint8_t)(rand32() & 0x0fu);
            C_mat[index] = 0u;
            C_ref[index] = 0u;
        }
    }

    if (verify != false) {
        for (uint32_t i = 0u; i < n; ++i) {
            for (uint32_t j = 0u; j < n; ++j) {
                uint32_t sum = 0u;

                for (uint32_t k = 0u; k < n; ++k) {
                    sum +=
                        (uint32_t)A_mat[i * n + k] *
                        (uint32_t)B_mat[k * n + j];
                }

                C_ref[i * n + j] = sum;
            }
        }
    }

    s_printf("SynapEngine start: %dx%d\n", (int)n, (int)n);

    sa_run(A_mat, B_mat, matrix_N, C_mat);

    s_printf("SynapEngine done.\n");

    if (verify != false) {
        int err = 0;

        for (uint32_t i = 0u; i < n; ++i) {
            for (uint32_t j = 0u; j < n; ++j) {
                const uint32_t index = i * n + j;

                if (C_mat[index] != C_ref[index]) {
                    s_printf(
                        "SA NG i=%d j=%d sa=%x cpu=%x\n",
                        (int)i,
                        (int)j,
                        C_mat[index],
                        C_ref[index]
                    );
                    ++err;
                }
            }
        }

        if (err == 0) {
            s_printf("SA VERIFY OK\n");
        } else {
            s_printf("SA VERIFY NG err=%d\n", err);
        }
    }

    putchar('\n');
}