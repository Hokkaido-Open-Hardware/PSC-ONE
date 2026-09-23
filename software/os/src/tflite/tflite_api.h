#ifndef PSC_TFLITE_API_H
#define PSC_TFLITE_API_H
#include "tflite_inspect.h"
#define PSC_TFLITE_ARENA_CAPACITY 4096u
enum psc_tflite_fc_backend { PSC_TFLITE_FC_CPU=0, PSC_TFLITE_FC_SYNAP=1, PSC_TFLITE_FC_PULP=2 };
enum { PSC_TFLITE_ERR_SYNAP=-206, PSC_TFLITE_ERR_SYNAP_TIMEOUT=-207,
       PSC_TFLITE_ERR_SYNAP_ARGUMENT=-208, PSC_TFLITE_ERR_SYNAP_BUSY=-209 };
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
/* Default CPU and tile=4 after load/prepare/reset. Switching invalidates only
   output, preserving the prepared model and input. PULP falls back to CPU when unavailable; Synap errors never fall back. */
int psc_tflite_set_fc_backend(enum psc_tflite_fc_backend backend);
int psc_tflite_set_synap_tile_size(unsigned size); /* 4,8,12,16 */
typedef struct {
    uint32_t tiles, packing_us, syscall_us, copy_in_us, execute_us, copy_out_us;
    uint32_t partial_us, post_us;
    int valid, device_status;
} psc_tflite_profile_t;
int psc_tflite_set_profiling(int enabled);
const psc_tflite_profile_t *psc_tflite_get_profile(void);
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
/* Read-only diagnostics, outside timed inference. */
int psc_tflite_debug_model(const void *model, size_t size, psc_tflite_log_fn log, void *user);
int psc_tflite_debug_fc(psc_tflite_log_fn log, void *user);
void cmd_tflite_run(const char *name);
void cmd_tflite_run_backend(const char *name, enum psc_tflite_fc_backend backend);
void cmd_tflite_bench(const char *name);
#ifdef __cplusplus
}
#endif
#endif
