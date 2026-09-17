#include <cstdint>

/* ---------- アサーション用PIO出力 (Byteアドレス) --------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

/* ---------- D-Cache CSR ---------- */
static constexpr uint32_t CSR_DCACHE_CTRL = 0x7F0;

/*
    csr_DCACHE_CTRL[0] = cache clear
    csr_DCACHE_CTRL[1] = cache writeback
*/
static inline void dcache_ctrl_write(uint32_t value)
{
    asm volatile ("csrw 0x7F0, %0" :: "r"(value));
}

static inline void dcache_writeback_clear()
{
    asm volatile(
        "li t0, 2\n"
        "csrw 0x7F0, t0\n"
        "li t0, 0\n"
        "csrw 0x7F0, t0\n"
        "li t0, 1\n"
        "csrw 0x7F0, t0\n"
        "li t0, 0\n"
        "csrw 0x7F0, t0\n"
        :
        :
        : "t0", "memory"
    );
}

static inline void tiny_delay(unsigned n)
{
    while (n--) {
        asm volatile("nop");
    }
}

/* ---------- 宣言（extern：初期化しない） ---------- */
extern "C" volatile uint32_t result;

/* ---------- スタートアップから呼ばれるエントリ ---------- */
extern "C" void run()
{
    constexpr uint32_t BASE_ADDR   = 0x00410000;
    constexpr uint32_t WORDS       = 16;
    constexpr uint32_t LOOP_COUNT  = 5;

    volatile uint32_t *data =
        reinterpret_cast<volatile uint32_t *>(BASE_ADDR);

    uint32_t error = 0;

    for (uint32_t loop = 0; loop < LOOP_COUNT; loop++) {

        /* -----------------------------
           1. D-Cache上にデータを書く
           ----------------------------- */
        for (uint32_t i = 0; i < WORDS; i++) {
            uint32_t pattern =
                0xA5A50000u ^ (loop << 16) ^ i ^ (i << 8);

            data[i] = pattern;
        }

        PIO32 = 0xA1;

#if 0
        /* -----------------------------
           2. D-Cache WriteBack
           ----------------------------- */
        dcache_ctrl_write(0x00000002u);
        dcache_ctrl_write(0x00000000u);
        
        //PIO32 = 0xA2;
        //ここにメモリWが入るとNGになるため
        //tiny_delay(1000);

        /* -----------------------------
           3. D-Cache Clear
              再Read時にSDRAMから読ませる
           ----------------------------- */
        dcache_ctrl_write(0x00000001u);
        dcache_ctrl_write(0x00000000u);
#endif

        // -----------------------------
        // D-Cache WriteBack
        // D-Cache Clear
        // -----------------------------
        dcache_writeback_clear();

        PIO32 = 0xA3;

        tiny_delay(1000);

        /* -----------------------------
           4. SDRAMから再ReadしてVerify
           ----------------------------- */
        for (uint32_t i = 0; i < WORDS; i++) {
            uint32_t expected =
                0xA5A50000u ^ (loop << 16) ^ i ^ (i << 8);

            uint32_t actual = data[i];

            if (actual != expected) {
                error++;
            }
        }

        PIO32 = 0xA4;
        PIO32 = error;
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