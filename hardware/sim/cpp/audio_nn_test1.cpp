// audio_nn_test1.cpp
//
// 単体テスト:
//   64個のINT8音声特徴量
//       ↓
//   全結合層 64 → 16
//       ↓
//   ReLU
//       ↓
//   全結合層 16 → 3
//       ↓
//   UP / DOWN / UNKNOWN 判定
//
// 外部関数・標準ライブラリは使用しない。
//
// 戻り値:
//   PASS                         : 0x00001213
//   第1層の計算結果エラー        : 0x0000E101
//   ReLUエラー                   : 0x0000E102
//   出力層エラー                 : 0x0000E103
//   判定結果エラー               : 0x0000E104

#include <stdint.h>

#define PIO32 \
    (*reinterpret_cast<volatile uint32_t*>(0x10001000u))

namespace {

constexpr int INPUT_SIZE  = 64;
constexpr int HIDDEN_SIZE = 16;
constexpr int OUTPUT_SIZE = 3;

constexpr int CLASS_UP      = 0;
constexpr int CLASS_DOWN    = 1;
constexpr int CLASS_UNKNOWN = 2;

constexpr uint32_t TEST_PASS = 0x00001213U;

constexpr uint32_t ERROR_HIDDEN   = 0x0000E101U;
constexpr uint32_t ERROR_RELU     = 0x0000E102U;
constexpr uint32_t ERROR_OUTPUT   = 0x0000E103U;
constexpr uint32_t ERROR_CLASSIFY = 0x0000E104U;

/*
 * テスト入力。
 *
 * 16帯域 × 4時間フレームを想定する。
 *
 * 前半から後半へ向かって値が増えるパターン。
 * このパターンを、この単体テストではUPとする。
 */
constexpr int8_t input_features[INPUT_SIZE] = {
    // frame 0
     4,  5,  6,  7,  8,  9, 10, 11,
    12, 13, 14, 15, 16, 17, 18, 19,

    // frame 1
     8, 10, 12, 14, 16, 18, 20, 22,
    24, 26, 28, 30, 32, 34, 36, 38,

    // frame 2
    12, 15, 18, 21, 24, 27, 30, 33,
    36, 39, 42, 45, 48, 51, 54, 57,

    // frame 3
    16, 20, 24, 28, 32, 36, 40, 44,
    48, 52, 56, 60, 64, 68, 72, 76
};

/*
 * 第1層の重み。
 *
 * テストを簡単にするため、各ニューロンは4個の入力だけを見る。
 *
 * hidden[0]  は input[0..3]
 * hidden[1]  は input[4..7]
 * ...
 * hidden[15] は input[60..63]
 *
 * 対象入力には重み1、それ以外には重み0を設定する。
 */
constexpr int8_t hidden_weights[HIDDEN_SIZE][INPUT_SIZE] = {
    {1,1,1,1},
    {0,0,0,0, 1,1,1,1},
    {0,0,0,0, 0,0,0,0, 1,1,1,1},
    {0,0,0,0, 0,0,0,0, 0,0,0,0, 1,1,1,1},

    {
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        1,1,1,1
    },

    {
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 1,1,1,1
    },

    {
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        1,1,1,1
    },

    {
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 1,1,1,1
    },

    {
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        1,1,1,1
    },

    {
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 1,1,1,1
    },

    {
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        1,1,1,1
    },

    {
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 1,1,1,1
    },

    {
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        1,1,1,1
    },

    {
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 1,1,1,1
    },

    {
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        1,1,1,1
    },

    {
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 0,0,0,0,
        0,0,0,0, 1,1,1,1
    }
};

constexpr int32_t hidden_bias[HIDDEN_SIZE] = {
    0, 0, 0, 0,
    0, 0, 0, 0,
    0, 0, 0, 0,
    0, 0, 0, 0
};

/*
 * 出力層。
 *
 * UP:
 *   後半8ニューロンを加算する。
 *
 * DOWN:
 *   前半8ニューロンを加算する。
 *
 * UNKNOWN:
 *   全体を弱く加算する。
 *
 * 今回の入力は後半ほど大きいため、UPが最大になる。
 */
constexpr int8_t output_weights[OUTPUT_SIZE][HIDDEN_SIZE] = {
    // UP
    {
        0, 0, 0, 0,
        0, 0, 0, 0,
        1, 1, 1, 1,
        1, 1, 1, 1
    },

    // DOWN
    {
        1, 1, 1, 1,
        1, 1, 1, 1,
        0, 0, 0, 0,
        0, 0, 0, 0
    },

    // UNKNOWN
    {
        0, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0
    }
};

constexpr int32_t output_bias[OUTPUT_SIZE] = {
    0,
    0,
    100
};

int32_t hidden_accumulator[HIDDEN_SIZE];
int32_t hidden_output[HIDDEN_SIZE];
int32_t output_accumulator[OUTPUT_SIZE];

void dense_hidden()
{
    for (int neuron = 0; neuron < HIDDEN_SIZE; ++neuron) {
        int32_t accumulator = hidden_bias[neuron];

        for (int input = 0; input < INPUT_SIZE; ++input) {
            const int32_t input_value =
                static_cast<int32_t>(input_features[input]);

            const int32_t weight =
                static_cast<int32_t>(
                    hidden_weights[neuron][input]
                );

            accumulator += input_value * weight;
        }

        hidden_accumulator[neuron] = accumulator;
    }
}

void relu_hidden()
{
    for (int neuron = 0; neuron < HIDDEN_SIZE; ++neuron) {
        const int32_t value =
            hidden_accumulator[neuron];

        hidden_output[neuron] =
            (value > 0) ? value : 0;
    }
}

void dense_output()
{
    for (int output = 0; output < OUTPUT_SIZE; ++output) {
        int32_t accumulator = output_bias[output];

        for (int neuron = 0; neuron < HIDDEN_SIZE; ++neuron) {
            const int32_t activation =
                hidden_output[neuron];

            const int32_t weight =
                static_cast<int32_t>(
                    output_weights[output][neuron]
                );

            accumulator += activation * weight;
        }

        output_accumulator[output] = accumulator;
    }
}

int classify()
{
    int maximum_index = 0;
    int32_t maximum_value = output_accumulator[0];

    for (int output = 1; output < OUTPUT_SIZE; ++output) {
        if (output_accumulator[output] > maximum_value) {
            maximum_value = output_accumulator[output];
            maximum_index = output;
        }
    }

    return maximum_index;
}

/*
 * 第1層の期待値。
 *
 * 入力を4個ずつ足した値。
 */
constexpr int32_t expected_hidden[HIDDEN_SIZE] = {
     22,  38,  54,  70,
     44,  76, 108, 140,
     66, 114, 162, 210,
     88, 152, 216, 280
};

/*
 * 出力層の期待値。
 *
 * UP:
 *   hidden[8]～hidden[15]
 *   = 66+114+162+210+88+152+216+280
 *   = 1288
 *
 * DOWN:
 *   hidden[0]～hidden[7]
 *   = 22+38+54+70+44+76+108+140
 *   = 552
 *
 * UNKNOWN:
 *   biasのみ = 100
 */
constexpr int32_t expected_output[OUTPUT_SIZE] = {
    1288,
    552,
    100
};

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

} // namespace

extern "C" uint32_t run()
{
    dense_hidden();

    PIO32 = 0xAB01;

    const uint32_t hidden_check =
        check_hidden_accumulator();

    PIO32 = 0xAB02;

    if (hidden_check != 0U) {
        return hidden_check;
    }
        
    PIO32 = 0xAB03;

    relu_hidden();
        
    PIO32 = 0xAB04;

    const uint32_t relu_check =
        check_relu();
        
    PIO32 = 0xAB05;

    if (relu_check != 0U) {
        return relu_check;
    }
        
    PIO32 = 0xAB06;

    dense_output();
        
    PIO32 = 0xAB07;

    const uint32_t output_check =
        check_output();
        
    PIO32 = 0xAB08;

    if (output_check != 0U) {
        return output_check;
    }
        
    PIO32 = 0xAB09;

    const int result = classify();
        
    PIO32 = 0xAC01;

    if (result != CLASS_UP) {
        return ERROR_CLASSIFY
            + static_cast<uint32_t>(result);
    }
        
    PIO32 = 0xAC02;

    PIO32 = 0xEE01;
    PIO32 = TEST_PASS;
    
    return TEST_PASS;
}