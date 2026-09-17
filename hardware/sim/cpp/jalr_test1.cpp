#include <cstdint>

#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

extern "C" volatile uint32_t result;

extern "C" void run()
{
    uint32_t ra_val = 0;
    uint32_t expected_ra = 0;

    asm volatile(
        "1:\n"
        "auipc t0, %%pcrel_hi(2f)\n"
        "addi  t0, t0, %%pcrel_lo(1b)\n"

        "jalr  ra, t0, 0\n"
        "3:\n"
        "nop\n"

        "2:\n"
        "mv    %0, ra\n"

        "la    t1, 3b\n"
        "mv    %1, t1\n"

        : "=r"(ra_val), "=r"(expected_ra)
        :
        : "t0", "t1", "ra", "memory"
    );

    result = ra_val;

    PIO32 = TEST_END_CODE;
    PIO32 = (ra_val == expected_ra) ? 0x5AA5u : 0x00EEu;

    while (1) {
    }
}

extern "C" {
    volatile uint32_t result = 0;
}