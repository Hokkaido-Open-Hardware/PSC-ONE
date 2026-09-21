#include <cstdint>

// Based on nn_test2.cpp's CPU reference (also numerically nn_test1/3).
// Unchanged network: unsigned byte inputs/weights, 8 -> 4 -> 1, zero biases.
// Hidden = {36, 56, 52, 16}; output = 368 (0x170). Nonnegative data makes
// nn_test1's ReLU an identity. No quantization, rounding, shifts or saturation.
// nn_test4 is a 32x32 matrix benchmark; nn_test5.cpp was absent at creation.
// Build with the existing cpp/Makefile: make nn_pulp_test1
// Requires a CPU implementing cv.dotup.h (currently CPU_VERSION=v1).

#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
#define TIMER_W (*reinterpret_cast<volatile uint32_t*>(0x10002000u))
#define TIMER_R (*reinterpret_cast<volatile uint32_t*>(0x10002004u))
#define TIMER_ST (*reinterpret_cast<volatile uint32_t*>(0x10002008u))

static constexpr uint32_t REPEATS = 16u;
static constexpr uint32_t SAMPLES = 5u;
static constexpr uint32_t ELEMENTS = 5u; // hidden[0..3], output[0]
static constexpr uint32_t DOTS_PER_INFERENCE = 18u; // 4*8/2 + 4/2
static constexpr uint32_t INVALID_CYCLES = 0xffffffffu;
static constexpr uint32_t expected[ELEMENTS] = {36u, 56u, 52u, 16u, 368u};

// Same runtime reads in both implementations. Volatile prevents folding the
// tiny constant network (including zero/one weights) or hoisting its loads.
// Keep the original byte representation: no prepacked data outside timing.
static volatile uint8_t nn_input[8];
static volatile uint8_t weight1[4][8];
static volatile uint8_t weight2[4];

struct Batch {
    uint32_t values[REPEATS][ELEMENTS];
};
static Batch scalar_output;
static Batch pulp_output;

extern "C" {
volatile uint32_t result = 0u;
volatile uint32_t scalar_cycles = INVALID_CYCLES;
volatile uint32_t pulp_cycles = INVALID_CYCLES;
volatile uint32_t result_mismatch_count = 0u;
volatile uint32_t scalar_expected_mismatch_count = 0u;
volatile uint32_t pulp_expected_mismatch_count = 0u;
volatile uint32_t timing_error_count = 0u;
}

static inline void compiler_barrier()
{
    asm volatile("" ::: "memory");
}

static inline uint32_t cv_dotup_h(uint32_t a, uint32_t b)
{
    uint32_t value;
    asm volatile(".insn r 0x7b, 0, 0x40, %0, %1, %2"
                 : "=r"(value) : "r"(a), "r"(b));
    return value;
}

static inline uint32_t pack_u16(uint32_t low, uint32_t high)
{
    return (low & 0xffffu) | ((high & 0xffffu) << 16);
}

static void initialize_model()
{
    static constexpr uint8_t original_weight1[4][8] = {
        {1, 1, 1, 1, 1, 1, 1, 1},
        {1, 2, 1, 2, 1, 2, 1, 2},
        {2, 1, 2, 1, 2, 1, 2, 1},
        {1, 0, 1, 0, 1, 0, 1, 0}
    };
    for (uint32_t i = 0u; i < 8u; ++i) {
        nn_input[i] = static_cast<uint8_t>(i + 1u);
        for (uint32_t j = 0u; j < 4u; ++j)
            weight1[j][i] = original_weight1[j][i];
    }
    for (uint32_t i = 0u; i < 4u; ++i)
        weight2[i] = static_cast<uint8_t>(i + 1u);
    compiler_barrier();
}

static void reset_output(Batch& output)
{
    // Volatile writes ensure the requested pre-run clearing is not elided.
    for (uint32_t r = 0u; r < REPEATS; ++r) {
        volatile uint32_t* const values = output.values[r];
        for (uint32_t i = 0u; i < ELEMENTS; ++i)
            values[i] = 0u;
    }
    compiler_barrier();
}

// Independent scalar kernel: ordinary RV32IM only. Every inference overwrites
// all hidden/output elements; there is no recurrent or persistent NN state.
__attribute__((noinline))
static void run_nn_scalar(Batch& output)
{
    for (uint32_t r = 0u; r < REPEATS; ++r) {
        for (uint32_t j = 0u; j < 4u; ++j) {
            uint32_t acc = 0u; // original implicit zero bias
            for (uint32_t i = 0u; i < 8u; ++i)
                acc += static_cast<uint32_t>(nn_input[i]) *
                       static_cast<uint32_t>(weight1[j][i]);
            output.values[r][j] = acc;
        }
        uint32_t acc = 0u;
        for (uint32_t i = 0u; i < 4u; ++i)
            acc += output.values[r][i] * static_cast<uint32_t>(weight2[i]);
        output.values[r][4] = acc;
    }
}

// Each DOT replaces two scalar products and their addition; accumulating the
// pair into acc remains scalar (this is DOT, not SDOT). All byte expansion,
// packing and hidden-value packing happen here, inside the measured call.
// No signed correction: the source model is unsigned. Hidden values fit in
// 16 bits without loss. For this unchanged data, each layer-1 product <= 16,
// pair <= 32, hidden <= 56; layer-2 product <= 224, pair <= 448, output=368.
// Thus regrouping cannot overflow uint32_t, and masking drops no valid bits.
// This is a test of this fixed model, not a general uint32_t NN conversion.
__attribute__((noinline))
static void run_nn_pulp(Batch& output)
{
    for (uint32_t r = 0u; r < REPEATS; ++r) {
        for (uint32_t j = 0u; j < 4u; ++j) {
            uint32_t acc = 0u;
            for (uint32_t i = 0u; i < 8u; i += 2u) {
                const uint32_t a = pack_u16(nn_input[i], nn_input[i + 1u]);
                const uint32_t b = pack_u16(weight1[j][i], weight1[j][i + 1u]);
                acc += cv_dotup_h(a, b);
            }
            output.values[r][j] = acc;
        }
        uint32_t acc = 0u;
        for (uint32_t i = 0u; i < 4u; i += 2u) {
            const uint32_t a = pack_u16(output.values[r][i], output.values[r][i + 1u]);
            const uint32_t b = pack_u16(weight2[i], weight2[i + 1u]);
            acc += cv_dotup_h(a, b);
        }
        output.values[r][4] = acc;
    }
}

// PSC_RV32IS_TIMER, also used by nn_test4/timer_test1, counts prescaled ticks,
// NOT CPU cycles. ST[20:11] exposes PRESC_MAX[9:0]. The current SoC shares the
// CPU/timer clock and uses FRAC=1, with divider <=1024. For other hardware,
// verify these assumptions before interpreting the cycle conversion.
// Report cycles = elapsed_ticks * divider: quantization error is <1 tick,
// plus the common timer-read/call/return overhead (not subtracted).
// A one-shot timer prevents unnoticed wrap; zero/expired samples fail.
// Minimum of five 16-inference batches is reported, NOT their sum.
// Before EACH sample: restore model, warm that kernel, then clear output.
// All preparation, initialization, comparison and PIO are outside timing.
template<void (*Kernel)(Batch&)>
static uint32_t measure(Batch& output, uint32_t& divider)
{
    initialize_model();
    reset_output(output);
    Kernel(output); // warm instructions/data, including the complete packing
    compiler_barrier();
    reset_output(output);

    TIMER_W = 0x0001ffffu; // start one-shot, IRQ disabled
    const uint32_t status = TIMER_ST;
    divider = ((status >> 11) & 0x3ffu) + 1u;
    compiler_barrier();
    const uint32_t begin = TIMER_R;
    compiler_barrier();
    Kernel(output);
    compiler_barrier();
    const uint32_t end = TIMER_R;
    compiler_barrier();
    TIMER_W = 0x00180000u; // stop + clear pending, outside the window

    if ((status & 0x80u) == 0u || end == 0u || begin <= end || begin > 0xffffu) {
        timing_error_count = timing_error_count + 1u;
        return INVALID_CYCLES;
    }
    return (begin - end) * divider;
}

struct Comparison {
    uint32_t mismatch;
    uint32_t scalar_expected;
    uint32_t pulp_expected;
    uint32_t first_index;
    uint32_t first_scalar;
    uint32_t first_pulp;
    uint32_t first_expected;
};

static void compare_outputs(uint32_t sample, Comparison& check)
{
    // Examine ALL elements of ALL repetitions of ALL measured samples, even
    // after a failure. A shared scalar/PULP bug also fails against the golden.
    for (uint32_t r = 0u; r < REPEATS; ++r) {
        for (uint32_t i = 0u; i < ELEMENTS; ++i) {
            const uint32_t a = scalar_output.values[r][i];
            const uint32_t b = pulp_output.values[r][i];
            if (a != b)
                ++check.mismatch;
            if (a != expected[i])
                ++check.scalar_expected;
            if (b != expected[i])
                ++check.pulp_expected;
            if ((a != b || a != expected[i] || b != expected[i]) &&
                check.first_index == 0xffffffffu) {
                check.first_index = (sample * REPEATS + r) * ELEMENTS + i;
                check.first_scalar = a;
                check.first_pulp = b;
                check.first_expected = expected[i];
            }
        }
    }
}

extern "C" void run()
{
    Comparison check = {0u, 0u, 0u, 0xffffffffu, 0u, 0u, 0u};
    uint32_t best_scalar = INVALID_CYCLES;
    uint32_t best_pulp = INVALID_CYCLES;
    uint32_t scalar_divider = 0u;
    uint32_t pulp_divider = 0u;
    timing_error_count = 0u;

    for (uint32_t sample = 0u; sample < SAMPLES; ++sample) {
        uint32_t a;
        uint32_t b;
        // Alternate order to reduce systematic first/second-run bias.
        if ((sample & 1u) == 0u) {
            a = measure<run_nn_scalar>(scalar_output, scalar_divider);
            b = measure<run_nn_pulp>(pulp_output, pulp_divider);
        } else {
            b = measure<run_nn_pulp>(pulp_output, pulp_divider);
            a = measure<run_nn_scalar>(scalar_output, scalar_divider);
        }
        if (a < best_scalar)
            best_scalar = a;
        if (b < best_pulp)
            best_pulp = b;
        if (scalar_divider != pulp_divider)
            timing_error_count = timing_error_count + 1u;
        compare_outputs(sample, check);
    }

    scalar_cycles = best_scalar;
    pulp_cycles = best_pulp;
    result_mismatch_count = check.mismatch;
    scalar_expected_mismatch_count = check.scalar_expected;
    pulp_expected_mismatch_count = check.pulp_expected;
    const bool ok = check.mismatch == 0u && check.scalar_expected == 0u &&
                    check.pulp_expected == 0u && timing_error_count == 0u;
    result = ok ? 0x600d600du : 0xbad0bad0u;

    // PIO stream (tag followed by the listed words), all outside timing:
    // EE40: repeats=16, samples=5, cycles_per_tick, DOTs/measured_batch=288.
    // A001: scalar_cycles; A002: pulp_cycles (minimum batch, converted ticks).
    //       FFFFFFFF = no valid timing; ignore performance if A006 != 0.
    // A003: result_mismatch_count (400 hidden/output element comparisons).
    // A004/A005: scalar/PULP mismatch counts against the original golden.
    // A006: timing_error_count (expired/stopped/zero interval/divider mismatch).
    // EE20/EE30: final sample's first inference, hidden[0..3], output.
    // BAD00001 (only on value error): first flat index, scalar, PULP, golden.
    //   index = ((sample * 16 + repetition) * 5 + element), zero-based;
    //   element 0..3 = hidden, 4 = output.
    // EE01: termination marker, THEN 600D600D (all pass) or BAD0BAD0 (failure).
    // Marker-before-signature matches the existing PSC-ONE testbench protocol.
    // Speedup = A001/A002; savings = A001-A002 (SIGNED); reduction% =
    // 100*(A001-A002)/A001. Per-inference cycles = batch cycles/16.
    // DOT count is analytic: 288 per measured batch, 1440 over 5 measured
    // batches, plus 1440 during warmups; scalar executes zero DOTs.
    PIO32 = 0xee40u;
    PIO32 = REPEATS;
    PIO32 = SAMPLES;
    PIO32 = scalar_divider;
    PIO32 = REPEATS * DOTS_PER_INFERENCE;
    PIO32 = 0xa001u;
    PIO32 = scalar_cycles;
    PIO32 = 0xa002u;
    PIO32 = pulp_cycles;
    PIO32 = 0xa003u;
    PIO32 = result_mismatch_count;
    PIO32 = 0xa004u;
    PIO32 = scalar_expected_mismatch_count;
    PIO32 = 0xa005u;
    PIO32 = pulp_expected_mismatch_count;
    PIO32 = 0xa006u;
    PIO32 = timing_error_count;
    PIO32 = 0xee20u;
    for (uint32_t i = 0u; i < ELEMENTS; ++i)
        PIO32 = scalar_output.values[0][i];
    PIO32 = 0xee30u;
    for (uint32_t i = 0u; i < ELEMENTS; ++i)
        PIO32 = pulp_output.values[0][i];
    if (check.first_index != 0xffffffffu) {
        PIO32 = 0xbad00001u;
        PIO32 = check.first_index;
        PIO32 = check.first_scalar;
        PIO32 = check.first_pulp;
        PIO32 = check.first_expected;
    }
    PIO32 = 0x0000ee01u;
    PIO32 = result;
    while (true)
        asm volatile("nop");
}
