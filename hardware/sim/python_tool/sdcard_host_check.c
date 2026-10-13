/* Read a generated image through the production PSC-OS FAT32 implementations. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#define printf psc_printf
#define putchar psc_putchar
#define exit psc_exit
#include "fs/fat32.h"
#include "boot/boot_fat32.h"
#undef printf
#undef putchar
#undef exit

#define CHECK(c) do { if (!(c)) { \
    fprintf(stderr, "FAIL line %d: %s\n", __LINE__, #c); return 1; \
} } while (0)

static FILE *image;

int call_sd_read_buf_api(uint32_t lba, void *buf)
{
    if (fseek(image, (long)lba * 512, SEEK_SET)) return -1;
    return fread(buf, 1, 512, image) == 512 ? 0 : -1;
}

static int boot_read(uint32_t lba, uint8_t *buf)
{
    return call_sd_read_buf_api(lba, buf);
}

void s_printf(const char *format, ...) { (void)format; }
void s_print_int(int value) { (void)value; }

int main(int argc, char **argv)
{
    CHECK(argc == 4);
    image = fopen(argv[1], "rb");
    CHECK(image);
    CHECK(boot_fat32_mount(boot_read) == 0);
    const char *names[] = {"KERNEL.MEM", "USER.MEM"};
    for (unsigned i = 0; i < 2; ++i) {
        FILE *source = fopen(argv[i + 2], "rb");
        CHECK(source);
        fat32_file_t file;
        CHECK(fat32_open(&file, names[i]) == 0);
        uint32_t cluster, size;
        CHECK(boot_fat32_find(names[i], &cluster, &size) == 0);
        CHECK(cluster == file.first_cluster && size == file.file_size);
        uint8_t actual[777], expected[777]; /* cross sector/cluster boundaries */
        uint32_t total = 0;
        for (;;) {
            uint32_t count;
            CHECK(fat32_stream_read(&file, actual, sizeof(actual), &count) == 0);
            size_t expected_count = fread(expected, 1, sizeof(expected), source);
            CHECK(!ferror(source) && count == expected_count);
            CHECK(memcmp(actual, expected, count) == 0);
            total += count;
            if (!count) break;
        }
        CHECK(total == size);
        fat32_close(&file);
        fclose(source);
        printf("PASS: PSC-OS boot lookup + FAT32 stream: %s, %u bytes\n", names[i], total);
    }
    fclose(image);
    return 0;
}
