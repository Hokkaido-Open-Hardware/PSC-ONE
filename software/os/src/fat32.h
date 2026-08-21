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

#endif