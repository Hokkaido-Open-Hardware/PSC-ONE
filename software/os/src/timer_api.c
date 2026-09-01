#include <stdint.h>

/* ------------------------------------------------------------
 * TIMER MMIO
 * ------------------------------------------------------------ */
#define TIMER_CTRL_ADDR    0x10002000u
#define TIMER_COUNT_ADDR   0x10002004u
#define TIMER_STATUS_ADDR  0x10002008u

#define TIMER_CTRL    (*(volatile uint32_t *)TIMER_CTRL_ADDR)
#define TIMER_COUNT   (*(volatile uint32_t *)TIMER_COUNT_ADDR)
#define TIMER_STATUS  (*(volatile uint32_t *)TIMER_STATUS_ADDR)


/* ------------------------------------------------------------
 * TIMER CTRL bit
 * ------------------------------------------------------------ */
#define TIMER_START_BIT       (1u << 16)
#define TIMER_AUTORELOAD_BIT  (1u << 17)
#define TIMER_IRQ_ENABLE_BIT  (1u << 18)
#define TIMER_STOP_BIT        (1u << 19)
#define TIMER_CLEAR_IRQ_BIT   (1u << 20)

#define TIMER_RELOAD_MASK     0xFFFFu

/*
 * PSC-ONE runs this timer from 100MHz and the RTL prescaler divides by 100,
 * so one timer tick is 1us.  Expiry occurs on the tick after counter reaches
 * zero; reload=999 therefore gives exactly 1000 ticks = 1ms.
 */
#define TIMER_SCHEDULER_RELOAD 999u

/* ------------------------------------------------------------
 * TIMER STATUS bit
 * ------------------------------------------------------------ */
#define TIMER_ST_RUNNING      (1u << 7)
#define TIMER_ST_AUTORELOAD   (1u << 8)
#define TIMER_ST_IRQ_ENABLE   (1u << 9)
#define TIMER_ST_IRQ_PENDING  (1u << 10)


/* ------------------------------------------------------------
 * タイマー開始
 * ------------------------------------------------------------ */
void timer_start(uint32_t reload)
{
    TIMER_CTRL =
        (reload & TIMER_RELOAD_MASK) |
        TIMER_START_BIT;
}


/* ------------------------------------------------------------
 * 自動リロードタイマー開始
 * ------------------------------------------------------------ */
void timer_start_auto(uint32_t reload)
{
    TIMER_CTRL =
        (reload & TIMER_RELOAD_MASK) |
        TIMER_START_BIT |
        TIMER_AUTORELOAD_BIT;
}

void timer_start_scheduler_tick(void)
{
    TIMER_CTRL =
        TIMER_SCHEDULER_RELOAD |
        TIMER_START_BIT |
        TIMER_AUTORELOAD_BIT |
        TIMER_IRQ_ENABLE_BIT;
}

void timer_clear_scheduler_irq(void)
{
    /* Preserve reload/autoreload/IRQ-enable while applying pending W1C. */
    TIMER_CTRL =
        TIMER_SCHEDULER_RELOAD |
        TIMER_AUTORELOAD_BIT |
        TIMER_IRQ_ENABLE_BIT |
        TIMER_CLEAR_IRQ_BIT;
}


/* ------------------------------------------------------------
 * タイマー停止
 * ------------------------------------------------------------ */
void timer_stop(void)
{
    TIMER_CTRL = TIMER_STOP_BIT;
}


/* ------------------------------------------------------------
 * 現在のカウンタ値取得
 * ------------------------------------------------------------ */
uint32_t timer_get_count(void)
{
    return TIMER_COUNT & TIMER_RELOAD_MASK;
}


/* ------------------------------------------------------------
 * ステータス取得
 * ------------------------------------------------------------ */
uint32_t timer_get_status(void)
{
    return TIMER_STATUS;
}


/* ------------------------------------------------------------
 * タイマー動作中か
 * ------------------------------------------------------------ */
int timer_is_running(void)
{
    return (TIMER_STATUS & TIMER_ST_RUNNING) != 0u;
}


/* ------------------------------------------------------------
 * タイマーウェイト 1usec
 * ------------------------------------------------------------ */
void timer_wait_us(uint32_t us)
{
    while (us != 0u) {
        uint32_t count;

        if (us > 0xFFFFu) {
            count = 0xFFFFu;
        } else {
            count = us;
        }

        timer_start(count);

        while (timer_is_running()) {
        }

        us -= count;
    }
}

/* ------------------------------------------------------------
 * タイマーウェイト 1msec
 * ------------------------------------------------------------ */
void timer_wait_ms(uint32_t ms)
{
    while (ms-- != 0u) {
        timer_wait_us(1000u);
    }
}
