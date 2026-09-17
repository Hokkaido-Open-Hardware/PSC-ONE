#include <cstdint>

#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))

static constexpr uint32_t TEST_END_CODE = 0xEE01u;

extern "C" volatile uint32_t result;

extern "C" void run()
{
    int32_t  s = 0;
    uint32_t u = 0;

#define CHECK_S(id, exp)                  \
    do {                                  \
        if (s != static_cast<int32_t>(exp)) { \
            PIO32 = 0xED000000u | (id);   \
            PIO32 = static_cast<uint32_t>(s); \
            PIO32 = TEST_END_CODE;        \
            PIO32 = static_cast<uint32_t>(s); \
            while (1) {}                  \
        }                                 \
    } while (0)

#define CHECK_U(id, exp)                  \
    do {                                  \
        if (u != static_cast<uint32_t>(exp)) { \
            PIO32 = 0xED000000u | (id);   \
            PIO32 = u;                    \
            PIO32 = TEST_END_CODE;        \
            PIO32 = u;                    \
            while (1) {}                  \
        }                                 \
    } while (0)

    // DIV 10 / 3 = 3
    asm volatile (
        "div %0, %1, %2"
        : "=r"(s)
        : "r"(10), "r"(3)
    );
    CHECK_S(0x01u, 3);

    // DIV -10 / 3 = -3
    asm volatile (
        "div %0, %1, %2"
        : "=r"(s)
        : "r"(-10), "r"(3)
    );
    CHECK_S(0x02u, -3);

    // DIV 10 / 0 = -1
    asm volatile (
        "div %0, %1, %2"
        : "=r"(s)
        : "r"(10), "r"(0)
    );
    CHECK_S(0x03u, -1);

    // REM 10 % 3 = 1
    asm volatile (
        "rem %0, %1, %2"
        : "=r"(s)
        : "r"(10), "r"(3)
    );
    CHECK_S(0x04u, 1);

    // REM -10 % 3 = -1
    asm volatile (
        "rem %0, %1, %2"
        : "=r"(s)
        : "r"(-10), "r"(3)
    );
    CHECK_S(0x05u, -1);

    // REM 10 % 0 = 10
    asm volatile (
        "rem %0, %1, %2"
        : "=r"(s)
        : "r"(10), "r"(0)
    );
    CHECK_S(0x06u, 10);

    // DIVU 10 / 3 = 3
    asm volatile (
        "divu %0, %1, %2"
        : "=r"(u)
        : "r"(10u), "r"(3u)
    );
    CHECK_U(0x07u, 3u);

    // DIVU 10 / 0 = 0xFFFFFFFF
    asm volatile (
        "divu %0, %1, %2"
        : "=r"(u)
        : "r"(10u), "r"(0u)
    );
    CHECK_U(0x08u, 0xFFFFFFFFu);

    // REMU 10 % 3 = 1
    asm volatile (
        "remu %0, %1, %2"
        : "=r"(u)
        : "r"(10u), "r"(3u)
    );
    CHECK_U(0x09u, 1u);

    // REMU 10 % 0 = 10
    asm volatile (
        "remu %0, %1, %2"
        : "=r"(u)
        : "r"(10u), "r"(0u)
    );
    CHECK_U(0x0Au, 10u);

    PIO32 = TEST_END_CODE;
    PIO32 = 0x00000001u;

    while (1) {}
}

extern "C" {
volatile uint32_t result = 0;
}
