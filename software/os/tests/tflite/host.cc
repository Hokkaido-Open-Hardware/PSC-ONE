/* Official schema builder is used on the HOST only. Target uses accessors only. */
#include "tflite_api.h"
#include "schema_generated.h"
#include <cstdio>
#include <cstdarg>
#include <fstream>
#include <cstdlib>
#include <cmath>

#define CHECK(x) do { if (!(x)) { std::fprintf(stderr, "FAIL line %d: %s\n", __LINE__, #x); std::exit(1); } } while (0)
using namespace tflite;
static unsigned checks;
static std::string report;
static void log_text(void *, const char *s) { report += s; }
#include "model_fixture.h"
static int inspect_bytes(const std::vector<uint8_t> &b, size_t size, bool logging = false) {
    alignas(16) uint8_t aligned[PSC_TFLITE_MODEL_CAPACITY];
    CHECK(b.size() <= sizeof(aligned)); memcpy(aligned, b.data(), b.size());
    psc_tflite_info_t info{99,99,99,99,99};
    report.clear();
    int rc = psc_tflite_inspect(aligned, size, logging ? log_text : nullptr, nullptr, &info);
    if (rc) CHECK(!info.version && !info.tensors && !info.operators && !info.constant_bytes && !info.tensor_bytes);
    // Exercise prepare's error cleanup on the same truncation/corruption corpus.
    int prepared = psc_tflite_prepare(aligned, size);
    if (rc) CHECK(prepared != 0);
    if (!prepared) {
        size_t n; auto *input = psc_tflite_get_input(&n); CHECK(input && n);
        memset(input, 0, n); CHECK(psc_tflite_invoke() == 0);
    }
    CHECK(psc_tflite_reset() == 0);
    ++checks; return rc;
}
static void expect(ModelT m, int expected) {
    auto b = pack(m); CHECK(inspect_bytes(b, b.size()) == expected);
}

/* Real fat32_stream.c consumes this fragmented synthetic SD card through its
   existing sector API. No replacement of the filesystem/parser under test. */
static uint8_t disk[1024][512];
static int fail_lba = -1;
extern "C" int call_sd_read_buf_api(uint32_t lba, void *dst) {
    if (lba >= 1024 || int(lba) == fail_lba) return -1;
    memcpy(dst, disk[lba], 512); return 0;
}
extern "C" void psc_printf(const char *fmt, ...) {
    va_list args; va_start(args, fmt); vprintf(fmt, args); va_end(args);
}
extern "C" int call_timer_measure_begin(void) { return -1; }
extern "C" int call_timer_measure_end_us(void) { return -1; }
static void w16(uint8_t *p, unsigned u) { p[0] = u; p[1] = u >> 8; }
static void w32(uint8_t *p, unsigned u) { w16(p,u); w16(p+2,u>>16); }
static void setup_sd(const std::vector<uint8_t> &data) {
    memset(disk,0,sizeof(disk)); fail_lba = -1;
    w16(disk[0]+510,0xaa55); w32(disk[0]+0x1c6,1);
    auto b = disk[1]; w16(b+510,0xaa55); w16(b+11,512); b[13]=1;
    w16(b+14,1); b[16]=1; w32(b+32,1023); w32(b+36,8); w32(b+44,2);
    w32(disk[2]+8,0x0fffffff);
    memcpy(disk[10],"MODEL   TFL",11); disk[10][11]=0x20;
    w16(disk[10]+26,3); w32(disk[10]+28,data.size());
    for (unsigned i=0; i*512<data.size(); ++i) {
        unsigned cluster=3+i*2;
        w32(disk[2+cluster/128]+4*(cluster%128),
            (i+1)*512>=data.size() ? 0x0fffffff : cluster+2);
        memcpy(disk[cluster+8],data.data()+i*512,std::min(size_t(512),data.size()-i*512));
    }
}
static void file_expect(const char *name, int expected) {
    psc_tflite_info_t info{99,99,99,99,99}; report.clear();
    int rc = psc_tflite_inspect_file(name, log_text, nullptr, &info);
    CHECK(rc == expected);
    if (rc) CHECK(info.version == 0 && info.tensors == 0);
    else CHECK(info.version == 3 && info.tensors == 7 && info.operators == 2 &&
               info.constant_bytes == 400 && info.tensor_bytes == 36);
    ++checks;
}
int main(int argc, char **argv) {
    if (argc == 3 && std::string(argv[1]) == "--diagnose") {
        std::ifstream file(argv[2], std::ios::binary);
        CHECK(file.good());
        std::vector<uint8_t> model((std::istreambuf_iterator<char>(file)), {});
        CHECK(model.size() >= 8 && model.size() <= PSC_TFLITE_MODEL_CAPACITY);
        setup_sd(model);
        cmd_tflite_run("MODEL.TFL");
        return 0; // diagnostic output includes the demo-oracle verdict
    }
    CHECK(argc == 2);
    auto valid = pack(fixture());
    setup_sd(valid);
    CHECK(psc_tflite_load("MODEL.TFL")==0);
    size_t n; auto *input=psc_tflite_get_input(&n); CHECK(input&&n==16);
    memset(input,127,n); fail_lba=0; // invoke must not read the card
    CHECK(psc_tflite_invoke()==0);
    auto *output=psc_tflite_get_output(&n);CHECK(output&&n==4);
    for(unsigned c=0;c<n;++c) CHECK(output[c]==7);
    CHECK(psc_tflite_load("MODEL.TFL")==-4); CHECK(!psc_tflite_get_input(&n));
    fail_lba=-1;

    std::ofstream(std::string(argv[1])+"/MODEL.TFL",std::ios::binary)
        .write(reinterpret_cast<const char*>(valid.data()),valid.size());
    CHECK(inspect_bytes(valid,valid.size(),true)==0);
    CHECK(report.find("FULLY_CONNECTED version=4") != std::string::npos);
    CHECK(report.find("float32=0x3e000000 zero_point=-3") != std::string::npos);
    CHECK(report.find("inputs=[0] outputs=[6]") != std::string::npos);
    std::ofstream(std::string(argv[1])+"/model_info.txt") << report;
    auto change = [&](auto fn, int expected) { auto m=fixture(); fn(m); expect(std::move(m),expected); };
    change([](auto &m){m.version=99;},-202);
    change([](auto &m){m.subgraphs[0]->inputs={99};},-203);
    change([](auto &m){m.subgraphs[0]->outputs={5};},-203);
    change([](auto &m){m.subgraphs[0]->tensors[1]->buffer=99;},-203);
    change([](auto &m){m.buffers[1]->data.pop_back();},-203);
    change([](auto &m){m.buffers[0]->data={0};},-203);
    change([](auto &m){m.buffers[1]->offset=1024;},-202);
    change([](auto &m){m.subgraphs[0]->tensors[0]->shape_signature={-1,16};},-202);
    change([](auto &m){m.subgraphs[0]->tensors[0]->shape={0x40000000,16};},-202);
    change([](auto &m){m.subgraphs[0]->tensors[1]->is_variable=true;},-202);
    change([](auto &m){m.subgraphs[0]->tensors[1]->quantization->scale.assign(16,.25f);
                       m.subgraphs[0]->tensors[1]->quantization->zero_point.assign(16,0);},-202);
    change([](auto &m){m.subgraphs[0]->tensors[1]->quantization->scale={0};},-203);
    change([](auto &m){m.subgraphs[0]->tensors[1]->quantization->scale={INFINITY};},-203);
    change([](auto &m){m.subgraphs[0]->tensors[0]->quantization->zero_point={int64_t(1)<<32};},-203);
    change([](auto &m){m.subgraphs[0]->tensors[1]->quantization->zero_point={1};},-202);
    change([](auto &m){m.subgraphs[0]->tensors[2]->quantization->scale={.5f};},-203);
    change([](auto &m){m.subgraphs[0]->tensors[0]->type=TensorType_FLOAT32;},-202);
    change([](auto &m){m.subgraphs[0]->operators[0]->opcode_index=99;},-203);
    change([](auto &m){m.subgraphs[0]->operators[0]->inputs[0]=6;},-203);
    change([](auto &m){m.subgraphs[0]->operators[0]->inputs[0]=-2;},-203);
    change([](auto &m){m.subgraphs[0]->operators[1]->outputs={3};},-203);
    change([](auto &m){m.operator_codes[0]->version=99;},-202);
    change([](auto &m){m.operator_codes[0]->builtin_code=BuiltinOperator_CONV_2D;
                       m.operator_codes[0]->deprecated_builtin_code=BuiltinOperator_CONV_2D;},-202);
    change([](auto &m){m.subgraphs[0]->operators[0]->inputs[2]=-1;},0);
    change([](auto &m){m.operator_codes[0]->builtin_code=BuiltinOperator_ADD;},0); // legacy code field
    // Identifier/root corruption and every truncation, including before header.
    auto broken=valid; broken[4]='X'; CHECK(inspect_bytes(broken,broken.size())==-201);
    broken=valid; memset(broken.data(),255,4); CHECK(inspect_bytes(broken,broken.size())==-201);
    for (size_t size=0; size<valid.size(); ++size) CHECK(inspect_bytes(valid,size)!=0);
    CHECK(inspect_bytes(valid,8193)==-200);
    alignas(16) uint8_t unaligned[8192+16]; memcpy(unaligned+1,valid.data(),valid.size());
    CHECK(psc_tflite_inspect(unaligned+1,valid.size(),nullptr,nullptr,nullptr)==-201);
    // Deterministic corruptions: ASan/UBSan must remain quiet, accept only safe data.
    uint32_t rng=0xabc123;
    for (unsigned i=0;i<2000;++i) {
        broken=valid; rng=rng*1664525+1013904223;
        broken[rng%broken.size()] ^= uint8_t(1u<<((rng>>24)&7));
        inspect_bytes(broken,broken.size());
    }
    setup_sd(valid); file_expect("MODEL.TFL",0);
    file_expect("MISSING.TFL",-3); file_expect("model.tfl",-2);
    file_expect("DIR/MODEL.TFL",-2);
    fail_lba=13; file_expect("MODEL.TFL",-4); // after first data sector
    fail_lba=-1; file_expect("MODEL.TFL",0);
    w32(disk[10]+28,8193); file_expect("MODEL.TFL",-200);
    setup_sd(valid); w32(disk[2]+12,0x0fffffff); file_expect("MODEL.TFL",-6);
    setup_sd(valid); w32(disk[2]+12,3); file_expect("MODEL.TFL",-6);
    setup_sd(valid); disk[11][4]='X'; file_expect("MODEL.TFL",-201);
    setup_sd(valid); file_expect("MODEL.TFL",0);
    for (unsigned i=0;i<20;++i) file_expect("MODEL.TFL",0);
    std::printf("PASS: %u parser/profile/FAT32 checks; model=%zu bytes\n",checks,valid.size());
}
