#include "fat32.h"

static uint32_t le16(const uint8_t *p) { return p[0] | ((uint32_t)p[1] << 8); }
static uint32_t le32(const uint8_t *p) {
    return le16(p) | (le16(p + 2) << 16);
}
static int fail(fat32_file_t *f, int error) { f->error = error; return error; }
static int valid_cluster(const fat32_file_t *f, uint32_t c) {
    return c >= 2 && c - 2 < f->cluster_count && c < 0x0ffffff0u;
}
static int sector(fat32_file_t *f, uint32_t lba) {
    if (f->cached_lba != lba) {
        if (call_sd_read_buf_api(lba, f->sector_buf))
            return fail(f, FAT32_ERR_SD);
        f->cached_lba = lba;
    }
    return FAT32_OK;
}
static void chain_start(fat32_file_t *f, uint32_t c) {
    f->current_cluster = f->chain_anchor = c;
    f->chain_power = 1;
    f->chain_length = f->chain_steps = 0;
    f->sector_in_cluster = f->sector_offset = 0;
}
/* Brent cycle detection and a volume-sized traversal limit, O(1) RAM.
   Return 1 for EOC; callers decide whether it is expected. */
static int next_cluster(fat32_file_t *f) {
    uint32_t c = f->current_cluster;
    if (!valid_cluster(f, c)) return fail(f, FAT32_ERR_CHAIN);
    if (sector(f, f->fat_begin + c / 128)) return f->error;
    uint32_t next = le32(f->sector_buf + (c % 128) * 4) & 0x0fffffffu;
    if (next >= 0x0ffffff8u) return 1;
    if (!valid_cluster(f, next) || ++f->chain_steps >= f->cluster_count)
        return fail(f, FAT32_ERR_CHAIN);
    if (next == f->chain_anchor) return fail(f, FAT32_ERR_CHAIN);
    if (++f->chain_length == f->chain_power) {
        f->chain_anchor = next;
        f->chain_length = 0;
        if (f->chain_power < 0x10000000u) f->chain_power *= 2;
    }
    f->current_cluster = next;
    f->sector_in_cluster = f->sector_offset = 0;
    return 0;
}
static int short_name(const char *name, uint8_t out[11]) {
    unsigned base = 0, ext = 0, dot = 0;
    if (!name) return 0;
    for (unsigned i = 0; i < 11; i++) out[i] = ' ';
    for (; *name; name++) {
        unsigned char c = (unsigned char)*name;
        if (c == '.' && !dot && base) { dot = 1; continue; }
        /* Deliberately small uppercase 8.3 subset; no paths. */
        if (!((c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') ||
              c == '_' || c == '-')) return 0;
        if (!dot) { if (base == 8) return 0; out[base++] = c; }
        else { if (ext == 3) return 0; out[8 + ext++] = c; }
    }
    return base && (!dot || ext);
}
void fat32_close(fat32_file_t *f) {
    if (f) { f->opened = 0; f->cached_lba = 0xffffffffu; }
}
int fat32_open(fat32_file_t *f, const char *name) {
    uint8_t wanted[11];
    if (!f) return FAT32_ERR_STATE;
    f->opened = 0; f->error = 0; f->file_pos = f->file_size = 0;
    f->cached_lba = 0xffffffffu;
    if (!short_name(name, wanted)) return fail(f, FAT32_ERR_NAME);
    if (sector(f, 0)) return f->error;
    if (le16(f->sector_buf + 510) != 0xaa55) return fail(f, FAT32_ERR_FORMAT);
    uint32_t part = le32(f->sector_buf + 0x1c6);
    if (!part || sector(f, part)) return f->error ? f->error : fail(f, FAT32_ERR_FORMAT);
    uint8_t *b = f->sector_buf;
    uint32_t spc = b[13], reserved = le16(b + 14), fats = b[16];
    uint32_t fatsz = le32(b + 36), total = le32(b + 32), root = le32(b + 44);
    if (le16(b + 510) != 0xaa55 || le16(b + 11) != 512 ||
        !spc || spc > 128 || (spc & (spc - 1)) || !reserved ||
        !fats || fats > 2 || !fatsz || fatsz > 0x01000000u ||
        le16(b + 17) || le16(b + 22) || le16(b + 42) ||
        total > 0xffffffffu - part)
        return fail(f, FAT32_ERR_FORMAT);
    uint32_t overhead = reserved + fats * fatsz;
    if (total <= overhead) return fail(f, FAT32_ERR_FORMAT);
    f->cluster_count = (total - overhead) / spc;
    if (!f->cluster_count || f->cluster_count > 0x0fffffeeu ||
        f->cluster_count + 2 > fatsz * 128u)
        return fail(f, FAT32_ERR_FORMAT);
    uint32_t active = (le16(b + 40) & 0x80) ? (b[40] & 15) : 0;
    if (active >= fats) return fail(f, FAT32_ERR_FORMAT);
    f->fat_begin = part + reserved + active * fatsz;
    f->data_begin = part + overhead;
    f->sectors_per_cluster = spc;
    if (!valid_cluster(f, root)) return fail(f, FAT32_ERR_CHAIN);
    chain_start(f, root);
    for (;;) {
        for (uint32_t s = 0; s < spc; s++) {
            uint32_t lba = f->data_begin + (f->current_cluster - 2) * spc + s;
            if (sector(f, lba)) return f->error;
            for (unsigned off = 0; off < 512; off += 32) {
                const uint8_t *e = f->sector_buf + off;
                if (!e[0]) return fail(f, FAT32_ERR_NOT_FOUND);
                if (e[0] == 0xe5 || (e[11] & 0x18) || e[11] == 0x0f) continue;
                unsigned i = 0;
                while (i < 11 && wanted[i] == e[i]) i++;
                if (i != 11) continue;
                f->file_size = le32(e + 28);
                f->first_cluster = (le16(e + 20) << 16) | le16(e + 26);
                if (f->file_size && !valid_cluster(f, f->first_cluster))
                    return fail(f, FAT32_ERR_CHAIN);
                chain_start(f, f->first_cluster);
                f->opened = 1;
                return 0;
            }
        }
        int rc = next_cluster(f);
        if (rc) return rc < 0 ? rc : fail(f, FAT32_ERR_NOT_FOUND);
    }
}
int fat32_stream_read(fat32_file_t *f, void *dst, uint32_t count, uint32_t *actual) {
    if (!actual) return FAT32_ERR_STATE;
    *actual = 0;
    if (!f || !f->opened) return FAT32_ERR_STATE;
    if (f->error) return f->error;
    uint32_t remaining = f->file_size - f->file_pos;
    if (count > remaining) count = remaining;
    uint8_t *out = dst;
    while (*actual < count) {
        if (f->sector_offset == 512) {
            f->sector_offset = 0;
            if (++f->sector_in_cluster == f->sectors_per_cluster) {
                int rc = next_cluster(f);
                if (rc) return rc < 0 ? rc : fail(f, FAT32_ERR_CHAIN);
            }
        }
        if (!valid_cluster(f, f->current_cluster)) return fail(f, FAT32_ERR_CHAIN);
        uint32_t lba = f->data_begin + (f->current_cluster - 2) * f->sectors_per_cluster
                       + f->sector_in_cluster;
        /* Skip also reads: SD errors cannot be hidden by a JPEG APP skip. */
        if (sector(f, lba)) return f->error;
        uint32_t n = 512 - f->sector_offset;
        if (n > count - *actual) n = count - *actual;
        if (out) for (uint32_t i = 0; i < n; i++) out[*actual + i] = f->sector_buf[f->sector_offset + i];
        f->sector_offset += n; f->file_pos += n; *actual += n;
    }
    return 0;
}
int fat32_skip(fat32_file_t *f, uint32_t count, uint32_t *actual) {
    return fat32_stream_read(f, 0, count, actual);
}
