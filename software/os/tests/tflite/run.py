#!/usr/bin/env python3
"""Build the real inspector + FAT32 reader with ASan/UBSan and official fixtures.
No TensorFlow/Python packages, network, board or existing build cleanup required.
"""
import argparse
import os
from pathlib import Path
import subprocess
import sys

os_dir = Path(__file__).resolve().parents[2]
subprocess.run([sys.executable, str(Path(__file__).with_name('check_vendor.py'))], check=True)
p = argparse.ArgumentParser()
p.add_argument('--build', type=Path, default=os_dir / 'build/tflite_tests')
a = p.parse_args()
build = a.build.resolve()
build.mkdir(parents=True, exist_ok=True)
vendor = os_dir / 'third_party/tflite'
flags = ['-O1', '-g', '-fno-omit-frame-pointer', '-fno-pie',
         '-fsanitize=address,undefined', '-fno-sanitize-recover=all',
         '-I' + str(os_dir / 'src/tflite'), '-I' + str(vendor),
         '-I' + str(vendor / 'flatbuffers/include'),
         '-I' + str(vendor / 'gemmlowp'), '-DTFLITE_SINGLE_ROUNDING=0']
objects = []
cxx = os.environ.get('CXX', 'g++')
cc = os.environ.get('CC', 'gcc')
for name in ['src/fat32_stream.c', 'src/tflite/tflite_file.c',
             'src/tflite/tflite_inspect.cc', 'src/tflite/tflite_runtime.cc',
             'src/tflite/tflite_quant.cc', 'src/tflite/tflite_synap.cc',
             'tests/tflite/synap_mock.cc', 'tests/tflite/host.cc']:
    src = os_dir / name
    obj = build / (src.stem + '.o')
    cpp = src.suffix == '.cc'
    extra = [] if cpp else ['-fno-builtin', '-Dprintf=psc_printf',
                           '-Dputchar=psc_putchar', '-Dexit=psc_exit']
    subprocess.run([cxx if cpp else cc, '-std=c++17' if cpp else '-std=c11',
                    *flags, *extra, '-c', str(src), '-o', str(obj)], check=True)
    objects.append(str(obj))
exe = build / 'tflite_host'
subprocess.run([cxx, '-fsanitize=address,undefined', '-no-pie',
                *objects, '-o', str(exe)], check=True)
subprocess.run([str(exe), str(build)], check=True, timeout=60)
print('Artifacts:', build)

subprocess.run([sys.executable, str(Path(__file__).with_name('generate_model.py')),
                '--build', str(build / 'phase3')], check=True)
subprocess.run([sys.executable, str(Path(__file__).with_name('driver_test.py')),
                '--build', str(build / 'driver')], check=True)
