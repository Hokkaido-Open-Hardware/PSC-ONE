#include <cstdint>
// Same nn_test1/2/3 model as nn_pulp_test1: [1..8], unchanged weights,
// zero biases, hidden {36,56,52,16}, output 368. Signed int8 interpretation
// preserves every original value. No quantization/rounding/saturation.
// New CPU v1 signed-byte SIMD required. Build: make nn_pulp_test2
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
#define TIMER_W (*reinterpret_cast<volatile uint32_t*>(0x10002000u))
#define TIMER_R (*reinterpret_cast<volatile uint32_t*>(0x10002004u))
#define TIMER_ST (*reinterpret_cast<volatile uint32_t*>(0x10002008u))
static constexpr uint32_t REPEATS = 16u;
static constexpr uint32_t SAMPLES = 5u;
static constexpr uint32_t ELEMENTS = 5u; // hidden[0..3], output[0]
static constexpr uint32_t DOTS_PER_INFERENCE = 9u; // 4*8/4 + 4/4
static constexpr uint32_t INVALID_CYCLES = 0xffffffffu;
static constexpr uint32_t expected[ELEMENTS] = {36u, 56u, 52u, 16u, 368u};

// Shared runtime byte data for both implementations. Volatile prevents folding the
// tiny constant network (including zero/one weights) or hoisting its loads.
// Keep the original byte representation: no prepacked data outside timing.
alignas(4) static volatile int8_t nn_input[8];
alignas(4) static volatile int8_t weight1[4][8];
alignas(4) static volatile int8_t weight2[4];

struct Batch {
    uint32_t values[REPEATS][ELEMENTS];
};
static Batch scalar_output;
static Batch dot_output;

extern "C" {
volatile uint32_t result = 0u;
volatile uint32_t scalar_cycles = INVALID_CYCLES;
volatile uint32_t dot_cycles = INVALID_CYCLES;
volatile uint32_t result_mismatch_count = 0u;
volatile uint32_t scalar_expected_mismatch_count = 0u;
volatile uint32_t dot_expected_mismatch_count = 0u;
volatile uint32_t timing_error_count = 0u;
}

static inline void compiler_barrier()
{
    asm volatile("" ::: "memory");
}


// Explicit aligned 32-bit load of four ORIGINAL adjacent int8 bytes. No type
// punning, no prepacking. Volatile asm models the complete memory access.
static inline uint32_t load4(const volatile int8_t* p)
{
    uint32_t v;
    asm volatile("lw %0, 0(%1)" : "=r"(v) : "r"(p) : "memory");
    return v;
}
static inline uint32_t dot(uint32_t a, uint32_t b)
{
    uint32_t r;
    asm volatile(".insn r 0x7b, 1, 0x48, %0, %1, %2" : "=r"(r) : "r"(a), "r"(b));
    return r;
}
static void initialize_model()
{
    static constexpr int8_t original_weight1[4][8] = {
        {1, 1, 1, 1, 1, 1, 1, 1},
        {1, 2, 1, 2, 1, 2, 1, 2},
        {2, 1, 2, 1, 2, 1, 2, 1},
        {1, 0, 1, 0, 1, 0, 1, 0}
    };
    for (uint32_t i = 0u; i < 8u; ++i) {
        nn_input[i] = static_cast<int8_t>(i + 1u);
        for (uint32_t j = 0u; j < 4u; ++j)
            weight1[j][i] = original_weight1[j][i];
    }
    for (uint32_t i = 0u; i < 4u; ++i)
        weight2[i] = static_cast<int8_t>(i + 1u);
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
            int32_t acc = 0; // original implicit zero bias
            for (uint32_t i = 0u; i < 8u; ++i)
                acc += static_cast<int32_t>(nn_input[i]) *
                       static_cast<int32_t>(weight1[j][i]);
            output.values[r][j] = static_cast<uint32_t>(acc);
        }
        int32_t acc = 0;
        for (uint32_t i = 0u; i < 4u; ++i)
            acc += static_cast<int32_t>(output.values[r][i]) * static_cast<int32_t>(weight2[i]);
        output.values[r][4] = static_cast<uint32_t>(acc);
    }
}


// The SIMD kernel loads four int8 values per word. Layer 2's int32 hidden
// values are repacked INSIDE timing; for this unchanged model all are <=56
// and nonnegative, so int8 conversion is exact. This is not a general int32
// NN conversion. The four byte stores + word load are part of the cost.
__attribute__((noinline)) static void run_nn_simd(Batch& output)
{
    for (uint32_t r=0u; r<REPEATS; ++r) {
        alignas(4) volatile int8_t hidden_bytes[4];
        for (uint32_t j=0u; j<4u; ++j) {
            uint32_t acc=0u;
            for (uint32_t i=0u; i<8u; i+=4u) {
                const uint32_t a=load4(&nn_input[i]);
                const uint32_t b=load4(&weight1[j][i]);
                acc+=dot(a,b);
            }
            output.values[r][j]=acc;
            hidden_bytes[j]=static_cast<int8_t>(acc);
        }
        const uint32_t a=load4(hidden_bytes), b=load4(weight2);
        output.values[r][4]=dot(a,b);
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


static uint32_t mismatch[2];
static uint32_t first_index=0xffffffffu, first_values[2];
static uint32_t cross_mismatch=0u;
static void compare(uint32_t sample)
{
    for (uint32_t r=0;r<REPEATS;++r) for (uint32_t i=0;i<ELEMENTS;++i) {
        const uint32_t a=scalar_output.values[r][i];
        const uint32_t b=dot_output.values[r][i];
        if (a!=b) ++cross_mismatch;
        if (a!=expected[i]) ++mismatch[0];
        if (b!=expected[i]) ++mismatch[1];
        if ((a!=expected[i] || b!=expected[i]) && first_index==0xffffffffu) {
            first_index=(sample*REPEATS+r)*ELEMENTS+i;
            first_values[0]=a;first_values[1]=b;
        }
    }
}
extern "C" void run()
{
    uint32_t best[2]={INVALID_CYCLES,INVALID_CYCLES};
    uint32_t divider[2]={0u,0u};
    for (uint32_t sample=0;sample<SAMPLES;++sample) {
        for (uint32_t turn=0;turn<2u;++turn) {
            const uint32_t mode=(sample+turn)%2u;
            uint32_t cycles;
            if (mode==0u) cycles=measure<run_nn_scalar>(scalar_output,divider[mode]);
            else cycles=measure<run_nn_simd>(dot_output,divider[mode]);
            if (cycles<best[mode]) best[mode]=cycles;
        }
        if (divider[0]!=divider[1])
            timing_error_count=timing_error_count+1u;
        compare(sample);
    }
    scalar_cycles=best[0];dot_cycles=best[1];
    result_mismatch_count=cross_mismatch;
    scalar_expected_mismatch_count=mismatch[0];
    dot_expected_mismatch_count=mismatch[1];
    const bool ok=cross_mismatch==0u && mismatch[0]==0u && mismatch[1]==0u &&
                  timing_error_count==0u;
    result=ok?0x600d600du:0xbad0bad0u;
    // PIO tags followed by data:
    // EE40: repeats=16, samples=5, cycles/tick, SIMD ops/batch=144.
    // A001/A002: scalar/DOT minimum batch cycles (converted ticks).
    // A004: cross-implementation mismatches (all 400 intermediate/final values).
    // A005: scalar, DOT golden mismatches; A006: timing errors.
    // EE20/EE30: scalar/DOT hidden[4], final output (first inference).
    // BAD00001: flat index, scalar, DOT, expected (only on error).
    // EE01: completion, then 600D600D pass or BAD0BAD0 failure.
    // Per-inference cycles=cycles/16; speedup=scalar_cycles/SIMD_cycles.
    // SIMD: 9 ops/inference, 144/batch, 720 measured +720 warmup.
    PIO32=0xee40u;PIO32=REPEATS;PIO32=SAMPLES;PIO32=divider[0];
    PIO32=REPEATS*DOTS_PER_INFERENCE;
    PIO32=0xa001u;PIO32=scalar_cycles;
    PIO32=0xa002u;PIO32=dot_cycles;
    PIO32=0xa004u;PIO32=result_mismatch_count;
    PIO32=0xa005u;
    for (uint32_t i=0;i<2u;++i) PIO32=mismatch[i];
    PIO32=0xa006u;PIO32=timing_error_count;
    PIO32=0xee20u;for (uint32_t i=0;i<ELEMENTS;++i) PIO32=scalar_output.values[0][i];
    PIO32=0xee30u;for (uint32_t i=0;i<ELEMENTS;++i) PIO32=dot_output.values[0][i];
    if (first_index!=0xffffffffu) {
        PIO32=0xbad00001u;PIO32=first_index;
        for (uint32_t i=0;i<2u;++i) PIO32=first_values[i];
        PIO32=expected[first_index%ELEMENTS];
    }
    PIO32=0xee01u;PIO32=result;
    while(true) asm volatile("nop");
}
