// mem_test.h
#pragma once

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

void random_mem_check(uint32_t start_addr, uint32_t end_addr);
void seqential_mem_check(uint32_t start_addr, uint32_t end_addr);