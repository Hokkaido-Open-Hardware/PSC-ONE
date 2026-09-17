#!/usr/bin/env python3
"""Cross-link inspector without libstdc++ on RV32I and audit firmware RAM.
The optional baseline is a pre-change PSC-OS build. Never invokes clean.
"""
import argparse
import json
from pathlib import Path
import subprocess

os_dir = Path(__file__).resolve().parents[2]
p = argparse.ArgumentParser()
p.add_argument('--build', type=Path, required=True)
p.add_argument('--firmware', type=Path, required=True)
p.add_argument('--baseline', type=Path)
a = p.parse_args()
build = a.build.resolve(); build.mkdir(parents=True, exist_ok=True)
firmware = a.firmware.resolve()
subprocess.run(['make', 'MODE=psc', f'Build={firmware}', 'kernel_mem'], cwd=os_dir, check=True)

def symbols(path):
    result = {}
    for line in subprocess.check_output(['llvm-nm', str(path)], text=True).splitlines():
        parts = line.split()
        if len(parts) == 3:
            result[parts[2]] = int(parts[0], 16)
    return result

def size(path):
    values = subprocess.check_output(['llvm-size', str(path)], text=True).splitlines()[1].split()
    return dict(zip(['text_rodata', 'data', 'bss'], map(int, values[:3])))

kernel = symbols(firmware / 'kernel.elf')
shell = symbols(firmware / 'shell.elf')
image_size = (firmware / 'shell.bin').stat().st_size
image_pages = (image_size + 4095) & ~4095
pool = kernel['__free_ram_end'] - kernel['__free_ram']
remaining = pool - image_pages - 128*1024 - 8*4096
assert remaining >= 0, 'shell copy + stack + page tables exceed kernel pool'
assert shell['__user_stack_top'] <= shell['USER_MAX']
undefined = subprocess.check_output(['llvm-nm', '-u', str(firmware / 'tflite_inspect.o')], text=True)
assert {s.split()[-1] for s in undefined.splitlines()} <= {'memcpy', 'memset', 'memcmp', 'strncmp'}
assert not subprocess.check_output(['llvm-nm', '-u', str(firmware / 'shell.elf')], text=True).strip()

# Compile/link just the C++ reader as RV32I. Compiler helpers are allowed here,
# but never libstdc++, malloc, exceptions or FPU instructions.
rv = build / 'rv32i'; obj = rv / 'tflite_inspect.o'
subprocess.run(['make', f'Build={rv}',
                'ARCH=-march=rv32i_zicsr_zifencei -mabi=ilp32 -mno-relax', str(obj)],
               cwd=os_dir, check=True)
libgcc = subprocess.check_output(['riscv64-unknown-elf-gcc', '-march=rv32i',
                                 '-mabi=ilp32', '-print-libgcc-file-name'], text=True).strip()
exe = rv / 'reader_link.elf'
subprocess.run(['clang', '--target=riscv64-unknown-elf', '-march=rv32i_zicsr_zifencei',
                '-mabi=ilp32', '-nostdlib', '-Wl,-e,psc_tflite_inspect',
                str(obj), '/usr/lib/picolibc/riscv64-unknown-elf/lib/rv32i/ilp32/libc.a',
                libgcc, '-o', str(exe)], check=True)
assert not subprocess.check_output(['llvm-nm', '-u', str(exe)], text=True).strip()
names = symbols(exe)
assert not any(n.startswith(('_Zn', '__cxa', '__gxx')) or n in ('malloc', 'calloc', 'realloc', 'free') for n in names)
result = {'shell': size(firmware / 'shell.elf'), 'kernel': size(firmware / 'kernel.elf'),
          'shell_image_bytes': image_size, 'shell_copy_page_bytes': image_pages,
          'page_pool_bytes': pool, 'remaining_after_stack_page_table_budget': remaining,
          'rv32im_inspector_undefined': undefined.splitlines(), 'rv32i_link': 'PASS'}
if a.baseline:
    before = size(a.baseline / 'shell.elf')
    result['baseline_shell'] = before
    result['shell_delta'] = {k: result['shell'][k] - before[k] for k in before}
(build / 'memory.json').write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps(result, indent=2))
print('PASS: RV32I/RV32IM C++ link, no C++ runtime/heap, user and physical page budgets')
