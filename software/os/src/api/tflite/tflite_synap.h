#ifndef PSC_TFLITE_SYNAP_H
#define PSC_TFLITE_SYNAP_H
#include "tflite_api.h"
#include "../sa_transfer.h"
#ifdef __cplusplus
extern "C" {
#endif
/* Platform boundary: real SYS_SA_RUN on PSC-OS; square-matmul mock on host. */
int psc_tflite_sa_tile(const int8_t *a,const int8_t *b,int32_t *c,
                        unsigned n,psc_sa_profile_t *profile);
int psc_tflite_clock_us(void);
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
