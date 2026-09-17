#include "led_api.h"

/* PSC-ONE LED MMIO */
#define PSC_LED_REG \
    (*(volatile uint32_t *)PSC_LED_BASE_ADDR)

/*
 * ソフトウェア側で保持するLED状態。
 *
 * bit0 = LED0
 * bit1 = LED1
 * ...
 * bit5 = LED5
 */
static uint32_t led_state = 0;


/*
 * 6bit LED出力
 */
void led_write(uint32_t value)
{
    led_state = value & PSC_LED_MASK;
    PSC_LED_REG = led_state;
}


/*
 * 指定LEDをON
 *
 * led = 0 ～ 5
 */
void led_on(uint32_t led)
{
    if (led >= 6)
        return;

    led_state |= (1u << led);
    PSC_LED_REG = led_state;
}


/*
 * 指定LEDをOFF
 */
void led_off(uint32_t led)
{
    if (led >= 6)
        return;

    led_state &= ~(1u << led);
    PSC_LED_REG = led_state;
}


/*
 * 指定LEDを反転
 */
void led_toggle(uint32_t led)
{
    if (led >= 6)
        return;

    led_state ^= (1u << led);
    PSC_LED_REG = led_state;
}


/*
 * 全LED ON
 */
void led_all_on(void)
{
    led_write(PSC_LED_MASK);
}


/*
 * 全LED OFF
 */
void led_all_off(void)
{
    led_write(0);
}


/*
 * 現在のLED状態
 */
uint32_t led_get_state(void)
{
    return led_state;
}