#include "common.h"
#include "kernel.h"
#include "synap_api.h"

struct process procs[PROCS_MAX];
struct process *current_proc;
struct process *idle_proc;

// idle entry
static void __attribute__((unused)) idle_entry(void) {
    while (1) {
        __asm__ volatile("nop");
    }
}

#define KERNEL_MAP_SIZE (1 * 1024 * 1024)   // 1MB

struct process *create_process(const void *image, size_t image_size) {
    // ---- プロセススロット探索 ----
    struct process *proc = NULL;
    int i;
    for (i = 0; i < PROCS_MAX; i++) {
        if (procs[i].state == PROC_UNUSED) {
            proc = &procs[i];
            break;
        }
    }
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

    // ---- L1 page table ----
    uint32_t *page_table = (uint32_t *)alloc_pages(1);

    // ---- Kernel Identity Map (U=0) ----
    s_printf("---- kernel map start. ----\n");
    extern char __kernel_base[], __free_ram_end[];
    for (paddr_t paddr = (paddr_t)__kernel_base;
         paddr < (paddr_t)__free_ram_end; paddr += PAGE_SIZE)
        map_page(page_table, paddr, paddr, PAGE_R | PAGE_W | PAGE_X);

    // ---- UART MMIO mapping (identity map) ----
#ifndef USE_SBI_CONSOLE
    #define MMIO_BASE 0x10000000u
    #define MMIO_SIZE 0x00010000u
    s_printf("---- MMIO map start. ----\n");
    s_printf("---- MMIO region map start. ----\n");
    for (uintptr_t va = MMIO_BASE; va < MMIO_BASE + MMIO_SIZE; va += PAGE_SIZE)
        map_page(page_table, va, va, PAGE_R | PAGE_W);

    s_printf("---- SA core address map start. ----\n");
    uintptr_t sa_page = PSC_SA_CTRL & ~(PAGE_SIZE - 1);
    map_page(page_table, sa_page, sa_page, PAGE_R | PAGE_W);

    s_printf("---- SA core data address map start. ----\n");
    uintptr_t sa_data_page = PSC_SA_DATA_BASE & ~(PAGE_SIZE - 1);
    map_page(page_table, sa_data_page, sa_data_page, PAGE_R | PAGE_W);

    s_printf("---- SA core data wb address map start. ----\n");
    uintptr_t sa_data_wb_page = PSC_SA_DATA_WB & ~(PAGE_SIZE - 1);
    map_page(page_table, sa_data_wb_page, sa_data_wb_page, PAGE_R | PAGE_W);
#endif

    // ---- User Program Mapping (U=1) ----
    if (image && image_size > 0) {
        s_printf("---- user image map start. ----\n");
        for (uint32_t off = 0; off < image_size; off += PAGE_SIZE) {
            paddr_t page = alloc_pages(1);
            size_t remaining = image_size - off;
            size_t copy_size = (remaining < PAGE_SIZE) ? remaining : PAGE_SIZE;
            memcpy((void *)page, (const uint8_t *)image + off, copy_size);
            __asm__ __volatile__("fence.i" ::: "memory");
            map_page(page_table, USER_BASE + off, page,
                     PAGE_U | PAGE_R | PAGE_W | PAGE_X);
        }

        s_printf("---- user stack map start. ----\n");
        uint32_t stack_bottom = USER_STACK_TOP - USER_STACK_SIZE;
        for (uint32_t va = stack_bottom; va < USER_STACK_TOP; va += PAGE_SIZE) {
            paddr_t page = alloc_pages(1);
            map_page(page_table, va, page, PAGE_U | PAGE_R | PAGE_W);
        }
    }

    proc->pid        = i + 1;
    proc->state      = PROC_RUNNABLE;
    proc->sp         = (uint32_t)sp;
    proc->page_table = page_table;
    s_printf("create_process_End\n");
    return proc;
}

void yield(void) {
    struct process *next = idle_proc;
    for (int i = 0; i < PROCS_MAX; i++) {
        struct process *proc = &procs[(current_proc->pid + i) % PROCS_MAX];
        if (proc->state == PROC_RUNNABLE && proc->pid > 0) {
            next = proc;
            break;
        }
    }
    if (next == current_proc)
        return;

    struct process *prev = current_proc;
    current_proc = next;
    __asm__ __volatile__(
        "sfence.vma\n"
        "csrw satp, %[satp]\n"
        "sfence.vma\n"
        "csrw sscratch, %[sscratch]\n"
        :
        : [satp] "r" (SATP_SV32 | ((uint32_t) next->page_table / PAGE_SIZE)),
          [sscratch] "r" ((uint32_t) &next->stack[sizeof(next->stack)])
    );
    switch_context(&prev->sp, &next->sp);
}

__attribute__((naked)) void switch_context(uint32_t *prev_sp,
                                           uint32_t *next_sp) {
    __asm__ __volatile__(
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
        "sw sp, (a0)\n"
        "lw sp, (a1)\n"
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
    );
}

__attribute__((noreturn)) void reboot(void)
{
    __asm__ __volatile__("csrw satp, zero\n" "sfence.vma\n" "fence.i\n");
    void (*boot)(void) = (void (*)(void))0x00000000;
    boot();
    while (1) {
        __asm__ __volatile__("wfi");
    }
}
