#!/usr/bin/env python3
"""Offline deterministic model + official TFLM oracle + Phase 3 sanitizer tests.
No TensorFlow installation needed. Uses the pinned upstream schema builder and
reference_integer_ops::FullyConnected. Generated tracing copy changes only the
namespace/header guard and adds an observer; original kernel also runs.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys

os_dir = Path(__file__).resolve().parents[2]
p = argparse.ArgumentParser()
p.add_argument('--build', type=Path, default=os_dir / 'build/tflite_phase3')
p.add_argument('--update-golden', action='store_true', help='explicitly refresh source demo header')
a = p.parse_args()
build = a.build.resolve(); build.mkdir(parents=True, exist_ok=True)
v = os_dir / 'third_party/tflite'
subprocess.run([sys.executable, str(Path(__file__).with_name('check_vendor.py'))], check=True)
source = v / 'tensorflow/lite/kernels/internal/reference/integer_ops/fully_connected.h'
text = source.read_text()
needle = ('      int32_t acc_scaled =\n'
          '          MultiplyByQuantizedMultiplier(acc, output_multiplier, output_shift);\n'
          '      acc_scaled += output_offset;')
assert text.count(needle) == 1
text = text.replace(needle, needle + '\n      reference_capture(out_c, acc, acc_scaled);')
text = text.replace('TENSORFLOW_LITE_KERNELS_INTERNAL_REFERENCE_INTEGER_OPS_FULLY_CONNECTED_H_', 'PSC_HOST_REFERENCE_TRACED_H_')
text = text.replace('namespace reference_integer_ops', 'namespace reference_traced')
(build / 'reference_traced.h').write_text(text)
flags = ['-std=c++17', '-O1', '-g', '-fno-omit-frame-pointer', '-fno-pie',
         '-fsanitize=address,undefined', '-fno-sanitize-recover=all',
         '-DTFLITE_SINGLE_ROUNDING=0']
for path in [os_dir / 'src/tflite', v, v / 'flatbuffers/include', v / 'gemmlowp', build]:
    flags.append('-I' + str(path))
objects = []
for name in ['src/tflite/tflite_inspect.cc', 'src/tflite/tflite_runtime.cc',
             'src/tflite/tflite_quant.cc', 'src/tflite/tflite_synap.cc',
             'tests/tflite/synap_mock.cc', 'tests/tflite/phase3.cc']:
    src = os_dir / name; obj = build / (src.stem + '.o')
    subprocess.run([os.environ.get('CXX', 'g++'), *flags, '-c', str(src), '-o', str(obj)], check=True)
    objects.append(str(obj))
exe = build / 'phase3'
subprocess.run([os.environ.get('CXX', 'g++'), '-fsanitize=address,undefined', '-no-pie', *objects, '-o', str(exe)], check=True)
env = dict(os.environ, ASAN_OPTIONS='detect_leaks=1:halt_on_error=1', UBSAN_OPTIONS='halt_on_error=1')
subprocess.run([str(exe), str(build)], check=True, env=env, timeout=60)
golden = os_dir / 'src/tflite/tflite_demo.h'
generated = (build / 'tflite_demo.h').read_bytes()
if a.update_golden:
    golden.write_bytes(generated)
elif not golden.exists() or golden.read_bytes() != generated:
    raise SystemExit('Demo oracle changed: inspect reference.csv before explicit --update-golden')
manifest = {name: hashlib.sha256((build / name).read_bytes()).hexdigest()
            for name in ['MODEL.TFL', 'reference.csv', 'tflite_demo.h']}
(build / 'generated_sha256.json').write_text(json.dumps(manifest, indent=2) + '\n')
print('PASS: reproducible model and source golden header; artifacts:', build)

# Same objects and official reference oracle; exercise the real tile adapter
# with a full square signed-matmul mock instead of hardware.
obj=build/'phase4.o'
subprocess.run([os.environ.get('CXX','g++'),*flags,'-c',str(os_dir/'tests/tflite/phase4.cc'),'-o',str(obj)],check=True)
exe4=build/'phase4'
subprocess.run([os.environ.get('CXX','g++'),'-fsanitize=address,undefined','-no-pie',
               *[o for o in objects if Path(o).name!='phase3.o'],str(obj),'-o',str(exe4)],check=True)
subprocess.run([str(exe4)],check=True,env=env,timeout=60)
