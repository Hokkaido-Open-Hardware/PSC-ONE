// user.h
#pragma once

#ifndef USER_BASE
#define USER_BASE 0x00400000u
#endif

#ifdef USE_SBI_CONSOLE
static inline void uart_init(void) { /* no-op on SBI */ }
#else
void uart_init(void);
#endif

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
#define NULL  ((void *) 0)

#define align_up(value, align)   __builtin_align_up(value, align)
#define is_aligned(value, align) __builtin_is_aligned(value, align)
#define offsetof(type, member)   __builtin_offsetof(type, member)

#define va_list  __builtin_va_list
#define va_start __builtin_va_start
#define va_end   __builtin_va_end
#define va_arg   __builtin_va_arg

uint32_t cluster_to_lba(uint32_t cluster);
int fat32_mount(void);

// Systlic Array
void call_sa_api(uint32_t matrix_size);
// Mic
void call_mic_api(unsigned count);
void call_mic_write_api(unsigned count);
uint32_t call_mic_write_file(uint32_t count);
// SD Card
void call_sd_read_api(unsigned sector);
void call_sd_write_test_api(unsigned sector);
uint32_t call_sd_write_buf_api(uint32_t sector, const uint8_t *buf);
int call_sd_read_buf_api(uint32_t sector, void *buf);
// speech
void cmd_speech(void);
int call_speech_recognition_api(void);
// Dump command
void call_dump_api(uint32_t addr, uint32_t len);

int test_div(int a, int b);
int test_mod(int a, int b);
bool is_prime(unsigned n);
unsigned parse_u32(const char *s);
void putchar(char ch);
int getchar(void);
int getchar_timeout(void);
void print_int(int v);

static inline uint32_t sa_api(uint32_t sysno, uint32_t arg0, uint32_t arg1, uint32_t arg2, uint32_t arg4);
static inline uint32_t mic_api(uint32_t sysno, uint32_t arg0);

inline static uint32_t sd_api(uint32_t sysno, uint32_t arg0);
static inline uint32_t sd_api2(uint32_t sysno, uint32_t arg0, uint32_t arg1);

inline static void dump_api(uint32_t sysno, uint32_t arg0, uint32_t arg1);
char *strcpy(char *dst, const char *src);
int strcmp(const char *s1, const char *s2);
void cmd_primes(unsigned max);
int parse_hex(const char *s, uintptr_t *out);
uint32_t poll_switch_api(void);
void printf(const char *fmt, ...);
__attribute__((noreturn)) void exit(void);
