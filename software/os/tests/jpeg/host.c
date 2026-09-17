/* Host-only SD/LCD boundary model; production stream and decoder are linked. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#define printf psc_printf
#define putchar psc_putchar
#define exit psc_exit
#include "jpeg/tjpgd_port.h"
#include "jpeg/jpeg_view.h"
#undef printf
#undef putchar
#undef exit

static uint8_t disk[1024][512], image[480 * 320 * 3], seen[480 * 320];
static uint8_t source[200000];
static int failed_lba = -1, lcd_fail, began;
static unsigned blocks, pixels, image_width;
#define CHECK(c) do { if (!(c)) { fprintf(stderr, "CHECK line %d: %s\n", __LINE__, #c); abort(); } } while (0)
void psc_printf(const char *fmt, ...) { (void)fmt; }
int call_sd_read_buf_api(uint32_t lba, void *out) {
    if (lba >= 1024 || (int)lba == failed_lba) return -1;
    memcpy(out, disk[lba], 512); return 0;
}
int call_lcd_rgb888_begin(void) { began++; return lcd_fail == 1 ? -1 : 0; }
int call_lcd_rgb888_rect(uint32_t x, uint32_t y, uint32_t w, uint32_t h, const uint8_t *rgb) {
    CHECK(began == 1 && w && h && w <= 16 && h <= 16 && x + w <= 480 && y + h <= 320);
    if (lcd_fail == 2 || (lcd_fail == 3 && blocks == 20)) return -1;
    if (x + w > image_width) image_width = x + w;
    blocks++;
    for (unsigned row = 0; row < h; row++) for (unsigned col = 0; col < w; col++) {
        unsigned off = (y + row) * 480 + x + col;
        CHECK(!seen[off]); seen[off] = 1; pixels++;
        memcpy(image + off * 3, rgb + (row * w + col) * 3, 3);
    }
    return 0;
}
static void w16(uint8_t *p, unsigned n) { p[0] = n; p[1] = n >> 8; }
static void w32(uint8_t *p, unsigned n) { w16(p, n); w16(p + 2, n >> 16); }
static unsigned data_lba(unsigned cluster) { return 10 + cluster - 2; }
static void setup(unsigned size) {
    memset(disk, 0, sizeof(disk)); memset(image, 0, sizeof(image)); memset(seen, 0, sizeof(seen));
    began = blocks = pixels = image_width = 0;
    w16(disk[0] + 510, 0xaa55); w32(disk[0] + 0x1c6, 1);
    uint8_t *b = disk[1];
    w16(b + 510, 0xaa55); w16(b + 11, 512); b[13] = 1; w16(b + 14, 1); b[16] = 1;
    w32(b + 32, 1023); w32(b + 36, 8); w32(b + 44, 2);
    w32(disk[2] + 8, 0x0fffffff);
    uint8_t *e = disk[10]; memcpy(e, "TEST    JPG", 11); e[11] = 0x20;
    w16(e + 26, 3); w32(e + 28, size);
    unsigned count = (size + 511) / 512;
    for (unsigned i = 0; i < count; i++) {
        unsigned cluster = 3 + i * 2;
        w32(disk[2 + cluster / 128] + (cluster % 128) * 4,
            i + 1 == count ? 0x0fffffffu : cluster + 2);
        unsigned n = size - i * 512; if (n > 512) n = 512;
        memcpy(disk[data_lba(cluster)], source + i * 512, n);
    }
}
static void stream_tests(unsigned size) {
    fat32_file_t f; uint8_t b[777]; uint32_t got;
    CHECK(fat32_open(&f, "TEST.JPG") == 0 && f.file_size == size);
    CHECK(fat32_stream_read(&f, b, 7, &got) == 0 && got == 7 && !memcmp(b, source, got));
    CHECK(fat32_skip(&f, 511, &got) == 0 && got == 511);
    unsigned pos = 518;
    while (pos < size) {
        CHECK(fat32_stream_read(&f, b, sizeof(b), &got) == 0 && got && !memcmp(b, source + pos, got));
        pos += got;
    }
    CHECK(fat32_stream_read(&f, b, 1, &got) == 0 && got == 0);
    fat32_close(&f); CHECK(fat32_stream_read(&f, b, 1, &got) == FAT32_ERR_STATE);
    CHECK(fat32_open(&f, "test.jpg") == FAT32_ERR_NAME);
    CHECK(fat32_open(&f, "DIR/TEST.JPG") == FAT32_ERR_NAME);
    CHECK(fat32_open(&f, "MISSING.JPG") == FAT32_ERR_NOT_FOUND);
    w32(disk[2] + 12, 0x0fffffff);
    CHECK(fat32_open(&f, "TEST.JPG") == 0);
    CHECK(fat32_skip(&f, size, &got) == FAT32_ERR_CHAIN);
    w32(disk[2] + 12, 3);
    CHECK(fat32_open(&f, "TEST.JPG") == 0);
    CHECK(fat32_skip(&f, size, &got) == FAT32_ERR_CHAIN);
    w32(disk[2] + 12, 0x0ffffff7);
    CHECK(fat32_open(&f, "TEST.JPG") == 0);
    CHECK(fat32_skip(&f, size, &got) == FAT32_ERR_CHAIN);
    setup(size);
    w32(disk[2] + 20, 3); /* 3 -> 5 -> 3 */
    CHECK(fat32_open(&f, "TEST.JPG") == 0);
    CHECK(fat32_skip(&f, size, &got) == FAT32_ERR_CHAIN);
    setup(size);
    /* Search across a fragmented root directory chain. */
    memcpy(disk[12], disk[10], 32);
    memset(disk[10], 0xe5, 512);
    w32(disk[2] + 8, 4); w32(disk[2] + 16, 0x0fffffff);
    CHECK(fat32_open(&f, "TEST.JPG") == 0 && f.file_size == size);
    setup(size);
    failed_lba = 2; CHECK(fat32_open(&f, "TEST.JPG") == 0);
    CHECK(fat32_skip(&f, size, &got) == FAT32_ERR_SD); failed_lba = -1;
}
int main(int argc, char **argv) {
    CHECK(argc >= 3);
    FILE *fp = fopen(argv[1], "rb"); CHECK(fp);
    unsigned size = fread(source, 1, sizeof(source), fp); CHECK(!ferror(fp) && feof(fp)); fclose(fp);
    CHECK(size < sizeof(source)); setup(size);
    if (argc > 3 && !strcmp(argv[3], "stream")) {
        stream_tests(size); puts("stream PASS"); return 0;
    }
    if (argc > 3 && !strcmp(argv[3], "sd")) failed_lba = data_lba(3);
    if (argc > 3 && !strcmp(argv[3], "lcd1")) lcd_fail = 1;
    if (argc > 3 && !strcmp(argv[3], "lcd2")) lcd_fail = 2;
    if (argc > 3 && !strcmp(argv[3], "lcdmid")) lcd_fail = 3;
    if (argc > 3 && !strcmp(argv[3], "sdmid")) failed_lba = data_lba(11);
    if (argc > 3 && !strcmp(argv[3], "retry")) {
        lcd_fail = 2; CHECK(jpeg_view("TEST.JPG") == JPEG_ERR_LCD);
        lcd_fail = 0; setup(size);
    }
    int result = jpeg_view("TEST.JPG");
    printf("result=%d blocks=%u pixels=%u\n", result, blocks, pixels);
    int expected = atoi(argv[2]);
    if (expected == 1) CHECK(result < 0); else CHECK(result == expected);
    if (!result) {
        CHECK(pixels && pixels % image_width == 0);
        unsigned height = pixels / image_width;
        fp = fopen("decoded.rgb", "wb"); CHECK(fp);
        for (unsigned y = 0; y < height; y++) {
            for (unsigned x = 0; x < image_width; x++) CHECK(seen[y * 480 + x]);
            CHECK(fwrite(image + y * 480 * 3, 3, image_width, fp) == image_width);
        }
        fclose(fp);
    }
    return 0;
}
