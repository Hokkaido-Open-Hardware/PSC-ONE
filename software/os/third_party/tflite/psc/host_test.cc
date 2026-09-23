// Reuse the existing official, unmodified TFLM oracle and fixture builder.
#define PSC_PHASE4_TEST
#include "phase3.cc"
#include "psc/pulp_fc.h"
#include <sys/mman.h>
#include <unistd.h>
#include <new>

static bool in_invoke=false;
extern "C" void *__real_malloc(size_t);
extern "C" void *__real_calloc(size_t,size_t);
extern "C" void *__real_realloc(void *,size_t);
extern "C" void *__wrap_malloc(size_t n) { CHECK(!in_invoke); return __real_malloc(n); }
extern "C" void *__wrap_calloc(size_t n,size_t s) { CHECK(!in_invoke); return __real_calloc(n,s); }
extern "C" void *__wrap_realloc(void *p,size_t n) { CHECK(!in_invoke); return __real_realloc(p,n); }
void *operator new(size_t n) { CHECK(!in_invoke); auto p=__real_malloc(n); if(!p)throw std::bad_alloc(); return p; }
void *operator new[](size_t n) { return ::operator new(n); }
void operator delete(void *p) noexcept { free(p); }
void operator delete[](void *p) noexcept { free(p); }
void operator delete(void *p,size_t) noexcept { free(p); }
void operator delete[](void *p,size_t) noexcept { free(p); }

extern int psc_test_sa_calls;
using Detail=std::array<int32_t,5>;
static Detail rows[20];
static unsigned row_count;
static void capture_detail(void *,unsigned l,unsigned c,int32_t r,int32_t z,int32_t b,int32_t q,int8_t y) {
    CHECK(row_count<20 && row_count==(l?16:0)+c);
    rows[row_count++]={r,z,b,q,y};
    CHECK(psc_tflite_set_fc_backend(PSC_TFLITE_FC_PULP)==PSC_TFLITE_ERR_BUSY);
}
static void invoke_detail() {
    row_count=0; in_invoke=true;
    int rc=psc_tflite_invoke_detailed(capture_detail,nullptr);
    in_invoke=false; CHECK(rc==0 && row_count==20);
}
static uint32_t seed=0x12345678;
static uint32_t random_word() { seed^=seed<<13; seed^=seed>>17; seed^=seed<<5; return seed; }

int main() {
    // Protected page immediately after each input/weight: all four pointer
    // alignments and tails, no readable padding to hide an overread.
    const size_t page=size_t(sysconf(_SC_PAGESIZE));
    auto *xm=static_cast<int8_t *>(mmap(nullptr,page*4,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0));
    CHECK(xm!=MAP_FAILED);
    CHECK(mprotect(xm+page,page,PROT_NONE)==0);
    CHECK(mprotect(xm+3*page,page,PROT_NONE)==0);
    unsigned dots=0;
    for(int k=1;k<=257;++k)for(int pass=0;pass<12;++pass) {
        int8_t *x=xm+page-k,*w=xm+3*page-k;
        int32_t expected=0,got=123;
        for(int i=0;i<k;++i) {
            x[i]=pass==0?0:pass==1?-128:pass==2?127:int8_t(random_word());
            w[i]=pass==1?-128:pass==2?127:int8_t(random_word());
            expected+=int32_t(x[i])*w[i];
        }
        bool used=psc_tflite_pulp::try_dot(x,w,k,0,true,&got);
#ifdef PSC_PULP_TEST_EMULATE
        CHECK(used==(k>=4));
#else
        CHECK(!used);
#endif
        if(used) { CHECK(got==expected); ++dots; } else CHECK(got==123);
        CHECK(!psc_tflite_pulp::try_dot(x,w,k,1,true,&got));
        CHECK(!psc_tflite_pulp::try_dot(x,w,k,0,false,&got));
        CHECK(!psc_tflite_pulp::try_dot(nullptr,w,k,0,true,&got));
        CHECK(!psc_tflite_pulp::try_dot(x,w,k,0,true,nullptr));
    }
    CHECK(munmap(xm,page*4)==0);
    // Independent input/weight alignments, full allowed depth and extrema.
    for(int ax=0;ax<4;++ax)for(int aw=0;aw<4;++aw)for(int k:{4,5,6,7,16,8192}) {
        std::vector<int8_t> x(k+ax,-128),w(k+aw,-128);
        int32_t got=0;
        if(psc_tflite_pulp::try_dot(x.data()+ax,w.data()+aw,k,0,true,&got))
            CHECK(got==k*16384);
    }
    int32_t ignored=99;
    CHECK(!psc_tflite_pulp::try_dot(nullptr,nullptr,-1,0,true,&ignored) && ignored==99);
    CHECK(!psc_tflite_pulp::try_dot(nullptr,nullptr,8193,0,true,&ignored));

    unsigned comparisons=0,invokes=0;
    for(int k:{1,2,3,4,5,6,7,15,16,17,31,33,64})
    for(int zero:{-128,-3,0,17,127})for(int pass=0;pass<6;++pass) {
        auto m=demo();auto &g=*m.subgraphs[0];
        g.tensors[0]->shape=g.tensors[0]->shape_signature={1,k};
        g.tensors[1]->shape=g.tensors[1]->shape_signature={16,k};
        g.tensors[0]->quantization->zero_point={zero};
        m.buffers[1]->data.resize(16*k);
        for(auto &v:m.buffers[1]->data)v=uint8_t(int(random_word()%255)-127);
        if(pass==5)for(auto &op:g.operators)op->inputs[2]=-1;
        auto b=pack(m);alignas(16) uint8_t bytes[8192];CHECK(b.size()<=sizeof(bytes));memcpy(bytes,b.data(),b.size());
        CHECK(psc_tflite_prepare(bytes,b.size())==0);
        size_t n;auto *x=psc_tflite_get_input(&n);CHECK(n==unsigned(k));
        for(int i=0;i<k;++i)x[i]=pass==0?0:pass==1?-128:pass==2?127:int8_t(random_word());
        auto oracle=reference(bytes,std::vector<int8_t>(x,x+k));
        invoke_detail(); ++invokes;
        std::array<Detail,20> cpu;std::copy(rows,rows+20,cpu.begin());
        unsigned idx=0;for(const auto &l:oracle)for(auto r:l) {
            CHECK(cpu[idx][2]==r.acc && cpu[idx][3]==r.requant && cpu[idx][4]==r.output);++idx;
        }
        for(auto backend:{PSC_TFLITE_FC_PULP,PSC_TFLITE_FC_PULP,PSC_TFLITE_FC_SYNAP,PSC_TFLITE_FC_CPU}) {
            CHECK(psc_tflite_set_fc_backend(backend)==0);
            CHECK(!psc_tflite_get_output(&n) && n==0);
            int calls=psc_test_sa_calls;
            invoke_detail();++invokes;
            if(backend!=PSC_TFLITE_FC_SYNAP)CHECK(calls==psc_test_sa_calls);
            for(unsigned c=0;c<20;++c) { CHECK(cpu[c]==rows[c]);++comparisons; }
            auto *out=psc_tflite_get_output(&n);CHECK(n==4);
            for(unsigned c=0;c<n;++c)CHECK(out[c]==cpu[c+16][4]);
        }
    }
    // The resident scalar runtime rejects these models at prepare, before any
    // backend can run. Preserve these errors, do not invent a scalar kernel.
    auto invalid=demo();invalid.subgraphs[0]->tensors[1]->quantization->zero_point={1};rejected(std::move(invalid));
    invalid=demo();invalid.subgraphs[0]->tensors[0]->type=TensorType_UINT8;rejected(std::move(invalid));
    invalid=demo();invalid.buffers[1]->data[0]=128;rejected(std::move(invalid));
    auto b=pack(demo());alignas(16) uint8_t bytes[8192];memcpy(bytes,b.data(),b.size());
    CHECK(psc_tflite_prepare(bytes,b.size())==0);size_t n;
    memcpy(psc_tflite_get_input(&n),demo_input.data(),demo_input.size());
    const int8_t expected[]={-36,27,18,8};
    for(auto backend:{PSC_TFLITE_FC_CPU,PSC_TFLITE_FC_PULP,PSC_TFLITE_FC_SYNAP,PSC_TFLITE_FC_CPU}) {
        CHECK(psc_tflite_set_fc_backend(backend)==0);invoke_detail();
        CHECK(memcmp(psc_tflite_get_output(&n),expected,4)==0 && n==4);
    }
    printf("PASS: %u protected-boundary dots, %u invokes, %u five-stage FC1/FC2 channel comparisons; no invoke allocations; output [-36,27,18,8]\n",dots,invokes,comparisons);
}
