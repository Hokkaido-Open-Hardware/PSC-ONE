#include <cstdint>

/* ---------- PIO ---------- */
#define PIO32 (*reinterpret_cast<volatile uint32_t*>(0x10001000u))
static constexpr uint32_t TEST_END_CODE = 0xEE01u;

/* ---------- CSR ---------- */
#define CSR_SSTATUS 0x100u
#define CSR_STVEC   0x105u
#define CSR_SEPC    0x141u
#define CSR_SCAUSE  0x142u
#define CSR_STVAL   0x143u
#define CSR_SATP    0x180u

#define CSR_MSTATUS 0x300u
#define CSR_MTVEC   0x305u
#define CSR_MEPC    0x341u

template <uint32_t CSR>
static inline uint32_t READ_CSR() {
    uint32_t v;
    asm volatile ("csrr %0, %1" : "=r"(v) : "i"(CSR));
    return v;
}

template <uint32_t CSR>
static inline void WRITE_CSR(uint32_t v) {
    asm volatile ("csrw %0, %1" :: "i"(CSR), "r"(v));
}

/* ---------- MSTATUS ---------- */
static constexpr uint32_t MSTATUS_MPP_SHIFT = 11;
static constexpr uint32_t MSTATUS_MPP_MASK  = (3u << MSTATUS_MPP_SHIFT);
static constexpr uint32_t MSTATUS_MPP_S     = (1u << MSTATUS_MPP_SHIFT);

/* ---------- Sv32 ---------- */
static constexpr uint32_t SATP_MODE_SV32  = 1u;
static constexpr uint32_t SATP_MODE_SHIFT = 31;

static constexpr uint32_t PTE_V = 1u << 0;
static constexpr uint32_t PTE_R = 1u << 1;
static constexpr uint32_t PTE_W = 1u << 2;
static constexpr uint32_t PTE_X = 1u << 3;
static constexpr uint32_t PTE_A = 1u << 6;
static constexpr uint32_t PTE_D = 1u << 7;

/* ---------- Page fault cause ---------- */
static constexpr uint32_t SCAUSE_INST_PAGE_FAULT  = 12u;
static constexpr uint32_t SCAUSE_LOAD_PAGE_FAULT  = 13u;
static constexpr uint32_t SCAUSE_STORE_PAGE_FAULT = 15u;

/* ---------- ページテーブル ---------- */
alignas(4096) static uint32_t l1_pt[1024];
alignas(4096) static uint32_t l0_identity[1024];  // vpn1=0 用
alignas(4096) static uint32_t l0_pio[1024];       // vpn1=64 用

alignas(4096) static uint8_t test_page[4096];

/* ---------- extern ---------- */
extern "C" volatile uint32_t result;

/* ---------- helper ---------- */
static inline void hang() {
    while (1) {
        asm volatile ("nop");
    }
}

/* ============================================================
 * Trap
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
    PIO32 = 0xEF01u;
    PIO32 = scause;
    PIO32 = 0xEF02u;
    PIO32 = sepc;
    PIO32 = 0xEF03u;
    PIO32 = stval;

    if (scause == SCAUSE_INST_PAGE_FAULT) {
        PIO32 = TEST_END_CODE;
        PIO32 = 0xEF12u;
        hang();
    }

    if (scause == SCAUSE_LOAD_PAGE_FAULT) {
        PIO32 = TEST_END_CODE;
        PIO32 = 0xEF13u;
        hang();
    }

    if (scause == SCAUSE_STORE_PAGE_FAULT) {
        PIO32 = TEST_END_CODE;
        PIO32 = 0xEF15u;
        hang();
    }

    PIO32 = TEST_END_CODE;
    PIO32 = 0xEFFFu;
    hang();
}

/* ============================================================
 * S-mode entry
 * ============================================================ */
extern "C" void s_mode_entry() {
    PIO32 = 0xEE61u;

    constexpr uintptr_t VA = 0x00001000u;
    uint32_t read_back = 0;

    asm volatile(
        "li t0, 0xA5A5A5A5\n"
        "sw t0, 0(%[pa])\n"      // PA=test_page
        "lw %[rd], 0(%[va])\n"   // S-mode VA access
        : [rd] "=r"(read_back)
        : [pa] "r"(reinterpret_cast<uintptr_t>(test_page)), [va] "r"(VA)
        : "t0", "memory"
    );

    PIO32 = 0xEE08u;

    result = (read_back == 0xA5A5A5A5u) ? 0x33u : 0xBAD01000u;

    PIO32 = TEST_END_CODE;
    PIO32 = result;
    hang();
}

/* ============================================================
 * run
 *   M-mode で satp を設定し、S-mode に降りて VA access を検証
 * ============================================================ */
extern "C" void run() {
    PIO32 = 0xEE20u;

    /* ========== 1) 初期 SATP ========== */
    result = READ_CSR<CSR_SATP>();
    PIO32 = 0xEE02u;
    PIO32 = result;

    /* ========== 2) trap vector ========== */
    WRITE_CSR<CSR_STVEC>(reinterpret_cast<uint32_t>(&trap_entry));
    WRITE_CSR<CSR_MTVEC>(reinterpret_cast<uint32_t>(&trap_entry));

    /* ========== 3) ページテーブル全クリア ========== */
    for (int i = 0; i < 1024; i++) {
        l1_pt[i]       = 0;
        l0_identity[i] = 0;
        l0_pio[i]      = 0;
    }
    PIO32 = 0xEE03u;

    /* ========== 4) identity-map（vpn1=0, 4MB） ========== */
    for (int i = 0; i < 1024; i++) {
        uint32_t ppn = static_cast<uint32_t>(i);
        l0_identity[i] =
            (ppn << 10) |
            (PTE_V | PTE_R | PTE_W | PTE_X | PTE_A | PTE_D);
    }

    uintptr_t l0_id_phys = reinterpret_cast<uintptr_t>(l0_identity);
    uint32_t  l0_id_ppn  = static_cast<uint32_t>(l0_id_phys >> 12);

    l1_pt[0] = (l0_id_ppn << 10) | PTE_V;   // pointer PTE

    PIO32 = 0xEE04u;

    /* ========== 5) PIO 用マッピング（vpn1=64） ========== */
    static constexpr uintptr_t PIO_ADDR = 0x10001000u;

    uint32_t vpn1_pio = static_cast<uint32_t>((PIO_ADDR >> 22) & 0x3FFu);  // =64
    uint32_t vpn0_pio = static_cast<uint32_t>((PIO_ADDR >> 12) & 0x3FFu);  // =1

    PIO32 = vpn1_pio;
    PIO32 = vpn0_pio;

    uintptr_t l0_pio_phys = reinterpret_cast<uintptr_t>(l0_pio);
    uint32_t  l0_pio_ppn  = static_cast<uint32_t>(l0_pio_phys >> 12);

    l1_pt[vpn1_pio] = (l0_pio_ppn << 10) | PTE_V;

    uint32_t pio_ppn = static_cast<uint32_t>(PIO_ADDR >> 12);
    l0_pio[vpn0_pio] =
        (pio_ppn << 10) |
        (PTE_V | PTE_R | PTE_W | PTE_A | PTE_D);

    PIO32 = 0xEE41u;

    /* ========== 6) VA=0x1000 → test_page（vpn1=0, vpn0=1） ========== */
    constexpr uintptr_t VA = 0x00001000u;

    uint32_t vpn0 = static_cast<uint32_t>((VA >> 12) & 0x3FFu);   // =1

    uintptr_t test_phys = reinterpret_cast<uintptr_t>(test_page);
    uint32_t  test_ppn  = static_cast<uint32_t>(test_phys >> 12);

    l0_identity[vpn0] =
        (test_ppn << 10) |
        (PTE_V | PTE_R | PTE_W | PTE_X | PTE_A | PTE_D);

    PIO32 = 0xEE05u;

    /* ========== 7) SATP 設定 (M-mode) ========== */
    uintptr_t l1_phys = reinterpret_cast<uintptr_t>(l1_pt);
    uint32_t  root_ppn = static_cast<uint32_t>(l1_phys >> 12);

    uint32_t satp_set =
        (SATP_MODE_SV32 << SATP_MODE_SHIFT) |
        (root_ppn & 0x003FFFFFu);

    PIO32 = 0xEE06u;
    PIO32 = satp_set;

    WRITE_CSR<CSR_SATP>(satp_set);
    asm volatile("sfence.vma x0, x0");
    asm volatile ("fence.i" ::: "memory");

    /* ========== 8) MRET で S-mode へ ========== */
    uint32_t mstatus = READ_CSR<CSR_MSTATUS>();
    mstatus &= ~MSTATUS_MPP_MASK;
    mstatus |=  MSTATUS_MPP_S;
    WRITE_CSR<CSR_MSTATUS>(mstatus);

    WRITE_CSR<CSR_MEPC>(reinterpret_cast<uint32_t>(&s_mode_entry));

    PIO32 = 0xEE07u;
    asm volatile("mret");

    PIO32 = TEST_END_CODE;
    PIO32 = 0xE099u;
    hang();
}

/* ---------- extern 実体 ---------- */
extern "C" {
    volatile uint32_t result = 0;
}