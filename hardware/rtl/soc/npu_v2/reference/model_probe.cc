// Host-only adapter to the existing PSC CPU runtime and pinned TFLite schema.
#include "tflite_api.h"
#include "tflite_quant.h"
#include "schema_generated.h"
#include <fstream>
#include <iostream>
#include <vector>
#include <iterator>
#include <cstdlib>
#include <iomanip>
#define CHECK(x) do { if (!(x)) { std::cerr << "check failed line " << __LINE__ << ": " << #x << '\n'; std::exit(1); } } while (0)
static unsigned sample;
static std::ofstream trace;
static void capture(void *,unsigned l,unsigned c,int32_t raw,int32_t corrected,int32_t biased,int32_t q,int8_t y) {
    trace<<sample<<','<<l<<','<<c<<','<<raw<<','<<corrected<<','<<biased<<','<<q<<','<<int(y)<<'\n';
}
int main(int argc,char **argv) {
    CHECK(argc==4);
    std::ifstream f(argv[1],std::ios::binary);
    std::vector<uint8_t> bytes((std::istreambuf_iterator<char>(f)),{});
    CHECK(!bytes.empty());
    flatbuffers::Verifier verifier(bytes.data(),bytes.size());
    CHECK(tflite::VerifyModelBuffer(verifier));
    CHECK(psc_tflite_prepare(bytes.data(),bytes.size())==0);
    auto m=tflite::GetModel(bytes.data()); auto g=m->subgraphs()->Get(0);
    std::ofstream desc(std::string(argv[3])+"/model.json");
    desc<<std::setprecision(17)<<"{\"layers\":[";
    unsigned l=0;
    for(auto op:*g->operators()) {
        if(l++)desc<<',';
        auto x=g->tensors()->Get(op->inputs()->Get(0));
        auto w=g->tensors()->Get(op->inputs()->Get(1));
        auto y=g->tensors()->Get(op->outputs()->Get(0));
        int n=w->shape()->Get(0),k=w->shape()->Get(1),mult,shift;
        CHECK(w->quantization()->zero_point()->Get(0)==0);
        auto scale=double(x->quantization()->scale()->Get(0))*w->quantization()->scale()->Get(0)/y->quantization()->scale()->Get(0);
        CHECK(psc_tflite_quantize(scale,&mult,&shift)==0);
        auto wd=m->buffers()->Get(w->buffer())->data();
        int wz=y->quantization()->zero_point()->Get(0);
        bool relu=op->builtin_options_as_FullyConnectedOptions()->fused_activation_function()==tflite::ActivationFunctionType_RELU;
        desc<<"{\"n\":"<<n<<",\"k\":"<<k<<",\"input_zero\":"<<x->quantization()->zero_point()->Get(0)<<",\"output_zero\":"<<wz<<",\"multiplier\":"<<mult<<",\"shift\":"<<shift<<",\"activation_min\":"<<(relu?wz:-128)<<",\"weights\":[";
        for(int i=0;i<n*k;++i){if(i)desc<<',';desc<<int(int8_t(wd->Get(i)));}
        desc<<"],\"bias\":[";
        int bi=op->inputs()->Get(2);
        for(int c=0;c<n;++c){
            if(c)desc<<',';
            int32_t b=0;
            if(bi>=0) b=flatbuffers::ReadScalar<int32_t>(m->buffers()->Get(g->tensors()->Get(bi)->buffer())->data()->data()+4*c);
            desc<<b;
        }
        desc<<"]}";
    }
    desc<<"]}\n";
    size_t size; auto input=psc_tflite_get_input(&size);CHECK(input);
    std::ifstream in(argv[2],std::ios::binary);
    trace.open(std::string(argv[3])+"/cpu.csv");
    trace<<"sample,layer,channel,raw,corrected,biased,requant,output\n";
    for(sample=0;in.read(reinterpret_cast<char *>(input),size);++sample)
        CHECK(psc_tflite_invoke_detailed(capture,nullptr)==0);
    CHECK(in.eof()&&in.gcount()==0&&sample>0);
    std::cout<<"CPU samples="<<sample<<" PASS\n";
}
