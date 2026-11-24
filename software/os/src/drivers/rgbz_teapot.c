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
