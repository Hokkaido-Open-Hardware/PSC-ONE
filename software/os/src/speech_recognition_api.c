#include "speech_recognition_api.h"
#include "mic_api.h"
#include "kernel.h"
#include "common.h"

#include <stddef.h>
#include <stdint.h>

#define DETECT_BLOCK_SIZE   256u
#define MIN_ACTIVE_BLOCKS   2u
#define VOICE_THRESHOLD     300u

/*
 * This file intentionally owns only 96 KiB of PCM storage.
 * The trained parameters are supplied separately through speech_model_t.
 */
static int16_t speech_pcm[SPEECH_RECORD_SAMPLES];
static uint8_t speech_features[SPEECH_FEATURE_COUNT];
static int32_t speech_hidden[SPEECH_HIDDEN_COUNT];

/* Dummy model: always chooses UNKNOWN until trained weights are installed. */
static const int8_t dummy_dense1_weight[
    SPEECH_HIDDEN_COUNT * SPEECH_FEATURE_COUNT] = {0};
static const int32_t dummy_dense1_bias[SPEECH_HIDDEN_COUNT] = {0};
static const int8_t dummy_dense2_weight[
    SPEECH_CLASS_COUNT * SPEECH_HIDDEN_COUNT] = {0};
static const int32_t dummy_dense2_bias[SPEECH_CLASS_COUNT] = {0, 0, 1};

static const speech_model_t dummy_model = {
    dummy_dense1_weight,
    dummy_dense1_bias,
    dummy_dense2_weight,
    dummy_dense2_bias,
    0u,
    0u
};

static const speech_model_t *active_model = &dummy_model;

static uint32_t abs_s16(int16_t value)
{
    int32_t v = (int32_t)value;
    return (uint32_t)((v < 0) ? -v : v);
}

static int16_t sample24_to_s16(uint32_t raw)
{
    /* Sign-extend the microphone's 24-bit two's-complement sample. */
    int32_t sample = (int32_t)(raw & 0x00ffffffu);

    if ((sample & 0x00800000) != 0) {
        sample |= (int32_t)0xff000000u;
    }

    /* Keep the upper 16 significant bits. */
    return (int16_t)(sample >> 8);
}

static int detect_voice_range(
    const int16_t *samples,
    uint32_t count,
    uint32_t *voice_start,
    uint32_t *voice_end)
{
    uint32_t first = count;
    uint32_t last = 0u;
    uint32_t active_run = 0u;

    if ((samples == NULL) ||
        (voice_start == NULL) ||
        (voice_end == NULL) ||
        (count < DETECT_BLOCK_SIZE)) {
        return -1;
    }

    for (uint32_t base = 0u;
         base + DETECT_BLOCK_SIZE <= count;
         base += DETECT_BLOCK_SIZE) {

        uint32_t sum = 0u;

        for (uint32_t i = 0u; i < DETECT_BLOCK_SIZE; ++i) {
            sum += abs_s16(samples[base + i]);
        }

        const uint32_t average = sum / DETECT_BLOCK_SIZE;

        if (average >= VOICE_THRESHOLD) {
            ++active_run;

            if ((active_run == MIN_ACTIVE_BLOCKS) && (first == count)) {
                first = base -
                    (MIN_ACTIVE_BLOCKS - 1u) * DETECT_BLOCK_SIZE;
            }

            last = base + DETECT_BLOCK_SIZE;
        } else {
            active_run = 0u;
        }
    }

    if ((first == count) || (last <= first)) {
        return -1;
    }

    *voice_start = first;
    *voice_end = (last <= count) ? last : count;
    return 0;
}

/*
 * Weak feature extractor.
 *
 * The default implementation is deliberately lightweight and produces
 * 16 normalized activity/detail values for each of four time frames.
 * Replace it with a strong definition using the existing fft_api.c when
 * the exact fft_q15() interface is fixed. The NN-facing layout remains:
 *
 *   feature[frame * 16 + band]
 */
__attribute__((weak))
int speech_extract_features(
    const int16_t *samples,
    uint32_t count,
    uint32_t voice_start,
    uint32_t voice_end,
    uint8_t features[SPEECH_FEATURE_COUNT])
{
    uint32_t maximum = 1u;

    if ((samples == NULL) ||
        (features == NULL) ||
        (voice_end <= voice_start) ||
        (voice_end > count)) {
        return -1;
    }

    const uint32_t voice_length = voice_end - voice_start;

    for (uint32_t frame = 0u; frame < SPEECH_FRAME_COUNT; ++frame) {
        const uint32_t frame_start =
            voice_start + (voice_length * frame) / SPEECH_FRAME_COUNT;
        const uint32_t frame_end =
            voice_start + (voice_length * (frame + 1u)) /
            SPEECH_FRAME_COUNT;
        const uint32_t frame_length = frame_end - frame_start;

        if (frame_length < SPEECH_BAND_COUNT) {
            return -1;
        }

        for (uint32_t band = 0u; band < SPEECH_BAND_COUNT; ++band) {
            const uint32_t begin =
                frame_start + (frame_length * band) / SPEECH_BAND_COUNT;
            const uint32_t end =
                frame_start + (frame_length * (band + 1u)) /
                SPEECH_BAND_COUNT;

            uint32_t energy = 0u;
            int16_t previous = samples[begin];

            for (uint32_t i = begin; i < end; ++i) {
                const int16_t current = samples[i];
                energy += abs_s16(current);
                energy += abs_s16((int16_t)(current - previous));
                previous = current;
            }

            const uint32_t length = (end > begin) ? (end - begin) : 1u;
            const uint32_t value = energy / length;
            const uint32_t index = frame * SPEECH_BAND_COUNT + band;

            features[index] = (uint8_t)((value > 65535u) ? 255u :
                                        (value >> 8));

            if ((uint32_t)features[index] > maximum) {
                maximum = features[index];
            }
        }
    }

    /* Normalize to the same 0..127 range used by the training path. */
    for (uint32_t i = 0u; i < SPEECH_FEATURE_COUNT; ++i) {
        features[i] =
            (uint8_t)(((uint32_t)features[i] * 127u) / maximum);
    }

    return 0;
}

static int32_t shift_round(int32_t value, uint8_t shift)
{
    if (shift == 0u) {
        return value;
    }

    if (shift >= 31u) {
        return (value < 0) ? -1 : 0;
    }

    const int32_t rounding = (int32_t)1 << (shift - 1u);
    return (value >= 0) ?
        ((value + rounding) >> shift) :
        -(((-value) + rounding) >> shift);
}

static void run_dense_network(
    const uint8_t features[SPEECH_FEATURE_COUNT],
    int32_t scores[SPEECH_CLASS_COUNT])
{
    const speech_model_t *model = active_model;

    for (uint32_t h = 0u; h < SPEECH_HIDDEN_COUNT; ++h) {
        int32_t sum = model->dense1_bias[h];
        const uint32_t row = h * SPEECH_FEATURE_COUNT;

        for (uint32_t i = 0u; i < SPEECH_FEATURE_COUNT; ++i) {
            sum += (int32_t)features[i] *
                   (int32_t)model->dense1_weight[row + i];
        }

        sum = shift_round(sum, model->dense1_shift);
        speech_hidden[h] = (sum > 0) ? sum : 0;
    }

    for (uint32_t output = 0u; output < SPEECH_CLASS_COUNT; ++output) {
        int32_t sum = model->dense2_bias[output];
        const uint32_t row = output * SPEECH_HIDDEN_COUNT;

        for (uint32_t h = 0u; h < SPEECH_HIDDEN_COUNT; ++h) {
            sum += speech_hidden[h] *
                   (int32_t)model->dense2_weight[row + h];
        }

        scores[output] = shift_round(sum, model->dense2_shift);
    }
}

void speech_recognition_set_model(const speech_model_t *model)
{
    if ((model == NULL) ||
        (model->dense1_weight == NULL) ||
        (model->dense1_bias == NULL) ||
        (model->dense2_weight == NULL) ||
        (model->dense2_bias == NULL)) {
        active_model = &dummy_model;
        return;
    }

    active_model = model;
}

uint32_t speech_record(int16_t *samples, uint32_t count)
{
    uint32_t read_count = 0u;

    if ((samples == NULL) || (count == 0u)) {
        return 0u;
    }

    /* Flush I2S RX FIFO, following mic_api.c convention. */
    PSC_I2S_ST = 0x01u;

    while (read_count < count) {
        uint32_t raw;

        if (mic_read_sample24(&raw) != 0) {
            break;
        }

        samples[read_count++] = sample24_to_s16(raw);
    }

    return read_count;
}

int speech_recognize_pcm(
    const int16_t *samples,
    uint32_t count,
    speech_result_t *result)
{
    uint32_t voice_start;
    uint32_t voice_end;

    if ((samples == NULL) || (result == NULL) || (count == 0u)) {
        return -1;
    }

    if (detect_voice_range(
            samples,
            count,
            &voice_start,
            &voice_end) != 0) {
        return -2;
    }

    if (speech_extract_features(
            samples,
            count,
            voice_start,
            voice_end,
            speech_features) != 0) {
        return -3;
    }

    run_dense_network(speech_features, result->score);

    uint32_t best = 0u;
    for (uint32_t i = 1u; i < SPEECH_CLASS_COUNT; ++i) {
        if (result->score[i] > result->score[best]) {
            best = i;
        }
    }

    result->class_id = (speech_class_t)best;
    result->voice_start = voice_start;
    result->voice_end = voice_end;
    return 0;
}

const char *speech_class_name(speech_class_t class_id)
{
    switch (class_id) {
    case SPEECH_CLASS_UP:
        return "UP";
    case SPEECH_CLASS_DOWN:
        return "DOWN";
    case SPEECH_CLASS_UNKNOWN:
        return "UNKNOWN";
    default:
        return "ERROR";
    }
}

int32_t s_call_speech_recognition_api(void)
{
    speech_result_t result;

    s_printf("SPEECH RECORD START samples=%d\n",
             (int)SPEECH_RECORD_SAMPLES);

    const uint32_t count =
        speech_record(speech_pcm, SPEECH_RECORD_SAMPLES);

    s_printf("SPEECH RECORD END samples=%d\n", (int)count);

    if (count != SPEECH_RECORD_SAMPLES) {
        s_printf("SPEECH MIC ERROR count=%d\n", (int)count);
        return (int32_t)SPEECH_CLASS_ERROR;
    }

    const int status = speech_recognize_pcm(speech_pcm, count, &result);

    if (status != 0) {
        s_printf("SPEECH RECOGNITION ERROR=%d\n", status);
        return (int32_t)SPEECH_CLASS_ERROR;
    }

    s_printf("VOICE RANGE start=%d end=%d\n",
             (int)result.voice_start,
             (int)result.voice_end);
    s_printf("SCORE UP=%d DOWN=%d UNKNOWN=%d\n",
             (int)result.score[SPEECH_CLASS_UP],
             (int)result.score[SPEECH_CLASS_DOWN],
             (int)result.score[SPEECH_CLASS_UNKNOWN]);
    s_printf("SPEECH RESULT=%s\n", speech_class_name(result.class_id));

    return (int32_t)result.class_id;
}