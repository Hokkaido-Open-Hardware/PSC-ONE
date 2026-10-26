#ifndef PSC_YOLO_H
#define PSC_YOLO_H
#include <stdint.h>
#include <stddef.h>
#include "../tflite/tflite_api.h"
#ifdef __cplusplus
extern "C" {
#endif
#define YOLO_SIDE 160u
#define YOLO_CLASSES 80u
#define YOLO_ANCHORS 525u
#define YOLO_MAX_DETECTIONS 50u
#define YOLO_INPUT_BYTES (3u * YOLO_SIDE * YOLO_SIDE * sizeof(float))
#define YOLO_OUTPUT_BYTES (84u * YOLO_ANCHORS * sizeof(float))
#define YOLO_CONFIDENCE 0.25f
#define YOLO_IOU 0.45f
enum { YOLO_ERR_ARGUMENT = -300, YOLO_ERR_PROFILE = -301,
       YOLO_ERR_PREPROCESS = -302, YOLO_ERR_OUTPUT = -303 };
typedef struct {
    uint32_t width, height, resized_width, resized_height, left, top;
    float scale;
} yolo_geometry_t;
typedef struct {
    float x1, y1, x2, y2, score;
    uint16_t class_id, anchor;
} yolo_detection_t;
typedef struct {
    yolo_geometry_t geometry;
    yolo_detection_t detections[YOLO_MAX_DETECTIONS];
    unsigned candidates, nms_count, count, truncated;
    uint32_t input_hash, output_hash;
    int load_us, preprocess_us, invoke_us, postprocess_us;
} yolo_result_t;
/* Fixed profile: normalized xywh + 80 COCO sigmoid scores, FLOAT32
   [1,3,160,160] -> [1,84,525]. Synchronous singleton workspaces, no heap.
   Failure clears result; no partially decoded image is inferred. */
int psc_yolo_run(const char *model, const char *jpeg, yolo_result_t *result);
/* Persistent YOLO preference, reapplied after each load/prepare; default CPU.
   Independent of tflite_run. No model/arena allocation or mutation here. */
int psc_yolo_set_backend(enum psc_tflite_fc_backend backend);
enum psc_tflite_fc_backend psc_yolo_get_backend(void);
void cmd_yolo_backend(const char *name);
void cmd_yolo_diagnostics(int enabled);
void cmd_yolo(const char *model, const char *jpeg);
const char *yolo_class_name(unsigned id);
/* Pure postprocessing, same singleton workspace restriction. */
int yolo_postprocess(const float *output, size_t bytes,
                     const yolo_geometry_t *geometry, yolo_result_t *result);
#ifdef __cplusplus
}
#endif
#endif
