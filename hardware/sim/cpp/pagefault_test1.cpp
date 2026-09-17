#include <cstdint>

/* ---------- PIO ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01u;

/* ---------- CSR ---------- */
/* S-mode */
#define CSR_SSTATUS 0x100u
#define CSR_STVEC   0x105u
#define CSR_SCAUSE  0x142u
#define CSR_STVAL   0x143u
#define CSR_SATP    0x180u

/* M-mode */
#define CSR_MSTATUS 0x300u
#define CSR_MEDELEG 0x302u
#define CSR_MTVEC   0x305u
#define CSR_MEPC    0x341u
#define CSR_MCAUSE  0x342u
#define CSR_MTVAL   0x343u

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

/* ---------- Sv32 ---------- */
static constexpr uint32_t SATP_MODE_SV32  = 1u;
static constexpr uint32_t SATP_MODE_SHIFT = 31u;

static constexpr uint32_t PTE_V = 1u << 0;
static constexpr uint32_t PTE_R = 1u << 1;
static constexpr uint32_t PTE_W = 1u << 2;
static constexpr uint32_t PTE_X = 1u << 3;
static constexpr uint32_t PTE_A = 1u << 6;
static constexpr uint32_t PTE_D = 1u << 7;

/* ---------- mstatus ---------- */
static constexpr uint32_t MSTATUS_MPP_SHIFT = 11u;
static constexpr uint32_t MSTATUS_MPP_MASK  = (3u << MSTATUS_MPP_SHIFT);
static constexpr uint32_t MSTATUS_MPP_S     = (1u << MSTATUS_MPP_SHIFT);

/* ---------- medeleg ---------- */
static constexpr uint32_t MEDELEG_INST_PAGE_FAULT  = (1u << 12);
static constexpr uint32_t MEDELEG_LOAD_PAGE_FAULT  = (1u << 13);
static constexpr uint32_t MEDELEG_STORE_PAGE_FAULT = (1u << 15);

/* ---------- exception ---------- */
static constexpr uint32_t SCAUSE_LOAD_PAGE_FAULT  = 13u;

/* ---------- debug marks ---------- */
static constexpr uint32_t MARK_RUN_START   = 0xEF00u;
static constexpr uint32_t MARK_SMODE_ENTER = 0xEF10u;
static constexpr uint32_t MARK_STRAP_ENTER = 0xEF01u;
static constexpr uint32_t MARK_STRAP_STVAL = 0xEF02u;
static constexpr uint32_t MARK_MTRAP_ENTER = 0xEFAAu;

/* ---------- page tables ---------- */
alignas(4096) static uint32_t l1_pt[1024];
alignas(4096) static uint32_t l0_identity[1024];
alignas(4096) static uint32_t l0_mmio[1024];

/* ---------- globals ---------- */
extern "C" volatile uint32_t result;

/* ============================================================ */

static inline void hang() {
    while (1) {
        asm volatile("nop");
    }
}

/* ============================================================ */
/* trap handlers */
/* ============================================================ */

extern "C" void s_trap_handler_c(uint32_t scause, uint32_t stval);
extern "C" void m_trap_handler_c(uint32_t mcause, uint32_t mtval);

/* ---------- S-mode trap entry ---------- */
extern "C" __attribute__((naked)) void strap_entry() {
    asm volatile(
        "addi sp, sp, -16\n"
        "sw   ra, 12(sp)\n"
        "sw   a0,  8(sp)\n"
        "sw   a1,  4(sp)\n"

        "csrr a0, scause\n"
        "csrr a1, stval\n"
        "call s_trap_handler_c\n"

        "lw   a1,  4(sp)\n"
        "lw   a0,  8(sp)\n"
        "lw   ra, 12(sp)\n"
        "addi sp, sp, 16\n"
        "sret\n"
    );
}

/* ---------- M-mode trap entry ---------- */
extern "C" __attribute__((naked)) void mtrap_entry() {
    asm volatile(
        "addi sp, sp, -16\n"
        "sw   ra, 12(sp)\n"
        "sw   a0,  8(sp)\n"
        "sw   a1,  4(sp)\n"

        "csrr a0, mcause\n"
        "csrr a1, mtval\n"
        "call m_trap_handler_c\n"

        "lw   a1,  4(sp)\n"
        "lw   a0,  8(sp)\n"
        "lw   ra, 12(sp)\n"
        "addi sp, sp, 16\n"
        "mret\n"
    );
}

/* ---------- S trap body ---------- */
extern "C"
void s_trap_handler_c(uint32_t scause, uint32_t stval)
{
    PIO32 = MARK_STRAP_ENTER;
    PIO32 = scause;

    PIO32 = MARK_STRAP_STVAL;
    PIO32 = stval;

    if (scause == SCAUSE_LOAD_PAGE_FAULT && stval == 0x40000000u)
    {
        PIO32 = TEST_END_CODE;
        PIO32 = 0xEF99u;   // PASS
        hang();
    }

    PIO32 = TEST_END_CODE;
    PIO32 = 0x0BADF00Eu;   // FAIL
    hang();
}

/* ---------- M trap body ---------- */
extern "C"
void m_trap_handler_c(uint32_t mcause, uint32_t mtval)
{
    PIO32 = MARK_MTRAP_ENTER;
    PIO32 = mcause;
    PIO32 = mtval;

    PIO32 = TEST_END_CODE;
    PIO32 = 0x0BAD0001u;   // FAIL: M trapに来た時点でおかしい
    hang();
}

/* ============================================================ */
/* S-mode test */
/* ============================================================ */

extern "C"
void s_mode_entry()
{
    PIO32 = MARK_SMODE_ENTER;

    volatile uint32_t* const bad =
        reinterpret_cast<volatile uint32_t*>(0x40000000u); // 未マップ

    uint32_t x = *bad;  // load page fault を期待
    (void)x;

    PIO32 = TEST_END_CODE;
    PIO32 = 0x0BADF00Du; // faultしなかったらFAIL
    hang();
}

/* ============================================================ */
/* run */
/* ============================================================ */

extern "C"
void run()
{
    PIO32 = MARK_RUN_START;

    /* trap vectors */
    write_csr<CSR_STVEC>(static_cast<uint32_t>(reinterpret_cast<uintptr_t>(&strap_entry)));
    write_csr<CSR_MTVEC>(static_cast<uint32_t>(reinterpret_cast<uintptr_t>(&mtrap_entry)));

    /* medeleg: page fault を S に委譲 */
    uint32_t medeleg = read_csr<CSR_MEDELEG>();
    medeleg |= MEDELEG_INST_PAGE_FAULT;
    medeleg |= MEDELEG_LOAD_PAGE_FAULT;
    medeleg |= MEDELEG_STORE_PAGE_FAULT;
    write_csr<CSR_MEDELEG>(medeleg);

    /* page table clear */
    for (int i = 0; i < 1024; ++i)
    {
        l1_pt[i]       = 0u;
        l0_identity[i] = 0u;
        l0_mmio[i]     = 0u;
    }

    /* identity map 0..4MB */
    for (int i = 0; i < 1024; ++i)
    {
        const uint32_t ppn = static_cast<uint32_t>(i);
        l0_identity[i] =
            (ppn << 10) |
            (PTE_V | PTE_R | PTE_W | PTE_X | PTE_A | PTE_D);
    }

    /* L1[0] -> identity 0..4MB */
    {
        const uintptr_t l0_phys = reinterpret_cast<uintptr_t>(l0_identity);
        const uint32_t l0_ppn = static_cast<uint32_t>(l0_phys >> 12);
        l1_pt[0] = (l0_ppn << 10) | PTE_V;
    }

    /* MMIO map: 0x10001000 */
    {
        constexpr uint32_t mmio_va   = 0x10001000u;
        constexpr uint32_t vpn1      = (mmio_va >> 22) & 0x3FFu; // 0x40
        constexpr uint32_t vpn0      = (mmio_va >> 12) & 0x3FFu; // 0x001
        constexpr uint32_t mmio_ppn  = (mmio_va >> 12);          // identity map

        const uintptr_t l0m_phys = reinterpret_cast<uintptr_t>(l0_mmio);
        const uint32_t l0m_ppn   = static_cast<uint32_t>(l0m_phys >> 12);

        /* L1[VPN1] -> l0_mmio */
        l1_pt[vpn1] = (l0m_ppn << 10) | PTE_V;

        /* L0[VPN0] -> 0x10001000 page */
        l0_mmio[vpn0] =
            (mmio_ppn << 10) |
            (PTE_V | PTE_R | PTE_W | PTE_A | PTE_D);
    }

    /* satp = Sv32 + root ppn */
    const uintptr_t root = reinterpret_cast<uintptr_t>(l1_pt);
    const uint32_t root_ppn = static_cast<uint32_t>(root >> 12);

    const uint32_t satp =
        (SATP_MODE_SV32 << SATP_MODE_SHIFT) |
        root_ppn;

    write_csr<CSR_SATP>(satp);
    asm volatile("sfence.vma x0, x0");

    /* M -> S */
    uint32_t mstatus = read_csr<CSR_MSTATUS>();
    mstatus &= ~MSTATUS_MPP_MASK;
    mstatus |=  MSTATUS_MPP_S;
    write_csr<CSR_MSTATUS>(mstatus);

    write_csr<CSR_MEPC>(static_cast<uint32_t>(reinterpret_cast<uintptr_t>(&s_mode_entry)));

    asm volatile("mret");

    PIO32 = TEST_END_CODE;
    PIO32 = 0x0BAD0002u; // ここに戻ったらFAIL
    hang();
}

/* ---------- 実体 ---------- */
extern "C" {
    volatile uint32_t result = 0;
}