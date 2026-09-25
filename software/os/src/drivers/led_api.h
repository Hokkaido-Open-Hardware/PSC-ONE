#ifndef LED_API_H
#define LED_API_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define PSC_LED_BASE_ADDR  0x10004000u
#define PSC_LED_MASK       0x3Fu

void led_write(uint32_t value);
void led_on(uint32_t led);
void led_off(uint32_t led);
void led_toggle(uint32_t led);
void led_all_on(void);
void led_all_off(void);
uint32_t led_get_state(void);

#ifdef __cplusplus
}
#endif

#endif /* LED_API_H */