// robot_mujoco_test1.cpp - Standalone PSC-ONE bare-metal INT8 NN test.
// Model source: robot_int8_native.TFL (4 -> 16 -> 16 -> 1).
// This code expands the model weights, biases and quantization parameters
// into constants; no TFLite runtime, SD, malloc, printf or external adapters.
// Input is ALREADY normalized and then quantized INT8 (not raw sensor values).
#include <cstdint>
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
#define TIMER_W (*reinterpret_cast<volatile uint32_t*>(0x10002000u))
#define TIMER_R (*reinterpret_cast<volatile uint32_t*>(0x10002004u))
#define TIMER_ST (*reinterpret_cast<volatile uint32_t*>(0x10002008u))
static constexpr uint32_t TEST_END_CODE = 0xEE01u;
static constexpr uint32_t TEST_PASS = 0x600DCAFEu;
static constexpr uint32_t TEST_FAIL = 0xBAD00000u;
static constexpr uint32_t REPEATS = 10u;
extern "C" volatile uint32_t result;
extern "C" {
volatile uint32_t min_cycles_result = 0;
volatile uint32_t avg_cycles_result = 0;
volatile uint32_t max_cycles_result = 0;
volatile uint32_t output_int8_result = 0;
volatile uint32_t avg_time_us_x1000 = 0;
volatile uint32_t cycle_counter_ok = 0;
volatile uint32_t timer_divider_result = 0;
}

// 2^30 fixed-point multipliers; error is well below one INT8 LSB.
static constexpr unsigned Q = 30;
static inline int32_t round_shift(int64_t x) {
    const int64_t half = int64_t(1) << (Q - 1);
    return (int32_t)(x >= 0 ? (x + half) >> Q : -(((-x) + half) >> Q));
}
static inline int8_t clamp8(int32_t x) {
    if (x > 127) x = 127;
    if (x < -128) x = -128;
    return (int8_t)x;
}
static inline void compiler_barrier() {
    asm volatile("" ::: "memory");
}
static void report(uint32_t tag, uint32_t value) {
    PIO32 = tag;
    PIO32 = value;
}

static const int8_t W1[64] = {
    49, 46, -44, 127, 8, -2, -12, 73, -8, -74, 94, 24, 16, 3, 70, -10,
    42, 18, -106, 35, -7, -12, -16, 43, -77, -36, -10, -60, 4, -47, 44, -94,
    55, 15, -83, 71, 4, 64, -66, -34, -14, 0, 74, 79, 27, 1, 26, -12,
    61, -29, -116, -38, -51, 24, 92, 38, 3, 24, 124, -120, -8, -46, 72, 4,
};
static const int32_t B1[16] = {
    263, -59, 383, 174, -86, -601, 357, 142,
    598, -322, -343, -576, -124, 107, 378, 243,
};
static constexpr int32_t M1 = 14200228; // (0.16758327186107635 * 0.005717689637094736) / 0.07245290279388428
static constexpr int32_t ZI1 = 1;
static constexpr int32_t ZO1 = -5;

static const int8_t W2[256] = {
    -10, -15, 25, -5, -17, 1, 2, -8, -43, -39, 12, -5, -15, 36, 30, 2,
    28, -15, 3, -20, -15, 16, -9, 4, -20, -34, -18, -9, -25, 2, 82, 27,
    -9, 3, -26, -17, 50, -32, 6, -9, 21, 5, -15, -30, 22, -10, -127, -10,
    19, -17, 32, 10, -20, 20, -6, -1, -34, -12, 11, -9, -11, 0, 86, -4,
    -2, 5, 24, 26, -5, -15, -3, -2, -20, -9, 31, -17, -8, 26, 65, 1,
    51, 48, 8, -43, 68, -16, 7, 20, 44, 10, -14, -25, 42, -9, -65, 6,
    -10, -12, -2, -23, 5, 4, 33, -12, 13, 29, -5, -18, 7, -7, -40, -22,
    21, 23, 10, 0, -32, 5, -2, -7, -41, -32, 29, 10, -27, 8, 30, -7,
    -14, 2, 10, 6, -8, -25, -12, 18, 1, 4, 3, -17, -9, 11, -20, -13,
    -39, 24, 8, 14, -5, -34, 5, 7, 5, 48, 6, -2, 19, -23, -40, -34,
    -8, -46, -12, -23, 44, -34, -3, 6, 12, 30, -27, -28, 21, -45, -27, -5,
    4, -28, 17, 15, 18, -15, 1, -12, -14, 4, 3, 2, -11, 21, 65, -17,
    12, 20, 28, -20, -78, 11, 20, -7, -23, -23, 3, -14, -25, 15, 17, 29,
    29, 21, -9, -33, -29, -25, 0, -37, -19, 2, 5, 1, -11, 19, 16, -19,
    -17, 14, -1, 2, 11, 4, 23, 22, -43, 9, 28, 2, 6, 44, 76, 25,
    -22, 8, 14, 9, 20, -28, -29, -32, -20, 11, 13, -1, -4, -26, 3, -26,
};
static const int32_t B2[16] = {
    280, 454, -115, 254, 78, 482, -298, -204,
    -674, -522, 1103, -570, -251, 23, 419, 221,
};
static constexpr int32_t M2 = 6842557; // (0.04108623415231705 * 0.009198576211929321) / 0.05930596962571144
static constexpr int32_t ZI2 = -106;
static constexpr int32_t ZO2 = 19;

static const int8_t W3[16] = {
    91, 104, -127, 51, 80, -89, -51, 59, -2, -59, -107, 17, 45, 29, 57, -5,
};
static const int32_t B3[1] = {
    -2271,
};
static constexpr int32_t M3 = 2877557; // (0.02861236408352852 * 0.003876450937241316) / 0.04138699546456337
static constexpr int32_t ZI3 = -98;
static constexpr int32_t ZO3 = -65;
static constexpr int32_t LA1 = 1893473900; // positive: scale in/out
static constexpr int32_t LB1 = 189347390; // negative: alpha=0.1
static constexpr int32_t LZI1 = -5;
static constexpr int32_t LZO1 = -106;
static constexpr int64_t LA2 = 2225586806LL; // positive: scale in/out
static constexpr int32_t LB2 = 222558681; // negative: alpha=0.1
static constexpr int32_t LZI2 = 19;
static constexpr int32_t LZO2 = -98;

// Matrix layout: W[out_channel][in_channel], row-major.
static void fc(const int8_t* input, int8_t* output, const int8_t* weights,
               const int32_t* bias, int ni, int no,
               int32_t zi, int32_t zo, int32_t multiplier) {
    for (int o = 0; o < no; ++o) {
        int32_t acc = bias[o];
        for (int i = 0; i < ni; ++i) {
            acc += (int32_t(input[i]) - zi) * int32_t(weights[o * ni + i]);
        }
        output[o] = clamp8(round_shift(int64_t(acc) * multiplier) + zo);
    }
}
static void leaky(int8_t* data, int n, int32_t zi, int32_t zo,
                  int64_t mp, int64_t mn) {
    for (int i = 0; i < n; ++i) {
        int32_t centered = int32_t(data[i]) - zi;
        int64_t multiplier = centered >= 0 ? mp : mn;
        data[i] = clamp8(round_shift(int64_t(centered) * multiplier) + zo);
    }
}
// Replace this array later with the INT8 representation of normalized sensors.
static volatile int8_t FIXED_INPUT[4] = {1, 1, 1, 1};
static constexpr int8_t EXPECTED_NATIVE_INT8 = -65; // host integer implementation; TFLite parity unverified
static int8_t infer(const int8_t* x) {
    int8_t a[16];
    int8_t b[16];
    int8_t y[1];
    fc(x, a, W1, B1, 4, 16, ZI1, ZO1, M1);
    leaky(a, 16, LZI1, LZO1, LA1, LB1);
    fc(a, b, W2, B2, 16, 16, ZI2, ZO2, M2);
    leaky(b, 16, LZI2, LZO2, LA2, LB2);
    fc(b, y, W3, B3, 16, 1, ZI3, ZO3, M3);
    return y[0];
}
extern "C" void run() {
    int8_t input[4];
    volatile int8_t final_output = 0;

    // Preheat code/data caches before the measurements.
    for (uint32_t i = 0; i < 10u; ++i) {
        for (uint32_t j = 0; j < 4u; ++j) input[j] = FIXED_INPUT[j];
        final_output = infer(input);
    }

    // CPU v1 has no rdcycle counter. Use the existing MMIO timer instead.
    // CPU and timer share a clock; ST[20:11] gives divider - 1 (<=1023).
    // The SoC uses FRAC=1: one timer tick is 1 us at its configured clock.
    const uint32_t divider = ((TIMER_ST >> 11) & 0x3ffu) + 1u;
    timer_divider_result = divider;
    cycle_counter_ok = 1u; // validity of the timer-derived cycle measurements

    uint32_t min_c = 0xFFFFFFFFu;
    uint32_t max_c = 0u;
    uint32_t avg_quotient = 0u;
    uint32_t avg_remainder = 0u;
    uint32_t total_ticks = 0u;

    for (uint32_t i = 0; i < REPEATS; ++i) {
        for (uint32_t j = 0; j < 4u; ++j) input[j] = FIXED_INPUT[j];
        // One-shot, IRQ disabled. Expiration is detected instead of wrapping.
        TIMER_W = 0x0001ffffu;
        const uint32_t status = TIMER_ST;
        compiler_barrier();
        const uint32_t start = TIMER_R;
        compiler_barrier();
        final_output = infer(input);
        compiler_barrier();
        const uint32_t end = TIMER_R;
        compiler_barrier();
        TIMER_W = 0x00180000u; // stop + clear pending, outside timing
        if ((status & 0x80u) == 0u || end == 0u || start <= end || start > 0xffffu) {
            cycle_counter_ok = 0u;
            break;
        }
        const uint32_t ticks = start - end;
        total_ticks += ticks;
        // Includes timer-read/call/return/store overhead; resolution = 1 tick.
        const uint32_t elapsed = ticks * divider;
        if (elapsed < min_c) min_c = elapsed;
        if (elapsed > max_c) max_c = elapsed;
        // Exact floor(sum(elapsed)/REPEATS) with 32-bit division only.
        avg_quotient += elapsed / REPEATS;
        avg_remainder += elapsed % REPEATS;
        if (avg_remainder >= REPEATS) {
            ++avg_quotient;
            avg_remainder -= REPEATS;
        }
    }

    min_cycles_result = cycle_counter_ok ? min_c : 0xffffffffu;
    avg_cycles_result = cycle_counter_ok ? avg_quotient : 0xffffffffu;
    max_cycles_result = cycle_counter_ok ? max_c : 0xffffffffu;
    output_int8_result = static_cast<uint32_t>(static_cast<int32_t>(final_output));

    // us_x1000 = ns at the configured clock (80 MHz FPGA / 100 MHz COCOTB_SIM).
    // At most 65534 ticks * 10 repeats * 1000, safely within uint32_t.
    avg_time_us_x1000 = cycle_counter_ok ? (total_ticks * 1000u) / REPEATS : 0xffffffffu;

    // PIO intermediate writes appear as 'PIO data' in the existing cocotb log.
    // Each tag is followed by its value (hex). Divide AB07's value by 1000
    // for average us/inference. Timing excludes warmup and input copying.
    report(0xAB01u, cycle_counter_ok);      // 1 = all samples valid
    report(0xAB02u, timer_divider_result);  // CPU cycles per timer tick
    report(0xAB03u, REPEATS);
    report(0xAB04u, min_cycles_result);
    report(0xAB05u, avg_cycles_result);
    report(0xAB06u, max_cycles_result);
    report(0xAB07u, avg_time_us_x1000);

    // This checks this custom kernel's existing baseline only, NOT TFLite parity.
    result = (final_output == EXPECTED_NATIVE_INT8) ? TEST_PASS : (TEST_FAIL | 1u);
    if (cycle_counter_ok == 0u) result = TEST_FAIL | 2u;
    PIO32 = TEST_END_CODE;
    PIO32 = result;
    while (1) { }
}
extern "C" { volatile uint32_t result = 0; }
