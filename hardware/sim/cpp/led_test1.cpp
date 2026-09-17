#include <cstdint>

/* ---------- アサーション用PIO出力 ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

/* ---------- PSC LED IF ---------- */
#define PSC_LED_ADDR     (*reinterpret_cast<volatile uint32_t*>(0x10004000u))

static inline void tiny_delay(unsigned n){ while(n--){ asm volatile("nop"); } }

extern "C" volatile uint32_t result_wr;
extern "C" volatile uint32_t result_rd;

extern "C" void run() {
    const uint32_t patterns[] = { 0x01u, 0x02u, 0x04u, 0x08u, 0x10u, 0x20u};

    // 観察用に現 result を一発出力
    //PIO32 = result;

    for (uint32_t i = 0; i < 6; ++i) {       
        const uint32_t v = patterns[i];
        // LEDは6bit
        PSC_LED_ADDR = v & 0x3F;
        result_wr = v;
        tiny_delay(2);
    }

    result_rd = PIO32;
    
    //tiny_delay(2);

    // テスト終了のコード送信
    PIO32 = TEST_END_CODE;

    if ((result_rd & 0xFFu) == 0x03u) {     // PIO input = 0x03 by cocotb file
        PIO32 = 0x022u;
    } else {
        PIO32 = result_rd;
    }

    while (1) {}
}

extern "C" {
    volatile uint32_t result_wr = 0;
    volatile uint32_t result_rd = 0;
}
