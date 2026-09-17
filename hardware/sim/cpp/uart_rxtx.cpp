// uart_echo.cpp — PSC_RV32IS 用・UARTエコーテスト（RX→TX：byte address 版）
#include <cstdint>

/* ===== MMIO addresses (byte addressed) ===== */
static constexpr uint32_t UART_TX_ADDR = 0x10000000u; // TX (下位8bit使用)
static constexpr uint32_t UART_RX_ADDR = 0x10000004u; // RX
static constexpr uint32_t UART_ST_ADDR = 0x10000008u; // ST: [0]=tx_busy,[1]=rx_avail,[2]=irq_rx,[3]=overrun,[4]=tx_buf_valid
static constexpr uint32_t UART_CT_ADDR = 0x1000000Cu; // CT: [0]=irq_en, W1C:[1]=irq_clr, W1C:[2]=overrun_clr
static constexpr uint32_t PIO_ADDR     = 0x10001000u; // テスト用PIO
static constexpr uint32_t TEST_END_CODE = 0xEE01u;

/* ===== ST bits ===== */
static constexpr uint32_t ST_TX_BUSY    = 1u << 0;
static constexpr uint32_t ST_RX_AVAIL   = 1u << 1;
static constexpr uint32_t ST_IRQ_RX     = 1u << 2;
static constexpr uint32_t ST_RX_OVERRUN = 1u << 3;
static constexpr uint32_t ST_TX_BUFVAL  = 1u << 4;

/* ===== CT bits ===== */
static constexpr uint32_t CT_IRQ_EN  = 1u << 0;
static constexpr uint32_t CT_IRQ_CLR = 1u << 1;  // W1C
static constexpr uint32_t CT_OVR_CLR = 1u << 2;  // W1C

/* ===== MMIO accessors ===== */
#define UART_TX8  (*reinterpret_cast<volatile uint32_t*>(UART_TX_ADDR))
#define UART_RX32 (*reinterpret_cast<volatile uint32_t*>(UART_RX_ADDR))
#define UART_ST   (*reinterpret_cast<volatile uint32_t*>(UART_ST_ADDR))
#define UART_CT   (*reinterpret_cast<volatile uint32_t*>(UART_CT_ADDR)) 


#define PIO32     (*reinterpret_cast<volatile uint32_t*>(PIO_ADDR))

/* ===== tiny delay ===== */
static inline void tiny_delay(unsigned n){ while(n--){ asm volatile("nop"); } }

/* ===== UART TX（busyが落ちるまで待って1byte送信） ===== */
static inline void uart_send_byte(uint8_t b) {
    while (UART_ST & ST_TX_BUSY) { asm volatile("nop"); }
    UART_TX8 = static_cast<uint32_t>(b);
}

/* ===== UART RX（availなら1byte取得してtrue、なければfalse） ===== */
static inline bool uart_try_recv(uint8_t& out) {
    if ((UART_ST & ST_RX_AVAIL) == 0) return false;
    out = static_cast<uint8_t>(UART_RX32 & 0xFFu);  // 読み出しでavail/irq/overrunはクリアされる仕様
    return true;
}

/* ===== entry ===== */
extern "C" void run() {
    // 初期化：IRQは使わない（無効化）＋既存フラグだけW1Cでクリア
    UART_CT = 0u;                          // irq_en=0
    UART_CT = (CT_IRQ_CLR | CT_OVR_CLR);   // W1C クリア

    uint8_t ch;
    // エコーループ：受信したらそのまま返す
    //while (1) {
    for(int i=0; i<3; ++i) {
        // Overrunが立っていたらW1Cでクリア（irq_enは0のまま）
        if (UART_ST & ST_RX_OVERRUN) {
            UART_CT = CT_OVR_CLR;  // W1C
        }

        if (uart_try_recv(ch)) {
            // 必要なら改行整形：\r単独を\r\nにする等
            // if (ch == '\r') { uart_send_byte('\r'); uart_send_byte('\n'); }
            // else { uart_send_byte(ch); }

            uart_send_byte(ch);  // 素直にエコー
        } else {
            // バス空振り時は少し待ってCPUを空回りさせない
            tiny_delay(200);
        }
    }
    // 目視用：開始マーカー
    PIO32 = TEST_END_CODE;
    PIO32 = uint32_t(ch);
}
