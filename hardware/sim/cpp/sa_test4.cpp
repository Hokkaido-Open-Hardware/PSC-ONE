#include <cstdint>

/* ---------- タイマーW ---------- */
#define TIMER_MMIOADDR_W \
    (*reinterpret_cast<volatile uint32_t*>(0x10002000u))

/* ---------- タイマーR ---------- */
#define TIMER_MMIOADDR_R \
    (*reinterpret_cast<volatile uint32_t*>(0x10002004u))

/* ---------- 宣言（extern：初期化しない） ---------- */
extern "C" volatile uint32_t timer_data;


// ============================================================
// SynapEngine CSR
// ============================================================
//
// CSR 0x7C0 : SA Control
//
//   bit 0 : start
//   bit 1 : state_reset
//   bit 3 : signed_mode
//
//   [23:16] : matrix_size_x
//   [31:24] : matrix_size_y
//
// CSR 0x7C4 : SA Mode
// CSR 0x7C8 : SA Status
//
// signed_mode:
//   0 = unsigned INT8
//   1 = signed INT8
//
// RTL:
//   wire signed_mode = csr_SA_CTRL[3];
//
// ============================================================

#define SA_BASE_ADDR_A      0x020000
#define SA_BASE_ADDR_B      0x021000
#define SA_BASE_ADDR_C      0x022000


// ============================================================
// PIO
// ============================================================

#define PIO32 \
    (*reinterpret_cast<volatile uint32_t*>(0x10001000u))

#define BASE_ADDR \
    (*reinterpret_cast<volatile uint32_t*>(0x00020000u))

static constexpr uint32_t TEST_END_CODE = 0xEE01;


// ============================================================
// CSR Write Helper
// ============================================================

#define CSR_WRITE(csr, val) \
    asm volatile ("csrw " #csr ", %0" :: "r"(val))


// ============================================================
// CSR Read Helper
// ============================================================

#define CSR_READ(csr) \
    ([&]() -> uint32_t { \
        uint32_t val; \
        asm volatile ("csrr %0, " #csr : "=r"(val)); \
        return val; \
    }())


// ============================================================
// SA Control values
// ============================================================

static constexpr uint32_t SA_MATRIX_SIZE =
    (0x04u << 24) |
    (0x04u << 16);

static constexpr uint32_t SA_SIGNED_MODE =
    (1u << 3);

static constexpr uint32_t SA_START =
    (1u << 0);

static constexpr uint32_t SA_STATE_RESET =
    (1u << 1);


// ============================================================
// Small delay
// ============================================================

static inline void tiny_delay(unsigned n)
{
    while (n--) {
        asm volatile("nop");
    }
}


// ============================================================
// SA Result Read
// ============================================================
//
// signed INT8 MAC の結果は signed 32bit として読み出す。
// ============================================================

static inline void sa_read_result_matrix(
    int32_t out[16])
{
    volatile int32_t* const result =
        reinterpret_cast<volatile int32_t*>(
            SA_BASE_ADDR_C
        );

    for (int i = 0; i < 16; i++) {
        out[i] = result[i];
    }
}


// ============================================================
// Software Reference Matrix Multiply
// ============================================================
//
// signed INT8 4x4 matrix multiply
//
//     C[i][j] = SUM A[i][k] * B[k][j]
//
// int8 x int8
//     ↓
// int32 accumulator
//
// ============================================================

static inline void matmul_sw(
    const int8_t A[4][4],
    const int8_t B[4][4],
    int32_t Csw[4][4])
{
    for (int i = 0; i < 4; i++) {

        for (int j = 0; j < 4; j++) {

            int32_t sum = 0;

            for (int k = 0; k < 4; k++) {

                sum +=
                    static_cast<int32_t>(A[i][k])
                    *
                    static_cast<int32_t>(B[k][j]);
            }

            Csw[i][j] = sum;
        }
    }
}


// ============================================================
// SA Result Verification
// ============================================================

static inline bool verify_sa_result(
    const int32_t Csw[4][4],
    const int32_t Csa[16])
{
    for (int i = 0; i < 4; i++) {

        for (int j = 0; j < 4; j++) {

            const int32_t v_sw =
                Csw[i][j];

            const int32_t v_sa =
                Csa[i * 4 + j];

            if (v_sw != v_sa) {

                const uint32_t err_code =
                    0xDEAD0000u
                    |
                    static_cast<uint32_t>(
                        i * 4 + j
                    );

                PIO32 = err_code;

                // Software result
                PIO32 =
                    static_cast<uint32_t>(v_sw);

                // SynapEngine result
                PIO32 =
                    static_cast<uint32_t>(v_sa);

                return false;
            }
        }
    }

    return true;
}


// ============================================================
// Signed INT8 test matrices
// ============================================================
//
// 正負を混ぜ、-128 / 127 付近も一部使用する。
// ============================================================

static const int8_t A_mat[4][4] = {

    {   1,   -2,    3,   -4 },

    { -10,   20,  -30,   40 },

    { 127,   -1, -128,    2 },

    { -64,   32,  -16,    8 }
};


static const int8_t B_mat[4][4] = {

    {   2,   -3,    4,   -5 },

    {  -6,    7,   -8,    9 },

    {  10,  -11,   12,  -13 },

    { -14,   15,  -16,   17 }
};


// ============================================================
// Test Entry
// ============================================================

extern "C" void run()
{
    // --------------------------------------------------------
    // 0. Result address
    // --------------------------------------------------------

    CSR_WRITE(
        0x7D8,
        SA_BASE_ADDR_C
    );


    // --------------------------------------------------------
    // 1. A/B matrix address
    // --------------------------------------------------------

    const uintptr_t addr_a =
        reinterpret_cast<uintptr_t>(
            &A_mat[0][0]
        );

    const uintptr_t addr_b =
        reinterpret_cast<uintptr_t>(
            &B_mat[0][0]
        );

    CSR_WRITE(
        0x7D0,
        static_cast<uint32_t>(addr_a)
    );

    CSR_WRITE(
        0x7D4,
        static_cast<uint32_t>(addr_b)
    );


    // --------------------------------------------------------
    // 2. Software reference
    // --------------------------------------------------------

    int32_t Csw[4][4];

    TIMER_MMIOADDR_W = 0x100FF;

    matmul_sw(
        A_mat,
        B_mat,
        Csw
    );

    timer_data = TIMER_MMIOADDR_R;

    PIO32 = 0xFF - timer_data;


#if 0

    // --------------------------------------------------------
    // SW result debug
    // --------------------------------------------------------

    for (uint32_t i = 0; i < 4; i++) {

        for (uint32_t j = 0; j < 4; j++) {

            PIO32 =
                static_cast<uint32_t>(
                    Csw[i][j]
                );
        }
    }

#endif


    // --------------------------------------------------------
    // 3. SA state reset
    // --------------------------------------------------------
    //
    // IMPORTANT:
    // signed_mode = bit3
    //
    // state_resetを操作している間も
    // signed_mode bitを1に保つ。
    //
    // --------------------------------------------------------

    CSR_WRITE(
        0x7C0,
        SA_MATRIX_SIZE
        |
        SA_SIGNED_MODE
        |
        SA_STATE_RESET
    );

    CSR_WRITE(
        0x7C0,
        SA_MATRIX_SIZE
        |
        SA_SIGNED_MODE
    );


    // --------------------------------------------------------
    // 4. Output-Stationary mode
    // --------------------------------------------------------

    CSR_WRITE(
        0x7C4,
        0x01
    );


    // --------------------------------------------------------
    // 5. SA start
    // --------------------------------------------------------

    TIMER_MMIOADDR_W = 0x100FF;

    CSR_WRITE(
        0x7C0,
        SA_MATRIX_SIZE
        |
        SA_SIGNED_MODE
        |
        SA_START
    );

    CSR_WRITE(
        0x7C0,
        SA_MATRIX_SIZE
        |
        SA_SIGNED_MODE
    );


    // --------------------------------------------------------
    // 6. Wait for SynapEngine completion
    // --------------------------------------------------------

    while (
        (CSR_READ(0x7C8) & 0x01u)
        !=
        0x01u
    ) {
        asm volatile("nop");
    }


    // --------------------------------------------------------
    // 7. Read SA result
    // --------------------------------------------------------

    int32_t Csa[16];

    sa_read_result_matrix(Csa);


    // --------------------------------------------------------
    // Timer
    // --------------------------------------------------------

    timer_data =
        TIMER_MMIOADDR_R;

    PIO32 =
        0xFF - timer_data;


#if 0

    // --------------------------------------------------------
    // SA result debug
    // --------------------------------------------------------

    for (uint32_t i = 0; i < 16; i++) {

        PIO32 =
            static_cast<uint32_t>(
                Csa[i]
            );
    }

#endif


    // --------------------------------------------------------
    // 8. Verify
    // --------------------------------------------------------

    const bool ok =
        verify_sa_result(
            Csw,
            Csa
        );


    // --------------------------------------------------------
    // Test end
    // --------------------------------------------------------

    if (ok) {

        PIO32 = TEST_END_CODE;
        PIO32 = 0xBEEF;

    } else {

        PIO32 = TEST_END_CODE;
        PIO32 = 0xDEAD;
    }


    // --------------------------------------------------------
    // CPU stop
    // --------------------------------------------------------

    while (1) {
    }
}


/* ---------- 定義（実体） ---------- */

extern "C" {
    volatile uint32_t timer_data = 0;
}