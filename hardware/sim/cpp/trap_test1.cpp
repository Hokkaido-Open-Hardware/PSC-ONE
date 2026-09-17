#include <cstdint>

#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t MARK_BEFORE_ECALL = 0xE000;
static constexpr uint32_t MARK_TRAP_ENTRY   = 0xE001;
static constexpr uint32_t MARK_BEFORE_MRET  = 0xE003;
static constexpr uint32_t MARK_AFTER_MRET   = 0xE004;
static constexpr uint32_t TEST_END_CODE     = 0xEE01;

extern "C" __attribute__((naked)) void trap_handler() {
    asm volatile (
        "li   t1, 0x10001000      \n"
        "li   t0, %0              \n"
        "sw   t0, 0(t1)           \n"

        /* mepc += 4 で ecall をスキップ */
        "csrr t0, mepc            \n"
        "addi t0, t0, 4           \n"
        "csrw mepc, t0            \n"

        "li   t0, %1              \n"
        "sw   t0, 0(t1)           \n"

        "mret                     \n"
        :
        : "i"(MARK_TRAP_ENTRY),
          "i"(MARK_BEFORE_MRET)
        : "memory"
    );
}

extern "C" __attribute__((naked)) void run() {
    asm volatile (
        "la   t0, trap_handler    \n"
        "csrw mtvec, t0           \n"

        "li   t1, 0x10001000      \n"
        "li   t0, %0              \n"
        "sw   t0, 0(t1)           \n"

        "ecall                    \n"

        "li   t0, %1              \n"
        "sw   t0, 0(t1)           \n"

        "li   t0, %2              \n"
        "sw   t0, 0(t1)           \n"
        "li   t0, 0xCAFEBABE      \n"
        "sw   t0, 0(t1)           \n"

        "j .                      \n"
        :
        : "i"(MARK_BEFORE_ECALL),
          "i"(MARK_AFTER_MRET),
          "i"(TEST_END_CODE)
        : "memory"
    );
}

extern "C" {
    volatile uint32_t result = 0;
}