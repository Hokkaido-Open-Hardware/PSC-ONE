#include "yolo.h"
#include "../jpeg_display.h"
#include <string.h>

static yolo_detection_t candidates[YOLO_ANCHORS];
static uint8_t suppressed[YOLO_ANCHORS];
_Static_assert(sizeof(float) == 4, "YOLO FLOAT32");
_Static_assert(sizeof(yolo_detection_t) == 24, "YOLO candidate memory budget");

static const char *const names[YOLO_CLASSES] = {
    "person", "bicycle", "car", "motorcycle", "airplane", "bus", "train", "truck",
    "boat", "traffic light", "fire hydrant", "stop sign", "parking meter", "bench",
    "bird", "cat", "dog", "horse", "sheep", "cow", "elephant", "bear", "zebra",
    "giraffe", "backpack", "umbrella", "handbag", "tie", "suitcase", "frisbee",
    "skis", "snowboard", "sports ball", "kite", "baseball bat", "baseball glove",
    "skateboard", "surfboard", "tennis racket", "bottle", "wine glass", "cup",
    "fork", "knife", "spoon", "bowl", "banana", "apple", "sandwich", "orange",
    "broccoli", "carrot", "hot dog", "pizza", "donut", "cake", "chair", "couch",
    "potted plant", "bed", "dining table", "toilet", "tv", "laptop", "mouse",
    "remote", "keyboard", "cell phone", "microwave", "oven", "toaster", "sink",
    "refrigerator", "book", "clock", "vase", "scissors", "teddy bear", "hair drier", "toothbrush"
};
const char *yolo_class_name(unsigned id) { return id < YOLO_CLASSES ? names[id] : "unknown"; }
static int finite_float(float value)
{
    uint32_t bits; memcpy(&bits, &value, sizeof(bits));
    return (bits & 0x7f800000u) != 0x7f800000u;
}
static float minf(float a, float b) { return a < b ? a : b; }
static float maxf(float a, float b) { return a > b ? a : b; }
static float area(const yolo_detection_t *d) { return (d->x2-d->x1)*(d->y2-d->y1); }
static int overlap(const yolo_detection_t *a, const yolo_detection_t *b)
{
    float w = maxf(0, minf(a->x2,b->x2)-maxf(a->x1,b->x1));
    float h = maxf(0, minf(a->y2,b->y2)-maxf(a->y1,b->y1));
    float intersection = w*h, total = area(a)+area(b)-intersection;
    return total > 0 && finite_float(total) && intersection/total > YOLO_IOU;
}
int yolo_postprocess(const float *output, size_t bytes,
                     const yolo_geometry_t *geometry, yolo_result_t *result)
{
    if (!result) return YOLO_ERR_ARGUMENT;
    yolo_geometry_t g = geometry ? *geometry : (yolo_geometry_t){0};
    memset(result, 0, sizeof(*result));
    if (!output || ((uintptr_t)output & 3) || bytes != YOLO_OUTPUT_BYTES ||
        !g.width || g.width > JPEG_LCD_WIDTH || !g.height || g.height > JPEG_LCD_HEIGHT ||
        !g.resized_width || g.resized_width > YOLO_SIDE ||
        !g.resized_height || g.resized_height > YOLO_SIDE ||
        g.left > YOLO_SIDE-g.resized_width || g.top > YOLO_SIDE-g.resized_height ||
        !finite_float(g.scale) || g.scale <= 0) return YOLO_ERR_ARGUMENT;
    result->geometry = g;
    unsigned n = 0;
    for (unsigned i = 0; i < YOLO_ANCHORS; ++i) {
        float cx = output[i]*YOLO_SIDE, cy = output[YOLO_ANCHORS+i]*YOLO_SIDE;
        float w = output[2*YOLO_ANCHORS+i]*YOLO_SIDE, h = output[3*YOLO_ANCHORS+i]*YOLO_SIDE;
        if (!finite_float(cx) || !finite_float(cy) || !finite_float(w) ||
            !finite_float(h) || w <= 0 || h <= 0) continue;
        float score = -1; unsigned cls = 0; int valid = 1;
        for (unsigned c = 0; c < YOLO_CLASSES; ++c) {
            float s = output[(4+c)*YOLO_ANCHORS+i];
            if (!finite_float(s) || s < 0 || s > 1) { valid = 0; break; }
            if (s > score) { score = s; cls = c; }
        }
        if (!valid || score <= YOLO_CONFIDENCE) continue;
        yolo_detection_t d = {cx-w/2, cy-h/2, cx+w/2, cy+h/2, score, cls, i};
        if (!finite_float(d.x1) || !finite_float(d.y1) ||
            !finite_float(d.x2) || !finite_float(d.y2) ||
            d.x2 <= d.x1 || d.y2 <= d.y1 || !finite_float(area(&d))) continue;
        /* Stable insertion: ascending anchor order breaks score ties.
           Bounded 525 candidates; no recursive sort or stack-sized arrays. */
        unsigned pos = n;
        while (pos && candidates[pos-1].score < score) {
            candidates[pos] = candidates[pos-1]; --pos;
        }
        candidates[pos] = d; ++n;
    }
    result->candidates = n;
    memset(suppressed, 0, sizeof(suppressed));
    for (unsigned i = 0; i < n; ++i) {
        if (suppressed[i]) continue;
        ++result->nms_count;
        for (unsigned j = i+1; j < n; ++j)
            if (!suppressed[j] && candidates[i].class_id == candidates[j].class_id &&
                overlap(&candidates[i], &candidates[j])) suppressed[j] = 1;
        yolo_detection_t d = candidates[i];
        d.x1 = minf(g.width, maxf(0, (d.x1-g.left)/g.scale));
        d.x2 = minf(g.width, maxf(0, (d.x2-g.left)/g.scale));
        d.y1 = minf(g.height, maxf(0, (d.y1-g.top)/g.scale));
        d.y2 = minf(g.height, maxf(0, (d.y2-g.top)/g.scale));
        if (d.x2 <= d.x1 || d.y2 <= d.y1) continue;
        if (result->count < YOLO_MAX_DETECTIONS) result->detections[result->count++] = d;
        else ++result->truncated;
    }
    return 0;
}
