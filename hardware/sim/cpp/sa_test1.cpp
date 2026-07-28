#include <cstdint>

/* ---------- タイマーW ---------- */
#define TIMER_MMIOADDR_W (*reinterpret_cast<volatile uint32_t*>(0x10002000u))

/* ---------- タイマーR ---------- */
#define TIMER_MMIOADDR_R (*reinterpret_cast<volatile uint32_t*>(0x10002004u))

/* ---------- 宣言（extern：初期化しない） ---------- */
extern "C" volatile uint32_t timer_data;

// ============================================================
// SynapEngine CSR
// ============================================================
// CSR 0x7C0 : SA Control
// CSR 0x7C4 : SA Status
// ============================================================
#define SA_BASE_ADDR_A      0x020000
#define SA_BASE_ADDR_B      0x021000

#define SA_BASE_ADDR_C      0x022000

// ============================================================
// PIO (テスト用デバッグ出力)
// ============================================================
// PIO32 に書くと cocotb 側でログに出力される
// ============================================================
#define PIO32          (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
#define BASE_ADDR      (*reinterpret_cast<volatile uint32_t*>(0x00020000u))

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
// Small delay (簡易ウェイト)
// ============================================================
static inline void tiny_delay(unsigned n){
    while (n--) {
        asm volatile("nop");
    }
}

// ============================================================
// SA Result Read
// ============================================================
static inline void sa_read_result_matrix(uint16_t out[16])
{
    volatile uint32_t* const result =
        reinterpret_cast<volatile uint32_t*>(SA_BASE_ADDR_C);

    for (int i = 0; i < 16; i++) {
        const uint32_t val32 = result[i];
        out[i] = static_cast<uint16_t>(val32 & 0xFFFFu);
    }
}

// ============================================================
// Software Reference Matrix Multiply
// ============================================================
//
// 4×4 行列積
//
// ============================================================
static inline void matmul_sw(
    const uint8_t A[4][4],
    const uint8_t B[4][4],
    uint16_t Csw[4][4])
{
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {

            int sum = 0;

            for (int k = 0; k < 4; k++) {
                sum += (int)A[i][k] * (int)B[k][j];
            }

            Csw[i][j] = (uint16_t)sum;
        }
    }
}


// ============================================================
// SA Result Verification
// ============================================================
//
// SW計算結果とSA結果を比較
//
// ============================================================
static inline bool verify_sa_result(
    const uint16_t Csw[4][4],
    const uint16_t Csa[16])
{
    uint32_t err_code;

    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {

            uint16_t v_sw = Csw[i][j];
            uint16_t v_sa = Csa[i * 4 + j];

            if (v_sw != v_sa) {
                err_code = 0xDEAD0000 | (uint32_t)(i * 2 + j);
                PIO32 = err_code;
                return false;
            }
        }
    }

    return true;
}

/* ============================================================
      テスト用 A / B 行列
   ============================================================ */
static const uint8_t A_mat[4][4] = {
    {1, 2, 1, 3},
    {3, 3, 1, 2},
    {3, 1, 1, 2},
    {1, 3, 1, 2}
};

static const uint8_t B_mat[4][4] = {
    {1, 2, 1, 2},
    {3, 2, 1, 2},
    {3, 1, 3, 1},
    {1, 3, 1, 2}
};

// ============================================================
// Test Entry
// ============================================================
extern "C" void run() {

    //bool wb;

    // --------------------------------------------------------
    // 0. SA_ADDR_A,B,C設定
    // --------------------------------------------------------
    // csr_SA_ADDR_A,B
    //CSR_WRITE(0x7D0, SA_BASE_ADDR_A);
    //CSR_WRITE(0x7D4, SA_BASE_ADDR_B);
    // csr_SA_ADDR_C
    CSR_WRITE(0x7D8, SA_BASE_ADDR_C);

    // --------------------------------------------------------
    // 0. A/B/C行列の先頭アドレスをSAへ設定
    // --------------------------------------------------------
    const uintptr_t addr_a =
        reinterpret_cast<uintptr_t>(&A_mat[0][0]);

    const uintptr_t addr_b =
        reinterpret_cast<uintptr_t>(&B_mat[0][0]);

    CSR_WRITE(0x7D0, static_cast<uint32_t>(addr_a));
    CSR_WRITE(0x7D4, static_cast<uint32_t>(addr_b));

    // --------------------------------------------------------
    // 3. Software参照計算
    // --------------------------------------------------------
    uint16_t Csw[4][4];

    // TIMER書き込み start
    TIMER_MMIOADDR_W = 0x100FF;

    matmul_sw(A_mat, B_mat, Csw);

    // TIMER読み出し
    timer_data = TIMER_MMIOADDR_R;
    PIO32 = 0xFF - timer_data;

#if 0
    // SW結果をPIOへ出力（デバッグ用）
    for (uint32_t i = 0; i < 4; i++) {
        for (uint32_t j = 0; j < 4; j++) {
            PIO32 = (uint32_t)Csw[i][j];
        }
    }
#endif

    // --------------------------------------------------------
    // 4. SA開始
    // --------------------------------------------------------
    // sa_state_reset
    CSR_WRITE(0x7C0, (0x04 << 24) | (0x04 << 16) | 0x02);
    CSR_WRITE(0x7C0, (0x04 << 24) | (0x04 << 16) | 0x00);
    // sa_mode : OS mode.
    CSR_WRITE(0x7C4, 0x01);
    // sa_start
    //CSR_WRITE(0x7C0, 0x01);   // SA start
    //CSR_WRITE(0x7C0, 0x00);   // clear start

    // TIMER書き込み start
    TIMER_MMIOADDR_W = 0x100FF;

    CSR_WRITE(0x7C0, (0x04 << 24) | (0x04 << 16) | 0x01);   // SA start
    CSR_WRITE(0x7C0, (0x04 << 24) | (0x04 << 16) | 0x00);   // clear start

    // SA計算待ち
    //tiny_delay(100);

    // 0x7C8 = csr_SA_STATUS
    while ((CSR_READ(0x7C8) & 0x01) != 0x01) {
        asm volatile("nop");
    }
    // --------------------------------------------------------
    // 5. SA結果読み出し
    // --------------------------------------------------------
    uint16_t Csa[16];
    sa_read_result_matrix(Csa);

    // TIMER読み出し
    timer_data = TIMER_MMIOADDR_R;
    PIO32 = 0xFF - timer_data;

#if 0
    // SA結果をPIOへ出力
    for (uint32_t i = 0; i < 16; i++) {
        PIO32 = (uint32_t)Csa[i];
    }
#endif

    // --------------------------------------------------------
    // 6. 結果検証
    // --------------------------------------------------------
    bool ok = verify_sa_result(Csw, Csa);

    // --------------------------------------------------------
    // テスト終了通知
    // --------------------------------------------------------
    //if (ok && wb) {
    if (ok) {
        PIO32 = TEST_END_CODE;
        PIO32 = 0xBEEF;   // PASS
    } else {
        PIO32 = TEST_END_CODE;
        PIO32 = 0xDEAD;   // FAIL
    }

    // --------------------------------------------------------
    // CPU停止
    // --------------------------------------------------------
    while (1) { }
}

/* ---------- 定義（実体）：extern を外す ---------- */
extern "C" {
    volatile uint32_t timer_data = 0;
}
