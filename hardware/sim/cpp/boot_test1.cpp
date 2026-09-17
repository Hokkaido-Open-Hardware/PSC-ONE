#include <cstdint>

/* ============================================================
 *  boot_test1.cpp
 *  最小ブート確認:
 *    1) boot到達
 *    2) RAM read/write
 *    3) memcpy
 *    4) Sv32 page table構築
 *    5) satp ON
 *    6) sret で U-mode へ
 *    7) U-mode ecall を S-mode trap で受ける
 * ============================================================ */

/* ---------- PIO ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01u;

/* ---------- 配置アドレス ---------- */
static constexpr uintptr_t USER_PA   = 0x00400000u;
static constexpr uintptr_t USER_VA   = 0x00400000u;

/* ---------- CSR ---------- */
static constexpr uint32_t CSR_SSTATUS = 0x100;
static constexpr uint32_t CSR_STVEC   = 0x105;
static constexpr uint32_t CSR_SSCRATCH= 0x140;
static constexpr uint32_t CSR_SEPC    = 0x141;
static constexpr uint32_t CSR_SCAUSE  = 0x142;
static constexpr uint32_t CSR_STVAL   = 0x143;
static constexpr uint32_t CSR_SATP    = 0x180;

static constexpr uint32_t CSR_MSTATUS = 0x300;
static constexpr uint32_t CSR_MTVEC   = 0x305;
static constexpr uint32_t CSR_MEPC    = 0x341;
static constexpr uint32_t CSR_MEDELEG = 0x302;

/* ---------- sstatus bits ---------- */
static constexpr uint32_t SSTATUS_SIE  = (1u << 1);
static constexpr uint32_t SSTATUS_SPIE = (1u << 5);
static constexpr uint32_t SSTATUS_SPP  = (1u << 8);

static constexpr uint32_t MSTATUS_MPP_SHIFT = 11;
static constexpr uint32_t MSTATUS_MPP_MASK  = (3u << MSTATUS_MPP_SHIFT);
static constexpr uint32_t MSTATUS_MPP_S     = (1u << MSTATUS_MPP_SHIFT);

/* ---------- scause ---------- */
static constexpr uint32_t SCAUSE_ECALL_FROM_U = 8u;
static constexpr uint32_t SCAUSE_INST_PAGE_FAULT  = 12u;
static constexpr uint32_t SCAUSE_LOAD_PAGE_FAULT  = 13u;
static constexpr uint32_t SCAUSE_STORE_PAGE_FAULT = 15u;

/* ---------- Sv32 ---------- */
static constexpr uint32_t SATP_MODE_SV32  = 1u;
static constexpr uint32_t SATP_MODE_SHIFT = 31;

static constexpr uint32_t PTE_V = 1u << 0;
static constexpr uint32_t PTE_R = 1u << 1;
static constexpr uint32_t PTE_W = 1u << 2;
static constexpr uint32_t PTE_X = 1u << 3;
static constexpr uint32_t PTE_U = 1u << 4;
static constexpr uint32_t PTE_G = 1u << 5;
static constexpr uint32_t PTE_A = 1u << 6;
static constexpr uint32_t PTE_D = 1u << 7;

/* ============================================================
 *  CSR helper
 * ============================================================ */
template <uint32_t CSR>
static inline uint32_t read_csr() {
    uint32_t v;
    asm volatile ("csrr %0, %1" : "=r"(v) : "i"(CSR));
    return v;
}

template <uint32_t CSR>
static inline void write_csr(uint32_t v) {
    asm volatile ("csrw %0, %1" :: "i"(CSR), "r"(v));
}

static inline void sfence_vma_all() {
    asm volatile ("sfence.vma x0, x0" ::: "memory");
}

static inline void fence_i() {
    asm volatile ("fence.i" ::: "memory");
}

/* ============================================================
 *  小物
 * ============================================================ */
static inline void hang() {
    while (1) {
        //asm volatile ("wfi");
        asm volatile ("nop");
    }
}

static inline void put_code(uint32_t code) {
    PIO32 = code;
}

static void* simple_memcpy(void* dst, const void* src, uint32_t n) {
    auto* d = reinterpret_cast<uint8_t*>(dst);
    auto* s = reinterpret_cast<const uint8_t*>(src);
    for (uint32_t i = 0; i < n; ++i) d[i] = s[i];
    return dst;
}

static bool simple_memcmp32(const uint32_t* a, const uint32_t* b, uint32_t words) {
    for (uint32_t i = 0; i < words; ++i) {
        if (a[i] != b[i]) return false;
    }
    return true;
}

/* ============================================================
 *  ページテーブル
 * ============================================================ */
alignas(4096) static uint32_t root_pt[1024];
alignas(4096) static uint32_t user_l0_pt[1024];

/* 4MB スーパーページ */
static inline uint32_t make_l1_leaf_superpage(uintptr_t pa, uint32_t flags)
{
    return ((pa >> 12) << 10) | flags;
}

/* 通常4KBページ */
static inline uint32_t make_l0_leaf_page(uintptr_t pa, uint32_t flags)
{
    return ((pa >> 12) << 10) | flags;
}

static inline uint32_t make_nonleaf_pt(uintptr_t next_pt_pa)
{
    return ((next_pt_pa >> 12) << 10) | PTE_V;
}

static void map_superpage(uintptr_t va, uintptr_t pa, uint32_t flags) {
    const uint32_t vpn1 = (va >> 22) & 0x3ffu;
    root_pt[vpn1] = make_l1_leaf_superpage(pa, flags);
}

static void map_page_user(uintptr_t va, uintptr_t pa, uint32_t flags) {
    const uint32_t vpn1 = (va >> 22) & 0x3ffu;
    const uint32_t vpn0 = (va >> 12) & 0x3ffu;

    root_pt[vpn1] = make_nonleaf_pt(reinterpret_cast<uintptr_t>(user_l0_pt));
    user_l0_pt[vpn0] = make_l0_leaf_page(pa, flags);
}

static void clear_page_tables() {
    for (int i = 0; i < 1024; ++i) {
        root_pt[i] = 0;
        user_l0_pt[i] = 0;
    }
}

extern "C" void s_mode_entry() {
    put_code(0xB008u);

    uint32_t sstatus = read_csr<CSR_SSTATUS>();
    sstatus &= ~SSTATUS_SPP;   // return to U
    sstatus |=  SSTATUS_SPIE;
    sstatus &= ~SSTATUS_SIE;
    write_csr<CSR_SSTATUS>(sstatus);

    write_csr<CSR_SEPC>(static_cast<uint32_t>(USER_VA));
    put_code(0xB009u);

    asm volatile ("sret");

    put_code(0xE199u);
    hang();
}

/* ============================================================
 *  U-mode テストコード
 *    0x00400000:
 *      addi a0, x0, 0x42
 *      ecall
 *      jal  x0, 0
 * ============================================================ */
static const uint32_t user_prog[] = {
    0x04200513u,  // addi a0, x0, 66
    0x00000073u,  // ecall
    0x0000006fu   // jal x0, 0
};

/* ============================================================
 *  Trap
 * ============================================================ */
extern "C" void trap_handler_c(uint32_t scause, uint32_t sepc, uint32_t stval);

extern "C" __attribute__((naked)) void trap_entry() {
    asm volatile(
        "addi sp, sp, -16\n"
        "sw   ra, 12(sp)\n"
        "sw   a0,  8(sp)\n"
        "sw   a1,  4(sp)\n"
        "sw   a2,  0(sp)\n"

        "csrr a0, scause\n"
        "csrr a1, sepc\n"
        "csrr a2, stval\n"
        "call trap_handler_c\n"

        "lw   a2,  0(sp)\n"
        "lw   a1,  4(sp)\n"
        "lw   a0,  8(sp)\n"
        "lw   ra, 12(sp)\n"
        "addi sp, sp, 16\n"
        "sret\n"
    );
}

extern "C" void trap_handler_c(uint32_t scause, uint32_t sepc, uint32_t stval) {
    PIO32 = 0xE001u;
    PIO32 = scause;
    PIO32 = 0xE002u;
    PIO32 = sepc;
    PIO32 = 0xE003u;
    PIO32 = stval;

    if (scause == SCAUSE_ECALL_FROM_U) {
        put_code(0xB0E1u);
        write_csr<CSR_SEPC>(sepc + 4);
        put_code(TEST_END_CODE);
        put_code(0x1321u);          // pass code
        hang();
    }

    if (scause == SCAUSE_INST_PAGE_FAULT) {
        put_code(0xE12u);
        hang();
    }
    if (scause == SCAUSE_LOAD_PAGE_FAULT) {
        put_code(0xE13u);
        hang();
    }
    if (scause == SCAUSE_STORE_PAGE_FAULT) {
        put_code(0xE15u);
        hang();
    }

    put_code(0xE0FFu);
    hang();
}

/* ============================================================
 *  テスト本体
 * ============================================================ */
extern "C" int main();

extern "C" void run()
{
    main();
}

extern "C" void s_mode_entry();

extern "C" int main() {
    put_code(0xB001u);

    volatile uint32_t* const user_ram = reinterpret_cast<volatile uint32_t*>(USER_PA);
    user_ram[0] = 0x11223344u;
    user_ram[1] = 0x55667788u;

    if (user_ram[0] != 0x11223344u || user_ram[1] != 0x55667788u) {
        put_code(0xE101u);
        hang();
    }
    put_code(0xB002u);

    simple_memcpy(reinterpret_cast<void*>(USER_PA), user_prog, sizeof(user_prog));
    fence_i();

    if (!simple_memcmp32(reinterpret_cast<const uint32_t*>(USER_PA),
                         user_prog,
                         sizeof(user_prog) / sizeof(uint32_t))) {
        put_code(0xE102u);
        hang();
    }
    put_code(0xB003u);

    write_csr<CSR_STVEC>(reinterpret_cast<uint32_t>(&trap_entry));
    put_code(0xB004u);

    clear_page_tables();

    map_superpage(
        0x00000000u,
        0x00000000u,
        PTE_V | PTE_R | PTE_W | PTE_X | PTE_A | PTE_D
    );

    map_page_user(
        0x10001000u,
        0x10001000u,
        PTE_V | PTE_R | PTE_W | PTE_A | PTE_D
    );

    map_page_user(
        USER_VA,
        USER_PA,
        PTE_V | PTE_R | PTE_X | PTE_U | PTE_A | PTE_D
    );

    put_code(0xB005u);

    const uint32_t root_ppn = (reinterpret_cast<uintptr_t>(root_pt) >> 12);
    const uint32_t satp_val = (SATP_MODE_SV32 << SATP_MODE_SHIFT) | root_ppn;

    write_csr<CSR_SATP>(satp_val);
    asm volatile ("sfence.vma x0, x0" ::: "memory");
    asm volatile ("fence.i" ::: "memory");

    put_code(0xB006u);

    // U-mode ecall/page fault を S-mode に委譲
    uint32_t medeleg = 0;
    medeleg |= (1u << 8);   // ecall from U
    medeleg |= (1u << 12);  // instruction page fault
    medeleg |= (1u << 13);  // load page fault
    medeleg |= (1u << 15);  // store page fault
    write_csr<CSR_MEDELEG>(medeleg);

    // MRET で S-mode へ
    uint32_t mstatus = read_csr<CSR_MSTATUS>();
    mstatus &= ~MSTATUS_MPP_MASK;
    mstatus |= MSTATUS_MPP_S;
    write_csr<CSR_MSTATUS>(mstatus);

    write_csr<CSR_MEPC>(reinterpret_cast<uint32_t>(&s_mode_entry));
    put_code(0xB007u);

    asm volatile ("mret");

    put_code(0xE198u);
    hang();
    return 0;
}