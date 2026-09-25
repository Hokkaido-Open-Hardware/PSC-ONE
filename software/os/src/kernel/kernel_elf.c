#include "kernel.h"
#include "elf_loader.h"

/* Fixed linker-owned pages, excluded from the bump allocator. Reused only
   after the foreground application exits; no general page-free API is needed. */
static uint32_t elf_root[1024] __attribute__((aligned(PAGE_SIZE)));
static uint32_t elf_leaf[1024] __attribute__((aligned(PAGE_SIZE)));
static uint8_t elf_pages[PSC_ELF_LOAD_PAGES + PSC_ELF_STACK_PAGES][PAGE_SIZE]
    __attribute__((aligned(PAGE_SIZE)));
static struct process *owner;
static uint32_t *shell_table;
static struct trap_frame shell_frame;

_Static_assert(PAGE_SIZE == PSC_ELF_PAGE_SIZE, "ELF page size mismatch");
_Static_assert((USER_BASE >> 22) == ((USER_STACK_TOP - 1) >> 22),
               "ELF user window must fit one Sv32 leaf table");

int elf_is_running(void) { return owner && current_proc == owner; }

static void activate(uint32_t *table)
{
    current_proc->page_table = table;
    __asm__ volatile("fence rw, rw\n"
                     "sfence.vma\n"
                     "csrw satp, %0\n"
                     "sfence.vma\n"
                     "fence.i\n"
                     :: "r"(SATP_SV32 | ((uint32_t)table / PAGE_SIZE)) : "memory");
}

void elf_run(struct trap_frame *f)
{
    psc_elf_image_t plan;
    if (owner) { f->a0 = PSC_ELF_BUSY; return; }
    if (f->a1 > PSC_ELF_FILE_MAX) { f->a0 = PSC_ELF_LIMIT; return; }
    if (!user_accessible(f->a0, f->a1, PAGE_R)) { f->a0 = PSC_ELF_POINTER; return; }
    uint32_t image = f->a0;
    int rc = psc_elf_validate((const void *)image, f->a1, &plan);
    if (rc) { f->a0 = rc; return; }

    /* The ELF root replaces only the existing user-window slot. */
    if (idle_proc->page_table[USER_BASE >> 22] & PAGE_V) {
        f->a0 = PSC_ELF_RANGE;
        return;
    }
    memcpy(elf_root, idle_proc->page_table, sizeof(elf_root));
    memset(elf_leaf, 0, sizeof(elf_leaf));
    elf_root[USER_BASE >> 22] = (((uint32_t)elf_leaf / PAGE_SIZE) << 10) | PAGE_V;
    uint32_t page_index = 0;
    for (uint32_t i = 0; i < plan.count; i++) {
        const psc_elf_segment_t *s = &plan.segments[i];
        uint32_t first = s->vaddr & ~(PAGE_SIZE - 1);
        uint32_t end = (s->vaddr + s->memsz + PAGE_SIZE - 1) & ~(PAGE_SIZE - 1);
        uint32_t flags = PAGE_U | (1u << 6) | (1u << 7);
        if (s->flags & 4) flags |= PAGE_R;
        if (s->flags & 2) flags |= PAGE_W;
        if (s->flags & 1) flags |= PAGE_X;
        uint8_t *destination = elf_pages[page_index] + (s->vaddr - first);
        for (uint32_t va = first; va < end; va += PAGE_SIZE) {
            uint8_t *page = elf_pages[page_index++];
            memset(page, 0, PAGE_SIZE);
            map_page(elf_root, va, (uint32_t)page, flags);
        }
        memcpy(destination, (const uint8_t *)image + s->offset, s->filesz);
    }
    for (uint32_t i = 0; i < PSC_ELF_STACK_PAGES; i++) {
        uint8_t *page = elf_pages[PSC_ELF_LOAD_PAGES + i];
        memset(page, 0, PAGE_SIZE);
        map_page(elf_root, PSC_ELF_STACK_BOTTOM + i * PAGE_SIZE, (uint32_t)page,
                 PAGE_U | PAGE_R | PAGE_W | (1u << 6) | (1u << 7));
    }

    shell_frame = *f; /* shell ECALL return PC was already advanced */
    shell_table = current_proc->page_table;
    owner = current_proc;
    sync_user_code();
    activate(elf_root);
    memset(f, 0, sizeof(*f));
    f->sp = USER_STACK_TOP;
    f->sepc = plan.entry;
    f->sstatus = SSTATUS_SPIE; /* SPP=0, SUM=0; trap return enters U */
    s_printf("ELF: entry=%x sp=%x pages=%d\n", plan.entry, f->sp, plan.pages);
}

void elf_finish(struct trap_frame *f, int result, int exit_code)
{
    activate(shell_table);
    *f = shell_frame;
    f->a0 = (uint32_t)result;
    f->a1 = (uint32_t)exit_code;
    owner = NULL;
}
