#include <cstdint>

/* ============================================================
   Timer MMIO
   ============================================================ */
#define TIMER_MMIOADDR_W \
    (*reinterpret_cast<volatile uint32_t*>(0x10002000u))

#define TIMER_MMIOADDR_R \
    (*reinterpret_cast<volatile uint32_t*>(0x10002004u))

extern "C" volatile uint32_t timer_data;

/* ============================================================
   SynapEngine CSR / Address
   ============================================================ */

// CSR
// 0x7C0 : SA Control
//          bit[0]     start
//          bit[1]     state reset
//          bit[2]     clear
//          bit[11:8]  instruction
//          bit[23:16] matrix size
//
// 0x7C8 : SA Status
//          bit[0] done
//          bit[1] busy
//
// 0x7D0 : Matrix A address
// 0x7D4 : Matrix B address
// 0x7D8 : Matrix C address

#define SA_BASE_ADDR_C 0x00022000u

/* ============================================================
   PIO
   ============================================================ */

#define PIO32 \
    (*reinterpret_cast<volatile uint32_t*>(0x10001000u))

static constexpr uint32_t TEST_END_CODE = 0x0000EE01u;

/* ============================================================
   Matrix configuration
   ============================================================ */

static constexpr uint32_t MATRIX_SIZE = 8u;

static constexpr uint32_t SA_CTRL_CONFIG =
    MATRIX_SIZE << 24 | MATRIX_SIZE << 16;

/* ============================================================
   CSR helpers
   ============================================================ */

#define CSR_WRITE(csr, val) \
    asm volatile ("csrw " #csr ", %0" :: "r"(val))

#define CSR_READ(csr) \
    ([&]() -> uint32_t { \
        uint32_t value; \
        asm volatile ("csrr %0, " #csr : "=r"(value)); \
        return value; \
    }())

/* ============================================================
   Test matrices

   uint8_t A[8][8]
   uint8_t B[8][8]

   メモリ上は行優先で、1行8バイト。
   RTL側が4×4タイル単位に読み出す。
   ============================================================ */

static const uint8_t A_mat[MATRIX_SIZE][MATRIX_SIZE] = {
    {1, 2, 1, 3, 2, 1, 4, 2},
    {3, 3, 1, 2, 1, 2, 3, 1},
    {3, 1, 1, 2, 4, 2, 1, 3},
    {1, 3, 1, 2, 2, 3, 2, 1},

    {2, 1, 3, 1, 3, 2, 1, 2},
    {1, 4, 2, 3, 1, 3, 2, 2},
    {3, 2, 4, 1, 2, 1, 3, 4},
    {2, 1, 2, 4, 3, 2, 1, 3}
};

static const uint8_t B_mat[MATRIX_SIZE][MATRIX_SIZE] = {
    {1, 2, 1, 2, 3, 1, 2, 1},
    {3, 2, 1, 2, 1, 3, 2, 2},
    {3, 1, 3, 1, 2, 2, 1, 4},
    {1, 3, 1, 2, 2, 1, 3, 2},

    {2, 1, 4, 3, 1, 2, 2, 1},
    {1, 2, 2, 1, 3, 4, 1, 2},
    {4, 1, 1, 2, 2, 3, 4, 1},
    {2, 3, 2, 1, 1, 2, 3, 4}
};

/* ============================================================
   Result buffers
   ============================================================ */

static uint32_t C_sw[MATRIX_SIZE][MATRIX_SIZE];
static uint32_t C_sa[MATRIX_SIZE][MATRIX_SIZE];

/* ============================================================
   Software reference matrix multiply
   ============================================================ */

static void matmul8x8_sw(
    const uint8_t A[MATRIX_SIZE][MATRIX_SIZE],
    const uint8_t B[MATRIX_SIZE][MATRIX_SIZE],
    uint32_t C[MATRIX_SIZE][MATRIX_SIZE])
{
    for (uint32_t i = 0; i < MATRIX_SIZE; ++i) {
        for (uint32_t j = 0; j < MATRIX_SIZE; ++j) {
            uint32_t sum = 0;

            for (uint32_t k = 0; k < MATRIX_SIZE; ++k) {
                sum +=
                    static_cast<uint32_t>(A[i][k]) *
                    static_cast<uint32_t>(B[k][j]);
            }

            C[i][j] = sum;
        }
    }
}

/* ============================================================
   Read SA result

   Cは次の形式。

       uint32_t C[8][8]

   メモリ上の要素間隔は4バイト。
   ============================================================ */

static void sa_read_result_matrix(
    uint32_t out[MATRIX_SIZE][MATRIX_SIZE])
{
    volatile const uint32_t* const result =
        reinterpret_cast<volatile const uint32_t*>(
            SA_BASE_ADDR_C
        );

    for (uint32_t i = 0; i < MATRIX_SIZE; ++i) {
        for (uint32_t j = 0; j < MATRIX_SIZE; ++j) {
            out[i][j] =
                result[i * MATRIX_SIZE + j];
        }
    }
}

/* ============================================================
   SA result verification
   ============================================================ */

static bool verify_sa_result(
    const uint32_t expected[MATRIX_SIZE][MATRIX_SIZE],
    const uint32_t actual[MATRIX_SIZE][MATRIX_SIZE])
{
    bool result = true;

    for (uint32_t i = 0; i < MATRIX_SIZE; ++i) {
        for (uint32_t j = 0; j < MATRIX_SIZE; ++j) {
            if (expected[i][j] != actual[i][j]) {
                const uint32_t error_code =
                    0xDEAD0000u |
                    ((i & 0xFFu) << 8) |
                    (j & 0xFFu);

                PIO32 = error_code;

                // 期待値
                PIO32 = expected[i][j];

                // SA結果
                PIO32 = actual[i][j];

                result = false;
            }
        }
    }

    return result;
}

/* ============================================================
   SA execution
   ============================================================ */

static void run_sa_8x8()
{
    const uintptr_t addr_a =
        reinterpret_cast<uintptr_t>(&A_mat[0][0]);

    const uintptr_t addr_b =
        reinterpret_cast<uintptr_t>(&B_mat[0][0]);

    /*
     * A/B/Cの先頭アドレスを設定
     */
    CSR_WRITE(
        0x7D0,
        static_cast<uint32_t>(addr_a)
    );

    CSR_WRITE(
        0x7D4,
        static_cast<uint32_t>(addr_b)
    );

    CSR_WRITE(
        0x7D8,
        SA_BASE_ADDR_C
    );

    /*
     * FSMをIDLEへ戻す
     *
     * matrix_sizeの上位ビットは必ず維持する。
     */
    CSR_WRITE(
        0x7C0,
        SA_CTRL_CONFIG | 0x02u
    );

    CSR_WRITE(
        0x7C0,
        SA_CTRL_CONFIG
    );

    /*
     * SA内部アキュムレータをクリア
     */
    CSR_WRITE(
        0x7C0,
        SA_CTRL_CONFIG | 0x04u
    );

    CSR_WRITE(
        0x7C0,
        SA_CTRL_CONFIG
    );

    /*
     * 8×8行列積を開始
     *
     * RTL内部で以下を実行する。
     *
     * i_idx = 0, 1
     * j_idx = 0, 1
     * k_idx = 0, 1
     *
     * 4×4タイル積は合計8回。
     */
    CSR_WRITE(
        0x7C0,
        SA_CTRL_CONFIG | 0x01u
    );

    CSR_WRITE(
        0x7C0,
        SA_CTRL_CONFIG
    );

    /*
     * done待ち
     */
    while ((CSR_READ(0x7C8) & 0x01u) == 0u) {
        asm volatile("nop");
    }
}

/* ============================================================
   Test entry
   ============================================================ */

extern "C" void run()
{
    bool ok;

    /*
     * Software reference
     */
    TIMER_MMIOADDR_W = 0x00010FFFu;

    matmul8x8_sw(
        A_mat,
        B_mat,
        C_sw
    );

    timer_data = TIMER_MMIOADDR_R;

    /*
     * Software実行時間
     */
    PIO32 = 0x0000A001u;
    PIO32 = 0xFFFu - timer_data;

    /*
     * SynapEngine
     */
    TIMER_MMIOADDR_W = 0x00010FFFu;

    run_sa_8x8();

    timer_data = TIMER_MMIOADDR_R;

    /*
     * SA実行時間
     */
    PIO32 = 0x0000A002u;
    PIO32 = 0xFFFu - timer_data;

    /*
     * SA結果を読み出す
     */
    sa_read_result_matrix(C_sa);

#if 0
    /*
     * デバッグ表示
     *
     * 各要素について、
     * SA結果 → SW結果の順でPIOへ出力する。
     */
    PIO32 = 0x0000AB01u;

    for (uint32_t i = 0; i < MATRIX_SIZE; ++i) {
        for (uint32_t j = 0; j < MATRIX_SIZE; ++j) {
            PIO32 = C_sa[i][j];
            PIO32 = C_sw[i][j];
        }
    }

    PIO32 = 0x0000ABE1u;
#endif

    /*
     * 結果比較
     */
    ok = verify_sa_result(
        C_sw,
        C_sa
    );

    /*
     * Test result
     */
    PIO32 = TEST_END_CODE;

    if (ok) {
        PIO32 = 0x0000BEEFu;
    } else {
        PIO32 = 0x0000DEADu;
    }

    while (1) {
        asm volatile("nop");
    }
}

/* ============================================================
   Global definition
   ============================================================ */

extern "C" {
    volatile uint32_t timer_data = 0;
}