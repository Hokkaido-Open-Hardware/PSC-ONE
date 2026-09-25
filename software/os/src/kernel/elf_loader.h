#pragma once
#include <stdint.h>
#include "user_memory.h"

/* Deliberately bounded, single foreground application. No heap allocation. */
#define PSC_ELF_FILE_MAX     (32u * 1024u)
#define PSC_ELF_PH_MAX       8u
#define PSC_ELF_PAGE_SIZE    4096u
#define PSC_ELF_LOAD_PAGES   16u
#define PSC_ELF_STACK_PAGES  4u
#define PSC_ELF_STACK_BOTTOM (USER_STACK_TOP - PSC_ELF_STACK_PAGES * PSC_ELF_PAGE_SIZE)
#define PSC_ELF_LOAD_END     (PSC_ELF_STACK_BOTTOM - PSC_ELF_PAGE_SIZE)

enum {
    PSC_ELF_OK = 0, PSC_ELF_HEADER = -1, PSC_ELF_FORMAT = -2,
    PSC_ELF_PHDR = -3, PSC_ELF_SEGMENT = -4, PSC_ELF_RANGE = -5,
    PSC_ELF_OVERLAP = -6, PSC_ELF_LIMIT = -7, PSC_ELF_ENTRY = -8,
    PSC_ELF_BUSY = -9, PSC_ELF_POINTER = -10, PSC_ELF_FAULT = -11
};

typedef struct {
    uint32_t offset, vaddr, filesz, memsz, flags;
} psc_elf_segment_t;
typedef struct {
    uint32_t entry, count, pages;
    psc_elf_segment_t segments[PSC_ELF_PH_MAX];
} psc_elf_image_t;

/* Byte-wise parsing: no ELF structure alignment or section-header dependency. */
int psc_elf_validate(const void *image, uint32_t size, psc_elf_image_t *out);
const char *psc_elf_error(int result);

/* Shell-side FAT32 reader and synchronous SYS_ELF_RUN wrapper. */
void cmd_run_elf(const char *name);
