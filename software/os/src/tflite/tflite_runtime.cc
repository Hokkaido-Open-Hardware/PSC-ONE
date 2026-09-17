#include "tflite_api.h"
#include "tflite_quant.h"
#include "tflite_synap.h"
#include "schema_generated.h"
#include <limits.h>

namespace {
struct FC {
    const int8_t *x, *w;
    const uint8_t *bias;
    int8_t *y;
    int32_t *row_sum;
    int k, n, input_zero, output_zero, multiplier, shift, minimum;
};
struct Runtime {
    alignas(16) uint8_t arena[PSC_TFLITE_ARENA_CAPACITY];
    FC fc[PSC_TFLITE_MAX_OPERATORS];
    int8_t *input, *output;
    size_t input_bytes, output_bytes, used;
    unsigned count, tile;
    psc_tflite_fc_backend backend;
    bool profiling;
    psc_tflite_profile_t profile;
    bool prepared, output_valid, invoking;
};
Runtime rt;
void *allocate(size_t bytes) {
    size_t pos = (rt.used + 3) & ~size_t(3);
    if (bytes > sizeof(rt.arena) - pos) return nullptr;
    rt.used = pos + bytes;
    return rt.arena + pos;
}
int32_t bias_at(const FC &f, int c) {
    return f.bias ? flatbuffers::ReadScalar<int32_t>(f.bias + 4*c) : 0;
}
int prepare(const void *data, size_t size) {
    int rc = psc_tflite_inspect(data, size, nullptr, nullptr, nullptr);
    if (rc) return rc;
    const auto *m = tflite::GetModel(data);
    const auto *g = m->subgraphs()->Get(0);
    int8_t *tensors[PSC_TFLITE_MAX_TENSORS] = {};
    size_t lengths[PSC_TFLITE_MAX_TENSORS] = {};
    for (unsigned i = 0; i < g->tensors()->size(); ++i) {
        const auto *t = g->tensors()->Get(i);
        const auto *b = m->buffers()->Get(t->buffer())->data();
        if (b && b->size()) continue; // constants remain in model buffer
        size_t bytes = t->type() == tflite::TensorType_INT32 ? 4 : 1;
        for (auto d : *t->shape()) bytes *= d;
        tensors[i] = static_cast<int8_t *>(allocate(bytes));
        if (!tensors[i]) return PSC_TFLITE_ERR_SIZE;
        lengths[i] = bytes;
    }
    rt.count = g->operators()->size();
    for (unsigned i = 0; i < rt.count; ++i) {
        const auto *op = g->operators()->Get(i);
        int xi=op->inputs()->Get(0), wi=op->inputs()->Get(1);
        int bi=op->inputs()->Get(2), yi=op->outputs()->Get(0);
        const auto *x=g->tensors()->Get(xi), *w=g->tensors()->Get(wi), *y=g->tensors()->Get(yi);
        FC &f=rt.fc[i];
        const auto *xb=m->buffers()->Get(x->buffer())->data();
        f.x = xb && xb->size() ? reinterpret_cast<const int8_t *>(xb->data()) : tensors[xi];
        f.w = reinterpret_cast<const int8_t *>(m->buffers()->Get(w->buffer())->data()->data());
        f.y = tensors[yi];
        f.bias = bi < 0 ? nullptr : m->buffers()->Get(g->tensors()->Get(bi)->buffer())->data()->data();
        f.k=w->shape()->Get(1); f.n=w->shape()->Get(0);
        f.input_zero=x->quantization()->zero_point()->Get(0);
        f.output_zero=y->quantization()->zero_point()->Get(0);
        double scale=static_cast<double>(x->quantization()->scale()->Get(0)) *
                     static_cast<double>(w->quantization()->scale()->Get(0)) /
                     static_cast<double>(y->quantization()->scale()->Get(0));
        rc=psc_tflite_quantize(scale, &f.multiplier, &f.shift);
        if (rc) return rc;
        f.minimum=op->builtin_options_as_FullyConnectedOptions()->fused_activation_function() ==
                  tflite::ActivationFunctionType_RELU ? f.output_zero : -128;
        f.row_sum=static_cast<int32_t *>(allocate(f.n * sizeof(int32_t)));
        if (!f.row_sum) return PSC_TFLITE_ERR_SIZE;
        for (int c=0; c<f.n; ++c) {
            int64_t low=bias_at(f,c), high=low;
            int32_t sum=0;
            for (int k=0; k<f.k; ++k) {
                int v=f.w[c*f.k+k]; sum+=v;
                int a=(-128-f.input_zero)*v, b=(127-f.input_zero)*v;
                low+=a<b?a:b; high+=a>b?a:b;
            }
            f.row_sum[c]=sum;
            /* Upstream double-rounding multiplies acc by (1<<left_shift)
               in INT32. Prove its domain for EVERY possible INT8 input.
               Reserve 128 for output zero-point addition as well. */
            int64_t factor=int64_t(1) << (f.shift>0?f.shift:0);
            if (low < (INT32_MIN+128)/factor || high > (INT32_MAX-128)/factor)
                return PSC_TFLITE_ERR_GRAPH;
        }
    }
    unsigned input=g->inputs()->Get(0), output=g->outputs()->Get(0);
    rt.input=tensors[input]; rt.output=tensors[output];
    rt.input_bytes=lengths[input]; rt.output_bytes=lengths[output];
    rt.prepared=true;
    return 0;
}
} // namespace
extern "C" int psc_tflite_reset(void) {
    if (rt.invoking) return PSC_TFLITE_ERR_BUSY;
    rt={}; rt.tile=4; return 0;
}
extern "C" int psc_tflite_prepare(const void *data, size_t size) {
    if (rt.invoking) return PSC_TFLITE_ERR_BUSY;
    psc_tflite_reset();
    int rc=prepare(data,size);
    if (rc) psc_tflite_reset();
    return rc;
}
extern "C" int8_t *psc_tflite_get_input(size_t *bytes) {
    if (bytes) *bytes=rt.prepared ? rt.input_bytes : 0;
    return rt.prepared && !rt.invoking ? rt.input : nullptr;
}
extern "C" const int8_t *psc_tflite_get_output(size_t *bytes) {
    if (bytes) *bytes=rt.output_valid ? rt.output_bytes : 0;
    return rt.output_valid && !rt.invoking ? rt.output : nullptr;
}
extern "C" size_t psc_tflite_arena_used(void) { return rt.used; }
extern "C" int psc_tflite_set_fc_backend(psc_tflite_fc_backend backend) {
    if(rt.invoking) return PSC_TFLITE_ERR_BUSY;
    if(backend!=PSC_TFLITE_FC_CPU && backend!=PSC_TFLITE_FC_SYNAP) return PSC_TFLITE_ERR_UNSUPPORTED;
    rt.backend=backend;rt.output_valid=false;return 0;
}
extern "C" int psc_tflite_set_synap_tile_size(unsigned tile) {
    if(rt.invoking) return PSC_TFLITE_ERR_BUSY;
    if(tile<4 || tile>16 || tile%4) return PSC_TFLITE_ERR_UNSUPPORTED;
    rt.tile=tile;rt.output_valid=false;return 0;
}
extern "C" int psc_tflite_set_profiling(int enabled) {
    if(rt.invoking) return PSC_TFLITE_ERR_BUSY;
    rt.profiling=enabled!=0;return 0;
}
extern "C" const psc_tflite_profile_t *psc_tflite_get_profile(void) { return &rt.profile; }
static int invoke(psc_tflite_trace_fn trace,psc_tflite_trace_ex_fn detail,psc_tflite_layer_fn layer,void *user) {
    if (rt.invoking) return PSC_TFLITE_ERR_BUSY;
    if (!rt.prepared) return PSC_TFLITE_ERR_GRAPH;
    rt.invoking=true; rt.output_valid=false;rt.profile={};rt.profile.valid=rt.profiling;
    for (unsigned i=0; i<rt.count; ++i) {
        const FC &f=rt.fc[i];
        if (layer) layer(user,i,1);
        unsigned block=rt.backend==PSC_TFLITE_FC_SYNAP ? rt.tile : 1;
        for(unsigned first=0;first<unsigned(f.n);first+=block) {
            unsigned n=unsigned(f.n)-first<block ? unsigned(f.n)-first : block;
            int32_t dots[16];
            if(rt.backend==PSC_TFLITE_FC_SYNAP) {
                int rc=psc_tflite_synap_dot(f.x,f.w+first*f.k,f.k,n,rt.tile,dots,rt.profiling?&rt.profile:nullptr);
                if(rc) {
                    if(layer) layer(user,i,0);
                    rt.profile.valid=0;rt.invoking=false;return rc;
                }
            } else {
                // Phase 3 CPU reference dot is retained, including INT32 accumulation.
                dots[0]=0;
                for(int k=0;k<f.k;++k) dots[0]+=int32_t(f.x[k])*f.w[first*f.k+k];
            }
            int before=rt.profiling?psc_tflite_clock_us():-1;
            for(unsigned local=0;local<n;++local) {
                unsigned c=first+local;int32_t dot=dots[local];
                int32_t corrected=static_cast<int32_t>(int64_t(dot)-int64_t(f.input_zero)*f.row_sum[c]);
                int32_t acc=static_cast<int32_t>(int64_t(corrected)+bias_at(f,c));
                int32_t q=psc_tflite_requantize(acc,f.multiplier,f.shift)+f.output_zero;
                int32_t clamped=q<f.minimum ? f.minimum : (q>127 ? 127 : q);
                f.y[c]=static_cast<int8_t>(clamped);
                if(trace) trace(user,i,c,acc,q,f.y[c]);
                if(detail) detail(user,i,c,dot,corrected,acc,q,f.y[c]);
            }
            if(rt.profiling) {
                int after=psc_tflite_clock_us();
                if(before<0 || after<before) rt.profile.valid=0;
                else rt.profile.post_us+=uint32_t(after-before);
            }
        }
        if (layer) layer(user,i,0);
    }
    rt.invoking=false; rt.output_valid=true;
    return 0;
}
extern "C" int psc_tflite_invoke_traced(psc_tflite_trace_fn trace,psc_tflite_layer_fn layer,void *user) {
    return invoke(trace,nullptr,layer,user);
}
extern "C" int psc_tflite_invoke_detailed(psc_tflite_trace_ex_fn trace,void *user) {
    return invoke(nullptr,trace,nullptr,user);
}
extern "C" int psc_tflite_invoke(void) { return invoke(nullptr,nullptr,nullptr,nullptr); }


/* Read-only diagnostics: byte loads also expose alignment/endian differences.
   No quantization/backend state is changed. Addresses are virtual on PSC-OS. */
namespace {
struct DebugLog {
    psc_tflite_log_fn fn; void *user;
    void text(const char *s) const { if (fn) fn(user,s); }
    void number(int32_t n) const {
        char b[12]; unsigned p=sizeof(b); b[--p]=0;
        uint32_t u=n<0 ? 0u-uint32_t(n) : uint32_t(n);
        do { b[--p]='0'+u%10; u/=10; } while(u);
        if(n<0)b[--p]='-'; text(b+p);
    }
    void hex(uintptr_t v) const {
        char b[2+sizeof(v)*2+1]; b[0]='0';b[1]='x';b[sizeof(b)-1]=0;
        for(unsigned i=0;i<sizeof(v)*2;++i) {b[sizeof(b)-2-i]="0123456789abcdef"[v&15];v>>=4;}
        text(b);
    }
    void value(const char *s,int32_t n) const {text(s);number(n);}
    void pointer(const char *s,const void *p) const {text(s);hex(reinterpret_cast<uintptr_t>(p));}
};
uint32_t debug_sum(const uint8_t *p,size_t n) {
    uint32_t sum=0;for(size_t i=0;i<n;++i)sum+=p[i];return sum;
}
int32_t debug_le32(const uint8_t *p) {
    return int32_t(uint32_t(p[0])|(uint32_t(p[1])<<8)|(uint32_t(p[2])<<16)|(uint32_t(p[3])<<24));
}
}
extern "C" int psc_tflite_debug_model(const void *data,size_t size,psc_tflite_log_fn log,void *user) {
    if(rt.invoking)return PSC_TFLITE_ERR_BUSY;
    DebugLog out{log,user};
    const auto *base=static_cast<const uint8_t *>(data);
    out.pointer("MODEL pointer=",data);out.value(" bytes=",size);
    if(data && size<=PSC_TFLITE_MODEL_CAPACITY)out.value(" byte_sum=",debug_sum(base,size));
    out.text("\n");
    int rc=psc_tflite_inspect(data,size,nullptr,nullptr,nullptr);
    if(rc) {out.value("MODEL verification error=",rc);out.text("\n");return rc;}
    const auto *m=tflite::GetModel(data);const auto *g=m->subgraphs()->Get(0);
    for(unsigned i=0;i<g->tensors()->size();++i) {
        const auto *t=g->tensors()->Get(i);const auto *b=m->buffers()->Get(t->buffer())->data();
        if(!b || !b->size())continue;
        const auto *p=b->data();
        out.value("Tensor=",i);out.value(" buffer=",t->buffer());
        out.value(" data_offset=",p-base);out.value(" length=",b->size());
        out.pointer(" pointer=",p);out.value(" align_mod4=",reinterpret_cast<uintptr_t>(p)&3);
        out.value(" byte_sum=",debug_sum(p,b->size()));out.text("\n first32 hex:");
        for(unsigned j=0;j<b->size() && j<32;++j) {
            char h[4]={' ',"0123456789abcdef"[p[j]>>4],"0123456789abcdef"[p[j]&15],0};out.text(h);
        }
        out.text("\n");
        if(t->type()==tflite::TensorType_INT32) {
            out.text(" bias LE32:");
            for(unsigned j=0;j<b->size()/4;++j)out.value(" ",debug_le32(p+4*j));
            out.text("\n bias ReadScalar:");
            for(unsigned j=0;j<b->size()/4;++j)out.value(" ",flatbuffers::ReadScalar<int32_t>(p+4*j));
            out.text("\n");
        }
    }
    return 0;
}
extern "C" int psc_tflite_debug_fc(psc_tflite_log_fn log,void *user) {
    if(rt.invoking)return PSC_TFLITE_ERR_BUSY;
    if(!rt.prepared)return PSC_TFLITE_ERR_GRAPH;
    DebugLog out{log,user};out.pointer("Runtime=",&rt);out.pointer(" arena=",rt.arena);out.text("\n");
    for(unsigned i=0;i<rt.count;++i) {
        const FC &f=rt.fc[i];out.value("FC=",i+1);out.value(" k=",f.k);out.value(" n=",f.n);
        out.pointer(" input=",f.x);out.pointer(" weight=",f.w);out.pointer(" bias=",f.bias);
        out.value(" weight_byte_sum=",debug_sum(reinterpret_cast<const uint8_t *>(f.w),f.k*f.n));
        out.value(" input_zero=",f.input_zero);out.value(" output_zero=",f.output_zero);out.text("\n");
    }
    const FC &f=rt.fc[0];int32_t dot=0;
    for(int k=0;k<f.k;++k) {
        int32_t x=f.x[k],w=f.w[k],product=x*w;dot+=product;
        if(k<16) {out.value("FC1 c=0 k=",k);out.value(" input=",x);out.value(" weight=",w);
            out.value(" product=",product);out.value(" running_dot=",dot);out.text("\n");}
    }
    out.value("FC1 c=0 raw_dot=",dot);out.value(" row_sum=",f.row_sum[0]);
    out.value(" bias=",bias_at(f,0));out.text("\n");return 0;
}
