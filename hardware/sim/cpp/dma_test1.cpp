#include <cstdint>

/* ---------- アサーション用PIO出力 (Byteアドレス) --------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

/* ---------- DMA CSR ---------- */
static constexpr uint32_t CSR_DMA_CTRL   = 0x7E0;
static constexpr uint32_t CSR_DMA_WORDS  = 0x7E4;
static constexpr uint32_t CSR_DMA_SRC    = 0x7E8;
static constexpr uint32_t CSR_DMA_DST    = 0x7EC;
static constexpr uint32_t CSR_DMA_STATUS = 0x7F0;

/* ---------- 宣言（extern：初期化しない） ---------- */
extern "C" volatile uint32_t result;

/* ---------- CSR Access ---------- */
static inline void csr_write(uint32_t csr, uint32_t value)
{
    switch (csr) {
    case CSR_DMA_CTRL:
        asm volatile ("csrw 0x7E0, %0" :: "r"(value));
        break;
    case CSR_DMA_WORDS:
        asm volatile ("csrw 0x7E4, %0" :: "r"(value));
        break;
    case CSR_DMA_SRC:
        asm volatile ("csrw 0x7E8, %0" :: "r"(value));
        break;
    case CSR_DMA_DST:
        asm volatile ("csrw 0x7EC, %0" :: "r"(value));
        break;
    }
}

static inline uint32_t csr_read_dma_status(void)
{
    uint32_t value;
    asm volatile ("csrr %0, 0x7F0" : "=r"(value));
    return value;
}

static inline void tiny_delay(unsigned n){
    while (n--) {
        asm volatile("nop");
    }
}

/* ---------- スタートアップから呼ばれるエントリ ---------- */
extern "C" void run()
{
    constexpr uint32_t SRC_ADDR   = 0x00000000;
    constexpr uint32_t DST_ADDR   = 0x00410000;
    constexpr uint32_t WORDS      = 100;
    constexpr uint32_t LOOP_COUNT = 3;

    volatile uint32_t *src =
        reinterpret_cast<volatile uint32_t *>(SRC_ADDR);
    volatile uint32_t *dst =
        reinterpret_cast<volatile uint32_t *>(DST_ADDR);
        
    uint32_t error = 0;

    csr_write(CSR_DMA_WORDS, WORDS);
    csr_write(CSR_DMA_SRC, SRC_ADDR);
    csr_write(CSR_DMA_DST, DST_ADDR);

    for (uint32_t loop = 0; loop < LOOP_COUNT; loop++) {

        // DMA開始
        csr_write(CSR_DMA_CTRL, 1);
        csr_write(CSR_DMA_CTRL, 0);

        // 完了待ち
        // dma_busy = H
        while ((csr_read_dma_status() & 0x02) == 0x02) {
            asm volatile("nop");
        }
#if 1
        // CPUでVerify
        for (uint32_t i = 0; i < WORDS; i++) {
            if (src[i] != dst[i]) {
                error++;
            }
        }
#endif
    }

    result = error;

    PIO32 = TEST_END_CODE;
    PIO32 = result;

    while (1) { }
}

/* ---------- 定義（実体） ---------- */
extern "C" {
    volatile uint32_t result = 0;
}