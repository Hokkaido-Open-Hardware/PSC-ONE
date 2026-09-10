#!/usr/bin/env python3
"""Host tests for the actual FAT32 stream/TJpgDec/adapter. No board required.
Requires Pillow and a host C compiler. Products and SD-ready JPEGs stay in build.
"""
from pathlib import Path
import argparse
import os
import subprocess
from PIL import Image, ImageDraw, ImageChops, ImageStat

OS = Path(__file__).resolve().parents[2]
p = argparse.ArgumentParser()
p.add_argument('--build', type=Path, default=OS / 'build/jpeg_tests')
a = p.parse_args()
build = a.build.resolve()
build.mkdir(parents=True, exist_ok=True)
inc = build / 'tjpgd'
inc.mkdir(exist_ok=True)
for name, target in [('tjpgd.c', OS / 'third_party/tjpgd/src/tjpgd.c'),
                     ('tjpgd.h', OS / 'third_party/tjpgd/src/tjpgd.h'),
                     ('tjpgdcnf.h', OS / 'src/jpeg/tjpgdcnf.h')]:
    link = inc / name
    if not link.exists(): link.symlink_to(os.path.relpath(target, inc))
cc = os.environ.get('CC', 'gcc')
flags = ['-std=c11', '-O1', '-g', '-fno-builtin', '-fsanitize=address',
         '-fno-omit-frame-pointer', '-fno-pie', '-I' + str(OS / 'src'), '-I' + str(inc)]
objects = []
for src in [OS / 'src/fat32_stream.c', *[OS / ('src/jpeg/' + n) for n in
             ['jpeg_view.c', 'jpeg_headers.c', 'tjpgd_port.c']], inc / 'tjpgd.c', Path(__file__).with_name('host.c')]:
    obj = build / (src.stem + '.o')
    rename = [] if src.name == 'host.c' else ['-Dprintf=psc_printf', '-Dputchar=psc_putchar', '-Dexit=psc_exit']
    subprocess.run([cc, *flags, *rename, '-c', str(src), '-o', str(obj)], check=True)
    objects.append(str(obj))
exe = build / 'jpeg_host'
subprocess.run([cc, '-fsanitize=address', '-no-pie', *objects, '-o', str(exe)], check=True)

def run(path, expected=0, mode=None):
    args = [str(exe), str(path), str(expected)] + ([mode] if mode else [])
    r = subprocess.run(args, cwd=build, text=True, capture_output=True, timeout=20)
    if r.returncode:
        raise RuntimeError(f'{path.name}: {r.stdout}\n{r.stderr}')
    print(path.name, mode or '', r.stdout.strip())

for w, h in [(64,64), (128,128), (320,240), (480,320), (240,320), (17,19), (1,1)]:
    im = Image.new('RGB', (w,h))
    for y in range(h):
        for x in range(w): im.putpixel((x,y), (x * 255 // max(1,w-1), y * 255 // max(1,h-1), (x+y) * 255 // max(1,w+h-2)))
    for sampling in [0,1,2]:
        path = build / f'{w}X{h}{sampling}.JPG'
        im.save(path, quality=90, subsampling=sampling)
        run(path)
        got = Image.frombytes('RGB', (w,h), (build / 'decoded.rgb').read_bytes())
        ref = Image.open(path).convert('RGB')
        error = ImageStat.Stat(ImageChops.difference(got, ref)).mean
        assert max(error) < 12, (path, error)
    path = build / f'GRAY{w}.JPG'
    im.convert('L').save(path, quality=90)
    run(path)

base = build / '320X2402.JPG'
run(base, mode='stream')
restart = build / 'RESTART.JPG'
Image.open(base).save(restart, quality=90, subsampling=2, restart_marker_blocks=4)
assert b'\xff\xdd' in restart.read_bytes(), 'Pillow restart marker support required'
run(restart)
run(base, -4, 'sd')
run(base, -104, 'lcd1')
run(base, -104, 'lcd2')
run(base, -104, 'lcdmid')
run(base, -4, 'sdmid')
run(base, 0, 'retry')
data = base.read_bytes()
for name, content, expected in [('BROKEN.JPG', b'not a jpeg', 1),
        ('NOEOI.JPG', data[:-2], -103), ('TRUNC.JPG', data[:len(data)//2], 1),
        ('SOI.JPG', data[:2], -103)]:
    path = build / name; path.write_bytes(content); run(path, expected)
for name, size, options, expected in [('PROGRESS.JPG',(64,64),{'progressive':True},-101),
        ('LARGE.JPG',(481,320),{},-102), ('TALL.JPG',(480,321),{},-102),
        ('PORTRAIT.JPG',(320,480),{},-102),
        ('CMYK.JPG',(64,64),{'mode':'CMYK'},-101)]:
    path = build / name
    Image.new(options.pop('mode','RGB'),size).save(path,**options)
    run(path, expected)
# Invalid precision, malformed segment lengths and table payloads.
sof = data.index(b'\xff\xc0'); dht = data.index(b'\xff\xc4'); dqt = data.index(b'\xff\xdb')
for name, off, value in [('12BIT.JPG',sof+4,12), ('BADDHT.JPG',dht+5,255),
                         ('BADQT.JPG',dqt+5,0), ('BADLEN.JPG',sof+3,3)]:
    broken = bytearray(data); broken[off] = value
    path = build / name; path.write_bytes(broken); run(path, 1)
# Large APP segments exercise NULL-buffer forward skip across sectors/clusters.
path = build / 'APPSKIP.JPG'
path.write_bytes(data[:2] + b'\xff\xe1\x10\x02' + bytes(4096) + data[2:])
run(path)
# SD-ready orientation/colour target: rows red, green, blue, white, black.
colors = Image.new('RGB', (480,320))
draw = ImageDraw.Draw(colors)
for i, color in enumerate(['red','lime','blue','white','black']):
    draw.rectangle((0,i*64,479,i*64+63), fill=color)
for label, xy, anchor in [('TOP LEFT',(4,4),'lt'), ('TOP RIGHT',(475,4),'rt'),
                           ('BOTTOM LEFT',(4,315),'lb'), ('BOTTOM RIGHT',(475,315),'rb')]:
    draw.text(xy,label,fill='white',anchor=anchor)
draw.rectangle((0,0,479,319),outline='yellow',width=2)
draw.line((180,150,300,150),fill='yellow',width=3)
draw.polygon([(300,150),(285,140),(285,160)],fill='yellow')
draw.text((210,165),'RIGHT ->',fill='yellow')
colors.save(build / 'COLORS.JPG',quality=95,subsampling=0)
run(build / 'COLORS.JPG')
print('JPEG host tests PASS (including pixel comparison and AddressSanitizer)')
print('Artifacts:', build)
