#include <cstdint>

// ============================================================
// MMIO / CSR
// ============================================================
#define PIO32          (*reinterpret_cast<volatile uint32_t*>(0x10001000u))

#define CSR_WRITE(csr, val) \
    asm volatile ("csrw " #csr ", %0" :: "r"(val))

#define CSR_READ(csr) \
    ([&]() -> uint32_t { \
        uint32_t val; \
        asm volatile ("csrr %0, " #csr : "=r"(val)); \
        return val; \
    }())

static constexpr uint32_t TEST_END_CODE = 0xEE01;


// ============================================================
// Entry
// ============================================================
extern "C" void run()
{
    bool all_ok = true;

    alignas(4) uint8_t A[4][4];
    alignas(4) uint8_t B[4][4];
    alignas(4) uint32_t Csa_mem[4][4];

    // --------------------------------------------------------
    // SA_ADDR_A/B/C 設定
    // --------------------------------------------------------
    CSR_WRITE(0x7D0, reinterpret_cast<uint32_t>(&A[0][0]));
    CSR_WRITE(0x7D4, reinterpret_cast<uint32_t>(&B[0][0]));
    CSR_WRITE(0x7D8, reinterpret_cast<uint32_t>(&Csa_mem[0][0]));

    for (int iter = 0; iter < 5; iter++) {

        // ----------------------------------------------------
        // 行列生成
        // ----------------------------------------------------
        A[0][0] = static_cast<uint8_t>(1 + iter);
        A[0][1] = static_cast<uint8_t>(2 + iter);
        A[1][0] = static_cast<uint8_t>(3 + iter);
        A[1][1] = static_cast<uint8_t>(4 + iter);

        B[0][0] = static_cast<uint8_t>(5 + iter);
        B[0][1] = static_cast<uint8_t>(6 + iter);
        B[1][0] = static_cast<uint8_t>(7 + iter);
        B[1][1] = static_cast<uint8_t>(8 + iter);

        // ----------------------------------------------------
        // SW計算
        // ----------------------------------------------------
        uint16_t Csw[4][4];

        for (int i = 0; i < 4; i++) {
            for (int j = 0; j < 4; j++) {

                int sum = 0;

                for (int k = 0; k < 4; k++) {
                    sum +=
                        static_cast<int>(A[i][k]) *
                        static_cast<int>(B[k][j]);
                }

                Csw[i][j] = static_cast<uint16_t>(sum);
            }
        }

        PIO32 = static_cast<uint32_t>(iter);

        // ----------------------------------------------------
        // SA開始
        // ----------------------------------------------------
        CSR_WRITE(0x7C0, (0x04 << 24) | (0x04 << 16) | 0x04);  // clear
        CSR_WRITE(0x7C0, (0x04 << 24) | (0x04 << 16) | 0x00);

        CSR_WRITE(0x7C0, (0x04 << 24) | (0x04 << 16) | 0x02);  // state_reset
        CSR_WRITE(0x7C0, (0x04 << 24) | (0x04 << 16) | 0x00);

        CSR_WRITE(0x7C4, 0x01);  // OS mode

        CSR_WRITE(0x7C0, (0x04 << 24) | (0x04 << 16) | 0x01);  // start
        CSR_WRITE(0x7C0, (0x04 << 24) | (0x04 << 16) | 0x00);

        while ((CSR_READ(0x7C8) & 0x01) == 0) {
            asm volatile("nop");
        }

        // ----------------------------------------------------
        // 結果取得
        // ----------------------------------------------------
        uint32_t Csa[16];

        for (int i = 0; i < 4; i++) {
            for (int j = 0; j < 4; j++) {
                Csa[i * 4 + j] = Csa_mem[i][j];
            }
        }

        // ----------------------------------------------------
        // 検証
        // ----------------------------------------------------
        bool ok = true;

        for (int i = 0; i < 4; i++) {
            for (int j = 0; j < 4; j++) {

                uint32_t v_sw = Csw[i][j];
                uint32_t v_sa = Csa[i * 4 + j];

                if (v_sw != v_sa) {
                    uint32_t err_code =
                        0xDEAD0000u |
                        static_cast<uint32_t>(i * 2 + j);

                    PIO32 = err_code;
                    ok = false;
                }
            }
        }

        if (!ok) {
            PIO32 = static_cast<uint32_t>(iter);
            all_ok = false;
            break;
        }
    }

    PIO32 = TEST_END_CODE;

    if (all_ok) {
        PIO32 = 0xBEEF;
    } else {
        PIO32 = 0xDEAD;
    }

    while (1) {
    }
}