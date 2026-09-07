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
    uint32_t *out_C,
    bool signed_mode)
{
    uint32_t config =
        ((uint32_t)matrix_N << 24) |
        ((uint32_t)matrix_N << 16);

    /*
     * CSR_SA_CTRL bit3
     *
     * 0 = unsigned INT8
     * 1 = signed INT8
     */
    if (signed_mode != false) {
        config |= (1u << 3);
    }

    volatile const uint32_t *const result =
        (volatile const uint32_t *)(uintptr_t)PSC_SA_ADDR_C;

    SA_LOG(
        "SA A=%x B=%x C=%x N=%d signed=%d\n",
        (uint32_t)(uintptr_t)in_A,
        (uint32_t)(uintptr_t)in_B,
        (uint32_t)PSC_SA_ADDR_C,
        (int)matrix_N,
        (int)signed_mode
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

    /* state reset */
    CSR_WRITE(
        CSR_SA_CTRL,
        config | 0x02u
    );

    CSR_WRITE(
        CSR_SA_CTRL,
        config
    );

    SA_LOG(
        "SA status reset=%x\n",
        CSR_READ(CSR_SA_STATUS)
    );

    /* SA clear */
    CSR_WRITE(
        CSR_SA_CTRL,
        config | 0x04u
    );

    CSR_WRITE(
        CSR_SA_CTRL,
        config
    );

    SA_LOG(
        "SA status clear=%x\n",
        CSR_READ(CSR_SA_STATUS)
    );

    /* start */
    CSR_WRITE(
        CSR_SA_CTRL,
        config | 0x01u
    );

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

            CSR_WRITE(
                CSR_SA_CTRL,
                config
            );

            return;
        }

        __asm__ volatile("nop");
    }

    SA_LOG(
        "SA DONE status=%x\n",
        CSR_READ(CSR_SA_STATUS)
    );

    /*
     * start bitだけ落とす。
     * signed_mode bit3は維持される。
     */
    CSR_WRITE(
        CSR_SA_CTRL,
        config
    );

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
void s_call_sa_api(
    uint8_t matrix_N,
    bool verify,
    bool signed_mode)
{
    /*
     * A/B は8bitの生ビット列として共有する。
     *
     * signed_mode == false:
     *   uint8_t として解釈
     *
     * signed_mode == true:
     *   int8_t として解釈
     */
    static uint8_t A_mat[SA_MAT_MAX * SA_MAT_MAX];
    static uint8_t B_mat[SA_MAT_MAX * SA_MAT_MAX];

    /*
     * NPUのaccumulator/resultは32bit。
     * signed modeでもビット列そのものはuint32_tで保持する。
     */
    static uint32_t C_mat[SA_MAT_MAX * SA_MAT_MAX];
    static uint32_t C_ref[SA_MAT_MAX * SA_MAT_MAX];

    const uint32_t n = (uint32_t)matrix_N;

    if ((n == 0u) ||
        (n > SA_MAT_MAX) ||
        ((n & 3u) != 0u)) {
        s_printf(
            "SA invalid matrix size: %d\n",
            (int)n
        );
        return;
    }

    /* ========================================================
       Test data generation
       ======================================================== */
    for (uint32_t i = 0u; i < n; ++i) {
        for (uint32_t j = 0u; j < n; ++j) {

            const uint32_t index = i * n + j;

            if (signed_mode != false) {

                /*
                 * signed INT8:
                 * -128 .. +127
                 *
                 * uint8_t配列には2の補数の生ビット列を格納する。
                 */
                const int8_t a =
                    (int8_t)(rand32() & 0xffu);

                const int8_t b =
                    (int8_t)(rand32() & 0xffu);

                A_mat[index] = (uint8_t)a;
                B_mat[index] = (uint8_t)b;

            } else {

                /*
                 * 従来のunsigned test。
                 */
                A_mat[index] =
                    (uint8_t)(rand32() & 0x0fu);

                B_mat[index] =
                    (uint8_t)(rand32() & 0x0fu);
            }

            C_mat[index] = 0u;
            C_ref[index] = 0u;
        }
    }

    /* ========================================================
       CPU reference
       ======================================================== */
    if (verify != false) {

        for (uint32_t i = 0u; i < n; ++i) {
            for (uint32_t j = 0u; j < n; ++j) {

                if (signed_mode != false) {

                    int32_t sum = 0;

                    for (uint32_t k = 0u; k < n; ++k) {

                        const int8_t a =
                            (int8_t)A_mat[i * n + k];

                        const int8_t b =
                            (int8_t)B_mat[k * n + j];

                        sum +=
                            (int32_t)a *
                            (int32_t)b;
                    }

                    /*
                     * 負数も含め、32bitの2の補数ビット列として保存。
                     */
                    C_ref[i * n + j] =
                        (uint32_t)sum;

                } else {

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
    }

    /* ========================================================
       SynapEngine
       ======================================================== */

    s_printf(
        "SynapEngine start: %dx%d mode=%s\n",
        (int)n,
        (int)n,
        (signed_mode != false)
            ? "signed"
            : "unsigned"
    );

    /*
     * signed_modeをNPUへ渡す。
     *
     * sa_run()側でも
     * CSR SA_CTRL bit3
     * を設定する必要がある。
     */
    sa_run(
        A_mat,
        B_mat,
        matrix_N,
        C_mat,
        signed_mode
    );

    s_printf("SynapEngine done.\n");


#if 1
    /* ========================================================
       Result display
       ======================================================== */

    s_printf("\nSA result / CPU reference\n\n");

    for (uint32_t i = 0u; i < n; ++i) {

        s_printf("row %d\n", (int)i);

        for (uint32_t j = 0u; j < n; ++j) {

            const uint32_t index = i * n + j;

            if (signed_mode != false) {

                const int32_t sa_value =
                    (int32_t)C_mat[index];

                const int32_t cpu_value =
                    (int32_t)C_ref[index];

                s_printf(
                    "  [%d][%d]  SA=%d  CPU=%d\n",
                    (int)i,
                    (int)j,
                    (int)sa_value,
                    (int)cpu_value
                );

            } else {

                s_printf(
                    "  [%d][%d]  SA=%x  CPU=%x\n",
                    (int)i,
                    (int)j,
                    C_mat[index],
                    C_ref[index]
                );
            }
        }

        s_printf("\n");
    }
#endif


    /* ========================================================
       Verification
       ======================================================== */

    if (verify != false) {

        int err = 0;

        for (uint32_t i = 0u; i < n; ++i) {
            for (uint32_t j = 0u; j < n; ++j) {

                const uint32_t index = i * n + j;

                /*
                 * signed/unsignedどちらも、
                 * 最終的な32bitビット列で比較可能。
                 */
                if (C_mat[index] != C_ref[index]) {

                    if (signed_mode != false) {

                        s_printf(
                            "SA NG i=%d j=%d sa=%d cpu=%d\n",
                            (int)i,
                            (int)j,
                            (int)((int32_t)C_mat[index]),
                            (int)((int32_t)C_ref[index])
                        );

                    } else {

                        s_printf(
                            "SA NG i=%d j=%d sa=%x cpu=%x\n",
                            (int)i,
                            (int)j,
                            C_mat[index],
                            C_ref[index]
                        );
                    }

                    ++err;
                }
            }
        }

        if (err == 0) {

            if (signed_mode != false) {
                s_printf("SA SIGNED VERIFY OK\n");
            } else {
                s_printf("SA VERIFY OK\n");
            }

        } else {

            s_printf(
                "SA VERIFY NG err=%d\n",
                err
            );
        }
    }

    putchar('\n');
}