#ifndef SPEECH_RECOGNITION_API_H
#define SPEECH_RECOGNITION_API_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define SPEECH_SAMPLE_RATE       16000u
#define SPEECH_RECORD_SECONDS    3u
#define SPEECH_RECORD_SAMPLES    (SPEECH_SAMPLE_RATE * SPEECH_RECORD_SECONDS)
#define SPEECH_FRAME_COUNT       4u
#define SPEECH_BAND_COUNT        16u
#define SPEECH_FEATURE_COUNT     (SPEECH_FRAME_COUNT * SPEECH_BAND_COUNT)
#define SPEECH_HIDDEN_COUNT      16u
#define SPEECH_CLASS_COUNT       3u

typedef enum {
    SPEECH_CLASS_UP = 0,
    SPEECH_CLASS_DOWN = 1,
    SPEECH_CLASS_UNKNOWN = 2,
    SPEECH_CLASS_ERROR = -1
} speech_class_t;

typedef struct {
    speech_class_t class_id;
    int32_t score[SPEECH_CLASS_COUNT];
    uint32_t voice_start;
    uint32_t voice_end;
} speech_result_t;

typedef struct {
    /* Row-major: hidden neuron x input feature. */
    const int8_t *dense1_weight;
    const int32_t *dense1_bias;

    /* Row-major: output neuron x hidden neuron. */
    const int8_t *dense2_weight;
    const int32_t *dense2_bias;

    /* Right shift after each dense layer. Set to zero for no shift. */
    uint8_t dense1_shift;
    uint8_t dense2_shift;
} speech_model_t;

/* Set trained INT8 model. Passing NULL restores the built-in dummy model. */
void speech_recognition_set_model(const speech_model_t *model);

/* Record samples directly from the I2S microphone. */
uint32_t speech_record(int16_t *samples, uint32_t count);

/* Recognize an already captured signed 16-bit PCM buffer. */
int speech_recognize_pcm(
    const int16_t *samples,
    uint32_t count,
    speech_result_t *result);

/* Kernel-side command/syscall entry: record three seconds and classify. */
int32_t s_call_speech_recognition_api(void);

const char *speech_class_name(speech_class_t class_id);

#ifdef __cplusplus
}
#endif

#endif