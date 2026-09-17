// i2s_rx_test1.cpp
#include <cstdint>

/* ---------- PIO ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE      = 0xEE01;
static constexpr uint32_t ERR_I2S_TIMEOUT    = 0xEE70;

/* ---------- PSC I2S RX ---------- */
#define PSC_I2S_RX  (*reinterpret_cast<volatile uint32_t*>(0x10007000u))
#define PSC_I2S_ST  (*reinterpret_cast<volatile uint32_t*>(0x10007004u))

static uint32_t samples[64];

static inline void tiny_delay(unsigned n)
{
    while (n--) {
        asm volatile("nop");
    }
}

extern "C" void run()
{
    uint32_t read_count = 0;
    uint32_t last_sample = 0;

    PIO32 = 0x1700;   // I2S test start

    tiny_delay(100);

    // fifo flush
    PSC_I2S_ST = 0x01;

    while (1) {

        while (1) {
            // FIFO count
            uint32_t fifo_count = (PSC_I2S_ST & 0xFF000000u) >> 24;
            if (fifo_count > 32) break;
        }

        // FIFO read x 24 times
        for (int j = 0; j < 24; j++) {
            samples[read_count] = PSC_I2S_RX & 0x00FFFFFFu;
            read_count = read_count + 1;
        }

        if (read_count > 40u) {
            PIO32 = read_count;
            break;
        }

    }

    PIO32 = 0x1800;   // I2S test end

    // 下位24bitが音声絶対値
    for (int k = 0; k < 40; k++) {
        PIO32 = samples[k];
    }
    last_sample = samples[39];

    PIO32 = last_sample;

    bool ok;
    
    if ((last_sample > 0x00803000) && (last_sample < 0x008134a8)) {
        ok = true;
    } else {
        ok = false;
    }

    if (ok) {
        PIO32 = TEST_END_CODE;
        PIO32 = 0x0abc0123;
    } else {
        PIO32 = TEST_END_CODE;
        PIO32 = 0x0BAD0001;
    }

    while (1) {}
}