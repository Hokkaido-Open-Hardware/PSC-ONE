#include "yolo.h"
#include "yolo_preprocess.h"
#include "yolo_display.h"
#include "../tflite/tflite_api.h"
#include "../jpeg/jpeg_view.h"
#include "../user.h"
#include <string.h>

static int yolo_busy;
static enum psc_tflite_fc_backend yolo_backend = PSC_TFLITE_FC_CPU;
static int yolo_diagnostics;
static yolo_result_t command_result;
int psc_yolo_set_backend(enum psc_tflite_fc_backend backend)
{
    if (yolo_busy) return PSC_TFLITE_ERR_BUSY;
    if (backend < PSC_TFLITE_FC_CPU || backend > PSC_TFLITE_FC_AUTO)
        return YOLO_ERR_ARGUMENT;
    yolo_backend = backend;
    return 0;
}
enum psc_tflite_fc_backend psc_yolo_get_backend(void) { return yolo_backend; }
void cmd_yolo_diagnostics(int enabled) { if (!yolo_busy) yolo_diagnostics = enabled != 0; }
void cmd_yolo_backend(const char *name)
{
    if (name) {
        int mode;
        for (mode = 0; mode <= PSC_TFLITE_FC_AUTO; ++mode)
            if (!strcmp(name, psc_tflite_backend_name((enum psc_tflite_fc_backend)mode))) break;
        if (mode > PSC_TFLITE_FC_AUTO) {
            printf("usage: yolo_backend cpu|pulp|npu|auto\n"); return;
        }
        int rc = psc_yolo_set_backend((enum psc_tflite_fc_backend)mode);
        if (rc) { printf("YOLO backend error %d\n", rc); return; }
    }
    printf("YOLO requested=%s (applied after load/prepare)\n", psc_tflite_backend_name(yolo_backend));
}
static uint32_t hash_bytes(const void *data, size_t bytes)
{
    const uint8_t *p = data; uint32_t h = 2166136261u;
    for (size_t i = 0; i < bytes; ++i) h = (h ^ p[i])*16777619u;
    return h;
}
static int profile_ok(void)
{
    psc_tflite_tensor_info_t in, out;
    return !psc_tflite_get_io_info(0, &in) && !psc_tflite_get_io_info(1, &out) &&
        in.type == 0 && in.rank == 4 && in.dims[0] == 1 && in.dims[1] == 3 &&
        in.dims[2] == YOLO_SIDE && in.dims[3] == YOLO_SIDE && in.bytes == YOLO_INPUT_BYTES &&
        out.type == 0 && out.rank == 3 && out.dims[0] == 1 && out.dims[1] == 84 &&
        out.dims[2] == YOLO_ANCHORS && out.bytes == YOLO_OUTPUT_BYTES &&
        psc_tflite_operator_count() == 289;
}
static int end_time(int started) { return started == 0 ? call_timer_measure_end_us() : -1; }
static int tensor_trace(void *user, unsigned op, int tensor, const void *data, size_t bytes, int type)
{
    (void)user;
    printf("TensorTrace op=%d tensor=%d type=%d bytes=%d fnv1a32=%x\n",
        (int)op, tensor, type, (int)bytes, hash_bytes(data, bytes));
    return 0;
}
static void execution_report(int rc, int wall_us)
{
    const psc_tflite_execution_t *e = psc_tflite_get_execution();
    const psc_tflite_profile_t *p = psc_tflite_get_profile();
    printf("YOLO requested=%s status=%d completed=%d CPU=%d PULP=%d NPU=%d fallbacks=%d\n",
        psc_tflite_backend_name(yolo_backend), rc, (int)e->completed,
        (int)e->operators[0], (int)e->operators[2], (int)e->operators[1], (int)e->fallbacks);
    printf("YOLO invoke_wall_us=%d operator_sum_us: CPU=%d PULP=%d NPU=%d\n",
        wall_us, e->invoke_us[0], e->invoke_us[2], e->invoke_us[1]);
    printf("YOLO CPU sum covers only completed CPU operators, not a CPU-only model benchmark\n");
    printf("YOLO NPU successful_tiles=%d profile_valid=%d device_status=%d\n",
        (int)p->tiles, p->valid, p->device_status);
    /* Aggregate actual CPU fallback reasons outside the inference stopwatch.
       No new buffers; reason strings come from the existing graph selector. */
    for (unsigned i = 0; i < e->completed; ++i) {
        const psc_tflite_operator_profile_t *r = psc_tflite_get_operator_profile(i);
        const char *reason = psc_tflite_get_operator_reason(i);
        if (yolo_diagnostics)
            printf("YOLO op=%d kind=%d actual=%s us=%d tiles=%d reason=%s\n", (int)i,
                r->kind, psc_tflite_backend_name((enum psc_tflite_fc_backend)r->backend),
                r->us, (int)r->npu_tiles, reason);
        if (yolo_backend == PSC_TFLITE_FC_CPU || r->backend != PSC_TFLITE_FC_CPU) continue;
        unsigned j, count = 0;
        for (j = 0; j < i; ++j)
            if (psc_tflite_get_operator_profile(j)->backend == PSC_TFLITE_FC_CPU &&
                !strcmp(reason, psc_tflite_get_operator_reason(j))) break;
        if (j != i) continue;
        for (j = i; j < e->completed; ++j)
            if (psc_tflite_get_operator_profile(j)->backend == PSC_TFLITE_FC_CPU &&
                !strcmp(reason, psc_tflite_get_operator_reason(j))) ++count;
        printf("YOLO fallback count=%d reason=%s\n", (int)count, reason);
    }
    if (rc && e->completed < psc_tflite_operator_count()) {
        const psc_tflite_operator_profile_t *r = psc_tflite_get_operator_profile(e->completed);
        printf("YOLO stopped op=%d attempted=%s status=%d tiles=%d; output invalid\n",
            (int)e->completed, psc_tflite_backend_name((enum psc_tflite_fc_backend)r->backend),
            r->status, (int)r->npu_tiles);
    }
}
static void progress(void *user, unsigned op, int begin)
{
    (void)user;
    if (begin && (op == 0 || (op+1)%25 == 0 || op == 288))
        printf("YOLO requested=%s operator %d/289\n", psc_tflite_backend_name(yolo_backend), (int)op+1);
}
int psc_yolo_run(const char *model, const char *jpeg, yolo_result_t *result)
{
    if (yolo_busy) return PSC_TFLITE_ERR_BUSY;
    if (!result || !model || !jpeg) {
        if (result) memset(result, 0, sizeof(*result));
        psc_tflite_reset();
        return YOLO_ERR_ARGUMENT;
    }
    memset(result, 0, sizeof(*result));
    yolo_busy = 1;
    uint32_t width, height;
    printf("YOLO: check JPEG %s\n", jpeg);
    int rc = jpeg_probe(jpeg, &width, &height);
    if (rc) goto done;
    printf("YOLO: load %s; profile=normalized-xywh COCO80\n", model);
    /* load's internal stopwatches decline this occupied timer; the outer
       stopwatch measures load+prepare and is released here on every result. */
    int started = call_timer_measure_begin();
    rc = psc_tflite_load(model);
    int load_us = end_time(started);
    if (rc) goto done;
    if (!profile_ok()) { rc = YOLO_ERR_PROFILE; goto done; }
    /* Both load and prepare reset runtime options. Apply the persistent
       application preference only after successful load/prepare. */
    rc = psc_tflite_set_fc_backend(yolo_backend);
    if (rc) goto done;
    psc_tflite_set_profiling(1);
    psc_tflite_set_tensor_trace(yolo_diagnostics ? tensor_trace : 0, 0);
    size_t bytes;
    float *input = (float *)psc_tflite_get_input(&bytes);
    if (!input || bytes != YOLO_INPUT_BYTES) { rc = YOLO_ERR_PROFILE; goto done; }
    printf("YOLO: JPEG %s -> RGB/255 CHW [1,3,160,160]\n", jpeg);
    yolo_geometry_t geometry;
    started = call_timer_measure_begin();
    rc = yolo_prepare_jpeg(jpeg, input, bytes, &geometry);
    int preprocess_us = end_time(started);
    if (rc) goto done;
    uint32_t input_hash = hash_bytes(input, bytes);
    printf("YOLO image=%dx%d resize=%dx%d pad_ltrb=%d,%d,%d,%d input_fnv=%x\n",
        (int)geometry.width, (int)geometry.height, (int)geometry.resized_width,
        (int)geometry.resized_height, (int)geometry.left, (int)geometry.top,
        (int)(YOLO_SIDE-geometry.resized_width-geometry.left),
        (int)(YOLO_SIDE-geometry.resized_height-geometry.top), input_hash);
    started = call_timer_measure_begin();
    rc = psc_tflite_invoke_traced(0, progress, 0);
    int invoke_us = end_time(started);
    execution_report(rc, invoke_us);
    if (rc) goto done;
    const psc_tflite_execution_t *execution = psc_tflite_get_execution();
    const float *output = (const float *)psc_tflite_get_output(&bytes);
    if (!output || bytes != YOLO_OUTPUT_BYTES || execution->completed != 289 ||
        execution->operators[0] + execution->operators[1] + execution->operators[2] != 289) {
        rc = YOLO_ERR_OUTPUT; goto done;
    }
    uint32_t output_hash = hash_bytes(output, bytes);
    started = call_timer_measure_begin();
    rc = yolo_postprocess(output, bytes, &geometry, result);
    int postprocess_us = end_time(started);
    if (rc) goto done;
    result->input_hash = input_hash; result->output_hash = output_hash;
    result->load_us = load_us; result->preprocess_us = preprocess_us;
    result->invoke_us = invoke_us; result->postprocess_us = postprocess_us;
done:
    if (rc) {
        memset(result, 0, sizeof(*result));
        psc_tflite_reset(); /* never expose stale inference after a JPEG error */
    }
    yolo_busy = 0;
    return rc;
}
void cmd_yolo(const char *model, const char *jpeg)
{
    /* Clear before inference so a timeout cannot leave the previous detection
       on screen. Fail closed if the LCD cannot acknowledge the clear. */
    int started = call_timer_measure_begin();
    int rc = yolo_display_clear();
    int clear_us = end_time(started);
    printf("YOLO LCD us: clear=%d (-1=unavailable)\n", clear_us);
    if (rc) {
        memset(&command_result, 0, sizeof(command_result));
        psc_tflite_reset();
        printf("YOLO LCD clear error %d: old screen may remain; inference not started\n", rc);
        return;
    }
    rc = psc_yolo_run(model, jpeg, &command_result);
    if (rc) {
        const char *error = rc <= -300 ? "YOLO profile/input/output error" :
            rc <= -200 ? psc_tflite_error_string(rc) : jpeg_error_string(rc);
        printf("YOLO error %d: %s\n", rc, error);
        return;
    }
    const yolo_result_t *r = &command_result;
    printf("YOLO complete: 289 operators; requested=%s output=[1,84,525] fnv=%x\n",
        psc_tflite_backend_name(yolo_backend), r->output_hash);
    printf("YOLO conf_milli=250 iou_milli=450 candidates=%d nms=%d detections=%d truncated=%d\n",
        (int)r->candidates, (int)r->nms_count, (int)r->count, (int)r->truncated);
    /* Only %s/%d/%x are supported by the PSC user printf. Values below have
       already been checked finite, clipped and bounded before conversion. */
    for (unsigned i = 0; i < r->count; ++i) {
        const yolo_detection_t *d = &r->detections[i];
        printf("DET anchor=%d class=%d name=%s score_milli=%d xyxy_milli=%d,%d,%d,%d\n",
            (int)d->anchor, (int)d->class_id, yolo_class_name(d->class_id),
            (int)(d->score*1000+0.5f), (int)(d->x1*1000+0.5f), (int)(d->y1*1000+0.5f),
            (int)(d->x2*1000+0.5f), (int)(d->y2*1000+0.5f));
    }
    printf("YOLO us: load_prepare=%d jpeg_preprocess=%d invoke_wall=%d nms=%d (-1=unavailable)\n",
        r->load_us, r->preprocess_us, r->invoke_us, r->postprocess_us);
    printf("YOLO invoke_wall includes progress UART and optional tensor diagnostics; coordinates are original-image pixels x1000\n");
    printf("YOLO arena=%d/%d bytes\n", (int)psc_tflite_arena_used(), (int)psc_tflite_arena_capacity());
    started = call_timer_measure_begin();
    rc = yolo_display(jpeg, r);
    int lcd_us = end_time(started);
    if (rc)
        printf("YOLO LCD error %d: %s; inference results retained\n", rc,
               rc == YOLO_ERR_ARGUMENT ? "invalid display result or image dimensions" : jpeg_error_string(rc));
    else
        printf("YOLO LCD complete: JPEG + %d detections (480x320 landscape)\n", (int)r->count);
    printf("YOLO LCD us: jpeg_overlay=%d (-1=unavailable)\n", lcd_us);
}
