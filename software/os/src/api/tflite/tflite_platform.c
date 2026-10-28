#include "tflite_synap.h"
#include "../user.h"
int psc_tflite_sa_tile(const int8_t *a,const int8_t *b,int32_t *c,
                       unsigned m,unsigned k,unsigned n,psc_sa_profile_t *profile) {
    return call_sa_matmul_int8_rect(a,b,c,m,k,n,profile);
}
int psc_tflite_clock_us(void) { return call_timer_measure_read_us(); }

#ifndef PSC_TFLITE_NPU_QTILE
#define PSC_TFLITE_NPU_QTILE 0
#endif
int psc_tflite_qtile_available(void) {
#if PSC_TFLITE_NPU_QTILE && PSC_TFLITE_HAS_SYNAP
    return call_sa_capabilities()==PSC_SA_CAP_QTILE;
#else
    return -1;
#endif
}
int psc_tflite_sa_qtile(const int8_t *a,const int8_t *b,int8_t *c,unsigned m,unsigned k,psc_sa_qtile_t *q) {
    return call_sa_qtile(a,b,c,m,k,q);
}
int psc_tflite_qbatch_enabled(void) {
#if PSC_TFLITE_NPU_QTILE >= 2 && PSC_TFLITE_HAS_SYNAP
    return 1;
#else
    return 0;
#endif
}
int psc_tflite_sa_qbatch(const int8_t *a,const int8_t *b,int8_t *c,psc_sa_qbatch_t *q) {
    return call_sa_qbatch(a,b,c,q);
}
