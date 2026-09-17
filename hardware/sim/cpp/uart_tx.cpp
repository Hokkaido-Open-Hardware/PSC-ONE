// uart_tx.cpp  —  PSC_RV32IS 用・UART送信テスト（byte address 版）
#include <cstdint>

/* ===== MMIO addresses (byte addressed) ===== */
static constexpr uint32_t UART_TX_ADDR = 0x10000000u; // 8bit TX (lower 8bit 使用)
static constexpr uint32_t UART_ST_ADDR = 0x10000008u; // status: bit0==1 -> busy/full
static constexpr uint32_t PIO_ADDR     = 0x10001000u; // テスト用PIO
static constexpr uint32_t TEST_END_CODE = 0xEE01u;

/* ===== MMIO accessors ===== */
#define UART_TX8  (*reinterpret_cast<volatile uint32_t*>(UART_TX_ADDR))
#define UART_ST   (*reinterpret_cast<volatile uint32_t*>(UART_ST_ADDR))
#define PIO32     (*reinterpret_cast<volatile uint32_t*>(PIO_ADDR))

/* ===== tiny delay ===== */
static inline void tiny_delay(unsigned n){ while(n--){ asm volatile("nop"); } }

/* ===== UART ===== */
static inline void uart_send_byte(uint8_t b) {
    // ST bit0==1 の間は「送出中/満杯」で待つ
    while (UART_ST & 0x01u) { asm volatile("nop"); }
    UART_TX8 = b;   // 下位8bitのみ有効に使われる想定
}

static inline void uart_send_crlf() {
    uart_send_byte(0x0D); // CR
    uart_send_byte(0x0A); // LF
}

static inline void uart_send_str(const char* s) {
    for (; *s; ++s) uart_send_byte(static_cast<uint8_t>(*s));
}

/* ===== entry ===== */
extern "C" void run() {
    // 一度だけ "hello PSC!" を送って、テストコードをPIOへ出力→しばらく待機
    while (1) {
        uart_send_str("hello PSC!");
        uart_send_crlf();

        // 目視用にPIOへテストコード
        PIO32 = TEST_END_CODE;
        PIO32 = 0x0123;

        // 適度にウェイト（UART可視化のため）
        tiny_delay(200000);

        // ループで繰り返し流す
    }
}
