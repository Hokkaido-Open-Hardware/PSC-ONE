#ifndef PSC_TFLITE_GRAPH_H
#define PSC_TFLITE_GRAPH_H
#include "tflite_api.h"
#ifndef PSC_TFLITE_GRAPH_ARENA_CAPACITY
#define PSC_TFLITE_GRAPH_ARENA_CAPACITY (768u*1024u)
#endif
#ifdef __cplusplus
extern "C" {
#endif
/* Structural analysis succeeds even when some CPU kernels are unavailable.
   Estimate is a lifetime peak lower bound; unsupported scratch is unknown. */
uint8_t *psc_tflite_graph_arena(size_t *capacity);
int psc_tflite_analyze(const void *, size_t, psc_tflite_log_fn, void *, psc_tflite_info_t *);
int psc_tflite_graph_is_fc(const void *verified_model);
int psc_tflite_graph_prepare(const void *,size_t,uint8_t *,size_t,size_t *,int8_t **,size_t *,int8_t **,size_t *);
int psc_tflite_graph_invoke(psc_tflite_layer_fn,void *,enum psc_tflite_fc_backend,
    unsigned,int32_t *,psc_tflite_operator_profile_t *,psc_tflite_profile_t *);
void psc_tflite_graph_reset(void);
unsigned psc_tflite_graph_count(void);
void psc_tflite_graph_trace(psc_tflite_tensor_trace_fn,void *);
void psc_tflite_graph_debug(psc_tflite_log_fn,void *,enum psc_tflite_fc_backend);
const char *psc_tflite_graph_reason(unsigned,enum psc_tflite_fc_backend,int);
int psc_tflite_inspect_fc(const void *,size_t,psc_tflite_log_fn,void *,psc_tflite_info_t *);
#ifdef __cplusplus
}
#endif
#endif
