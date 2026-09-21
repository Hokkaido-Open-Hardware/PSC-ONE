#include <cstdint>

#define PSC_HAS_CV_DOTUP_H 1
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
extern "C" { volatile uint32_t result = 0u; }

// Independent software reference: ordinary RV32 MUL, 64-bit accumulation.
static uint32_t reference(uint32_t a, uint32_t b)
{
    uint64_t sum = 0;
    for (unsigned shift = 0; shift < 32; shift += 16)
        sum += uint64_t((a >> shift) & 65535u) * ((b >> shift) & 65535u);
    return static_cast<uint32_t>(sum);
}

static uint32_t dot(uint32_t a, uint32_t b)
{
    uint32_t r;
    asm volatile (".insn r 0x7b, 0, 0x40, %0, %1, %2"
                  : "=r"(r) : "r"(a), "r"(b));
    return r;
}

static void check(uint32_t actual, uint32_t expected)
{
    if (actual != expected) {
        result = result + 1u;
        PIO32 = 0xBAD00001u;
        PIO32 = actual;
        PIO32 = expected;
    }
}

static void aliases(uint32_t a, uint32_t b)
{
    uint32_t r = a;
    asm volatile (".insn r 0x7b, 0, 0x40, %0, %0, %1" : "+r"(r) : "r"(b));
    check(r, reference(a, b));                       // rd == rs1
    r = b;
    asm volatile (".insn r 0x7b, 0, 0x40, %0, %1, %0" : "+r"(r) : "r"(a));
    check(r, reference(a, b));                       // rd == rs2
    asm volatile (".insn r 0x7b, 0, 0x40, %0, %1, %1" : "=r"(r) : "r"(a));
    check(r, reference(a, a));                       // rs1 == rs2
    r = a;
    asm volatile (".insn r 0x7b, 0, 0x40, %0, %0, %0" : "+r"(r));
    check(r, reference(a, a));                       // all three equal
    asm volatile (".insn r 0x7b, 0, 0x40, %0, x0, %1" : "=r"(r) : "r"(b));
    check(r, 0);
    asm volatile (".insn r 0x7b, 0, 0x40, %0, %1, x0" : "=r"(r) : "r"(a));
    check(r, 0);
    asm volatile (".insn r 0x7b, 0, 0x40, x0, %1, %2\n\taddi %0, x0, 0"
                  : "=r"(r) : "r"(a), "r"(b));
    check(r, 0);
    // Adjacent ALU -> DOT -> DOT -> ALU; early-clobber prevents b overlap.
    r = a;
    asm volatile ("addi %0, %0, 1\n\t"
                  ".insn r 0x7b, 0, 0x40, %0, %0, %1\n\t"
                  ".insn r 0x7b, 0, 0x40, %0, %0, %1\n\t"
                  "addi %0, %0, 1" : "+&r"(r) : "r"(b));
    check(r, reference(reference(a + 1u, b), b) + 1u);
    // Load -> DOT -> store, exercised with delayed memory by the RTL runner.
    volatile uint32_t input = a;
    volatile uint32_t output = 0;
    asm volatile ("lw %0, 0(%1)\n\t"
                  ".insn r 0x7b, 0, 0x40, %0, %0, %2\n\t"
                  "sw %0, 0(%3)" : "=&r"(r)
                  : "r"(&input), "r"(b), "r"(&output) : "memory");
    check(output, reference(a, b));
}

extern "C" void run()
{
    check(dot(0, 0), 0);
    check(dot(0x00010002u, 0x00030004u), 11);
    check(dot(0xffff0001u, 0x00020003u), 0x20001u);
    check(dot(0x80008000u, 0x00020003u), 0x28000u);
    check(dot(0xffffffffu, 0xffffffffu), 0xfffc0002u);
    constexpr uint32_t edge[] = {0, 1, 0x7fff, 0x8000, 0xfffe, 0xffff};
    // All 6^4 combinations cover zero, signedness and carry in each lane.
    for (auto a0 : edge) for (auto a1 : edge)
        for (auto b0 : edge) for (auto b1 : edge) {
            const uint32_t a = a0 | (a1 << 16), b = b0 | (b1 << 16);
            check(dot(a, b), reference(a, b));
        }
    uint32_t state = 0x43565031u;
    for (unsigned i = 0; i < 512; ++i) {
        state ^= state << 13; state ^= state >> 17; state ^= state << 5;
        const uint32_t a = state;
        state ^= state << 13; state ^= state >> 17; state ^= state << 5;
        check(dot(a, state), reference(a, state));
        aliases(a, state);
    }
    PIO32 = 0xEE01u;
    PIO32 = (result == 0u) ? 0x600D600Du : 0xBAD0BAD0u;
    while (true) {}
}
