#include "tflite_inspect.h"
#include "schema_generated.h"

namespace {
/* Keep formatting independent of printf's float/64-bit support on PSC-OS. */
struct Log {
    psc_tflite_log_fn fn;
    void *user;
    void text(const char *s) const { if (fn) fn(user, s); }
    void number(int32_t n) const {
        char b[12]; unsigned p = sizeof(b); b[--p] = 0;
        uint32_t u = n < 0 ? 0u - static_cast<uint32_t>(n) : static_cast<uint32_t>(n);
        do { b[--p] = '0' + u % 10; u /= 10; } while (u);
        if (n < 0) b[--p] = '-';
        text(b + p);
    }
    void hex(uint32_t u) const {
        char b[11] = "0x00000000";
        for (unsigned i = 0; i < 8; ++i) {
            b[9-i] = "0123456789abcdef"[u & 15]; u >>= 4;
        }
        text(b);
    }
    void name(const flatbuffers::String *s) const {
        if (!s) return;
        char b[49]; unsigned n = s->size() < 48 ? s->size() : 48;
        for (unsigned i = 0; i < n; ++i) {
            unsigned char c = s->Get(i);
            b[i] = c >= 32 && c < 127 ? c : '?';
        }
        b[n] = 0; text(b);
    }
    int fail(int code, const char *reason) const {
        text("Rejected: "); text(reason); text("\n"); return code;
    }
};
template<class T> uint32_t count(const T *v) { return v ? v->size() : 0; }
uint32_t bits(float value) {
    uint32_t u; memcpy(&u, &value, sizeof(u)); return u;
}
bool normal_scale(uint32_t u) {
    return !(u >> 31) && (u >> 23) != 0 && (u >> 23) < 255;
}
int opcode(const tflite::OperatorCode *c) {
    /* Official schema's backward-compatible builtin-code resolution. */
    int a = c->builtin_code(), b = c->deprecated_builtin_code();
    return a > b ? a : b;
}
void indices(const Log &out, const flatbuffers::Vector<int32_t> *v) {
    out.text("[");
    for (unsigned i = 0; i < count(v); ++i) {
        if (i) out.text(","); out.number(v->Get(i));
    }
    out.text("]");
}
bool index_ok(int32_t i, uint32_t n) { return i >= 0 && static_cast<uint32_t>(i) < n; }

/* Compare stored bias scale with input*weight, allowing 2 float32 ULPs.
   Integer-only normalization: no soft-float or FPU needed in Phase 0..2. */
bool bias_scale_matches(uint32_t a, uint32_t b, uint32_t c) {
    uint64_t product = static_cast<uint64_t>((a & 0x7fffff) | 0x800000) *
                      ((b & 0x7fffff) | 0x800000);
    int exponent = int(a >> 23) + int(b >> 23) - 127;
    unsigned shift = (product & (uint64_t(1) << 47)) ? 24 : 23;
    if (shift == 24) ++exponent;
    uint32_t mantissa = static_cast<uint32_t>((product + (uint64_t(1) << (shift-1))) >> shift);
    if (mantissa == 0x1000000) { mantissa >>= 1; ++exponent; }
    if (exponent <= 0 || exponent >= 255) return false;
    uint32_t expected = (uint32_t(exponent) << 23) | (mantissa & 0x7fffff);
    return c >= expected - 2 && c <= expected + 2;
}

int inspect(const void *data, size_t size, const Log &out, psc_tflite_info_t &info) {
    if (!data || size < 8 || size > PSC_TFLITE_MODEL_CAPACITY)
        return out.fail(PSC_TFLITE_ERR_SIZE, "file size");
    if ((reinterpret_cast<uintptr_t>(data) & 15) != 0)
        return out.fail(PSC_TFLITE_ERR_FORMAT, "model buffer must be 16-byte aligned");
    const auto *bytes = static_cast<const uint8_t *>(data);
    if (memcmp(bytes + 4, "TFL3", 4))
        return out.fail(PSC_TFLITE_ERR_FORMAT, "TFL3 identifier");
    flatbuffers::Verifier::Options options;
    options.max_depth = 16;
    options.max_tables = 512;
    flatbuffers::Verifier verifier(bytes, size, options);
    if (!tflite::VerifyModelBuffer(verifier))
        return out.fail(PSC_TFLITE_ERR_FORMAT, "FlatBuffers bounds/table verification");
    const auto *m = tflite::GetModel(bytes);
    out.text("TFLite TFL3 bytes="); out.number(size);
    out.text(" schema="); out.number(m->version()); out.text("\n");
    if (m->version() != 3)
        return out.fail(PSC_TFLITE_ERR_UNSUPPORTED, "schema version (requires 3)");
    if (count(m->subgraphs()) != 1 || count(m->buffers()) == 0 ||
        count(m->buffers()) > 64 || count(m->operator_codes()) > 8)
        return out.fail(PSC_TFLITE_ERR_UNSUPPORTED, "subgraph/buffer/opcode count");
    if (count(m->external_buffers()) || count(m->external_buffer_groups()))
        return out.fail(PSC_TFLITE_ERR_UNSUPPORTED, "external buffers");
    for (unsigned i = 0; i < count(m->buffers()); ++i) {
        const auto *b = m->buffers()->Get(i);
        if (b->offset() || b->size())
            return out.fail(PSC_TFLITE_ERR_UNSUPPORTED, "out-of-line buffer data");
        if (!i && count(b->data()))
            return out.fail(PSC_TFLITE_ERR_GRAPH, "buffer 0 must be empty");
        info.constant_bytes += count(b->data());
    }
    const auto *g = m->subgraphs()->Get(0);
    uint32_t nt = count(g->tensors()), no = count(g->operators());
    if (!nt || nt > PSC_TFLITE_MAX_TENSORS || !no || no > PSC_TFLITE_MAX_OPERATORS ||
        count(g->inputs()) != 1 || count(g->outputs()) != 1)
        return out.fail(PSC_TFLITE_ERR_UNSUPPORTED, "requires 1 input/output, 1..32 tensors, 1..8 ops");
    if (!index_ok(g->inputs()->Get(0), nt) || !index_ok(g->outputs()->Get(0), nt))
        return out.fail(PSC_TFLITE_ERR_GRAPH, "subgraph input/output index");
    out.text("SubGraph 0 name="); out.name(g->name());
    out.text(" tensors="); out.number(nt); out.text(" operators="); out.number(no);
    out.text(" inputs="); indices(out, g->inputs());
    out.text(" outputs="); indices(out, g->outputs()); out.text("\n");

    bool ready[PSC_TFLITE_MAX_TENSORS] = {};
    bool constant[PSC_TFLITE_MAX_TENSORS] = {};
    bool unsupported = false;
    for (unsigned i = 0; i < nt; ++i) {
        const auto *t = g->tensors()->Get(i);
        out.text("Tensor "); out.number(i); out.text(" name="); out.name(t->name());
        out.text(" type="); out.text(tflite::EnumNameTensorType(t->type()));
        out.text(" shape=");
        if (count(t->shape()) > 4 || !count(t->shape()))
            return out.fail(PSC_TFLITE_ERR_UNSUPPORTED, "requires rank 1..4");
        indices(out, t->shape()); out.text(" buffer="); out.number(t->buffer()); out.text("\n");
        if (t->buffer() >= count(m->buffers()))
            return out.fail(PSC_TFLITE_ERR_GRAPH, "tensor buffer index");
        if (t->is_variable() || t->sparsity() || t->external_buffer())
            return out.fail(PSC_TFLITE_ERR_UNSUPPORTED, "variable/sparse/external tensor");
        if (count(t->shape_signature()) && count(t->shape_signature()) != count(t->shape()))
            return out.fail(PSC_TFLITE_ERR_GRAPH, "shape_signature rank");
        uint32_t elements = 1;
        for (unsigned d = 0; d < count(t->shape()); ++d) {
            int dim = t->shape()->Get(d);
            if (dim <= 0 || (count(t->shape_signature()) && t->shape_signature()->Get(d) != dim))
                return out.fail(PSC_TFLITE_ERR_UNSUPPORTED, "dynamic/nonpositive shape");
            if (uint32_t(dim) > PSC_TFLITE_MODEL_CAPACITY / elements)
                return out.fail(PSC_TFLITE_ERR_UNSUPPORTED, "tensor element limit");
            elements *= dim;
        }
        unsigned width = t->type() == tflite::TensorType_INT8 ? 1 :
                         t->type() == tflite::TensorType_INT32 ? 4 : 0;
        if (!width) unsupported = true;
        const auto *buffer = m->buffers()->Get(t->buffer());
        unsigned length = count(buffer->data());
        if (length && width && length != elements * width)
            return out.fail(PSC_TFLITE_ERR_GRAPH, "constant byte length != shape*element size");
        constant[i] = ready[i] = length != 0;
        if (!length) info.tensor_bytes += elements * width;
        const auto *q = t->quantization();
        if (!q || q->details_type() != tflite::QuantizationDetails_NONE || q->details()) {
            unsupported = true;
            out.text("  quantization: missing or non-affine\n");
            continue;
        }
        unsigned nq = count(q->scale());
        if (!nq || nq > 64 || count(q->zero_point()) != nq)
            return out.fail(PSC_TFLITE_ERR_GRAPH, "scale/zero_point array lengths (1..64 required)");
        if (q->quantized_dimension() < 0 || uint32_t(q->quantized_dimension()) >= count(t->shape()))
            return out.fail(PSC_TFLITE_ERR_GRAPH, "quantized_dimension");
        if (nq > 1) {
            unsupported = true;
            if (nq != uint32_t(t->shape()->Get(q->quantized_dimension())))
                return out.fail(PSC_TFLITE_ERR_GRAPH, "per-axis scale count != quantized dimension");
        }
        for (unsigned k = 0; k < nq; ++k) {
            uint32_t s = bits(q->scale()->Get(k));
            int64_t z = q->zero_point()->Get(k);
            if (!normal_scale(s) || z < -128 || z > 127 ||
                (t->type() == tflite::TensorType_INT32 && z != 0))
                return out.fail(PSC_TFLITE_ERR_GRAPH, "requires positive normal scale and valid zero_point");
            out.text("  quant["); out.number(k); out.text("] scale=");
            out.number((s & 0x7fffff) | 0x800000);
            out.text("*2^"); out.number(int(s >> 23) - 150);
            out.text(" float32="); out.hex(s);
            out.text(" zero_point="); out.number(static_cast<int32_t>(z));
            out.text(" quantized_dimension="); out.number(q->quantized_dimension()); out.text("\n");
        }
    }
    unsigned input = g->inputs()->Get(0), output = g->outputs()->Get(0);
    if (constant[input] || constant[output] || input == output)
        return out.fail(PSC_TFLITE_ERR_GRAPH, "model input/output must be distinct nonconstants");
    ready[input] = true;
    if (g->tensors()->Get(input)->type() != tflite::TensorType_INT8 ||
        g->tensors()->Get(output)->type() != tflite::TensorType_INT8) unsupported = true;
    for (unsigned i = 0; i < no; ++i) {
        const auto *op = g->operators()->Get(i);
        if (op->opcode_index() >= count(m->operator_codes()))
            return out.fail(PSC_TFLITE_ERR_GRAPH, "opcode_index");
        const auto *code = m->operator_codes()->Get(op->opcode_index());
        int builtin = opcode(code);
        if (count(op->inputs()) > 8 || count(op->outputs()) > 4)
            return out.fail(PSC_TFLITE_ERR_UNSUPPORTED, "operator input/output count");
        out.text("Operator "); out.number(i); out.text(" opcode_index="); out.number(op->opcode_index());
        out.text(" "); out.text(tflite::EnumNameBuiltinOperator(static_cast<tflite::BuiltinOperator>(builtin)));
        out.text(" version="); out.number(code->version());
        out.text(" inputs="); indices(out, op->inputs());
        out.text(" outputs="); indices(out, op->outputs()); out.text("\n");
        for (unsigned j = 0; j < count(op->inputs()); ++j) {
            int id = op->inputs()->Get(j);
            if (id != -1 && (!index_ok(id, nt) || !ready[id]))
                return out.fail(PSC_TFLITE_ERR_GRAPH, "input index/use before production");
        }
        for (unsigned j = 0; j < count(op->outputs()); ++j) {
            int id = op->outputs()->Get(j);
            if (!index_ok(id, nt) || ready[id])
                return out.fail(PSC_TFLITE_ERR_GRAPH, "output index/multiple producer");
            ready[id] = true;
        }
        if (count(op->custom_options()) || count(op->intermediates()) ||
            count(op->mutating_variable_inputs()) || op->large_custom_options_offset() ||
            op->large_custom_options_size() || op->builtin_options_2_type() != tflite::BuiltinOptions2_NONE)
            unsupported = true;
        if (builtin != tflite::BuiltinOperator_FULLY_CONNECTED || code->version() != 4 ||
            code->custom_code() || op->builtin_options_type() != tflite::BuiltinOptions_FullyConnectedOptions) {
            unsupported = true; continue;
        }
        const auto *fc = op->builtin_options_as_FullyConnectedOptions();
        if (!fc || fc->weights_format() != tflite::FullyConnectedOptionsWeightsFormat_DEFAULT ||
            fc->keep_num_dims() || fc->asymmetric_quantize_inputs() ||
            (fc->quantized_bias_type() != tflite::TensorType_FLOAT32 &&
             fc->quantized_bias_type() != tflite::TensorType_INT32) ||
            (fc->fused_activation_function() != tflite::ActivationFunctionType_NONE &&
             fc->fused_activation_function() != tflite::ActivationFunctionType_RELU)) {
            unsupported = true; continue;
        }
        out.text("  fused_activation="); out.text(tflite::EnumNameActivationFunctionType(fc->fused_activation_function())); out.text("\n");
        if (count(op->inputs()) != 3 || count(op->outputs()) != 1 ||
            op->inputs()->Get(0) < 0 || op->inputs()->Get(1) < 0)
            return out.fail(PSC_TFLITE_ERR_GRAPH, "FC requires activation, weight, optional bias slot");
        int x_id = op->inputs()->Get(0), w_id = op->inputs()->Get(1), b_id = op->inputs()->Get(2);
        const auto *x = g->tensors()->Get(x_id), *w = g->tensors()->Get(w_id);
        const auto *y = g->tensors()->Get(op->outputs()->Get(0));
        if (x->type() != tflite::TensorType_INT8 || w->type() != tflite::TensorType_INT8 ||
            y->type() != tflite::TensorType_INT8) { unsupported = true; continue; }
        if (count(x->shape()) != 2 || count(w->shape()) != 2 || count(y->shape()) != 2 ||
            x->shape()->Get(0) != 1 || y->shape()->Get(0) != 1) {
            unsupported = true; continue;
        }
        if (x->shape()->Get(1) != w->shape()->Get(1) || y->shape()->Get(1) != w->shape()->Get(0) ||
            !constant[w_id]) return out.fail(PSC_TFLITE_ERR_GRAPH, "FC shape/constant weights");
        if (unsupported) continue; // quantization pointers below require the profile
        if (w->quantization()->zero_point()->Get(0) != 0)
            return out.fail(PSC_TFLITE_ERR_UNSUPPORTED, "FC weight zero_point must be 0");
        const auto *weights = m->buffers()->Get(w->buffer())->data();
        for (unsigned k = 0; k < count(weights); ++k)
            if (weights->Get(k) == 128)
                return out.fail(PSC_TFLITE_ERR_UNSUPPORTED, "weight -128 outside symmetric INT8 profile");
        if (b_id != -1) {
            const auto *b = g->tensors()->Get(b_id);
            if (b->type() != tflite::TensorType_INT32 || !constant[b_id] ||
                count(b->shape()) != 1 || b->shape()->Get(0) != w->shape()->Get(0))
                return out.fail(PSC_TFLITE_ERR_GRAPH, "FC INT32 bias shape/constant");
            if (!bias_scale_matches(bits(x->quantization()->scale()->Get(0)),
                                    bits(w->quantization()->scale()->Get(0)),
                                    bits(b->quantization()->scale()->Get(0))))
                return out.fail(PSC_TFLITE_ERR_GRAPH, "bias scale != input scale * weight scale");
        }
    }
    if (!ready[output]) return out.fail(PSC_TFLITE_ERR_GRAPH, "model output never produced");
    if (unsupported) return out.fail(PSC_TFLITE_ERR_UNSUPPORTED, "requires INT8 FC v4, per-tensor quantization, NONE/RELU");
    info.version = m->version(); info.tensors = nt; info.operators = no;
    out.text("Profile compatible: INT8 FC v4 (CPU NONE/RELU profile)\n");
    out.text("Buffer data bytes="); out.number(info.constant_bytes);
    out.text(" nonconstant tensor bytes (sum, not arena)="); out.number(info.tensor_bytes); out.text("\n");
    return 0;
}
} // namespace

extern "C" int psc_tflite_inspect(const void *data, size_t size,
                                  psc_tflite_log_fn log, void *user,
                                  psc_tflite_info_t *info) {
    if (info) *info = {};
    psc_tflite_info_t result = {};
    int rc = inspect(data, size, {log, user}, result);
    if (!rc && info) *info = result;
    return rc;
}
