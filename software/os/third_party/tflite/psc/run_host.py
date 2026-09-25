#!/usr/bin/env python3
"""Host sanitizer/oracle tests against repository runtime sources."""
import argparse
import os
from pathlib import Path
import subprocess
import sys

HERE = Path(__file__).resolve().parent
VENDOR = HERE.parent
OS = VENDOR.parents[1]


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--build', type=Path, required=True)
    a = p.parse_args()
    build = a.build.resolve()
    build.mkdir(parents=True, exist_ok=True)
    subprocess.run([sys.executable, str(OS / 'tests/tflite/generate_model.py'),
                    '--build', str(build / 'baseline')], check=True)
    dst = OS / 'src/api/tflite'
    flags = ['-std=c++17', '-O2', '-g', '-fno-omit-frame-pointer', '-fno-pie',
             '-fsanitize=address,undefined', '-fno-sanitize-recover=all',
             '-DTFLITE_SINGLE_ROUNDING=0', '-include', str(dst / 'tflite_api.h')]
    for path in (dst, OS / 'src/api/tflite', VENDOR, VENDOR / 'flatbuffers/include',
                 VENDOR / 'gemmlowp', OS / 'tests/tflite', build / 'baseline'):
        flags += ['-I' + str(path)]
    cxx = os.environ.get('CXX', 'g++')
    common = []
    for src in [OS / 'src/api/tflite' / name for name in
                ('tflite_inspect.cc', 'tflite_quant.cc', 'tflite_synap.cc')] + [OS / 'tests/tflite/synap_mock.cc']:
        obj = build / (src.stem + '.o')
        subprocess.run([cxx, *flags, '-c', str(src), '-o', str(obj)], check=True)
        common.append(str(obj))
    env = dict(os.environ, ASAN_OPTIONS='detect_leaks=1:halt_on_error=1', UBSAN_OPTIONS='halt_on_error=1')
    for mode in ('disabled', 'emulated'):
        extra = ['-DPSC_PULP_TEST_EMULATE=1'] if mode == 'emulated' else []
        exe = build / mode
        subprocess.run([cxx, *flags, *extra, '-no-pie', str(dst / 'tflite_runtime.cc'),
                        str(HERE / 'host_test.cc'), *common,
                        '-Wl,--wrap=malloc,--wrap=calloc,--wrap=realloc', '-o', str(exe)], check=True)
        result = subprocess.run([str(exe)], check=True, env=env, capture_output=True, text=True)
        (build / (mode + '.log')).write_text(result.stdout + result.stderr)
        print(mode + ': ' + result.stdout, end='')
    print('Artifacts:', build)


if __name__ == '__main__':
    main()
