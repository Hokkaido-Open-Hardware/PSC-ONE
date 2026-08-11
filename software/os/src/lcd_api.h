// lcd_api.h
#pragma once

/* ===== MMIO 定義 ===== */
#define PSC_LCD_PIXS_DATA   (*(volatile uint32_t*)0x10003000u)
#define PSC_LCD_PIXS_ST     (*(volatile uint32_t*)0x10003004u)

#define LCD_PIXS_DATA     0x10003000u
#define LCD_PIXS_ST       0x10003004u

typedef int bool;
typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int uint32_t;
typedef unsigned long long uint64_t;
typedef uint32_t size_t;
typedef uint32_t uintptr_t;
typedef uint32_t paddr_t;
typedef uint32_t vaddr_t;

#define true  1
#define false 0

void lcd_draw_boot_logo(void);
void lcd_draw_text(void);

// ============================================================
// LCD TEXT API
// ============================================================

void lcd_clear(void);

void lcd_set_cursor(
    uint32_t x,
    uint32_t y
);

uint32_t lcd_get_cursor_x(void);
uint32_t lcd_get_cursor_y(void);

void lcd_draw_char(
    uint32_t x,
    uint32_t y,
    char ch
);

void lcd_putc(char ch);

void lcd_puts(
    const char *str
);

void lcd_printf(const char *fmt, ...);