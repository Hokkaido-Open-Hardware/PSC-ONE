#include "elf_loader.h"

static uint32_t le16(const uint8_t *p) { return p[0] | ((uint32_t)p[1] << 8); }
static uint32_t le32(const uint8_t *p) { return le16(p) | (le16(p + 2) << 16); }

int psc_elf_validate(const void *image, uint32_t size, psc_elf_image_t *out)
{
    const uint8_t *b = image;
    out->count = out->pages = out->entry = 0;
    if (!b || size < 52 || b[0] != 0x7f || b[1] != 'E' ||
        b[2] != 'L' || b[3] != 'F') return PSC_ELF_HEADER;
    if (size > PSC_ELF_FILE_MAX) return PSC_ELF_LIMIT;
    /* RV32IM/ILP32 only: no RVC, float ABI, RVE or vendor e_flags. */
    if (b[4] != 1 || b[5] != 1 || b[6] != 1 || le16(b + 16) != 2 ||
        le16(b + 18) != 243 || le32(b + 20) != 1 ||
        le32(b + 36) != 0 || le16(b + 40) != 52) return PSC_ELF_FORMAT;
    uint32_t phoff = le32(b + 28), phnum = le16(b + 44);
    if (le16(b + 42) != 32 || !phnum || phnum > PSC_ELF_PH_MAX ||
        phoff < 52 || phoff > size || phnum > (size - phoff) / 32)
        return PSC_ELF_PHDR;
    uint32_t entry = le32(b + 24), executable_entry = 0;
    for (uint32_t i = 0; i < phnum; i++) {
        const uint8_t *p = b + phoff + i * 32;
        uint32_t type = le32(p);
        /* PT_DYNAMIC / PT_INTERP / PT_TLS need runtimes we do not provide. */
        if (type == 2 || type == 3 || type == 7) return PSC_ELF_FORMAT;
        if (type != 1) continue;
        psc_elf_segment_t s = {le32(p + 4), le32(p + 8), le32(p + 16),
                               le32(p + 20), le32(p + 24)};
        uint32_t alignment = le32(p + 28);
        if (s.filesz > s.memsz || s.offset > size || s.filesz > size - s.offset)
            return PSC_ELF_SEGMENT;
        /* Linkers may emit an empty PT_LOAD with no meaningful VA/alignment. */
        if (!s.memsz) continue;
        if ((s.flags & ~7u) || !(s.flags & 5u) ||
            ((s.flags & 2u) && !(s.flags & 4u)) ||
            (alignment > 1 && ((alignment & (alignment - 1)) ||
              ((s.vaddr - s.offset) & (alignment - 1)))))
            return PSC_ELF_SEGMENT;
        if (s.vaddr < USER_BASE || s.vaddr >= PSC_ELF_LOAD_END ||
            s.memsz > PSC_ELF_LOAD_END - s.vaddr) return PSC_ELF_RANGE;
        uint32_t first = s.vaddr / PSC_ELF_PAGE_SIZE;
        uint32_t last = (s.vaddr + s.memsz - 1) / PSC_ELF_PAGE_SIZE;
        for (uint32_t j = 0; j < out->count; j++) {
            const psc_elf_segment_t *t = &out->segments[j];
            if (first <= (t->vaddr + t->memsz - 1) / PSC_ELF_PAGE_SIZE &&
                t->vaddr / PSC_ELF_PAGE_SIZE <= last) return PSC_ELF_OVERLAP;
        }
        if (last - first + 1 > PSC_ELF_LOAD_PAGES - out->pages) return PSC_ELF_LIMIT;
        out->pages += last - first + 1;
        out->segments[out->count++] = s;
        /* Entry must start a complete, aligned instruction in file-backed X data. */
        if ((s.flags & 1u) && entry >= s.vaddr && s.filesz >= 4 &&
            entry - s.vaddr <= s.filesz - 4) executable_entry = 1;
    }
    if (!executable_entry || (entry & 3)) return PSC_ELF_ENTRY;
    out->entry = entry;
    return PSC_ELF_OK;
}

const char *psc_elf_error(int result)
{
    switch (result) {
    case PSC_ELF_HEADER: return "bad ELF magic or truncated header";
    case PSC_ELF_FORMAT: return "unsupported ELF format/architecture";
    case PSC_ELF_PHDR: return "invalid/truncated program header table";
    case PSC_ELF_SEGMENT: return "invalid PT_LOAD file range/size/flags/alignment";
    case PSC_ELF_RANGE: return "PT_LOAD outside user region";
    case PSC_ELF_OVERLAP: return "PT_LOAD pages overlap";
    case PSC_ELF_LIMIT: return "ELF file/page limit exceeded";
    case PSC_ELF_ENTRY: return "entry is not aligned executable file data";
    case PSC_ELF_BUSY: return "an ELF is already running";
    case PSC_ELF_POINTER: return "invalid user buffer";
    case PSC_ELF_FAULT: return "user application fault";
    default: return "ELF load failed";
    }
}
