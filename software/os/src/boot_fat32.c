#include "boot_fat32.h"
#include "common.h"

#define FAT32_EOC_MIN      0x0FFFFFF8u
#define FAT32_BAD_CLUSTER  0x0FFFFFF7u

static uint8_t fat32_buf[512];
static uint8_t file_buf[512];

static boot_sd_read_sector_fn g_read_sector;

static uint32_t g_part_lba;
static uint32_t g_fat_begin_lba;
static uint32_t g_data_begin_lba;
static uint32_t g_sectors_per_cluster;
static uint32_t g_root_cluster;

static uint16_t rd16(const uint8_t *p)
{
    return (uint16_t)p[0] |
           ((uint16_t)p[1] << 8);
}

static uint32_t rd32(const uint8_t *p)
{
    return ((uint32_t)p[0]) |
           ((uint32_t)p[1] << 8) |
           ((uint32_t)p[2] << 16) |
           ((uint32_t)p[3] << 24);
}

static char upper_char(char c)
{
    if (c >= 'a' && c <= 'z')
        return (char)(c - 'a' + 'A');

    return c;
}

static int is_fat32_boot_sector(const uint8_t *b)
{
    if (b[510] != 0x55 || b[511] != 0xAA)
        return 0;

    if (rd16(&b[11]) != 512u)
        return 0;

    if (b[13] == 0)
        return 0;

    if (rd16(&b[14]) == 0)
        return 0;

    if (b[16] == 0)
        return 0;

    if (rd32(&b[36]) == 0)
        return 0;

    if (rd32(&b[44]) < 2)
        return 0;

    return 1;
}

uint32_t boot_fat32_cluster_to_lba(uint32_t cluster)
{
    uint32_t lba;
    uint32_t n;

    //s_printf("FAT32: c2l enter\n");

    lba = g_data_begin_lba;

    if (cluster < 2u) {
        s_printf("FAT32: c2l bad\n");
        return lba;
    }

    //s_printf("FAT32: c2l sub\n");

    n = cluster - 2u;

    //s_printf("FAT32: c2l loop\n");

    while (n > 0u) {
        lba += g_sectors_per_cluster;
        n--;
    }

    //s_printf("FAT32: c2l done\n");

    return lba;
}

int boot_fat32_mount(boot_sd_read_sector_fn read_sector)
{
    uint8_t *buf = fat32_buf;

    uint32_t bytes_per_sector;
    uint32_t reserved_sector_count;
    uint32_t fat_count;
    uint32_t fat_size;

    s_printf("FAT32: mount enter\n");

    g_read_sector = read_sector;

    if (g_read_sector == 0) {
        s_printf("FAT32: read_sector null\n");
        return -1;
    }

    s_printf("FAT32: read LBA0\n");

    if (g_read_sector(0, buf)) {
        s_printf("FAT32: read LBA0 failed\n");
        return -1;
    }

    s_printf("FAT32: read LBA0 ok\n");

    if (is_fat32_boot_sector(buf)) {
        g_part_lba = 0;
        s_printf("FAT32: super floppy\n");
    } else {
        if (buf[510] != 0x55 || buf[511] != 0xAA) {
            s_printf("FAT32: MBR sig bad\n");
            return -1;
        }

        g_part_lba = rd32(&buf[0x1C6]);

        s_printf("FAT32: part ok\n");

        if (g_part_lba == 0u) {
            s_printf("FAT32: part_lba zero\n");
            return -1;
        }

        s_printf("FAT32: read BPB\n");

        if (g_read_sector(g_part_lba, buf)) {
            s_printf("FAT32: read BPB failed\n");
            return -1;
        }

        s_printf("FAT32: read BPB ok\n");

        if (!is_fat32_boot_sector(buf)) {
            s_printf("FAT32: BPB invalid\n");
            return -1;
        }

        s_printf("FAT32: BPB valid\n");
    }

    s_printf("FAT32: parse 1\n");
    bytes_per_sector = rd16(&buf[11]);

    s_printf("FAT32: parse 2\n");
    g_sectors_per_cluster = buf[13];

    s_printf("FAT32: parse 3\n");
    reserved_sector_count = rd16(&buf[14]);

    s_printf("FAT32: parse 4\n");
    fat_count = buf[16];

    s_printf("FAT32: parse 5\n");
    fat_size = rd32(&buf[36]);

    s_printf("FAT32: parse 6\n");
    g_root_cluster = rd32(&buf[44]);

    s_printf("FAT32: validate\n");

    if (bytes_per_sector != 512u) {
        s_printf("FAT32: bad bps\n");
        return -1;
    }

    if (g_sectors_per_cluster == 0u) {
        s_printf("FAT32: bad spc\n");
        return -1;
    }

    if (reserved_sector_count == 0u) {
        s_printf("FAT32: bad reserved\n");
        return -1;
    }

    if (fat_count == 0u || fat_count > 4u) {
        s_printf("FAT32: bad fat_count\n");
        return -1;
    }

    if (fat_size == 0u) {
        s_printf("FAT32: bad fat_size\n");
        return -1;
    }

    if (g_root_cluster < 2u) {
        s_printf("FAT32: bad root_cluster\n");
        return -1;
    }

    s_printf("FAT32: root check\n");

    if (g_root_cluster == 2u)
        s_printf("FAT32: root is 2\n");
    else
        s_printf("FAT32: root NOT 2\n");

    s_printf("FAT32: calc fat\n");

    g_fat_begin_lba = g_part_lba + reserved_sector_count;

    s_printf("FAT32: calc data\n");

    g_data_begin_lba = g_fat_begin_lba;

    if (fat_count >= 1u) {
        s_printf("FAT32: add fat1\n");
        g_data_begin_lba += fat_size;
    }

    if (fat_count >= 2u) {
        s_printf("FAT32: add fat2\n");
        g_data_begin_lba += fat_size;
    }

    if (fat_count >= 3u) {
        s_printf("FAT32: add fat3\n");
        g_data_begin_lba += fat_size;
    }

    if (fat_count >= 4u) {
        s_printf("FAT32: add fat4\n");
        g_data_begin_lba += fat_size;
    }

    s_printf("FAT32: mount ok\n");

    return 0;
}

uint32_t boot_fat32_next_cluster(uint32_t cluster)
{
    uint32_t fat_offset = cluster * 4u;
    uint32_t fat_lba    = g_fat_begin_lba + (fat_offset / 512u);
    uint32_t ent_off    = fat_offset & 0x1FFu;
    uint32_t next;

    if (cluster < 2u)
        return FAT32_EOC_MIN;

    if (g_read_sector(fat_lba, fat32_buf))
        return FAT32_EOC_MIN;

    next = rd32(&fat32_buf[ent_off]);
    next &= 0x0FFFFFFFu;

    return next;
}

int boot_fat32_find(
    const char *name,
    uint32_t *cluster,
    uint32_t *size
)
{
    uint32_t dir_cluster;
    char target[11];

    s_printf("FAT32: find enter\n");

    for (int i = 0; i < 11; i++)
        target[i] = ' ';

    {
        int i = 0;
        int j = 0;

        while (name[i] != '\0' && name[i] != '.' && j < 8) {
            target[j++] = upper_char(name[i]);
            i++;
        }

        if (name[i] == '.')
            i++;

        j = 8;

        while (name[i] != '\0' && j < 11) {
            target[j++] = upper_char(name[i]);
            i++;
        }
    }

    dir_cluster = g_root_cluster;

    s_printf("FAT32: root loop\n");

    while (dir_cluster >= 2u &&
           dir_cluster < FAT32_EOC_MIN &&
           dir_cluster != FAT32_BAD_CLUSTER) {

        uint32_t dir_lba;

        s_printf("FAT32: calc lba\n");

        /* root cluster = 2 固定で検証 */
        dir_lba = g_data_begin_lba;

        s_printf("FAT32: read dir\n");

        for (uint32_t s = 0; s < g_sectors_per_cluster; s++) {

            uint8_t *e;

            if (g_read_sector(dir_lba + s, fat32_buf)) {
                s_printf("FAT32: read dir failed\n");
                return -1;
            }

            s_printf("FAT32: dir ok\n");

            e = fat32_buf;

            for (int i = 0; i < 16; i++) {
                uint8_t attr;
                int match;

                if (e[0] == 0x00) {
                    s_printf("FAT32: dir end\n");
                    return -1;
                }

                if (e[0] == 0xE5) {
                    e += 32;
                    continue;
                }

                attr = e[11];

                if (attr == 0x0F) {
                    e += 32;
                    continue;
                }

                if (attr & 0x08) {
                    e += 32;
                    continue;
                }

                if (attr & 0x10) {
                    e += 32;
                    continue;
                }

                s_printf("FAT32: entry\n");

                match = 1;

                for (int k = 0; k < 11; k++) {
                    if ((char)e[k] != target[k]) {
                        match = 0;
                        break;
                    }
                }

                if (match) {
                    uint32_t cl_hi;
                    uint32_t cl_lo;

                    s_printf("FAT32: found\n");

                    cl_hi = rd16(&e[20]);
                    cl_lo = rd16(&e[26]);

                    *cluster = (cl_hi << 16) | cl_lo;
                    *size    = rd32(&e[28]);

                    return 0;
                }

                e += 32;
            }
        }

        s_printf("FAT32: next\n");

        dir_cluster = boot_fat32_next_cluster(dir_cluster);
    }

    s_printf("FAT32: not found\n");

    return -1;
}

static uint32_t boot_fat32_spc_shift(void)
{
    if (g_sectors_per_cluster == 1u)   return 0u;
    if (g_sectors_per_cluster == 2u)   return 1u;
    if (g_sectors_per_cluster == 4u)   return 2u;
    if (g_sectors_per_cluster == 8u)   return 3u;
    if (g_sectors_per_cluster == 16u)  return 4u;
    if (g_sectors_per_cluster == 32u)  return 5u;
    if (g_sectors_per_cluster == 64u)  return 6u;
    if (g_sectors_per_cluster == 128u) return 7u;

    return 0xFFFFFFFFu;
}

static uint32_t boot_fat32_calc_lba_no_loop(uint32_t cluster)
{
    uint32_t shift;

    shift = boot_fat32_spc_shift();

    if (shift == 0xFFFFFFFFu) {
        s_printf("FAT32: bad spc shift\n");
        return g_data_begin_lba;
    }

    return g_data_begin_lba + ((cluster - 2u) << shift);
}

int boot_fat32_load_file(
    const char *name,
    uint32_t dst_addr,
    uint32_t *loaded_size
)
{
    uint32_t cluster;
    uint32_t size;
    uint32_t remain;
    volatile uint8_t *dst;

    s_printf("FAT32: load enter\n");

    if (boot_fat32_find(name, &cluster, &size)) {
        s_printf("FAT32: find failed\n");
        return -1;
    }

    s_printf("FAT32: find ok\n");

    s_printf("FAT32: cluster=");
    s_print_int((int)cluster);
    s_printf("\n");

    s_printf("FAT32: size=");
    s_print_int((int)size);
    s_printf("\n");

    if (size == 0u) {
        s_printf("FAT32: size zero\n");
        return -1;
    }

    if (cluster < 2u) {
        s_printf("FAT32: invalid start cluster\n");
        return -1;
    }

    dst = (volatile uint8_t *)dst_addr;
    remain = size;

    s_printf("FAT32: remain set\n");

    while (remain > 0u) {
        uint32_t lba;

        s_printf("FAT32: loop enter\n");

        if (cluster < 2u) {
            s_printf("FAT32: cluster <2\n");
            return -1;
        }

        if (cluster == FAT32_BAD_CLUSTER) {
            s_printf("FAT32: bad cluster\n");
            return -1;
        }

        if (cluster >= FAT32_EOC_MIN) {
            s_printf("FAT32: EOC before complete\n");
            return -1;
        }

        s_printf("FAT32: calc lba\n");

        lba = boot_fat32_calc_lba_no_loop(cluster);

        s_printf("FAT32: lba ok\n");

        for (uint32_t s = 0; s < g_sectors_per_cluster; s++) {
            uint32_t copy_size;

            if (remain == 0u)
                break;

            s_printf("FAT32: read file sector\n");

            if (g_read_sector(lba + s, file_buf)) {
                s_printf("FAT32: read file failed\n");
                return -1;
            }

            s_printf("FAT32: file sector ok\n");

            copy_size = (remain > 512u) ? 512u : remain;

            for (uint32_t i = 0; i < copy_size; i++)
                dst[i] = file_buf[i];

            dst += copy_size;
            remain -= copy_size;

            s_printf("FAT32: copy ok\n");
        }

        if (remain == 0u) {
            s_printf("FAT32: file complete\n");
            break;
        }

        s_printf("FAT32: next cluster\n");

        cluster = boot_fat32_next_cluster(cluster);

        s_printf("FAT32: next cluster ok\n");
    }

    if (loaded_size)
        *loaded_size = size;

    s_printf("FAT32: load done\n");

    return 0;
}

static int hex_val(char c)
{
    if (c >= '0' && c <= '9')
        return c - '0';

    if (c >= 'a' && c <= 'f')
        return c - 'a' + 10;

    if (c >= 'A' && c <= 'F')
        return c - 'A' + 10;

    return -1;
}

int boot_fat32_load_mem_file(
    const char *name,
    uint32_t dst_addr,
    uint32_t *loaded_words
)
{
    uint32_t cluster;
    uint32_t size;
    uint32_t remain;
    volatile uint32_t *dst;
    uint32_t words;
    uint32_t hex_count;
    uint32_t word;

    s_printf("FAT32: load mem enter\n");

    if (boot_fat32_find(name, &cluster, &size)) {
        s_printf("FAT32: find failed\n");
        return -1;
    }

    s_printf("FAT32: find ok\n");

    if (size == 0u) {
        s_printf("FAT32: size zero\n");
        return -1;
    }

    if (cluster < 2u) {
        s_printf("FAT32: invalid start cluster\n");
        return -1;
    }

    dst = (volatile uint32_t *)dst_addr;
    remain = size;
    words = 0;
    hex_count = 0;
    word = 0;

    while (remain > 0u) {
        uint32_t lba;

        if (cluster < 2u) {
            s_printf("FAT32: cluster <2\n");
            return -1;
        }

        if (cluster == FAT32_BAD_CLUSTER) {
            s_printf("FAT32: bad cluster\n");
            return -1;
        }

        if (cluster >= FAT32_EOC_MIN) {
            s_printf("FAT32: EOC before complete\n");
            return -1;
        }

        lba = boot_fat32_calc_lba_no_loop(cluster);

        for (uint32_t s = 0; s < g_sectors_per_cluster; s++) {
            uint32_t sector_bytes;

            if (remain == 0u)
                break;

            if (g_read_sector(lba + s, file_buf)) {
                s_printf("FAT32: read file failed\n");
                return -1;
            }

            sector_bytes = (remain > 512u) ? 512u : remain;

            for (uint32_t i = 0; i < sector_bytes; i++) {
                char c = (char)file_buf[i];
                int h;

                h = hex_val(c);

                if (h >= 0) {
                    word = (word << 4) | (uint32_t)h;
                    hex_count++;

                    if (hex_count == 8u) {
                        dst[words] = word;
                        words++;

                        word = 0;
                        hex_count = 0;
                    }
                } else {
                    if (c == '\r' || c == '\n' || c == ' ' || c == '\t') {
                        continue;
                    }

                    s_printf("FAT32: bad mem char\n");
                    return -1;
                }
            }

            remain -= sector_bytes;
        }

        if (remain == 0u)
            break;

        cluster = boot_fat32_next_cluster(cluster);
    }

    if (hex_count != 0u) {
        s_printf("FAT32: partial hex word\n");
        return -1;
    }

    if (loaded_words)
        *loaded_words = words;

    s_printf("FAT32: load mem done\n");

    return 0;
}