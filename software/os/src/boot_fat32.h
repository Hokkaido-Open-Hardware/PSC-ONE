#ifndef BOOT_FAT32_H
#define BOOT_FAT32_H

#include <stdint.h>

typedef int (*boot_sd_read_sector_fn)(
    uint32_t lba,
    uint8_t *buf
);

typedef struct {
    uint32_t part_lba;
    uint32_t fat_begin;
    uint32_t data_begin;
    uint32_t root_cluster;
    uint32_t sectors_per_cluster;
    boot_sd_read_sector_fn read_sector;
} boot_fat32_t;

typedef int (*boot_sd_read_sector_fn)(
    uint32_t lba,
    uint8_t *buf
);

int boot_fat32_mount(
    boot_sd_read_sector_fn read_sector
);

int boot_fat32_find(
    const char *name,
    uint32_t *cluster,
    uint32_t *size
);

uint32_t boot_fat32_cluster_to_lba(
    uint32_t cluster
);

uint32_t boot_fat32_next_cluster(
    uint32_t cluster
);

int boot_fat32_load_file(
    const char *name,
    uint32_t dst_addr,
    uint32_t *loaded_size
);

int boot_fat32_load_mem_file(
    const char *name,
    uint32_t dst_addr,
    uint32_t *loaded_words
);

#endif