#include <cstdint>

// ビルド: make npu_test1
// 対象構成: CPU_VERSION=v1、NPU_VERSION=legacy、INT8累積保持の機能識別ビット[8]=1。
// 成功時: PIO 0xEE01 → 0xBEEF。失敗時: PIO 0xEE01 → 0xDEADxxxx。
// 失敗時は終了通知の前に、PIOへテスト段階・比較位置・期待値・実値を出力する（0xEE20パケット）。

#define PIO32 \
    (*reinterpret_cast<volatile uint32_t*>(0x10001000u))

#define CSR_WRITE(csr, value)                    \
    do {                                       \
        const uint32_t csr_value_ = (value);    \
        asm volatile (                         \
            "csrw " #csr ", %0"                \
            :                                  \
            : "r"(csr_value_)                  \
            : "memory"                         \
        );                                     \
    } while (false)

// ============================================================
// CSR・コマンド・パラメータブロック
// ============================================================
static constexpr uint32_t START       = 0x01u;
static constexpr uint32_t STATE_RESET = 0x02u;
static constexpr uint32_t CLEAR       = 0x04u;
static constexpr uint32_t CONFIG      = 0x18u; // 符号付きINT8＋OSモード
static constexpr uint32_t DONE        = 0x01u;
static constexpr uint32_t BUSY        = 0x02u;
static constexpr uint32_t ERROR       = 0x04u;
static constexpr uint32_t ACC_VALID   = 0x08u;
static constexpr uint32_t CAPABILITY  = 0x100u;

static constexpr uint32_t FIRST       = 1u;
static constexpr uint32_t CONTINUE    = 2u;
static constexpr uint32_t LAST        = 3u;
static constexpr uint32_t SINGLE      = 4u;
static constexpr uint32_t MAX_SEGMENT = 252u;
static constexpr uint32_t POLL_LIMIT  = 1000000u;
static constexpr uint32_t C_BASE      = 0x028004u;
static constexpr uint32_t GUARD       = 0xA55AA55Au;
static constexpr int32_t  INPUT_ZERO  = -3;
static constexpr int32_t  INT_MINIMUM = (-2147483647 - 1);

// C+0: 初期累積値[4]、C+16: 乗数[4]、C+32: シフト量[4]。
// C+48/52/56/60: 出力ゼロ点・下限値・上限値・予約領域（0）。
// C+64..79: 確保済みのINT8出力作業領域（出力1行につき4バイト）。
static volatile int32_t* const params =
    reinterpret_cast<volatile int32_t*>(C_BASE);
static volatile int8_t* const output =
    reinterpret_cast<volatile int8_t*>(C_BASE + 64u);

alignas(16) static int8_t matrix_a[4u * MAX_SEGMENT];
alignas(16) static int8_t matrix_b[MAX_SEGMENT * 4u];
static int32_t initial[4];
static int32_t multiplier[4];
static int32_t shift[4];
static int32_t output_zero;
static int32_t minimum;
static int32_t maximum;
static uint32_t failure;
static uint32_t stage;
static uint32_t commands;

static inline uint32_t read_status()
{
    uint32_t status;
    asm volatile ("csrr %0, 0x7C8" : "=r"(status) : : "memory");
    return status;
}

static bool check(uint32_t index, uint32_t expected, uint32_t actual)
{
    if (expected == actual) {
        return true;
    }
    PIO32 = 0xEE20u;
    PIO32 = stage;
    PIO32 = index;
    PIO32 = expected;
    PIO32 = actual;
    failure = 0xDEAD0000u | stage;
    return false;
}

static void acknowledge(bool clear)
{
    CSR_WRITE(0x7C0, CONFIG | STATE_RESET | (clear ? CLEAR : 0u));
    CSR_WRITE(0x7C0, CONFIG);
}

// ============================================================
// 独立したCPU参照計算: gemmlowpの2段階丸め方式
// ============================================================
static int32_t requantize(int32_t value, uint32_t col)
{
    const uint32_t left = shift[col] > 0 ? static_cast<uint32_t>(shift[col]) : 0u;
    const uint32_t right = shift[col] < 0 ? static_cast<uint32_t>(-shift[col]) : 0u;
    const int32_t lhs = static_cast<int32_t>(static_cast<uint32_t>(value) << left);
    int32_t high;
    if (lhs == INT_MINIMUM && multiplier[col] == INT_MINIMUM) {
        high = 2147483647;
    } else {
        const int64_t product = static_cast<int64_t>(lhs) * multiplier[col];
        const int64_t nudge = product >= 0 ? (int64_t{1} << 30)
                                          : 1 - (int64_t{1} << 30);
        high = static_cast<int32_t>((product + nudge) / (int64_t{1} << 31));
    }
    const uint32_t mask = (uint32_t{1} << right) - 1u;
    const uint32_t remainder = static_cast<uint32_t>(high) & mask;
    const uint32_t threshold = (mask >> 1) + (high < 0 ? 1u : 0u);
    const int32_t rounded = (high >> right) + (remainder > threshold ? 1 : 0);
    const int32_t offset = static_cast<int32_t>(static_cast<uint32_t>(rounded)
                                            + static_cast<uint32_t>(output_zero));
    return offset < minimum ? minimum : offset > maximum ? maximum : offset;
}

static int8_t input_value(uint32_t row, uint32_t k)
{
    // 空間方向のパディングは入力ゼロ点で表現し、1行全体をパディングする場合も含める。
    if (row == 3u || k % 13u == 0u) {
        return static_cast<int8_t>(INPUT_ZERO);
    }
    return static_cast<int8_t>(static_cast<int32_t>((row * 37u + k * 19u) % 31u) - 15);
}

static int8_t weight_value(uint32_t k, uint32_t col)
{
    return static_cast<int8_t>(static_cast<int32_t>((k * 7u + col * 11u) % 17u) - 8);
}

static int32_t bias_value(uint32_t col)
{
    return static_cast<int32_t>(col) * 17 - 23;
}

static void prepare(uint32_t depth)
{
    for (uint32_t col = 0u; col < 4u; ++col) {
        int32_t weight_sum = 0;
        for (uint32_t k = 0u; k < depth; ++k) {
            weight_sum += weight_value(k, col);
        }
        initial[col] = bias_value(col) - INPUT_ZERO * weight_sum;
        multiplier[col] = (col & 1u) != 0u ? 0x60000000 : 0x40000000;
        shift[col] = static_cast<int32_t>(col) - 2;
    }
    output_zero = -7;
    minimum = -101;
    maximum = 99;
}

static void write_block()
{
    *reinterpret_cast<volatile uint32_t*>(C_BASE - 4u) = GUARD;
    *reinterpret_cast<volatile uint32_t*>(C_BASE + 80u) = GUARD;
    for (uint32_t col = 0u; col < 4u; ++col) {
        params[col] = initial[col];
        params[4u + col] = multiplier[col];
        params[8u + col] = shift[col];
    }
    params[12] = output_zero;
    params[13] = minimum;
    params[14] = maximum;
    params[15] = 0;
    for (uint32_t i = 0u; i < 16u; ++i) {
        output[i] = 85;
    }
}

static void pack(uint32_t rows, uint32_t depth, uint32_t base, uint32_t length)
{
    for (uint32_t row = 0u; row < rows; ++row) {
        for (uint32_t k = 0u; k < length; ++k) {
            matrix_a[row * length + k] = base + k < depth ? input_value(row, base + k) : int8_t{0};
        }
    }
    for (uint32_t k = 0u; k < length; ++k) {
        for (uint32_t col = 0u; col < 4u; ++col) {
            matrix_b[k * 4u + col] = base + k < depth ? weight_value(base + k, col) : int8_t{0};
        }
    }
}

// ============================================================
// コマンド実行: 応答または未完了要求の処理終了までNPUの所有権を保持する
// ============================================================
static bool execute(uint32_t command, uint32_t rows, uint32_t length,
                    uint32_t expected_status, bool mutate_csrs = false)
{
    acknowledge(false);
    CSR_WRITE(0x7D0, reinterpret_cast<uintptr_t>(matrix_a));
    CSR_WRITE(0x7D4, reinterpret_cast<uintptr_t>(matrix_b));
    CSR_WRITE(0x7D8, C_BASE);
    CSR_WRITE(0x7C4, (rows << 16) | (4u << 8) | length);
    asm volatile ("fence rw, rw" : : : "memory");
    CSR_WRITE(0x7C0, CONFIG | (command << 8) | START);
    ++commands;
    if (mutate_csrs) {
        // 受付済みコマンドが、受付時にラッチしたサイズとアドレスを使用することを確認する。
        asm volatile ("nop; nop" : : : "memory");
        CSR_WRITE(0x7C4, 0u);
        CSR_WRITE(0x7D0, 0u);
        CSR_WRITE(0x7D4, 0u);
        CSR_WRITE(0x7D8, 0u);
    }
    uint32_t status = 0u;
    for (uint32_t poll = 0u; poll < POLL_LIMIT; ++poll) {
        status = read_status();
        if ((status & DONE) != 0u) {
            break;
        }
    }
    if ((status & DONE) == 0u) {
        CSR_WRITE(0x7C0, CONFIG | STATE_RESET | CLEAR);
        for (uint32_t poll = 0u; poll < POLL_LIMIT; ++poll) {
            if ((read_status() & (BUSY | ACC_VALID)) == 0u) {
                break;
            }
        }
        // 未完了要求の処理終了を確認できなくてもテストを終了し、バッファ再利用や代替経路への切替は行わない。
        return check(0x100u, DONE, status & DONE);
    }
    asm volatile ("fence rw, rw" : : : "memory");
    if (!check(0x101u, CAPABILITY | expected_status, status)) {
        return false;
    }
    // startをhighに保ち、再実行されず完了状態が維持されることを確認する。
    for (uint32_t i = 0u; i < 16u; ++i) {
        if (!check(0x102u, status, read_status())) {
            return false;
        }
    }
    acknowledge(false);
    // state_resetはdone/errorを解除するが、部分累積値は保持する。
    return check(0x103u, CAPABILITY | (expected_status & ACC_VALID), read_status());
}

static bool check_guards(uint32_t valid_bytes)
{
    if (!check(0x110u, GUARD, *reinterpret_cast<volatile uint32_t*>(C_BASE - 4u)) ||
        !check(0x111u, GUARD, *reinterpret_cast<volatile uint32_t*>(C_BASE + 80u))) {
        return false;
    }
    for (uint32_t i = valid_bytes; i < 16u; ++i) {
        if (!check(0x120u + i, 85u, static_cast<uint8_t>(output[i]))) {
            return false;
        }
    }
    for (uint32_t col = 0u; col < 4u; ++col) {
        if (!check(0x140u + col, static_cast<uint32_t>(initial[col]), static_cast<uint32_t>(params[col])) ||
            !check(0x144u + col, static_cast<uint32_t>(multiplier[col]), static_cast<uint32_t>(params[4u + col])) ||
            !check(0x148u + col, static_cast<uint32_t>(shift[col]), static_cast<uint32_t>(params[8u + col]))) {
            return false;
        }
    }
    return true;
}

static bool run_tile(uint32_t rows, uint32_t depth, uint32_t segment)
{
    prepare(depth);
    write_block();
    const uint32_t padded = (depth + 3u) & ~3u;
    const uint32_t before = commands;
    for (uint32_t base = 0u; base < padded; base += segment) {
        const uint32_t length = padded - base < segment ? padded - base : segment;
        const bool last = base + length == padded;
        const uint32_t command = padded <= segment ? SINGLE
                               : base == 0u ? FIRST : last ? LAST : CONTINUE;
        pack(rows, depth, base, length);
        if (!execute(command, rows, length, DONE | (last ? 0u : ACC_VALID), true) ||
            !check_guards(last ? rows * 4u : 0u)) {
            return false;
        }
    }
    if (!check(0x150u, (padded + segment - 1u) / segment, commands - before)) {
        return false;
    }
    for (uint32_t row = 0u; row < rows; ++row) {
        for (uint32_t col = 0u; col < 4u; ++col) {
            // 初期累積値の補正とは独立に、（入力値－入力ゼロ点）を直接計算する。
            int32_t acc = bias_value(col);
            for (uint32_t k = 0u; k < depth; ++k) {
                acc += (static_cast<int32_t>(input_value(row, k)) - INPUT_ZERO)
                     * static_cast<int32_t>(weight_value(k, col));
            }
            if (!check(row * 4u + col, static_cast<uint32_t>(requantize(acc, col)),
                       static_cast<uint32_t>(static_cast<int32_t>(output[row * 4u + col])))) {
                return false;
            }
        }
    }
    return true;
}

static bool rounding_case(bool left_shift)
{
    static const int32_t expected[2][4] = {{-1, 0, 127, -1}, {3, -3, 0, 127}};
    initial[0] = left_shift ? 3 : -3;
    initial[1] = left_shift ? -3 : -1;
    initial[2] = INT_MINIMUM;
    initial[3] = left_shift ? 2147483647 : INT_MINIMUM;
    for (uint32_t col = 0u; col < 4u; ++col) {
        multiplier[col] = !left_shift && col == 2u ? INT_MINIMUM : 0x40000000;
        shift[col] = left_shift ? (col == 3u ? 0 : 1)
                               : col == 0u ? -1 : col == 3u ? -31 : 0;
        matrix_a[col] = 0;
    }
    for (uint32_t i = 0u; i < 16u; ++i) {
        matrix_b[i] = 0;
    }
    output_zero = 0;
    minimum = -128;
    maximum = 127;
    write_block();
    if (!execute(SINGLE, 1u, 4u, DONE) || !check_guards(4u)) {
        return false;
    }
    for (uint32_t col = 0u; col < 4u; ++col) {
        const uint32_t wanted = static_cast<uint32_t>(expected[left_shift ? 1 : 0][col]);
        if (!check(col, wanted, static_cast<uint32_t>(requantize(initial[col], col))) ||
            !check(col, wanted, static_cast<uint32_t>(static_cast<int32_t>(output[col])))) {
            return false;
        }
    }
    return true;
}

static bool sequence_cases()
{
    acknowledge(true);
    prepare(4u);
    write_block();
    pack(4u, 4u, 0u, 4u);
    if (!execute(CONTINUE, 4u, 4u, DONE | ERROR) || !check_guards(0u) ||
        !execute(LAST, 4u, 4u, DONE | ERROR) || !check_guards(0u)) {
        return false;
    }
    acknowledge(true);
    if (!check(0x160u, CAPABILITY, read_status()) ||
        !execute(FIRST, 4u, 4u, DONE | ACC_VALID) || !check_guards(0u)) {
        return false;
    }
    acknowledge(true);
    if (!check(0x161u, CAPABILITY, read_status()) ||
        !execute(LAST, 4u, 4u, DONE | ERROR) || !check_guards(0u)) {
        return false;
    }
    // FIRSTは前のFIRSTによる累積を置き換え、バイアスや初期累積値を二重加算しない。
    if (!execute(FIRST, 4u, 4u, DONE | ACC_VALID)) {
        return false;
    }
    return run_tile(4u, 12u, 4u);
}

// ============================================================
// テスト開始処理
// ============================================================
static bool run_tests()
{
    stage = 1u;
    if (!check(0u, CAPABILITY, read_status() & CAPABILITY)) {
        return false;
    }
    acknowledge(true);
    static const uint32_t cases[5][3] = {
        {1u,    7u, 252u},
        {3u,   68u, 252u},
        {4u,  252u, 252u},
        {4u,   12u,   4u},
        {4u, 2304u, 252u}
    };
    for (uint32_t i = 0u; i < 5u; ++i) {
        stage = i + 2u;
        if (!run_tile(cases[i][0], cases[i][1], cases[i][2])) {
            return false;
        }
    }
    stage = 7u;
    if (!rounding_case(false)) {
        return false;
    }
    stage = 8u;
    if (!rounding_case(true)) {
        return false;
    }
    stage = 9u;
    return sequence_cases();
}

extern "C" void run()
{
    if (run_tests()) {
        acknowledge(true);
    }
    PIO32 = 0xEE30u;
    PIO32 = commands;
    PIO32 = 0xEE01u;
    PIO32 = failure == 0u ? 0xBEEFu : failure;
    while (true) {
        asm volatile ("nop");
    }
}
