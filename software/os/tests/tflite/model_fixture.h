#ifndef PSC_TEST_MODEL_FIXTURE_H
#define PSC_TEST_MODEL_FIXTURE_H
#include "schema_generated.h"
using namespace tflite;
static std::unique_ptr<TensorT> tensor(const char *name, std::vector<int32_t> shape,
                                      TensorType type, unsigned buffer, float scale, int64_t zero) {
    auto t = std::make_unique<TensorT>();
    t->name = name; t->shape = shape; t->shape_signature = shape; t->type = type; t->buffer = buffer;
    t->quantization = std::make_unique<QuantizationParametersT>();
    t->quantization->scale = {scale}; t->quantization->zero_point = {zero};
    return t;
}
static ModelT fixture() {
    ModelT m; m.version = 3;
    auto code = std::make_unique<OperatorCodeT>();
    code->builtin_code = BuiltinOperator_FULLY_CONNECTED;
    code->deprecated_builtin_code = BuiltinOperator_FULLY_CONNECTED; code->version = 4;
    m.operator_codes.push_back(std::move(code));
    for (unsigned size : {0u, 256u, 64u, 64u, 16u}) {
        auto b = std::make_unique<BufferT>(); b->data.resize(size, 0);
        m.buffers.push_back(std::move(b));
    }
    auto g = std::make_unique<SubGraphT>(); g->name = "PSC tiny FC 16-16-4";
    g->inputs = {0}; g->outputs = {6};
    g->tensors.push_back(tensor("input", {1,16}, TensorType_INT8, 0, .125f, -3));
    g->tensors.push_back(tensor("w0", {16,16}, TensorType_INT8, 1, .25f, 0));
    g->tensors.push_back(tensor("b0", {16}, TensorType_INT32, 2, .03125f, 0));
    g->tensors.push_back(tensor("hidden", {1,16}, TensorType_INT8, 0, .25f, -128));
    g->tensors.push_back(tensor("w1", {4,16}, TensorType_INT8, 3, .125f, 0));
    g->tensors.push_back(tensor("b1", {4}, TensorType_INT32, 4, .03125f, 0));
    g->tensors.push_back(tensor("output", {1,4}, TensorType_INT8, 0, .5f, 7));
    for (unsigned i = 0; i < 2; ++i) {
        auto op = std::make_unique<OperatorT>();
        op->inputs = i ? std::vector<int32_t>{3,4,5} : std::vector<int32_t>{0,1,2};
        op->outputs = {i ? 6 : 3};
        FullyConnectedOptionsT options;
        options.fused_activation_function = i ? ActivationFunctionType_NONE : ActivationFunctionType_RELU;
        op->builtin_options.Set(std::move(options));
        g->operators.push_back(std::move(op));
    }
    m.subgraphs.push_back(std::move(g)); return m;
}
static std::vector<uint8_t> pack(const ModelT &m) {
    flatbuffers::FlatBufferBuilder b;
    auto root = Model::Pack(b, &m); FinishModelBuffer(b, root);
    return {b.GetBufferPointer(), b.GetBufferPointer() + b.GetSize()};
}

#endif
