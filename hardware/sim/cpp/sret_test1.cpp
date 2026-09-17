#include <cstdint>
#include <cstddef>

/* ---------- PIO ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01;

/* ---------- S-mode 入口 / sret 後 ---------- */
extern "C" void s_mode_entry();
extern "C" void sret_target();

/* =========================================================
 * M-mode エントリ
 * ========================================================= */
extern "C" void run() {

    uintptr_t s_entry = reinterpret_cast<uintptr_t>(&s_mode_entry);

    /* mepc = S-mode entry */
    asm volatile ("csrw mepc, %0" :: "r"(s_entry) : "memory");

    /*
     * mstatus.MPP = 01 (S-mode)
     */
    asm volatile (
        "li   t0, (3 << 11)\n"
        "csrrc x0, mstatus, t0\n"
        "li   t0, (1 << 11)\n"
        "csrs  mstatus, t0\n"
        ::: "t0", "memory"
    );

    PIO32 = 0x1001;   // mret before
    asm volatile ("mret");
    while (1) {}
}

/* =========================================================
 * S-mode entry
 * ========================================================= */
extern "C" void s_mode_entry() {

    uintptr_t target = reinterpret_cast<uintptr_t>(&sret_target);

    /* sepc = sret target */
    asm volatile ("csrw sepc, %0" :: "r"(target) : "memory");

    /*
     * sstatus.SPP = 1 (return to S-mode)
     */
    asm volatile (
        "li   t0, (1 << 8)\n"
        "csrs sstatus, t0\n"
        ::: "t0", "memory"
    );

    PIO32 = 0x2001;   // sret before
    asm volatile ("sret");
    while (1) {}
}

/* =========================================================
 * sret 後（S-mode）
 * ========================================================= */
extern "C" void sret_target() {

    uint32_t sstatus;

    asm volatile (
        "csrr %0, sstatus"
        : "=r"(sstatus)
        :
        : "memory"
    );

    /* 下位 12bit を確認 */
    PIO32 = 0xB000 | (sstatus & 0x0FFF);

    uint32_t result =
        (sstatus & (1 << 8)) == 0 ?  // SPP must be cleared
        0xDC12 : 0x1234;

    PIO32 = TEST_END_CODE;
    PIO32 = result;

    while (1) {}
}
