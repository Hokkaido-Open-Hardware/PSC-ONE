// common.h
#pragma once
#include <stddef.h>  

// PSC_OS
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

#define align_up(value, align)   __builtin_align_up(value, align)
#define is_aligned(value, align) __builtin_is_aligned(value, align)

#define va_list  __builtin_va_list
#define va_start __builtin_va_start
#define va_end   __builtin_va_end
#define va_arg   __builtin_va_arg

#define PAGE_SIZE 4096

static inline void mmio_w32(uint32_t addr, uint32_t v) {
    *(volatile uint32_t*)addr = v;
}
static inline uint32_t mmio_r32(uint32_t addr) {
    return *(volatile uint32_t*)addr;
}

void *memset(void *buf, char c, size_t n);
void *memcpy(void *dst, const void *src, size_t n);
int memcmp(const void *a, const void *b, size_t n);
void *dma_memcpy(void *dst, const void *src, size_t n);
void s_print_int(int v);
void s_printf(const char *fmt, ...);
void hexdump(const void *addr, size_t len, uintptr_t base_addr_label);
void cmd_dump(int argc, const char **argv);
