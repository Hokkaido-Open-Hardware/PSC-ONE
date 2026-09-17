#include <cstdint>

/* ---------- タイマーW ---------- */
#define TIMER_MMIOADDR_W  (*reinterpret_cast<volatile uint32_t*>(0x10002000u))

/* ---------- タイマーR ---------- */
#define TIMER_MMIOADDR_R  (*reinterpret_cast<volatile uint32_t*>(0x10002004u))

/* ---------- タイマーST ---------- */
#define TIMER_MMIOADDR_ST (*reinterpret_cast<volatile uint32_t*>(0x10002008u))

/* ---------- アサーション用PIO出力 ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))

static constexpr uint32_t TEST_END_CODE = 0xEE01u;
static constexpr uint32_t TEST_PASS     = 0x0123u;

static constexpr uint32_t FAIL_STATUS   = 0xE401u;
static constexpr uint32_t FAIL_COUNT    = 0xE402u;

/* ---------- 宣言（extern：初期化しない） ---------- */
extern "C" volatile uint32_t timer_data;
extern "C" volatile uint32_t timer_st;


/* ---------- 簡易ウェイト ---------- */
static inline void tiny_delay(unsigned n) {
    while (n--) {
        asm volatile("nop");
    }
}


/* ---------- スタートアップから呼ばれるエントリ ---------- */
extern "C" void run() {

    uint32_t timer_before;
    uint32_t timer_after;


    /* ---------- TIMER start ---------- */
    TIMER_MMIOADDR_W = 0x10FFFu;


    /* ---------- TIMER status確認 ---------- */
    tiny_delay(10);

    timer_st = TIMER_MMIOADDR_ST;

    PIO32 = 0xAB01u;
    PIO32 = timer_st;

    /* running bit確認 */
    if ((timer_st & (1u << 7)) == 0u) {
        PIO32 = TEST_END_CODE;
        PIO32 = FAIL_STATUS;

        while (1) {
        }
    }


    /* ---------- カウンタ減少確認 ---------- */
    timer_before = TIMER_MMIOADDR_R;

    tiny_delay(100);

    timer_after = TIMER_MMIOADDR_R;

    if (timer_after >= timer_before) {
        PIO32 = TEST_END_CODE;
        PIO32 = FAIL_COUNT;

        while (1) {
        }
    }


    /* ---------- TIMER読み出し ---------- */
    timer_data = timer_after;
    PIO32 = timer_data;


    /* ---------- テスト終了 ---------- */
    PIO32 = TEST_END_CODE;

    /* PASSコード */
    PIO32 = TEST_PASS;


    while (1) {
    }
}


/* ---------- 定義（実体）：extern を外す ---------- */
extern "C" {
    volatile uint32_t timer_data = 0;
    volatile uint32_t timer_st   = 0;
}