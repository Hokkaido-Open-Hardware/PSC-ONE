#include <cstdint>
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
extern "C" { volatile uint32_t result = 0u; }

// Independent scalar oracle: interpret each byte as int8_t, accumulate in
// int64_t. The signed dot is in [-65024,65536], so int32_t conversion is exact.
static int32_t reference_dotsp_b(uint32_t a, uint32_t b)
{
    int64_t sum = 0;
    for (unsigned shift = 0; shift < 32u; shift += 8u) {
        const int8_t x = static_cast<int8_t>((a >> shift) & 255u);
        const int8_t y = static_cast<int8_t>((b >> shift) & 255u);
        sum += int64_t(x) * int64_t(y);
    }
    return static_cast<int32_t>(sum);
}
static uint32_t dot(uint32_t a, uint32_t b)
{
    uint32_t r;
    asm volatile(".insn r 0x7b, 1, 0x48, %0, %1, %2" : "=r"(r) : "r"(a), "r"(b));
    return r;
}
static uint32_t test_index = 0u;
static void check(uint32_t actual, uint32_t expected)
{
    if (actual != expected) {
        result = result + 1u;
        PIO32 = 0xbad00001u;
        PIO32 = test_index;
        PIO32 = actual;
        PIO32 = expected;
    }
    ++test_index;
}
static void aliases(uint32_t a, uint32_t b, uint32_t c)
{
    { // dot: rd=rs1
        uint32_t r = a;
        asm volatile(".insn r 0x7b, 1, 0x48, %0, %0, %1" : "+r"(r) : "r"(b));
        check(r, static_cast<uint32_t>(reference_dotsp_b(a, b)));
    }
    { // dot: rd=rs2
        uint32_t r = b;
        asm volatile(".insn r 0x7b, 1, 0x48, %0, %1, %0" : "+r"(r) : "r"(a));
        check(r, static_cast<uint32_t>(reference_dotsp_b(a, b)));
    }
    { // dot: rs1=rs2
        uint32_t r = c;
        asm volatile(".insn r 0x7b, 1, 0x48, %0, %1, %1" : "+r"(r) : "r"(a));
        check(r, static_cast<uint32_t>(reference_dotsp_b(a, a)));
    }
    { // dot: all equal
        uint32_t r = a;
        asm volatile(".insn r 0x7b, 1, 0x48, %0, %0, %0" : "+r"(r) : );
        check(r, static_cast<uint32_t>(reference_dotsp_b(a, a)));
    }
    { // dot: rs1=x0
        uint32_t r = c;
        asm volatile(".insn r 0x7b, 1, 0x48, %0, x0, %1" : "+r"(r) : "r"(b));
        check(r, static_cast<uint32_t>(reference_dotsp_b(0u, b)));
    }
    { // dot: rs2=x0
        uint32_t r = c;
        asm volatile(".insn r 0x7b, 1, 0x48, %0, %1, x0" : "+r"(r) : "r"(a));
        check(r, static_cast<uint32_t>(reference_dotsp_b(a, 0u)));
    }
    { // dot: rd=x0; explicitly read x0 after discarded result
        uint32_t r;
        asm volatile(".insn r 0x7b, 1, 0x48, x0, %1, %2\n\taddi %0, x0, 0"
                     : "=r"(r) : "r"(a), "r"(b));
        check(r, 0u);
    }
}

static void dependencies(uint32_t a, uint32_t b, uint32_t c)
{
    uint32_t r;
    // Fixed scratch registers guarantee adjacent producers and consumers.
    asm volatile("mv t1, %1\n\tmv t2, %2\n\t"
                 "addi t1, t1, 1\n\t"
                 ".insn r 0x7b, 1, 0x48, t0, t1, t2\n\t"
                 "addi %0, t0, 1"
                 : "=r"(r) : "r"(a), "r"(b) : "t0", "t1", "t2");
    check(r, static_cast<uint32_t>(reference_dotsp_b(a+1u, b)) + 1u);
    asm volatile("mv t1, %1\n\tmv t2, %2\n\t"
                 "addi t2, t2, 1\n\t"
                 ".insn r 0x7b, 1, 0x48, t0, t1, t2\n\t"
                 "addi %0, t0, 1"
                 : "=r"(r) : "r"(a), "r"(b) : "t0", "t1", "t2");
    check(r, static_cast<uint32_t>(reference_dotsp_b(a, b+1u)) + 1u);
    asm volatile(".insn r 0x7b, 1, 0x48, %0, %1, %2\n\taddi %0, %0, 1"
                 : "=r"(r) : "r"(a), "r"(b));
    check(r, static_cast<uint32_t>(reference_dotsp_b(a,b)) + 1u);
    { // load -> t1 -> DOTSP -> STORE; RTL harness delays memory.
        volatile uint32_t input=c, output=0u;
        asm volatile("mv t1, %0\n\tmv t2, %1\n\t"
                     "lw t1, 0(%3)\n\t"
                     ".insn r 0x7b, 1, 0x48, t0, t1, t2\n\tsw t0, 0(%2)"
                     : : "r"(a), "r"(b), "r"(&output), "r"(&input)
                     : "t0", "t1", "t2", "memory");
        const uint32_t produced=c;
        check(output, static_cast<uint32_t>(reference_dotsp_b(produced, b)));
    }
    { // load -> t2 -> DOTSP -> STORE; RTL harness delays memory.
        volatile uint32_t input=c, output=0u;
        asm volatile("mv t1, %0\n\tmv t2, %1\n\t"
                     "lw t2, 0(%3)\n\t"
                     ".insn r 0x7b, 1, 0x48, t0, t1, t2\n\tsw t0, 0(%2)"
                     : : "r"(a), "r"(b), "r"(&output), "r"(&input)
                     : "t0", "t1", "t2", "memory");
        const uint32_t produced=c;
        check(output, static_cast<uint32_t>(reference_dotsp_b(a, produced)));
    }
    { // mul -> t1 -> DOTSP -> STORE; RTL harness delays memory.
        volatile uint32_t input=c, output=0u;
        asm volatile("mv t1, %0\n\tmv t2, %1\n\t"
                     "mul t1, t1, t2\n\t"
                     ".insn r 0x7b, 1, 0x48, t0, t1, t2\n\tsw t0, 0(%2)"
                     : : "r"(a), "r"(b), "r"(&output), "r"(&input)
                     : "t0", "t1", "t2", "memory");
        const uint32_t produced=a*b;
        check(output, static_cast<uint32_t>(reference_dotsp_b(produced, b)));
    }
    { // mul -> t2 -> DOTSP -> STORE; RTL harness delays memory.
        volatile uint32_t input=c, output=0u;
        asm volatile("mv t1, %0\n\tmv t2, %1\n\t"
                     "mul t2, t1, t2\n\t"
                     ".insn r 0x7b, 1, 0x48, t0, t1, t2\n\tsw t0, 0(%2)"
                     : : "r"(a), "r"(b), "r"(&output), "r"(&input)
                     : "t0", "t1", "t2", "memory");
        const uint32_t produced=a*b;
        check(output, static_cast<uint32_t>(reference_dotsp_b(a, produced)));
    }
    { // dotup -> t1 -> DOTSP -> STORE; RTL harness delays memory.
        volatile uint32_t input=c, output=0u;
        asm volatile("mv t1, %0\n\tmv t2, %1\n\t"
                     ".insn r 0x7b, 0, 0x40, t1, t1, t2\n\t"
                     ".insn r 0x7b, 1, 0x48, t0, t1, t2\n\tsw t0, 0(%2)"
                     : : "r"(a), "r"(b), "r"(&output), "r"(&input)
                     : "t0", "t1", "t2", "memory");
        const uint32_t produced=(a&65535u)*(b&65535u)+(a>>16)*(b>>16);
        check(output, static_cast<uint32_t>(reference_dotsp_b(produced, b)));
    }
    { // dotup -> t2 -> DOTSP -> STORE; RTL harness delays memory.
        volatile uint32_t input=c, output=0u;
        asm volatile("mv t1, %0\n\tmv t2, %1\n\t"
                     ".insn r 0x7b, 0, 0x40, t2, t1, t2\n\t"
                     ".insn r 0x7b, 1, 0x48, t0, t1, t2\n\tsw t0, 0(%2)"
                     : : "r"(a), "r"(b), "r"(&output), "r"(&input)
                     : "t0", "t1", "t2", "memory");
        const uint32_t produced=(a&65535u)*(b&65535u)+(a>>16)*(b>>16);
        check(output, static_cast<uint32_t>(reference_dotsp_b(a, produced)));
    }
    { // dotsp -> t1 -> DOTSP -> STORE; RTL harness delays memory.
        volatile uint32_t input=c, output=0u;
        asm volatile("mv t1, %0\n\tmv t2, %1\n\t"
                     ".insn r 0x7b, 1, 0x48, t1, t1, t2\n\t"
                     ".insn r 0x7b, 1, 0x48, t0, t1, t2\n\tsw t0, 0(%2)"
                     : : "r"(a), "r"(b), "r"(&output), "r"(&input)
                     : "t0", "t1", "t2", "memory");
        const uint32_t produced=static_cast<uint32_t>(reference_dotsp_b(a,b));
        check(output, static_cast<uint32_t>(reference_dotsp_b(produced, b)));
    }
    { // dotsp -> t2 -> DOTSP -> STORE; RTL harness delays memory.
        volatile uint32_t input=c, output=0u;
        asm volatile("mv t1, %0\n\tmv t2, %1\n\t"
                     ".insn r 0x7b, 1, 0x48, t2, t1, t2\n\t"
                     ".insn r 0x7b, 1, 0x48, t0, t1, t2\n\tsw t0, 0(%2)"
                     : : "r"(a), "r"(b), "r"(&output), "r"(&input)
                     : "t0", "t1", "t2", "memory");
        const uint32_t produced=static_cast<uint32_t>(reference_dotsp_b(a,b));
        check(output, static_cast<uint32_t>(reference_dotsp_b(a, produced)));
    }
}
static uint32_t random_word(uint32_t& state)
{
    state ^= state << 13; state ^= state >> 17; state ^= state << 5;
    return state;
}
extern "C" void run()
{
    check(dot(0u,0u),0u);
    check(dot(0x01010101u,0x01010101u),4u);
    check(dot(0x80808080u,0x80808080u),65536u);
    check(dot(0x7f7f7f7fu,0x80808080u),static_cast<uint32_t>(-65024));
    check(dot(0x01ff01ffu,0x01010101u),0u);
    constexpr uint32_t edge[] = {0u,1u,0x7eu,0x7fu,0x80u,0x81u,0xfeu,0xffu};
    for (auto x:edge) for (auto y:edge) {
        const uint32_t a=x*0x01010101u, b=y*0x01010101u;
        check(dot(a,b),static_cast<uint32_t>(reference_dotsp_b(a,b)));
        aliases(a,b,0u);
    }
    uint32_t state=0x53444f54u;
    // 2048 fully random pairs + 2048 pairs with each lane chosen from
    // signed edge values. Dependencies/aliases also use varied full words.
    for (uint32_t i=0u;i<4096u;++i) {
        uint32_t a=random_word(state), b=random_word(state);
        const uint32_t c=random_word(state);
        if (i>=2048u) {
            a=0u; b=0u;
            for (unsigned lane=0;lane<4u;++lane) {
                a |= edge[random_word(state)&7u] << (lane*8u);
                b |= edge[random_word(state)&7u] << (lane*8u);
            }
        }
        check(dot(a,b),static_cast<uint32_t>(reference_dotsp_b(a,b)));
        if (i<64u) { aliases(a,b,c); dependencies(a,b,c); }
    }
    // PIO: EE40, total checks, mismatch count; EE01 then pass/fail signature.
    // BAD00001 above includes check index, actual and independent expected.
    PIO32=0xee40u; PIO32=test_index; PIO32=result;
    PIO32=0xee01u;
    PIO32=(result==0u)?0x600d600du:0xbad0bad0u;
    while (true) asm volatile("nop");
}
