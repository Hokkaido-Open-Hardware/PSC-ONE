#include <cstdint>

/*
 * timer_irq_test1.cpp
 *
 * PSC_RV32IS_TIMER interrupt test
 *
 * Test:
 *   1. mtvec setup
 *   2. mie.MTIE enable
 *   3. mstatus.MIE enable
 *   4. TIMER one-shot start
 *   5. wait for timer IRQ
 *   6. trap handler checks mcause
 *   7. clear timer IRQ
 *   8. return by mret
 *   9. PASS / FAIL output to PIO32
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


/*
 * Machine Timer Interrupt
 *
 * mcause:
 *
 * bit31 = interrupt
 * cause = 7
 */

static constexpr uint32_t EXPECT_MCAUSE_TIMER =
    0x80000007u;


/* ============================================================
 * result
 * ============================================================ */

extern "C" volatile uint32_t result;
extern "C" volatile uint32_t results[8];

extern "C" volatile uint32_t timer_irq_count;


/* ============================================================
 * M-mode timer interrupt handler
 *
 * IMPORTANT:
 *
 * Interrupt is different from ECALL.
 *
 * ECALL:
 *      mepc += 4
 *
 * Interrupt:
 *      mepc MUST NOT be incremented.
 *
 * mret returns directly to interrupted code.
 * ============================================================ */

extern "C" void timer_trap_handler(void);

asm(
".section .text                          \n"
".align  2                               \n"
".globl  timer_trap_handler              \n"
".type   timer_trap_handler, @function   \n"

"timer_trap_handler:                     \n"

    /*
     * results[6] = mcause
     * results[7] = mepc
     */

"    la    t3, results                   \n"

"    csrr  t0, mcause                    \n"
"    sw    t0, 24(t3)                    \n"

"    csrr  t1, mepc                      \n"
"    sw    t1, 28(t3)                    \n"


    /*
     * timer_irq_count++
     */

"    la    t3, timer_irq_count           \n"
"    lw    t0, 0(t3)                     \n"
"    addi  t0, t0, 1                     \n"
"    sw    t0, 0(t3)                     \n"


    /*
     * Clear TIMER IRQ
     *
     * TIMER_CTRL = IRQ_ENABLE | CLEAR_IRQ
     *
     * irq_enable must remain 1 because writing the control
     * register also updates irq_enable.
     */

"    li    t3, 0x10002000                \n"
"    li    t0, 0x00140000                \n"
"    sw    t0, 0(t3)                     \n"


    /*
     * Debug PIO
     */

"    li    t3, 0x10001000                \n"
"    li    t0, 0x0000A101                \n"
"    sw    t0, 0(t3)                     \n"


    /*
     * Interrupt:
     *
     * DO NOT mepc += 4
     */

"    mret                                \n"

".size timer_trap_handler, .-timer_trap_handler\n"
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
     * 1) mtvec
     * -------------------------------------------------------- */

    const uint32_t handler_addr =
        reinterpret_cast<uint32_t>(&timer_trap_handler);

    write_csr<CSR_MTVEC>(handler_addr);

    results[0] = handler_addr;

    PIO32 = 0x00D0;


    /* --------------------------------------------------------
     * 2) Clear old TIMER state / IRQ
     * -------------------------------------------------------- */

    TIMER_CTRL =
        TIMER_STOP |
        TIMER_CLEAR_IRQ;

    timer_irq_count = 0;

    PIO32 = 0x00D1;


    /* --------------------------------------------------------
     * 3) Enable Machine Timer Interrupt
     * -------------------------------------------------------- */

    set_csr<CSR_MIE>(MIE_MTIE);

    uint32_t mie =
        read_csr<CSR_MIE>();

    results[1] = mie;

    if ((mie & MIE_MTIE) == 0) {
        note_fail(
            fail,
            1u << 0
        );
    }


    /* --------------------------------------------------------
     * 4) Enable global M-mode interrupt
     * -------------------------------------------------------- */

    set_csr<CSR_MSTATUS>(MSTATUS_MIE);

    uint32_t mstatus =
        read_csr<CSR_MSTATUS>();

    results[2] = mstatus;

    if ((mstatus & MSTATUS_MIE) == 0) {
        note_fail(
            fail,
            1u << 1
        );
    }

    PIO32 = 0x00D2;


    /* --------------------------------------------------------
     * 5) Start TIMER
     *
     * reload = 1000 ticks
     * one-shot
     * IRQ enabled
     * -------------------------------------------------------- */

    static constexpr uint32_t TIMER_RELOAD = 1000u;

    TIMER_CTRL =
        TIMER_RELOAD |
        TIMER_START |
        TIMER_IRQ_ENABLE;

    PIO32 = 0x00D3;


    /* --------------------------------------------------------
     * 6) Check TIMER status immediately
     * -------------------------------------------------------- */

    uint32_t timer_status =
        TIMER_STATUS;

    results[3] = timer_status;

    if ((timer_status & TIMER_ST_IRQ_ENABLE) == 0) {
        note_fail(
            fail,
            1u << 2
        );
    }


    /* --------------------------------------------------------
     * 7) Wait interrupt
     * -------------------------------------------------------- */

    uint32_t timeout = 10000000u;

    while (
        (timer_irq_count == 0) &&
        (timeout != 0)
    ) {
        timeout--;

        asm volatile("nop");
    }

    PIO32 = 0x00D4;


    /* --------------------------------------------------------
     * 8) Timeout check
     * -------------------------------------------------------- */

    if (timer_irq_count == 0) {
        note_fail(
            fail,
            1u << 3
        );
    }


    /* --------------------------------------------------------
     * 9) IRQ count
     *
     * one-shotなので1回だけのはず
     * -------------------------------------------------------- */

    results[4] = timer_irq_count;

    if (timer_irq_count != 1u) {
        note_fail(
            fail,
            1u << 4
        );
    }


    /* --------------------------------------------------------
     * 10) mcause
     * -------------------------------------------------------- */

    uint32_t mcause =
        results[6];

    if (mcause != EXPECT_MCAUSE_TIMER) {
        note_fail(
            fail,
            1u << 5
        );
    }


    /* --------------------------------------------------------
     * 11) TIMER irq_pending should be cleared
     * -------------------------------------------------------- */

    timer_status =
        TIMER_STATUS;

    results[5] = timer_status;

    if (timer_status & TIMER_ST_IRQ_PENDING) {
        note_fail(
            fail,
            1u << 6
        );
    }


    /* --------------------------------------------------------
     * 12) Disable interrupt
     * -------------------------------------------------------- */

    clr_csr<CSR_MSTATUS>(MSTATUS_MIE);
    clr_csr<CSR_MIE>(MIE_MTIE);

    TIMER_CTRL =
        TIMER_STOP |
        TIMER_CLEAR_IRQ;


    /* --------------------------------------------------------
     * result
     * -------------------------------------------------------- */

    if (fail == 0) {

        result = 0x0321u;

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

volatile uint32_t timer_irq_count = 0;

}