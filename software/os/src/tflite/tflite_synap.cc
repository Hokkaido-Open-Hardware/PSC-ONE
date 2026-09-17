#include "tflite_synap.h"
#include <string.h>
namespace {
/* Shared synchronous workspace, protected by runtime's invoking guard.
   SYS_SA_RUN copies to kernel physical buffers; no user VA is given to NPU. */
alignas(16) int8_t a[256], b[256];
alignas(16) int32_t c[256];
void elapsed(psc_tflite_profile_t *p,int start,int end,uint32_t &field) {
    if (start < 0 || end < start) p->valid=0;
    else field+=uint32_t(end-start);
}
}
extern "C" int psc_tflite_synap_dot(const int8_t *x,const int8_t *w,unsigned k,unsigned n,
                                    unsigned tile,int32_t *dot,psc_tflite_profile_t *p) {
    if (!x || !w || !dot || !k || k>8192 || !n || n>tile ||
        tile<4 || tile>16 || tile%4) return PSC_TFLITE_ERR_GRAPH;
    for (unsigned row=0;row<n;++row) dot[row]=0;
    for (unsigned base=0;base<k;base+=tile) {
        int t0=p?psc_tflite_clock_us():-1;
        unsigned count=k-base<tile ? k-base : tile;
        memset(a,0,tile*tile);memset(b,0,tile*tile);
        for(unsigned row=0;row<n;++row)
            for(unsigned col=0;col<count;++col) a[row*tile+col]=w[row*k+base+col];
        for(unsigned row=0;row<count;++row) b[row*tile]=x[base+row];
        int t1=p?psc_tflite_clock_us():-1;
        psc_sa_profile_t device={};
        int rc=psc_tflite_sa_tile(a,b,c,tile,p?&device:nullptr);
        int t2=p?psc_tflite_clock_us():-1;
        if(p) {
            ++p->tiles;p->device_status=rc;
            elapsed(p,t0,t1,p->packing_us);elapsed(p,t1,t2,p->syscall_us);
            if(!device.valid) p->valid=0;
            else {p->copy_in_us+=device.copy_in_us;p->execute_us+=device.execute_us;p->copy_out_us+=device.copy_out_us;}
        }
        if(rc) { // never consume stale c, no fallback
            if(rc==-1) return PSC_TFLITE_ERR_SYNAP_ARGUMENT;
            if(rc==-2) return PSC_TFLITE_ERR_SYNAP_TIMEOUT;
            if(rc==-3) return PSC_TFLITE_ERR_SYNAP_BUSY;
            return PSC_TFLITE_ERR_SYNAP;
        }
        for(unsigned row=0;row<n;++row) dot[row]+=c[row*tile];
        if(p) elapsed(p,t2,psc_tflite_clock_us(),p->partial_us);
    }
    return 0;
}
