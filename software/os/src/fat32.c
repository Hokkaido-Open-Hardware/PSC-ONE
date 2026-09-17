#include "fat32.h"
#include "user.h"

static uint8_t fat32_buf[512];

fat32_info_t g_fat32;

int fat32_cat(const char *name)
{
    uint8_t buf[512];

    uint32_t cluster;
    uint32_t size;

    if (fat32_mount())
        return -1;

    if (fat32_find(name, &cluster, &size)) {
        printf("file not found\n");
        return -1;
    }

    uint32_t lba =
        cluster_to_lba(cluster);

    if (call_sd_read_buf_api(lba, buf))
        return -1;

    for (uint32_t i = 0; i < size; i++) {

        if (i >= 512)
            break;

        putchar(buf[i]);
    }

    putchar('\n');

    return 0;
}

int fat32_find(
    const char *name,
    uint32_t *cluster,
    uint32_t *size)
{
    uint8_t *buf = fat32_buf;

    if (fat32_mount())
        return -1;

    uint32_t root_lba =
        cluster_to_lba(g_fat32.root_cluster);

    if (call_sd_read_buf_api(root_lba, buf))
        return -1;

    for (int i = 0; i < 16; i++) {

        uint8_t *e = &buf[i * 32];

        // End of directory
        if (e[0] == 0x00)
            break;

        // Deleted
        if (e[0] == 0xE5)
            continue;

        // LFN
        if (e[11] == 0x0F)
            continue;

        char shortname[13];
        int k = 0;

        // name
        for (int j = 0; j < 8; j++) {
            if (e[j] != ' ')
                shortname[k++] = e[j];
        }

        // extension
        if (e[8] != ' ') {

            shortname[k++] = '.';

            for (int j = 8; j < 11; j++) {
                if (e[j] != ' ')
                    shortname[k++] = e[j];
            }
        }

        shortname[k] = '\0';

        if (strcmp(shortname, name) == 0) {

            uint32_t cl_hi =
                ((uint32_t)e[20]) |
                ((uint32_t)e[21] << 8);

            uint32_t cl_lo =
                ((uint32_t)e[26]) |
                ((uint32_t)e[27] << 8);

            *cluster =
                (cl_hi << 16) | cl_lo;

            *size =
                ((uint32_t)e[28]) |
                ((uint32_t)e[29] << 8) |
                ((uint32_t)e[30] << 16) |
                ((uint32_t)e[31] << 24);

            return 0;
        }
    }

    return -1;
}

uint32_t cluster_to_lba(uint32_t cluster)
{
    return g_fat32.data_begin +
           (cluster - 2) *
           g_fat32.sectors_per_cluster;
}

int fat32_mount(void)
{
    uint8_t *buf = fat32_buf;

    if (call_sd_read_buf_api(0, buf))
        return -1;

    g_fat32.part_lba =
        ((uint32_t)buf[0x1C6]) |
        ((uint32_t)buf[0x1C7] << 8) |
        ((uint32_t)buf[0x1C8] << 16) |
        ((uint32_t)buf[0x1C9] << 24);

    if (call_sd_read_buf_api(g_fat32.part_lba, buf))
        return -1;

    uint32_t reserved =
        ((uint32_t)buf[14]) |
        ((uint32_t)buf[15] << 8);

    uint32_t fat_count =
        (uint32_t)buf[16];

    uint32_t fat_size =
        ((uint32_t)buf[36]) |
        ((uint32_t)buf[37] << 8) |
        ((uint32_t)buf[38] << 16) |
        ((uint32_t)buf[39] << 24);

    g_fat32.sectors_per_cluster =
        (uint32_t)buf[13];

    g_fat32.root_cluster =
        ((uint32_t)buf[44]) |
        ((uint32_t)buf[45] << 8) |
        ((uint32_t)buf[46] << 16) |
        ((uint32_t)buf[47] << 24);

    g_fat32.fat_begin =
        g_fat32.part_lba + reserved;

    g_fat32.data_begin =
        g_fat32.fat_begin + fat_count * fat_size;

    return 0;
}

void fat32_ls(void)
{
    uint8_t *buf = fat32_buf;

    if (fat32_mount())
        return;

    uint32_t root_lba =
        cluster_to_lba(g_fat32.root_cluster);

    if (call_sd_read_buf_api(root_lba, buf))
        return;

    for (int i = 0; i < 16; i++) {

        uint8_t *e = &buf[i * 32];

        if (e[0] == 0x00)
            break;

        if (e[0] == 0xE5)
            continue;

        if (e[11] == 0x0F)
            continue;

        for (int j = 0; j < 8; j++) {
            if (e[j] != ' ')
                putchar(e[j]);
        }

        if (e[8] != ' ') {
            putchar('.');
            for (int j = 8; j < 11; j++) {
                if (e[j] != ' ')
                    putchar(e[j]);
            }
        }

        printf(" attr=%x", (uint32_t)e[11]);

        uint32_t cl_hi =
            ((uint32_t)e[20]) |
            ((uint32_t)e[21] << 8);

        uint32_t cl_lo =
            ((uint32_t)e[26]) |
            ((uint32_t)e[27] << 8);

        uint32_t cl =
            (cl_hi << 16) | cl_lo;

        uint32_t lba = 0;

        if (cl >= 2)
            lba = cluster_to_lba(cl);

        uint32_t size =
            ((uint32_t)e[28]) |
            ((uint32_t)e[29] << 8) |
            ((uint32_t)e[30] << 16) |
            ((uint32_t)e[31] << 24);

        //printf(" cl=%x size=%x\n", cl, size);
        printf(" cl=%x lba=%x size=%x\n",
                cl,
                lba,
                size);
    }
}

static int fat32_make_shortname(
    const char *name,
    uint8_t out[11])
{
    int i;

    // space fill
    for (i = 0; i < 11; i++)
        out[i] = ' ';

    int pos = 0;

    // basename
    while (*name &&
           *name != '.' &&
           pos < 8) {

        out[pos++] = *name++;
    }

    // skip basename overflow
    while (*name &&
           *name != '.')
        name++;

    if (*name == '.')
        name++;

    // extension
    pos = 8;

    while (*name && pos < 11) {
        out[pos++] = *name++;
    }

    return 0;
}

int fat32_touch(const char *name)
{
    uint8_t *buf = fat32_buf;

    if (fat32_mount())
        return -1;

    uint32_t root_lba =
        cluster_to_lba(g_fat32.root_cluster);

    if (call_sd_read_buf_api(root_lba, buf))
        return -1;

    uint8_t shortname[11];

    fat32_make_shortname(name, shortname);

    for (int i = 0; i < 16; i++) {

        uint8_t *e = &buf[i * 32];

        if (e[0] != 0x00 &&
            e[0] != 0xE5)
            continue;

        for (int j = 0; j < 32; j++)
            e[j] = 0;

        // 8.3 filename
        for (int j = 0; j < 11; j++)
            e[j] = shortname[j];

        // archive
        e[11] = 0x20;

        // first cluster = 0
        e[20] = 0;
        e[21] = 0;
        e[26] = 0;
        e[27] = 0;

        // size = 0
        e[28] = 0;
        e[29] = 0;
        e[30] = 0;
        e[31] = 0;

        printf("USER BUF: ");

        /*
        for (int i = 0; i < 16; i++) {
            printf("%x ", (uint32_t)buf[i]);
        }
        */

        printf("\n");

        if (call_sd_write_buf_api(root_lba, buf))
            return -1;

        printf("created: %s\n", name);

        return 0;
    }

    return -1;
}

static int fat32_next_cluster(uint32_t cluster, uint32_t *next)
{
    uint8_t buf[512];

    uint32_t fat_offset = cluster * 4;
    uint32_t fat_sector = g_fat32.fat_begin + (fat_offset / 512);
    uint32_t ent_offset = fat_offset % 512;

    if (call_sd_read_buf_api(fat_sector, buf))
        return -1;

    uint32_t value =
        ((uint32_t)buf[ent_offset + 0]) |
        ((uint32_t)buf[ent_offset + 1] << 8) |
        ((uint32_t)buf[ent_offset + 2] << 16) |
        ((uint32_t)buf[ent_offset + 3] << 24);

    value &= 0x0FFFFFFF;

    *next = value;
    return 0;
}

int fat32_read(
    const char *name,
    uint8_t *dst,
    uint32_t max_size,
    uint32_t *read_size)
{
    uint8_t buf[512];

    uint32_t cluster;
    uint32_t file_size;

    if (read_size)
        *read_size = 0;

    if (fat32_mount())
        return -1;

    if (fat32_find(name, &cluster, &file_size)) {
        printf("file not found\n");
        return -1;
    }

    uint32_t remaining = file_size;

    if (remaining > max_size)
        remaining = max_size;

    uint32_t total = 0;

    while (remaining > 0) {

        uint32_t first_lba = cluster_to_lba(cluster);

        for (uint32_t s = 0;
             s < g_fat32.sectors_per_cluster && remaining > 0;
             s++) {

            if (call_sd_read_buf_api(first_lba + s, buf))
                return -1;

            uint32_t n = remaining;

            if (n > 512)
                n = 512;

            for (uint32_t i = 0; i < n; i++)
                dst[total + i] = buf[i];

            total += n;
            remaining -= n;
        }

        if (remaining == 0)
            break;

        uint32_t next;

        if (fat32_next_cluster(cluster, &next))
            return -1;

        // FAT32 end-of-chain
        if (next >= 0x0FFFFFF8)
            break;

        cluster = next;
    }

    if (read_size)
        *read_size = total;

    return 0;
}