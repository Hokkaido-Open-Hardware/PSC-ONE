#include "tflite_synap.h"
#include "../user.h"
int psc_tflite_sa_tile(const int8_t *a,const int8_t *b,int32_t *c,
                       unsigned n,psc_sa_profile_t *profile) {
    return call_sa_matmul_int8(a,b,c,n,profile);
}
int psc_tflite_clock_us(void) { return call_timer_measure_read_us(); }
