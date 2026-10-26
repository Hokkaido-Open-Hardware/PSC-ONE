#include "tflite_graph.h"
#include "tflite_cpu.h"
#include "tflite_quant.h"
#include "tflite_accel.h"
#include "tflite_synap.h"
#include "schema_generated.h"
#include <limits.h>
#include <cmath>

namespace {
constexpr unsigned analysis_limit=1024;
struct Log {
    psc_tflite_log_fn fn; void *user;
    void text(const char *s) const {if(fn)fn(user,s);}
    void num(uint32_t n) const {char b[11];unsigned p=10;b[p]=0;do{b[--p]='0'+n%10;n/=10;}while(n);text(b+p);}
    void field(const char *s,uint32_t n) const {text(s);num(n);}
    int fail(int code,const char *s) const {text("Rejected: ");text(s);text("\n");return code;}
};
template<class T> unsigned count(const T *v){return v?v->size():0;}
int builtin(const tflite::OperatorCode *c){return c->builtin_code()>c->deprecated_builtin_code()?c->builtin_code():c->deprecated_builtin_code();}
bool kernel(int code){return code==0||code==3||code==9||code==14||code==17||code==18||code==39||code==34||code==65||code==2||code==97||code==22||code==25||code==41||code==114||code==6;}
const char *name(int code){return tflite::EnumNameBuiltinOperator(static_cast<tflite::BuiltinOperator>(code));}
struct TensorPlan {uint32_t bytes,offset;int first,last;bool constant,ready,assigned;};
/* Bounded analysis workspace, separate from the prepared graph and Arena.
   No stack arrays proportional to an untrusted model count. Non-reentrant. */
TensorPlan plans[analysis_limit];
struct BufferView {const uint8_t *ptr;uint32_t bytes;};
BufferView buffers[analysis_limit];
struct Op {psc_tflite_cpu_op cpu;int x,w,b,y,inputs[16];unsigned ninputs;uint32_t params;};
struct Graph {
    Op ops[512];
    const uint8_t *data[analysis_limit];
    unsigned count;bool prepared;
    const tflite::Model *model;uint32_t bytes[analysis_limit];psc_tflite_tensor_trace_fn trace;void *trace_user;
} graph;
unsigned width(int type){
    switch(type){case tflite::TensorType_INT8:case tflite::TensorType_UINT8:case tflite::TensorType_BOOL:return 1;
    case tflite::TensorType_INT16:case tflite::TensorType_FLOAT16:return 2;
    case tflite::TensorType_INT32:case tflite::TensorType_FLOAT32:return 4;
    case tflite::TensorType_INT64:case tflite::TensorType_FLOAT64:return 8;default:return 0;}
}
bool scale(float s){return s>0 && std::isfinite(s) && std::isnormal(s);}
int verify(const void *data,size_t size,const tflite::Model **model,const Log &log){
    if(!data||size<8||size>PSC_TFLITE_MODEL_CAPACITY)return log.fail(-200,"model size");
    if((reinterpret_cast<uintptr_t>(data)&15)||memcmp(static_cast<const uint8_t *>(data)+4,"TFL3",4))return log.fail(-201,"alignment/TFL3 identifier");
    flatbuffers::Verifier::Options options;options.max_depth=16;options.max_tables=65536;
    flatbuffers::Verifier v(static_cast<const uint8_t *>(data),size,options);
    if(!tflite::VerifyModelBuffer(v))return log.fail(-201,"FlatBuffers bounds/table verification");
    *model=tflite::GetModel(data);
    if((*model)->version()!=3)return log.fail(-202,"schema version");
    return 0;
}
int analyze(const tflite::Model *m,const void *base,size_t size,const Log &log,psc_tflite_info_t &info){
    if(count(m->subgraphs())!=1||!count(m->buffers())||count(m->buffers())>analysis_limit||
       count(m->operator_codes())>analysis_limit)return log.fail(-202,"analysis count limit (1024)");
    if(count(m->external_buffers())||count(m->external_buffer_groups()))return log.fail(-202,"external buffers");
    const auto *g=m->subgraphs()->Get(0);unsigned nt=count(g->tensors()),no=count(g->operators());
    if(!nt||nt>analysis_limit||!no||no>analysis_limit)return log.fail(-202,"analysis tensor/operator limit (1024)");
    info.version=3;info.tensors=nt;info.operators=no;info.operator_codes=count(m->operator_codes());
    log.field("TFLite TFL3 bytes=",size);log.text(" schema=3\nFlatBuffer verified; subgraphs=1");
    log.field(" buffers=",count(m->buffers()));log.field(" opcodes=",info.operator_codes);
    log.field(" tensors=",nt);log.field(" operators=",no);log.text("\n");
    uint64_t constants=0,total=0;
    for(unsigned i=0;i<count(m->buffers());++i){
        const auto *b=m->buffers()->Get(i);auto &view=buffers[i];
        view={b->data()?b->data()->data():nullptr,count(b->data())};
        if(b->offset()>1){
            // Schema v3: offset is relative to the complete file, not Model.
            // Check uint64 values before narrowing or forming any pointer.
            if(view.bytes || b->offset()>size || b->size()>size-b->offset()) {
                log.field("Buffer ",i);return log.fail(-203,"out-of-line range/ambiguous inline data");
            }
            view={static_cast<const uint8_t *>(base)+size_t(b->offset()),uint32_t(b->size())};
            info.out_of_line_buffers++;
        } else if(b->size()) {log.field("Buffer ",i);return log.fail(-203,"size without valid out-of-line offset");}
        constants+=view.bytes;
    }
    log.field("Out-of-line buffer count: ",info.out_of_line_buffers);log.text(" (file bounds verified)\n");
    if(constants>UINT32_MAX)return log.fail(-203,"constant byte count overflow");
    info.constant_bytes=uint32_t(constants);
    if(buffers[0].bytes)return log.fail(-203,"buffer 0 must be empty");
    for(unsigned i=0;i<nt;++i){
        const auto *t=g->tensors()->Get(i);auto &p=plans[i];p={0,0,-1,0,false,false,false};
        if(t->buffer()>=count(m->buffers()))return log.fail(-203,"tensor buffer index");
        if(t->is_variable()||t->sparsity()||t->external_buffer())return log.fail(-202,"variable/sparse/external tensor");
        if(count(t->shape())>8)return log.fail(-202,"tensor rank > 8");
        if(count(t->shape_signature())&&count(t->shape_signature())!=count(t->shape()))return log.fail(-203,"shape_signature rank");
        uint64_t elements=1;bool dynamic=false;
        for(unsigned d=0;d<count(t->shape());++d){
            int dim=t->shape()->Get(d);
            if(dim<=0)return log.fail(-202,"nonpositive/dynamic shape");
            if(count(t->shape_signature())&&t->shape_signature()->Get(d)!=dim)dynamic=true;
            if(elements>uint64_t(INT32_MAX)/unsigned(dim))return log.fail(-203,"tensor element overflow");
            elements*=unsigned(dim);
        }
        if(dynamic)info.dynamic_tensors++;
        unsigned w=width(t->type());
        if(!w)return log.fail(-202,"tensor storage type not supported by analyzer");
        if(elements>uint64_t(INT32_MAX)/w)return log.fail(-203,"tensor byte overflow");
        p.bytes=uint32_t(elements*w);
        auto data=buffers[t->buffer()];p.constant=p.ready=data.bytes!=0;
        if(p.constant&&data.bytes!=p.bytes)return log.fail(-203,"constant buffer length != tensor size");
        if(!p.constant){total+=p.bytes;if(p.bytes>info.max_tensor_bytes)info.max_tensor_bytes=p.bytes;}
        const auto *q=t->quantization();
        if(q&&count(q->scale())){
            unsigned nq=count(q->scale());
            if(nq!=count(q->zero_point())||q->quantized_dimension()<0||
               (count(t->shape())?unsigned(q->quantized_dimension())>=count(t->shape()):q->quantized_dimension()!=0))return log.fail(-203,"quantization lengths/axis");
            if(nq>1 && (!count(t->shape())||nq!=unsigned(t->shape()->Get(q->quantized_dimension()))))return log.fail(-203,"per-channel quantization dimension");
            for(unsigned j=0;j<nq;++j){
                auto z=q->zero_point()->Get(j);
                if(!scale(q->scale()->Get(j))||(t->type()==tflite::TensorType_INT8&&(z<-128||z>127))||
                   (t->type()==tflite::TensorType_INT32&&z!=0))return log.fail(-203,"invalid scale/zero point");
            }
        }
    }
    if(total>UINT32_MAX)return log.fail(-210,"tensor byte sum overflow");
    info.tensor_bytes=uint32_t(total);
    if(!count(g->inputs())||!count(g->outputs()))return log.fail(-203,"missing graph IO");
    for(int id:*g->inputs()){
        if(id<0||unsigned(id)>=nt||plans[id].ready)return log.fail(-203,"graph input index/constant/duplicate");
        plans[id].ready=true;plans[id].first=0;plans[id].last=no+1; // caller retains input across invokes
    }
    for(unsigned i=0;i<no;++i){
        const auto *op=g->operators()->Get(i);
        if(op->opcode_index()>=info.operator_codes)return log.fail(-203,"opcode index");
        const auto *code=m->operator_codes()->Get(op->opcode_index());int kind=builtin(code);
        log.field("Operator ",i);log.text(" ");log.text(name(kind));log.field(" version=",code->version());
        bool available=kernel(kind)&&!code->custom_code();
        log.text(available?" CPU kernel available (conditions checked before execution)\n":" unsupported by CPU runtime\n");
        if(available)info.supported_operators++;else info.unsupported_operators++;
        if(!count(op->outputs()))return log.fail(-203,"operator has no output");
        if(op->inputs())for(int id:*op->inputs()){
            if(id==-1)continue;
            if(id<0||unsigned(id)>=nt||!plans[id].ready)return log.fail(-203,"input index/use before production");
            if(plans[id].last<int(i+1))plans[id].last=i+1;
        }
        for(int id:*op->outputs()){
            if(id<0||unsigned(id)>=nt||plans[id].ready)return log.fail(-203,"output index/multiple producer");
            plans[id].ready=true;plans[id].first=plans[id].last=i+1;
        }
    }
    for(int id:*g->outputs()){
        if(id<0||unsigned(id)>=nt||!plans[id].ready||plans[id].constant)return log.fail(-203,"graph output index/production");
        plans[id].last=no+1;
    }
    uint64_t peak=0;
    for(unsigned time=0;time<=no+1;++time){
        uint64_t live=0;
        for(unsigned i=0;i<nt;++i)if(!plans[i].constant&&plans[i].first>=0&&unsigned(plans[i].first)<=time&&unsigned(plans[i].last)>=time)live+=(plans[i].bytes+3u)&~3u;
        if(live>peak)peak=live;
    }
    if(peak>UINT32_MAX)return log.fail(-210,"lifetime peak overflow");
    info.arena_estimate=uint32_t(peak);
    log.field("Tensor bytes (sum)=",info.tensor_bytes);log.field("; maximum nonconstant tensor=",info.max_tensor_bytes);
    log.field("; Arena lifetime peak lower bound=",info.arena_estimate);
    log.text(" bytes (operator parameters/scratch not included)\n");
    log.field("CPU kernels available=",info.supported_operators);log.field(" unsupported=",info.unsupported_operators);
    log.field("; model buffer capacity=",PSC_TFLITE_MODEL_CAPACITY);log.text("\n");
    return 0;
}
const uint8_t *buffer(const tflite::Model *,const tflite::Tensor *t){return buffers[t->buffer()].ptr;}
bool affine(const tflite::Tensor *t,bool per_channel=false){
    const auto *q=t->quantization();
    return t->type()==tflite::TensorType_INT8&&q&&!q->details()&&q->details_type()==tflite::QuantizationDetails_NONE&&
        count(q->scale())&&count(q->scale())==count(q->zero_point())&&(per_channel||count(q->scale())==1);
}
void shape(const tflite::Tensor *t,int32_t dims[4]){for(int i=0;i<4;++i)dims[i]=1;for(unsigned i=0;i<count(t->shape());++i)dims[4-count(t->shape())+i]=t->shape()->Get(i);}
int clamp_value(double real,float scale,int zero){double q=std::round(real/scale)+zero;return q<-128?-128:q>127?127:int(q);}
int activation(int a,float scale,int zero,psc_tflite_cpu_op &p){
    p.minimum=-128;p.maximum=127;
    if(a==tflite::ActivationFunctionType_NONE)return 0;
    if(a==tflite::ActivationFunctionType_RELU||a==tflite::ActivationFunctionType_RELU6){p.minimum=zero;if(a==tflite::ActivationFunctionType_RELU6)p.maximum=clamp_value(6,scale,zero);return 0;}
    if(a==tflite::ActivationFunctionType_RELU_N1_TO_1){p.minimum=clamp_value(-1,scale,zero);p.maximum=clamp_value(1,scale,zero);return 0;}
    return -202;
}
int spatial(int in,int filter,int dilation,int stride,int padding,int out,int32_t &pad){
    if(filter<=0||dilation<=0||stride<=0)return -203;
    int64_t effective=int64_t(filter-1)*dilation+1;
    if(effective>INT32_MAX||int64_t(out)*stride+effective>INT32_MAX)return -203;
    int64_t expected;
    if(padding==tflite::Padding_SAME){expected=(int64_t(in)+stride-1)/stride;int64_t total=(expected-1)*stride+effective-in;pad=int32_t(total>0?total/2:0);}
    else if(padding==tflite::Padding_VALID){expected=in>=effective?(in-effective)/stride+1:0;pad=0;}
    else return -202;
    return expected==out?0:-203;
}
int32_t bias_at(const uint8_t *p,unsigned c){return flatbuffers::ReadScalar<int32_t>(p+4*c);}
bool bias_scale(float a,float w,float b){
    float wanted=float(double(a)*w);uint32_t x,y;memcpy(&x,&wanted,4);memcpy(&y,&b,4);
    return scale(wanted)&&y>=x-2&&y<=x+2;
}
bool storage_type(const tflite::Tensor *t){return t->type()==tflite::TensorType_INT8||t->type()==tflite::TensorType_INT32||t->type()==tflite::TensorType_FLOAT32;}
bool same_quant(const tflite::Tensor *a,const tflite::Tensor *b){
    if(a->type()!=b->type())return false;
    return a->type()!=tflite::TensorType_INT8 || (affine(a)&&affine(b)&&a->quantization()->scale()->Get(0)==b->quantization()->scale()->Get(0)&&a->quantization()->zero_point()->Get(0)==b->quantization()->zero_point()->Get(0));
}
bool same_shape(const tflite::Tensor *a,const tflite::Tensor *b){if(count(a->shape())!=count(b->shape()))return false;for(unsigned i=0;i<count(a->shape());++i)if(a->shape()->Get(i)!=b->shape()->Get(i))return false;return true;}
int compile_transform(const tflite::Model *m,const tflite::Operator *op,Op &o,uint8_t *params){
    const auto *g=m->subgraphs()->Get(0);const auto *x=g->tensors()->Get(o.x),*y=g->tensors()->Get(o.y);auto &p=o.cpu;
    int k=p.kind,rank=count(x->shape());if(rank>4||count(y->shape())>4||!storage_type(x)||!storage_type(y))return -202;
    shape(x,p.in);shape(y,p.out);p.rank=rank;p.type=x->type();p.width=width(p.type);
    if(x->type()==tflite::TensorType_INT8){if(!affine(x))return -202;p.input_zero=x->quantization()->zero_point()->Get(0);p.input_scale=x->quantization()->scale()->Get(0);}
    if(y->type()==tflite::TensorType_INT8){if(!affine(y))return -202;p.output_zero=y->quantization()->zero_point()->Get(0);p.output_scale=y->quantization()->scale()->Get(0);}
    if(k==114||k==6||k==25){
        if(count(op->inputs())!=1||!same_shape(x,y))return -203;
        if(k==114){
            if(op->builtin_options_type()!=tflite::BuiltinOptions_QuantizeOptions&&op->builtin_options_type()!=tflite::BuiltinOptions_NONE)return -203;
            if(y->type()!=tflite::TensorType_INT8||(x->type()!=tflite::TensorType_FLOAT32&&x->type()!=tflite::TensorType_INT8))return -202;
            if(x->type()==tflite::TensorType_INT8){int rc=psc_tflite_quantize(double(p.input_scale)/p.output_scale,&p.multiplier[0],&p.shift[0]);if(rc)return rc;if(int64_t(255)*(int64_t(1)<<(p.shift[0]>0?p.shift[0]:0))>INT32_MAX-128)return -202;}
        }else if(k==6){
            if(op->builtin_options_type()!=tflite::BuiltinOptions_DequantizeOptions&&op->builtin_options_type()!=tflite::BuiltinOptions_NONE)return -203;
            if(x->type()!=tflite::TensorType_INT8||y->type()!=tflite::TensorType_FLOAT32)return -202;
        }else{
            const auto *v=op->builtin_options_as_SoftmaxOptions();if(!v)return -203;
            if(!rank||x->type()!=tflite::TensorType_INT8||y->type()!=tflite::TensorType_INT8||p.output_scale!=1.f/256||p.output_zero!=-128)return -202;
            if(p.out[3]>511)return -202; // Q12 sum and output exponent fit the pinned INT8 reference
            o.params=256*4;int32_t scratch[256];int rc=psc_tflite_softmax_lut(v->beta(),p.input_scale,params?reinterpret_cast<int32_t *>(params):scratch);if(rc)return rc;p.exp_lut=reinterpret_cast<int32_t *>(params);
        }
        return 0;
    }
    if(!same_quant(x,y))return -202;
    if(k==2){
        auto *v=op->builtin_options_as_ConcatenationOptions();if(!v||v->fused_activation_function()!=tflite::ActivationFunctionType_NONE)return -202;
        int axis=v->axis();if(axis<0)axis+=rank;if(axis<0||axis>=rank||count(y->shape())!=unsigned(rank))return -203;
        p.axis=4-rank+axis;p.input_count=count(op->inputs());uint64_t sum=0;
        for(unsigned i=0;i<count(op->inputs());++i){int id=op->inputs()->Get(i);if(id<0)return -203;const auto *t=g->tensors()->Get(id);if(!same_quant(x,t)||count(t->shape())!=unsigned(rank))return -202;
            for(int d=0;d<rank;++d)if(d!=axis&&t->shape()->Get(d)!=y->shape()->Get(d))return -203;
            p.concat_size[i]=t->shape()->Get(axis);sum+=p.concat_size[i];
        }return sum==unsigned(y->shape()->Get(axis))?0:-203;
    }
    if(k==22){
        if(count(op->inputs())<1||count(op->inputs())>2||plans[o.x].bytes!=plans[o.y].bytes)return -203;
        const auto *v=op->builtin_options_as_ReshapeOptions();if(!v&&op->builtin_options_type()!=tflite::BuiltinOptions_NONE)return -203;
        const int32_t *unused=nullptr;(void)unused;
        unsigned nr=0;const uint8_t *raw=nullptr;const flatbuffers::Vector<int32_t> *vshape=nullptr;
        if(count(op->inputs())==2&&op->inputs()->Get(1)>=0){int id=op->inputs()->Get(1);auto *t=g->tensors()->Get(id);if(!plans[id].constant||t->type()!=tflite::TensorType_INT32||count(t->shape())!=1)return -202;nr=plans[id].bytes/4;raw=buffer(m,t);}
        else {if(!v)return -203;vshape=v->new_shape();nr=count(vshape);}
        if(nr!=count(y->shape()))return -203;
        unsigned infer=0;for(unsigned d=0;d<nr;++d){int dim=raw?flatbuffers::ReadScalar<int32_t>(raw+4*d):vshape->Get(d);if(dim==-1){if(++infer>1)return -203;}else if(dim<=0||dim!=y->shape()->Get(d))return -203;}
        return 0; // copy preserves lifetimes; no aliasing of caller input
    }
    unsigned needed=k==65?3:2;if(count(op->inputs())!=needed||op->inputs()->Get(1)<0)return -203;
    int id=op->inputs()->Get(1);auto *control=g->tensors()->Get(id);
    if(control->type()!=tflite::TensorType_INT32||!plans[id].constant)return -202;
    const uint8_t *raw=buffer(m,control);
    if(k==39){
        if((op->builtin_options_type()!=tflite::BuiltinOptions_TransposeOptions&&op->builtin_options_type()!=tflite::BuiltinOptions_NONE))return -203;
        if(count(control->shape())!=1||plans[id].bytes!=unsigned(rank)*4||count(y->shape())!=unsigned(rank))return -203;
        unsigned seen=0;for(int d=0;d<4;++d)p.aux[d]=d;
        for(int d=0;d<rank;++d){int axis=flatbuffers::ReadScalar<int32_t>(raw+4*d);if(axis<0||axis>=rank||(seen&(1u<<axis)))return -203;seen|=1u<<axis;if(y->shape()->Get(d)!=x->shape()->Get(axis))return -203;p.aux[4-rank+d]=4-rank+axis;}
    }else if(k==34){
        if((op->builtin_options_type()!=tflite::BuiltinOptions_PadOptions&&op->builtin_options_type()!=tflite::BuiltinOptions_NONE))return -203;
        if(count(control->shape())!=2||control->shape()->Get(0)!=rank||control->shape()->Get(1)!=2||count(y->shape())!=unsigned(rank))return -203;
        for(int d=0;d<rank;++d){int before=flatbuffers::ReadScalar<int32_t>(raw+8*d),after=flatbuffers::ReadScalar<int32_t>(raw+8*d+4);if(before<0||after<0||int64_t(before)+after+x->shape()->Get(d)!=y->shape()->Get(d))return -203;p.begin[4-rank+d]=before;}
    }else if(k==65){
        if((op->builtin_options_type()!=tflite::BuiltinOptions_SliceOptions&&op->builtin_options_type()!=tflite::BuiltinOptions_NONE)||op->inputs()->Get(2)<0)return -203;
        int si=op->inputs()->Get(2);auto *t=g->tensors()->Get(si);if(t->type()!=tflite::TensorType_INT32||!plans[si].constant)return -202;
        if(count(control->shape())!=1||count(t->shape())!=1||plans[id].bytes!=unsigned(rank)*4||plans[si].bytes!=unsigned(rank)*4||count(y->shape())!=unsigned(rank))return -203;
        auto *sizes=buffer(m,t);for(int d=0;d<rank;++d){int begin=flatbuffers::ReadScalar<int32_t>(raw+4*d),n=flatbuffers::ReadScalar<int32_t>(sizes+4*d),dim=x->shape()->Get(d);if(begin<0||begin>=dim)return -203;if(n==-1)n=dim-begin;if(n<=0||n>dim-begin||n!=y->shape()->Get(d))return -203;p.begin[4-rank+d]=begin;}
    }else if(k==97){
        auto *v=op->builtin_options_as_ResizeNearestNeighborOptions();if(!v||rank!=4||count(y->shape())!=4)return -203;
        if(v->half_pixel_centers()&&v->align_corners())return -202;
        if(count(control->shape())!=1||plans[id].bytes!=8||p.in[0]!=p.out[0]||p.in[3]!=p.out[3]||p.out[1]!=flatbuffers::ReadScalar<int32_t>(raw)||p.out[2]!=flatbuffers::ReadScalar<int32_t>(raw+4))return -203;
        if(p.in[1]>(1<<24)||p.in[2]>(1<<24)||p.out[1]>(1<<24)||p.out[2]>(1<<24))return -202;
        p.aux[0]=v->align_corners();p.aux[1]=v->half_pixel_centers();
    }else return -202;
    return 0;
}

/* Parameters are validated first, then written into the independent Arena.
   prepare never follows a model pointer before structural bounds validation. */
int compile(const tflite::Model *m,const tflite::Operator *op,Op &o,uint8_t *params){
    const auto *g=m->subgraphs()->Get(0);const auto *code=m->operator_codes()->Get(op->opcode_index());
    int k=builtin(code);o={};o.cpu.kind=k;o.b=o.w=-1;
    if(!kernel(k)||code->custom_code()||count(op->custom_options())||count(op->intermediates())||count(op->mutating_variable_inputs())||
       op->large_custom_options_offset()||op->large_custom_options_size()||op->builtin_options_2_type()!=tflite::BuiltinOptions2_NONE)return -202;
    if(code->version()<1||code->version()>4)return -202;
    if(count(op->outputs())!=1||!count(op->inputs())||op->inputs()->Get(0)<0)return -203;
    o.x=op->inputs()->Get(0);o.y=op->outputs()->Get(0);
    o.ninputs=count(op->inputs());if(o.ninputs>16)return -202;for(unsigned i=0;i<o.ninputs;++i)o.inputs[i]=op->inputs()->Get(i);
    if(k!=0&&k!=3&&k!=9&&k!=14&&k!=17&&k!=18&&k!=41)return compile_transform(m,op,o,params);
    const auto *x=g->tensors()->Get(o.x),*y=g->tensors()->Get(o.y);
    if(!affine(x)||!affine(y)||count(x->shape())>4||count(y->shape())>4)return -202;
    auto &p=o.cpu;shape(x,p.in);shape(y,p.out);
    float xs=x->quantization()->scale()->Get(0),ys=y->quantization()->scale()->Get(0);
    p.input_zero=int(x->quantization()->zero_point()->Get(0));p.output_zero=int(y->quantization()->zero_point()->Get(0));
    int act=tflite::ActivationFunctionType_NONE,rc=0;
    if(k==3||k==9){
        if(count(op->inputs())<2||count(op->inputs())>3||op->inputs()->Get(1)<0)return -203;
        o.w=op->inputs()->Get(1);if(count(op->inputs())==3)o.b=op->inputs()->Get(2);
        const auto *w=g->tensors()->Get(o.w);if(!affine(w,k==3)||!plans[o.w].constant)return -202;
        const auto *q=w->quantization();unsigned channels;
        if(k==3){
            auto *v=op->builtin_options_as_Conv2DOptions();
            if(!v||count(x->shape())!=4||count(y->shape())!=4||count(w->shape())!=4)return -203;
            shape(w,p.filter);channels=p.filter[0];p.stride_h=v->stride_h();p.stride_w=v->stride_w();
            p.dilation_h=v->dilation_h_factor();p.dilation_w=v->dilation_w_factor();act=v->fused_activation_function();
            if((p.stride_h!=1&&p.stride_h!=2)||(p.stride_w!=1&&p.stride_w!=2))return -202;
            if(p.in[0]!=p.out[0]||p.in[3]!=p.filter[3]||p.out[3]!=p.filter[0])return -203;
            if((rc=spatial(p.in[1],p.filter[1],p.dilation_h,p.stride_h,v->padding(),p.out[1],p.pad_h))||
               (rc=spatial(p.in[2],p.filter[2],p.dilation_w,p.stride_w,v->padding(),p.out[2],p.pad_w)))return rc;
        } else {
            auto *v=op->builtin_options_as_FullyConnectedOptions();
            if(!v||code->version()!=4||v->keep_num_dims()||v->asymmetric_quantize_inputs()||v->weights_format()!=tflite::FullyConnectedOptionsWeightsFormat_DEFAULT)return -202;
            if(count(w->shape())!=2||count(y->shape())!=2)return -203;
            channels=w->shape()->Get(0);unsigned depth=w->shape()->Get(1);
            if(plans[o.x].bytes%depth||uint64_t(plans[o.y].bytes)!=uint64_t(plans[o.x].bytes/depth)*channels||y->shape()->Get(0)!=int(plans[o.x].bytes/depth)||y->shape()->Get(1)!=int(channels))return -203;
            p.in[0]=plans[o.x].bytes/depth;p.in[1]=p.in[2]=1;p.in[3]=depth;
            p.out[0]=p.in[0];p.out[1]=p.out[2]=1;p.out[3]=channels;
            p.filter[0]=channels;p.filter[1]=p.filter[2]=1;p.filter[3]=depth;
            p.stride_h=p.stride_w=p.dilation_h=p.dilation_w=1;act=v->fused_activation_function();
        }
        if(count(q->scale())!=1&&(count(q->scale())!=channels||q->quantized_dimension()!=0))return -203;
        for(auto z:*q->zero_point())if(z!=0)return -202;
        const uint8_t *bias=nullptr;const tflite::QuantizationParameters *bq=nullptr;
        if(o.b>=0){
            const auto *b=g->tensors()->Get(o.b);bq=b->quantization();
            if(b->type()!=tflite::TensorType_INT32||!plans[o.b].constant||count(b->shape())!=1||b->shape()->Get(0)!=int(channels)||
               !bq||bq->details()||bq->details_type()!=tflite::QuantizationDetails_NONE||(count(bq->scale())!=1&&count(bq->scale())!=channels)||count(bq->zero_point())!=count(bq->scale()))return -203;
            if(count(bq->scale())>1&&bq->quantized_dimension()!=0)return -203;
            bias=buffer(m,b);
        }
        if(channels>UINT32_MAX/8)return -203;o.params=channels*8;
        auto *mult=reinterpret_cast<int32_t *>(params);auto *shifts=params?mult+channels:nullptr;
        uint64_t depth=uint64_t(p.filter[1])*p.filter[2]*p.filter[3];
        for(unsigned c=0;c<channels;++c){
            unsigned qi=count(q->scale())==1?0:c;float ws=q->scale()->Get(qi);
            if(bq&&(!bias_scale(xs,ws,bq->scale()->Get(count(bq->scale())==1?0:c))||bq->zero_point()->Get(count(bq->scale())==1?0:c)!=0))return -203;
            int32_t multiplier;int shift;if((rc=psc_tflite_quantize(double(xs)*ws/ys,&multiplier,&shift)))return rc;
            // Conservative proof for all possible inputs, including padded zero.
            int64_t bound=int64_t(depth)*255*128;
            int64_t b=bias?bias_at(bias,c):0;
            int64_t factor=int64_t(1)<<(shift>0?shift:0);
            if(bound>INT32_MAX || b-bound<(INT32_MIN+128)/factor || b+bound>(INT32_MAX-128)/factor)return -203;
            if(params){mult[c]=multiplier;shifts[c]=shift;}
        }
        p.channel_multiplier=mult;p.channel_shift=shifts;
    } else if(k==0||k==18||k==41){
        if(count(op->inputs())!=2||op->inputs()->Get(1)<0)return -203;
        o.w=op->inputs()->Get(1);const auto *b=g->tensors()->Get(o.w);
        if(!affine(b)||count(b->shape())>4)return -202;
        if(count(y->shape())!=(count(x->shape())>count(b->shape())?count(x->shape()):count(b->shape())))return -203;
        int32_t bs[4];shape(b,bs);int32_t as=1,st=1;
        for(int d=3;d>=0;--d){
            if(p.in[d]!=bs[d]&&p.in[d]!=1&&bs[d]!=1)return -203;
            if(p.out[d]!=(p.in[d]>bs[d]?p.in[d]:bs[d]))return -203;
            p.broadcast_a[d]=p.in[d]==1?0:as;p.broadcast_b[d]=bs[d]==1?0:st;as*=p.in[d];st*=bs[d];
        }
        float bscl=b->quantization()->scale()->Get(0);p.second_zero=int(b->quantization()->zero_point()->Get(0));
        if(k==0||k==41){
            if(k==0){auto *v=op->builtin_options_as_AddOptions();if(!v)return -203;act=v->fused_activation_function();}
            else {auto *v=op->builtin_options_as_SubOptions();if(!v)return -203;act=v->fused_activation_function();}
            double twice=2.0*(xs>bscl?xs:bscl);
            if((rc=psc_tflite_quantize(xs/twice,&p.multiplier[0],&p.shift[0]))||
               (rc=psc_tflite_quantize(bscl/twice,&p.multiplier[1],&p.shift[1]))||
               (rc=psc_tflite_quantize(twice/(1048576.0*ys),&p.multiplier[2],&p.shift[2])))return rc;
            if(p.shift[0]>0||p.shift[1]>0||p.shift[2]>0)return -202;
        } else {
            auto *v=op->builtin_options_as_MulOptions();if(!v)return -203;act=v->fused_activation_function();
            if((rc=psc_tflite_quantize(double(xs)*bscl/ys,&p.multiplier[2],&p.shift[2])))return rc;
            if(int64_t(65025)*(int64_t(1)<<(p.shift[2]>0?p.shift[2]:0))>INT32_MAX-128)return -202;
        }
    } else if(k==14){
        if(count(op->inputs())!=1||op->builtin_options_type()!=tflite::BuiltinOptions_NONE)return -203;
        if(count(x->shape())!=count(y->shape()))return -203;
        for(int d=0;d<4;++d)if(p.in[d]!=p.out[d])return -203;
        if(ys!=1.0f/256||p.output_zero!=-128)return -202;
        o.params=256;p.lut=reinterpret_cast<int8_t *>(params);
        int8_t check[256];if((rc=psc_tflite_logistic_lut(xs,p.input_zero,params?reinterpret_cast<int8_t *>(params):check)))return rc;
    } else {
        auto *v=op->builtin_options_as_Pool2DOptions();
        if(count(op->inputs())!=1||!v||count(x->shape())!=4||count(y->shape())!=4)return -203;
        if(xs!=ys||p.input_zero!=p.output_zero)return -202;
        p.filter[1]=v->filter_height();p.filter[2]=v->filter_width();p.stride_h=v->stride_h();p.stride_w=v->stride_w();act=v->fused_activation_function();
        if(p.in[0]!=p.out[0]||p.in[3]!=p.out[3])return -203;
        if((rc=spatial(p.in[1],p.filter[1],1,p.stride_h,v->padding(),p.out[1],p.pad_h))||
           (rc=spatial(p.in[2],p.filter[2],1,p.stride_w,v->padding(),p.out[2],p.pad_w)))return rc;
    }
    return activation(act,ys,p.output_zero,p);
}
int supported(const tflite::Model *m,const psc_tflite_info_t &info,const Log &log){
    const auto *g=m->subgraphs()->Get(0);
    if(info.unsupported_operators)return log.fail(-202,"graph contains unsupported CPU operators");
    if(info.dynamic_tensors)return log.fail(-202,"dynamic shape signature");
    if(info.tensors>analysis_limit||info.operators>512||count(g->inputs())!=1||count(g->outputs())!=1)return log.fail(-202,"execution limits: 1024 tensors, 512 operators, one input/output");
    unsigned index=0;
    for(const auto *op:*g->operators()){
        Op prepared;int rc=compile(m,op,prepared,nullptr);
        if(rc){log.field("Operator ",index);log.text(" ");log.text(name(builtin(m->operator_codes()->Get(op->opcode_index()))));log.text(" ");return log.fail(rc,"unsupported/invalid options, shape, quantization or accumulator range");}
        ++index;
    }
    return 0;
}
uint32_t tensor_layout(unsigned nt,unsigned no){
    uint32_t peak=0;
    for(unsigned time=0;time<=no;++time)for(unsigned i=0;i<nt;++i){
        auto &t=plans[i];if(t.constant||t.first!=int(time))continue;
        uint32_t pos=0;
        for(;;){bool collision=false;
            for(unsigned j=0;j<nt;++j){const auto &u=plans[j];
                if(!u.assigned||t.last<u.first||u.last<t.first)continue;
                if(uint64_t(pos)+t.bytes>u.offset&&uint64_t(u.offset)+u.bytes>pos){
                    if(uint64_t(u.offset)+u.bytes+3>UINT32_MAX)return UINT32_MAX;
                    pos=(u.offset+u.bytes+3)&~3u;collision=true;break;}
            }
            if(!collision)break;
        }
        if(uint64_t(pos)+t.bytes+3>UINT32_MAX)return UINT32_MAX;
        t.offset=pos;t.assigned=true;if(pos+t.bytes>peak)peak=pos+t.bytes;
    }
    return (peak+3)&~3u;
}
} // namespace
extern "C" uint8_t *psc_tflite_graph_arena(size_t *capacity){
    *capacity=PSC_TFLITE_GRAPH_ARENA_CAPACITY;
#ifdef PSC_TFLITE_ARENA_ADDRESS
    return reinterpret_cast<uint8_t *>(PSC_TFLITE_ARENA_ADDRESS);
#else
    alignas(16) static uint8_t arena[PSC_TFLITE_GRAPH_ARENA_CAPACITY];
    return arena;
#endif
}
extern "C" int psc_tflite_analyze(const void *data,size_t size,psc_tflite_log_fn fn,void *user,psc_tflite_info_t *info){
    if(info)*info={};Log log{fn,user};const tflite::Model *m;int rc=verify(data,size,&m,log);
    psc_tflite_info_t result={};if(!rc)rc=analyze(m,data,size,log,result);if(!rc&&info)*info=result;return rc;
}
extern "C" int psc_tflite_graph_is_fc(const void *data){
    const auto *m=tflite::GetModel(data);
    if(count(m->subgraphs())!=1)return 0;
    if(m->buffers())for(const auto *b:*m->buffers())if(b->offset()>1)return 0;
    const auto *g=m->subgraphs()->Get(0);if(!count(g->operators()))return 0;
    for(const auto *op:*g->operators())if(op->opcode_index()>=count(m->operator_codes())||builtin(m->operator_codes()->Get(op->opcode_index()))!=tflite::BuiltinOperator_FULLY_CONNECTED)return 0;
    return 1;
}
extern "C" int psc_tflite_inspect(const void *data,size_t size,psc_tflite_log_fn fn,void *user,psc_tflite_info_t *info){
    if(info)*info={};Log log{fn,user};const tflite::Model *m;int rc=verify(data,size,&m,log);if(rc)return rc;
    if(psc_tflite_graph_is_fc(data))return psc_tflite_inspect_fc(data,size,fn,user,info);
    psc_tflite_info_t result={};rc=analyze(m,data,size,{nullptr,nullptr},result);if(rc)return log.fail(rc,"structural graph validation");
    if(fn)analyze(m,data,size,log,result={});
    rc=supported(m,result,log);if(!rc){if(info)*info=result;log.text("Profile compatible: CPU operator graph (INT8/FLOAT32/INT32)\n");}return rc;
}
extern "C" void psc_tflite_graph_reset(void){graph={};}
extern "C" int psc_tflite_graph_prepare(const void *data,size_t size,uint8_t *arena,size_t capacity,size_t *required,
                                        int8_t **input,size_t *input_bytes,int8_t **output,size_t *output_bytes){
    graph={};*required=0;psc_tflite_info_t info={};int rc=psc_tflite_analyze(data,size,nullptr,nullptr,&info);if(rc)return rc;
    const auto *m=tflite::GetModel(data);const auto *g=m->subgraphs()->Get(0);
    if((rc=supported(m,info,{nullptr,nullptr})))return rc;
    uint32_t activation_bytes=tensor_layout(info.tensors,info.operators);
    if(activation_bytes==UINT32_MAX){*required=UINT32_MAX;return -210;}
    uint32_t offset=activation_bytes;
    for(unsigned i=0;i<info.operators;++i){if((rc=compile(m,g->operators()->Get(i),graph.ops[i],nullptr)))return rc;if(uint64_t(offset)+3+graph.ops[i].params>UINT32_MAX){*required=UINT32_MAX;return -210;}offset=(offset+3)&~3u;offset+=graph.ops[i].params;}
    *required=offset;if(offset>capacity)return PSC_TFLITE_ERR_ARENA;
    offset=activation_bytes;
    for(unsigned i=0;i<info.tensors;++i){const auto *b=buffer(m,g->tensors()->Get(i));graph.data[i]=plans[i].constant?b:arena+plans[i].offset;}
    for(unsigned i=0;i<info.operators;++i){offset=(offset+3)&~3u;if((rc=compile(m,g->operators()->Get(i),graph.ops[i],arena+offset)))return rc;offset+=graph.ops[i].params;}
    unsigned xi=g->inputs()->Get(0),yi=g->outputs()->Get(0);
    *input=const_cast<int8_t *>(reinterpret_cast<const int8_t *>(graph.data[xi]));*input_bytes=plans[xi].bytes;
    *output=const_cast<int8_t *>(reinterpret_cast<const int8_t *>(graph.data[yi]));*output_bytes=plans[yi].bytes;
    for(unsigned i=0;i<info.tensors;++i)graph.bytes[i]=plans[i].bytes;
    graph.model=m;graph.count=info.operators;graph.prepared=true;return 0;
}
static psc_tflite_fc_backend graph_select(const Op &o,psc_tflite_fc_backend requested) {
    // compile() has already proved INT8, symmetric constant weights, geometry,
    // per-channel scales/bias and safe INT32 accumulation for Conv/FC.
    if((o.cpu.kind==3||o.cpu.kind==9)&&psc_tflite_synap_available()) {
        if(requested==PSC_TFLITE_FC_SYNAP)return PSC_TFLITE_FC_SYNAP;
        // Preserve the existing measured FC allowlist. Conv AUTO stays SIMD
        // until measurements justify a device-specific NPU policy.
        if(requested==PSC_TFLITE_FC_AUTO&&o.cpu.kind==9 &&
           (o.cpu.in[0]==16||o.cpu.in[0]==32)&&o.cpu.in[3]==o.cpu.in[0]&&o.cpu.out[3]==o.cpu.in[0])return PSC_TFLITE_FC_SYNAP;
    }
    if((requested==PSC_TFLITE_FC_PULP||requested==PSC_TFLITE_FC_AUTO)&&psc_pulp_supports(o.cpu))return PSC_TFLITE_FC_PULP;
    return PSC_TFLITE_FC_CPU;
}
extern "C" const char *psc_tflite_graph_reason(unsigned i,psc_tflite_fc_backend requested,int actual) {
    if(!graph.prepared||i>=graph.count)return nullptr;
    if(requested==PSC_TFLITE_FC_CPU)return "explicit CPU";
    if(actual==PSC_TFLITE_FC_SYNAP)return "INT8 Conv/FC NPU";
    if(actual==PSC_TFLITE_FC_PULP)return "INT8 Conv/FC SIMD";
    const auto &o=graph.ops[i];
    if(o.cpu.kind!=3&&o.cpu.kind!=9)return "operator uses CPU kernel";
    if(requested==PSC_TFLITE_FC_SYNAP)return "NPU unavailable in platform";
#if PSC_HAS_CV_DOTSP_B || defined(PSC_PULP_TEST_EMULATE)
    if(!psc_pulp_supports(o.cpu))return requested==PSC_TFLITE_FC_AUTO ?
        "PULP geometry unsupported; AUTO NPU not calibrated" : "PULP geometry unsupported";
    return "no SIMD span executed";
#else
    return requested==PSC_TFLITE_FC_AUTO ?
        "PULP disabled in build; AUTO NPU not calibrated" : "PULP disabled in build";
#endif
}
extern "C" int psc_tflite_graph_invoke(psc_tflite_layer_fn layer,void *user,psc_tflite_fc_backend requested,
    unsigned tile,int32_t *scratch,psc_tflite_operator_profile_t *records,psc_tflite_profile_t *profile){
    if(!graph.prepared)return -203;
    for(unsigned i=0;i<graph.count;++i){const auto &o=graph.ops[i];const auto *x=reinterpret_cast<const int8_t *>(graph.data[o.x]);
        const auto *w=o.w<0?nullptr:reinterpret_cast<const int8_t *>(graph.data[o.w]);auto *y=const_cast<int8_t *>(reinterpret_cast<const int8_t *>(graph.data[o.y]));
        if(layer)layer(user,i,1);
        auto &record=records[i];record={o.cpu.kind,int(graph_select(o,requested)),-1,-205,0};
        int start=psc_tflite_clock_us();uint32_t old_tiles=profile?profile->tiles:0;
        switch(o.cpu.kind){case 3:case 9:
            if(record.backend==PSC_TFLITE_FC_SYNAP) {
                int rc=psc_tflite_synap_conv(&o.cpu,x,w,o.b<0?nullptr:graph.data[o.b],y,tile,scratch,profile);
                if(rc){record.status=rc;record.npu_tiles=profile?profile->tiles-old_tiles:0;
                    int end=psc_tflite_clock_us();record.us=start>=0&&end>=start?end-start:-1;
                    if(layer)layer(user,i,0);return rc;}
            } else if(record.backend==PSC_TFLITE_FC_PULP) {
                if(!psc_pulp_conv(o.cpu,x,w,o.b<0?nullptr:graph.data[o.b],y))record.backend=PSC_TFLITE_FC_CPU;
            } else psc_tflite_cpu_conv(&o.cpu,x,w,o.b<0?nullptr:graph.data[o.b],y);
            break;
        case 0:case 18:case 41:psc_tflite_cpu_binary(&o.cpu,x,w,y);break;case 14:psc_tflite_cpu_logistic(&o.cpu,x,y);break;
        case 17:psc_tflite_cpu_pool(&o.cpu,x,y);break;
        default:{const void *inputs[16];for(unsigned j=0;j<o.ninputs;++j)inputs[j]=o.inputs[j]<0?nullptr:graph.data[o.inputs[j]];
            int rc=psc_tflite_cpu_transform(&o.cpu,inputs,y);if(rc){record.status=rc;if(layer)layer(user,i,0);return rc;}break;}}
        int end=psc_tflite_clock_us();record.us=start>=0&&end>=start?end-start:-1;record.status=0;record.npu_tiles=profile?profile->tiles-old_tiles:0;
        if(layer)layer(user,i,0);
        if(graph.trace){int rc=graph.trace(graph.trace_user,i,o.y,y,graph.bytes[o.y],graph.model->subgraphs()->Get(0)->tensors()->Get(o.y)->type());if(rc)return rc;}
    }
    return 0;
}
extern "C" void psc_tflite_graph_debug(psc_tflite_log_fn fn,void *user,psc_tflite_fc_backend requested){Log log{fn,user};for(unsigned i=0;i<graph.count;++i){log.field("Operator ",i);log.text(" ");log.text(name(graph.ops[i].cpu.kind));log.text(" backend=");log.text(psc_tflite_backend_name(graph_select(graph.ops[i],requested)));log.text("\n");}}

extern "C" void psc_tflite_graph_trace(psc_tflite_tensor_trace_fn fn,void *user){graph.trace=fn;graph.trace_user=user;}

extern "C" unsigned psc_tflite_graph_count(void){return graph.prepared?graph.count:0;}
