/* HOST ONLY. Executes a full signed square matrix product, not FC shortcuts. */
#include "tflite_synap.h"
#include <cstdlib>
int psc_test_sa_calls=0, psc_test_sa_fail_after=-1, psc_test_sa_error=-2;
extern "C" int call_sa_matmul_int8(const int8_t *a,const int8_t *b,int32_t *c,
                                   unsigned n,psc_sa_profile_t *profile) {
    ++psc_test_sa_calls;
    if(psc_test_sa_fail_after==0)return psc_test_sa_error;
    if(psc_test_sa_fail_after>0)--psc_test_sa_fail_after;
    if(!a || !b || !c || n<4 || n>16 || n%4)return -1;
    for(unsigned r=0;r<n;++r)for(unsigned col=0;col<n;++col) {
        int32_t sum=0;
        for(unsigned k=0;k<n;++k)sum+=int32_t(a[r*n+k])*b[k*n+col];
        c[r*n+col]=sum;
    }
    if(profile)*profile={1,1,2,1};
    return 0;
}
extern "C" int psc_tflite_sa_tile(const int8_t *a,const int8_t *b,int32_t *c,
                                   unsigned n,psc_sa_profile_t *profile) {
    return call_sa_matmul_int8(a,b,c,n,profile);
}
extern "C" int psc_tflite_clock_us(void) { static int t;return ++t; }
