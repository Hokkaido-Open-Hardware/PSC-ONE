#include <cstdint>

// ============================================================
//   Timer MMIO
// ============================================================
#define TIMER_MMIOADDR_W \
    (*reinterpret_cast<volatile uint32_t*>(0x10002000u))

#define TIMER_MMIOADDR_R \
    (*reinterpret_cast<volatile uint32_t*>(0x10002004u))

extern "C" volatile uint32_t timer_data;

// ============================================================
// MMIO / CSR
// ============================================================

#define SA_BASE_ADDR_C 0x028000u

#define PIO32 \
    (*reinterpret_cast<volatile uint32_t*>(0x10001000u))

static constexpr uint32_t TEST_END_CODE = 0xEE01u;

// 期待する最終結果
static constexpr uint32_t EXPECTED_RESULT = 0x00000780u;

#define CSR_WRITE(csr, val)                    \
    do {                                       \
        const uint32_t csr_value_ = (val);     \
        asm volatile (                         \
            "csrw " #csr ", %0"                \
            :                                  \
            : "r"(csr_value_)                  \
            : "memory"                         \
        );                                     \
    } while (false)

#define CSR_READ(csr)                          \
    ([&]() -> uint32_t {                       \
        uint32_t csr_value_;                   \
        asm volatile (                         \
            "csrr %0, " #csr                   \
            : "=r"(csr_value_)                 \
            :                                  \
            : "memory"                         \
        );                                     \
        return csr_value_;                     \
    }())

extern "C" volatile uint32_t result;

// ============================================================
// NN Parameters
// ============================================================

static constexpr uint32_t INPUT_SIZE  = 64u;
static constexpr uint32_t HIDDEN_SIZE = 16u;

static constexpr uint32_t SA_SIZE = 16u;

static_assert((INPUT_SIZE % SA_SIZE) == 0u);
static_assert((HIDDEN_SIZE % SA_SIZE) == 0u);

static constexpr uint32_t INPUT_BLOCKS =
    INPUT_SIZE / SA_SIZE;       // 4

static constexpr uint32_t HIDDEN_BLOCKS =
    HIDDEN_SIZE / SA_SIZE;      // 1

// ============================================================
// NN Input
//
// 1,2,3,4を16回繰り返す。
// ============================================================

static const uint8_t nn_input[INPUT_SIZE] = {
    1, 2, 3, 4,
    1, 2, 3, 4,
    1, 2, 3, 4,
    1, 2, 3, 4,

    1, 2, 3, 4,
    1, 2, 3, 4,
    1, 2, 3, 4,
    1, 2, 3, 4,

    1, 2, 3, 4,
    1, 2, 3, 4,
    1, 2, 3, 4,
    1, 2, 3, 4,

    1, 2, 3, 4,
    1, 2, 3, 4,
    1, 2, 3, 4,
    1, 2, 3, 4
};

// ============================================================
// Weight generation
//
// weight1[neuron][input]
//
// neuron番号とinput番号の下位2bitが一致するとき1。
// それ以外は0。
//
// neuron % 4 == 0 : 入力1を16個加算 → 16
// neuron % 4 == 1 : 入力2を16個加算 → 32
// neuron % 4 == 2 : 入力3を16個加算 → 48
// neuron % 4 == 3 : 入力4を16個加算 → 64
//
// hidden:
//   16,32,48,64,
//   16,32,48,64,
//   16,32,48,64,
//   16,32,48,64
// ============================================================

static inline uint8_t weight1_at(
    uint32_t neuron,
    uint32_t input)
{
    return ((neuron & 0x03u) == (input & 0x03u))
        ? 1u
        : 0u;
}

// 第二層の重み
//
// 1,2,3,4を4回繰り返す。
static inline uint8_t weight2_at(
    uint32_t neuron)
{
    return static_cast<uint8_t>(
        (neuron & 0x03u) + 1u
    );
}

// ============================================================
// SA Control
//
// csr_SA_CTRL[23:16] : matrix_size_x
// csr_SA_CTRL[31:24] : matrix_size_y
// csr_SA_CTRL[7:0]   : control bits
// ============================================================

static constexpr uint32_t SA_CTRL_START       = 0x01u;
static constexpr uint32_t SA_CTRL_STATE_RESET = 0x02u;
static constexpr uint32_t SA_CTRL_CLEAR       = 0x04u;

static constexpr uint32_t sa_make_ctrl(
    uint32_t matrix_size_x,
    uint32_t matrix_size_y,
    uint32_t control)
{
    return ((matrix_size_y & 0xFFu) << 24) |
           ((matrix_size_x & 0xFFu) << 16) |
           (control & 0xFFFFu);
}

static inline void sa_write_ctrl(
    uint32_t matrix_size_x,
    uint32_t matrix_size_y,
    uint32_t control)
{
    CSR_WRITE(
        0x7C0,
        sa_make_ctrl(matrix_size_x, matrix_size_y, control)
    );
}

static inline void sa_clear(
    uint32_t matrix_size_x,
    uint32_t matrix_size_y)
{
    sa_write_ctrl(matrix_size_x, matrix_size_y, SA_CTRL_CLEAR);
    sa_write_ctrl(matrix_size_x, matrix_size_y, 0u);
}

static inline void sa_state_reset(
    uint32_t matrix_size_x,
    uint32_t matrix_size_y)
{
    sa_write_ctrl(matrix_size_x, matrix_size_y, SA_CTRL_STATE_RESET);
    sa_write_ctrl(matrix_size_x, matrix_size_y, 0u);
}

static inline void sa_wait_done()
{
    while ((CSR_READ(0x7C8) & 0x01u) == 0u) {
        asm volatile("nop");
    }
}

static inline void sa_set_A(
    const uint8_t A[SA_SIZE][SA_SIZE])
{
    const uintptr_t address =
        reinterpret_cast<uintptr_t>(&A[0][0]);

    CSR_WRITE(0x7D0, address);
}

static inline void sa_set_B(
    const uint8_t B[SA_SIZE][SA_SIZE])
{
    const uintptr_t address =
        reinterpret_cast<uintptr_t>(&B[0][0]);

    CSR_WRITE(0x7D4, address);
}

static inline void sa_read_C(
    uint32_t C[SA_SIZE][SA_SIZE])
{
    volatile const uint32_t* const base =
        reinterpret_cast<volatile const uint32_t*>(
            SA_BASE_ADDR_C
        );

    for (uint32_t row = 0u; row < SA_SIZE; ++row) {
        for (uint32_t col = 0u; col < SA_SIZE; ++col) {
            C[row][col] =
                base[(row * SA_SIZE) + col];
        }
    }
}

// ============================================================
// 16×16 SA Matrix Multiplication
// ============================================================

static inline void sa_matmul16x16(
    const uint8_t A[SA_SIZE][SA_SIZE],
    const uint8_t B[SA_SIZE][SA_SIZE],
    uint32_t C[SA_SIZE][SA_SIZE])
{
    static constexpr uint32_t MATRIX_SIZE_X = SA_SIZE;
    static constexpr uint32_t MATRIX_SIZE_Y = SA_SIZE;

    // 前回の累積結果を消去
    sa_clear(MATRIX_SIZE_X, MATRIX_SIZE_Y);

    sa_set_A(A);
    sa_set_B(B);

    sa_state_reset(MATRIX_SIZE_X, MATRIX_SIZE_Y);

    // SA start
    sa_write_ctrl(MATRIX_SIZE_X, MATRIX_SIZE_Y, SA_CTRL_START);
    sa_write_ctrl(MATRIX_SIZE_X, MATRIX_SIZE_Y, 0u);

    sa_wait_done();
    sa_read_C(C);
}

// ============================================================
// CPU Reference
//
// 64 → 16 → 1
// ============================================================

static uint32_t nn_forward_cpu()
{
    uint32_t hidden[HIDDEN_SIZE];

    for (uint32_t neuron = 0u;
         neuron < HIDDEN_SIZE;
         ++neuron) {

        uint32_t acc = 0u;

        for (uint32_t input = 0u;
             input < INPUT_SIZE;
             ++input) {

            acc +=
                static_cast<uint32_t>(nn_input[input]) *
                static_cast<uint32_t>(
                    weight1_at(neuron, input)
                );
        }

        hidden[neuron] = acc;
    }

    uint32_t output = 0u;

    for (uint32_t neuron = 0u;
         neuron < HIDDEN_SIZE;
         ++neuron) {

        output +=
            hidden[neuron] *
            static_cast<uint32_t>(
                weight2_at(neuron)
            );
    }

    return output;
}

// ============================================================
// SA Layer 1
//
// 64 inputs → 16 hidden neurons
//
// A : 16 × 64
// B : 64 × 16
// C : 16 × 16
//
// matrix_size_x = 64  (共通次元 K)
// matrix_size_y = 16  (出力列数 N)
//
// 1回の64×16 SA演算で16ニューロンを計算する。
// Aの全16行へ同じ入力ベクトルを配置するため、
// Cの各行には同じ16ニューロンの結果が現れる。
// ============================================================

static void nn_layer1_sa(
    uint32_t hidden[HIDDEN_SIZE])
{
    static constexpr uint32_t MATRIX_SIZE_X = INPUT_SIZE;   // 64
    static constexpr uint32_t MATRIX_SIZE_Y = HIDDEN_SIZE;  // 16

    alignas(4) uint8_t A[MATRIX_SIZE_Y][MATRIX_SIZE_X];
    alignas(4) uint8_t B[MATRIX_SIZE_X][MATRIX_SIZE_Y];

    // ------------------------------------------------
    // A行列: 16 × 64
    // 同じ64入力を全16行へ配置する。
    // ------------------------------------------------
    for (uint32_t row = 0u;
         row < MATRIX_SIZE_Y;
         ++row) {

        for (uint32_t k = 0u;
             k < MATRIX_SIZE_X;
             ++k) {

            A[row][k] = nn_input[k];
        }
    }

    // ------------------------------------------------
    // B行列: 64 × 16
    // B[k][neuron]
    // ------------------------------------------------
    for (uint32_t k = 0u;
         k < MATRIX_SIZE_X;
         ++k) {

        for (uint32_t neuron = 0u;
             neuron < MATRIX_SIZE_Y;
             ++neuron) {

            B[k][neuron] = weight1_at(neuron, k);
        }
    }

    // 前回の累積結果を消去
    sa_clear(MATRIX_SIZE_X, MATRIX_SIZE_Y);

    CSR_WRITE(
        0x7D0,
        reinterpret_cast<uintptr_t>(&A[0][0])
    );

    CSR_WRITE(
        0x7D4,
        reinterpret_cast<uintptr_t>(&B[0][0])
    );

    sa_state_reset(MATRIX_SIZE_X, MATRIX_SIZE_Y);

    // SA start
    sa_write_ctrl(MATRIX_SIZE_X, MATRIX_SIZE_Y, SA_CTRL_START);
    sa_write_ctrl(MATRIX_SIZE_X, MATRIX_SIZE_Y, 0u);

    sa_wait_done();

    // Cは16×16。全行が同じ結果なのでrow 0だけ読む。
    volatile const uint32_t* const c_base =
        reinterpret_cast<volatile const uint32_t*>(
            SA_BASE_ADDR_C
        );

    for (uint32_t neuron = 0u;
         neuron < HIDDEN_SIZE;
         ++neuron) {

        hidden[neuron] = c_base[neuron];
    }
}

// ============================================================
// SA Layer 2
//
// 16 hidden neurons → 1 output
//
// hidden 16個を1回の16×16 SA演算で処理する。
// ============================================================

static uint32_t nn_layer2_sa(
    const uint32_t hidden[HIDDEN_SIZE])
{
    uint32_t output = 0u;

    for (uint32_t hidden_block = 0u;
         hidden_block < HIDDEN_BLOCKS;
         ++hidden_block) {

        const uint32_t hidden_base =
            hidden_block * SA_SIZE;

        alignas(4) uint8_t A[SA_SIZE][SA_SIZE];
        alignas(4) uint8_t B[SA_SIZE][SA_SIZE];

        uint32_t C[SA_SIZE][SA_SIZE];

        // 行列をゼロクリア
        for (uint32_t row = 0u;
             row < SA_SIZE;
             ++row) {

            for (uint32_t col = 0u;
                 col < SA_SIZE;
                 ++col) {

                A[row][col] = 0u;
                B[row][col] = 0u;
            }
        }

        // Aのrow 0へhiddenを16個配置
        for (uint32_t k = 0u;
             k < SA_SIZE;
             ++k) {

            const uint32_t neuron =
                hidden_base + k;

            // 今回のテストデータではhiddenは最大64なので
            // uint8_tへ安全に変換できる。
            A[0][k] =
                static_cast<uint8_t>(
                    hidden[neuron]
                );

            // 出力ニューロンは1個なのでcol 0だけ使用
            B[k][0] =
                weight2_at(neuron);
        }

        sa_matmul16x16(A, B, C);

        output += C[0][0];
    }

    return output;
}

// ============================================================
// SA Forward
// ============================================================

static uint32_t nn_forward_sa()
{
    uint32_t hidden[HIDDEN_SIZE];

    nn_layer1_sa(hidden);

    // hidden表示開始
    PIO32 = 0xEE10u;

    /*
    for (uint32_t neuron = 0u;
         neuron < HIDDEN_SIZE;
         ++neuron) {

        PIO32 = hidden[neuron];
    }
    */

    return nn_layer2_sa(hidden);
}

// ============================================================
// Entry
// ============================================================

extern "C" void run()
{
    // C出力バッファ設定
    CSR_WRITE(0x7D8, SA_BASE_ADDR_C);

    // SA有効化
    CSR_WRITE(0x7C4, 0x01u);

    // ------------------------------------------------
    // CPU calculation
    // ------------------------------------------------
    PIO32 = 0xEE21u;

    /*
     * Software reference
     */
    TIMER_MMIOADDR_W = 0x0001FFFFu;

    const uint32_t cpu_result =
        nn_forward_cpu();

    PIO32 = 0xEE20u;
    PIO32 = cpu_result;


    /*
     * Software実行時間
     */
    timer_data = TIMER_MMIOADDR_R;
    PIO32 = 0x0000A001u;
    PIO32 = 0xFFFFu - timer_data;

    // ------------------------------------------------
    // SA calculation
    // ------------------------------------------------
    PIO32 = 0xEE31u;

    /*
     * SynapEngine
     */
    TIMER_MMIOADDR_W = 0x0001FFFFu;

    const uint32_t sa_result =
        nn_forward_sa();

    /*
     * SynapEngine
     */

    timer_data = TIMER_MMIOADDR_R;
    PIO32 = 0x0000A002u;
    PIO32 = 0xFFFFu - timer_data;

    PIO32 = 0xEE30u;
    PIO32 = sa_result;

    // ------------------------------------------------
    // Result check
    // ------------------------------------------------
    bool ok = true;

    if (cpu_result != EXPECTED_RESULT) {
        PIO32 = 0xDEAD0001u;
        PIO32 = cpu_result;
        ok = false;
    }

    if (sa_result != EXPECTED_RESULT) {
        PIO32 = 0xDEAD0002u;
        PIO32 = sa_result;
        ok = false;
    }

    if (cpu_result != sa_result) {
        PIO32 = 0xDEAD0003u;
        ok = false;
    }

    result = sa_result;

    PIO32 = TEST_END_CODE;

    if (ok) {
        PIO32 = result;
    }
    else {
        PIO32 = 0x0000DEADu;
    }

    while (true) {
        asm volatile("nop");
    }
}

// ============================================================
// Global variables
// ============================================================

extern "C" {

volatile uint32_t result = 0u;
volatile uint32_t timer_data = 0;

}