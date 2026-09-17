#ifndef PSC_TFLITE_INSPECT_H
#define PSC_TFLITE_INSPECT_H

#include <stddef.h>
#include <stdint.h>

#define PSC_TFLITE_MODEL_CAPACITY 8192u
#define PSC_TFLITE_MAX_TENSORS 32u
#define PSC_TFLITE_MAX_OPERATORS 8u

#ifdef __cplusplus
extern "C" {
#endif

enum {
    PSC_TFLITE_OK = 0,
    PSC_TFLITE_ERR_SIZE = -200,
    PSC_TFLITE_ERR_FORMAT = -201,
    PSC_TFLITE_ERR_UNSUPPORTED = -202,
    PSC_TFLITE_ERR_GRAPH = -203,
    PSC_TFLITE_ERR_TRUNCATED = -204,
    PSC_TFLITE_ERR_BUSY = -205
};

typedef void (*psc_tflite_log_fn)(void *user, const char *text);
/* No pointers into the model are retained. Counts are valid only on success.
   Compatibility here does not include prepare arena/accumulator range checks. */
typedef struct {
    uint32_t version, tensors, operators, constant_bytes, tensor_bytes;
} psc_tflite_info_t;

/* data must be 16-byte aligned and remain immutable for this call. */
int psc_tflite_inspect(const void *data, size_t size,
                      psc_tflite_log_fn log, void *user,
                      psc_tflite_info_t *info);
/* Root directory uppercase 8.3 FAT32 filename; shared 8 KiB buffer, no heap. */
int psc_tflite_inspect_file(const char *name, psc_tflite_log_fn log, void *user,
                           psc_tflite_info_t *info);
const char *psc_tflite_error_string(int error);
void cmd_tflite_info(const char *name);

#ifdef __cplusplus
}
#endif
#endif
