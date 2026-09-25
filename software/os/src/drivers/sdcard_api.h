// sdcard_api.h
#pragma once

/* ===== MMIO 定義 ===== */

#define PSC_IF_DATA     (*(volatile uint32_t*)0x10006000u)
#define PSC_SD_SECTOR   (*(volatile uint32_t*)0x10006004u)
#define PSC_SD_IF_CTRL  (*(volatile uint32_t*)0x10006008u)

//#define SD_DATA_ADDR     0x10006000u
//#define SD_SECTOR_ADDR   0x10006004u
//#define SD_IF_CTRL_ADDR  0x10006008u

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

int sd_read_sector(uint32_t sector, uint8_t *buf);
int sd_write_sector(uint32_t sector, uint8_t *buf);

void s_call_sdcard_read_api(uint32_t sd_sector_address);
int s_call_sdcard_write_api(uint32_t sd_sector_address, const uint8_t *buf);