#include <cstdint>

/* ============================================================
   Timer MMIO
   ============================================================ */
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
static constexpr uint32_t MATRIX_SIZE   = 32u;

// この入力パターンによる8×8行列積の全要素チェックサム
static constexpr uint32_t EXPECTED_CHECKSUM =
    //0x00006380u;    // 8x8
    //0x00038400u;    // 16x16
    0x001C2000u;    // 32x32
    //0x00657FA5u;    // 64x64

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
// Matrix Data
// ============================================================

alignas(4)
static uint8_t matrix_a[MATRIX_SIZE][MATRIX_SIZE];

alignas(4)
static uint8_t matrix_b[MATRIX_SIZE][MATRIX_SIZE];

alignas(4)
static uint32_t matrix_cpu_c[MATRIX_SIZE][MATRIX_SIZE];

// ============================================================
// Matrix Initialization
//
// A[row][col] = (row + col) & 0x0F
// B[row][col] = (row * 3 + col) & 0x0F
// ============================================================

static void initialize_matrices()
{
    for (uint32_t row = 0u;
         row < MATRIX_SIZE;
         ++row) {

        for (uint32_t col = 0u;
             col < MATRIX_SIZE;
             ++col) {

            matrix_a[row][col] =
                static_cast<uint8_t>(
                    (row + col) & 0x0Fu
                );

            matrix_b[row][col] =
                static_cast<uint8_t>(
                    ((row * 3u) + col) & 0x0Fu
                );
        }
    }
}

// ============================================================
// SA Control
// ============================================================

static constexpr uint32_t sa_command(
    uint32_t command)
{
    return
        (MATRIX_SIZE << 24) | (MATRIX_SIZE << 16) |
        command;
}

static inline void sa_clear()
{
    CSR_WRITE(0x7C0, sa_command(0x04u));
    CSR_WRITE(0x7C0, sa_command(0x00u));
}

static inline void sa_state_reset()
{
    CSR_WRITE(0x7C0, sa_command(0x02u));
    CSR_WRITE(0x7C0, sa_command(0x00u));
}

static inline void sa_start()
{
    CSR_WRITE(0x7C0, sa_command(0x01u));
    CSR_WRITE(0x7C0, sa_command(0x00u));
}

static inline void sa_wait_done()
{
    while ((CSR_READ(0x7C8) & 0x01u) == 0u) {
        asm volatile("nop");
    }
}

static inline void sa_set_A(
    const uint8_t A[MATRIX_SIZE][MATRIX_SIZE])
{
    const uintptr_t address =
        reinterpret_cast<uintptr_t>(&A[0][0]);

    CSR_WRITE(0x7D0, address);
}

static inline void sa_set_B(
    const uint8_t B[MATRIX_SIZE][MATRIX_SIZE])
{
    const uintptr_t address =
        reinterpret_cast<uintptr_t>(&B[0][0]);

    CSR_WRITE(0x7D4, address);
}

static inline volatile const uint32_t*
sa_c_base()
{
    return reinterpret_cast<
        volatile const uint32_t*
    >(SA_BASE_ADDR_C);
}

// ============================================================
// CPU Reference
// ============================================================

static uint32_t matmul_cpu()
{
    uint32_t checksum = 0u;

    for (uint32_t row = 0u;
         row < MATRIX_SIZE;
         ++row) {

        for (uint32_t col = 0u;
             col < MATRIX_SIZE;
             ++col) {

            uint32_t acc = 0u;

            for (uint32_t k = 0u;
                 k < MATRIX_SIZE;
                 ++k) {

                acc +=
                    static_cast<uint32_t>(
                        matrix_a[row][k]
                    ) *
                    static_cast<uint32_t>(
                        matrix_b[k][col]
                    );
            }

            matrix_cpu_c[row][col] = acc;
            checksum += acc;
        }
    }

    return checksum;
}

// ============================================================
// SA Matrix Multiplication
// ============================================================

static void matmul_sa()
{
    sa_clear();

    sa_set_A(matrix_a);
    sa_set_B(matrix_b);

    sa_state_reset();
    sa_start();

    sa_wait_done();
}

// ============================================================
// SA Result Check
//
// 戻り値:
//   0     : 全要素一致
//   1以上 : 最初に不一致になった要素番号 + 1
// ============================================================

static uint32_t compare_cpu_and_sa(
    uint32_t& sa_checksum)
{
    volatile const uint32_t* const sa_c =
        sa_c_base();

    sa_checksum = 0u;

    for (uint32_t row = 0u;
         row < MATRIX_SIZE;
         ++row) {

        for (uint32_t col = 0u;
             col < MATRIX_SIZE;
             ++col) {

            const uint32_t index =
                (row * MATRIX_SIZE) + col;

            const uint32_t sa_value =
                sa_c[index];

            const uint32_t cpu_value =
                matrix_cpu_c[row][col];

            sa_checksum += sa_value;

            if (sa_value != cpu_value) {
                return index + 1u;
            }
        }
    }

    return 0u;
}

// ============================================================
// Selected Result Output
// ============================================================

static void output_sample_values()
{
    volatile const uint32_t* const sa_c =
        sa_c_base();

    PIO32 = 0xEE10u;

    // C[0][0] = 212 = 0x000000D4
    PIO32 = sa_c[0u];

    // C[0][1] = 160 = 0x000000A0
    PIO32 = sa_c[1u];

    // C[1][0] = 264 = 0x00000108
    PIO32 = sa_c[MATRIX_SIZE];

    // C[4][4]
    PIO32 =
        sa_c[(4u * MATRIX_SIZE) + 4u];

    // C[7][7] = 636 = 0x0000027C
    PIO32 =
        sa_c[
            ((MATRIX_SIZE - 1u) * MATRIX_SIZE)
            + (MATRIX_SIZE - 1u)
        ];
}

// ============================================================
// Entry
// ============================================================

extern "C" void run()
{
    PIO32 = 0xEE11u;
    PIO32 = MATRIX_SIZE;

    // C行列出力先
    CSR_WRITE(0x7D8, SA_BASE_ADDR_C);

    // SA有効化
    CSR_WRITE(0x7C4, 0x01u);

    initialize_matrices();

    bool ok = true;

    // --------------------------------------------------------
    // CPU calculation
    // --------------------------------------------------------
    PIO32 = 0xEE21u;

    /*
     * Software reference
     */
    TIMER_MMIOADDR_W = 0x0001FFFFu;

    const uint32_t cpu_checksum =
        matmul_cpu();

    timer_data = TIMER_MMIOADDR_R;

    /*
     * Software実行時間
     */
    PIO32 = 0x0000A001u;
    PIO32 = 0xFFFFu - timer_data;

    PIO32 = 0xEE20u;
    PIO32 = cpu_checksum;

    // --------------------------------------------------------
    // SA calculation
    // --------------------------------------------------------
    PIO32 = 0xEE31u;

    /*
     * SynapEngine
     */
    TIMER_MMIOADDR_W = 0x0001FFFFu;

    matmul_sa();

    timer_data = TIMER_MMIOADDR_R;

    /*
     * SA実行時間
     */
    PIO32 = 0x0000A002u;
    PIO32 = 0xFFFFu - timer_data;

    uint32_t sa_checksum = 0u;

    const uint32_t mismatch_index =
        compare_cpu_and_sa(sa_checksum);

    PIO32 = 0xEE30u;
    PIO32 = sa_checksum;

    output_sample_values();

    // --------------------------------------------------------
    // Check
    // --------------------------------------------------------
    if (cpu_checksum != EXPECTED_CHECKSUM) {
        PIO32 = 0xDEAD0001u;
        PIO32 = cpu_checksum;
        ok = false;
    }

    if (sa_checksum != EXPECTED_CHECKSUM) {
        PIO32 = 0xDEAD0002u;
        PIO32 = sa_checksum;
        ok = false;
    }

    if (cpu_checksum != sa_checksum) {
        PIO32 = 0xDEAD0003u;
        ok = false;
    }

    if (mismatch_index != 0u) {
        PIO32 = 0xDEAD0004u;
        PIO32 = mismatch_index;
        ok = false;
    }

    result = sa_checksum;

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
// Global Result
// ============================================================

extern "C" {

volatile uint32_t result = 0u;
volatile uint32_t timer_data = 0;

}