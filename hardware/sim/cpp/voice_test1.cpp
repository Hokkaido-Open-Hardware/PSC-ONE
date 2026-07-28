// voice_test1.cpp
//
// 音声認識の統合テスト:
//
//   模擬FFTスペクトル
//       ↓
//   4フレーム × 16帯域
//       ↓
//   64個の特徴量
//       ↓
//   0～127へ正規化
//       ↓
//   全結合層 64 → 16
//       ↓
//   ReLU
//       ↓
//   全結合層 16 → 3
//       ↓
//   UP / DOWN / UNKNOWN 判定
//
// 外部関数・標準ライブラリ・64bit演算は使用しない。
//
// 戻り値:
//   PASS                         : 0x00001214
//   FFT模擬データエラー          : 0x0000E201 + index
//   生特徴量エラー               : 0x0000E301 + index
//   最大値エラー                 : 0x0000E401
//   正規化特徴量エラー           : 0x0000E501 + index
//   第1層計算結果エラー          : 0x0000E601 + neuron
//   ReLUエラー                   : 0x0000E701 + neuron
//   出力層エラー                 : 0x0000E801 + output
//   判定結果エラー               : 0x0000E901 + class

#include <stdint.h>

#define PIO32 \
    (*reinterpret_cast<volatile uint32_t*>(0x10001000u))

namespace {

constexpr int FFT_SIZE        = 1024;
constexpr int FFT_BINS        = FFT_SIZE / 2;
constexpr int TIME_FRAMES     = 4;
constexpr int BANDS_PER_FRAME = 16;
constexpr int BINS_PER_BAND   = FFT_BINS / BANDS_PER_FRAME;

constexpr int INPUT_SIZE  = TIME_FRAMES * BANDS_PER_FRAME;
constexpr int HIDDEN_SIZE = 16;
constexpr int OUTPUT_SIZE = 3;

constexpr int CLASS_UP = 0;

constexpr uint32_t TEST_PASS = 0x00001214U;

constexpr uint32_t ERROR_FFT_DATA  = 0x0000E201U;
constexpr uint32_t ERROR_RAW       = 0x0000E301U;
constexpr uint32_t ERROR_MAX       = 0x0000E401U;
constexpr uint32_t ERROR_NORMALIZE = 0x0000E501U;
constexpr uint32_t ERROR_HIDDEN    = 0x0000E601U;
constexpr uint32_t ERROR_RELU      = 0x0000E701U;
constexpr uint32_t ERROR_OUTPUT    = 0x0000E801U;
constexpr uint32_t ERROR_CLASSIFY  = 0x0000E901U;

/*
 * 正規化後に得たい64個の特徴量。
 *
 * 16帯域 × 4時間フレーム。
 *
 * 最後の特徴量を127にしている。
 * これにより最大値正規化後も、すべての値が
 * この配列と完全に一致する。
 */
constexpr uint8_t expected_features[INPUT_SIZE] = {
    // frame 0
     4,  5,  6,  7,
     8,  9, 10, 11,
    12, 13, 14, 15,
    16, 17, 18, 19,

    // frame 1
     8, 10, 12, 14,
    16, 18, 20, 22,
    24, 26, 28, 30,
    32, 34, 36, 38,

    // frame 2
    12, 15, 18, 21,
    24, 27, 30, 33,
    36, 39, 42, 45,
    48, 51, 54, 57,

    // frame 3
    16, 20, 24, 28,
    32, 36, 40, 44,
    48, 52, 56, 60,
    64, 68, 72, 127
};

/*
 * 模擬FFT出力。
 *
 * 実際の音声処理では、fft_q15()などの結果が入る。
 */
int16_t fft_real[TIME_FRAMES][FFT_BINS];
int16_t fft_imag[TIME_FRAMES][FFT_BINS];

/*
 * 特徴量。
 */
uint32_t raw_features[INPUT_SIZE];
uint8_t normalized_features[INPUT_SIZE];

/*
 * NN中間値。
 */
int32_t hidden_accumulator[HIDDEN_SIZE];
int32_t hidden_output[HIDDEN_SIZE];
int32_t output_accumulator[OUTPUT_SIZE];

/*
 * 第1層のバイアス。
 */
constexpr int32_t hidden_bias[HIDDEN_SIZE] = {
    0, 0, 0, 0,
    0, 0, 0, 0,
    0, 0, 0, 0,
    0, 0, 0, 0
};

/*
 * 出力層のバイアス。
 *
 * UNKNOWNには100を加える。
 */
constexpr int32_t output_bias[OUTPUT_SIZE] = {
    0,
    0,
    100
};

/*
 * 第1層の期待値。
 *
 * hidden[0]  = feature[0]  ～ feature[3]
 * hidden[1]  = feature[4]  ～ feature[7]
 * ...
 * hidden[15] = feature[60] ～ feature[63]
 */
constexpr int32_t expected_hidden[HIDDEN_SIZE] = {
     22,  38,  54,  70,
     44,  76, 108, 140,
     66, 114, 162, 210,
     88, 152, 216, 331
};

/*
 * 出力層の期待値。
 *
 * UP:
 *   hidden[8]～hidden[15]
 *
 *   66 + 114 + 162 + 210
 *   + 88 + 152 + 216 + 331
 *   = 1339
 *
 * DOWN:
 *   hidden[0]～hidden[7]
 *
 *   22 + 38 + 54 + 70
 *   + 44 + 76 + 108 + 140
 *   = 552
 *
 * UNKNOWN:
 *   biasのみ
 *   = 100
 */
constexpr int32_t expected_output[OUTPUT_SIZE] = {
    1339,
    552,
    100
};

int32_t abs_s16(int16_t value)
{
    const int32_t extended =
        static_cast<int32_t>(value);

    if (extended < 0) {
        return -extended;
    }

    return extended;
}

/*
 * 模擬FFT出力を作る。
 *
 * 1つの帯域に含まれる全FFTビンへ、
 * expected_features[]の値を設定する。
 *
 * したがって帯域合計は、
 *
 *   expected_features[index] × BINS_PER_BAND
 *
 * になる。
 */
void make_mock_fft()
{
    for (int frame = 0; frame < TIME_FRAMES; ++frame) {
        for (int band = 0; band < BANDS_PER_FRAME; ++band) {
            const int feature_index =
                (frame * BANDS_PER_FRAME) + band;

            const int16_t magnitude =
                static_cast<int16_t>(
                    expected_features[feature_index]
                );

            const int start_bin =
                band * BINS_PER_BAND;

            const int end_bin =
                start_bin + BINS_PER_BAND;

            for (int bin = start_bin; bin < end_bin; ++bin) {
                fft_real[frame][bin] = magnitude;
                fft_imag[frame][bin] = 0;
            }
        }
    }
}

/*
 * 模擬FFTデータを検査する。
 */
uint32_t check_mock_fft()
{
    for (int frame = 0; frame < TIME_FRAMES; ++frame) {
        for (int band = 0; band < BANDS_PER_FRAME; ++band) {
            const int feature_index =
                (frame * BANDS_PER_FRAME) + band;

            const int first_bin =
                band * BINS_PER_BAND;

            const int16_t expected =
                static_cast<int16_t>(
                    expected_features[feature_index]
                );

            if (fft_real[frame][first_bin] != expected) {
                return ERROR_FFT_DATA
                    + static_cast<uint32_t>(feature_index);
            }

            if (fft_imag[frame][first_bin] != 0) {
                return ERROR_FFT_DATA
                    + static_cast<uint32_t>(feature_index);
            }
        }
    }

    return 0U;
}

/*
 * FFT出力から64特徴量を生成する。
 *
 * magnitudeは簡易的に、
 *
 *   abs(real) + abs(imag)
 *
 * とする。
 */
void extract_features()
{
    for (int frame = 0; frame < TIME_FRAMES; ++frame) {
        for (int band = 0; band < BANDS_PER_FRAME; ++band) {
            const int feature_index =
                (frame * BANDS_PER_FRAME) + band;

            const int start_bin =
                band * BINS_PER_BAND;

            const int end_bin =
                start_bin + BINS_PER_BAND;

            uint32_t accumulator = 0U;

            for (int bin = start_bin; bin < end_bin; ++bin) {
                const int32_t real_abs =
                    abs_s16(fft_real[frame][bin]);

                const int32_t imag_abs =
                    abs_s16(fft_imag[frame][bin]);

                accumulator +=
                    static_cast<uint32_t>(
                        real_abs + imag_abs
                    );
            }

            raw_features[feature_index] = accumulator;
        }
    }
}

/*
 * 生特徴量を検査する。
 */
uint32_t check_raw_features()
{
    for (int index = 0; index < INPUT_SIZE; ++index) {
        const uint32_t expected =
            static_cast<uint32_t>(
                expected_features[index]
            ) * static_cast<uint32_t>(BINS_PER_BAND);

        if (raw_features[index] != expected) {
            return ERROR_RAW
                + static_cast<uint32_t>(index);
        }
    }

    return 0U;
}

/*
 * 生特徴量の最大値を探す。
 */
uint32_t find_max_feature()
{
    uint32_t maximum = 0U;

    for (int index = 0; index < INPUT_SIZE; ++index) {
        if (raw_features[index] > maximum) {
            maximum = raw_features[index];
        }
    }

    return maximum;
}

/*
 * 特徴量を0～127へ正規化する。
 */
void normalize_features(uint32_t maximum)
{
    if (maximum == 0U) {
        for (int index = 0; index < INPUT_SIZE; ++index) {
            normalized_features[index] = 0U;
        }

        return;
    }

    for (int index = 0; index < INPUT_SIZE; ++index) {
        const uint32_t scaled =
            raw_features[index] * 127U;

        normalized_features[index] =
            static_cast<uint8_t>(
                scaled / maximum
            );
    }
}

/*
 * 正規化特徴量を検査する。
 */
uint32_t check_normalized_features()
{
    for (int index = 0; index < INPUT_SIZE; ++index) {
        if (normalized_features[index] !=
            expected_features[index]) {
            return ERROR_NORMALIZE
                + static_cast<uint32_t>(index);
        }
    }

    return 0U;
}

/*
 * 第1層の重みを返す。
 *
 * hiddenニューロンごとに、4個の入力だけ重み1とする。
 *
 * hidden[0]:
 *   input[0]～input[3]
 *
 * hidden[1]:
 *   input[4]～input[7]
 *
 * ...
 *
 * hidden[15]:
 *   input[60]～input[63]
 */
int32_t hidden_weight(int neuron, int input)
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

/*
 * 第1全結合層。
 *
 * 64入力 × 16ニューロン。
 */
void dense_hidden()
{
    for (int neuron = 0; neuron < HIDDEN_SIZE; ++neuron) {
        int32_t accumulator =
            hidden_bias[neuron];

        for (int input = 0; input < INPUT_SIZE; ++input) {
            const int32_t input_value =
                static_cast<int32_t>(
                    normalized_features[input]
                );

            const int32_t weight =
                hidden_weight(neuron, input);

            accumulator += input_value * weight;
        }

        hidden_accumulator[neuron] = accumulator;
    }
}

/*
 * 第1層結果を検査する。
 */
uint32_t check_hidden_accumulator()
{
    for (int neuron = 0; neuron < HIDDEN_SIZE; ++neuron) {
        if (hidden_accumulator[neuron] !=
            expected_hidden[neuron]) {
            return ERROR_HIDDEN
                + static_cast<uint32_t>(neuron);
        }
    }

    return 0U;
}

/*
 * ReLU。
 */
void relu_hidden()
{
    for (int neuron = 0; neuron < HIDDEN_SIZE; ++neuron) {
        const int32_t value =
            hidden_accumulator[neuron];

        hidden_output[neuron] =
            (value > 0) ? value : 0;
    }
}

/*
 * ReLU結果を検査する。
 */
uint32_t check_relu()
{
    for (int neuron = 0; neuron < HIDDEN_SIZE; ++neuron) {
        if (hidden_output[neuron] !=
            expected_hidden[neuron]) {
            return ERROR_RELU
                + static_cast<uint32_t>(neuron);
        }
    }

    return 0U;
}

/*
 * 出力層の重み。
 *
 * output 0 = UP
 *   hidden[8]～hidden[15]を加算
 *
 * output 1 = DOWN
 *   hidden[0]～hidden[7]を加算
 *
 * output 2 = UNKNOWN
 *   重みはすべて0
 */
int32_t output_weight(int output, int neuron)
{
    if (output == 0) {
        if (neuron >= 8) {
            return 1;
        }

        return 0;
    }

    if (output == 1) {
        if (neuron < 8) {
            return 1;
        }

        return 0;
    }

    return 0;
}

/*
 * 出力層。
 *
 * 16入力 × 3出力。
 */
void dense_output()
{
    for (int output = 0; output < OUTPUT_SIZE; ++output) {
        int32_t accumulator =
            output_bias[output];

        for (int neuron = 0; neuron < HIDDEN_SIZE; ++neuron) {
            const int32_t weight =
                output_weight(output, neuron);

            accumulator +=
                hidden_output[neuron] * weight;
        }

        output_accumulator[output] = accumulator;
    }
}

/*
 * 出力層を検査する。
 */
uint32_t check_output()
{
    for (int output = 0; output < OUTPUT_SIZE; ++output) {
        if (output_accumulator[output] !=
            expected_output[output]) {
            return ERROR_OUTPUT
                + static_cast<uint32_t>(output);
        }
    }

    return 0U;
}

/*
 * 最大スコアのクラスを選択する。
 */
int classify()
{
    int maximum_index = 0;

    int32_t maximum_value =
        output_accumulator[0];

    for (int output = 1; output < OUTPUT_SIZE; ++output) {
        if (output_accumulator[output] > maximum_value) {
            maximum_value =
                output_accumulator[output];

            maximum_index = output;
        }
    }

    return maximum_index;
}

} // namespace

extern "C" uint32_t run()
{
    /*
     * 模擬FFTデータ生成。
     */
    PIO32 = 0xB001U;

    make_mock_fft();

    PIO32 = 0xB002U;

    const uint32_t fft_check =
        check_mock_fft();

    PIO32 = 0xB003U;

    if (fft_check != 0U) {
        PIO32 = 0xE201U;
        return fft_check;
    }

    /*
     * 特徴量抽出。
     */
    PIO32 = 0xB101U;

    extract_features();

    PIO32 = 0xB102U;

    const uint32_t raw_check =
        check_raw_features();

    PIO32 = 0xB103U;

    if (raw_check != 0U) {
        PIO32 = 0xE301U;
        return raw_check;
    }

    /*
     * 最大値検索。
     */
    PIO32 = 0xB201U;

    const uint32_t maximum =
        find_max_feature();

    PIO32 = 0xB202U;

    constexpr uint32_t expected_maximum =
        127U * static_cast<uint32_t>(BINS_PER_BAND);

    if (maximum != expected_maximum) {
        PIO32 = 0xE401U;
        return ERROR_MAX;
    }

    /*
     * 特徴量正規化。
     */
    PIO32 = 0xB301U;

    normalize_features(maximum);

    PIO32 = 0xB302U;

    const uint32_t normalize_check =
        check_normalized_features();

    PIO32 = 0xB303U;

    if (normalize_check != 0U) {
        PIO32 = 0xE501U;
        return normalize_check;
    }

    /*
     * 第1全結合層。
     */
    PIO32 = 0xB401U;

    dense_hidden();

    PIO32 = 0xB402U;

    const uint32_t hidden_check =
        check_hidden_accumulator();

    PIO32 = 0xB403U;

    if (hidden_check != 0U) {
        PIO32 = 0xE601U;
        return hidden_check;
    }

    /*
     * ReLU。
     */
    PIO32 = 0xB501U;

    relu_hidden();

    PIO32 = 0xB502U;

    const uint32_t relu_check =
        check_relu();

    PIO32 = 0xB503U;

    if (relu_check != 0U) {
        PIO32 = 0xE701U;
        return relu_check;
    }

    /*
     * 出力層。
     */
    PIO32 = 0xB601U;

    dense_output();

    PIO32 = 0xB602U;

    const uint32_t output_check =
        check_output();

    PIO32 = 0xB603U;

    if (output_check != 0U) {
        PIO32 = 0xE801U;
        return output_check;
    }

    /*
     * クラス判定。
     */
    PIO32 = 0xB701U;

    const int result =
        classify();

    PIO32 = 0xB702U;

    if (result != CLASS_UP) {
        PIO32 = 0xE901U;

        return ERROR_CLASSIFY
            + static_cast<uint32_t>(result);
    }

    PIO32 = 0xB703U;

    /*
     * cocotbへ終了通知。
     *
     * TEST_PASSをPIOへ書いた後にreturnしても、
     * sp_start.Sが戻り値をPIOのword0へ格納する。
     */
    PIO32 = 0xEE01U;
    PIO32 = TEST_PASS;

    return TEST_PASS;
}