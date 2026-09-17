#include <cstdint>

#define PIO32   (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

static inline void sb(uint32_t addr, uint8_t  v){ asm volatile("sb %0, (%1)" :: "r"(v), "r"(addr) : "memory"); }
static inline void sh(uint32_t addr, uint16_t v){ asm volatile("sh %0, (%1)" :: "r"(v), "r"(addr) : "memory"); }
static inline void sw(uint32_t addr, uint32_t v){ asm volatile("sw %0, (%1)" :: "r"(v), "r"(addr) : "memory"); }
static inline uint32_t lw(uint32_t addr){
    uint32_t v; asm volatile("lw %0, (%1)" : "=r"(v) : "r"(addr)); return v;
}

extern "C" void run() {

    uint32_t base = 0x00005000;
    uint32_t passmask = 0;

    /* 1: SB test */
    sw(base, 0);
    sb(base, 0x33);
    uint32_t r1 = lw(base);
    uint32_t exp1 = 0x00000033;

    if (r1 == exp1) passmask |= (1 << 0);
    PIO32 = 0x10000000 | r1;

    /* 2: SH test */
    sw(base, 0);
    sh(base, 0x1234);
    uint32_t r2 = lw(base);
    uint32_t exp2 = 0x00001234;

    if (r2 == exp2) passmask |= (1 << 1);
    PIO32 = 0x20000000 | r2;

    /* 3: SW test */
    sw(base, 0xDEADBEEF);
    uint32_t r3 = lw(base);
    uint32_t exp3 = 0xDEADBEEF;

    if (r3 == exp3) passmask |= (1 << 2);
    PIO32 = 0x30000000 | r3;

    /* 4: SB x 4 test */
    sw(base, 0);
    sb(base+0, 0x11);
    sb(base+1, 0x22);
    sb(base+2, 0x33);
    sb(base+3, 0x44);

    uint32_t r4 = lw(base);
    uint32_t exp4 = 0x44332211;

    if (r4 == exp4) passmask |= (1 << 3);
    PIO32 = 0x40000000 | r4;

    /* ======== END ======== */
    PIO32  = TEST_END_CODE;

    /* ★★★ 最終 PASS/FAIL を出力 ★★★ */
    /* 0xE5000000 | passmask → PASS/FAILビット列 */
    PIO32 = 0xE5000000 | passmask;

    while (1) {}
}

