#include "fat32.h"
#include "../api/user.h"

static uint8_t fat32_buf[512];

fat32_info_t g_fat32;

static int fat32_next_cluster(uint32_t cluster, uint32_t *next);

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

    uint32_t remaining = size;
    while (remaining != 0) {
        if (cluster < 2 || cluster >= 0x0FFFFFF0u ||
            g_fat32.sectors_per_cluster == 0)
            return -1;

        uint32_t lba = cluster_to_lba(cluster);
        for (uint32_t sector = 0;
             sector < g_fat32.sectors_per_cluster && remaining != 0;
             ++sector) {
            if (call_sd_read_buf_api(lba + sector, buf))
                return -1;

            uint32_t count = remaining < sizeof(buf) ? remaining : sizeof(buf);
            for (uint32_t i = 0; i < count; ++i)
                putchar(buf[i]);
            remaining -= count;
        }

        if (remaining != 0) {
            uint32_t next;
            if (fat32_next_cluster(cluster, &next))
                return -1;
            cluster = next;
        }
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

    uint32_t dir_cluster = g_fat32.root_cluster;

    if (g_fat32.sectors_per_cluster == 0)
        return -1;

    while (dir_cluster >= 2 && dir_cluster < 0x0FFFFFF0u) {
        uint32_t root_lba = cluster_to_lba(dir_cluster);
        for (uint32_t sector = 0;
             sector < g_fat32.sectors_per_cluster; ++sector) {
            if (call_sd_read_buf_api(root_lba + sector, buf))
                return -1;

            for (int i = 0; i < 16; i++) {

                uint8_t *e = &buf[i * 32];

                // End of directory
                if (e[0] == 0x00)
                    return -1;

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
        }

        uint32_t next;
        if (fat32_next_cluster(dir_cluster, &next) || next == dir_cluster)
            return -1;
        dir_cluster = next;
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

/* Kept outside the SD buffer so names can cross sectors and clusters. */
typedef struct {
    uint16_t name[260]; /* 20 entries, 13 UTF-16 code units each */
    unsigned slots, next;
    uint8_t checksum;
} fat32_lfn_t;

static void fat32_lfn_entry(fat32_lfn_t *lfn, const uint8_t *e)
{
    static const uint8_t offsets[13] = {
        1, 3, 5, 7, 9, 14, 16, 18, 20, 22, 24, 28, 30
    };
    unsigned order = e[0] & 0x1f;
    if ((e[0] & 0xa0) || order == 0 || order > 20 ||
        e[12] != 0 || e[26] != 0 || e[27] != 0) {
        lfn->slots = 0;
        return;
    }
    if (e[0] & 0x40) {
        lfn->slots = order * 13;
        lfn->next = order;
        lfn->checksum = e[13];
    }
    if (!lfn->slots || lfn->next != order || lfn->checksum != e[13]) {
        lfn->slots = 0;
        return;
    }
    for (unsigned i = 0; i < 13; ++i) {
        unsigned p = offsets[i];
        lfn->name[(order - 1) * 13 + i] =
            (uint16_t)e[p] | ((uint16_t)e[p + 1] << 8);
    }
    --lfn->next;
}

/* Validate before printing anything; corrupt names fall back to 8.3. */
static unsigned fat32_lfn_length(const fat32_lfn_t *lfn, const uint8_t *e)
{
    if (!lfn->slots || lfn->next || (e[11] & 0x08))
        return 0;
    uint8_t checksum = 0;
    for (unsigned i = 0; i < 11; ++i)
        checksum = ((checksum & 1) << 7) + (checksum >> 1) + e[i];
    if (checksum != lfn->checksum)
        return 0;
    unsigned length = 0;
    while (length < lfn->slots && lfn->name[length] != 0) {
        if (lfn->name[length] == 0xffff)
            return 0;
        ++length;
    }
    if (!length || length > 255 || length <= lfn->slots - 13)
        return 0;
    for (unsigned i = length + 1; i < lfn->slots; ++i)
        if (lfn->name[i] != 0xffff)
            return 0;
    return length;
}

/* Console column widths for common combining, CJK and emoji characters.
 * Ambiguous-width characters are treated as one column.
 */
static unsigned fat32_name_columns(uint32_t ch)
{
    if ((ch >= 0x0300 && ch <= 0x036f) ||
        (ch >= 0xfe00 && ch <= 0xfe0f))
        return 0;
    if ((ch >= 0x1100 && ch <= 0x115f) ||
        (ch >= 0x2e80 && ch <= 0xa4cf && ch != 0x303f) ||
        (ch >= 0xac00 && ch <= 0xd7a3) ||
        (ch >= 0xf900 && ch <= 0xfaff) ||
        (ch >= 0xfe10 && ch <= 0xfe19) ||
        (ch >= 0xfe30 && ch <= 0xfe6f) ||
        (ch >= 0xff01 && ch <= 0xff60) ||
        (ch >= 0xffe0 && ch <= 0xffe6) ||
        (ch >= 0x1f300 && ch <= 0x1faff) ||
        (ch >= 0x20000 && ch <= 0x3fffd))
        return 2;
    return 1;
}

static unsigned fat32_lfn_print(const fat32_lfn_t *lfn, unsigned length)
{
    unsigned columns = 0, total = 0;
    /* Measure first so only overflowing names reserve room for "...". */
    for (unsigned pass = 0; pass < 2; ++pass) {
        for (unsigned i = 0; i < length; ++i) {
            uint32_t ch = lfn->name[i];
            if (ch >= 0xd800 && ch <= 0xdbff && i + 1 < length &&
                lfn->name[i + 1] >= 0xdc00 && lfn->name[i + 1] <= 0xdfff) {
                ch = 0x10000 + ((ch - 0xd800) << 10) +
                     (lfn->name[++i] - 0xdc00);
            } else if (ch >= 0xd800 && ch <= 0xdfff) {
                ch = 0xfffd;
            }
            unsigned width = fat32_name_columns(ch);
            if (pass == 0) {
                total += width;
                continue;
            }
            if (total > 28 && columns + width > 25)
                break;
            columns += width;
            if (ch < 0x80) {
                putchar(ch);
            } else {
                if (ch < 0x800) {
                    putchar(0xc0 | (ch >> 6));
                } else {
                    if (ch < 0x10000) {
                        putchar(0xe0 | (ch >> 12));
                    } else {
                        putchar(0xf0 | (ch >> 18));
                        putchar(0x80 | ((ch >> 12) & 0x3f));
                    }
                    putchar(0x80 | ((ch >> 6) & 0x3f));
                }
                putchar(0x80 | (ch & 0x3f));
            }
        }
    }
    if (total > 28) {
        printf("...");
        columns += 3;
    }
    return columns;
}

/* Both short names and LFNs finish at the same details column. */
static void fat32_name_print(const uint8_t *e, const fat32_lfn_t *lfn,
                             unsigned length)
{
    unsigned columns = 0;
    if (length) {
        columns = fat32_lfn_print(lfn, length);
    } else {
        for (int j = 0; j < 8; ++j) {
            if (e[j] != ' ') {
                putchar(e[j]);
                ++columns;
            }
        }
        if (e[8] != ' ') {
            putchar('.');
            ++columns;
            for (int j = 8; j < 11; ++j) {
                if (e[j] != ' ') {
                    putchar(e[j]);
                    ++columns;
                }
            }
        }
    }
    /* 28 columns plus two spaces, including the space before attr below. */
    for (; columns < 29; ++columns)
        putchar(' ');
}

void fat32_ls(void)
{
    uint8_t *buf = fat32_buf;
    fat32_lfn_t lfn;
    lfn.slots = 0;

    if (fat32_mount())
        return;

    uint32_t dir_cluster = g_fat32.root_cluster;
    if (g_fat32.sectors_per_cluster == 0)
        return;

    /* Match fat32_find: every sector of every root-directory cluster. */
    while (dir_cluster >= 2 && dir_cluster < 0x0FFFFFF0u) {
        uint32_t root_lba = cluster_to_lba(dir_cluster);
        for (uint32_t sector = 0;
             sector < g_fat32.sectors_per_cluster; ++sector) {
            if (call_sd_read_buf_api(root_lba + sector, buf))
                return;

            for (int i = 0; i < 16; i++) {

                uint8_t *e = &buf[i * 32];

                /* End of the entire directory, not just this sector. */
                if (e[0] == 0x00)
                    return;

                if (e[0] == 0xE5) {
                    lfn.slots = 0;
                    continue;
                }

                if (e[11] == 0x0F) {
                    fat32_lfn_entry(&lfn, e);
                    continue;
                }

                unsigned length = fat32_lfn_length(&lfn, e);
                fat32_name_print(e, &lfn, length);
                lfn.slots = 0;

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

        uint32_t next;
        if (fat32_next_cluster(dir_cluster, &next) || next == dir_cluster)
            return;
        dir_cluster = next;
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
