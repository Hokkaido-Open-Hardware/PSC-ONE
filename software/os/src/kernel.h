#pragma once
#include <stddef.h>  // offsetof 用（必要なら）

#define PROCS_MAX 8
#define PROC_UNUSED   0
#define PROC_RUNNABLE 1
#define PROC_EXITED   2

#define SATP_SV32   (1u << 31)
#define SSTATUS_SPIE (1 << 5)
#define SSTATUS_SUM  (1 << 18)

#define SCAUSE_ECALL 8
#define SCAUSE_INST_MISALIGNED  0

// USER_BASE は run.sh から -DUSER_BASE=... で渡す。
// 未指定ならデフォルト値（0x0040_0000）を使用。
#ifndef USER_BASE
#define USER_BASE 0x00400000u
#endif

// USER_STACK_TOP = USER_BASE + 1MB
#define USER_STACK_TOP   (USER_BASE + 0x00100000u)
#define USER_STACK_SIZE  (128 * 1024)
#define USER_STACK_GUARD (4 * 1024)

// user stack: 128KB
#define USER_STACK_SIZE (128 * 1024)

#define PAGE_V (1 << 0)
#define PAGE_R (1 << 1)
#define PAGE_W (1 << 2)
#define PAGE_X (1 << 3)
#define PAGE_U (1 << 4)

struct sbiret { long error; long value; };

#define PANIC(fmt, ...) do { \
  s_printf("PANIC: %s:%d: " fmt "\n", __FILE__, __LINE__, ##__VA_ARGS__); \
  while (1) {} \
} while (0)

struct process {
  int pid;
  int state;

  // context
  vaddr_t sp;

  // memory
  uint32_t *page_table;

  // kernel stack
  uint8_t stack[8192];
};

struct trap_frame {
  uint32_t ra, gp, tp;
  uint32_t t0, t1, t2, t3, t4, t5, t6;
  uint32_t a0, a1, a2, a3, a4, a5, a6, a7;
  uint32_t s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11;
  uint32_t sp;
} __attribute__((packed));

#define READ_CSR(reg) ({ unsigned long __tmp; \
  __asm__ __volatile__("csrr %0, " #reg : "=r"(__tmp)); __tmp; })

#define WRITE_CSR(reg, value) do { uint32_t __tmp = (value); \
  __asm__ __volatile__("csrw " #reg ", %0" :: "r"(__tmp)); } while (0)


  /* kernel.h に追加する関数宣言（プロトタイプ） */
// --- SBI/Console ---
struct sbiret sbi_call(long arg0, long arg1, long arg2, long arg3,
                       long arg4, long arg5, long fid, long eid);
void putchar(char ch);
void uart_putchar(char ch);
long uart_getchar(void);

// --- メモリ管理/ページング ---
paddr_t alloc_pages(uint32_t n);
void map_page(uint32_t *table1, uint32_t vaddr, paddr_t paddr, uint32_t flags);

// --- 例外/トラップ/ブート ---
__attribute__((naked)) void user_entry(void);
__attribute__((naked, aligned(4))) void kernel_entry(void);
void handle_syscall(struct trap_frame *f);
void handle_trap(struct trap_frame *f);
__attribute__((section(".text.boot"), naked)) void boot(void);
void kernel_main(void);

// --- スケジューラ/プロセス ---
__attribute__((naked))
void switch_context(uint32_t *prev_sp, uint32_t *next_sp);

struct process *create_process(const void *image, size_t image_size);
void yield(void);

// --- デモ用（必要なら残す） ---
void delay(void);
void proc_a_entry(void);
void proc_b_entry(void);