#include "tflite_api.h"
#include "tflite_graph.h"
#include "tflite_quant.h"
#include "tflite_synap.h"
#include "schema_generated.h"
#include <limits.h>
#include "psc/pulp_fc.h"

#ifndef PSC_TFLITE_HAS_SYNAP
#define PSC_TFLITE_HAS_SYNAP 0
#endif
extern "C" __attribute__((weak)) int psc_tflite_synap_available(void){return PSC_TFLITE_HAS_SYNAP;}
namespace {
struct FC {
    const int8_t *x, *w;
    const uint8_t *bias;
    int8_t *y;
    int32_t *row_sum;
    int m, k, n, input_zero, output_zero, multiplier, shift, minimum;
};
struct Runtime {
    alignas(16) uint8_t arena[PSC_TFLITE_ARENA_CAPACITY];
    FC fc[PSC_TFLITE_MAX_OPERATORS];
    const void *model;
    int8_t *input, *output;
    size_t input_bytes, output_bytes, used;
    unsigned count, tile;
    psc_tflite_fc_backend backend;
    bool profiling;
    psc_tflite_profile_t profile;
    psc_tflite_execution_t execution;
    psc_tflite_operator_profile_t records[512];
    bool prepared, output_valid, invoking, generic;
};
Runtime rt;
size_t arena_required;
size_t arena_available=PSC_TFLITE_ARENA_CAPACITY;
// Shared synchronous scratch, protected by rt.invoking; never put a 64x64 tile on the stack.
alignas(16) int32_t dots[SA_MAT_MAX*SA_MAT_MAX];
void *allocate(size_t bytes) {
    size_t pos = (rt.used + 3) & ~size_t(3);
    if (bytes > sizeof(rt.arena) - pos) return nullptr;
    rt.used = pos + bytes;
    return rt.arena + pos;
}
int32_t bias_at(const FC &f, int c) {
    return f.bias ? flatbuffers::ReadScalar<int32_t>(f.bias + 4*c) : 0;
}
// Conservative, measured shape allowlist; do not extrapolate to padded tiles.
// See AUTO.md and tests/tflite/auto_results.json. Selection is O(1) per FC.
psc_tflite_fc_backend select(const FC &f, const char **reason, unsigned *tile) {
    *tile=rt.tile;
    if (rt.backend==PSC_TFLITE_FC_CPU || rt.backend==PSC_TFLITE_FC_SYNAP) {
        if(rt.backend==PSC_TFLITE_FC_SYNAP&&!psc_tflite_synap_available()) {
            *reason="NPU unavailable; CPU fallback";return PSC_TFLITE_FC_CPU;
        }
        *reason="explicit backend"; return rt.backend;
    }
    if(psc_tflite_synap_available() && rt.backend==PSC_TFLITE_FC_AUTO && (f.m==16 || f.m==32) && f.k==f.m && f.n==f.m) {
        *tile=f.m; *reason="measured OS FC advantage including packing/copies/start/wait; one unpadded tile";
        return PSC_TFLITE_FC_SYNAP;
    }
#if PSC_HAS_CV_DOTSP_B || defined(PSC_PULP_TEST_EMULATE)
    if(f.k>=4 && f.k<=8192) {
        *reason=rt.backend==PSC_TFLITE_FC_AUTO ? "outside calibrated NPU shapes; SIMD FC" : "explicit PULP";
        return PSC_TFLITE_FC_PULP;
    }
    *reason="FC depth below SIMD width";
#else
    *reason="PULP disabled in this build; CPU fallback";
#endif
    return PSC_TFLITE_FC_CPU;
}
int prepare(const void *data, size_t size) {
    int rc = psc_tflite_inspect(data, size, nullptr, nullptr, nullptr);
    if (rc) return rc;
    rt.model=data;
    if(!psc_tflite_graph_is_fc(data)) {
        rt.generic=true;rt.tile=32;
        size_t capacity;uint8_t *arena=psc_tflite_graph_arena(&capacity);arena_available=capacity;
        rc=psc_tflite_graph_prepare(data,size,arena,capacity,&arena_required,
            &rt.input,&rt.input_bytes,&rt.output,&rt.output_bytes);
        if(!rc){rt.used=arena_required;rt.prepared=true;}
        return rc;
    }
    const auto *m = tflite::GetModel(data);
    const auto *g = m->subgraphs()->Get(0);
    // Plan independently of allocation, so failure reports the full requirement.
    for (const auto *t : *g->tensors()) {
        const auto *b = m->buffers()->Get(t->buffer())->data();
        if (b && b->size()) continue;
        size_t bytes = t->type() == tflite::TensorType_INT32 ? 4 : 1;
        for (auto d : *t->shape()) bytes *= d;
        arena_required = ((arena_required + 3) & ~size_t(3)) + bytes;
    }
    for (const auto *op : *g->operators()) {
        const auto *w = g->tensors()->Get(op->inputs()->Get(1));
        arena_required = ((arena_required + 3) & ~size_t(3)) + w->shape()->Get(0) * sizeof(int32_t);
    }
    if (arena_required > sizeof(rt.arena)) return PSC_TFLITE_ERR_ARENA;
    int8_t *tensors[PSC_TFLITE_MAX_TENSORS] = {};
    size_t lengths[PSC_TFLITE_MAX_TENSORS] = {};
    for (unsigned i = 0; i < g->tensors()->size(); ++i) {
        const auto *t = g->tensors()->Get(i);
        const auto *b = m->buffers()->Get(t->buffer())->data();
        if (b && b->size()) continue; // constants remain in model buffer
        size_t bytes = t->type() == tflite::TensorType_INT32 ? 4 : 1;
        for (auto d : *t->shape()) bytes *= d;
        tensors[i] = static_cast<int8_t *>(allocate(bytes));
        if (!tensors[i]) return PSC_TFLITE_ERR_ARENA;
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
        f.m=x->shape()->Get(0); f.k=w->shape()->Get(1); f.n=w->shape()->Get(0);
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
        if (!f.row_sum) return PSC_TFLITE_ERR_ARENA;
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
    rt={}; psc_tflite_graph_reset(); arena_required=0; arena_available=PSC_TFLITE_ARENA_CAPACITY;rt.tile=4; return 0;
}
extern "C" int psc_tflite_prepare(const void *data, size_t size) {
    if (rt.invoking) return PSC_TFLITE_ERR_BUSY;
    psc_tflite_reset();
    int rc=prepare(data,size);
    if (rc) { size_t required=arena_required,available=arena_available; psc_tflite_reset(); arena_required=required;arena_available=available; }
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
extern "C" size_t psc_tflite_arena_required(void) { return arena_required; }
extern "C" size_t psc_tflite_arena_used(void) { return rt.used; }
extern "C" int psc_tflite_set_fc_backend(psc_tflite_fc_backend backend) {
    if(rt.invoking) return PSC_TFLITE_ERR_BUSY;
    if(backend!=PSC_TFLITE_FC_CPU && backend!=PSC_TFLITE_FC_SYNAP && backend!=PSC_TFLITE_FC_PULP && backend!=PSC_TFLITE_FC_AUTO) return PSC_TFLITE_ERR_UNSUPPORTED;
    rt.backend=backend;rt.output_valid=false;return 0;
}
extern "C" int psc_tflite_set_synap_tile_size(unsigned tile) {
    if(rt.invoking) return PSC_TFLITE_ERR_BUSY;
    if(tile<4 || tile>SA_MAT_MAX || tile%4) return PSC_TFLITE_ERR_UNSUPPORTED;
    rt.tile=tile;rt.output_valid=false;return 0;
}
extern "C" int psc_tflite_set_profiling(int enabled) {
    if(rt.invoking) return PSC_TFLITE_ERR_BUSY;
    rt.profiling=enabled!=0;return 0;
}
extern "C" const psc_tflite_profile_t *psc_tflite_get_profile(void) { return &rt.profile; }
static void summarize() {
    rt.execution={};
    unsigned count=rt.generic?psc_tflite_graph_count():rt.count;
    for(unsigned i=0;i<count;++i){const auto &r=rt.records[i];if(r.status)continue;
        ++rt.execution.completed;++rt.execution.operators[r.backend];
        if(rt.backend!=PSC_TFLITE_FC_CPU && r.backend==PSC_TFLITE_FC_CPU)++rt.execution.fallbacks;
        int &us=rt.execution.invoke_us[r.backend];
        if(us<0||r.us<0||r.us>INT_MAX-us)us=-1;else us+=r.us;
    }
}
extern "C" const psc_tflite_execution_t *psc_tflite_get_execution(void){return &rt.execution;}
extern "C" const psc_tflite_operator_profile_t *psc_tflite_get_operator_profile(unsigned i){
    return i<(rt.generic?psc_tflite_graph_count():rt.count)?&rt.records[i]:nullptr;
}
extern "C" const char *psc_tflite_get_operator_reason(unsigned i){
    if(!rt.prepared||rt.invoking||i>=rt.execution.completed)return nullptr;
    if(rt.generic)return psc_tflite_graph_reason(i,rt.backend,rt.records[i].backend);
    const char *reason;unsigned tile;select(rt.fc[i],&reason,&tile);return reason;
}
static int invoke(psc_tflite_trace_fn trace,psc_tflite_trace_ex_fn detail,psc_tflite_layer_fn layer,void *user) {
    if (rt.invoking) return PSC_TFLITE_ERR_BUSY;
    if (!rt.prepared) return PSC_TFLITE_ERR_GRAPH;
    rt.invoking=true; rt.output_valid=false;rt.profile={};rt.profile.valid=rt.profiling;
    rt.execution={};
    for(auto &r:rt.records)r={0,0,-1,-205,0};
    if(rt.generic) {
        int rc=psc_tflite_graph_invoke(layer,user,rt.backend,rt.tile,dots,rt.records,rt.profiling?&rt.profile:nullptr);
        summarize();
        if(rc)rt.profile.valid=0;
        rt.invoking=false;rt.output_valid=rc==0;return rc;
    }
    for (unsigned i=0; i<rt.count; ++i) {
        const FC &f=rt.fc[i];
        if (layer) layer(user,i,1);
        const char *reason; unsigned tile;
        const auto backend=select(f,&reason,&tile);
        auto &record=rt.records[i];record={9,int(backend),-1,-205,0};
        int op_start=psc_tflite_clock_us();uint32_t old_tiles=rt.profile.tiles;
        unsigned block=backend==PSC_TFLITE_FC_SYNAP ? tile : 1;
        for(unsigned row=0;row<unsigned(f.m);row+=block) {
          unsigned m=unsigned(f.m)-row<block ? unsigned(f.m)-row : block;
          for(unsigned first=0;first<unsigned(f.n);first+=block) {
            unsigned n=unsigned(f.n)-first<block ? unsigned(f.n)-first : block;
            const int8_t *x=f.x+row*f.k;
            if(backend==PSC_TFLITE_FC_SYNAP) {
                int rc=psc_tflite_synap_batch(x,f.w+first*f.k,m,f.k,n,tile,dots,rt.profiling?&rt.profile:nullptr);
                if(rc) {
                    if(layer) layer(user,i,0);
                    record.status=rc;rt.profile.valid=0;summarize();rt.invoking=false;return rc;
                }
            } else if(backend==PSC_TFLITE_FC_PULP &&
                      psc_tflite_pulp::try_dot(x,f.w+first*f.k,f.k,0,true,&dots[0])) {
                // Raw dot only; all backends share quantization below.
            } else {
                dots[0]=0;
                for(int k=0;k<f.k;++k) dots[0]+=int32_t(x[k])*f.w[first*f.k+k];
            }
            int before=rt.profiling?psc_tflite_clock_us():-1;
            for(unsigned sample=0;sample<m;++sample) for(unsigned local=0;local<n;++local) {
                unsigned c=first+local, index=(row+sample)*f.n+c;
                int32_t dot=dots[sample*n+local];
                int32_t corrected=static_cast<int32_t>(int64_t(dot)-int64_t(f.input_zero)*f.row_sum[c]);
                int32_t acc=static_cast<int32_t>(int64_t(corrected)+bias_at(f,c));
                int32_t q=psc_tflite_requantize(acc,f.multiplier,f.shift)+f.output_zero;
                int32_t clamped=q<f.minimum ? f.minimum : (q>127 ? 127 : q);
                f.y[index]=static_cast<int8_t>(clamped);
                if(trace) trace(user,i,index,acc,q,f.y[index]);
                if(detail) detail(user,i,index,dot,corrected,acc,q,f.y[index]);
            }
            if(rt.profiling) {
                int after=psc_tflite_clock_us();
                if(before<0 || after<before) rt.profile.valid=0;
                else rt.profile.post_us+=uint32_t(after-before);
            }
          }
        }
        int op_end=psc_tflite_clock_us();record.us=op_start>=0&&op_end>=op_start?op_end-op_start:-1;record.status=0;
        record.npu_tiles=rt.profile.tiles-old_tiles;
        if (layer) layer(user,i,0);
    }
    summarize();
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
    if(rt.generic){psc_tflite_graph_debug(log,user,rt.backend);return 0;}
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

extern "C" const char *psc_tflite_backend_name(psc_tflite_fc_backend backend) {
    switch(backend) {
    case PSC_TFLITE_FC_CPU:return "cpu";
    case PSC_TFLITE_FC_SYNAP:return "npu";
    case PSC_TFLITE_FC_PULP:return "pulp";
    case PSC_TFLITE_FC_AUTO:return "auto";
    default:return "unknown";
    }
}
extern "C" int psc_tflite_debug_selection(psc_tflite_log_fn log,void *user) {
    if(rt.invoking)return PSC_TFLITE_ERR_BUSY;
    if(!rt.prepared)return PSC_TFLITE_ERR_GRAPH;
    if(rt.generic){psc_tflite_graph_debug(log,user,rt.backend);return 0;}
    DebugLog out{log,user};
    for(unsigned i=0;i<rt.count;++i) {
        const FC &f=rt.fc[i]; const char *reason; unsigned tile;
        auto backend=select(f,&reason,&tile);
        out.value("FC=",i+1);out.value(" M=",f.m);out.value(" K=",f.k);out.value(" N=",f.n);
        out.value(" npu_tile=",tile);
        out.value(" npu_tiles=",((f.m+tile-1)/tile)*((f.k+tile-1)/tile)*((f.n+tile-1)/tile));
        out.value(" tail_M=",f.m%tile);out.value(" tail_K=",f.k%tile);out.value(" tail_N=",f.n%tile);
        out.text(" backend=");out.text(psc_tflite_backend_name(backend));
        out.text(" reason=");out.text(reason);out.text("\n");
    }
    return 0;
}

extern "C" size_t psc_tflite_arena_capacity(void){return arena_available;}
extern "C" int psc_tflite_set_tensor_trace(psc_tflite_tensor_trace_fn fn,void *user){if(rt.invoking)return -205;if(!rt.prepared||!rt.generic)return -202;psc_tflite_graph_trace(fn,user);return 0;}
extern "C" int psc_tflite_get_io_info(int output,psc_tflite_tensor_info_t *info){
    if(!info)return -203;*info={};if(!rt.prepared||rt.invoking)return -203;
    const auto *g=tflite::GetModel(rt.model)->subgraphs()->Get(0);int id=output?g->outputs()->Get(0):g->inputs()->Get(0);const auto *t=g->tensors()->Get(id);
    info->tensor=id;info->type=t->type();info->rank=t->shape()?t->shape()->size():0;info->bytes=output?rt.output_bytes:rt.input_bytes;
    for(int i=0;i<info->rank;++i)info->dims[i]=t->shape()->Get(i);
    const auto *q=t->quantization();if(q&&q->scale()&&q->scale()->size()){info->scale=q->scale()->Get(0);info->zero_point=q->zero_point()->Get(0);}return 0;
}

extern "C" unsigned psc_tflite_operator_count(void){return rt.prepared?(rt.generic?psc_tflite_graph_count():rt.count):0;}
