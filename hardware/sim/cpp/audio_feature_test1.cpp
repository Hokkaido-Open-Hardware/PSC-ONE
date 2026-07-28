// audio_feature_test1.cpp
//
// 単体テスト:
//   FFT後のスペクトルを模擬生成
//   ↓
//   abs(real) + abs(imag)
//   ↓
//   4フレーム × 16帯域
//   ↓
//   64特徴量
//   ↓
//   0～127へ正規化
//
// 正常終了値:
//   0x00001212
//
// 外部関数、標準ライブラリ、64bit除算は使用しない。

#include <stdint.h>

#define PIO32 \
    (*reinterpret_cast<volatile uint32_t*>(0x10001000u))

namespace {

constexpr int FFT_SIZE         = 1024;
constexpr int FFT_BINS         = FFT_SIZE / 2;
constexpr int TIME_FRAMES      = 4;
constexpr int BANDS_PER_FRAME  = 16;
constexpr int FEATURE_SIZE     = TIME_FRAMES * BANDS_PER_FRAME;
constexpr int BINS_PER_BAND    = FFT_BINS / BANDS_PER_FRAME;

constexpr uint32_t TEST_PASS = 0x00001212U;

constexpr uint32_t ERROR_RAW_FEATURE    = 0x0000E001U;
constexpr uint32_t ERROR_MAX_FEATURE    = 0x0000E002U;
constexpr uint32_t ERROR_NORMALIZE      = 0x0000E003U;
constexpr uint32_t ERROR_PEAK_POSITION  = 0x0000E004U;
constexpr uint32_t ERROR_FRAME_FEATURE  = 0x0000E005U;

int16_t fft_real[TIME_FRAMES][FFT_BINS];
int16_t fft_imag[TIME_FRAMES][FFT_BINS];

uint32_t raw_features[FEATURE_SIZE];
uint8_t normalized_features[FEATURE_SIZE];

int32_t abs_s16(int16_t value)
{
    const int32_t extended = static_cast<int32_t>(value);

    return (extended < 0) ? -extended : extended;
}

/*
 * FFT出力を模擬する。
 *
 * frame 0: band 2 が最大
 * frame 1: band 5 が最大
 * frame 2: band 9 が最大
 * frame 3: band 13が最大
 */
void generate_mock_fft_output()
{
    constexpr int peak_band[TIME_FRAMES] = {
        2, 5, 9, 13
    };

    for (int frame = 0; frame < TIME_FRAMES; ++frame) {
        for (int bin = 0; bin < FFT_BINS; ++bin) {
            fft_real[frame][bin] = 0;
            fft_imag[frame][bin] = 0;
        }

        /*
         * 全帯域に小さな背景成分を入れる。
         */
        for (int band = 0; band < BANDS_PER_FRAME; ++band) {
            const int start_bin = band * BINS_PER_BAND;

            for (int offset = 0; offset < BINS_PER_BAND; ++offset) {
                const int bin = start_bin + offset;

                const int32_t real_value =
                    static_cast<int32_t>(band + 1);

                const int32_t imag_value =
                    static_cast<int32_t>(frame + 1);

                fft_real[frame][bin] =
                    static_cast<int16_t>(real_value);

                fft_imag[frame][bin] =
                    static_cast<int16_t>(imag_value);
            }
        }

        /*
         * フレームごとに異なる帯域へ大きな成分を入れる。
         */
        const int selected_band = peak_band[frame];
        const int selected_bin =
            selected_band * BINS_PER_BAND + 3;

        fft_real[frame][selected_bin] =
            static_cast<int16_t>(12000);

        fft_imag[frame][selected_bin] =
            static_cast<int16_t>(-8000);
    }
}

void extract_features()
{
    for (int frame = 0; frame < TIME_FRAMES; ++frame) {
        for (int band = 0; band < BANDS_PER_FRAME; ++band) {
            const int start_bin = band * BINS_PER_BAND;
            const int end_bin = start_bin + BINS_PER_BAND;

            uint32_t sum = 0U;

            for (int bin = start_bin; bin < end_bin; ++bin) {
                const uint32_t real_abs =
                    static_cast<uint32_t>(
                        abs_s16(fft_real[frame][bin])
                    );

                const uint32_t imag_abs =
                    static_cast<uint32_t>(
                        abs_s16(fft_imag[frame][bin])
                    );

                sum += real_abs + imag_abs;
            }

            const int feature_index =
                frame * BANDS_PER_FRAME + band;

            raw_features[feature_index] = sum;
        }
    }
}

uint32_t find_max_feature()
{
    uint32_t max_value = 0U;

    for (int index = 0; index < FEATURE_SIZE; ++index) {
        if (raw_features[index] > max_value) {
            max_value = raw_features[index];
        }
    }

    return max_value;
}

/*
 * 0～127へ正規化する。
 *
 * 64bit演算を使わず、先に割り算と余りを求める。
 *
 * value * 127 / max
 *
 * =
 *
 * (value / max) * 127
 * + (value % max) * 127 / max
 *
 * value <= maxなので、最初の項は0または127。
 * remainder * 127は32bit内に収まる。
 */
void normalize_features(uint32_t max_value)
{
    for (int index = 0; index < FEATURE_SIZE; ++index) {
        const uint32_t value = raw_features[index];

        uint32_t normalized;

        if (value >= max_value) {
            normalized = 127U;
        } else {
            normalized = (value * 127U) / max_value;
        }

        if (normalized > 127U) {
            normalized = 127U;
        }

        normalized_features[index] =
            static_cast<uint8_t>(normalized);
    }
}

int find_peak_band(int frame)
{
    int peak_band = 0;
    uint8_t peak_value = 0U;

    for (int band = 0; band < BANDS_PER_FRAME; ++band) {
        const int index =
            frame * BANDS_PER_FRAME + band;

        if (normalized_features[index] > peak_value) {
            peak_value = normalized_features[index];
            peak_band = band;
        }
    }

    return peak_band;
}

uint32_t check_raw_features()
{
    for (int index = 0; index < FEATURE_SIZE; ++index) {
        if (raw_features[index] == 0U) {
            return ERROR_RAW_FEATURE;
        }
    }

    return 0U;
}

uint32_t check_normalized_features()
{
    int maximum_count = 0;

    for (int index = 0; index < FEATURE_SIZE; ++index) {
        const uint32_t value =
            static_cast<uint32_t>(
                normalized_features[index]
            );

        if (value > 127U) {
            return ERROR_NORMALIZE;
        }

        if (value == 127U) {
            ++maximum_count;
        }
    }

    if (maximum_count == 0) {
        return ERROR_NORMALIZE;
    }

    return 0U;
}

uint32_t check_peak_positions()
{
    constexpr int expected_peak_band[TIME_FRAMES] = {
        2, 5, 9, 13
    };

    for (int frame = 0; frame < TIME_FRAMES; ++frame) {
        const int actual_peak_band =
            find_peak_band(frame);

        if (actual_peak_band != expected_peak_band[frame]) {
            return ERROR_PEAK_POSITION
                + static_cast<uint32_t>(frame);
        }
    }

    return 0U;
}

uint32_t check_each_frame()
{
    for (int frame = 0; frame < TIME_FRAMES; ++frame) {
        int nonzero_count = 0;

        for (int band = 0; band < BANDS_PER_FRAME; ++band) {
            const int index =
                frame * BANDS_PER_FRAME + band;

            if (normalized_features[index] != 0U) {
                ++nonzero_count;
            }
        }

        if (nonzero_count == 0) {
            return ERROR_FRAME_FEATURE
                + static_cast<uint32_t>(frame);
        }
    }

    return 0U;
}

} // namespace

extern "C" uint32_t run()
{
    generate_mock_fft_output();

    PIO32 = 0xAC01;

    extract_features();

    PIO32 = 0xAC02;

    const uint32_t raw_check =
        check_raw_features();

    PIO32 = 0xAB01;

    if (raw_check != 0U) {
        return raw_check;
    }

    PIO32 = 0xAB02;

    const uint32_t max_value =
        find_max_feature();

    PIO32 = 0xAB03;

    if (max_value == 0U) {
        return ERROR_MAX_FEATURE;
    }

    PIO32 = 0xAB04;

    normalize_features(max_value);

    PIO32 = 0xAB05;

    const uint32_t normalized_check =
        check_normalized_features();

    PIO32 = 0xAB06;

    if (normalized_check != 0U) {
        return normalized_check;
    }

    PIO32 = 0xAB07;

    const uint32_t frame_check =
        check_each_frame();

    PIO32 = 0xAB08;

    if (frame_check != 0U) {
        return frame_check;
    }

    PIO32 = 0xAD01;

    const uint32_t peak_check =
        check_peak_positions();

    PIO32 = 0xAD02;

    if (peak_check != 0U) {
        return peak_check;
    }

    PIO32 = 0xAD03;

    PIO32 = 0xEE01;
    PIO32 = TEST_PASS;
    
    return TEST_PASS;
}