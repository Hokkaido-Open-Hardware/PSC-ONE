#include <cstdint>

// ============================================================
// CSR / MMIO
// ============================================================
#define SA_BASE_ADDR_C 0x028000u

#define PIO32 \
    (*reinterpret_cast<volatile uint32_t*>(0x10001000u))

static constexpr uint32_t TEST_END_CODE = 0xEE01u;

#define CSR_WRITE(csr, val)                      \
    do {                                         \
        const uint32_t csr_value_ = (val);       \
        asm volatile (                           \
            "csrw " #csr ", %0"                  \
            :                                    \
            : "r"(csr_value_)                    \
            : "memory"                           \
        );                                       \
    } while (false)

#define CSR_READ(csr)                                            \
    ([&]() -> uint32_t {                                         \
        uint32_t csr_value_;                                     \
        asm volatile ("csrr %0, " #csr                          \
                      : "=r"(csr_value_)                         \
                      :                                          \
                      : "memory");                               \
        return csr_value_;                                       \
    }())

extern "C" volatile uint32_t result;

// ============================================================
// NN Configuration
//
// Input 8 -> Hidden 4 -> Output 1
// ============================================================
static const uint8_t nn_input[8] = {
    1, 2, 3, 4,
    5, 6, 7, 8
};

// weight1[neuron][input]
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
    // bit[2] = accumulator clear
    CSR_WRITE(0x7C0, (0x04 << 24) | (0x04 << 16) | 0x04u);
    CSR_WRITE(0x7C0, (0x04 << 24) | (0x04 << 16) | 0x00u);
}

static inline void sa_state_reset()
{
    // bit[1] = controller state reset
    CSR_WRITE(0x7C0, (0x04 << 24) | (0x04 << 16) | 0x02u);
    CSR_WRITE(0x7C0, (0x04 << 24) | (0x04 << 16) | 0x00u);
}

static inline void sa_wait_done()
{
    while ((CSR_READ(0x7C8) & 0x01u) == 0u) {
        asm volatile ("nop");
    }
}

static inline void sa_set_A(const uint8_t A[4][4])
{
    const uintptr_t addr =
        reinterpret_cast<uintptr_t>(&A[0][0]);

    CSR_WRITE(0x7D0, addr);
}

static inline void sa_set_B(const uint8_t B[4][4])
{
    const uintptr_t addr =
        reinterpret_cast<uintptr_t>(&B[0][0]);

    CSR_WRITE(0x7D4, addr);
}

static inline void sa_read_C(uint32_t C[4][4])
{
    volatile const uint32_t* const base =
        reinterpret_cast<volatile const uint32_t*>(SA_BASE_ADDR_C);

    for (int row = 0; row < 4; ++row) {
        for (int col = 0; col < 4; ++col) {
            C[row][col] = base[row * 4 + col];
        }
    }
}

// One independent 4x4 matrix multiplication.
static inline void sa_matmul4x4(
    const uint8_t A[4][4],
    const uint8_t B[4][4],
    uint32_t C[4][4])
{
    sa_clear();
    sa_set_A(A);
    sa_set_B(B);

    sa_state_reset();
    CSR_WRITE(0x7C4, 0x01u); // Output Stationary mode

    CSR_WRITE(0x7C0, (0x04 << 24) | (0x04 << 16) | 0x01u); // start
    CSR_WRITE(0x7C0, (0x04 << 24) | (0x04 << 16) | 0x00u);

    sa_wait_done();
    sa_read_C(C);
}

// ============================================================
// CPU Reference NN
// ============================================================
static uint32_t nn_forward_cpu()
{
    uint32_t hidden[4] = {0u, 0u, 0u, 0u};

    for (uint32_t neuron = 0; neuron < 4u; ++neuron) {
        uint32_t acc = 0u;

        for (uint32_t input = 0; input < 8u; ++input) {
            acc += static_cast<uint32_t>(nn_input[input]) *
                   static_cast<uint32_t>(weight1[neuron][input]);
        }

        hidden[neuron] = acc;
    }

    uint32_t output = 0u;

    for (uint32_t i = 0; i < 4u; ++i) {
        output += hidden[i] * static_cast<uint32_t>(weight2[i]);
    }

    return output;
}

// ============================================================
// SA Layer 1: 8 -> 4
//
// 4 inputs per 4x4 operation, therefore two operations.
//
// A row 0 = four inputs
// B[k][neuron] = corresponding weight
// C[0][neuron] = four-input partial sum
// ============================================================
static void nn_layer1_sa(uint32_t hidden[4])
{
    hidden[0] = 0u;
    hidden[1] = 0u;
    hidden[2] = 0u;
    hidden[3] = 0u;

    for (uint32_t block = 0; block < 2u; ++block) {
        const uint32_t input_base = block * 4u;

        alignas(4) uint8_t A[4][4] = {
            {0u, 0u, 0u, 0u},
            {0u, 0u, 0u, 0u},
            {0u, 0u, 0u, 0u},
            {0u, 0u, 0u, 0u}
        };

        alignas(4) uint8_t B[4][4] = {
            {0u, 0u, 0u, 0u},
            {0u, 0u, 0u, 0u},
            {0u, 0u, 0u, 0u},
            {0u, 0u, 0u, 0u}
        };

        uint32_t C[4][4];

        for (uint32_t k = 0; k < 4u; ++k) {
            A[0][k] = nn_input[input_base + k];

            for (uint32_t neuron = 0; neuron < 4u; ++neuron) {
                B[k][neuron] = weight1[neuron][input_base + k];
            }
        }

        sa_matmul4x4(A, B, C);

        for (uint32_t neuron = 0; neuron < 4u; ++neuron) {
            hidden[neuron] += C[0][neuron];
        }
    }
}

// ============================================================
// SA Layer 2: 4 -> 1
//
// A row 0 = hidden[0..3]
// B column 0 = weight2[0..3]
// C[0][0] = output
// ============================================================
static uint32_t nn_layer2_sa(const uint32_t hidden[4])
{
    alignas(4) uint8_t A[4][4] = {
        {0u, 0u, 0u, 0u},
        {0u, 0u, 0u, 0u},
        {0u, 0u, 0u, 0u},
        {0u, 0u, 0u, 0u}
    };

    alignas(4) uint8_t B[4][4] = {
        {0u, 0u, 0u, 0u},
        {0u, 0u, 0u, 0u},
        {0u, 0u, 0u, 0u},
        {0u, 0u, 0u, 0u}
    };

    uint32_t C[4][4];

    for (uint32_t k = 0; k < 4u; ++k) {
        A[0][k] = static_cast<uint8_t>(hidden[k]);
        B[k][0] = weight2[k];
    }

    sa_matmul4x4(A, B, C);
    return C[0][0];
}

// ============================================================
// SynapEngine NN Forward
// ============================================================
static uint32_t nn_forward_sa()
{
    uint32_t hidden[4] = {0u, 0u, 0u, 0u};

    nn_layer1_sa(hidden);

    PIO32 = 0xEE10u;
    for (uint32_t i = 0; i < 4u; ++i) {
        PIO32 = hidden[i];
    }

    return nn_layer2_sa(hidden);
}

// ============================================================
// Test Entry
// ============================================================
extern "C" void run()
{
    // C result base remains fixed in memory.
    CSR_WRITE(0x07D8, SA_BASE_ADDR_C);

    const uint32_t cpu_result = nn_forward_cpu();

    PIO32 = 0xEE20u;
    PIO32 = cpu_result;

    const uint32_t sa_result = nn_forward_sa();

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
    PIO32 = ok ? result : 0x0000DEADu;

    while (true) {
        asm volatile ("nop");
    }
}

extern "C" {
volatile uint32_t result = 0u;
}