#ifndef FAT32_H
#define FAT32_H

#include "user.h"

typedef struct {
    uint32_t part_lba;
    uint32_t fat_begin;
    uint32_t data_begin;
    uint32_t root_cluster;
    uint32_t sectors_per_cluster;
} fat32_info_t;

int fat32_cat(const char *name);
int fat32_find(const char *name, uint32_t *cluster, uint32_t *size);
int fat32_mount(void);
void fat32_ls(void);
int fat32_touch(const char *name);
int fat32_read(const char *name, uint8_t *dst, uint32_t max_size, uint32_t *read_size);

extern fat32_info_t g_fat32;

/* Read-only, root-directory, uppercase 8.3 streaming interface.
   A short successful read (including zero bytes) is normal EOF.
   Negative results are sticky until close/open. No heap allocation. */
enum {
    FAT32_OK = 0, FAT32_ERR_NAME = -2, FAT32_ERR_NOT_FOUND = -3,
    FAT32_ERR_SD = -4, FAT32_ERR_FORMAT = -5, FAT32_ERR_CHAIN = -6,
    FAT32_ERR_STATE = -7
};
typedef struct {
    uint32_t file_size, file_pos, first_cluster, current_cluster;
    uint32_t data_begin, fat_begin, sectors_per_cluster, cluster_count;
    uint32_t sector_in_cluster, sector_offset, cached_lba;
    uint32_t chain_anchor, chain_power, chain_length, chain_steps;
    int error, opened;
    uint8_t sector_buf[512];
} fat32_file_t;
int fat32_open(fat32_file_t *file, const char *name);
int fat32_stream_read(fat32_file_t *file, void *dst, uint32_t count,
                      uint32_t *actual);
int fat32_skip(fat32_file_t *file, uint32_t count, uint32_t *actual);
void fat32_close(fat32_file_t *file);

#endif
