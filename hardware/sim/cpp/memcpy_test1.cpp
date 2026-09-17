#include <cstdint>
#include <cstddef>

/* ---------- PIO ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01u;

/* ---------- 結果 ---------- */
extern "C" volatile uint32_t result;

/* ============================================================
 * memcpy_byte : LB/SB
 * ============================================================ */
static void* memcpy_byte(void* dst, const void* src, size_t n) {

    auto* d = reinterpret_cast<uint8_t*>(dst);
    const auto* s = reinterpret_cast<const uint8_t*>(src);
    while (n--) *d++ = *s++;
    return dst;
}

/* ============================================================
 * memcpy_half : LH/SH
 *   ※ Cの都合で実際はbyteコピーだが、
 *      別途 asm で LH/SH を直接テストする
 * ============================================================ */
static void* memcpy_half(void* dst, const void* src, size_t n) {
    auto* d = reinterpret_cast<uint8_t*>(dst);
    const auto* s = reinterpret_cast<const uint8_t*>(src);

    while (n >= 2) {
        d[0] = s[0];
        d[1] = s[1];
        d += 2; s += 2; n -= 2;
    }
    while (n--) *d++ = *s++;
    return dst;
}

/* ============================================================
 * memcpy_word : LW/SW
 * ============================================================ */
static void* memcpy_word(void* dst, const void* src, size_t n) {
    auto* d = reinterpret_cast<uint8_t*>(dst);
    const auto* s = reinterpret_cast<const uint8_t*>(src);

    while (n >= 4) {
        d[0]=s[0]; d[1]=s[1]; d[2]=s[2]; d[3]=s[3];
        d+=4; s+=4; n-=4;
    }
    while (n--) *d++ = *s++;
    return dst;
}

/* ============================================================
 * utility
 * ============================================================ */
static bool memeq8(const uint8_t* a, const uint8_t* b, size_t n) {
    while (n--) if (*a++ != *b++) return false;
    return true;
}

static void fill(uint8_t* p, size_t n, uint8_t seed) {
    for (size_t i=0;i<n;i++) p[i] = (uint8_t)((i*17)^seed);
}

/* ============================================================
 * テスト用メモリ
 * ============================================================ */
static constexpr size_t BUF = 512;
static constexpr size_t GUARD = 32;
static constexpr uint8_t GV = 0xCC;

static uint8_t src_raw[BUF+GUARD*2];
static uint8_t dst_raw[BUF+GUARD*2];

static uint8_t* const SRC = &src_raw[GUARD];
static uint8_t* const DST = &dst_raw[GUARD];

static void init_buf() {
    for (size_t i=0;i<BUF+GUARD*2;i++) {
        src_raw[i]=GV;
        dst_raw[i]=GV;
    }
    fill(SRC, BUF, 0xAA);
}

static bool check_guard() {
    for (size_t i=0;i<GUARD;i++) {
        if (src_raw[i]!=GV) return false;
        if (dst_raw[i]!=GV) return false;
    }
    return true;
}

/* ============================================================
 * LH/SH テスト（直接命令）
 * ============================================================ */
static bool test_lh_sh(uint8_t* base) {
    uint16_t val = 0x1234;
    uint16_t out = 0;

    uintptr_t addr = reinterpret_cast<uintptr_t>(base);

    asm volatile(
        "sh %[v], 0(%[a])\n"
        "lh %[o], 0(%[a])\n"
        : [o]"=r"(out)
        : [v]"r"(val), [a]"r"(addr)
        : "memory"
    );

    return (out == val) &&
           (base[0]==0x34) &&
           (base[1]==0x12);
}

/* ============================================================
 * LW/SW テスト
 * ============================================================ */
static bool test_lw_sw(uint8_t* base) {
    uint32_t val = 0x89ABCDEF;
    uint32_t out = 0;

    uintptr_t addr = reinterpret_cast<uintptr_t>(base);

    asm volatile(
        "sw %[v], 0(%[a])\n"
        "lw %[o], 0(%[a])\n"
        : [o]"=r"(out)
        : [v]"r"(val), [a]"r"(addr)
        : "memory"
    );

    return (out == val) &&
           base[0]==0xEF &&
           base[1]==0xCD &&
           base[2]==0xAB &&
           base[3]==0x89;
}

/* ============================================================
 * run
 * ============================================================ */
extern "C" void run() {

    uint32_t fail = 0;

    /* --- byte memcpy --- */
    PIO32=0xA1;
    init_buf();
    memcpy_byte(DST,SRC,256);

    /*
    uint32_t sum_s = 0;
    uint32_t sum_d = 0;
    for (size_t i=0;i<256;i++) {
        sum_s += SRC[i];
        sum_d += DST[i];
    }

    PIO32 = 0xE101;
    PIO32 = sum_s;
    PIO32 = sum_d;
    */

    if (!memeq8(DST,SRC,256)) fail|=1<<0;
    PIO32 = fail;

#if 1
    /* --- half memcpy --- */
    PIO32=0xA2;
    init_buf();
    memcpy_half(DST,SRC,256);
    if (!memeq8(DST,SRC,256)) fail|=1<<1;
    PIO32 = fail;

    /* --- word memcpy --- */
    PIO32=0xA3;
    init_buf();
    memcpy_word(DST,SRC,256);
    if (!memeq8(DST,SRC,256)) fail|=1<<2;
    PIO32 = fail;

    /* --- misaligned --- */
    PIO32=0xA4;
    init_buf();
    memcpy_byte(DST+1,SRC+3,123);
    if (!memeq8(DST+1,SRC+3,123)) fail|=1<<3;
    PIO32 = fail;

    /* --- 境界またぎ --- */
    PIO32=0xA5;
    init_buf();
    memcpy_byte(DST+15,SRC+15,17);
    if (!memeq8(DST+15,SRC+15,17)) fail|=1<<4;
    PIO32 = fail;

    /* --- LH/SH --- */
    PIO32=0xA6;
    init_buf();
    if (!test_lh_sh(DST+2)) fail|=1<<5;
    PIO32 = fail;
#endif
    /* --- LW/SW --- */
    PIO32=0xA7;
    init_buf();
    if (!test_lw_sw(DST+4)) fail|=1<<6;
    PIO32 = fail;

#if 1
    /* --- guard --- */
    PIO32=0xA8;
    if (!check_guard()) fail|=1<<7;
    PIO32 = fail;
#endif

    /* --- result --- */
    if (fail==0) result=0x2521;
    else result=0xBAD00000|fail;

    PIO32=TEST_END_CODE;
    PIO32=result;

    while(1){}
}

extern "C" {
    volatile uint32_t result=0;
}