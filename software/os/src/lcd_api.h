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