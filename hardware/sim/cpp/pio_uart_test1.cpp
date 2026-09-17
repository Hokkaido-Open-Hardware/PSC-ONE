// pio_uart_test1.cpp
#include <stdint.h>

/* ---------- PIO ---------- */
static constexpr uint32_t TEST_END_CODE = 0xEE01;

#define PIO32_ADDR (*(volatile uint32_t*)0x10001000)
#define UART_TX    (*(volatile uint32_t*)0x10000000)
#define UART_ST    (*(volatile uint32_t*)0x10000008)

#define ST_TX_BUSY (1u << 0)

static void uart_putchar(char c) {
    while (UART_ST & ST_TX_BUSY) {
        __asm__ __volatile__("nop");
    }
    UART_TX = (uint32_t)c;
}

static void uart_puts(const char* s) {
    while (*s) {
        uart_putchar(*s++);
    }
}

static void uart_hex4(uint32_t v)
{
    v &= 0xF;

    char c;
    if (v < 10) {
        c = static_cast<char>('0' + static_cast<int>(v));
    } else {
        c = static_cast<char>('A' + static_cast<int>(v) - 10);
    }

    uart_putchar(c);
}

static void uart_hex32(uint32_t v) {
    for (int i = 7; i >= 0; i--) {
        uart_hex4(v >> (i * 4));
    }
}

extern "C" void run() {
    uart_puts("\r\npio_uart_test1 start\r\n");

    for (;;) {
        uart_puts("before PIO read\r\n");

        volatile uint32_t pio = PIO32_ADDR;

        uart_puts("after PIO read: ");
        uart_hex32(pio);
        uart_puts(" sw=");
        uart_hex4(pio & 0x03);
        uart_puts("\r\n");

        PIO32_ADDR = pio;

        for (int i = 0; i < 100; ++i) {
            __asm__ __volatile__("nop");
        }

        // 終了通知
        PIO32_ADDR = TEST_END_CODE;
        PIO32_ADDR = 0x1212;
    }
}