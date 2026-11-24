#include <stdint.h>
#include "teapot_mesh.h"

/* Rasterize each projected OBJ edge, retaining the nearest sample where lines cross. */
void rgbz_draw_teapot(uint16_t *rgb, uint16_t *depth)
{
    for (unsigned i = 0; i < 640 * 360; i++) {
        rgb[i] = 0;
        depth[i] = 0;
    }
    for (unsigned i = 0; i < sizeof(edges) / sizeof(edges[0]); i++) {
        const uint16_t *a = points[edges[i][0]], *b = points[edges[i][1]];
        int x = a[0], y = a[1], z = a[2];
        int sx = b[0] >= x ? 1 : -1, sy = b[1] >= y ? 1 : -1;
        int dx = sx * (b[0] - x), dy = sy * (b[1] - y);
        int steps = dx > dy ? dx : dy;
        int dz = (int)b[2] - z;
        int zstep = steps ? dz / steps : 0;
        int fraction = dz - zstep * steps;
        int zsign = fraction < 0 ? -1 : 1;
        int zerror = steps / 2, error = dx - dy;
        if (!steps && b[2] < z) z = b[2];
        for (;;) {
            unsigned pos = (unsigned)y * 640 + (unsigned)x;
            if (depth[pos] == 0 || z < depth[pos]) {
                depth[pos] = (uint16_t)z;
                rgb[pos] = z < 1900 ? 0xffff : z < 2350 ? 0x57ff : 0x0555;
            }
            if (x == b[0] && y == b[1]) break;
            int twice = 2 * error;
            if (twice > -dy) { error -= dy; x += sx; }
            if (twice <  dx) { error += dx; y += sy; }
            z += zstep;
            zerror += fraction * zsign;
            if (zerror >= steps) { zerror -= steps; z += zsign; }
        }
    }
}

enum { WIDTH = 640, HEIGHT = 360, GROUPS = WIDTH / 8 };
typedef struct { uint16_t x, y, z, key; } point_t;

static void moving_edge(uint8_t *input, const point_t *a, const point_t *b)
{
    /* Match the still renderer's tie-breaking at half-pixel boundaries. */
    if (a->x > b->x || (a->x == b->x && a->y > b->y)) {
        const point_t *temp = a; a = b; b = temp;
    }
    int dx = b->x - a->x, dy = (int)b->y - a->y;
    int ystep = dy < 0 ? -WIDTH : WIDTH;
    if (dy < 0) dy = -dy;
    int steps = dx >= dy ? dx : dy, minor = dx >= dy ? dy : dx;
    int major_step = dx >= dy ? 1 : ystep, minor_step = dx >= dy ? ystep : 1;
    uint8_t *pixel = input + a->y * WIDTH + a->x;
    unsigned key = a->key;
    if (key == b->key && steps < 32) {
        uint32_t mask = line_masks[steps * (steps + 1) / 2 + minor];
        for (;;) {
            if (*pixel < key) *pixel = key;
            if (mask == 1) break;
            pixel += major_step + (mask & 1 ? minor_step : 0);
            mask >>= 1;
        }
        return;
    }
    int z = a->z, dz = (int)b->z - z;
    int step = steps ? dz / steps : 0;
    int remainder = dz - step * steps;
    int sign = remainder < 0 ? -1 : 1;
    if (remainder < 0) remainder = -remainder;
    int fraction = steps / 2, error = (steps - 1) / 2;
    if (!steps && b->z < z) z = b->z;
    for (int i = 0;; ++i) {
        key = depth_key[z];
        if (*pixel < key) *pixel = key;
        if (i == steps) break;
        pixel += major_step;
        error += minor;
        if (error >= steps) { error -= steps; pixel += minor_step; }
        z += step;
        fraction += remainder;
        if (fraction >= steps) { fraction -= steps; z += sign; }
    }
}

static int round_ratio(int numerator, int denominator)
{
    return (numerator + (numerator < 0 ? -denominator / 2 : denominator / 2)) / denominator;
}

static void draw_view(uint8_t *input, point_t *projected, unsigned angle)
{
    if (angle == 0) {
        /* Use the exact rounded OBJ projection used by the still command. */
        for (unsigned i = 0; i < sizeof(points) / sizeof(points[0]); ++i) {
            const uint16_t *p = points[i];
            projected[i] = (point_t){p[0], p[1], p[2], depth_key[p[2]]};
        }
        for (unsigned i = 0; i < sizeof(edges) / sizeof(edges[0]); ++i)
            moving_edge(input, &projected[edges[i][0]], &projected[edges[i][1]]);
        return;
    }
    const int sy = views[angle][0], cy = views[angle][1], distance = views[angle][2];
    unsigned visible_sector = 1u << (angle / 30);
    for (unsigned i = 0; i < sizeof(model) / sizeof(model[0]); ++i) {
        if (!(group_sectors[i / 8] & visible_sector)) continue;
        int x = model[i][0], y = model[i][1], z = model[i][2];
        int side = (x * cy - z * sy + 8192) >> 14;
        int towards = (x * sy + z * cy + 8192) >> 14;
        int up = (15964 * y - 3686 * towards + 8192) >> 14;
        int near = (15964 * towards + 3686 * y + 8192) >> 14;
        int depth = distance - near;
        int z_mm = (500 * depth + 2048) >> 12;
        projected[i] = (point_t){330 + round_ratio(320 * side, depth),
                                 180 - round_ratio(320 * up, depth),
                                 z_mm, depth_key[z_mm]};
    }
    const uint32_t *span = edge_spans;
    for (unsigned a = 0; a < sizeof(model) / sizeof(model[0]); ++a) {
        for (unsigned n = span_counts[a]; n; --n) {
            uint32_t entry = *span++;
            int offset = (int)angle - (int)((entry >> 9) & 511);
            if (offset < 0) offset += 360;
            if ((unsigned)offset <= (entry & 511))
                moving_edge(input, &projected[a], &projected[entry >> 18]);
        }
    }
}

/* Each input depth key contains the RGBZ disparity and the ordered shade.
 * Both increase monotonically as depth decreases, so keeping the largest key
 * gives exactly the colour and shift of the nearest input sample. */
static void project_row(uint32_t *packed, uint32_t *input, unsigned begin, unsigned end)
{
    for (unsigned x = begin; x < end; x += 4) {
        uint32_t keys = input[x / 4];
        if (!keys) continue;
        input[x / 4] = 0;
        for (int i = 0; i < 4; ++i, keys >>= 8) {
            unsigned key = keys & 255;
            if (!key) continue;
            int u = (int)x + i - (int)(key >> 3);
            if (u >= 0) packed[u / 8] |= ((key & 7) * 2u + 1u) << ((u & 7) * 4);
        }
    }
}

void rgbz_draw_teapot_frame(uint32_t *vram, uint32_t *previous, uint32_t *input,
                            unsigned angle, int first)
{
    /* The RGB and Z planes are idle during software scan conversion. Use the
     * first for the previous packed frame, the second for keys and vertices. */
    enum { KEY_WORDS = WIDTH * HEIGHT / 4 };
    _Static_assert(KEY_WORDS * 4 + sizeof(model)/sizeof(model[0]) * sizeof(point_t)
                   <= WIDTH * HEIGHT * 2, "animation workspace exceeds Z plane");
    if (first) {
        for (unsigned i = 0; i < KEY_WORDS; ++i) input[i] = 0;
    }
    angle %= 360;
    unsigned sector = angle / 15;
    unsigned old_sector = first ? sector : previous[GROUPS * HEIGHT] % 24;
    previous[GROUPS * HEIGHT] = sector;
    const uint8_t (*current)[2] = scan_bounds + sector * (HEIGHT / 8);
    const uint8_t (*old)[2] = scan_bounds + old_sector * (HEIGHT / 8);
    draw_view((uint8_t *)input, (point_t *)(input + KEY_WORDS), angle);
    uint32_t row[GROUPS] = {0};
    for (unsigned y = 0; y < HEIGHT; ++y) {
        unsigned begin = current[y / 8][0], end = current[y / 8][1];
        project_row(row, input + y * WIDTH / 4, begin * 8, end * 8);
        if (first) { begin = 0; end = GROUPS; }
        else {
            if (old[y / 8][0] < begin) begin = old[y / 8][0];
            if (old[y / 8][1] > end) end = old[y / 8][1];
        }
        for (unsigned g = begin; g < end; ++g) {
            uint32_t shades = row[g];
            row[g] = 0;
            if (!first && shades == previous[g]) continue;
            previous[g] = shades;
            uint32_t a = triple_pair[shades & 255], b = triple_pair[(shades >> 8) & 255];
            uint32_t c = triple_pair[(shades >> 16) & 255], d = triple_pair[shades >> 24];
            for (unsigned line = 0; line < 3; ++line) {
                uint32_t *dst = vram + 3 * (line * GROUPS + g);
                dst[0] = a | (b << 24);
                dst[1] = (b >> 8) | (c << 16);
                dst[2] = (c >> 16) | (d << 8);
            }
        }
        previous += GROUPS;
        vram += 9 * GROUPS;
    }
}
