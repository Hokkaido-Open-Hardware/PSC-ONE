#include "../api/user.h"
#include "../fs/fat32.h"
#include "../kernel/syscall.h"
#include "../kernel/elf_loader.h"

void cmd_run_elf(const char *name)
{
    /* The existing shell stack is 128 KiB. Avoid enlarging shell.bin's BSS. */
    uint8_t image[PSC_ELF_FILE_MAX];
    fat32_file_t file;
    uint32_t actual;
    int rc = fat32_open(&file, name);
    if (rc) {
        printf("run: FAT32 open failed (%d)\n", rc);
        return;
    }
    if (file.file_size > sizeof(image)) {
        printf("run: %s\n", psc_elf_error(PSC_ELF_LIMIT));
        fat32_close(&file);
        return;
    }
    rc = fat32_stream_read(&file, image, file.file_size, &actual);
    fat32_close(&file);
    if (rc || actual != file.file_size) {
        printf("run: FAT32 read failed (%d)\n", rc);
        return;
    }
    register uint32_t a0 __asm__("a0") = (uint32_t)image;
    register uint32_t a1 __asm__("a1") = actual;
    register uint32_t a3 __asm__("a3") = SYS_ELF_RUN;
    __asm__ volatile("ecall" : "+r"(a0), "+r"(a1) : "r"(a3) : "memory");
    if ((int)a0) printf("run: %s\n", psc_elf_error((int)a0));
    else printf("run: exit %d\n", (int)a1);
}
