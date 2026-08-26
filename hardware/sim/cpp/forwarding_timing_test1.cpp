#include <cstdint>

#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))

static constexpr uint32_t TEST_END_CODE = 0xEE01u;
static constexpr uint32_t TEST_PASS_CODE = 0x00008000u;

alignas(4) static volatile uint32_t load_source = 0x12345678u;

extern "C" volatile uint32_t result;

extern "C" void run()
{
    uint32_t failures;

    asm volatile(
        "li      %[fail], 0              \n"

        // slot0 producer -> slot1 consumer.
        ".balign 8                       \n"
        "addi    t0, zero, 1             \n"
        "add     t1, t0, t0              \n"
        "li      t2, 2                   \n"
        "beq     t1, t2, 1f              \n"
        "ori     %[fail], %[fail], 1      \n"
        "1:                               \n"

        // slot1 producer -> next slot0 consumer.
        ".balign 8                       \n"
        "nop                              \n"
        "addi    t0, zero, 3             \n"
        "add     t1, t0, t0              \n"
        "li      t2, 6                   \n"
        "beq     t1, t2, 2f              \n"
        "ori     %[fail], %[fail], 2      \n"
        "2:                               \n"

        // The consumer reaches issue while the producer is in commit.
        // This is the path changed from data bypass to a one-cycle interlock.
        ".balign 8                       \n"
        "addi    t0, zero, 7             \n"
        "addi    t1, zero, 1             \n"
        "addi    t2, zero, 2             \n"
        "addi    t3, zero, 3             \n"
        "add     t4, t0, t1              \n"
        "li      t5, 8                   \n"
        "beq     t4, t5, 3f              \n"
        "ori     %[fail], %[fail], 4      \n"
        "3:                               \n"

        // CSRRW must return the old value, and the following instruction
        // must consume that GPR result correctly.
        "li      t0, 0x33                \n"
        "csrw    mscratch, t0            \n"
        "li      t2, 0x44                \n"
        "csrrw   t3, mscratch, t2        \n"
        "addi    t4, t3, 1               \n"
        "li      t5, 0x34                \n"
        "beq     t4, t5, 4f              \n"
        "ori     %[fail], %[fail], 8      \n"
        "4:                               \n"

        // Load-use dependency.
        "lw      t0, 0(%[base])           \n"
        "add     t1, t0, t0              \n"
        "li      t2, 0x2468acf0          \n"
        "beq     t1, t2, 5f              \n"
        "ori     %[fail], %[fail], 16     \n"
        "5:                               \n"
        : [fail] "=&r"(failures)
        : [base] "r"(&load_source)
        : "t0", "t1", "t2", "t3", "t4", "t5", "memory"
    );

    result = TEST_PASS_CODE | failures;
    PIO32 = TEST_END_CODE;
    PIO32 = result;

    while (1) {
    }
}

extern "C" {
    volatile uint32_t result = 0;
}
