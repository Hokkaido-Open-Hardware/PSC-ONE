#include <cstdint>

/* ---------- アサーション用PIO出力 ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

static inline void tiny_delay(unsigned n){ while(n--){ asm volatile("nop"); } }

extern "C" volatile uint32_t result_wr;
extern "C" volatile uint32_t result_rd;

extern "C" void run() {
    const uint32_t patterns[] = { 0x51u, 0xA2u, 0x3Eu, 0x05u, 0xF7u };

    // 観察用に現 result を一発出力
    //PIO32 = result;

    for (uint32_t i = 0; i < 5; ++i) {       
        const uint32_t v = patterns[i];
        PIO32 = v;
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
