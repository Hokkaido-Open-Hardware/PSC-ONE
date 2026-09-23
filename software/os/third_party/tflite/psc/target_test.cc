// Bare-metal validation of the real runtime, quantizer, Synap adapter and
// existing hardware driver. Platform boundary omits PSC-OS syscalls only.
#include "tflite_api.h"
#include "tflite_synap.h"
#include "tflite_demo.h"
#include "psc/pulp_fc.h"
#include "model_bytes.h"
#include <string.h>

#define PIO (*(volatile uint32_t *)0x10001000u)
#define TIMER_W (*(volatile uint32_t *)0x10002000u)
#define TIMER_R (*(volatile uint32_t *)0x10002004u)
#define TIMER_ST (*(volatile uint32_t *)0x10002008u)
static void check(bool ok,unsigned line) {
    if(!ok) { PIO=0xbad00001;PIO=line;PIO=0xee01;PIO=0xbad0bad0;for(;;)asm volatile("nop"); }
}
#define CHECK(x) check(bool(x),__LINE__)
extern "C" int sa_run_checked(const uint8_t *,const uint8_t *,uint8_t,uint32_t *,int);
static unsigned sa_calls;
extern "C" int psc_tflite_sa_tile(const int8_t *a,const int8_t *b,int32_t *c,unsigned n,psc_sa_profile_t *p) {
    ++sa_calls;
    int start=psc_tflite_clock_us();
    int rc=sa_run_checked(reinterpret_cast<const uint8_t *>(a),reinterpret_cast<const uint8_t *>(b),
                          n,reinterpret_cast<uint32_t *>(c),1);
    if(p)*p={1,0,unsigned(psc_tflite_clock_us()-start),0};
    return rc;
}
extern "C" int psc_tflite_clock_us(void) { return int(0xffffu-TIMER_R); }
static int32_t reference_rows[20][5];
static unsigned row_count;
static bool record;
static void detail(void *,unsigned l,unsigned c,int32_t r,int32_t z,int32_t b,int32_t q,int8_t y) {
    unsigned idx=(l?16:0)+c;
    CHECK(idx==row_count++ && idx<20);
    const int32_t actual[]={r,z,b,q,y};
    for(unsigned j=0;j<5;++j) {
        if(record)reference_rows[idx][j]=actual[j];
        else CHECK(actual[j]==reference_rows[idx][j]);
    }
    CHECK(b==demo_trace[idx][0] && q==demo_trace[idx][1] && y==demo_trace[idx][2]);
}
static void validate() {
    row_count=0;
    CHECK(psc_tflite_invoke_detailed(detail,nullptr)==0 && row_count==20);
    size_t n;const auto *y=psc_tflite_get_output(&n);const int8_t expected[]={-36,27,18,8};
    CHECK(y && n==4 && memcmp(y,expected,4)==0);
}
static unsigned starts[2],elapsed[2];
static void layer(void *,unsigned i,int begin) {
    CHECK(i<2);
    unsigned now=psc_tflite_clock_us();
    if(begin)starts[i]=now;else elapsed[i]=now-starts[i];
}
static void timer_start() {
    TIMER_W=0x0001ffffu;
    CHECK((((TIMER_ST>>11)&1023)+1)==100); // 100 MHz, one microsecond tick
}

// Separate symbols also permit an encoding audit independent of runtime
// inlining. Both are actually executed on target, for every pointer alignment.
extern "C" __attribute__((noinline)) int32_t audit_scalar(const int8_t *x,const int8_t *w,int k) {
    int32_t r=0;for(int i=0;i<k;++i)r+=int32_t(x[i])*w[i];return r;
}
extern "C" __attribute__((noinline)) int32_t audit_pulp(const int8_t *x,const int8_t *w,int k) {
    int32_t r=0;if(!psc_tflite_pulp::try_dot(x,w,k,0,true,&r))r=audit_scalar(x,w,k);return r;
}
extern "C" void run() {
    alignas(4) int8_t x[40],w[40];
    for(int ax=0;ax<4;++ax)for(int aw=0;aw<4;++aw)for(int k=1;k<=33;++k) {
        for(int i=0;i<40;++i) { x[i]=int8_t(i*79-128);w[i]=int8_t(i*53+127); }
        CHECK(audit_scalar(x+ax,w+aw,k)==audit_pulp(x+ax,w+aw,k));
    }
    CHECK(psc_tflite_prepare(model_bytes,sizeof(model_bytes))==0);
    size_t n;auto *input=psc_tflite_get_input(&n);CHECK(input && n==sizeof(demo_input));
    memcpy(input,demo_input,n);
    timer_start();record=true;validate();record=false;
    const psc_tflite_fc_backend order[]={PSC_TFLITE_FC_PULP,PSC_TFLITE_FC_PULP,PSC_TFLITE_FC_SYNAP,PSC_TFLITE_FC_CPU};
    for(auto b:order) {
        unsigned calls=sa_calls;CHECK(psc_tflite_set_fc_backend(b)==0);validate();
        if(b!=PSC_TFLITE_FC_SYNAP)CHECK(calls==sa_calls);
    }
    // Original layer callback mechanism; no per-channel tracing in timing.
    // Each mode warms itself immediately before each of five timed samples.
    // Store all samples; use minimum invoke sample with its matching FC times.
    const psc_tflite_fc_backend modes[]={PSC_TFLITE_FC_CPU,PSC_TFLITE_FC_PULP,
        PSC_TFLITE_FC_SYNAP,PSC_TFLITE_FC_SYNAP,PSC_TFLITE_FC_SYNAP,PSC_TFLITE_FC_SYNAP};
    for(unsigned sample=0;sample<5;++sample)for(unsigned turn=0;turn<6;++turn) {
        unsigned mode=(sample+turn)%6;
        unsigned tile=mode<2?4:(mode-1)*4;
        CHECK(psc_tflite_set_fc_backend(modes[mode])==0);
        CHECK(psc_tflite_set_synap_tile_size(tile)==0);
        unsigned calls=sa_calls;
        timer_start();CHECK(psc_tflite_invoke_traced(nullptr,layer,nullptr)==0);
        timer_start();unsigned begin=psc_tflite_clock_us();
        int rc=psc_tflite_invoke_traced(nullptr,layer,nullptr);
        unsigned total=psc_tflite_clock_us()-begin;
        CHECK(rc==0 && total>0 && TIMER_R>0 && elapsed[0]>0 && elapsed[1]>0);
        if(mode<2)CHECK(calls==sa_calls);
        PIO=0xee40;PIO=sample;PIO=mode;PIO=tile;PIO=total;PIO=elapsed[0];PIO=elapsed[1];
        validate(); // all five intermediate stages, outside timing
    }
    PIO=0xee50;
    for(unsigned i=0;i<20;++i)for(unsigned j=0;j<5;++j)PIO=uint32_t(reference_rows[i][j]);
    PIO=0xee01;PIO=0x600d600d;
    for(;;)asm volatile("nop");
}
