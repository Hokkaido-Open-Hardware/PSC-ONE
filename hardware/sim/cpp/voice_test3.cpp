// voice_test3.cpp
//
// 48000 PCM
//   -> silence detection
//   -> voice range extraction
//   -> four-way segmentation
//   -> 1024-point resampling
//   -> fft_q15()
//   -> 16 bands x 4 frames
//   -> 64 features
//   -> normalize
//   -> Dense 64x16
//   -> ReLU
//   -> Dense 16x3
//   -> classify UP
//
// PASS: 0x00001216

#include <stdint.h>

#define PIO32 \
    (*reinterpret_cast<volatile uint32_t*>(0x10001000u))

namespace {

constexpr int SAMPLE_RATE       = 16000;
constexpr int RECORD_SECONDS    = 3;
constexpr int RECORD_SAMPLES    = SAMPLE_RATE * RECORD_SECONDS;

constexpr int FFT_SIZE          = 1024;
constexpr int FFT_BINS          = FFT_SIZE / 2;
constexpr int FFT_STAGE_COUNT   = 10;

constexpr int FRAME_COUNT       = 4;
constexpr int BAND_COUNT        = 16;
constexpr int BINS_PER_BAND     = FFT_BINS / BAND_COUNT;
constexpr int FEATURE_SIZE      = FRAME_COUNT * BAND_COUNT;

constexpr int HIDDEN_SIZE       = 16;
constexpr int OUTPUT_SIZE       = 3;

constexpr int CLASS_UP          = 0;
constexpr int CLASS_DOWN        = 1;
constexpr int CLASS_UNKNOWN     = 2;

constexpr int DETECT_BLOCK_SIZE = 256;
constexpr int MIN_ACTIVE_BLOCKS = 2;

/*
 * 人工音声の発話範囲。
 *
 * start  = 12288
 * length = 16384
 * end    = 28672
 *
 * 4分割すると1区間4096サンプルになる。
 */
constexpr int TEST_VOICE_START  = 12288;
constexpr int TEST_VOICE_LENGTH = 16384;
constexpr int TEST_VOICE_END    =
    TEST_VOICE_START + TEST_VOICE_LENGTH;

constexpr uint32_t VOICE_THRESHOLD = 300U;

constexpr uint32_t TEST_PASS = 0x00001216U;

constexpr uint32_t ERROR_PCM             = 0x0000E301U;
constexpr uint32_t ERROR_VOICE_NOT_FOUND = 0x0000E302U;
constexpr uint32_t ERROR_VOICE_RANGE     = 0x0000E303U;
constexpr uint32_t ERROR_SEGMENT         = 0x0000E304U;
constexpr uint32_t ERROR_FFT             = 0x0000E305U;
constexpr uint32_t ERROR_ENERGY          = 0x0000E306U;
constexpr uint32_t ERROR_FEATURE         = 0x0000E307U;
constexpr uint32_t ERROR_NORMALIZE       = 0x0000E308U;
constexpr uint32_t ERROR_HIDDEN          = 0x0000E309U;
constexpr uint32_t ERROR_OUTPUT          = 0x0000E30AU;
constexpr uint32_t ERROR_CLASSIFY        = 0x0000E30BU;

/*
 * 32サンプル周期のQ15正弦波。
 *
 * 人工PCMでは各値を4回ずつ繰り返す。
 * したがって元PCMの周期は128サンプル。
 *
 * 4096 -> 1024への変換時に4サンプルおきに取得すると、
 * FFT入力では32サンプル周期になる。
 *
 * FFT bin = 1024 / 32 = 32
 */
constexpr int16_t sine_table[32] = {
         0,   6393,  12539,  18204,
     23170,  27245,  30273,  32137,
     32767,  32137,  30273,  27245,
     23170,  18204,  12539,   6393,
         0,  -6393, -12539, -18204,
    -23170, -27245, -30273, -32137,
    -32767, -32137, -30273, -27245,
    -23170, -18204, -12539,  -6393
};

/*
 * 後半ほど振幅を大きくし、
 * 最終的な判定をUPにする。
 */
constexpr int16_t segment_amplitude[FRAME_COUNT] = {
     4096,
     8192,
    16384,
    24576
};

constexpr int32_t output_bias[OUTPUT_SIZE] = {
    0,
    0,
    100
};

struct VoiceRange {
    int start;
    int end;
    bool found;
};

/*
 * FFT用バッファは1フレーム分だけ保持して使い回す。
 */
int16_t fft_real[FFT_SIZE];
int16_t fft_imag[FFT_SIZE];

uint32_t raw_features[FEATURE_SIZE];
uint8_t normalized_features[FEATURE_SIZE];

uint32_t frame_energy[FRAME_COUNT];

int32_t hidden_accumulator[HIDDEN_SIZE];
int32_t hidden_output[HIDDEN_SIZE];
int32_t output_accumulator[OUTPUT_SIZE];

/*
 * Q15複素乗算。
 */
void complex_multiply_q15(
    int16_t ar,
    int16_t ai,
    int16_t br,
    int16_t bi,
    int16_t& result_real,
    int16_t& result_imag
)
{
    const int32_t real_value =
        static_cast<int32_t>(ar) *
        static_cast<int32_t>(br)
        -
        static_cast<int32_t>(ai) *
        static_cast<int32_t>(bi);

    const int32_t imag_value =
        static_cast<int32_t>(ar) *
        static_cast<int32_t>(bi)
        +
        static_cast<int32_t>(ai) *
        static_cast<int32_t>(br);

    result_real =
        static_cast<int16_t>(real_value >> 15);

    result_imag =
        static_cast<int16_t>(imag_value >> 15);
}

/*
 * 10bitビット反転。
 */
uint32_t reverse_bits_10(uint32_t value)
{
    uint32_t reversed = 0U;

    for (int bit = 0; bit < FFT_STAGE_COUNT; ++bit) {
        reversed <<= 1U;
        reversed |= value & 1U;
        value >>= 1U;
    }

    return reversed;
}

/*
 * 1024点Q15 FFT。
 */
void fft_q15(
    int16_t real[FFT_SIZE],
    int16_t imag[FFT_SIZE]
)
{
    /*
     * ビット反転並べ替え。
     */
    for (uint32_t index = 0U;
         index < static_cast<uint32_t>(FFT_SIZE);
         ++index) {

        const uint32_t reversed =
            reverse_bits_10(index);

        if (reversed > index) {
            const int16_t real_temp =
                real[index];

            const int16_t imag_temp =
                imag[index];

            real[index] =
                real[reversed];

            imag[index] =
                imag[reversed];

            real[reversed] =
                real_temp;

            imag[reversed] =
                imag_temp;
        }
    }

    /*
     * 各FFT段の回転係数。
     *
     * cos(2π / stage_size)
     * -sin(2π / stage_size)
     */
    constexpr int16_t stage_cos[FFT_STAGE_COUNT] = {
        -32768,
             0,
         23170,
         30273,
         32138,
         32610,
         32729,
         32758,
         32766,
         32767
    };

    constexpr int16_t stage_minus_sin[FFT_STAGE_COUNT] = {
             0,
        -32768,
        -23170,
        -12540,
         -6393,
         -3212,
         -1608,
          -804,
          -402,
          -201
    };

    int stage_size = 2;

    for (int stage = 0;
         stage < FFT_STAGE_COUNT;
         ++stage) {

        const int half_size =
            stage_size / 2;

        const int16_t step_real =
            stage_cos[stage];

        const int16_t step_imag =
            stage_minus_sin[stage];

        for (int group = 0;
             group < FFT_SIZE;
             group += stage_size) {

            int16_t twiddle_real = 32767;
            int16_t twiddle_imag = 0;

            for (int pair = 0;
                 pair < half_size;
                 ++pair) {

                const int even_index =
                    group + pair;

                const int odd_index =
                    even_index + half_size;

                int16_t product_real = 0;
                int16_t product_imag = 0;

                complex_multiply_q15(
                    real[odd_index],
                    imag[odd_index],
                    twiddle_real,
                    twiddle_imag,
                    product_real,
                    product_imag
                );

                const int32_t even_real =
                    static_cast<int32_t>(
                        real[even_index]
                    );

                const int32_t even_imag =
                    static_cast<int32_t>(
                        imag[even_index]
                    );

                /*
                 * 各段で1bit縮小して、
                 * Q15オーバーフローを防ぐ。
                 */
                real[even_index] =
                    static_cast<int16_t>(
                        (
                            even_real +
                            static_cast<int32_t>(
                                product_real
                            )
                        ) >> 1
                    );

                imag[even_index] =
                    static_cast<int16_t>(
                        (
                            even_imag +
                            static_cast<int32_t>(
                                product_imag
                            )
                        ) >> 1
                    );

                real[odd_index] =
                    static_cast<int16_t>(
                        (
                            even_real -
                            static_cast<int32_t>(
                                product_real
                            )
                        ) >> 1
                    );

                imag[odd_index] =
                    static_cast<int16_t>(
                        (
                            even_imag -
                            static_cast<int32_t>(
                                product_imag
                            )
                        ) >> 1
                    );

                int16_t next_real = 0;
                int16_t next_imag = 0;

                complex_multiply_q15(
                    twiddle_real,
                    twiddle_imag,
                    step_real,
                    step_imag,
                    next_real,
                    next_imag
                );

                twiddle_real =
                    next_real;

                twiddle_imag =
                    next_imag;
            }
        }

        stage_size <<= 1;
    }
}

int32_t abs_s16(int16_t value)
{
    const int32_t extended =
        static_cast<int32_t>(value);

    if (extended < 0) {
        return -extended;
    }

    return extended;
}

int16_t multiply_q15(
    int16_t left,
    int16_t right
)
{
    const int32_t product =
        static_cast<int32_t>(left) *
        static_cast<int32_t>(right);

    return static_cast<int16_t>(
        product >> 15
    );
}

int16_t get_recorded_sample(int sample)
{
    if ((sample < TEST_VOICE_START) ||
        (sample >= TEST_VOICE_END)) {

        return 0;
    }

    constexpr int segment_length =
        TEST_VOICE_LENGTH / FRAME_COUNT;

    const int voice_offset =
        sample - TEST_VOICE_START;

    int segment_index =
        voice_offset / segment_length;

    if (segment_index >= FRAME_COUNT) {
        segment_index = FRAME_COUNT - 1;
    }

    const int segment_offset =
        voice_offset -
        segment_index * segment_length;

    const int sine_index =
        (segment_offset >> 2) & 31;

    return multiply_q15(
        sine_table[sine_index],
        segment_amplitude[segment_index]
    );
}

uint32_t check_recorded_pcm()
{
    for (int sample = 0;
         sample < TEST_VOICE_START;
         ++sample) {

        if (get_recorded_sample(sample) != 0) {
            return ERROR_PCM;
        }
    }

    for (int sample = TEST_VOICE_END;
         sample < RECORD_SAMPLES;
         ++sample) {

        if (get_recorded_sample(sample) != 0) {
            return ERROR_PCM + 1U;
        }
    }

    bool found_positive = false;
    bool found_negative = false;

    for (int sample = TEST_VOICE_START;
         sample < TEST_VOICE_END;
         ++sample) {

        const int16_t value =
            get_recorded_sample(sample);

        if (value > 0) {
            found_positive = true;
        }

        if (value < 0) {
            found_negative = true;
        }
    }

    if ((!found_positive) ||
        (!found_negative)) {

        return ERROR_PCM + 2U;
    }

    return 0U;
}

/*
 * ブロック内の平均絶対値。
 */
uint32_t block_average_abs(
    int start,
    int count
)
{
    uint32_t sum = 0U;

    for (int index = 0;
         index < count;
         ++index) {

        sum += static_cast<uint32_t>(
            abs_s16(
                get_recorded_sample(
                    start + index
                )
            )
        );
    }

    return sum /
        static_cast<uint32_t>(count);
}

/*
 * 256サンプル単位で発話範囲を検出する。
 *
 * 2ブロック以上連続してしきい値を超えた場所を
 * 発話開始として扱う。
 */
VoiceRange detect_voice_range(
    int sample_count
)
{
    VoiceRange result {
        0,
        0,
        false
    };

    const int block_count =
        sample_count / DETECT_BLOCK_SIZE;

    int first_active_block = -1;
    int last_active_block = -1;
    int active_run = 0;

    for (int block = 0;
         block < block_count;
         ++block) {

        const int block_start =
            block * DETECT_BLOCK_SIZE;

        const uint32_t average =
            block_average_abs(
                block_start,
                DETECT_BLOCK_SIZE
            );

        if (average >= VOICE_THRESHOLD) {
            ++active_run;

            if ((active_run >= MIN_ACTIVE_BLOCKS) &&
                (first_active_block < 0)) {

                first_active_block =
                    block - MIN_ACTIVE_BLOCKS + 1;
            }

            if (first_active_block >= 0) {
                last_active_block = block;
            }
        } else {
            active_run = 0;
        }
    }

    if ((first_active_block < 0) ||
        (last_active_block < first_active_block)) {

        return result;
    }

    result.start =
        first_active_block * DETECT_BLOCK_SIZE;

    result.end =
        (last_active_block + 1) *
        DETECT_BLOCK_SIZE;

    result.found = true;

    return result;
}

uint32_t check_voice_range(
    const VoiceRange& voice
)
{
    if (!voice.found) {
        return ERROR_VOICE_NOT_FOUND;
    }

    if (voice.start != TEST_VOICE_START) {
        return ERROR_VOICE_RANGE;
    }

    if (voice.end != TEST_VOICE_END) {
        return ERROR_VOICE_RANGE + 1U;
    }

    if ((voice.end - voice.start) <
        FRAME_COUNT) {

        return ERROR_VOICE_RANGE + 2U;
    }

    return 0U;
}

/*
 * 発話区間の指定された1/4を
 * 1024サンプルへ変換する。
 *
 * Q16.16位置アキュムレータを使用する。
 */
uint32_t make_fft_frame(
    const VoiceRange& voice,
    int frame_index
)
{
    if ((frame_index < 0) ||
        (frame_index >= FRAME_COUNT)) {

        return ERROR_SEGMENT;
    }

    const int voice_length =
        voice.end - voice.start;

    const int base_segment_length =
        voice_length / FRAME_COUNT;

    const int segment_start =
        voice.start +
        frame_index * base_segment_length;

    const int segment_end =
        (frame_index == (FRAME_COUNT - 1))
        ? voice.end
        : segment_start + base_segment_length;

    const int segment_length =
        segment_end - segment_start;

    if (segment_length <= 0) {
        return ERROR_SEGMENT +
            static_cast<uint32_t>(
                frame_index
            );
    }

    /*
     * Q16.16の入力位置増分。
     *
     * 外側のstatic_cast<uint32_t>は不要。
     */
    const uint32_t step_q16 =
        (
            static_cast<uint32_t>(
                segment_length
            ) << 16U
        ) /
        static_cast<uint32_t>(
            FFT_SIZE
        );

    uint32_t position_q16 = 0U;

    for (int index = 0;
         index < FFT_SIZE;
         ++index) {

        int source_offset =
            static_cast<int>(
                position_q16 >> 16U
            );

        if (source_offset >=
            segment_length) {

            source_offset =
                segment_length - 1;
        }

        const int source_index =
            segment_start +
            source_offset;

        fft_real[index] =
            get_recorded_sample(source_index);

        fft_imag[index] = 0;

        position_q16 += step_q16;
    }

    return 0U;
}

uint32_t check_fft_input()
{
    bool found_positive = false;
    bool found_negative = false;

    for (int index = 0;
         index < FFT_SIZE;
         ++index) {

        if (fft_real[index] > 0) {
            found_positive = true;
        }

        if (fft_real[index] < 0) {
            found_negative = true;
        }

        if (fft_imag[index] != 0) {
            return ERROR_SEGMENT + 0x10U;
        }
    }

    if ((!found_positive) ||
        (!found_negative)) {

        return ERROR_SEGMENT + 0x11U;
    }

    return 0U;
}

uint32_t check_fft_output()
{
    bool found_nonzero = false;

    for (int bin = 0;
         bin < FFT_BINS;
         ++bin) {

        if ((fft_real[bin] != 0) ||
            (fft_imag[bin] != 0)) {

            found_nonzero = true;
            break;
        }
    }

    if (!found_nonzero) {
        return ERROR_FFT;
    }

    return 0U;
}

/*
 * FFT結果を16帯域へ集約する。
 */
void extract_frame_features(
    int frame_index
)
{
    uint32_t total_energy = 0U;

    for (int band = 0;
         band < BAND_COUNT;
         ++band) {

        const int start_bin =
            band * BINS_PER_BAND;

        const int end_bin =
            start_bin + BINS_PER_BAND;

        uint32_t band_energy = 0U;

        for (int bin = start_bin;
             bin < end_bin;
             ++bin) {

            const uint32_t real_abs =
                static_cast<uint32_t>(
                    abs_s16(
                        fft_real[bin]
                    )
                );

            const uint32_t imag_abs =
                static_cast<uint32_t>(
                    abs_s16(
                        fft_imag[bin]
                    )
                );

            band_energy +=
                real_abs + imag_abs;
        }

        const int feature_index =
            frame_index * BAND_COUNT +
            band;

        raw_features[feature_index] =
            band_energy;

        total_energy += band_energy;
    }

    frame_energy[frame_index] =
        total_energy;
}

uint32_t check_frame_energy()
{
    if (frame_energy[0] == 0U) {
        return ERROR_ENERGY;
    }

    /*
     * 入力振幅が増えるので、
     * FFT後の総エネルギーも増えることを確認する。
     */
    for (int frame = 1;
         frame < FRAME_COUNT;
         ++frame) {

        if (frame_energy[frame] <=
            frame_energy[frame - 1]) {

            return ERROR_ENERGY +
                static_cast<uint32_t>(
                    frame
                );
        }
    }

    return 0U;
}

uint32_t find_max_feature()
{
    uint32_t maximum = 0U;

    for (int index = 0;
         index < FEATURE_SIZE;
         ++index) {

        if (raw_features[index] >
            maximum) {

            maximum =
                raw_features[index];
        }
    }

    return maximum;
}

void normalize_features(
    uint32_t maximum
)
{
    for (int index = 0;
         index < FEATURE_SIZE;
         ++index) {

        if (maximum == 0U) {
            normalized_features[index] =
                0U;
        } else {
            const uint32_t scaled =
                raw_features[index] *
                127U;

            normalized_features[index] =
                static_cast<uint8_t>(
                    scaled / maximum
                );
        }
    }
}

uint32_t check_normalized_features()
{
    bool found_nonzero = false;
    bool found_127 = false;

    for (int index = 0;
         index < FEATURE_SIZE;
         ++index) {

        const uint8_t value =
            normalized_features[index];

        if (value != 0U) {
            found_nonzero = true;
        }

        if (value == 127U) {
            found_127 = true;
        }
    }

    if ((!found_nonzero) ||
        (!found_127)) {

        return ERROR_NORMALIZE;
    }

    return 0U;
}

/*
 * hidden neuronごとに4特徴量を加算する。
 *
 * hidden[0..3]   = frame 0
 * hidden[4..7]   = frame 1
 * hidden[8..11]  = frame 2
 * hidden[12..15] = frame 3
 */
int32_t hidden_weight(
    int neuron,
    int input
)
{
    const int first_input =
        neuron * 4;

    const int last_input =
        first_input + 4;

    if ((input >= first_input) &&
        (input < last_input)) {

        return 1;
    }

    return 0;
}

void dense_hidden()
{
    for (int neuron = 0;
         neuron < HIDDEN_SIZE;
         ++neuron) {

        int32_t accumulator = 0;

        for (int input = 0;
             input < FEATURE_SIZE;
             ++input) {

            accumulator +=
                static_cast<int32_t>(
                    normalized_features[
                        input
                    ]
                ) *
                hidden_weight(
                    neuron,
                    input
                );
        }

        hidden_accumulator[neuron] =
            accumulator;
    }
}

uint32_t check_hidden()
{
    bool found_nonzero = false;

    for (int neuron = 0;
         neuron < HIDDEN_SIZE;
         ++neuron) {

        if (hidden_accumulator[neuron] !=
            0) {

            found_nonzero = true;
            break;
        }
    }

    if (!found_nonzero) {
        return ERROR_HIDDEN;
    }

    return 0U;
}

void relu_hidden()
{
    for (int neuron = 0;
         neuron < HIDDEN_SIZE;
         ++neuron) {

        const int32_t value =
            hidden_accumulator[neuron];

        hidden_output[neuron] =
            (value > 0)
            ? value
            : 0;
    }
}

int32_t output_weight(
    int output,
    int neuron
)
{
    /*
     * 後半2フレームをUPへ接続する。
     */
    if (output == CLASS_UP) {
        return (neuron >= 8)
            ? 1
            : 0;
    }

    /*
     * 前半2フレームをDOWNへ接続する。
     */
    if (output == CLASS_DOWN) {
        return (neuron < 8)
            ? 1
            : 0;
    }

    return 0;
}

void dense_output()
{
    for (int output = 0;
         output < OUTPUT_SIZE;
         ++output) {

        int32_t accumulator =
            output_bias[output];

        for (int neuron = 0;
             neuron < HIDDEN_SIZE;
             ++neuron) {

            accumulator +=
                hidden_output[neuron] *
                output_weight(
                    output,
                    neuron
                );
        }

        output_accumulator[output] =
            accumulator;
    }
}

uint32_t check_output()
{
    if (output_accumulator[CLASS_UP] <=
        output_accumulator[CLASS_DOWN]) {

        return ERROR_OUTPUT;
    }

    if (output_accumulator[CLASS_UP] <=
        output_accumulator[
            CLASS_UNKNOWN
        ]) {

        return ERROR_OUTPUT + 1U;
    }

    return 0U;
}

int classify()
{
    int maximum_index = 0;

    int32_t maximum_value =
        output_accumulator[0];

    for (int output = 1;
         output < OUTPUT_SIZE;
         ++output) {

        if (output_accumulator[output] >
            maximum_value) {

            maximum_value =
                output_accumulator[output];

            maximum_index =
                output;
        }
    }

    return maximum_index;
}

} // namespace

extern "C" uint32_t run()
{
    /*
     * 人工PCMは必要な位置のサンプルを
     * get_recorded_sample()で逐次生成する。
     */
    PIO32 = 0xD001U;
    PIO32 = 0xD002U;

    const uint32_t pcm_check =
        check_recorded_pcm();

    PIO32 = 0xD003U;

    if (pcm_check != 0U) {
        PIO32 = 0xE301U;
        return pcm_check;
    }

    /*
     * 無音区間検出。
     */
    PIO32 = 0xD101U;

    const VoiceRange voice =
        detect_voice_range(
            RECORD_SAMPLES
        );

    PIO32 = 0xD102U;

    const uint32_t voice_check =
        check_voice_range(voice);

    PIO32 = 0xD103U;

    if (voice_check != 0U) {
        PIO32 = 0xE302U;
        return voice_check;
    }

    /*
     * 4分割
     * -> 1024サンプル変換
     * -> FFT
     * -> 特徴量抽出
     */
    PIO32 = 0xD201U;

    for (int frame = 0;
         frame < FRAME_COUNT;
         ++frame) {

        PIO32 =
            0xD210U +
            static_cast<uint32_t>(
                frame
            );

        const uint32_t segment_result =
            make_fft_frame(
                voice,
                frame
            );

        if (segment_result != 0U) {
            PIO32 = 0xE304U;
            return segment_result;
        }

        const uint32_t fft_input_check =
            check_fft_input();

        if (fft_input_check != 0U) {
            PIO32 = 0xE305U;
            return fft_input_check;
        }

        fft_q15(
            fft_real,
            fft_imag
        );

        const uint32_t fft_output_check =
            check_fft_output();

        if (fft_output_check != 0U) {
            PIO32 = 0xE306U;

            return fft_output_check +
                static_cast<uint32_t>(
                    frame
                );
        }

        extract_frame_features(frame);

        PIO32 =
            0xD220U +
            static_cast<uint32_t>(
                frame
            );
    }

    PIO32 = 0xD202U;

    const uint32_t energy_check =
        check_frame_energy();

    PIO32 = 0xD203U;

    if (energy_check != 0U) {
        PIO32 = 0xE307U;
        return energy_check;
    }

    /*
     * 最大特徴量検索。
     */
    PIO32 = 0xD301U;

    const uint32_t maximum =
        find_max_feature();

    PIO32 = 0xD302U;

    if (maximum == 0U) {
        PIO32 = 0xE308U;
        return ERROR_FEATURE;
    }

    /*
     * 64特徴量を0～127へ正規化。
     */
    PIO32 = 0xD401U;

    normalize_features(maximum);

    PIO32 = 0xD402U;

    const uint32_t normalize_check =
        check_normalized_features();

    PIO32 = 0xD403U;

    if (normalize_check != 0U) {
        PIO32 = 0xE309U;
        return normalize_check;
    }

    /*
     * Dense 64 -> 16。
     */
    PIO32 = 0xD501U;

    dense_hidden();

    PIO32 = 0xD502U;

    const uint32_t hidden_check =
        check_hidden();

    PIO32 = 0xD503U;

    if (hidden_check != 0U) {
        PIO32 = 0xE30AU;
        return hidden_check;
    }

    /*
     * ReLU。
     */
    PIO32 = 0xD601U;

    relu_hidden();

    PIO32 = 0xD602U;

    /*
     * Dense 16 -> 3。
     */
    PIO32 = 0xD701U;

    dense_output();

    PIO32 = 0xD702U;

    const uint32_t output_check =
        check_output();

    PIO32 = 0xD703U;

    if (output_check != 0U) {
        PIO32 = 0xE30BU;
        return output_check;
    }

    /*
     * クラス判定。
     */
    PIO32 = 0xD801U;

    const int result =
        classify();

    PIO32 = 0xD802U;

    if (result != CLASS_UP) {
        PIO32 = 0xE30CU;

        return ERROR_CLASSIFY +
            static_cast<uint32_t>(
                result
            );
    }

    PIO32 = 0xD803U;

    /*
     * cocotb完了通知。
     */
    PIO32 = 0xEE01U;
    PIO32 = TEST_PASS;

    return TEST_PASS;
}