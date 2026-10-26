#ifndef PSC_TFLITE_API_H
#define PSC_TFLITE_API_H
#include "tflite_inspect.h"
#include "../sa_limits.h"
#define PSC_TFLITE_ARENA_CAPACITY 4096u
enum psc_tflite_fc_backend { PSC_TFLITE_FC_CPU=0, PSC_TFLITE_FC_SYNAP=1, PSC_TFLITE_FC_PULP=2, PSC_TFLITE_FC_AUTO=3 };
enum { PSC_TFLITE_ERR_SYNAP=-206, PSC_TFLITE_ERR_SYNAP_TIMEOUT=-207,
       PSC_TFLITE_ERR_SYNAP_ARGUMENT=-208, PSC_TFLITE_ERR_SYNAP_BUSY=-209,
       PSC_TFLITE_ERR_ARENA=-210 };
#ifdef __cplusplus
extern "C" {
#endif
/* Single resident model; synchronous, non-reentrant PSC-OS API, no heap.
   load replaces/invalidate the previous model even on failure.
   prepare borrows aligned immutable bytes until reset/load/prepare.
   get_input/output pointers expire on reset/load/prepare/inspect_file.
   Output is available only after a successful invoke. */
int psc_tflite_load(const char *name);
int psc_tflite_prepare(const void *model, size_t size);
int psc_tflite_reset(void);
int8_t *psc_tflite_get_input(size_t *bytes);
const int8_t *psc_tflite_get_output(size_t *bytes);
int psc_tflite_invoke(void);
size_t psc_tflite_arena_used(void);
size_t psc_tflite_arena_capacity(void);
unsigned psc_tflite_operator_count(void);
typedef struct {int32_t tensor,type,rank,dims[8],zero_point;float scale;size_t bytes;} psc_tflite_tensor_info_t;
int psc_tflite_get_io_info(int output,psc_tflite_tensor_info_t *info);
/* Synchronous observer, after each generic operator, before Arena reuse.
   Returning nonzero aborts invoke safely; callback must not reenter the API. */
typedef int (*psc_tflite_tensor_trace_fn)(void *,unsigned,int,const void *,size_t,int);
int psc_tflite_set_tensor_trace(psc_tflite_tensor_trace_fn,void *);
/* Exact allocation plan for a supported graph, including alignment/row sums.
   Zero means unavailable (e.g. unsupported operators); retained on arena error. */
size_t psc_tflite_arena_required(void);
/* Default CPU; tile=4 for legacy FC/reset, tile=32 for generic graphs.
   Switching invalidates only
   output, preserving the prepared model and input. Unsupported operators or
   unavailable hardware use CPU. Started Synap errors abort; no unsafe retry.
   Legacy FC-only AUTO owns its calibrated NPU tile; the explicit setting is unchanged. */
int psc_tflite_set_fc_backend(enum psc_tflite_fc_backend backend);
int psc_tflite_set_synap_tile_size(unsigned size); /* multiples of 4, up to SA_MAT_MAX */
typedef struct {
    uint32_t tiles, packing_us, syscall_us, copy_in_us, execute_us, copy_out_us;
    uint32_t partial_us, post_us;
    int valid, device_status;
} psc_tflite_profile_t;
int psc_tflite_set_profiling(int enabled);
const psc_tflite_profile_t *psc_tflite_get_profile(void);
/* Last invocation: counts include only completed operators. Fallbacks count
   CPU operators in a non-CPU mode, including pre-dispatch unsupported cases.
   Times exclude layer/tensor callbacks; FC per-channel debug traces add overhead.
   -1 means clock unavailable/overflow. NPU tile counts (when profiling is on)
   are successful hardware calls, not requested mode labels. */
typedef struct { int kind, backend, us, status; uint32_t npu_tiles; } psc_tflite_operator_profile_t;
typedef struct { unsigned operators[3], fallbacks, completed; int invoke_us[3]; } psc_tflite_execution_t;
const psc_tflite_execution_t *psc_tflite_get_execution(void);
const psc_tflite_operator_profile_t *psc_tflite_get_operator_profile(unsigned index);
/* Last completed operator's dispatch/fallback reason; NULL before completion. */
const char *psc_tflite_get_operator_reason(unsigned index);
/* Debug callbacks run synchronously; must not reenter API or allocate/read files.
   requant is AFTER output zero point, BEFORE INT8 saturation and fused ReLU. */
typedef void (*psc_tflite_trace_fn)(void *, unsigned layer, unsigned channel,
                                  int32_t acc, int32_t requant, int8_t output);
typedef void (*psc_tflite_layer_fn)(void *, unsigned layer, int begin);
int psc_tflite_invoke_traced(psc_tflite_trace_fn trace,
                             psc_tflite_layer_fn layer, void *user);
typedef void (*psc_tflite_trace_ex_fn)(void *,unsigned layer,unsigned channel,
    int32_t raw,int32_t corrected,int32_t biased,int32_t requant,int8_t output);
int psc_tflite_invoke_detailed(psc_tflite_trace_ex_fn trace, void *user);
/* Read-only selection diagnostics, outside timed inference. No callback or
   formatting overhead inside invoke. channel in trace APIs is row*N+column. */
const char *psc_tflite_backend_name(enum psc_tflite_fc_backend backend);
int psc_tflite_debug_selection(psc_tflite_log_fn log, void *user);
/* Read-only diagnostics, outside timed inference. */
int psc_tflite_debug_model(const void *model, size_t size, psc_tflite_log_fn log, void *user);
int psc_tflite_debug_fc(psc_tflite_log_fn log, void *user);
void cmd_tflite_diagnostics(int enabled); /* shell diagnostics; default on */
void cmd_tflite_run(const char *name);
void cmd_tflite_run_backend(const char *name, enum psc_tflite_fc_backend backend);
void cmd_tflite_bench(const char *name);
void cmd_tflite_bench_quick(const char *name);
#ifdef __cplusplus
}
#endif
#endif
