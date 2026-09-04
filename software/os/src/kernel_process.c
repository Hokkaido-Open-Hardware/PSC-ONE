#include "common.h"
#include "kernel.h"
#include "synap_api.h"
#include "timer_api.h"

struct process procs[PROCS_MAX];
struct process *current_proc;
struct process *idle_proc;
volatile uint32_t preemption_ticks;
static volatile uint32_t preemption_active;

static uint32_t current_gp(void)
{
    uint32_t gp;
    __asm__ __volatile__("mv %0, gp" : "=r"(gp));
    return gp;
}

void init_process_machine_context(struct process *proc, void (*entry)(void))
{
    memset(&proc->machine_context, 0, sizeof(proc->machine_context));
    proc->machine_context.x[2] =
        (uint32_t)&proc->stack[sizeof(proc->stack)];
    proc->machine_context.x[3] = current_gp();
    proc->machine_context.mepc = (uint32_t)entry;
    /* mret restores S privilege and enables M interrupts from MPIE. */
    proc->machine_context.mstatus = MSTATUS_MPP_S | MSTATUS_MPIE;
    proc->machine_context_valid = 1u;
}

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
    init_process_machine_context(proc, user_entry);
    s_printf("create_process_End\n");
    return proc;
}

void yield(void) {
    if (preemption_active != 0u) {
        register uint32_t extension __asm__("a7") = 6u;
        __asm__ __volatile__("ecall" : "+r"(extension) :: "memory");
        return;
    }

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

void schedule_from_machine_trap(struct machine_context *context)
{
    struct process *next = idle_proc;
    int current_slot = 0;
    int prev_pid = -1;

    preemption_ticks++;
    if (current_proc != NULL) {

        prev_pid = current_proc->pid;

        current_proc->machine_context = *context;
        current_proc->machine_context_valid = 1u;
        current_slot = (int)(current_proc - procs);
    }

    for (int i = 1; i <= PROCS_MAX; ++i) {
        struct process *candidate = &procs[(current_slot + i) % PROCS_MAX];
        if (candidate->state == PROC_RUNNABLE && candidate->pid > 0) {
            next = candidate;
            break;
        }
    }

    if (next == NULL || next == current_proc)
        return;
    if (next->machine_context_valid == 0u) {
        for (;;) {
            __asm__ __volatile__("nop");
        }
    }

    current_proc = next;
    //s_printf("[SW] %d -> %d\n", prev_pid, next->pid);

    *context = next->machine_context;
    
    __asm__ __volatile__(
        "sfence.vma\n"
        "csrw satp, %[satp]\n"
        "sfence.vma\n"
        "csrw sscratch, %[sscratch]\n"
        :
        : [satp] "r" (SATP_SV32 |
                       ((uint32_t)next->page_table / PAGE_SIZE)),
          [sscratch] "r" ((uint32_t)&next->stack[sizeof(next->stack)])
        : "memory"
    );
}

void preemption_start(void)
{
    register uint32_t handler __asm__("a0") =
        (uint32_t)machine_trap_entry;
    register uint32_t machine_sp __asm__("a1") =
        (uint32_t)&machine_interrupt_stack[sizeof(machine_interrupt_stack)];
    register uint32_t extension __asm__("a7") = 3u;

    /* MBIOS installs mtvec and enables mie.MTIE plus mstatus.MIE. */
    __asm__ __volatile__("ecall"
                         : "+r"(handler), "+r"(machine_sp), "+r"(extension)
                         :
                         : "memory");
    preemption_ticks = 0u;
    preemption_active = 1u;
    timer_start_scheduler_tick();
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

struct process *create_kernel_task(void (*entry)(void))
{
    struct process *proc = NULL;
    int i;

    for (i = 0; i < PROCS_MAX; i++) {
        if (procs[i].state == PROC_UNUSED) {
            proc = &procs[i];
            break;
        }
    }

    if (!proc)
        PANIC("no free process slots");

    memset(proc, 0, sizeof(*proc));

    uint32_t *sp =
        (uint32_t *)&proc->stack[sizeof(proc->stack)];

    *--sp = 0; // s11
    *--sp = 0; // s10
    *--sp = 0; // s9
    *--sp = 0; // s8
    *--sp = 0; // s7
    *--sp = 0; // s6
    *--sp = 0; // s5
    *--sp = 0; // s4
    *--sp = 0; // s3
    *--sp = 0; // s2
    *--sp = 0; // s1
    *--sp = 0; // s0
    *--sp = (uint32_t)entry;

    proc->pid   = i + 1;
    proc->state = PROC_RUNNABLE;
    proc->sp    = (uint32_t)sp;

    /*
     * kernel taskなのでidleと同じpage tableを使う
     */
    proc->page_table = idle_proc->page_table;

    init_process_machine_context(
        proc,
        entry
    );

    return proc;
}

// 2つ目のtask
void shell_idle_task(void)
{
    for (;;) {
        //ここに2つ目のtaskを記述する
        //TBD

        for (volatile uint32_t i = 0; i < 1000000; i++) {
            __asm__ __volatile__("nop");
        }
        //s_printf("T\n");
    }
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
