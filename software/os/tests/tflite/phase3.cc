/* Model generator and official TFLM reference oracle. HOST ONLY. */
#include "tflite_api.h"
#include "tflite_quant.h"
#include "model_fixture.h"
#include "tensorflow/lite/kernels/internal/reference/integer_ops/fully_connected.h"
#include "tensorflow/lite/kernels/internal/quantization_util.h"
#include <array>
#include <climits>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <sstream>

#define CHECK(x) do { if (!(x)) { fprintf(stderr,"FAIL phase3:%d: %s\n",__LINE__,#x); exit(1); } } while(0)
struct Row { int32_t acc, requant; int8_t output; };
static std::vector<Row> oracle_rows;
static void reference_capture(int, int32_t a, int32_t q) { oracle_rows.push_back({a,q,0}); }
#include "reference_traced.h"
static const std::vector<int8_t> demo_input={-128,127,-3,0,1,-1,64,-64,7,-11,31,-32,90,-100,2,-2};
static void set_bias(ModelT &m, unsigned buffer, unsigned channel, int32_t value) {
    flatbuffers::WriteScalar<int32_t>(m.buffers[buffer]->data.data()+4*channel,value);
}
static ModelT demo() {
    auto m=fixture();
    // Deterministic synthetic weights, not trained and no accuracy claim.
    for (unsigned c=0;c<16;++c) {
        for (unsigned k=0;k<16;++k) m.buffers[1]->data[c*16+k]=uint8_t(int((c*17+k*7+3)%15)-7);
        set_bias(m,2,c,int(c)*19-137);
    }
    for (unsigned c=0;c<4;++c) {
        for (unsigned k=0;k<16;++k) m.buffers[3]->data[c*16+k]=uint8_t(int((c*11+k*5+1)%13)-6);
        set_bias(m,4,c,int(c)*83-101);
    }
    // A non-extreme ReLU zero point exposes the distinction between INT8
    // saturation and the fused activation clamp.
    m.subgraphs[0]->tensors[3]->quantization->zero_point={-17};
    return m;
}
static std::vector<std::vector<Row>> reference(const void *bytes, const std::vector<int8_t> &input) {
    auto *m=GetModel(bytes); auto *g=m->subgraphs()->Get(0);
    std::vector<std::vector<int8_t>> data(g->tensors()->size());
    data[g->inputs()->Get(0)]=input;
    std::vector<std::vector<Row>> rows;
    for (const auto *op : *g->operators()) {
        int xi=op->inputs()->Get(0),wi=op->inputs()->Get(1),bi=op->inputs()->Get(2),yi=op->outputs()->Get(0);
        auto *x=g->tensors()->Get(xi), *w=g->tensors()->Get(wi), *y=g->tensors()->Get(yi);
        int k=w->shape()->Get(1),n=w->shape()->Get(0);
        const int8_t *weights=reinterpret_cast<const int8_t *>(m->buffers()->Get(w->buffer())->data()->data());
        std::vector<int32_t> bias(n);
        if (bi>=0) {
            auto *b=m->buffers()->Get(g->tensors()->Get(bi)->buffer())->data();
            for (int c=0;c<n;++c) bias[c]=flatbuffers::ReadScalar<int32_t>(b->data()+4*c);
        }
        FullyConnectedParams p{};
        p.input_offset=-x->quantization()->zero_point()->Get(0);
        p.output_offset=y->quantization()->zero_point()->Get(0);
        double scale=double(x->quantization()->scale()->Get(0))*double(w->quantization()->scale()->Get(0))/double(y->quantization()->scale()->Get(0));
        QuantizeMultiplier(scale,&p.output_multiplier,&p.output_shift);
        p.quantized_activation_min=op->builtin_options_as_FullyConnectedOptions()->fused_activation_function()==ActivationFunctionType_RELU ? p.output_offset : -128;
        p.quantized_activation_max=127;
        data[yi].resize(n); std::vector<int8_t> unmodified(n);
        RuntimeShape xs(2),ws(2),bs(1),ys(2);
        xs.SetDim(0,1);xs.SetDim(1,k);ws.SetDim(0,n);ws.SetDim(1,k);
        bs.SetDim(0,n);ys.SetDim(0,1);ys.SetDim(1,n);
        reference_integer_ops::FullyConnected(p,xs,data[xi].data(),ws,weights,bs,bi>=0?bias.data():nullptr,ys,unmodified.data());
        oracle_rows.clear();
        reference_traced::FullyConnected(p,xs,data[xi].data(),ws,weights,bs,bi>=0?bias.data():nullptr,ys,data[yi].data());
        CHECK(data[yi]==unmodified); CHECK(oracle_rows.size()==size_t(n));
        for (int c=0;c<n;++c) oracle_rows[c].output=data[yi][c];
        rows.push_back(oracle_rows);
    }
    return rows;
}
static std::vector<std::vector<Row>> actual;
static size_t compared, cases;
static void capture(void *,unsigned layer,unsigned channel,int32_t acc,int32_t q,int8_t output) {
    if (actual.size()<=layer) actual.resize(layer+1);
    CHECK(actual[layer].size()==channel);
    actual[layer].push_back({acc,q,output});
    // API must reject recursive invocation without changing the active model.
    CHECK(psc_tflite_invoke()==PSC_TFLITE_ERR_BUSY);
    CHECK(psc_tflite_reset()==PSC_TFLITE_ERR_BUSY);
    CHECK(psc_tflite_prepare(nullptr,0)==PSC_TFLITE_ERR_BUSY);
}
static std::vector<std::vector<Row>> compare(ModelT m,std::vector<int8_t> input) {
    auto b=pack(m); alignas(16) uint8_t bytes[8192]; CHECK(b.size()<=sizeof(bytes)); memcpy(bytes,b.data(),b.size());
    auto expected=reference(bytes,input);
    CHECK(psc_tflite_prepare(bytes,b.size())==0);
    size_t size=999; CHECK(!psc_tflite_get_output(&size)&&size==0);
    auto *x=psc_tflite_get_input(&size); CHECK(x&&size==input.size()); memcpy(x,input.data(),size);
    actual.clear(); CHECK(psc_tflite_invoke_traced(capture,nullptr,nullptr)==0);
    CHECK(actual.size()==expected.size());
    for (unsigned l=0;l<expected.size();++l) {
        CHECK(actual[l].size()==expected[l].size());
        for (unsigned c=0;c<expected[l].size();++c) {
            auto a=actual[l][c], e=expected[l][c];
            CHECK(a.acc==e.acc); CHECK(a.requant==e.requant); CHECK(a.output==e.output); ++compared;
        }
    }
    auto *y=psc_tflite_get_output(&size); CHECK(y&&size==expected.back().size());
    for (unsigned c=0;c<size;++c) CHECK(y[c]==expected.back()[c].output);
    CHECK(psc_tflite_invoke()==0); // no trace path must match too
    for (unsigned c=0;c<size;++c) CHECK(y[c]==expected.back()[c].output);
    psc_tflite_reset(); CHECK(!psc_tflite_get_input(&size)&&size==0);
    CHECK(psc_tflite_invoke()==PSC_TFLITE_ERR_GRAPH);
    ++cases; return expected;
}
static void rejected(ModelT m) {
    auto b=pack(m); alignas(16) uint8_t bytes[8192]; CHECK(b.size()<=sizeof(bytes)); memcpy(bytes,b.data(),b.size());
    CHECK(psc_tflite_prepare(bytes,b.size())<0);
    size_t n; CHECK(!psc_tflite_get_input(&n)&&n==0); CHECK(!psc_tflite_get_output(&n)&&n==0);
    CHECK(psc_tflite_arena_used()==0); ++cases;
}
#ifndef PSC_PHASE4_TEST
int main(int argc,char **argv) {
    CHECK(argc==2);
    auto model=demo(); auto b=pack(model); auto gold=compare(demo(),demo_input);
    std::ofstream(std::string(argv[1])+"/MODEL.TFL",std::ios::binary).write(reinterpret_cast<const char *>(b.data()),b.size());
    std::ofstream trace(std::string(argv[1])+"/reference.csv"); trace<<"layer,channel,accumulator,requant_with_zero_point,clamped_output\n";
    std::ostringstream header;
    header<<"/* Generated by tests/tflite/generate_model.py; do not edit. */\n#ifndef PSC_TFLITE_DEMO_H\n#define PSC_TFLITE_DEMO_H\n";
    header<<"static const int8_t demo_input[16] = {";
    for (auto x:demo_input) header<<int(x)<<",";
    header<<"};\nstatic const int32_t demo_trace[20][3] = {\n";
    for (unsigned l=0;l<gold.size();++l) for (unsigned c=0;c<gold[l].size();++c) {
        auto r=gold[l][c]; trace<<l<<","<<c<<","<<r.acc<<","<<r.requant<<","<<int(r.output)<<"\n";
        header<<"{"<<r.acc<<","<<r.requant<<","<<int(r.output)<<"},\n";
    }
    header<<"};\n#endif\n";
    std::ofstream(std::string(argv[1])+"/tflite_demo.h")<<header.str();
    // Quantization boundaries: upstream two-stage negative rounding, not >>.
    for (double scale : {.125,.25,.5,.99999999,1.,1.25,2.,0.000000000001}) {
        int32_t m;int s; CHECK(psc_tflite_quantize(scale,&m,&s)==0);
        int32_t rm;int rs;QuantizeMultiplier(scale,&rm,&rs);CHECK(m==rm&&s==rs);
        for (int x=-4097;x<=4097;++x) CHECK(psc_tflite_requantize(x,m,s)==MultiplyByQuantizedMultiplier(x,rm,rs));
    }
    CHECK(psc_tflite_requantize(-1,1073741824,0)==0);
    CHECK(psc_tflite_requantize(-2,1073741824,-1)==-1);
    CHECK(psc_tflite_requantize(2,1073741824,-1)==1);
    // Arbitrary asymmetric input/output zero points, both signs and extremes.
    for (int zero : {-128,-3,0,17,127}) for (int v : {-128,-1,0,1,127}) {
        auto m=demo();m.subgraphs[0]->tensors[0]->quantization->zero_point={zero};
        compare(std::move(m),std::vector<int8_t>(16,int8_t(v)));
    }
    // No bias slots, zero bias and a non-multiple-of-four reduction depth.
    auto m=demo();for(auto &op:m.subgraphs[0]->operators) op->inputs[2]=-1;
    compare(std::move(m),demo_input);
    compare(fixture(),demo_input);
    m=demo(); m.subgraphs[0]->tensors[0]->shape={1,15};m.subgraphs[0]->tensors[0]->shape_signature={1,15};
    m.subgraphs[0]->tensors[1]->shape={16,15};m.subgraphs[0]->tensors[1]->shape_signature={16,15};m.buffers[1]->data.resize(240);
    auto short_input=demo_input;short_input.pop_back();compare(std::move(m),short_input);
    // Non-power-of-two scales and multipliers greater than one.
    for(float s:{.0037f,.31f,1.25f,2.f}) {
        m=demo(); m.subgraphs[0]->tensors[6]->quantization->scale={s}; compare(std::move(m),demo_input);
    }
    m=demo();set_bias(m,4,0,100000);set_bias(m,4,1,-100000);
    auto saturation=compare(std::move(m),demo_input);CHECK(saturation[1][0].output==127&&saturation[1][1].output==-128);
    bool positive=false,negative=false,relu=false;
    for (auto r:gold[0]) {positive|=r.acc>0;negative|=r.acc<0;relu|=r.requant < -17 && r.output==-17;}
    CHECK(positive&&negative&&relu);
    // End-to-end FC rounding at both signs of exact half-way boundaries.
    for (float scale : {.0625f,.125f}) {
        m=demo();m.subgraphs[0]->operators.resize(1);m.subgraphs[0]->outputs={3};
        m.subgraphs[0]->operators[0]->builtin_options.AsFullyConnectedOptions()->fused_activation_function=ActivationFunctionType_NONE;
        m.subgraphs[0]->tensors[3]->quantization->scale={scale};
        std::fill(m.buffers[1]->data.begin(),m.buffers[1]->data.end(),0);
        for(unsigned c=0;c<16;++c)set_bias(m,2,c,int(c)-8);
        compare(std::move(m),demo_input);
    }
    auto bad=[&](auto change){auto m=demo();change(m);rejected(std::move(m));};
    bad([](auto &m){m.subgraphs[0]->tensors[1]->shape[1]=15;});
    bad([](auto &m){m.subgraphs[0]->tensors[0]->type=TensorType_UINT8;});
    bad([](auto &m){m.subgraphs[0]->operators[0]->builtin_options.AsFullyConnectedOptions()->fused_activation_function=ActivationFunctionType_RELU6;});
    bad([](auto &m){m.subgraphs[0]->tensors[0]->quantization->scale={0};});
    bad([](auto &m){m.subgraphs[0]->tensors[0]->quantization->scale={-1};});
    bad([](auto &m){m.subgraphs[0]->tensors[0]->quantization->scale={NAN};});
    bad([](auto &m){m.subgraphs[0]->tensors[6]->quantization->scale={1e-30f};});
    bad([](auto &m){m.subgraphs[0]->tensors[2]->quantization->scale={1.f};});
    bad([](auto &m){set_bias(m,2,0,INT32_MAX);});
    bad([](auto &m){m.buffers[2]->data.pop_back();});
    bad([](auto &m){m.subgraphs[0]->tensors[0]->quantization->zero_point={128};});
    printf("PASS: Phase 3 %zu models/cases, %zu channel accumulator/requant/clamp comparisons; 65560 multiplier comparisons\n",cases,compared);
    printf("Demo bytes=%zu; official TFLM reference output:",b.size()); for(auto r:gold.back())printf(" %d",int(r.output));puts("");
}
#endif
