#include "tflite_api.h"
#include "tflite_demo.h"
#include "../../fs/fat32.h"
#include <string.h>

static _Alignas(16) uint8_t model_buffer[PSC_TFLITE_MODEL_CAPACITY];
static int busy;
static int debug_load;
static uint32_t resident_size;
static void shell_log(void *user, const char *text);

static int load_us, prepare_us;
static int read_model(const char *name, uint32_t *size) {
    fat32_file_t file = {0};
    if (debug_load) printf("FAT32 sector_buffer=%x model_buffer=%x capacity=%d\n",
        (unsigned)(uintptr_t)file.sector_buf, (unsigned)(uintptr_t)model_buffer,
        (int)sizeof(model_buffer));
    int rc = fat32_open(&file, name);
    *size = 0;
    if (!rc) {
        if (file.file_size < 8 || file.file_size > sizeof(model_buffer)) rc = PSC_TFLITE_ERR_SIZE;
        else {
            rc = fat32_stream_read(&file, model_buffer, file.file_size, size);
            if (!rc && *size != file.file_size) rc = PSC_TFLITE_ERR_TRUNCATED;
        }
    }
    fat32_close(&file);
    return rc;
}
int psc_tflite_inspect_file(const char *name, psc_tflite_log_fn log, void *user,
                           psc_tflite_info_t *info) {
    if (info) *info = (psc_tflite_info_t){0};
    if (busy || psc_tflite_reset()) return PSC_TFLITE_ERR_BUSY;
    busy = 1;
    /* shared model buffer invalidates resident inference */
    uint32_t size;
    int rc = read_model(name, &size);
    if (!rc) rc = psc_tflite_inspect(model_buffer, size, log, user, info);
    busy = 0;
    return rc;
}
int psc_tflite_load(const char *name) {
    if (busy || psc_tflite_reset()) return PSC_TFLITE_ERR_BUSY;
    busy = 1;
    uint32_t size;
    int timing = call_timer_measure_begin();
    int rc = read_model(name, &size);
    load_us = timing == 0 ? call_timer_measure_end_us() : -1;
    prepare_us = -1;
    resident_size = rc ? 0 : size;
    if (!rc) {
        if (debug_load) {
            printf("CONSTANTS after FAT32 read/close, before prepare\n");
            psc_tflite_debug_model(model_buffer, size, shell_log, 0);
        }
        timing = call_timer_measure_begin();
        rc = psc_tflite_prepare(model_buffer, size);
        prepare_us = timing == 0 ? call_timer_measure_end_us() : -1;
    }
    busy = 0;
    return rc;
}

static void shell_log(void *user, const char *text) {
    (void)user;
    printf("%s", text);
}

void cmd_tflite_info(const char *name) {
    psc_tflite_info_t info;
    int rc = psc_tflite_inspect_file(name, shell_log, 0, &info);
    if (rc) printf("TFLite error %d: %s\n", rc, psc_tflite_error_string(rc));
}

const char *psc_tflite_error_string(int rc) {
    switch (rc) {
    case 0: return "OK";
    case PSC_TFLITE_ERR_SIZE: return "model or arena capacity exceeded (model 8..8192 bytes)";
    case PSC_TFLITE_ERR_SYNAP: return "SynapEngine syscall failure";
    case PSC_TFLITE_ERR_SYNAP_TIMEOUT: return "SynapEngine timeout";
    case PSC_TFLITE_ERR_SYNAP_ARGUMENT: return "SynapEngine size/buffer error";
    case PSC_TFLITE_ERR_SYNAP_BUSY: return "SynapEngine busy";
    case PSC_TFLITE_ERR_FORMAT: return "invalid/alignment/unsupported FlatBuffer encoding";
    case PSC_TFLITE_ERR_UNSUPPORTED: return "outside initial INT8 FC profile";
    case PSC_TFLITE_ERR_GRAPH: return "invalid tensor/operator/quantization relationship";
    case PSC_TFLITE_ERR_TRUNCATED: return "short model read";
    case PSC_TFLITE_ERR_BUSY: return "TFLite API busy";
    case FAT32_ERR_NAME: return "use root uppercase 8.3 filename (MODEL.TFL)";
    case FAT32_ERR_NOT_FOUND: return "file not found";
    case FAT32_ERR_SD: return "SD read failed";
    case FAT32_ERR_FORMAT: return "invalid FAT32 volume";
    case FAT32_ERR_CHAIN: return "invalid/truncated FAT chain";
    default: return "FAT32 state error";
    }
}

/* Fixed-input diagnostic. Generic applications use the C API instead. */
typedef struct {
    int32_t trace[20][3];
    unsigned count;
    int valid, timing, fc_us[2];
} demo_result_t;
static void demo_capture(void *user, unsigned layer, unsigned channel,
                         int32_t acc, int32_t quant, int8_t output) {
    demo_result_t *r = user;
    unsigned index = layer == 0 ? channel : 16 + channel;
    if (layer > 1 || (layer == 0 && channel >= 16) ||
        (layer == 1 && channel >= 4) || index != r->count) { r->valid = 0; return; }
    r->trace[index][0] = acc;
    r->trace[index][1] = quant;
    r->trace[index][2] = output;
    ++r->count;
}
static void demo_layer(void *user, unsigned layer, int begin) {
    demo_result_t *r = user;
    if (begin) r->timing = call_timer_measure_begin();
    else {
        int us = r->timing == 0 ? call_timer_measure_end_us() : -1;
        if (layer < 2) r->fc_us[layer] = us;
    }
}
void cmd_tflite_run_backend(const char *name, enum psc_tflite_fc_backend backend) {
    debug_load = 1;
    int rc = psc_tflite_load(name);
    debug_load = 0;
    if (!rc) {
        printf("CONSTANTS after prepare\n");
        psc_tflite_debug_model(model_buffer, resident_size, shell_log, 0);
    }
    size_t bytes;
    int8_t *input = psc_tflite_get_input(&bytes);
    if (rc || !input || bytes != sizeof(demo_input)) {
        printf("TFLite run error %d: %s\n", rc, rc ? psc_tflite_error_string(rc) : "demo requires input [1,16]");
        return;
    }
    rc = psc_tflite_set_fc_backend(backend);
    if (rc) { printf("TFLite backend error %d\n", rc); return; }
    memcpy(input, demo_input, sizeof(demo_input));
    psc_tflite_debug_fc(shell_log, 0);
    demo_result_t result = {.valid = 1, .fc_us = {-1,-1}};
    rc = psc_tflite_invoke_traced(demo_capture, 0, &result);
    if (rc) { printf("TFLite invoke error %d\n", rc); return; }
    printf("CONSTANTS after first invoke\n");
    psc_tflite_debug_model(model_buffer, resident_size, shell_log, 0);
    int timing = call_timer_measure_begin();
    rc = psc_tflite_invoke(); /* timing excludes trace capture and UART */
    int invoke_us = timing == 0 ? call_timer_measure_end_us() : -1;
    if (!rc) rc = psc_tflite_invoke_traced(0, demo_layer, &result);
    const int8_t *output = psc_tflite_get_output(&bytes);
    if (rc || !output) { printf("TFLite invoke error %d\n", rc); return; }
    printf("TFLite inference (%s INT8)\nInput : [", backend==PSC_TFLITE_FC_CPU?"CPU":"Synap");
    for (unsigned i=0; i<sizeof(demo_input); ++i) printf("%s%d", i ? "," : "", input[i]);
    printf("]\n");
    for (unsigned i=0; i<result.count; ++i) {
        printf("FC%d channel=%d acc=%d requant=%d output=%d\n", i<16?1:2, (int)(i<16?i:i-16),
               result.trace[i][0], result.trace[i][1], result.trace[i][2]);
        for (unsigned j=0; j<3; ++j) if (result.trace[i][j] != demo_trace[i][j]) result.valid=0;
    }
    printf("Output: [");
    for (unsigned i=0; i<bytes; ++i) printf("%s%d", i ? "," : "", output[i]);
    printf("]\nValidation (demo oracle): %s\n", result.valid && result.count==20 && bytes==4 ? "PASS" : "FAIL");
    printf("Time us: load=%d prepare=%d invoke=%d FC1=%d FC2=%d\n", load_us, prepare_us, invoke_us, result.fc_us[0], result.fc_us[1]);
    printf("Arena: %d / %d bytes\n", (int)psc_tflite_arena_used(), (int)PSC_TFLITE_ARENA_CAPACITY);
}

void cmd_tflite_run(const char *name) { cmd_tflite_run_backend(name, PSC_TFLITE_FC_CPU); }

/* CPU/NPU comparison and warm-invoke benchmark on the same resident model. */
typedef struct { int32_t row[20][5]; unsigned count; int compare, valid; } comparison_t;
static void compare_trace(void *user,unsigned layer,unsigned channel,
    int32_t raw,int32_t corrected,int32_t biased,int32_t requant,int8_t out) {
    comparison_t *r=user;
    unsigned index=layer==0?channel:16+channel;
    if(layer>1 || channel>=(layer==0?16u:4u) || index!=r->count) {r->valid=0;return;}
    int32_t values[5]={raw,corrected,biased,requant,out};
    for(unsigned j=0;j<5;++j) {
        if(r->compare) {if(r->row[index][j]!=values[j])r->valid=0;}
        else r->row[index][j]=values[j];
    }
    ++r->count;
}
static int benchmark_invoke(int *us,int *fc1,int *fc2) {
    int timing=call_timer_measure_begin();
    int rc=psc_tflite_invoke();
    *us=timing==0?call_timer_measure_end_us():-1;
    demo_result_t result={.fc_us={-1,-1}};
    if(!rc)rc=psc_tflite_invoke_traced(0,demo_layer,&result);
    *fc1=result.fc_us[0];*fc2=result.fc_us[1];return rc;
}
void cmd_tflite_bench(const char *name) {
    int rc=psc_tflite_load(name);size_t bytes;
    int8_t *input=psc_tflite_get_input(&bytes);
    if(rc || !input || bytes!=16) {printf("TFLite bench error %d\n",rc?rc:PSC_TFLITE_ERR_GRAPH);return;}
    memcpy(input,demo_input,16);
    comparison_t comparison={.valid=1};
    rc=psc_tflite_invoke_detailed(compare_trace,&comparison);
    if(rc || comparison.count!=20) {printf("Comparison: FAIL shape/runtime\n");return;}
    for(unsigned i=0;i<20;++i)for(unsigned j=0;j<3;++j)
        if(comparison.row[i][j+2]!=demo_trace[i][j]) comparison.valid=0;
    const int8_t *output=psc_tflite_get_output(&bytes);
    if(!output || bytes!=4 || !comparison.valid) {printf("Comparison: FAIL demo oracle\n");return;}
    int us,fc1,fc2;
    rc=benchmark_invoke(&us,&fc1,&fc2);
    if(rc) {printf("Benchmark error %d\n",rc);return;}
    printf("BENCH backend=cpu tile=0 invoke=%d FC1=%d FC2=%d us\n",us,fc1,fc2);
    for(unsigned tile=4;tile<=16;tile+=4) {
        /* Switch CPU -> NPU each time, without reloading/repreparing. */
        psc_tflite_set_fc_backend(PSC_TFLITE_FC_CPU);
        comparison.compare=0;comparison.count=0;
        rc=psc_tflite_invoke_detailed(compare_trace,&comparison);
        if(rc)break;
        psc_tflite_set_synap_tile_size(tile);
        psc_tflite_set_fc_backend(PSC_TFLITE_FC_SYNAP);
        comparison.compare=1;comparison.count=0;
        rc=psc_tflite_invoke_detailed(compare_trace,&comparison);
        if(rc || comparison.count!=20 || !comparison.valid)break;
        for(unsigned i=0;i<20;++i)
            printf("MATCH tile=%d FC%d channel=%d raw=%d corrected=%d bias=%d requant=%d output=%d\n",
                (int)tile,i<16?1:2,(int)(i<16?i:i-16),comparison.row[i][0],comparison.row[i][1],
                comparison.row[i][2],comparison.row[i][3],comparison.row[i][4]);
        rc=benchmark_invoke(&us,&fc1,&fc2);if(rc)break;
        printf("BENCH backend=npu tile=%d invoke=%d FC1=%d FC2=%d us\n",(int)tile,us,fc1,fc2);
        psc_tflite_set_profiling(1);
        int timing=call_timer_measure_begin();
        rc=psc_tflite_invoke();
        int profiled=timing==0?call_timer_measure_end_us():-1;
        const psc_tflite_profile_t *p=psc_tflite_get_profile();
        printf("PROFILE tile=%d total=%d tiles=%d pack=%d syscall=%d copy_in=%d run=%d copy_out=%d partial=%d post=%d valid=%d us\n",
            (int)tile,profiled,(int)p->tiles,(int)p->packing_us,(int)p->syscall_us,(int)p->copy_in_us,
            (int)p->execute_us,(int)p->copy_out_us,(int)p->partial_us,(int)p->post_us,p->valid);
        psc_tflite_set_profiling(0);if(rc)break;
        /* Change every input and reuse all user/kernel/SA result buffers. */
        for(unsigned i=0;i<16;++i)input[i]=(int8_t)(127-i*13);
        psc_tflite_set_fc_backend(PSC_TFLITE_FC_CPU);
        comparison.compare=0;comparison.count=0;
        rc=psc_tflite_invoke_detailed(compare_trace,&comparison);if(rc)break;
        psc_tflite_set_fc_backend(PSC_TFLITE_FC_SYNAP);
        comparison.compare=1;comparison.count=0;
        rc=psc_tflite_invoke_detailed(compare_trace,&comparison);
        if(rc || comparison.count!=20 || !comparison.valid)break;
        memcpy(input,demo_input,16);
    }
    if(rc || !comparison.valid || comparison.count!=20) {
        printf("Comparison: FAIL error=%d (%s)\n",rc,psc_tflite_error_string(rc));return;
    }
    /* Invalid requests must be rejected before touching the engine/buffers. */
    int32_t dummy[16];
    if(call_sa_matmul_int8(input,input,dummy,0,0)!=-1 ||
       call_sa_matmul_int8(0,input,dummy,4,0)!=-1 ||
       call_sa_matmul_int8(input,input,(int32_t *)(uintptr_t)1,4,0)!=-1) {
        printf("Comparison: FAIL syscall validation\n");return;
    }
    psc_tflite_set_fc_backend(PSC_TFLITE_FC_CPU);psc_tflite_set_synap_tile_size(4);
    rc=psc_tflite_invoke();output=psc_tflite_get_output(&bytes);
    if(rc || !output || bytes!=4) {printf("Comparison: FAIL final invoke\n");return;}
    for(unsigned i=0;i<4;++i)if(output[i]!=demo_trace[16+i][2])comparison.valid=0;
    printf("Comparison: %s (all 20 channels, five stages, changed inputs, backend switching)\n",comparison.valid?"PASS":"FAIL");
    printf("Output: [%d,%d,%d,%d]\n",output[0],output[1],output[2],output[3]);
}
