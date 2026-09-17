// dma.h
#pragma once

#define CSR_DMA_CTRL   0x7E0
#define CSR_DMA_WORDS  0x7E4
#define CSR_DMA_SRC    0x7E8
#define CSR_DMA_DST    0x7EC
#define CSR_DMA_STATUS 0x7F0

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