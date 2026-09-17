#include "dma.h"

static inline void csr_write(uint32_t csr, uint32_t value)
{
    switch (csr) {
    case CSR_DMA_CTRL:
        __asm__ __volatile__("csrw 0x7E0, %0" :: "r"(value));
        break;

    case CSR_DMA_WORDS:
        __asm__ __volatile__("csrw 0x7E4, %0" :: "r"(value));
        break;

    case CSR_DMA_SRC:
        __asm__ __volatile__("csrw 0x7E8, %0" :: "r"(value));
        break;

    case CSR_DMA_DST:
        __asm__ __volatile__("csrw 0x7EC, %0" :: "r"(value));
        break;
    }
}

static inline uint32_t csr_read_dma_status(void)
{
    uint32_t value;
    __asm__ __volatile__("csrr %0, 0x7F0" : "=r"(value));
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
    csr_write(CSR_DMA_WORDS, (uint32_t)(n >> 2));
    csr_write(CSR_DMA_SRC,   (uint32_t)src);
    csr_write(CSR_DMA_DST,   (uint32_t)dst);

    csr_write(CSR_DMA_CTRL, 1);
    csr_write(CSR_DMA_CTRL, 0);

    while (csr_read_dma_status() == 0)
        ;

    // D-Cache Clear
    dcache_clear();

    return dst;
}
