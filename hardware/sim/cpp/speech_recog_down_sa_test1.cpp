// NISHIHARU
// speech_recog_down_sa_test1.cpp
//
// PSC_NPU accelerated version of speech_recog_down_test1.cpp.
// The Q16.16 front-end normalization remains on the CPU.  Both dense layers
// are quantized to signed int8 and evaluated by the unsigned-int8 PSC_NPU;
// zero-point correction restores signed dot products on the CPU.

// Reuse the regression input, trained parameters, fixed-point helpers, debug
// protocol, and buffers without changing the original test source.
#define run speech_recog_down_cpu_unused_run
#define result speech_recog_down_cpu_unused_result
#include "speech_recog_down_test1.cpp"
#undef result
#undef run

// -----------------------------------------------------------------------------
// PSC_NPU CSR interface
// -----------------------------------------------------------------------------

#define CSR_WRITE(csr, val)                                            \
    do {                                                               \
        const uint32_t csr_value_ = (val);                             \
        asm volatile ("csrw " #csr ", %0" :: "r"(csr_value_) : "memory"); \
    } while (false)

#define CSR_READ(csr)                                                   \
    ([&]() -> uint32_t {                                               \
        uint32_t csr_value_;                                           \
        asm volatile ("csrr %0, " #csr : "=r"(csr_value_) :: "memory"); \
        return csr_value_;                                             \
    }())

static constexpr uintptr_t SA_BASE_ADDR_C = 0x00028000u;
static constexpr uint32_t SA_ROWS = 4u;
static constexpr uint32_t SA_CTRL_START = 0x01u;
static constexpr uint32_t SA_CTRL_STATE_RESET = 0x02u;
static constexpr uint32_t SA_CTRL_CLEAR = 0x04u;
static constexpr int32_t SIGNED_ZERO_POINT = 128;

// Power-of-two quantization keeps the CPU-side requantization inexpensive.
// Q16.16 normalized input / 1024 and Q16.16 weights / 512 both fit int8.
static constexpr uint32_t INPUT_QUANT_SHIFT = 10u;
static constexpr uint32_t WEIGHT_QUANT_SHIFT = 9u;
static constexpr uint32_t DENSE1_RESULT_SHIFT =
    INPUT_QUANT_SHIFT + WEIGHT_QUANT_SHIFT - 16u; // dot * 8 -> Q16.16

// Hidden Q16.16 / 2048 and layer-2 weights / 512 both fit int8.
static constexpr uint32_t HIDDEN_QUANT_SHIFT = 11u;
static constexpr uint32_t DENSE2_RESULT_SHIFT =
    HIDDEN_QUANT_SHIFT + WEIGHT_QUANT_SHIFT - 16u; // dot * 16 -> Q16.16

alignas(4) static uint8_t gSaA[SA_ROWS][FEATURES];
// Offline-quantized and NPU-layout weights.  Keeping these in inference-ready
// form avoids converting and transposing 1072 Q16.16 weights on every run.
alignas(4) static const uint8_t kW1Npu[4][FEATURES][SA_ROWS] = {
    {
        {115,107,136,120},{144,161,182,124},{130,96,112,124},{135,157,133,137},
        {126,122,117,128},{126,117,120,120},{132,136,135,122},{122,81,110,116},
        {147,128,104,129},{129,140,156,135},{131,132,142,120},{117,113,78,139},
        {136,134,79,151},{147,151,167,129},{147,131,130,130},{130,120,155,106},
        {103,123,115,130},{136,92,119,121},{120,131,105,99},{107,152,109,110},
        {123,175,74,109},{125,184,114,120},{161,151,125,113},{135,56,154,185},
        {164,37,172,108},{167,154,116,149},{74,203,126,169},{128,175,229,121},
        {64,121,156,73},{112,109,92,138},{110,43,142,84},{174,89,64,90},
        {149,115,89,114},{122,127,103,104},{144,113,205,122},{150,76,147,159},
        {158,71,123,160},{131,110,166,86},{106,167,160,107},{156,178,139,133},
        {122,131,120,103},{126,24,115,120},{124,80,134,61},{145,140,164,105},
        {155,125,116,89},{117,125,167,123},{43,148,108,112},{100,141,118,136},
        {115,125,81,134},{113,146,111,152},{117,141,210,130},{125,130,141,133},
        {109,134,144,115},{120,131,167,140},{140,134,151,107},{100,105,136,123},
        {136,125,130,141},{105,138,135,120},{148,117,143,130},{120,115,132,142},
        {141,106,107,156},{125,108,120,125},{145,195,128,123},{110,162,141,156}
    },
    {
        {134,177,130,130},{155,141,165,120},{126,110,148,133},{125,129,122,120},
        {142,124,141,120},{141,183,151,120},{167,134,136,107},{140,153,140,73},
        {109,123,133,157},{129,114,154,117},{114,122,115,133},{172,152,155,116},
        {165,162,120,167},{100,126,126,173},{106,83,134,131},{106,105,131,153},
        {124,106,146,149},{142,150,130,151},{132,123,147,134},{115,153,154,139},
        {131,165,151,161},{154,116,110,162},{166,125,78,164},{166,106,105,117},
        {154,115,135,103},{93,104,124,22},{166,117,131,162},{157,182,122,145},
        {151,164,129,146},{88,153,123,100},{25,174,131,119},{84,156,182,102},
        {110,122,107,165},{178,143,112,80},{83,128,125,146},{148,93,125,113},
        {123,154,130,147},{153,114,136,108},{80,130,192,119},{128,156,153,124},
        {162,134,125,192},{155,169,159,96},{59,140,116,80},{95,124,74,156},
        {112,140,142,105},{124,104,75,107},{134,123,114,75},{190,79,97,105},
        {120,114,141,114},{148,97,141,100},{131,117,115,143},{128,122,74,146},
        {147,60,87,128},{116,120,89,105},{134,105,136,87},{101,138,136,118},
        {121,111,167,108},{120,134,141,105},{149,141,99,147},{113,123,144,120},
        {154,141,164,137},{123,156,179,130},{151,141,141,115},{157,132,135,125}
    },
    {
        {112,151,141,171},{123,135,118,136},{100,118,119,133},{120,165,100,151},
        {139,123,142,117},{141,162,120,168},{165,115,151,121},{124,56,145,127},
        {131,112,111,128},{98,151,162,133},{121,127,74,127},{147,167,109,125},
        {154,110,153,172},{143,146,131,142},{99,136,120,113},{149,165,141,143},
        {144,132,112,151},{154,117,121,138},{120,110,108,110},{140,131,125,104},
        {114,128,138,169},{104,116,163,156},{128,108,125,60},{189,211,153,89},
        {92,220,203,198},{162,197,79,73},{98,72,42,204},{154,59,32,122},
        {88,122,151,131},{103,106,189,126},{120,133,160,153},{124,125,184,122},
        {115,190,130,100},{127,141,132,140},{100,127,138,149},{110,135,115,162},
        {157,110,120,143},{158,110,101,89},{175,79,113,113},{192,129,107,208},
        {85,94,160,171},{183,136,125,129},{125,220,117,141},{115,162,124,115},
        {170,123,126,133},{119,136,134,122},{134,115,167,143},{136,187,115,169},
        {143,104,124,126},{140,140,104,132},{136,136,134,117},{102,111,126,116},
        {151,120,138,121},{121,159,95,117},{153,94,115,129},{132,115,130,131},
        {130,154,101,117},{148,131,124,124},{125,166,153,136},{151,76,146,119},
        {115,116,131,149},{123,158,93,144},{151,151,157,129},{116,138,113,127}
    },
    {
        {85,143,120,107},{126,125,137,159},{110,141,125,101},{139,115,120,121},
        {113,136,128,110},{148,131,117,115},{145,139,151,97},{98,95,147,148},
        {121,130,107,119},{120,108,162,134},{127,151,126,100},{117,165,68,173},
        {131,123,157,146},{96,114,115,120},{127,136,136,140},{128,120,112,110},
        {159,145,100,120},{123,134,105,136},{146,96,151,148},{100,128,120,131},
        {166,115,112,145},{144,132,162,97},{120,103,112,142},{115,78,165,154},
        {133,100,118,109},{113,120,160,163},{132,147,151,96},{113,161,116,120},
        {124,92,150,186},{126,97,126,111},{158,168,125,136},{119,120,147,163},
        {117,109,200,130},{78,138,209,139},{193,129,161,138},{110,146,74,132},
        {95,172,72,142},{109,178,106,136},{89,152,65,153},{108,126,152,105},
        {112,102,143,64},{158,56,140,154},{150,119,107,90},{116,137,142,156},
        {130,140,145,103},{115,169,60,149},{127,180,134,150},{103,179,106,142},
        {166,124,111,131},{87,112,94,110},{77,106,122,143},{146,143,135,125},
        {136,110,123,119},{45,135,134,141},{143,141,115,94},{78,122,113,108},
        {177,151,164,127},{161,79,141,130},{134,90,137,146},{141,172,121,142},
        {134,141,122,146},{182,147,107,117},{147,125,143,150},{128,151,105,170}
    }
};

static const uint32_t kW1NpuSums[4][SA_ROWS] = {
    {8134u,8004u,8419u,7910u},
    {8326u,8352u,8370u,7992u},
    {8438u,8489u,8130u,8574u},
    {8014u,8289u,8151u,8339u}
};

alignas(4) static const uint8_t kW2Npu[HIDDEN][SA_ROWS] = {
    {121,58,240,128},{93,76,203,128},{107,196,145,128},{153,247,55,128},
    {49,238,148,128},{10,147,110,128},{162,39,148,128},{43,185,132,128},
    {206,93,84,128},{151,63,160,128},{118,35,174,128},{231,64,74,128},
    {110,216,141,128},{106,108,206,128},{191,110,127,128},{237,86,69,128}
};
static const uint32_t kW2NpuSums[SA_ROWS] = {2088u,1961u,2216u,2048u};


static constexpr uint32_t sa_make_ctrl(uint32_t matrix_size_x,
                                       uint32_t matrix_size_y,
                                       uint32_t control)
{
    return ((matrix_size_y & 0xFFu) << 24) |
           ((matrix_size_x & 0xFFu) << 16) |
           (control & 0xFFFFu);
}

static inline void sa_write_ctrl(uint32_t matrix_size_x,
                                 uint32_t matrix_size_y,
                                 uint32_t control)
{
    CSR_WRITE(0x7C0, sa_make_ctrl(matrix_size_x, matrix_size_y, control));
}

static inline void sa_command_pulse(uint32_t matrix_size_x,
                                    uint32_t matrix_size_y,
                                    uint32_t command)
{
    sa_write_ctrl(matrix_size_x, matrix_size_y, command);
    sa_write_ctrl(matrix_size_x, matrix_size_y, 0u);
}

static inline int32_t quantize_signed_shift(int32_t value, uint32_t shift)
{
    const int32_t half = static_cast<int32_t>(1u << (shift - 1u));
    int32_t quantized;

    if (value >= 0) {
        quantized = (value + half) >> shift;
    } else {
        quantized = -(((-value) + half) >> shift);
    }

    if (quantized > 127) return 127;
    if (quantized < -128) return -128;
    return quantized;
}

static inline uint8_t to_npu_u8(int32_t signed_value)
{
    return static_cast<uint8_t>(signed_value + SIGNED_ZERO_POINT);
}

static void sa_prepare_a(const int32_t* vector,
                         uint32_t vector_size,
                         uint32_t quant_shift,
                         uint32_t& sum_a_u8)
{
    sum_a_u8 = 0u;

    for (uint32_t k = 0u; k < vector_size; ++k) {
        const uint8_t value =
            to_npu_u8(quantize_signed_shift(vector[k], quant_shift));
        gSaA[0][k] = value;
        sum_a_u8 += value;
    }

    // The controller produces a square 4x4 output.  Only row zero is useful;
    // keep the other rows at the signed zero point so they are benign.
    for (uint32_t row = 1u; row < SA_ROWS; ++row) {
        for (uint32_t k = 0u; k < vector_size; ++k) {
            gSaA[row][k] = static_cast<uint8_t>(SIGNED_ZERO_POINT);
        }
    }
}

static void sa_run(uint32_t matrix_size_x, const uint8_t* matrix_b)
{
    sa_command_pulse(matrix_size_x, SA_ROWS, SA_CTRL_CLEAR);
    sa_command_pulse(matrix_size_x, SA_ROWS, SA_CTRL_STATE_RESET);

    CSR_WRITE(0x7D0, reinterpret_cast<uintptr_t>(&gSaA[0][0]));
    CSR_WRITE(0x7D4, reinterpret_cast<uintptr_t>(matrix_b));

    sa_command_pulse(matrix_size_x, SA_ROWS, SA_CTRL_START);

    while ((CSR_READ(0x7C8) & 0x01u) == 0u) {
        asm volatile("nop");
    }
}

static inline int32_t sa_signed_dot(uint32_t column,
                                    uint32_t vector_size,
                                    uint32_t sum_a_u8,
                                    uint32_t sum_b_u8)
{
    volatile const uint32_t* const c =
        reinterpret_cast<volatile const uint32_t*>(SA_BASE_ADDR_C);
    const int32_t raw = static_cast<int32_t>(c[column]);

    return raw
         - (SIGNED_ZERO_POINT * static_cast<int32_t>(sum_a_u8))
         - (SIGNED_ZERO_POINT * static_cast<int32_t>(sum_b_u8))
         + (static_cast<int32_t>(vector_size) *
            SIGNED_ZERO_POINT * SIGNED_ZERO_POINT);
}

static inline int32_t add_scaled_dot(int32_t bias,
                                     int32_t dot,
                                     uint32_t scale_shift)
{
    // Worst cases are bounded by 64 * 128 * 128 * 8 for layer 1 and
    // 16 * 128 * 128 * 16 for layer 2, so signed 32-bit arithmetic is safe.
    return bias + dot * static_cast<int32_t>(1u << scale_shift);
}

static void dense1_sa()
{
    uint32_t sum_a_u8 = 0u;
    sa_prepare_a(gNormQ16, FEATURES, INPUT_QUANT_SHIFT, sum_a_u8);

    for (uint32_t output_base = 0u;
         output_base < HIDDEN;
         output_base += SA_ROWS) {
        const uint32_t output_block = output_base / SA_ROWS;
        sa_run(FEATURES, &kW1Npu[output_block][0][0]);

        for (uint32_t col = 0u; col < SA_ROWS; ++col) {
            const int32_t dot =
                sa_signed_dot(col, FEATURES, sum_a_u8,
                              kW1NpuSums[output_block][col]);
            const int32_t value =
                add_scaled_dot(kB1Q16[output_base + col], dot,
                               DENSE1_RESULT_SHIFT);
            gHiddenQ16[output_base + col] = (value > 0) ? value : 0;
        }
    }
}

static void dense2_sa()
{
    uint32_t sum_a_u8 = 0u;
    sa_prepare_a(gHiddenQ16, HIDDEN, HIDDEN_QUANT_SHIFT, sum_a_u8);

    sa_run(HIDDEN, &kW2Npu[0][0]);

    for (uint32_t col = 0u; col < CLASSES; ++col) {
        const int32_t dot =
            sa_signed_dot(col, HIDDEN, sum_a_u8, kW2NpuSums[col]);
        gLogitsQ16[col] =
            add_scaled_dot(kB2Q16[col], dot, DENSE2_RESULT_SHIFT);
    }
}

static uint32_t run_nn_sa()
{
    // Preserve the original CPU fixed-point preprocessing exactly.
    for (uint32_t i = 0u; i < FEATURES; ++i) {
        const int32_t delta = kFeatureQ16[i] - kFeatureMeanQ16[i];
        gNormQ16[i] = mul_q16(delta, kFeatureInvStdQ16[i]);
    }

    CSR_WRITE(0x7D8, SA_BASE_ADDR_C);
    CSR_WRITE(0x7C4, 0x01u);

    dense1_sa();
    dense2_sa();

    uint32_t best = 0u;
    for (uint32_t output = 1u; output < CLASSES; ++output) {
        if (gLogitsQ16[output] > gLogitsQ16[best]) best = output;
    }
    return best;
}

extern "C" volatile uint32_t result;

extern "C" void run()
{
    result = run_nn_sa();
    
    PIO32 = 0x00D1;

    // Keep the original debug and completion protocol so the two programs can
    // be compared under the same cocotb testbench and input conditions.
    dump_nn_debug(result);

    PIO32 = TEST_END_CODE;
    PIO32 = result;

    while (1) { }
}

extern "C" {
volatile uint32_t result = 0u;
}
