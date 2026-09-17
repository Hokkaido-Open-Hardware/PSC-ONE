// uart_test1.cpp 
#include <cstdint>
#include <cstddef>  // size_t

/* ---------- アサーション用PIO出力 ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

/* ---------- UART MMIO ADDR ---------- */
#define UART32 (*reinterpret_cast<volatile uint32_t*>(0x10000000u))
#define UART_ST (*reinterpret_cast<volatile uint32_t*>(0x10000008u))

static inline void tiny_delay(unsigned n){ while(n--){ asm volatile("nop"); } }

extern "C" volatile uint32_t result_wr;  // 観察用
extern "C" volatile uint32_t result_ok;  // 未使用でも外部から読む想定で残す
extern "C" volatile uint32_t result;     // ★ UART READ が 0x00 なら 0x22 を書く

extern "C" void run() {
    const uint32_t patterns[] = { 0x51u , 0x23u };

    for (uint32_t i = 0; i < 2; ++i) {
        const uint32_t v = patterns[i];

        // UART送信
        UART32 = v;

        // ストアの可視性を明確化したい場合はコメント解除
        // asm volatile("fence iorw, iorw" ::: "memory");
        // tiny_delay(64);

        result_wr = v;  // 観察用
    }

    //tiny_delay(10);

    // ---- ここで UART STATUS を読み、下位8bitが 0x01 なら result=0x77 ----
    result = UART_ST;          // Verilog 側は {27'h0, tx_buf_valid, rx_overrun, irq_rx, rx_avail, tx_busy} を返す想定

    // テスト終了のコード送信
    PIO32 = TEST_END_CODE;
    
    // PIO データによるアサーション用書き込み
    if (result == 0x11u) {
        PIO32 = 0x77u;
    } else {
        PIO32 = result;
    }

    while (1) {}
}

extern "C" {
    volatile uint32_t result    = 0;
    volatile uint32_t result_wr = 0;
    volatile uint32_t result_rd = 0;  // ★ 追加
}
