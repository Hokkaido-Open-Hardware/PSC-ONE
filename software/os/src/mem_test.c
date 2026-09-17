#include "mem_test.h"
#include "common.h"

#define MEM_STEP 4u   // 32bit access

#ifndef UART_MMIO_BASE
#define UART_MMIO_BASE 0x10000000u
#endif

#ifndef UART_TX
#define UART_TX 0x0
#endif
#ifndef UART_RX
#define UART_RX 0x4
#endif
#ifndef UART_ST
#define UART_ST 0x8
#endif

#ifndef ST_TX_BUSY
#define ST_TX_BUSY (1u << 0)
#endif
#ifndef ST_RX_AVAIL
#define ST_RX_AVAIL (1u << 1)
#endif

/* 32bit LFSR (Galois) */
static inline uint32_t lfsr_next(uint32_t x) {
    uint32_t lsb = x & 1u;
    x >>= 1;
    if (lsb) {
        x ^= 0xA3000000u;
    }
    return x;
}

static inline uint32_t test_pattern(uint32_t addr) {
    return addr ^ 0xA5A5A5A5u;
}

void random_mem_check(uint32_t start_addr, uint32_t end_addr)
{
    bool TestPass = true;
    uint32_t lfsr;
    uint32_t addr;

    uint32_t range_bytes = end_addr - start_addr;
    uint32_t range_words = range_bytes / MEM_STEP;

    /* range_bytes must be power-of-two */
    uint32_t mask = range_bytes - MEM_STEP;

    s_printf("[mem_check] range %x - %x\n", start_addr, end_addr);

    /* ================= write phase ================= */
    s_printf("[mem_check] random write phase\n");

    lfsr = 0x12345678u;

    for (uint32_t i = 0; i < range_words; i++)
    {
        addr = start_addr + (lfsr & mask);

        *(volatile uint32_t *)addr = test_pattern(addr);

        lfsr = lfsr_next(lfsr);
    }

    /* ================= read & verify ================= */
    s_printf("[mem_check] random read & verify phase\n");

    lfsr = 0x12345678u;

    for (uint32_t i = 0; i < range_words; i++)
    {
        addr = start_addr + (lfsr & mask);

        uint32_t v   = *(volatile uint32_t *)addr;
        uint32_t exp = test_pattern(addr);

        if (v != exp)
        {
            TestPass = false;

            s_printf("MEM ERROR addr=%x read=%x exp=%x\n",
                     addr, v, exp);

            mmio_w32(UART_MMIO_BASE + UART_TX, 0xEE01);
        }

        lfsr = lfsr_next(lfsr);
    }

    /* ================= result ================= */

    if (TestPass)
        s_printf("[mem_check] OK (RV32I safe)\n");
    else
        s_printf("[mem_check] NG!!! (RV32I fail)\n");
}

void seqential_mem_check(uint32_t start_addr, uint32_t end_addr) {
    bool TestPass = true;
    volatile uint32_t *p;
    uint32_t lfsr;
    uint32_t addr;

    /* 範囲サイズ（バイト） */
    uint32_t range_bytes = end_addr - start_addr;

    s_printf("[mem_check] range %x - %x\n", start_addr, end_addr);

    /* ---------- write phase ---------- */
    s_printf("[mem_check] sequential write phase\n");

    lfsr = 0x123456ABu;
    for (uint32_t i = 0; i < (range_bytes / MEM_STEP); i++) {
        addr = start_addr + i * MEM_STEP;

        p = (volatile uint32_t *)addr;
        *p = test_pattern(addr);

        lfsr = lfsr_next(lfsr);
    }

    /* ---------- read & verify ---------- */
    s_printf("[mem_check] sequential read & verify phase\n");

    lfsr = 0x123456ABu;
    for (uint32_t i = 0; i < (range_bytes / MEM_STEP); i++) {
        addr = start_addr + i * MEM_STEP;

        p = (volatile uint32_t *)addr;
        uint32_t v   = *p;
        uint32_t exp = test_pattern(addr);

        if (v != exp) {
            TestPass = false;
            s_printf("MEM ERROR addr=%x read=%x exp=%x\n",
                   addr, v, exp);
            //PANIC("mem_check failed");
            mmio_w32(UART_MMIO_BASE + UART_TX, 0xEE01);
        }

        lfsr = lfsr_next(lfsr);
    }

    if(TestPass==true) {
        s_printf("[mem_check] OK (RV32I safe)\n");
    } else {
        s_printf("[mem_check] NG!!! (RV32I fail)\n");
    }
}
