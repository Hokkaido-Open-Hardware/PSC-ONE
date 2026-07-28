#include <cstdint>

// ============================================================
// MMIO / CSR
// ============================================================

#define SA_BASE_ADDR_C 0x028000u

#define PIO32 \
    (*reinterpret_cast<volatile uint32_t*>(0x10001000u))

static constexpr uint32_t TEST_END_CODE = 0xEE01u;

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
// NN Data
// ============================================================

static const uint8_t nn_input[8] = {
    1, 2, 3, 4,
    5, 6, 7, 8
};

static const uint8_t weight1[4][8] = {
    {1, 1, 1, 1, 1, 1, 1, 1},
    {1, 2, 1, 2, 1, 2, 1, 2},
    {2, 1, 2, 1, 2, 1, 2, 1},
    {1, 0, 1, 0, 1, 0, 1, 0}
};

static const uint8_t weight2[4] = {
    1, 2, 3, 4
};

// ============================================================
// SA Control
// ============================================================

static inline void sa_clear()
{
    CSR_WRITE(0x7C0, (0x04 << 24) | (0x04 << 16) | 0x04u);
    CSR_WRITE(0x7C0, (0x04 << 24) | (0x04 << 16) | 0x00u);
}

static inline void sa_state_reset()
{
    CSR_WRITE(0x7C0, (0x04 << 24) | (0x04 << 16) | 0x02u);
    CSR_WRITE(0x7C0, (0x04 << 24) | (0x04 << 16) | 0x00u);
}

static inline void sa_wait_done()
{
    while ((CSR_READ(0x7C8) & 0x01u) == 0u) {
        asm volatile("nop");
    }
}

static inline void sa_set_A(const uint8_t A[4][4])
{
    const uintptr_t address =
        reinterpret_cast<uintptr_t>(&A[0][0]);

    CSR_WRITE(0x7D0, address);
}

static inline void sa_set_B(const uint8_t B[4][4])
{
    const uintptr_t address =
        reinterpret_cast<uintptr_t>(&B[0][0]);

    CSR_WRITE(0x7D4, address);
}

static inline void sa_read_C(uint32_t C[4][4])
{
    volatile const uint32_t* const base =
        reinterpret_cast<volatile const uint32_t*>(
            SA_BASE_ADDR_C
        );

    for (int row = 0; row < 4; ++row) {
        for (int col = 0; col < 4; ++col) {
            C[row][col] = base[(row * 4) + col];
        }
    }
}

// 完全に独立した4x4行列積。
// 前回の累積結果は毎回clearする。
static inline void sa_matmul4x4(
    const uint8_t A[4][4],
    const uint8_t B[4][4],
    uint32_t C[4][4])
{
    sa_clear();

    sa_set_A(A);
    sa_set_B(B);

    sa_state_reset();

    CSR_WRITE(0x7C0, (0x04 << 24) | (0x04 << 16) | 0x01u);
    CSR_WRITE(0x7C0, (0x04 << 24) | (0x04 << 16) | 0x00u);

    sa_wait_done();
    sa_read_C(C);
}

// ============================================================
// CPU Reference
// ============================================================

static uint32_t nn_forward_cpu()
{
    uint32_t hidden[4] = {
        0u, 0u, 0u, 0u
    };

    for (uint32_t neuron = 0u; neuron < 4u; ++neuron) {
        uint32_t acc = 0u;

        for (uint32_t input = 0u; input < 8u; ++input) {
            acc +=
                static_cast<uint32_t>(nn_input[input]) *
                static_cast<uint32_t>(weight1[neuron][input]);
        }

        hidden[neuron] = acc;
    }

    uint32_t output = 0u;

    for (uint32_t i = 0u; i < 4u; ++i) {
        output +=
            hidden[i] *
            static_cast<uint32_t>(weight2[i]);
    }

    return output;
}

// ============================================================
// SA Layer 1
//
// 8 inputs -> 4 hidden
//
// 4入力ずつ2回、独立した4x4行列積を行い、
// 部分和はCPU側で加算する。
// ============================================================

static void nn_layer1_sa(uint32_t hidden[4])
{
    uint32_t accum[4] = {
        0u, 0u, 0u, 0u
    };

    for (uint32_t input_block = 0u;
         input_block < 2u;
         ++input_block) {

        const uint32_t input_base =
            input_block * 4u;

        uint8_t A[4][4];
        uint8_t B[4][4];
        uint32_t C[4][4];

        // Aの各行に同じ4入力を配置する。
        for (uint32_t row = 0u; row < 4u; ++row) {
            for (uint32_t k = 0u; k < 4u; ++k) {
                A[row][k] =
                    nn_input[input_base + k];
            }
        }

        // B[k][neuron]
        for (uint32_t k = 0u; k < 4u; ++k) {
            for (uint32_t neuron = 0u;
                 neuron < 4u;
                 ++neuron) {

                B[k][neuron] =
                    weight1[neuron][input_base + k];
            }
        }

        sa_matmul4x4(A, B, C);

        // row 0に4ニューロン分の部分和が並ぶ。
        for (uint32_t neuron = 0u;
             neuron < 4u;
             ++neuron) {

            accum[neuron] +=
                C[0][neuron];
        }
    }

    for (uint32_t neuron = 0u;
         neuron < 4u;
         ++neuron) {

        hidden[neuron] =
            accum[neuron];
    }
}

// ============================================================
// SA Layer 2
//
// hidden[4] -> output[1]
// ============================================================

static uint32_t nn_layer2_sa(
    const uint32_t hidden[4])
{
    uint8_t A[4][4];
    uint8_t B[4][4];
    uint32_t C[4][4];

    // memset生成を避ける。
    for (uint32_t row = 0u; row < 4u; ++row) {
        for (uint32_t col = 0u; col < 4u; ++col) {
            A[row][col] = 0u;
            B[row][col] = 0u;
        }
    }

    for (uint32_t k = 0u; k < 4u; ++k) {
        A[0][k] =
            static_cast<uint8_t>(hidden[k]);

        B[k][0] =
            weight2[k];
    }

    sa_matmul4x4(A, B, C);

    return C[0][0];
}

// ============================================================
// SA Forward
// ============================================================

static uint32_t nn_forward_sa()
{
    uint32_t hidden[4] = {
        0u, 0u, 0u, 0u
    };

    nn_layer1_sa(hidden);

    PIO32 = 0xEE10u;

    for (uint32_t i = 0u; i < 4u; ++i) {
        PIO32 = hidden[i];
    }

    return nn_layer2_sa(hidden);
}

// ============================================================
// Entry
// ============================================================

extern "C" void run()
{
    CSR_WRITE(0x7D8, SA_BASE_ADDR_C);
    CSR_WRITE(0x7C4, 0x01u);

    PIO32 = 0xEE21u;

    const uint32_t cpu_result =
        nn_forward_cpu();

    PIO32 = 0xEE20u;
    PIO32 = cpu_result;

    PIO32 = 0xEE31u;

    const uint32_t sa_result =
        nn_forward_sa();

    PIO32 = 0xEE30u;
    PIO32 = sa_result;

    bool ok = true;

    if (cpu_result != 0x00000170u) {
        PIO32 = 0xDEAD0001u;
        ok = false;
    }

    if (cpu_result != sa_result) {
        PIO32 = 0xDEAD0002u;
        ok = false;
    }

    result = sa_result;

    PIO32 = TEST_END_CODE;

    if (ok) {
        PIO32 = result;
    }
    else {
        PIO32 = 0xDEADu;
    }

    while (true) {
        asm volatile("nop");
    }
}

extern "C" {

volatile uint32_t result = 0u;

}