#include <cstdint>

/* ---------- PIO ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

/* ---------- 結果 ---------- */
extern "C" volatile uint32_t result;
extern "C" volatile uint32_t results[4];

/* ---------- CPU Monitor CSR ---------- */
#define CSR_CPU_MON_CTRL   0xBC0u
#define CSR_CPU_MON_CYCLE  0xBC4u

/* ---------- CSR Utility ---------- */
template <uint32_t CSR>
static inline uint32_t read_csr()
{
    uint32_t v;
    asm volatile ("csrr %0, %1"
                  : "=r"(v)
                  : "i"(CSR));
    return v;
}

template <uint32_t CSR>
static inline void write_csr(uint32_t v)
{
    asm volatile ("csrw %0, %1"
                  :
                  : "i"(CSR), "r"(v));
}

static inline void note_fail(uint32_t &fail, uint32_t bit)
{
    fail |= bit;
}

/* =========================================================
 * main
 * ========================================================= */
extern "C" void run()
{
    uint32_t fail = 0;

    // -----------------------------------------------------

    // program_cache_hit_count
    // Counter Reset
    write_csr<CSR_CPU_MON_CTRL>(0x00000000u);

    // Read Cycle Counter
    results[0] = read_csr<CSR_CPU_MON_CYCLE>();
    PIO32 = results[0];

    // Wait
    for (uint32_t i = 0; i < 100; ++i) {
        asm volatile ("nop");
    }

    // program_cache_miss_count
    // Counter Reset
    write_csr<CSR_CPU_MON_CTRL>(0x00000001u);

    // Read Cycle Counter
    results[1] = read_csr<CSR_CPU_MON_CYCLE>();
    PIO32 = results[1];

    // Wait
    for (uint32_t i = 0; i < 100; ++i) {
        asm volatile ("nop");
    }

    // data_cache_hit_count
    // Counter Reset
    write_csr<CSR_CPU_MON_CTRL>(0x00000002u);

    // Read Cycle Counter
    results[2] = read_csr<CSR_CPU_MON_CYCLE>();
    PIO32 = results[2];

    // Wait
    for (uint32_t i = 0; i < 100; ++i) {
        asm volatile ("nop");
    }

    // data_cache_miss_count
    // Counter Reset
    write_csr<CSR_CPU_MON_CTRL>(0x00000003u);

    // Read Cycle Counter
    results[3] = read_csr<CSR_CPU_MON_CYCLE>();
    PIO32 = results[3];

    // Wait
    for (uint32_t i = 0; i < 100; ++i) {
        asm volatile ("nop");
    }


    // -----------------------------------------------------
    if (results[0] == 0) {
        fail = 1;
    }

    // Result
    if (fail == 0) {
        result = 0x22;
    } else {
        result = 0xBAD00000u | fail;
    }

    //
    // Finish
    //
    PIO32 = TEST_END_CODE;
    PIO32 = result;

    while (1) {
    }
}

/* ---------- Global ---------- */
extern "C" {

volatile uint32_t result = 0;
volatile uint32_t results[4] = {0};

}