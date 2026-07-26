#include <cstdint>

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

static constexpr uint32_t SA_SIZE = 4u;

static constexpr uint32_t INPUT_BLOCKS =
    INPUT_SIZE / SA_SIZE;       // 16

static constexpr uint32_t HIDDEN_BLOCKS =
    HIDDEN_SIZE / SA_SIZE;      // 4

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
// ============================================================

static inline void sa_clear()
{
    CSR_WRITE(0x7C0, (0x04u << 16) | 0x04u);
    CSR_WRITE(0x7C0, (0x04u << 16) | 0x00u);
}

static inline void sa_state_reset()
{
    CSR_WRITE(0x7C0, (0x04u << 16) | 0x02u);
    CSR_WRITE(0x7C0, (0x04u << 16) | 0x00u);
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
// 4×4 SA Matrix Multiplication
// ============================================================

static inline void sa_matmul4x4(
    const uint8_t A[SA_SIZE][SA_SIZE],
    const uint8_t B[SA_SIZE][SA_SIZE],
    uint32_t C[SA_SIZE][SA_SIZE])
{
    // 前回の累積結果を消去
    sa_clear();

    sa_set_A(A);
    sa_set_B(B);

    sa_state_reset();

    // SA start
    CSR_WRITE(0x7C0, (0x04u << 16) | 0x01u);
    CSR_WRITE(0x7C0, (0x04u << 16) | 0x00u);

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
// 入力を4個ずつ16ブロック、
// ニューロンを4個ずつ4ブロックに分割する。
//
// 合計:
//   16 input blocks × 4 neuron blocks
//   = 64回の4×4行列積
// ============================================================

static void nn_layer1_sa(
    uint32_t hidden[HIDDEN_SIZE])
{
    for (uint32_t neuron = 0u;
         neuron < HIDDEN_SIZE;
         ++neuron) {

        hidden[neuron] = 0u;
    }

    for (uint32_t input_block = 0u;
         input_block < INPUT_BLOCKS;
         ++input_block) {

        const uint32_t input_base =
            input_block * SA_SIZE;

        for (uint32_t neuron_block = 0u;
             neuron_block < HIDDEN_BLOCKS;
             ++neuron_block) {

            const uint32_t neuron_base =
                neuron_block * SA_SIZE;

            alignas(4) uint8_t A[SA_SIZE][SA_SIZE];
            alignas(4) uint8_t B[SA_SIZE][SA_SIZE];

            uint32_t C[SA_SIZE][SA_SIZE];

            // ------------------------------------------------
            // A行列
            //
            // 同じ4入力を全行へ配置する。
            // そのため、Cの各行には同じ結果が現れる。
            // ------------------------------------------------
            for (uint32_t row = 0u;
                 row < SA_SIZE;
                 ++row) {

                for (uint32_t k = 0u;
                     k < SA_SIZE;
                     ++k) {

                    A[row][k] =
                        nn_input[input_base + k];
                }
            }

            // ------------------------------------------------
            // B行列
            //
            // B[k][local_neuron]
            // ------------------------------------------------
            for (uint32_t k = 0u;
                 k < SA_SIZE;
                 ++k) {

                const uint32_t input_index =
                    input_base + k;

                for (uint32_t local_neuron = 0u;
                     local_neuron < SA_SIZE;
                     ++local_neuron) {

                    const uint32_t neuron =
                        neuron_base + local_neuron;

                    B[k][local_neuron] =
                        weight1_at(
                            neuron,
                            input_index
                        );
                }
            }

            sa_matmul4x4(A, B, C);

            // row 0に4ニューロン分の部分和が並ぶ
            for (uint32_t local_neuron = 0u;
                 local_neuron < SA_SIZE;
                 ++local_neuron) {

                const uint32_t neuron =
                    neuron_base + local_neuron;

                hidden[neuron] +=
                    C[0][local_neuron];
            }
        }
    }
}

// ============================================================
// SA Layer 2
//
// 16 hidden neurons → 1 output
//
// hiddenを4個ずつ処理し、4回のSA演算結果を加算する。
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

        // Aのrow 0へhiddenを4個配置
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

        sa_matmul4x4(A, B, C);

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

    for (uint32_t neuron = 0u;
         neuron < HIDDEN_SIZE;
         ++neuron) {

        PIO32 = hidden[neuron];
    }

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

    const uint32_t cpu_result =
        nn_forward_cpu();

    PIO32 = 0xEE20u;
    PIO32 = cpu_result;

    // ------------------------------------------------
    // SA calculation
    // ------------------------------------------------
    PIO32 = 0xEE31u;

    const uint32_t sa_result =
        nn_forward_sa();

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

}