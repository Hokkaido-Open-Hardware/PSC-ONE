#include "common.h"
#include "kernel.h"
#include "synap_api.h"
#include "sdcard_api.h"
#include "timer_api.h"
#include "mic_api.h"
#include "lcd_api.h"
#include "led_api.h"
#include "fft_api.h"
#include "mem_test.h"
#include "speech_recognition_api.h"

extern uint8_t _binary_shell_bin_start[];
extern uint8_t _binary_shell_bin_end[];
extern char __bss[], __bss_end[], __kernel_stack_top[];
extern char __free_ram[], __free_ram_end[];

struct virtio_virtq *blk_request_vq;
struct virtio_blk_req *blk_req;
paddr_t blk_req_paddr;
uint64_t blk_capacity;

#ifdef USE_SBI_CONSOLE
struct sbiret sbi_call(long arg0, long arg1, long arg2, long arg3,
                       long arg4, long arg5, long fid, long eid) {
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
                         : "r"(a0), "r"(a1), "r"(a2), "r"(a3), "r"(a4),
                           "r"(a5), "r"(a6), "r"(a7)
                         : "memory");
    return (struct sbiret){.error = a0, .value = a1};
}

void uart_putchar(char ch) {
    sbi_call(ch, 0, 0, 0, 0, 0, 0, 1);
}

long uart_getchar(void) {
    struct sbiret ret = sbi_call(0, 0, 0, 0, 0, 0, 0, 2);
    return ret.error;
}

#else

#ifndef PIO32_ADDR
#define PIO32_ADDR (*(volatile uint32_t *)0x10001000)
#endif
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

void putchar(char ch) {
    while (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_TX_BUSY)
        __asm__ __volatile__("nop");
    mmio_w32(UART_MMIO_BASE + UART_TX, (uint32_t)(uint8_t)ch);
}

void uart_putchar(char ch) {
    while (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_TX_BUSY)
        __asm__ __volatile__("nop");
    mmio_w32(UART_MMIO_BASE + UART_TX, (uint32_t)(uint8_t)ch);
}

long uart_getchar_timeout(uint32_t timeout) {
    while (timeout--) {
        if (mmio_r32(UART_MMIO_BASE + UART_ST) & ST_RX_AVAIL)
            return (long)(mmio_r32(UART_MMIO_BASE + UART_RX) & 0xFF);
        __asm__ __volatile__("nop");
    }
    return -1;
}

long uart_getchar(void) {
    while ((mmio_r32(UART_MMIO_BASE + UART_ST) & ST_RX_AVAIL) == 0)
        __asm__ __volatile__("nop");
    return (long)(mmio_r32(UART_MMIO_BASE + UART_RX) & 0xFF);
}

#endif

paddr_t alloc_pages(uint32_t n) {
    static int initialized;
    static paddr_t next_paddr;
    if (!initialized) {
        next_paddr = (paddr_t)__free_ram;
        initialized = 1;
    }
    paddr_t paddr = next_paddr;
    next_paddr += n * PAGE_SIZE;
    if (next_paddr > (paddr_t)__free_ram_end)
        PANIC("out of memory");
    memset((void *)paddr, 0, n * PAGE_SIZE);
    return paddr;
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
    uint32_t *table0 = (uint32_t *)((table1[vpn1] >> 10) * PAGE_SIZE);
    table0[vpn0] = ((paddr / PAGE_SIZE) << 10) | flags | PAGE_V;
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

__attribute__((used)) void kernel_main(void) {
#if BSS_CLEAR_OFF
    s_printf("memset = OFF\n");
#else
    s_printf("memset = ON\n");
    memset(__bss, 0, (size_t)__bss_end - (size_t)__bss);
#endif
    s_printf("PSC_OS Boot Start.........\n");
    s_printf("--- memset done ---\n");
    s_printf("Test Ver: test_1.7.0\n");
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
        "| CMD   : microPython\n"
        "| microPython exit: Ctl+D.\n"
        "| SBI quit : Ctl+A C. q.\n"
        "+--------------------------------------------------+\n",
        __DATE__, __TIME__);

    WRITE_CSR(stvec, (uint32_t)kernel_entry);

#ifdef PSC_OS_DUMMY_TEST
    run_multitask_dummy_test();
    PANIC("dummy scheduler test returned");
#endif

    s_printf("--- create_process_1 ---\n");
    idle_proc = create_process(NULL, 0);
    idle_proc->pid = 0;
    current_proc = idle_proc;

    /* 
    task1: 本物shell 
    */
    s_printf("--- create_process_2 ---\n");
    s_printf("DBG: _binary_shell_bin_start=%x _binary_shell_bin_end=%x\n",
             (uint32_t)_binary_shell_bin_start,
             (uint32_t)_binary_shell_bin_end);
    size_t shell_size = _binary_shell_bin_end - _binary_shell_bin_start;
    create_process(_binary_shell_bin_start, shell_size);
    __asm__ __volatile__("fence.i" ::: "memory");

#if 1
    /* 
    task2: kernel内テストtask 
    */
    s_printf("--- create_process_3 ---\n");
    create_kernel_task(shell_idle_task);

    //ここのコメントアウトを外すとブートしない
    preemption_start();
    
    /*
     * yield()しない。
     * Timer IRQだけで idle -> shell -> shell_idle_task
     * と切り替わることを確認する。
     */
    for (;;) {
        __asm__ __volatile__("nop");
    }
#else
    s_printf("--- yield ---\n");
    yield();
    s_printf("--- yield end ---\n");
    PANIC("switched to idle process");
#endif
}
