#include "common.h"
#include "syscall.h"
#include "synap_api.h"
#include "sdcard_api.h"
#include "mic_api.h"
#include "lcd_api.h"
#include "fft_api.h"
#include "mem_test.h"
#include "speech_recognition_api.h"
#include "kernel.h"
#include <stdint.h>

extern uint8_t  _binary_shell_bin_start[];
extern uint8_t  _binary_shell_bin_end[];

extern char __kernel_base[];
struct process procs[PROCS_MAX];
struct process *current_proc;
struct process *idle_proc;

extern char __bss[], __bss_end[], __kernel_stack_top[];

struct virtio_virtq *blk_request_vq;
struct virtio_blk_req *blk_req;
paddr_t blk_req_paddr;
uint64_t blk_capacity;

#ifdef USE_SBI_CONSOLE
struct sbiret sbi_call(long arg0, long arg1, long arg2, long arg3, long arg4,
                       long arg5, long fid, long eid) {
    register long a0 __asm__("a0") = arg0;
    register long a1 __asm__("a1") = arg1;
    register long a2 __asm__("a2") = arg2;
    register long a3 __asm__("a3") = arg3;
    register long a4 __asm__("a4") = arg4;
    register long a5 __asm__("a5") = arg5;
    register long a6 __asm__("a6") = fid;
    register long a7 __asm__("a7") = eid;

    __asm__ __volatile__("ecall"
                         : "=r"(a0), "=r"(a1)
                         : "r"(a0), "r"(a1), "r"(a2), "r"(a3), "r"(a4), "r"(a5),
                           "r"(a6), "r"(a7)
                         : "memory");
    return (struct sbiret){.error = a0, .value = a1};
}
#endif

#ifdef USE_SBI_CONSOLE

void uart_putchar(char ch) {
    sbi_call(ch, 0, 0, 0, 0, 0, 0, 1 /* Console Putchar */);
}

long uart_getchar(void) {
    struct sbiret ret = sbi_call(0, 0, 0, 0, 0, 0, 0, 2);
    return ret.error;
}

#else   // ==== MMIO版（FPGA用）====

#ifndef PIO32_ADDR
#define PIO32_ADDR (*(volatile uint32_t *)0x10001000)
#endif

// UART ベースやビット定義が common.h に無ければ保険として定義
#ifndef UART_MMIO_BASE
#define UART_MMIO_BASE 0x10000000u
#endif

#ifndef UART_TX
#define UART_TX 0x0
#endif
#ifndef UART_RX
#define UART_RX 0x4
#endif
#ifndef UART_ST
#define UART_ST 0x8
#endif

#ifndef ST_TX_BUSY
#define ST_TX_BUSY (1u << 0)
#endif
#ifndef ST_RX_AVAIL
#define ST_RX_AVAIL (1u << 1)
#endif
// kernel.c もしくは uart.c
// S-Mode用: putchar
void putchar(char ch) {
    // 送信ビジー解除待ち
    while (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_TX_BUSY) {
        __asm__ __volatile__("nop");
    }
    mmio_w32(UART_MMIO_BASE + UART_TX, (uint32_t)(uint8_t)ch);
}

// U-Mode ecall 用: putchar
void uart_putchar(char ch) {
    // 送信ビジー解除待ち
    while (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_TX_BUSY) {
        __asm__ __volatile__("nop");
    }
    mmio_w32(UART_MMIO_BASE + UART_TX, (uint32_t)(uint8_t)ch);
}

// タイムアウト処理付き
// TBD
long uart_getchar_timeout(uint32_t timeout)
{
    while (timeout--) {
        if (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_RX_AVAIL) {
            return (long)(mmio_r32(UART_MMIO_BASE + UART_RX) & 0xFF);
        }

        __asm__ __volatile__("nop");
    }

    return -1;      // タイムアウト
}

// U-Mode ecall 用: getchar
long uart_getchar(void) {
    // ブロッキング受信：来るまで待つ
    while ((mmio_r32(UART_MMIO_BASE + UART_ST) & ST_RX_AVAIL) == 0) {
        __asm__ __volatile__("nop");
    }
    return (long)(mmio_r32(UART_MMIO_BASE + UART_RX) & 0xFF);
}

#endif  // USE_SBI_CONSOLE

extern char __free_ram[], __free_ram_end[];

#if 0
static inline uint32_t read_sp(void){
    uint32_t x;
    __asm__ volatile("mv %0, sp" : "=r"(x));
    return x;
}
#endif

paddr_t alloc_pages(uint32_t n) {
    //printf("SP=%x\n", read_sp());
    static int initialized = 0;
    static paddr_t next_paddr;

    //printf("alloc_pages START\n");
    //printf(" initialized=%x\n", (uint32_t)initialized);
    //printf(" next_paddr(before)=%x\n", next_paddr);
    //printf(" __free_ram=%x __free_ram_end=%x\n", (uint32_t)__free_ram, (uint32_t)__free_ram_end);

    if (!initialized) {
        next_paddr = (paddr_t)__free_ram;  // ★ 実行時にセットする
        initialized = 1;
    }

    paddr_t paddr = next_paddr;
    next_paddr += n * PAGE_SIZE;

    if (next_paddr > (paddr_t)__free_ram_end)
        PANIC("out of memory");

    memset((void *) paddr, 0, n * PAGE_SIZE);
    return paddr;
}

__attribute__((naked)) void user_entry(void) {
    __asm__ __volatile__(
        "mv sp, %[user_sp]\n"
        "csrw sepc, %[entry]\n"
        // sstatus = SPIE, SPP=0
        "li   t0, (1 << 5)\n"   // SPIE
        "csrw sstatus, t0\n"
        "sret\n"
        :
        : [user_sp] "r" (USER_STACK_TOP),
          [entry]   "r" (USER_BASE)
        : "t0", "memory"
    );
}

__attribute__((naked))
__attribute__((aligned(4)))
void kernel_entry(void) {
    __asm__ __volatile__(
        "csrw sscratch, sp\n"
        "addi sp, sp, -4 * 31\n"
        "nop\n"
        "sw ra,  4 * 0(sp)\n"
        "sw gp,  4 * 1(sp)\n"
        "sw tp,  4 * 2(sp)\n"
        "sw t0,  4 * 3(sp)\n"
        "sw t1,  4 * 4(sp)\n"
        "sw t2,  4 * 5(sp)\n"
        "sw t3,  4 * 6(sp)\n"
        "sw t4,  4 * 7(sp)\n"
        "sw t5,  4 * 8(sp)\n"
        "sw t6,  4 * 9(sp)\n"
        "sw a0,  4 * 10(sp)\n"
        "sw a1,  4 * 11(sp)\n"
        "sw a2,  4 * 12(sp)\n"
        "sw a3,  4 * 13(sp)\n"
        "sw a4,  4 * 14(sp)\n"
        "sw a5,  4 * 15(sp)\n"
        "sw a6,  4 * 16(sp)\n"
        "sw a7,  4 * 17(sp)\n"
        "sw s0,  4 * 18(sp)\n"
        "sw s1,  4 * 19(sp)\n"
        "sw s2,  4 * 20(sp)\n"
        "sw s3,  4 * 21(sp)\n"
        "sw s4,  4 * 22(sp)\n"
        "sw s5,  4 * 23(sp)\n"
        "sw s6,  4 * 24(sp)\n"
        "sw s7,  4 * 25(sp)\n"
        "sw s8,  4 * 26(sp)\n"
        "sw s9,  4 * 27(sp)\n"
        "sw s10, 4 * 28(sp)\n"
        "sw s11, 4 * 29(sp)\n"

        "csrr a0, sscratch\n"
        "sw a0, 4 * 30(sp)\n"

        "mv a0, sp\n"
        "call handle_trap\n"

        "lw ra,  4 * 0(sp)\n"
        "lw gp,  4 * 1(sp)\n"
        "lw tp,  4 * 2(sp)\n"
        "lw t0,  4 * 3(sp)\n"
        "lw t1,  4 * 4(sp)\n"
        "lw t2,  4 * 5(sp)\n"
        "lw t3,  4 * 6(sp)\n"
        "lw t4,  4 * 7(sp)\n"
        "lw t5,  4 * 8(sp)\n"
        "lw t6,  4 * 9(sp)\n"
        "lw a0,  4 * 10(sp)\n"
        "lw a1,  4 * 11(sp)\n"
        "lw a2,  4 * 12(sp)\n"
        "lw a3,  4 * 13(sp)\n"
        "lw a4,  4 * 14(sp)\n"
        "lw a5,  4 * 15(sp)\n"
        "lw a6,  4 * 16(sp)\n"
        "lw a7,  4 * 17(sp)\n"
        "lw s0,  4 * 18(sp)\n"
        "lw s1,  4 * 19(sp)\n"
        "lw s2,  4 * 20(sp)\n"
        "lw s3,  4 * 21(sp)\n"
        "lw s4,  4 * 22(sp)\n"
        "lw s5,  4 * 23(sp)\n"
        "lw s6,  4 * 24(sp)\n"
        "lw s7,  4 * 25(sp)\n"
        "lw s8,  4 * 26(sp)\n"
        "lw s9,  4 * 27(sp)\n"
        "lw s10, 4 * 28(sp)\n"
        "lw s11, 4 * 29(sp)\n"
        "lw sp,  4 * 30(sp)\n"
        "sret\n"
    );
}

__attribute__((naked)) void switch_context(uint32_t *prev_sp,
                                           uint32_t *next_sp) {
    __asm__ __volatile__(
        // 実行中プロセスのスタックへレジスタを保存
        "addi sp, sp, -13 * 4\n"
        "sw ra,  0  * 4(sp)\n"
        "sw s0,  1  * 4(sp)\n"
        "sw s1,  2  * 4(sp)\n"
        "sw s2,  3  * 4(sp)\n"
        "sw s3,  4  * 4(sp)\n"
        "sw s4,  5  * 4(sp)\n"
        "sw s5,  6  * 4(sp)\n"
        "sw s6,  7  * 4(sp)\n"
        "sw s7,  8  * 4(sp)\n"
        "sw s8,  9  * 4(sp)\n"
        "sw s9,  10 * 4(sp)\n"
        "sw s10, 11 * 4(sp)\n"
        "sw s11, 12 * 4(sp)\n"

        // スタックポインタの切り替え
        "sw sp, (a0)\n"
        "lw sp, (a1)\n"

        // 次のプロセスのスタックからレジスタを復元
        "lw ra,  0  * 4(sp)\n"
        "lw s0,  1  * 4(sp)\n"
        "lw s1,  2  * 4(sp)\n"
        "lw s2,  3  * 4(sp)\n"
        "lw s3,  4  * 4(sp)\n"
        "lw s4,  5  * 4(sp)\n"
        "lw s5,  6  * 4(sp)\n"
        "lw s6,  7  * 4(sp)\n"
        "lw s7,  8  * 4(sp)\n"
        "lw s8,  9  * 4(sp)\n"
        "lw s9,  10 * 4(sp)\n"
        "lw s10, 11 * 4(sp)\n"
        "lw s11, 12 * 4(sp)\n"
        "addi sp, sp, 13 * 4\n"
        "ret\n"
        //"j .\n"   // ★ 無限ループで止める（Cには戻らない）
    );
}


void map_page(uint32_t *table1, uint32_t vaddr, paddr_t paddr, uint32_t flags) {
    if (!is_aligned(vaddr, PAGE_SIZE))
        PANIC("unaligned vaddr %x", vaddr);

    if (!is_aligned(paddr, PAGE_SIZE))
        PANIC("unaligned paddr %x", paddr);

    uint32_t vpn1 = (vaddr >> 22) & 0x3ff;
    if ((table1[vpn1] & PAGE_V) == 0) {
        uint32_t pt_paddr = alloc_pages(1);
        table1[vpn1] = ((pt_paddr / PAGE_SIZE) << 10) | PAGE_V;
    }

    uint32_t vpn0 = (vaddr >> 12) & 0x3ff;
    uint32_t *table0 = (uint32_t *) ((table1[vpn1] >> 10) * PAGE_SIZE);
    table0[vpn0] = ((paddr / PAGE_SIZE) << 10) | flags | PAGE_V;
}

// idle entry追加
void idle_entry(void) {
    while (1) {
        __asm__ volatile("nop");
    }
}

#define KERNEL_MAP_SIZE (1 * 1024 * 1024)   // 1MB

struct process *create_process(const void *image, size_t image_size) {
    //printf("create_process_P0\n");

    // ---- プロセススロット探索 ----
    struct process *proc = NULL;
    int i;
    for (i = 0; i < PROCS_MAX; i++) {
        if (procs[i].state == PROC_UNUSED) {
            proc = &procs[i];
            break;
        }
    }
    //printf("create_process_P1\n");
    if (!proc) PANIC("no free process slots");

    // ---- 初期スタック構築 (callee-saved + ra=user_entry) ----
    uint32_t *sp = (uint32_t *)&proc->stack[sizeof(proc->stack)];
    *--sp = 0;  // s11
    *--sp = 0;  // s10
    *--sp = 0;  // s9
    *--sp = 0;  // s8
    *--sp = 0;  // s7
    *--sp = 0;  // s6
    *--sp = 0;  // s5
    *--sp = 0;  // s4
    *--sp = 0;  // s3
    *--sp = 0;  // s2
    *--sp = 0;  // s1
    *--sp = 0;  // s0
    *--sp = (uint32_t)user_entry;  // ra

    //printf("create_process_P2\n");

    // ---- L1 page table ----
    uint32_t *page_table = (uint32_t *)alloc_pages(1);
    //printf("P3 page_table_paddr=%x\n", (unsigned)page_table);

    //printf("ADDR kernel_base=%x free_ram=%x free_ram_end=%x\n",
    //(uint32_t)__kernel_base,
    //(uint32_t)__free_ram,
    //(uint32_t)__free_ram_end);

    // ---- Kernel Identity Map (U=0) ----P3
    s_printf("---- kernel map start. ----\n");
    // カーネルのページをマッピングする
    for (paddr_t paddr = (paddr_t) __kernel_base;
         paddr < (paddr_t) __free_ram_end; paddr += PAGE_SIZE)
        map_page(page_table, paddr, paddr, PAGE_R | PAGE_W | PAGE_X);

    //printf("create_process_P4\n");

    // ---- UART MMIO mapping (identity map) ----
    // ★ MMIO は PTE を作らない。MMU では無視させる。
#ifndef USE_SBI_CONSOLE

    s_printf("---- MMIO map start. ----\n");
    //printf("DBG: UART MMIO identity map start (paddr=%x)\n",
    //    (unsigned)UART_MMIO_BASE);

    #define MMIO_BASE 0x10000000u
    #define MMIO_SIZE 0x00010000u

    s_printf("---- MMIO region map start. ----\n");

    for (uintptr_t va = MMIO_BASE;
        va < MMIO_BASE + MMIO_SIZE;
        va += PAGE_SIZE) {
        map_page(page_table, va, va, PAGE_R | PAGE_W);
    }

    // SA Address Map
    s_printf("---- SA core address map start. ----\n");

    uintptr_t sa_page = PSC_SA_CTRL & ~(PAGE_SIZE - 1);

    map_page(page_table,
             sa_page,          // vaddr = paddr（identity map）
             sa_page,
             PAGE_R | PAGE_W);

    // SA Address Map
    s_printf("---- SA core data address map start. ----\n");

    uintptr_t sa_data_page = PSC_SA_DATA_BASE & ~(PAGE_SIZE - 1);

    map_page(page_table,
             sa_data_page,          // vaddr = paddr（identity map）
             sa_data_page,
             PAGE_R | PAGE_W);

    // SA WB Address Map
    s_printf("---- SA core data wb address map start. ----\n");

    uintptr_t sa_data_wb_page = PSC_SA_DATA_WB & ~(PAGE_SIZE - 1);

    map_page(page_table,
             sa_data_wb_page,          // vaddr = paddr（identity map）
             sa_data_wb_page,
             PAGE_R | PAGE_W);

#endif
    //printf("create_process_P5\n");

    // ---- User Program Mapping (U=1) ----
    if (image && image_size > 0) {
        s_printf("---- user image map start. ----\n");

        //printf("DBG: user image map start size=%x\n", (unsigned)image_size);

        for (uint32_t off = 0; off < image_size; off += PAGE_SIZE) {

            paddr_t page = alloc_pages(1);

            size_t remaining = image_size - off;
            size_t copy_size = (remaining < PAGE_SIZE) ? remaining : PAGE_SIZE;

            memcpy((void *)page, (const uint8_t *)image + off, copy_size);
            //dma_memcpy((void *)page, (const uint8_t *)image + off, copy_size);

            // ↓ここに貼る
            /*
            for (uint32_t i = 0; i < copy_size / 4; i++) {
                uint32_t s = ((uint32_t *)((const uint8_t *)image + off))[i];
                uint32_t d = ((uint32_t *)page)[i];

                if (s != d) {
                    s_printf("DMA NG off=%x i=%x src=%x dst=%x\n",
                            off, i, s, d);
                    break;
                }
            }

            if (memcmp((void *)page, (const uint8_t *)image + off, copy_size) != 0) {
                s_printf("DMA compare NG off=%x\n", off);
            }
            */

            // 命令フェンス
            __asm__ __volatile__("fence.i" ::: "memory");

            //s_printf("DBG: map user image v=%x -> p=%x\n", (unsigned)(USER_BASE + off), (unsigned)page);
            map_page(page_table,
                    USER_BASE + off,
                    page,
                    PAGE_U | PAGE_R | PAGE_W | PAGE_X);
        }
#if 1
        s_printf("---- user stack map start. ----\n");

        /* stack bottom は guard の上 */
        uint32_t stack_bottom =
            USER_STACK_TOP - USER_STACK_SIZE;

        /* stack 領域のみ map */
        for (uint32_t va = stack_bottom;
            va < USER_STACK_TOP;
            va += PAGE_SIZE) {
            
            paddr_t page = alloc_pages(1);

            //s_printf("map: va=%x -> pa=%x flags=%x\n", va, page, PAGE_U | PAGE_R | PAGE_W);
            map_page(page_table,
                    va,
                    page,
                    PAGE_U | PAGE_R | PAGE_W);
        }
    }
#endif

    // ---- プロセス制御ブロック初期化 ----
    proc->pid        = i + 1;
    proc->state      = PROC_RUNNABLE;
    proc->sp         = (uint32_t)sp;
    proc->page_table = page_table;
    s_printf("create_process_End\n");

    return proc;
}


void yield(void) {
    //printf("yield start\n");
    // 実行可能なプロセスを探す
    struct process *next = idle_proc;
    for (int i = 0; i < PROCS_MAX; i++) {
        struct process *proc = &procs[(current_proc->pid + i) % PROCS_MAX];
        if (proc->state == PROC_RUNNABLE && proc->pid > 0) {
            next = proc;
            break;
        }
    }
    //printf("yield_P0\n");

    // 現在実行中のプロセス以外に、実行可能なプロセスがない。戻って処理を続行する
    if (next == current_proc)
        return;

    // コンテキストスイッチ
    struct process *prev = current_proc;
    current_proc = next;

    //printf("yield_P1\n");

    __asm__ __volatile__(
        "sfence.vma\n"
        "csrw satp, %[satp]\n"
        "sfence.vma\n"
        "csrw sscratch, %[sscratch]\n"
        :
        // 行末のカンマを忘れずに！
        : [satp] "r" (SATP_SV32 | ((uint32_t) next->page_table / PAGE_SIZE)),
          [sscratch] "r" ((uint32_t) &next->stack[sizeof(next->stack)])
    );
    //printf("yield_P2\n");

    //printf("CPU SP(real x2) = %x\n", read_sp());
    //printf("prev->sp(saved) = %x\n", (uint32_t)prev->sp);
    //printf("next->sp(saved) = %x\n", (uint32_t)next->sp);

    switch_context(&prev->sp, &next->sp);

    // 🚫 ここには絶対に来ない
    //__builtin_unreachable();
}

__attribute__((noreturn)) void reboot(void)
{
    __asm__ __volatile__(
        "csrw satp, zero\n"
        "sfence.vma\n"
        "fence.i\n"
    );

    void (*boot)(void) = (void (*)(void))0x00000000;
    boot();

    // 絶対ここに来たらおかしい
    while (1) {
        __asm__ __volatile__("wfi");
    }
}

// syscall処理
void handle_syscall(struct trap_frame *f) {
    switch (f->a3) {             // ★ syscall番号は a3

        // -------------------------------------------
        case SYS_PUTCHAR:
            uart_putchar(f->a0);      // ★ 引数は a0
            break;

        // -------------------------------------------
        case SYS_GETCHAR: {
            while (1) {
                long ch = uart_getchar();
                if (ch >= 0) {
                    f->a0 = ch;       // 戻り値
                    break;
                }
                yield();
            }
            break;
        }

        // -------------------------------------------
        case SYS_GETCHAR_TIMEOUT: {
            long ch = uart_getchar_timeout(1000);
            f->a0 = ch;   // 入力なしなら -1
            break;
        }

        // -------------------------------------------
        case SYS_PRINT_INT: {
            s_print_int(f->a0);   // ← kernel の print_int
            break;
        }
            
        // -------------------------------------------
        case SYS_SA_RUN: {
            const uint8_t *user_A =
                (const uint8_t *)(uintptr_t)f->a0;
            const uint8_t *user_B =
                (const uint8_t *)(uintptr_t)f->a1;
            uint32_t *user_C =
                (uint32_t *)(uintptr_t)f->a2;

            uint32_t n = f->a4;

            static uint8_t kernel_A[SA_MAT_MAX * SA_MAT_MAX];
            static uint8_t kernel_B[SA_MAT_MAX * SA_MAT_MAX];
            static uint32_t kernel_C[SA_MAT_MAX * SA_MAT_MAX];

            uint32_t elements = n * n;

            /* ユーザー領域からカーネル領域へコピー */
            for (uint32_t i = 0; i < elements; ++i) {
                kernel_A[i] = user_A[i];
                kernel_B[i] = user_B[i];
                kernel_C[i] = 0;
            }

            /* SAにはカーネル側の物理的に有効なアドレスを渡す */
            sa_run(kernel_A, kernel_B, (uint8_t)n, kernel_C);

            /* 結果をユーザー領域へ返す */
            for (uint32_t i = 0; i < elements; ++i) {
                user_C[i] = kernel_C[i];
            }

            f->a0 = 0;
            break;
        }
        
        // -------------------------------------------
        case I2S_MIC_READ: {
            f->a0 = s_call_mic_read_samples24(f->a0);
            break;
        }
        
        // -------------------------------------------
        /*
        case I2S_MIC_WRITE: {
            f->a0 = s_call_mic_write_samples24(f->a0);
            break;
        }
        */
        case I2S_MIC_WRITE: {

            f->a0 =
                s_call_mic_write_samples24(
                    f->a0,   // count
                    f->a1    // MIC.TXT start LBA
                );

            break;
        }        
        // -------------------------------------------
        case SYS_SD_READ: {
            s_call_sdcard_read_api(f->a0);
            break;
        }
        
        // -------------------------------------------
        case SYS_SD_WRITE_TEST: {
            uint8_t test_buf[512];

            for (int i = 0; i < 512; i++) {
                test_buf[i] = (uint8_t)i;
            }

            f->a0 = s_call_sdcard_write_api(
                f->a0,
                test_buf
            );

            break;
        }
        
        // -------------------------------------------
        case SYS_SD_WRITE: {
            f->a0 = s_call_sdcard_write_api(
                f->a0,
                (const uint8_t *)f->a1
            );

            break;
        }
        
        // -------------------------------------------
        case SYS_SD_READ_BUF: {
            static uint8_t kbuf[512];

            int ret = sd_read_sector(f->a0, kbuf);

            if (ret == 0) {
                memcpy((void *)f->a1, kbuf, 512);
            }

            f->a0 = ret;
            break;
        }
        
        // -------------------------------------------
        case SYS_DUMP: {
            uintptr_t addr = (uintptr_t)f->a0;
            size_t    len  = (size_t)f->a1;

            if (len == 0) {
                len = 0x100;
            } else if (len > 0x1000) {
                len = 0x1000;
            }

            hexdump((const void *)addr, len, addr);
            break;
        }
        
        // -------------------------------------------
        case SYS_SW_READ: {
            //s_printf("SYS_SW_READ\n");
            volatile uint32_t tmp = PIO32_ADDR;
            f->a0 = tmp & 0x03;
            break;
        }

        // -------------------------------------------
        case SYS_SPEECH_RECOGNITION: {
            int32_t result =
                s_call_speech_recognition_api();

            f->a0 = (uint32_t)result;
            break;
        }
                
        // -------------------------------------------
        case SYS_EXIT: {
            /*
            s_printf("process %d exited\n", current_proc->pid);
            current_proc->state = PROC_EXITED;
            yield();
            PANIC("unreachable");
            */
            // PCS版
            s_printf("process %d exited\n", current_proc->pid);
            reboot();
            __builtin_unreachable();

            while (1) { }
        }

        // -------------------------------------------
        default: {
            PANIC("unexpected syscall a3=%x\n", f->a3);
        }
    }
}

void handle_trap(struct trap_frame *f)
{
    uint32_t scause = READ_CSR(scause);
    uint32_t stval  = READ_CSR(stval);
    uint32_t sepc   = READ_CSR(sepc);
    uint32_t sstatus = READ_CSR(sstatus);

    if (scause == SCAUSE_ECALL) {
        handle_syscall(f);
        sepc += 4;   // ecall の次へ
        WRITE_CSR(sepc, sepc);
        return;
    }

    /* それ以外は「想定された trap」かどうかを確認 */
    if (scause == SCAUSE_INST_MISALIGNED) {
        //PANIC("PC misaligned sepc=%x\n", sepc);
        //PANIC("PC misaligned sepc=%x stval=%x\n", sepc, stval);
        PANIC("PC misaligned sepc=%x stval=%x sstatus=%x\n",
              sepc, stval, sstatus);
    }

    PANIC("unexpected trap scause=%x stval=%x sepc=%x\n",
          scause, stval, sepc);
}


__attribute__((section(".text.boot")))
__attribute__((naked))
void boot(void) {
    __asm__ __volatile__(
        "mv sp, %[stack_top]\n"
        "j kernel_main\n"
        :
        : [stack_top] "r" (__kernel_stack_top)
    );
}

// -------------------------------------------
// kernel main
// -------------------------------------------

extern char __kernel_base[];

void kernel_main(void) {

#if 0
    // SA run.
    s_printf("SA run\n");
    s_call_sa_api(4, true);
    s_call_sa_api(8, true);
    //s_call_sa_api(16, true);
    s_printf("\n");
#endif

#if 0
    // dump
    const char *argv[] = {
        "0x200000",
        "100",
    };

    cmd_dump(2, argv);
#endif

#if BSS_CLEAR_OFF
    s_printf("memset = OFF\n");
#else
    s_printf("memset = ON\n");
    memset(__bss, 0, (size_t) __bss_end - (size_t) __bss);
#endif
    s_printf("PSC_OS Boot Start.........\n");
    s_printf("--- memset done ---\n");

    // compline number.
    s_printf("Test Ver: test_1.4.8\n");

#if 1
    s_printf("Draw PSC Logo\n");
    lcd_draw_boot_logo();
#endif

    s_printf(
        "\n"
        "+--------------------------------------------------+\n"
        "|                    PSC_OS                        |\n"
        "|            Minimal RISC-V Kernel Boot            |\n"
        "+--------------------------------------------------+\n"
        "| Build : %s %s\n"
        "| CPU   : RV32 (Supervisor mode)\n"
        "| MMU   : SV32\n"
        "| UART  : SBI console or\n"
        "| UART  : MMIO console\n"
        "| CMD   : hello, primes, dump\n"
        "| CMD   : sa_start\n"
        "| CMD   : sd_read, sd_write\n"
        "| CMD   : mic_read, mic_write\n"
        "| CMD   : fat32_info, fat32_ls, fat32_cat\n"
        "| CMD   : fat32_touch\n"
        "| CMD   : speech\n"
        "| quit  : Ctl+A C. q.\n"
        "+--------------------------------------------------+\n",
        __DATE__, __TIME__
    );
    /*
    printf("ADDR kernel_base=%x free_ram=%x free_ram_end=%x\n",
       (uint32_t)__kernel_base,
       (uint32_t)__free_ram,
       (uint32_t)__free_ram_end);
    */

    // -------------------------------------------
    WRITE_CSR(stvec, (uint32_t) kernel_entry);

    //printf("================================================\n");
    s_printf("--- create_process_1 ---\n");
    idle_proc = create_process(NULL, 0);
    idle_proc->pid = 0; // idle
    current_proc = idle_proc;

    //printf("DBG: _binary_shell_bin_start=%x _binary_shell_bin_end=%x\n",
    //   (uint32_t)_binary_shell_bin_start,
    //   (uint32_t)_binary_shell_bin_end);

    size_t shell_size = _binary_shell_bin_end - _binary_shell_bin_start;
    //printf("================================================\n");
    s_printf("--- create_process_2 ---\n");
    create_process(_binary_shell_bin_start, shell_size);

    // 命令フェンス
    __asm__ __volatile__("fence.i" ::: "memory");

    //printf("================================================\n");
    s_printf("--- yield ---\n");
    yield();

    //uint32_t satp_now = READ_CSR(satp);
    //printf("satp after yield = %x\n", satp_now);

    s_printf("--- yield end ---\n");
    PANIC("switched to idle process");
}
