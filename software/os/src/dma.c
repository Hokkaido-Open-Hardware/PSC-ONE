#include "dma.h"

static inline void csr_write(uint32_t csr, uint32_t value)
{
    switch (csr) {
    case CSR_DMA_CTRL:
        __asm__ __volatile__("csrw 0x7E0, %0" :: "r"(value) : "memory");
        break;

    case CSR_DMA_WORDS:
        __asm__ __volatile__("csrw 0x7E4, %0" :: "r"(value) : "memory");
        break;

    case CSR_DMA_SRC:
        __asm__ __volatile__("csrw 0x7E8, %0" :: "r"(value) : "memory");
        break;

    case CSR_DMA_DST:
        __asm__ __volatile__("csrw 0x7EC, %0" :: "r"(value) : "memory");
        break;
    }
}

static inline uint32_t csr_read_dma_status(void)
{
    uint32_t value;
    __asm__ __volatile__("csrr %0, 0x7F0" : "=r"(value) :: "memory");
    return value;
}

static inline void dcache_clear()
{
    __asm__ __volatile__(
        "li t0, 1\n"
        "csrw 0x7F0, t0\n"
        "li t0, 0\n"
        "csrw 0x7F0, t0\n"
        :
        :
        : "t0", "memory"
    );
}

void *dma_memcpy(void *dst, const void *src, size_t n)
{
    uint8_t *d = (uint8_t *)dst;
    const uint8_t *s = (const uint8_t *)src;

    if (n == 0)
        return dst;

    // The DMA transfers aligned 32-bit words only.
    if ((((uintptr_t)dst | (uintptr_t)src) & 3u) == 0 && n >= 4) {
        size_t bytes = n & ~3u;
        csr_write(CSR_DMA_WORDS, bytes >> 2);
        csr_write(CSR_DMA_SRC, (uint32_t)src);
        csr_write(CSR_DMA_DST, (uint32_t)dst);

        // Hold start until accepted, including a restart from ST_DONE.
        csr_write(CSR_DMA_CTRL, 1);
        while ((csr_read_dma_status() & 2u) == 0)
            ;
        csr_write(CSR_DMA_CTRL, 0);

        // bit 0 = done, bit 1 = busy. Busy is not completion.
        while ((csr_read_dma_status() & 1u) == 0)
            ;

        dcache_clear();
        d += bytes;
        s += bytes;
        n -= bytes;
    }

    // Copy short, unaligned and trailing bytes through the CPU.
    while (n-- != 0)
        *d++ = *s++;

    return dst;
}
