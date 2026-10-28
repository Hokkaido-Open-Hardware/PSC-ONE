#include "synap_api.h"
#include "../kernel/kernel.h"
#include "../lib/common.h"
#include "../drivers/timer_api.h"

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

   A[M][K] and B[K][N] are tightly packed row-major arrays.
   RTL performs all 4x4 tiling internally.
   C[M][N] is returned tightly packed; only M rows are computed.
   ============================================================ */
#ifndef SA_DEBUG
#define SA_DEBUG 0
#endif

#if SA_DEBUG
#define SA_LOG(...) s_printf(__VA_ARGS__)
#else
#define SA_LOG(...) ((void)0)
#endif

static int sa_active;
unsigned sa_capabilities(void) { return CSR_READ(CSR_SA_STATUS) & PSC_SA_CAP_QTILE; }

/* Caller holds sa_active for the entire K sequence/batch. A -5 result
   permanently quarantines all shared DMA buffers until system reset. */
static int sa_qcommand(const uint8_t *a,const uint8_t *b,uint32_t *block,
                       unsigned m,unsigned len,unsigned code) {
    unsigned config=0x18u|(code<<8);
    CSR_WRITE(CSR_SA_CTRL,config|2u);CSR_WRITE(CSR_SA_CTRL,config);
    CSR_WRITE(CSR_SA_ADDR_A,(uintptr_t)a);CSR_WRITE(CSR_SA_ADDR_B,(uintptr_t)b);
    CSR_WRITE(CSR_SA_ADDR_C,(uintptr_t)block);
    CSR_WRITE(CSR_SA_SIZE,(m<<16)|(4u<<8)|len);
    __asm__ volatile("fence rw,rw" ::: "memory");
    CSR_WRITE(CSR_SA_CTRL,config|1u);

    unsigned timeout=10000000u,status;
    do {status=CSR_READ(CSR_SA_STATUS);} while(!(status&1u) && --timeout);
    if(!timeout || (status&4u)) {
        /* Keep outstanding requests alive until acknowledged. A stuck bus
           leaves the lock held permanently: no reuse and no fallback. */
        CSR_WRITE(CSR_SA_CTRL,config|6u);
        unsigned drain=10000000u;
        do {status=CSR_READ(CSR_SA_STATUS);} while((status&10u) && --drain);
        if(!drain) return -5;
        CSR_WRITE(CSR_SA_CTRL,config);
        __asm__ volatile("fence rw,rw" ::: "memory");
        return timeout?-6:-2;
    }
    CSR_WRITE(CSR_SA_CTRL,config);
    return 0;
}

int sa_run_qtile_checked(const uint8_t *a,const uint8_t *b,uint8_t *c,
                        unsigned m,unsigned k,psc_sa_qtile_t *q) {
    if(!a || !b || !c || !q || !m || m>4 || !k || k>PSC_SA_Q_MAX_K || (k&3)) return -1;
    if(!sa_capabilities()) return -4;
    if(sa_active) return -3;
    for(unsigned j=8;j<12;++j) if(q->parameters[j]<-31 || q->parameters[j]>30) return -1;
    if(q->parameters[12]<-128 || q->parameters[12]>127 || q->parameters[13]<-128 ||
       q->parameters[14]>127 || q->parameters[13]>q->parameters[14] || q->parameters[15]) return -1;
    /* Single hart, synchronous syscall with interrupts disabled by trap entry.
       All raw and quantized requests use this same lock. */
    sa_active=1;
    static _Alignas(16) uint8_t qa[4*252],qb[252*4];
    static _Alignas(16) uint32_t block[20];
    for(unsigned j=0;j<16;++j)block[j]=(uint32_t)q->parameters[j];
    q->commands=0;q->read_bytes=0;q->write_bytes=0;
    q->copy_in_us=0;q->execute_us=0;q->copy_out_us=0;q->valid=1;
    for(unsigned base=0;base<k;base+=252) {
        unsigned len=k-base;if(len>252)len=252;
        int t0=timer_measure_read_us();
        for(unsigned r=0;r<m;++r)for(unsigned j=0;j<len;++j)qa[r*len+j]=a[r*k+base+j];
        for(unsigned j=0;j<len*4;++j)qb[j]=b[base*4+j];
        int t1=timer_measure_read_us();
        if(t0<0 || t1<t0)q->valid=0;else q->copy_in_us+=t1-t0;
        unsigned code=k<=252?4:base==0?1:base+len==k?3:2;
        int rc=sa_qcommand(qa,qb,block,m,len,code);
        if(rc) { q->valid=0;if(rc!=-5)sa_active=0; return rc; }
        ++q->commands;q->read_bytes+=m*len+4*len+(base==0?64:0);
        int t2=timer_measure_read_us();
        if(t1<0 || t2<t1)q->valid=0;else q->execute_us+=t2-t1;
    }
    __asm__ volatile("fence rw,rw" ::: "memory");
    int t0=timer_measure_read_us();
    volatile const uint8_t *out=(volatile const uint8_t *)&block[16];
    for(unsigned j=0;j<m*4;++j)c[j]=out[j];
    int t1=timer_measure_read_us();
    if(t0<0 || t1<t0)q->valid=0;else q->copy_out_us=t1-t0;
    q->write_bytes=m*4;sa_active=0;return 0;
}

/* Software batching only: the hardware still receives the original commands.
   Segment-major A permits reuse without a second copy before each launch.
   B already consists of contiguous Kx4 panels. All scratch is kernel-owned. */
int sa_run_qbatch_checked(const uint8_t *a,const uint8_t *b,uint8_t *c,psc_sa_qbatch_t *q) {
    if(!q)return -1;
    unsigned m=q->m,k=q->k,n=q->n;
    q->commands=q->completed_tiles=q->read_bytes=q->write_bytes=q->copy_in_bytes=0;
    q->copy_in_us=q->execute_us=q->copy_out_us=0;q->valid=0;
    if(!a || !b || !c || !m || m>PSC_SA_Q_BATCH_M || !k || k>PSC_SA_Q_MAX_K ||
       (k&3u) || !n || n>PSC_SA_Q_BATCH_N || (n&3u) || q->reserved)return -1;
    if(sa_active)return -3;
    if(!sa_capabilities())return -4;
    for(unsigned g=0;g<n/4;++g) {
        const int *p=q->parameters[g];
        for(unsigned j=8;j<12;++j)if(p[j]<-31 || p[j]>30)return -1;
        if(p[12]<-128 || p[12]>127 || p[13]<-128 || p[14]>127 || p[13]>p[14] || p[15])return -1;
    }
    sa_active=1;q->valid=1;
    static _Alignas(16) uint8_t a_stage[PSC_SA_Q_BATCH_M*PSC_SA_Q_MAX_K];
    static _Alignas(16) uint8_t b_stage[PSC_SA_Q_BATCH_N*PSC_SA_Q_MAX_K];
    static _Alignas(16) uint32_t blocks[PSC_SA_Q_BATCH_N/4][20];
    static uint8_t result[PSC_SA_Q_BATCH_M*PSC_SA_Q_BATCH_N];
    int t0=timer_measure_read_us();
    for(unsigned r0=0;r0<m;r0+=4) {
        unsigned rows=m-r0;if(rows>4)rows=4;
        for(unsigned base=0;base<k;base+=252) {
            unsigned len=k-base;if(len>252)len=252;
            for(unsigned r=0;r<rows;++r)
                for(unsigned j=0;j<len;++j)
                    a_stage[r0*k+rows*base+r*len+j]=a[(r0+r)*k+base+j];
        }
    }
    for(unsigned j=0;j<n*k;++j)b_stage[j]=b[j];
    for(unsigned g=0;g<n/4;++g)
        for(unsigned j=0;j<16;++j)blocks[g][j]=(uint32_t)q->parameters[g][j];
    q->copy_in_bytes=(m+n)*k;
    int t1=timer_measure_read_us();
    if(t0<0 || t1<t0)q->valid=0;else q->copy_in_us=t1-t0;
    for(unsigned g=0;g<n/4;++g)for(unsigned r0=0;r0<m;r0+=4) {
        unsigned rows=m-r0;if(rows>4)rows=4;
        t0=timer_measure_read_us();
        for(unsigned base=0;base<k;base+=252) {
            unsigned len=k-base;if(len>252)len=252;
            unsigned code=k<=252?4:base==0?1:base+len==k?3:2;
            int rc=sa_qcommand(a_stage+r0*k+rows*base,b_stage+g*k*4+base*4,
                               blocks[g],rows,len,code);
            if(rc) { q->valid=0;if(rc!=-5)sa_active=0;return rc; }
            ++q->commands;q->read_bytes+=(rows+4)*len+(base==0?64:0);
        }
        __asm__ volatile("fence rw,rw" ::: "memory");
        t1=timer_measure_read_us();
        if(t0<0 || t1<t0)q->valid=0;else q->execute_us+=t1-t0;
        volatile const uint8_t *out=(volatile const uint8_t *)&blocks[g][16];
        for(unsigned r=0;r<rows;++r)for(unsigned j=0;j<4;++j)
            result[(r0+r)*n+g*4+j]=out[r*4+j];
        int t2=timer_measure_read_us();
        if(t1<0 || t2<t1)q->valid=0;else q->copy_out_us+=t2-t1;
        ++q->completed_tiles;q->write_bytes+=rows*4;
    }
    t0=timer_measure_read_us();
    for(unsigned j=0;j<m*n;++j)c[j]=result[j];
    t1=timer_measure_read_us();
    if(t0<0 || t1<t0)q->valid=0;else q->copy_out_us+=t1-t0;
    sa_active=0;return 0;
}

int sa_run_rect_profiled(
    const uint8_t *in_A,
    const uint8_t *in_B,
    uint32_t m, uint32_t k, uint32_t n,
    uint32_t *out_C,
    bool signed_mode, psc_sa_profile_t *profile)
{
    if (!in_A || !in_B || !out_C || !m || !k || !n ||
        m > SA_MAT_MAX || k > SA_MAT_MAX || n > SA_MAT_MAX ||
        (k & 3u) || (n & 3u)) return -1;
    if (sa_active) return -3;
    sa_active = 1;
    int execute_start = profile ? timer_measure_read_us() : -1;
    if(profile) { profile->valid=0; profile->execute_us=0; profile->copy_out_us=0; }
    uint32_t config = (1u << 4); /* OS mode; instruction[11:8] = 0. */
    const uint32_t size =
        (m << 16) | /* M: A/C rows */
        (n << 8) |  /* Y: B/C columns */
        k;          /* X: reduction dimension */

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
        "SA A=%x B=%x C=%x M=%d K=%d N=%d signed=%d\n",
        (uint32_t)(uintptr_t)in_A,
        (uint32_t)(uintptr_t)in_B,
        (uint32_t)PSC_SA_ADDR_C,
        (int)m, (int)k, (int)n,
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

    CSR_WRITE(CSR_SA_SIZE, size);

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

            CSR_WRITE(CSR_SA_CTRL, config | 0x02u);
            /* Legacy reset is acknowledged only at completion. Keep reset
               asserted and ownership held until its outstanding bus work ends. */
            uint32_t drain = 10000000u;
            while ((CSR_READ(CSR_SA_STATUS) & 2u) && --drain) { }
            if (!drain) return -5;
            CSR_WRITE(CSR_SA_CTRL, config);
            __asm__ volatile("fence rw, rw" ::: "memory");
            sa_active = 0;
            return -2;
        }

        __asm__ volatile("nop");
    }

    SA_LOG(
        "SA DONE status=%x\n",
        CSR_READ(CSR_SA_STATUS)
    );

    /*
     * start bitだけ落とす。
     * signed_mode bit3とOS mode bit4は維持される。
     */
    CSR_WRITE(
        CSR_SA_CTRL,
        config
    );

    __asm__ volatile("fence rw, rw" ::: "memory");

    int copy_start = profile ? timer_measure_read_us() : -1;
    const uint32_t count = m * n;

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

    if(profile) {
        int end=timer_measure_read_us();
        profile->valid=execute_start>=0 && copy_start>=execute_start && end>=copy_start;
        if(profile->valid) {
            profile->execute_us=copy_start-execute_start;
            profile->copy_out_us=end-copy_start;
        }
    }
    SA_LOG("SA run complete\n");
    sa_active = 0;
    return 0;
}

int sa_run_rect_checked(const uint8_t *a,const uint8_t *b,uint32_t m,uint32_t k,
                        uint32_t n,uint32_t *c,bool signed_mode) {
    return sa_run_rect_profiled(a,b,m,k,n,c,signed_mode,0);
}

int sa_run_checked(const uint8_t *a, const uint8_t *b, uint8_t n,
                   uint32_t *c, bool signed_mode) {
    return sa_run_rect_checked(a, b, n, n, n, c, signed_mode);
}

void sa_run(const uint8_t *a, const uint8_t *b, uint8_t n,
            uint32_t *c, bool signed_mode) {
    (void)sa_run_checked(a, b, n, c, signed_mode);
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
