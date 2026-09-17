#include <cstdint>

/* ---------- アサーション用PIO出力 ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))

static constexpr uint32_t TEST_END_CODE = 0xEE01;


/* ---------- 宣言 ---------- */
extern "C" volatile uint32_t result;


/* ============================================================
 * ReLU
 * ============================================================ */
static inline int32_t relu(int32_t x)
{
    return (x > 0) ? x : 0;
}


/* ============================================================
 * 8入力 → 4ニューロン
 * ============================================================ */
static void nn_layer_8x4(
    const int32_t input[8],
    const int32_t weight[4][8],
    const int32_t bias[4],
    int32_t output[4]
)
{
    for (uint32_t j = 0; j < 4; j++) {

        int32_t acc = bias[j];

        for (uint32_t i = 0; i < 8; i++) {

            acc += input[i] * weight[j][i];
        }

        output[j] = relu(acc);
    }
}


/* ============================================================
 * 4入力 → 1ニューロン
 * ============================================================ */
static int32_t nn_layer_4x1(
    const int32_t input[4],
    const int32_t weight[4],
    int32_t bias
)
{
    int32_t acc = bias;

    for (uint32_t i = 0; i < 4; i++) {

        acc += input[i] * weight[i];
    }

    return acc;
}


/* ============================================================
 * NN forward
 *
 *       input[8]
 *           |
 *         8 x 4
 *           |
 *          ReLU
 *           |
 *       hidden[4]
 *           |
 *         4 x 1
 *           |
 *        output
 *
 * ============================================================ */
static int32_t nn_forward(const int32_t input[8])
{
    /*
     * Layer 1
     *
     * 8 input
     * 4 neuron
     */

    static constexpr int32_t weight1[4][8] = {

        { 1, 1, 1, 1, 1, 1, 1, 1 },

        { 1, 2, 1, 2, 1, 2, 1, 2 },

        { 2, 1, 2, 1, 2, 1, 2, 1 },

        { 1, 0, 1, 0, 1, 0, 1, 0 }
    };


    static constexpr int32_t bias1[4] = {

        0,
        0,
        0,
        0
    };


    /*
     * Layer 2
     */

    static constexpr int32_t weight2[4] = {

        1,
        2,
        3,
        4
    };


    static constexpr int32_t bias2 = 0;


    int32_t hidden[4];


    nn_layer_8x4(
        input,
        weight1,
        bias1,
        hidden
    );


    return nn_layer_4x1(
        hidden,
        weight2,
        bias2
    );
}


/* ============================================================
 * Entry
 * ============================================================ */
extern "C" void run()
{
    /*
     * input
     *
     * [1,2,3,4,5,6,7,8]
     */

    const int32_t input[8] = {

        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8
    };


    int32_t output = nn_forward(input);


    result = static_cast<uint32_t>(output);


    /*
     * Test End
     */

    PIO32 = TEST_END_CODE;


    /*
     * Result
     */

    PIO32 = result;


    while (1) {
    }
}


/* ---------- result 実体 ---------- */

extern "C" {

volatile uint32_t result = 0;

}