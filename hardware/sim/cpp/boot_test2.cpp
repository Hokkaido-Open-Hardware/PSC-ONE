#include <cstdint>

/* ============================================================
 * boot_test2.cpp
 *
 * MMU テスト
 *  1 boot
 *  2 page table build
 *  3 satp ON
 *  4 M -> S -> U
 *  5 U-mode load/store
 *  6 U-mode ecall
 * ============================================================ */

#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01u;

/* ---------- memory layout ---------- */
static constexpr uintptr_t PIO_VA       = 0x10001000u;
static constexpr uintptr_t PIO_PA       = 0x10001000u;

static constexpr uintptr_t USER_CODE_PA = 0x00400000u;
static constexpr uintptr_t USER_DATA_PA = 0x00401000u;

static constexpr uintptr_t USER_CODE_VA = 0x00400000u;
static constexpr uintptr_t USER_DATA_VA = 0x00401000u;

/* ---------- CSR ---------- */
static constexpr uint32_t CSR_SSTATUS = 0x100;
static constexpr uint32_t CSR_STVEC   = 0x105;
static constexpr uint32_t CSR_SEPC    = 0x141;
static constexpr uint32_t CSR_SCAUSE  = 0x142;
static constexpr uint32_t CSR_STVAL   = 0x143;
static constexpr uint32_t CSR_SATP    = 0x180;

static constexpr uint32_t CSR_MSTATUS = 0x300;
static constexpr uint32_t CSR_MTVEC   = 0x305;
static constexpr uint32_t CSR_MEPC    = 0x341;
static constexpr uint32_t CSR_MEDELEG = 0x302;

/* ---------- sstatus ---------- */
static constexpr uint32_t SSTATUS_SPP  = (1u << 8);
static constexpr uint32_t SSTATUS_SPIE = (1u << 5);

/* ---------- mstatus ---------- */
static constexpr uint32_t MSTATUS_MPP_SHIFT = 11;
static constexpr uint32_t MSTATUS_MPP_MASK  = (3u << MSTATUS_MPP_SHIFT);
static constexpr uint32_t MSTATUS_MPP_S     = (1u << MSTATUS_MPP_SHIFT);

/* ---------- scause ---------- */
static constexpr uint32_t SCAUSE_ECALL_FROM_U = 8u;
static constexpr uint32_t SCAUSE_LOAD_PF      = 13u;
static constexpr uint32_t SCAUSE_STORE_PF     = 15u;
static constexpr uint32_t SCAUSE_INST_PF      = 12u;

/* ---------- Sv32 ---------- */
static constexpr uint32_t SATP_MODE_SV32  = 1u;
static constexpr uint32_t SATP_MODE_SHIFT = 31u;

static constexpr uint32_t PTE_V = 1u << 0;
static constexpr uint32_t PTE_R = 1u << 1;
static constexpr uint32_t PTE_W = 1u << 2;
static constexpr uint32_t PTE_X = 1u << 3;
static constexpr uint32_t PTE_U = 1u << 4;
static constexpr uint32_t PTE_A = 1u << 6;
static constexpr uint32_t PTE_D = 1u << 7;

/* ---------- CSR helpers ---------- */
template<uint32_t CSR>
static inline uint32_t read_csr()
{
    uint32_t v;
    asm volatile ("csrr %0, %1" : "=r"(v) : "i"(CSR));
    return v;
}

template<uint32_t CSR>
static inline void write_csr(uint32_t v)
{
    asm volatile ("csrw %0, %1" :: "i"(CSR), "r"(v));
}

static inline void sfence_vma()
{
    asm volatile ("sfence.vma x0, x0" ::: "memory");
}

static inline void fence_i()
{
    asm volatile ("fence.i" ::: "memory");
}

static inline void hang()
{
    while (1) {
        asm volatile ("nop");
    }
}

/* ---------- page tables ---------- */
alignas(4096) static uint32_t root_pt[1024];
alignas(4096) static uint32_t l0_user_pt[1024];

static inline uint32_t make_leaf(uintptr_t pa, uint32_t flags)
{
    return ((pa >> 12) << 10) | flags;
}

static inline uint32_t make_nonleaf(uintptr_t next_pt_pa)
{
    return ((next_pt_pa >> 12) << 10) | PTE_V;
}

/* ---------- trap ---------- */
extern "C" void trap_handler_c(uint32_t scause, uint32_t sepc, uint32_t stval);

extern "C" __attribute__((naked)) void trap_entry()
{
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

extern "C" void trap_handler_c(uint32_t scause, uint32_t sepc, uint32_t stval)
{
    PIO32 = 0xE201u;
    PIO32 = scause;
    PIO32 = 0xE202u;
    PIO32 = sepc;
    PIO32 = 0xE203u;
    PIO32 = stval;

    if (scause == SCAUSE_ECALL_FROM_U) {
        PIO32 = 0xB2E1u;
        PIO32 = TEST_END_CODE;
        PIO32 = 0x2321u;
        hang();
    }

    if (scause == SCAUSE_LOAD_PF) {
        PIO32 = 0xB2F1u;
        PIO32 = TEST_END_CODE;
        PIO32 = 0xEE22u;
        hang();
    }

    if (scause == SCAUSE_STORE_PF) {
        PIO32 = 0xB2F2u;
        PIO32 = TEST_END_CODE;
        PIO32 = 0xEE23u;
        hang();
    }

    if (scause == SCAUSE_INST_PF) {
        PIO32 = 0xB2F3u;
        PIO32 = TEST_END_CODE;
        PIO32 = 0xEE24u;
        hang();
    }

    PIO32 = 0xE2FFu;
    hang();
}

/* ---------- U-mode program ----------
 * a0 = USER_DATA_VA (= 0x00401000)
 * lw a1, 0(a0)
 * sw a1, 4(a0)
 * ecall
 */
static const uint32_t user_prog[] = {
    0x00401537u, // lui  a0, 0x00401
    0x00050513u, // addi a0, a0, 0
    0x00052583u, // lw   a1, 0(a0)
    0x00b52223u, // sw   a1, 4(a0)
    0x00000073u  // ecall
};

/* ---------- S entry ---------- */
extern "C" void s_mode_entry()
{
    PIO32 = 0xB208u;

    uint32_t sstatus = read_csr<CSR_SSTATUS>();
    sstatus &= ~SSTATUS_SPP;   // return to U
    sstatus |=  SSTATUS_SPIE;
    write_csr<CSR_SSTATUS>(sstatus);

    write_csr<CSR_SEPC>(static_cast<uint32_t>(USER_CODE_VA));

    PIO32 = 0xB209u;
    asm volatile ("sret");

    PIO32 = 0xE298u;
    hang();
}

/* ---------- entry ---------- */
extern "C" int main();

extern "C" void run()
{
    main();
}

/* ---------- main ---------- */
extern "C" int main()
{
    PIO32 = 0xB201u;

    /* user code copy */
    auto* code_dst = reinterpret_cast<volatile uint32_t*>(USER_CODE_PA);
    for (unsigned i = 0; i < (sizeof(user_prog) / sizeof(user_prog[0])); ++i) {
        code_dst[i] = user_prog[i];
    }

    /* user data init */
    auto* data_dst = reinterpret_cast<volatile uint32_t*>(USER_DATA_PA);
    data_dst[0] = 0xA5A5A5A5u;
    data_dst[1] = 0x00000000u;

    /* clear page tables */
    for (int i = 0; i < 1024; ++i) {
        root_pt[i]    = 0;
        l0_user_pt[i] = 0;
    }

    /* root_pt[0] : kernel/boot identity superpage */
    root_pt[(0x00000000u >> 22) & 0x3ffu] =
        make_leaf(0x00000000u,
                  PTE_V | PTE_R | PTE_W | PTE_X | PTE_A | PTE_D);

    /* root_pt[64] : PIO identity superpage */
    root_pt[(0x10000000u >> 22) & 0x3ffu] =
        make_leaf(0x10000000u,
                  PTE_V | PTE_R | PTE_W | PTE_A | PTE_D);

    /* root_pt[1] : user L0 */
    root_pt[(USER_CODE_VA >> 22) & 0x3ffu] =
        make_nonleaf(reinterpret_cast<uintptr_t>(l0_user_pt));

    /* user code page */
    l0_user_pt[(USER_CODE_VA >> 12) & 0x3ffu] =
        make_leaf(USER_CODE_PA,
                  PTE_V | PTE_R | PTE_X | PTE_U | PTE_A | PTE_D);

    /* user data page */
    l0_user_pt[(USER_DATA_VA >> 12) & 0x3ffu] =
        make_leaf(USER_DATA_PA,
                  PTE_V | PTE_R | PTE_W | PTE_U | PTE_A | PTE_D);

    /* trap vector */
    write_csr<CSR_STVEC>(reinterpret_cast<uint32_t>(&trap_entry));
    write_csr<CSR_MTVEC>(reinterpret_cast<uint32_t>(&trap_entry));

    PIO32 = 0xB205u;

    /* delegate U exceptions to S */
    uint32_t medeleg = 0;
    medeleg |= (1u << 8);   // ecall from U
    medeleg |= (1u << 12);  // inst page fault
    medeleg |= (1u << 13);  // load page fault
    medeleg |= (1u << 15);  // store page fault
    write_csr<CSR_MEDELEG>(medeleg);

    /* enable Sv32 */
    const uint32_t root_ppn = static_cast<uint32_t>(reinterpret_cast<uintptr_t>(root_pt) >> 12);
    write_csr<CSR_SATP>((SATP_MODE_SV32 << SATP_MODE_SHIFT) | root_ppn);
    sfence_vma();
    fence_i();

    PIO32 = 0xB206u;

    /* MRET -> S */
    uint32_t mstatus = read_csr<CSR_MSTATUS>();
    mstatus &= ~MSTATUS_MPP_MASK;
    mstatus |= MSTATUS_MPP_S;
    write_csr<CSR_MSTATUS>(mstatus);

    write_csr<CSR_MEPC>(reinterpret_cast<uint32_t>(&s_mode_entry));

    PIO32 = 0xB207u;

    uint32_t spv;
    asm volatile ("mv %0, sp" : "=r"(spv));

    PIO32 = 0xB20A;
    PIO32 = spv;

    asm volatile ("mret");

    PIO32 = 0xE299u;
    hang();
    return 0;
}