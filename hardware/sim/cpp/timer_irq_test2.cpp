#include <cstdint>

/*
 * timer_irq_test2.cpp
 *
 * PSC_RV32IS_TIMER interrupt PC jump test
 *
 * Test:
 *   1. Set mtvec = timer_irq_target
 *   2. Enable mie.MTIE
 *   3. Enable mstatus.MIE
 *   4. Start TIMER one-shot
 *   5. Wait for timer IRQ
 *   6. Confirm CPU jumps to exact mtvec target
 *   7. Confirm mcause = Machine Timer Interrupt
 *   8. Clear TIMER IRQ
 *   9. Return by mret
 *  10. Confirm execution resumes normally
 *  11. PASS / FAIL output to PIO32
 */


/* ============================================================
 * PIO
 * ============================================================ */

#define PIO32 \
    (*reinterpret_cast<volatile uint32_t *>(0x10001000u))

static constexpr uint32_t TEST_END_CODE = 0xEE01u;


/* ============================================================
 * TIMER MMIO
 * ============================================================ */

#define TIMER_CTRL \
    (*reinterpret_cast<volatile uint32_t *>(0x10002000u))

#define TIMER_COUNT \
    (*reinterpret_cast<volatile uint32_t *>(0x10002004u))

#define TIMER_STATUS \
    (*reinterpret_cast<volatile uint32_t *>(0x10002008u))


/*
 * TIMER CTRL
 *
 * bit 15:0 : reload_val
 * bit 16   : start
 * bit 17   : autoreload
 * bit 18   : irq_enable
 * bit 19   : stop
 * bit 20   : clear_irq
 */

#define TIMER_START       (1u << 16)
#define TIMER_AUTORELOAD  (1u << 17)
#define TIMER_IRQ_ENABLE  (1u << 18)
#define TIMER_STOP        (1u << 19)
#define TIMER_CLEAR_IRQ   (1u << 20)


/*
 * TIMER STATUS
 *
 * bit 7  : running
 * bit 8  : autoreload
 * bit 9  : irq_enable
 * bit 10 : irq_pending
 */

#define TIMER_ST_RUNNING      (1u << 7)
#define TIMER_ST_AUTORELOAD   (1u << 8)
#define TIMER_ST_IRQ_ENABLE   (1u << 9)
#define TIMER_ST_IRQ_PENDING  (1u << 10)


/* ============================================================
 * CSR
 * ============================================================ */

#define CSR_MSTATUS   0x300u
#define CSR_MIE       0x304u
#define CSR_MTVEC     0x305u
#define CSR_MEPC      0x341u
#define CSR_MCAUSE    0x342u
#define CSR_MIP       0x344u


template <uint32_t CSR>
static inline uint32_t read_csr()
{
    uint32_t value;

    asm volatile(
        "csrr %0, %1"
        : "=r"(value)
        : "i"(CSR)
    );

    return value;
}


template <uint32_t CSR>
static inline void write_csr(uint32_t value)
{
    asm volatile(
        "csrw %0, %1"
        :
        : "i"(CSR), "r"(value)
    );
}


template <uint32_t CSR>
static inline void set_csr(uint32_t mask)
{
    asm volatile(
        "csrs %0, %1"
        :
        : "i"(CSR), "r"(mask)
    );
}


template <uint32_t CSR>
static inline void clr_csr(uint32_t mask)
{
    asm volatile(
        "csrc %0, %1"
        :
        : "i"(CSR), "r"(mask)
    );
}


/* ============================================================
 * interrupt bits
 * ============================================================ */

#define MSTATUS_MIE    (1u << 3)
#define MIE_MTIE       (1u << 7)

static constexpr uint32_t EXPECT_MCAUSE_TIMER =
    0x80000007u;


/* ============================================================
 * result
 * ============================================================ */

extern "C" volatile uint32_t result;
extern "C" volatile uint32_t results[8];

extern "C" volatile uint32_t irq_target_reached;
extern "C" volatile uint32_t timer_irq_count;


/* ============================================================
 * Timer IRQ target
 *
 * mtvec points directly to this address.
 *
 * If CPU really changes PC to mtvec when timer IRQ occurs,
 * execution MUST start here.
 * ============================================================ */

extern "C" void timer_irq_target(void);

asm(
".section .text                          \n"
".align  2                               \n"
".globl  timer_irq_target                \n"
".type   timer_irq_target, @function     \n"

"timer_irq_target:                       \n"

    /*
     * Save temporary registers used by this handler.
     */

"    addi  sp, sp, -16                   \n"
"    sw    t0,  0(sp)                    \n"
"    sw    t1,  4(sp)                    \n"
"    sw    t2,  8(sp)                    \n"
"    sw    t3, 12(sp)                    \n"


    /*
     * --------------------------------------------------------
     * FIRST observable action at the IRQ target.
     *
     * If this appears, PC reached timer_irq_target.
     * --------------------------------------------------------
     */

"    li    t3, 0x10001000                \n"
"    li    t0, 0x0000A202                \n"
"    sw    t0, 0(t3)                     \n"


    /*
     * irq_target_reached = 1
     */

"    la    t3, irq_target_reached        \n"
"    li    t0, 1                         \n"
"    sw    t0, 0(t3)                     \n"


    /*
     * timer_irq_count++
     */

"    la    t3, timer_irq_count           \n"
"    lw    t0, 0(t3)                     \n"
"    addi  t0, t0, 1                     \n"
"    sw    t0, 0(t3)                     \n"


    /*
     * Save mcause
     *
     * results[4] = mcause
     */

"    la    t3, results                   \n"
"    csrr  t0, mcause                    \n"
"    sw    t0, 16(t3)                    \n"


    /*
     * Save mepc
     *
     * results[5] = mepc
     */

"    csrr  t0, mepc                      \n"
"    sw    t0, 20(t3)                    \n"


    /*
     * Save mtvec observed inside handler
     *
     * results[6] = mtvec
     */

"    csrr  t0, mtvec                     \n"
"    sw    t0, 24(t3)                    \n"


    /*
     * Clear TIMER IRQ.
     *
     * TIMER_CTRL =
     *     TIMER_IRQ_ENABLE |
     *     TIMER_CLEAR_IRQ
     *
     * 0x00040000 = IRQ_ENABLE
     * 0x00100000 = CLEAR_IRQ
     */

"    li    t3, 0x10002000                \n"
"    li    t0, 0x00140000                \n"
"    sw    t0, 0(t3)                     \n"


    /*
     * Restore registers.
     */

"    lw    t0,  0(sp)                    \n"
"    lw    t1,  4(sp)                    \n"
"    lw    t2,  8(sp)                    \n"
"    lw    t3, 12(sp)                    \n"
"    addi  sp, sp, 16                    \n"


    /*
     * Timer interrupt:
     *
     * DO NOT increment mepc.
     */

"    mret                                 \n"

".size timer_irq_target, .-timer_irq_target\n"
);


/* ============================================================
 * fail utility
 * ============================================================ */

static inline void note_fail(
    uint32_t &fail,
    uint32_t bit
)
{
    fail |= bit;
}


/* ============================================================
 * run
 * ============================================================ */

extern "C" void run()
{
    uint32_t fail = 0;


    /* --------------------------------------------------------
     * 0) Disable interrupts first
     * -------------------------------------------------------- */

    clr_csr<CSR_MSTATUS>(MSTATUS_MIE);
    clr_csr<CSR_MIE>(MIE_MTIE);


    /* --------------------------------------------------------
     * 1) Set exact PC target into mtvec
     * -------------------------------------------------------- */

    const uint32_t target_addr =
        reinterpret_cast<uint32_t>(&timer_irq_target);

    write_csr<CSR_MTVEC>(target_addr);

    results[0] = target_addr;

    PIO32 = 0x00E0;


    /* --------------------------------------------------------
     * 2) Verify mtvec readback
     * -------------------------------------------------------- */

    const uint32_t mtvec_before =
        read_csr<CSR_MTVEC>();

    results[1] = mtvec_before;

    if (mtvec_before != target_addr) {
        note_fail(
            fail,
            1u << 0
        );
    }

    PIO32 = 0x00E1;


    /* --------------------------------------------------------
     * 3) Clear TIMER old state
     * -------------------------------------------------------- */

    TIMER_CTRL =
        TIMER_STOP |
        TIMER_CLEAR_IRQ;

    irq_target_reached = 0;
    timer_irq_count = 0;

    PIO32 = 0x00E2;


    /* --------------------------------------------------------
     * 4) Enable Machine Timer Interrupt
     * -------------------------------------------------------- */

    set_csr<CSR_MIE>(MIE_MTIE);

    const uint32_t mie =
        read_csr<CSR_MIE>();

    results[2] = mie;

    if ((mie & MIE_MTIE) == 0) {
        note_fail(
            fail,
            1u << 1
        );
    }


    /* --------------------------------------------------------
     * 5) Enable global M interrupt
     * -------------------------------------------------------- */

    set_csr<CSR_MSTATUS>(MSTATUS_MIE);

    const uint32_t mstatus =
        read_csr<CSR_MSTATUS>();

    results[3] = mstatus;

    if ((mstatus & MSTATUS_MIE) == 0) {
        note_fail(
            fail,
            1u << 2
        );
    }

    PIO32 = 0x00E3;


    /* --------------------------------------------------------
     * 6) Start TIMER
     *
     * one-shot
     * reload = 1000 ticks
     * -------------------------------------------------------- */

    static constexpr uint32_t TIMER_RELOAD =
        1000u;

    TIMER_CTRL =
        TIMER_RELOAD |
        TIMER_START |
        TIMER_IRQ_ENABLE;

    PIO32 = 0x00E4;


    /* --------------------------------------------------------
     * 7) Execute normal code while waiting.
     *
     * Timer interrupt should asynchronously change PC from
     * this loop to timer_irq_target.
     * -------------------------------------------------------- */

    uint32_t timeout =
        10000000u;

    while (
        (irq_target_reached == 0u) &&
        (timeout != 0u)
    ) {
        timeout--;

        asm volatile("nop");
    }


    /* --------------------------------------------------------
     * If mret worked, execution returns here eventually.
     * -------------------------------------------------------- */

    PIO32 = 0x00E5;


    /* --------------------------------------------------------
     * 8) Did target execute?
     * -------------------------------------------------------- */

    if (irq_target_reached != 1u) {
        note_fail(
            fail,
            1u << 3
        );
    }


    /* --------------------------------------------------------
     * 9) One-shot IRQ must occur exactly once
     * -------------------------------------------------------- */

    if (timer_irq_count != 1u) {
        note_fail(
            fail,
            1u << 4
        );
    }


    /* --------------------------------------------------------
     * 10) mcause
     * -------------------------------------------------------- */

    if (results[4] != EXPECT_MCAUSE_TIMER) {
        note_fail(
            fail,
            1u << 5
        );
    }


    /* --------------------------------------------------------
     * 11) mtvec seen from IRQ handler must equal target
     * -------------------------------------------------------- */

    if (results[6] != target_addr) {
        note_fail(
            fail,
            1u << 6
        );
    }


    /* --------------------------------------------------------
     * 12) TIMER pending must be cleared
     * -------------------------------------------------------- */

    const uint32_t timer_status =
        TIMER_STATUS;

    results[7] = timer_status;

    if (timer_status & TIMER_ST_IRQ_PENDING) {
        note_fail(
            fail,
            1u << 7
        );
    }


    /* --------------------------------------------------------
     * 13) Disable interrupts
     * -------------------------------------------------------- */

    clr_csr<CSR_MSTATUS>(MSTATUS_MIE);
    clr_csr<CSR_MIE>(MIE_MTIE);

    TIMER_CTRL =
        TIMER_STOP |
        TIMER_CLEAR_IRQ;


    /* --------------------------------------------------------
     * result
     *
     * timer_irq_test2 PASS = 0x0322
     * -------------------------------------------------------- */

    if (fail == 0u) {

        result = 0x0322u;

    } else {

        result =
            0xBAD00000u |
            fail;
    }


    /* --------------------------------------------------------
     * Test end
     * -------------------------------------------------------- */

    PIO32 = TEST_END_CODE;
    PIO32 = result;


    while (1) {
    }
}


/* ============================================================
 * globals
 * ============================================================ */

extern "C" {

volatile uint32_t result = 0;

volatile uint32_t results[8] = {
    0
};

volatile uint32_t irq_target_reached = 0;

volatile uint32_t timer_irq_count = 0;

}