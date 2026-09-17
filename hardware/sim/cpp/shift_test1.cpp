#include <cstdint>

/* ---------- アサーション用PIO出力 ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

/* ---------- 宣言（extern：初期化しない） ---------- */
extern "C" volatile uint32_t result_sll;
extern "C" volatile uint32_t result_srl;
extern "C" volatile uint32_t result_sra;
extern "C" volatile uint32_t result_slli;
extern "C" volatile uint32_t result_srli;
extern "C" volatile uint32_t result_srai;

/* ---------- スタートアップから呼ばれるエントリ ---------- */
extern "C" void run() {
    uint32_t a = 0x0000000F;  // 15
    uint32_t shift = 2;

    uint32_t sll_res, srl_res, sra_res;
    uint32_t slli_res, srli_res, srai_res;

    /* -------- R-type シフト -------- */
    asm volatile ("sll  %0, %1, %2" : "=r"(sll_res)  : "r"(a), "r"(shift));
    asm volatile ("srl  %0, %1, %2" : "=r"(srl_res)  : "r"(a), "r"(shift));
    asm volatile ("sra  %0, %1, %2" : "=r"(sra_res)  : "r"(a), "r"(shift));

    /* -------- I-type 即値シフト（← 本命） -------- */
    asm volatile ("slli %0, %1, 2"  : "=r"(slli_res) : "r"(a));
    asm volatile ("srli %0, %1, 2"  : "=r"(srli_res) : "r"(a));
    asm volatile ("srai %0, %1, 2"  : "=r"(srai_res) : "r"(a));

    result_sll  = sll_res;   // 0x3C
    result_srl  = srl_res;   // 0x03
    result_sra  = sra_res;   // 0x03
    result_slli = slli_res;  // 0x3C
    result_srli = srli_res;  // ★ 0x03 になるべき
    result_srai = srai_res;  // 0x03

    /* -------- テスト終了通知 -------- */
    PIO32 = TEST_END_CODE;

    /* -------- 判定 -------- */
    if ((result_sll  == 0x3Cu) &&
        (result_srl  == 0x3u ) &&
        (result_sra  == 0x3u ) &&
        (result_slli == 0x3Cu) &&
        (result_srli == 0x3u ) &&
        (result_srai == 0x3u )) {

        PIO32 = 0x1234;   // PASS
    } else {
        PIO32 = 0xDEAD;   // FAIL
    }

    while (1) {}
}

/* ---------- 定義（実体） ---------- */
extern "C" {
    volatile uint32_t result_sll  = 0;
    volatile uint32_t result_srl  = 0;
    volatile uint32_t result_sra  = 0;
    volatile uint32_t result_slli = 0;
    volatile uint32_t result_srli = 0;
    volatile uint32_t result_srai = 0;
}
