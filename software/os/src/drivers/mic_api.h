// mic_api.h
#pragma once

/* ===== MMIO 定義 ===== */
#define PSC_I2S_RX  (*(volatile uint32_t*)0x10007000u)
#define PSC_I2S_ST  (*(volatile uint32_t*)0x10007004u)

//#define I2S_RX      0x10007000u
//#define I2S_ST      0x10007004u

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

int mic_wait_sample(void);
int mic_read_raw(uint32_t *sample);
int mic_read_sample24(uint32_t *sample24);
uint32_t mic_read_samples24(uint32_t *buf, uint32_t count);

// syscall
uint32_t s_call_mic_read_samples24(uint32_t count);
uint32_t s_call_mic_write_samples24(uint32_t count, uint32_t start_sector);