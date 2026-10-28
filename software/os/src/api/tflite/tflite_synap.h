#ifndef PSC_TFLITE_SYNAP_H
#define PSC_TFLITE_SYNAP_H
#include "tflite_api.h"
#include "tflite_cpu.h"
#include "../sa_transfer.h"
#include "../sa_qtile.h"
#ifdef __cplusplus
extern "C" {
#endif
/* Platform boundary: A[m][k] * B[k][n] = C[m][n], row-major.
   Real rectangular SYS_SA_RUN on PSC-OS; matrix multiplication mock on host. */
int psc_tflite_sa_tile(const int8_t *a,const int8_t *b,int32_t *c,
                        unsigned m,unsigned k,unsigned n,psc_sa_profile_t *profile);
int psc_tflite_clock_us(void);
/* -1: opt-out (no syscall); 0: probed unsupported; 1: supported. */
int psc_tflite_qtile_available(void);
int psc_tflite_sa_qtile(const int8_t *,const int8_t *,int8_t *,unsigned,unsigned,psc_sa_qtile_t *);
int psc_tflite_qbatch_enabled(void);
int psc_tflite_sa_qbatch(const int8_t *,const int8_t *,int8_t *,psc_sa_qbatch_t *);
/* Platform opt-in. Default false; never probe an absent device via CSR/MMIO. */
int psc_tflite_synap_available(void);
/* Tiled im2col, bounded shared workspace; scratch is SA_MAT_MAX^2 INT32.
   No full image expansion, no Arena allocation. Errors invalidate invoke. */
int psc_tflite_synap_conv(const psc_tflite_cpu_op *,const int8_t *,const int8_t *,
    const uint8_t *,int8_t *,unsigned,int32_t *,psc_tflite_profile_t *);
/* Batched FC: x[m,k], w[n,k], dot[m,n], m,n <= tile. */
int psc_tflite_synap_batch(const int8_t *x,const int8_t *w,unsigned m,unsigned k,unsigned n,
                         unsigned tile,int32_t *dot,psc_tflite_profile_t *profile);
/* n output rows <= tile, k arbitrary within validated model limit. */
int psc_tflite_synap_dot(const int8_t *x,const int8_t *w,unsigned k,unsigned n,
                         unsigned tile,int32_t *dot,psc_tflite_profile_t *profile);
#ifdef __cplusplus
}
#endif
#endif
