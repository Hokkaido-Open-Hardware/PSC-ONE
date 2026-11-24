#!/usr/bin/env python3
"""Project the bundled, Y-up Utah teapot OBJ and pack its visible-facing edges."""
import argparse
from math import ceil, cos, radians, sin
from pathlib import Path


def read_mesh(path):
    vertices, faces = [], []
    for line in path.read_text().splitlines():
        fields = line.partition('#')[0].split()
        if fields[:1] == ['v']:
            vertices.append(tuple(map(float, fields[1:4])))
        elif fields[:1] == ['f']:
            faces.append(tuple(int(v.split('/')[0]) - 1 for v in fields[1:]))
    if not vertices or not faces or any(len(f) != 3 or min(f) < 0 or max(f) >= len(vertices)
                                        for f in faces):
        raise ValueError('expected a triangle mesh with positive OBJ vertex indices')
    return vertices, faces


def project_mesh(vertices, faces):
    # Origin at the model centre. Looking slightly down from its +Z side.
    centre = [(min(axis) + max(axis)) / 2 for axis in zip(*vertices)]
    yaw, pitch = radians(12), radians(13)
    camera = []
    for vx, vy, vz in vertices:
        x, y, z = vx-centre[0], vy-centre[1], vz-centre[2]
        side = x*cos(yaw) - z*sin(yaw)
        towards = x*sin(yaw) + z*cos(yaw)
        camera.append((side, y*cos(pitch)-towards*sin(pitch),
                       towards*cos(pitch)+y*sin(pitch)))
    # Fit a 320px focal length to the input and leave margin for the RTL shift.
    distance = max(z + max(abs(x)*320/278, abs(y)*320/155) for x,y,z in camera)
    projected = [(330+320*x/(distance-z), 180-320*y/(distance-z), (distance-z)*500)
                 for x,y,z in camera]
    edges = set()
    for a,b,c in faces:
        x0,y0,_ = projected[a]
        x1,y1,_ = projected[b]
        x2,y2,_ = projected[c]
        if (x1-x0)*(y2-y0) - (y1-y0)*(x2-x0) < 0:  # screen Y grows down
            for i,j in ((a,b), (b,c), (c,a)):
                edges.add(tuple(sorted((i,j))))
    # Merge the OBJ's coincident patch seams after projection and quantization.
    points = sorted({tuple(map(round, projected[i])) for e in edges for i in e})
    index = {p:i for i,p in enumerate(points)}
    if len(points) > 65535 or any(not (0 <= x < 640 and 0 <= y < 360 and 0 < z < 65535)
                                   for x,y,z in points):
        raise ValueError('projected vertices exceed the renderer limits')
    packed = {tuple(sorted(index[tuple(map(round, projected[i]))] for i in e)) for e in edges}
    return points, sorted((a,b) for a,b in packed if a != b)


def visible_runs(mask):
    """Yield (start angle, length), joining runs that cross zero degrees."""
    if not mask:
        return
    if mask == (1 << 360) - 1:
        yield 0, 360
        return
    gap = next(angle for angle in range(360) if not (mask >> angle) & 1)
    length = 0
    for step in range(1, 361):
        angle = (gap + step) % 360
        if (mask >> angle) & 1:
            length += 1
        elif length:
            yield (angle - length) % 360, length
            length = 0


def rotation_mesh(vertices, faces):
    # Weld only coincident patch seams. Keep every triangle for visibility.
    # OBJ patches visit adjacent triangles together. Preserve that locality
    # when walking the visible edges on the CPU.
    unique = list(dict.fromkeys(vertices[i] for face in faces for i in face))
    index = {v: i for i, v in enumerate(unique)}
    faces = [tuple(index[vertices[i]] for i in face) for face in faces]
    centre = [(min(axis) + max(axis)) / 2 for axis in zip(*unique)]
    xyz = [tuple(v - c for v, c in zip(point, centre)) for point in unique]
    model = [tuple(round(v * 4096) for v in point) for point in xyz]
    if len(model) >= 1 << 14 or any(abs(v) >= 32768 for point in model for v in point):
        raise ValueError('rotating mesh exceeds the packed coordinate/index range')
    cp, sp = cos(radians(13)), sin(radians(13))
    visible = [0] * len(faces)
    views = []
    max_depth = 0
    # Conservative horizontal scan limits per eight scanlines over a full turn.
    # Include both the input line and the disparity-shifted output line.
    bands = [[[640, -1] for _ in range(360 // 8)] for _ in range(360 // 15)]
    for angle in range(360):
        sy, cy = sin(radians(12 + angle)), cos(radians(12 + angle))
        camera = []
        for x, y, z in xyz:
            t = x * sy + z * cy
            camera.append((x * cy - z * sy, y * cp - t * sp, t * cp + y * sp))
        if angle == 0:
            original_distance = max(z + max(abs(x)*320/278, abs(y)*320/155)
                                    for x, y, z in camera)
        # Preserve the still's scale. Back off slightly only when necessary
        # to keep the entire spout/lid inside the RGBZ viewport.
        distance = max(original_distance, max(z + max(abs(x)*320/307, abs(y)*320/177)
                                              for x, y, z in camera))
        views.append((round(sy * 16384), round(cy * 16384), round(distance * 4096)))
        depths = [(distance - z) * 500 for _, _, z in camera]
        # Leave room for rounding the Q12 coordinates and Q14 rotations. The
        # five disparity bits represent every depth used by the bundled model.
        if min(depths) < 514:
            raise ValueError('rotating mesh exceeds the 5-bit disparity range')
        max_depth = max(max_depth, max(depths))
        screen = [(x/(distance-z), y/(distance-z)) for x,y,z in camera]
        bounds = [(round(330 + 320 * x), round(180 - 320 * y),
                   (16000 + round((distance-z)*250)) // max(1, round((distance-z)*500)))
                  for (x,y), (_,_,z) in zip(screen,camera)]
        limits = bands[angle // 15]
        for i, (a,b,c) in enumerate(faces):
            x0,y0 = screen[a]
            x1,y1 = screen[b]
            x2,y2 = screen[c]
            if (x1-x0)*(y2-y0) > (y1-y0)*(x2-x0):
                visible[i] |= 1 << angle
                corners = bounds[a], bounds[b], bounds[c]
                xs, ys, shifts = zip(*corners)
                low = max(0, min(xs) - max(shifts) - 2)
                high = min(639, max(xs) + 2)
                for band in range(max(0, min(ys)-2)//8, min(359, max(ys)+2)//8+1):
                    limits[band][0] = min(limits[band][0], low)
                    limits[band][1] = max(limits[band][1], high)

    # An edge is visible whenever either neighbouring face is visible. Store
    # circular runs, grouped by the first vertex (shared across many edges).
    masks = {}
    for (a,b,c), mask in zip(faces, visible):
        for u,v in ((a,b), (b,c), (c,a)):
            edge = min(u,v), max(u,v)
            if u != v:
                masks[edge] = masks.get(edge, 0) | mask
    # Skip projection for entire neighbouring groups of eight vertices hidden
    # throughout the current 30-degree sector.
    group_masks = [0] * ((len(model) + 7) // 8)
    counts = [0] * len(model)
    spans = []
    for (a,b), mask in sorted(masks.items()):
        group_masks[a // 8] |= mask
        group_masks[b // 8] |= mask
        for start, length in visible_runs(mask):
            # High 14 bits: other endpoint. Low nine-bit fields: start and length-1.
            spans.append((b << 18) | (start << 9) | (length - 1))
            counts[a] += 1
    if max(counts) > 255 or max(v[2] for v in views) > 32767:
        raise ValueError('rotating mesh exceeds the packed view limits')
    # Key ordering follows depth, allowing a byte-wise maximum to implement
    # nearest-depth selection without losing any displayed colour or parallax.
    keys = [0]
    for z in range(1, ceil(max_depth) + 5):
        disparity = (16000 + z//2)//z
        shade = 7 if z < 1900 else 5 if z < 2350 else 1
        keys.append(min(disparity, 31)*8 + shade)
    group_sectors = [sum(1 << sector for sector in range(12)
                         if (mask >> (sector * 30)) & ((1 << 30) - 1))
                     for mask in group_masks]
    scan_bounds = [(lo // 8, hi // 8 + 1) for view in bands for lo, hi in view]
    return model, views, counts, spans, keys, group_sectors, scan_bounds


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('obj', type=Path)
    parser.add_argument('header', type=Path)
    args = parser.parse_args()
    vertices, faces = read_mesh(args.obj)
    points, edges = project_mesh(vertices, faces)
    model, views, counts, spans, keys, group_sectors, bands = rotation_mesh(vertices, faces)
    with args.header.open('w') as out:
        out.write('/* Generated from teapot.obj by pack_teapot.py. */\n')
        for name, values, cols, ctype in [('points', points, 3, 'uint16_t'),
                                          ('edges', edges, 2, 'uint16_t'),
                                          ('model', model, 3, 'int16_t'),
                                          ('views', views, 3, 'int16_t'),
                                          ('scan_bounds', bands, 2, 'uint8_t')]:
            out.write(f'static const {ctype} {name}[][{cols}] = {{\n')
            for item in values:
                out.write('    {' + ','.join(map(str,item)) + '},\n')
            out.write('};\n')
        # Steps on the minor axis for short Bresenham lines, with a final
        # sentinel bit. The strip fits in one RV32 shift register.
        line_masks = []
        for major in range(32):
            for minor in range(major + 1):
                error = (major - 1) // 2
                mask = 1 << major
                for step in range(major):
                    error += minor
                    if error >= major:
                        error -= major
                        mask |= 1 << step
                line_masks.append(mask)
        for name, values, ctype in [('line_masks', line_masks, 'uint32_t'),
                                    ('span_counts', counts, 'uint8_t'),
                                    ('group_sectors', group_sectors, 'uint16_t'),
                                    ('triple_pair', [((b & 15) | ((b & 240) << 8))*0x111
                                                     for b in range(256)], 'uint32_t'),
                                    ('edge_spans', spans, 'uint32_t'),
                                    ('depth_key', keys, 'uint8_t')]:
            out.write(f'static const {ctype} {name}[] = {{\n')
            for i in range(0, len(values), 12):
                out.write('    ' + ','.join(map(str,values[i:i+12])) + ',\n')
            out.write('};\n')
    print(f'Utah teapot: {len(faces)} faces, {len(model)} unique model vertices')


if __name__ == '__main__':
    main()
