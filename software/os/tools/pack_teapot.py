#!/usr/bin/env python3
"""Project the bundled, Y-up Utah teapot OBJ and pack its visible-facing edges."""
import argparse
from math import cos, radians, sin
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


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('obj', type=Path)
    parser.add_argument('header', type=Path)
    args = parser.parse_args()
    points, edges = project_mesh(*read_mesh(args.obj))
    with args.header.open('w') as out:
        out.write('/* Generated from teapot.obj by pack_teapot.py. */\n')
        for name, values, cols in [('points',points,3), ('edges',edges,2)]:
            out.write(f'static const uint16_t {name}[][{cols}] = {{\n')
            for item in values:
                out.write('    {' + ','.join(map(str,item)) + '},\n')
            out.write('};\n')
    print(f'Utah teapot: packed {len(points)} vertices, {len(edges)} edges')


if __name__ == '__main__':
    main()
