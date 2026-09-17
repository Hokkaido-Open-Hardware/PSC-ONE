// voice_test2.cpp
//
// 実FFTを使用した音声認識統合テスト:
//
//   Q15時間波形
//       ↓
//   fft_q15()
//       ↓
//   4フレーム × 512 FFTビン
//       ↓
//   4フレーム × 16帯域
//       ↓
//   64個の正規化特徴量
//       ↓
//   全結合層 64 → 16
//       ↓
//   ReLU
//       ↓
//   全結合層 16 → 3
//       ↓
//   UP / DOWN / UNKNOWN判定
//
// テスト波形:
//   同じ周波数の正弦波を4フレーム生成する。
//   フレームが進むほど振幅を大きくする。
//
//   frame 0: 小
//   frame 1: 中
//   frame 2: 大
//   frame 3: 最大
//
// 後半フレームの特徴量が大きくなるため、
// NNの判定結果はUPになる。
//
// 戻り値:
//   PASS                         : 0x00001215
//   PCM生成エラー                : 0x0000EA01 + frame
//   FFT出力エラー                : 0x0000EB01 + frame
//   フレームエネルギーエラー     : 0x0000EC01 + frame
//   特徴量最大値エラー           : 0x0000ED01
//   正規化エラー                 : 0x0000EE01
//   第1層エラー                  : 0x0000EF01
//   出力層エラー                 : 0x0000F001
//   判定結果エラー               : 0x0000F101 + class

#include <stdint.h>

#define PIO32 \
    (*reinterpret_cast<volatile uint32_t*>(0x10001000u))

/*
 * PSC-ONE側に既に存在するFFT関数。
 *
 * 実際の宣言が異なる場合は、ここおよび呼び出し部分を
 * 既存のfft_q15()に合わせる。
 */
namespace {

constexpr int FFT_N = 1024;

namespace {

constexpr int FFT_N = 1024;

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
 * ビット反転。
 */
uint32_t reverse_bits_10(uint32_t value)
{
    uint32_t reversed = 0U;

    for (int bit = 0; bit < 10; ++bit) {
        reversed <<= 1U;
        reversed |= value & 1U;
        value >>= 1U;
    }

    return reversed;
}

/*
 * 1024点FFT用Q15回転係数。
 *
 * 1段ごとに必要な角度を、簡易的な漸化式で更新する。
 *
 * このテストではbin 32の正弦波を入力するため、
 * 完全な汎用FFT精度よりも、周波数成分を得ることを優先する。
 */
void fft_q15(
    int16_t real[FFT_N],
    int16_t imag[FFT_N]
)
{
    /*
     * ビット反転並べ替え。
     */
    for (uint32_t index = 0U;
         index < static_cast<uint32_t>(FFT_N);
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
     * 各FFT段の回転係数初期値。
     *
     * cos(2π / stage_size),
     * -sin(2π / stage_size)
     *
     * をQ15で保持する。
     */
    constexpr int16_t stage_cos[10] = {
        -32768,     // 2
             0,     // 4
         23170,     // 8
         30273,     // 16
         32138,     // 32
         32610,     // 64
         32729,     // 128
         32758,     // 256
         32766,     // 512
         32767      // 1024
    };

    constexpr int16_t stage_minus_sin[10] = {
             0,     // 2
        -32768,     // 4
        -23170,     // 8
        -12540,     // 16
         -6393,     // 32
         -3212,     // 64
         -1608,     // 128
          -804,     // 256
          -402,     // 512
          -201      // 1024
    };

    int stage_size = 2;

    for (int stage = 0; stage < 10; ++stage) {
        const int half_size =
            stage_size / 2;

        const int16_t step_real =
            stage_cos[stage];

        const int16_t step_imag =
            stage_minus_sin[stage];

        for (int group = 0;
             group < FFT_N;
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
                 * 各段で1ビット縮小し、
                 * Q15オーバーフローを防止する。
                 */
                real[even_index] =
                    static_cast<int16_t>(
                        (even_real +
                         static_cast<int32_t>(product_real))
                        >> 1
                    );

                imag[even_index] =
                    static_cast<int16_t>(
                        (even_imag +
                         static_cast<int32_t>(product_imag))
                        >> 1
                    );

                real[odd_index] =
                    static_cast<int16_t>(
                        (even_real -
                         static_cast<int32_t>(product_real))
                        >> 1
                    );

                imag[odd_index] =
                    static_cast<int16_t>(
                        (even_imag -
                         static_cast<int32_t>(product_imag))
                        >> 1
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

} // namespace

constexpr int FFT_SIZE        = 1024;
constexpr int FFT_BINS        = FFT_SIZE / 2;
constexpr int TIME_FRAMES     = 4;
constexpr int BANDS_PER_FRAME = 16;
constexpr int BINS_PER_BAND   = FFT_BINS / BANDS_PER_FRAME;

constexpr int INPUT_SIZE  = TIME_FRAMES * BANDS_PER_FRAME;
constexpr int HIDDEN_SIZE = 16;
constexpr int OUTPUT_SIZE = 3;

constexpr int CLASS_UP      = 0;
constexpr int CLASS_DOWN    = 1;
constexpr int CLASS_UNKNOWN = 2;

constexpr uint32_t TEST_PASS = 0x00001215U;

constexpr uint32_t ERROR_PCM        = 0x0000EA01U;
constexpr uint32_t ERROR_FFT        = 0x0000EB01U;
constexpr uint32_t ERROR_ENERGY     = 0x0000EC01U;
constexpr uint32_t ERROR_MAX        = 0x0000ED01U;
constexpr uint32_t ERROR_NORMALIZE  = 0x0000EE01U;
constexpr uint32_t ERROR_HIDDEN     = 0x0000EF01U;
constexpr uint32_t ERROR_OUTPUT     = 0x0000F001U;
constexpr uint32_t ERROR_CLASSIFY   = 0x0000F101U;

/*
 * 32サンプル周期のQ15正弦波テーブル。
 *
 * FFT_SIZE=1024なので、
 *
 *   1024 / 32 = FFT bin 32
 *
 * の周波数成分になる。
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
 * 各時間フレームの振幅。
 *
 * Q15正弦波に乗算し、15ビット右シフトする。
 */
constexpr int16_t frame_amplitude[TIME_FRAMES] = {
     4096,
     8192,
    16384,
    24576
};

/*
 * FFT入力およびFFT出力。
 *
 * fft_q15()がインプレース変換する前提。
 */
int16_t fft_real[TIME_FRAMES][FFT_SIZE];
int16_t fft_imag[TIME_FRAMES][FFT_SIZE];

/*
 * 特徴量。
 */
uint32_t raw_features[INPUT_SIZE];
uint8_t normalized_features[INPUT_SIZE];

/*
 * フレームごとの総エネルギー。
 */
uint32_t frame_energy[TIME_FRAMES];

/*
 * NN中間値。
 */
int32_t hidden_accumulator[HIDDEN_SIZE];
int32_t hidden_output[HIDDEN_SIZE];
int32_t output_accumulator[OUTPUT_SIZE];

constexpr int32_t hidden_bias[HIDDEN_SIZE] = {
    0, 0, 0, 0,
    0, 0, 0, 0,
    0, 0, 0, 0,
    0, 0, 0, 0
};

constexpr int32_t output_bias[OUTPUT_SIZE] = {
    0,
    0,
    100
};

/*
 * int16_tの絶対値。
 *
 * -32768も安全に扱うため、先にint32_tへ拡張する。
 */
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
 * Q15の乗算。
 */
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

/*
 * FFTへ入力する時間波形を生成する。
 *
 * 全フレームで周波数は同じ。
 * フレームが進むほど振幅だけを大きくする。
 */
void make_pcm_frames()
{
    for (int frame = 0; frame < TIME_FRAMES; ++frame) {
        const int16_t amplitude =
            frame_amplitude[frame];

        for (int sample = 0; sample < FFT_SIZE; ++sample) {
            const int table_index =
                sample & 31;

            fft_real[frame][sample] =
                multiply_q15(
                    sine_table[table_index],
                    amplitude
                );

            fft_imag[frame][sample] = 0;
        }
    }
}

/*
 * PCM入力を簡易検査する。
 */
uint32_t check_pcm_frames()
{
    for (int frame = 0; frame < TIME_FRAMES; ++frame) {
        bool found_positive = false;
        bool found_negative = false;

        for (int sample = 0; sample < FFT_SIZE; ++sample) {
            const int16_t value =
                fft_real[frame][sample];

            if (value > 0) {
                found_positive = true;
            }

            if (value < 0) {
                found_negative = true;
            }

            if (fft_imag[frame][sample] != 0) {
                return ERROR_PCM
                    + static_cast<uint32_t>(frame);
            }
        }

        if ((!found_positive) || (!found_negative)) {
            return ERROR_PCM
                + static_cast<uint32_t>(frame);
        }
    }

    return 0U;
}

/*
 * 4フレームに対して実際のFFTを実行する。
 */
void execute_fft()
{
    for (int frame = 0; frame < TIME_FRAMES; ++frame) {
        fft_q15(
            fft_real[frame],
            fft_imag[frame]
        );
    }
}

/*
 * FFT出力が完全なゼロになっていないことを確認する。
 */
uint32_t check_fft_output()
{
    for (int frame = 0; frame < TIME_FRAMES; ++frame) {
        bool found_nonzero = false;

        for (int bin = 0; bin < FFT_BINS; ++bin) {
            if ((fft_real[frame][bin] != 0) ||
                (fft_imag[frame][bin] != 0)) {
                found_nonzero = true;
                break;
            }
        }

        if (!found_nonzero) {
            return ERROR_FFT
                + static_cast<uint32_t>(frame);
        }
    }

    return 0U;
}

/*
 * FFTスペクトルを16帯域へ集約する。
 *
 * 簡易振幅:
 *
 *   abs(real) + abs(imag)
 *
 * 平方根および64bit演算は使用しない。
 */
void extract_features()
{
    for (int frame = 0; frame < TIME_FRAMES; ++frame) {
        uint32_t total_energy = 0U;

        for (int band = 0; band < BANDS_PER_FRAME; ++band) {
            const int feature_index =
                (frame * BANDS_PER_FRAME) + band;

            const int start_bin =
                band * BINS_PER_BAND;

            const int end_bin =
                start_bin + BINS_PER_BAND;

            uint32_t band_energy = 0U;

            for (int bin = start_bin; bin < end_bin; ++bin) {
                const int32_t real_abs =
                    abs_s16(fft_real[frame][bin]);

                const int32_t imag_abs =
                    abs_s16(fft_imag[frame][bin]);

                band_energy +=
                    static_cast<uint32_t>(
                        real_abs + imag_abs
                    );
            }

            raw_features[feature_index] =
                band_energy;

            total_energy += band_energy;
        }

        frame_energy[frame] = total_energy;
    }
}

/*
 * 振幅が増えるにつれて、フレームエネルギーも
 * 増えていることを確認する。
 *
 * FFT実装の段階シフトや丸めがあっても、
 * 厳密な数値一致を要求しない。
 */
uint32_t check_frame_energy()
{
    if (frame_energy[0] == 0U) {
        return ERROR_ENERGY;
    }

    for (int frame = 1; frame < TIME_FRAMES; ++frame) {
        if (frame_energy[frame] <=
            frame_energy[frame - 1]) {
            return ERROR_ENERGY
                + static_cast<uint32_t>(frame);
        }
    }

    return 0U;
}

/*
 * 64特徴量中の最大値を取得する。
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
 * 0～127へ最大値正規化する。
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
        /*
         * raw_features[index] <= maximumなので、
         * 127倍しても今回のテスト範囲では
         * uint32_tを超えない。
         */
        const uint32_t scaled =
            raw_features[index] * 127U;

        normalized_features[index] =
            static_cast<uint8_t>(
                scaled / maximum
            );
    }
}

/*
 * 正規化結果の簡易検査。
 */
uint32_t check_normalized_features()
{
    bool found_nonzero = false;
    bool found_maximum = false;

    for (int index = 0; index < INPUT_SIZE; ++index) {
        const uint8_t value =
            normalized_features[index];

        if (value != 0U) {
            found_nonzero = true;
        }

        if (value == 127U) {
            found_maximum = true;
        }
    }

    if ((!found_nonzero) || (!found_maximum)) {
        return ERROR_NORMALIZE;
    }

    return 0U;
}

/*
 * 第1層の重み。
 *
 * hiddenニューロン1個につき、連続する4特徴量を加算する。
 *
 * hidden[0]  = feature[0..3]
 * hidden[1]  = feature[4..7]
 * ...
 * hidden[15] = feature[60..63]
 */
int32_t hidden_weight(int neuron, int input)
{
    const int first_input =
        neuron * 4;

    const int end_input =
        first_input + 4;

    if ((input >= first_input) &&
        (input < end_input)) {
        return 1;
    }

    return 0;
}

/*
 * 64 → 16全結合層。
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

            accumulator +=
                input_value * weight;
        }

        hidden_accumulator[neuron] =
            accumulator;
    }
}

/*
 * 第1層に非ゼロ結果が存在することを確認する。
 */
uint32_t check_hidden()
{
    bool found_nonzero = false;

    for (int neuron = 0; neuron < HIDDEN_SIZE; ++neuron) {
        if (hidden_accumulator[neuron] != 0) {
            found_nonzero = true;
            break;
        }
    }

    if (!found_nonzero) {
        return ERROR_HIDDEN;
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
 * 出力層の重み。
 *
 * UP:
 *   後半8ニューロンを加算する。
 *   主にframe 2およびframe 3。
 *
 * DOWN:
 *   前半8ニューロンを加算する。
 *   主にframe 0およびframe 1。
 *
 * UNKNOWN:
 *   重みはすべて0で、biasだけを使用する。
 */
int32_t output_weight(int output, int neuron)
{
    if (output == CLASS_UP) {
        if (neuron >= 8) {
            return 1;
        }

        return 0;
    }

    if (output == CLASS_DOWN) {
        if (neuron < 8) {
            return 1;
        }

        return 0;
    }

    return 0;
}

/*
 * 16 → 3出力層。
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

        output_accumulator[output] =
            accumulator;
    }
}

/*
 * 出力値の関係を確認する。
 *
 * 後半フレームの振幅が大きいため、
 *
 *   UP > DOWN
 *   UP > UNKNOWN
 *
 * になる必要がある。
 */
uint32_t check_output()
{
    if (output_accumulator[CLASS_UP] <=
        output_accumulator[CLASS_DOWN]) {
        return ERROR_OUTPUT;
    }

    if (output_accumulator[CLASS_UP] <=
        output_accumulator[CLASS_UNKNOWN]) {
        return ERROR_OUTPUT + 1U;
    }

    return 0U;
}

/*
 * 最大出力クラスを取得する。
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
     * 時間波形生成。
     */
    PIO32 = 0xC001U;

    make_pcm_frames();

    PIO32 = 0xC002U;

    const uint32_t pcm_check =
        check_pcm_frames();

    PIO32 = 0xC003U;

    if (pcm_check != 0U) {
        PIO32 = 0xEA01U;
        return pcm_check;
    }

    /*
     * 実FFT実行。
     */
    PIO32 = 0xC101U;

    execute_fft();

    PIO32 = 0xC102U;

    const uint32_t fft_check =
        check_fft_output();

    PIO32 = 0xC103U;

    if (fft_check != 0U) {
        PIO32 = 0xEB01U;
        return fft_check;
    }

    /*
     * 16帯域×4フレームの特徴量抽出。
     */
    PIO32 = 0xC201U;

    extract_features();

    PIO32 = 0xC202U;

    const uint32_t energy_check =
        check_frame_energy();

    PIO32 = 0xC203U;

    if (energy_check != 0U) {
        PIO32 = 0xEC01U;
        return energy_check;
    }

    /*
     * 最大値検索。
     */
    PIO32 = 0xC301U;

    const uint32_t maximum =
        find_max_feature();

    PIO32 = 0xC302U;

    if (maximum == 0U) {
        PIO32 = 0xED01U;
        return ERROR_MAX;
    }

    /*
     * 特徴量正規化。
     */
    PIO32 = 0xC401U;

    normalize_features(maximum);

    PIO32 = 0xC402U;

    const uint32_t normalize_check =
        check_normalized_features();

    PIO32 = 0xC403U;

    if (normalize_check != 0U) {
        PIO32 = 0xEE02U;
        return normalize_check;
    }

    /*
     * 64 → 16全結合層。
     */
    PIO32 = 0xC501U;

    dense_hidden();

    PIO32 = 0xC502U;

    const uint32_t hidden_check =
        check_hidden();

    PIO32 = 0xC503U;

    if (hidden_check != 0U) {
        PIO32 = 0xEF01U;
        return hidden_check;
    }

    /*
     * ReLU。
     */
    PIO32 = 0xC601U;

    relu_hidden();

    PIO32 = 0xC602U;

    /*
     * 16 → 3出力層。
     */
    PIO32 = 0xC701U;

    dense_output();

    PIO32 = 0xC702U;

    const uint32_t output_check =
        check_output();

    PIO32 = 0xC703U;

    if (output_check != 0U) {
        PIO32 = 0xF001U;
        return output_check;
    }

    /*
     * クラス判定。
     */
    PIO32 = 0xC801U;

    const int result =
        classify();

    PIO32 = 0xC802U;

    if (result != CLASS_UP) {
        PIO32 = 0xF101U;

        return ERROR_CLASSIFY
            + static_cast<uint32_t>(result);
    }

    PIO32 = 0xC803U;

    /*
     * cocotbへ完了通知。
     */
    PIO32 = 0xEE01U;
    PIO32 = TEST_PASS;

    return TEST_PASS;
}
