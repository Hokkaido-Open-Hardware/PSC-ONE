#define PSC_PHASE4_TEST
#include "phase3.cc"
#include "tflite_synap.h"
extern int psc_test_sa_calls,psc_test_sa_fail_after,psc_test_sa_error;
using Detail=std::array<int32_t,5>;
static std::vector<Detail> details;
static void detailed(void *,unsigned,unsigned,int32_t raw,int32_t z,int32_t b,int32_t q,int8_t y) {
    details.push_back({raw,z,b,q,y});
    CHECK(psc_tflite_set_fc_backend(PSC_TFLITE_FC_CPU)==PSC_TFLITE_ERR_BUSY);
    CHECK(psc_tflite_set_synap_tile_size(4)==PSC_TFLITE_ERR_BUSY);
}
int main() {
    unsigned comparisons=0,invocations=0;
    for(unsigned k:{1u,3u,4u,5u,15u,16u,17u,31u,33u}) {
        auto m=demo();auto &g=*m.subgraphs[0];
        g.tensors[0]->shape=g.tensors[0]->shape_signature={1,int(k)};
        g.tensors[1]->shape=g.tensors[1]->shape_signature={16,int(k)};
        m.buffers[1]->data.resize(16*k);
        for(unsigned i=0;i<16*k;++i)m.buffers[1]->data[i]=uint8_t(int(i*17%255)-127);
        auto bytes=pack(m);alignas(16) uint8_t aligned[8192];memcpy(aligned,bytes.data(),bytes.size());
        CHECK(psc_tflite_prepare(aligned,bytes.size())==0);
        CHECK(psc_tflite_set_fc_backend(static_cast<psc_tflite_fc_backend>(7))==-202);
        CHECK(psc_tflite_set_synap_tile_size(0)==-202);CHECK(psc_tflite_set_synap_tile_size(6)==-202);
        CHECK(psc_tflite_set_synap_tile_size(20)==-202);
        size_t n;auto *x=psc_tflite_get_input(&n);CHECK(n==k);
        for(unsigned tile:{4u,8u,12u,16u})for(unsigned pass=0;pass<4;++pass) {
            for(unsigned i=0;i<k;++i)x[i]=int8_t(int((i*73+pass*47)%256)-128);
            auto ref=reference(aligned,std::vector<int8_t>(x,x+k));
            CHECK(psc_tflite_set_fc_backend(PSC_TFLITE_FC_CPU)==0);
            int oldcalls=psc_test_sa_calls;details.clear();CHECK(psc_tflite_invoke_detailed(detailed,nullptr)==0);
            CHECK(psc_test_sa_calls==oldcalls);auto cpu=details;
            unsigned index=0;for(auto &layer:ref)for(auto r:layer) {
                CHECK(cpu[index][2]==r.acc&&cpu[index][3]==r.requant&&cpu[index][4]==r.output);++index;
            }
            CHECK(psc_tflite_set_synap_tile_size(tile)==0);
            CHECK(psc_tflite_set_fc_backend(PSC_TFLITE_FC_SYNAP)==0);
            CHECK(!psc_tflite_get_output(&n)&&n==0);
            details.clear();CHECK(psc_tflite_invoke_detailed(detailed,nullptr)==0);CHECK(cpu==details);
            unsigned expected_calls=((16+tile-1)/tile)*((k+tile-1)/tile)+((4+tile-1)/tile)*((16+tile-1)/tile);
            CHECK(unsigned(psc_test_sa_calls-oldcalls)==expected_calls);
            comparisons+=details.size();invocations+=2;
            CHECK(psc_tflite_get_output(&n)&&n==4);
        }
        // Device faults on the first and a later K/channel tile: output is
        // unavailable and no implicit CPU fallback may turn the result into OK.
        CHECK(psc_tflite_set_synap_tile_size(4)==0);
        for(int error:{-1,-2,-3,-77})for(int after:{0,1}) {
            psc_test_sa_fail_after=after;psc_test_sa_error=error;
            int expected=error==-1?-208:error==-2?-207:error==-3?-209:-206;
            CHECK(psc_tflite_invoke()==expected);
            CHECK(!psc_tflite_get_output(&n)&&n==0);
            psc_test_sa_fail_after=-1;
            CHECK(psc_tflite_set_fc_backend(PSC_TFLITE_FC_CPU)==0);CHECK(psc_tflite_invoke()==0);
            CHECK(psc_tflite_set_fc_backend(PSC_TFLITE_FC_SYNAP)==0);CHECK(psc_tflite_invoke()==0);
        }
        CHECK(psc_tflite_set_profiling(1)==0);CHECK(psc_tflite_invoke()==0);
        auto *p=psc_tflite_get_profile();CHECK(p->valid&&p->tiles&&p->execute_us&&p->packing_us);
        CHECK(psc_tflite_set_profiling(0)==0);
    }
    int32_t dot[16];int8_t x[16]={},w[256]={};
    CHECK(psc_tflite_synap_dot(x,w,0,4,4,dot,nullptr)<0);
    CHECK(psc_tflite_synap_dot(x,w,16,5,4,dot,nullptr)<0);
    CHECK(psc_tflite_synap_dot(x,w,16,4,3,dot,nullptr)<0);
    CHECK(psc_tflite_reset()==0);
    printf("PASS: Phase 4 %u CPU/NPU invokes, %u five-stage channel comparisons, all tile sizes, K tails, injected failures and recovery\n",invocations,comparisons);
}
