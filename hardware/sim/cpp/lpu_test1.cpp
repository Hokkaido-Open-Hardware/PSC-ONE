#include <cstdint>

// Build: make lpu_test1
// Hardware: ENABLE_NPU=0, ENABLE_LPU=1. Match these two macros to RTL.
// Default: OUT_SHIFT=0, LPU_OUTPUT_INT32=0 (packed signed INT8).
#ifndef LPU_OUT_SHIFT
#define LPU_OUT_SHIFT 0
#endif
#ifndef LPU_OUTPUT_INT32
#define LPU_OUTPUT_INT32 0
#endif

static_assert(LPU_OUT_SHIFT >= 0 && LPU_OUT_SHIFT <= 31);
static_assert(LPU_OUTPUT_INT32 == 0 || LPU_OUTPUT_INT32 == 1);

#define PIO32 \
    (*reinterpret_cast<volatile uint32_t*>(0x10001000u))

#define CSR_WRITE(csr, value)                   \
    do {                                      \
        const uint32_t csr_value_ = (value);   \
        asm volatile (                        \
            "csrw " #csr ", %0"               \
            :                                 \
            : "r"(csr_value_)                 \
            : "memory"                        \
        );                                    \
    } while (false)

static constexpr uint32_t MAX_M       = 8u;
static constexpr uint32_t K           = 12u;
static constexpr uint32_t N           = 8u;
static constexpr uint32_t GUARD       = 0xA55AA55Au;
static constexpr uint32_t C_BASE      = 0x028004u;
static constexpr uint32_t POLL_LIMIT  = 1000000u;

alignas(4) static int8_t   matrix_a[MAX_M][K];
alignas(4) static int8_t   matrix_b[K][N];
alignas(4) static uint32_t packed_b[(K / 4u) * (N / 4u)];

static inline uint32_t read_status()
{
    uint32_t status;
    asm volatile (
        "csrr %0, 0x7C8"
        : "=r"(status)
        :
        : "memory"
    );
    return status;
}

static void control_pulse(
    uint32_t command)
{
    CSR_WRITE(0x7C0, command);
    CSR_WRITE(0x7C0, 0u);
}

static void prepare_model()
{
    // Columns 0/1 force both saturation directions. Column 2 remains zero.
    // Other columns exercise cancellation, ordering, and negative shifts.
    for (uint32_t k = 0u; k < K; ++k) {
        for (uint32_t col = 0u; col < N; ++col) {
            const uint32_t code = (k + col) % 3u;
            matrix_b[k][col] = (col == 0u) ? int8_t{-1}
                            : (col == 1u) ? int8_t{1}
                            : (col == 2u) ? int8_t{0}
                            : static_cast<int8_t>(static_cast<int32_t>(code) - 1);
        }
    }

    // Model-load conversion, once before all inferences. Never emit code 11.
    for (uint32_t kt = 0u; kt < K / 4u; ++kt) {
        for (uint32_t nt = 0u; nt < N / 4u; ++nt) {
            uint32_t word = 0u;
            for (uint32_t row = 0u; row < 4u; ++row) {
                for (uint32_t col = 0u; col < 4u; ++col) {
                    const int8_t weight = matrix_b[kt * 4u + row][nt * 4u + col];
                    const uint32_t code = (weight > 0) ? 1u : (weight < 0) ? 2u : 0u;
                    word |= code << (2u * (row * 4u + col));
                }
            }
            packed_b[kt * (N / 4u) + nt] = word;
        }
    }
}

static int32_t reference_value(
    uint32_t row,
    uint32_t col)
{
    int32_t acc = 0;
    for (uint32_t k = 0u; k < K; ++k) {
        // CPU multiply intentionally independent of the RTL add/sub lanes.
        acc += static_cast<int32_t>(matrix_a[row][k])
             * static_cast<int32_t>(matrix_b[k][col]);
    }
    if constexpr (LPU_OUTPUT_INT32 != 0) {
        return acc;
    }
    // C++23 signed right shift rounds toward negative infinity, as RTL >>>.
    const int32_t shifted = acc >> LPU_OUT_SHIFT;
    return (shifted > 127) ? 127 : (shifted < -128) ? -128 : shifted;
}

static uint32_t run_case(
    uint32_t rows,
    bool     default_m,
    bool     signed_mode)
{
    for (uint32_t row = 0u; row < MAX_M; ++row) {
        for (uint32_t k = 0u; k < K; ++k) {
            const int32_t value = static_cast<int32_t>((row * 37u + k * 19u) & 255u) - 128;
            matrix_a[row][k] = (row == 0u) ? int8_t{-128}
                             : (row == 1u) ? int8_t{127}
                             : static_cast<int8_t>(value);
        }
    }

    volatile uint32_t* const output = reinterpret_cast<volatile uint32_t*>(C_BASE);
    const uint32_t words = (LPU_OUTPUT_INT32 != 0) ? rows * N : rows * N / 4u;
    output[-1] = GUARD;
    for (uint32_t index = 0u; index < words; ++index) {
        output[index] = GUARD;
    }
    output[words] = GUARD;

    control_pulse(0x02u);
    control_pulse(0x04u);
    CSR_WRITE(0x7C4, ((default_m ? 0u : rows) << 16) | (N << 8) | K);
    CSR_WRITE(0x7D0, reinterpret_cast<uintptr_t>(&matrix_a[0][0]));
    CSR_WRITE(0x7D4, reinterpret_cast<uintptr_t>(&packed_b[0]));
    CSR_WRITE(0x7D8, C_BASE);
    asm volatile ("fence rw, rw" : : : "memory");

    control_pulse((signed_mode ? 0x08u : 0u) | 0x01u);
    uint32_t poll = 0u;
    while ((read_status() & 1u) == 0u) {
        if (++poll == POLL_LIMIT) {
            return 0xDEAD0001u;
        }
    }
    asm volatile ("fence rw, rw" : : : "memory");
    if ((read_status() & 3u) != 1u) {
        return 0xDEAD0002u;
    }

    for (uint32_t row = 0u; row < rows; ++row) {
        for (uint32_t col = 0u; col < N; ++col) {
            const uint32_t index = row * N + col;
            const int32_t expected = reference_value(row, col);
            const int32_t actual = (LPU_OUTPUT_INT32 != 0)
                ? reinterpret_cast<volatile const int32_t*>(C_BASE)[index]
                : reinterpret_cast<volatile const int8_t*>(C_BASE)[index];
            if (actual != expected) {
                PIO32 = index;
                PIO32 = static_cast<uint32_t>(expected);
                PIO32 = static_cast<uint32_t>(actual);
                return 0xDEAD0003u;
            }
        }
    }
    if (output[-1] != GUARD || output[words] != GUARD) {
        return 0xDEAD0004u;
    }
    if ((read_status() & 1u) == 0u) {
        return 0xDEAD0005u;
    }
    control_pulse(0x02u);
    return (read_status() & 1u) == 0u ? 0u : 0xDEAD0006u;
}

extern "C" void run()
{
    prepare_model();
    uint32_t failure = 0u;
    for (uint32_t rows = 1u; rows <= 5u; ++rows) {
        failure = run_case(rows, false, (rows & 1u) != 0u);
        if (failure != 0u) {
            break;
        }
    }
    if (failure == 0u) {
        failure = run_case(N, true, false);  // M=0 means M=N.
    }
    PIO32 = 0xEE01u;
    PIO32 = (failure == 0u) ? 0x0000BEEFu : failure;
    while (true) {
        asm volatile ("nop");
    }
}
