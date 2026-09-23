#!/usr/bin/env python3
"""Build in /tmp and run the unchanged full PSC-ONE CPU v1 + Synap RTL."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import xml.etree.ElementTree as ET

sys.dont_write_bytecode = True
from run_host import HERE, VENDOR, OS


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--build', required=True, type=Path)
    p.add_argument('--model', required=True, type=Path)
    p.add_argument('--build-only', action='store_true')
    p.add_argument('--disable-pulp', action='store_true')
    a = p.parse_args()
    build = a.build.resolve();build.mkdir(parents=True, exist_ok=True)
    os.environ['CCACHE_DIR']=str(build/'ccache')
    dst = OS / 'src/tflite'
    model = a.model.read_bytes()
    (build / 'model_bytes.h').write_text('alignas(16) static const unsigned char model_bytes[]={' +
                                        ','.join(str(x) for x in model) + '};\n')
    sim = OS.parents[1] / 'hardware/sim'
    arch = ['--target=riscv64-unknown-elf', '-march=rv32im_zicsr_zifencei', '-mabi=ilp32',
            '-mno-relax', '-mstrict-align']
    flags = [*arch, '-Os', '-g', '-fno-builtin', '-fno-stack-protector',
             '-ffunction-sections', '-fdata-sections', '-DNDEBUG']
    includes = []
    for path in (dst, OS / 'src/tflite', VENDOR, VENDOR / 'flatbuffers/include',
                 VENDOR / 'gemmlowp', build):
        includes += ['-I' + str(path)]
    version = subprocess.check_output(['riscv64-unknown-elf-gcc', '-dumpversion'], text=True).strip()
    cxxroot = Path('/usr/include/newlib/c++') / version
    for path in (cxxroot, cxxroot / 'riscv64-unknown-elf/rv32im/ilp32',
                 Path('/usr/lib/picolibc/riscv64-unknown-elf/include')):
        includes += ['-isystem', str(path)]
    objects = []
    for src in [dst / 'tflite_runtime.cc', HERE / 'target_test.cc'] + [OS / 'src/tflite' / name for name in
                 ('tflite_inspect.cc', 'tflite_quant.cc', 'tflite_synap.cc')]:
        obj = build / (src.stem + '.o')
        subprocess.run(['clang++', *flags, *includes, '-std=c++17', '-fno-exceptions', '-fno-rtti',
                        '-fno-threadsafe-statics', '-DTFLITE_SINGLE_ROUNDING=0',
                        '-DFLATBUFFERS_LOCALE_INDEPENDENT=0', f'-DPSC_HAS_CV_DOTSP_B={int(not a.disable_pulp)}',
                        '-include', str(dst / 'tflite_api.h'), '-c', str(src), '-o', str(obj)], check=True)
        objects.append(str(obj))
    for src in (OS / 'src/synap_api.c', sim / 'cpp/sp_start.S'):
        obj = build / (src.stem + '.o')
        subprocess.run(['clang', *flags, '-c', str(src), '-o', str(obj)], check=True)
        objects.append(str(obj))
    libgcc = subprocess.check_output(['riscv64-unknown-elf-gcc', '-march=rv32im', '-mabi=ilp32',
                                      '-print-libgcc-file-name'], text=True).strip()
    lib = Path('/usr/lib/picolibc/riscv64-unknown-elf/lib/rv32i/ilp32')
    elf = build / 'pulp_fc.elf'
    # Full schema/inspector exceeds the tiny C++ test's 64 KiB layout. Use
    # 128 KiB of existing SDRAM; the testbench preloads beyond the boot ROM.
    linker=build/'target.ld'
    layout=(sim/'cpp/link.ld').read_text().replace('LENGTH = 64K','LENGTH = 128K')
    layout=layout.replace('__bss_end = .;', '. = ALIGN(4); __bss_end = .;')
    linker.write_text(layout)
    objects=[objects[-1]]+objects[:-1]  # reset PC 0 must execute _start
    subprocess.run(['clang', *arch, '-nostdlib', '-fuse-ld=lld',
                    '-Wl,--gc-sections,--no-relax,-T,' + str(linker),
                    '-Wl,-Map,' + str(build / 'pulp_fc.map'), *objects,
                    '-Wl,--start-group', str(lib / 'libm.a'), str(lib / 'libc.a'), libgcc,
                    '-Wl,--end-group', '-o', str(elf)], check=True)
    dis = subprocess.check_output(['riscv64-unknown-elf-objdump', '-d', '-C', str(elf)], text=True)
    (build / 'pulp_fc.disasm').write_text(dis)
    functions = {}; name = None
    for line in dis.splitlines():
        m = re.match(r'^[0-9a-f]+ <(.+)>:', line)
        if m: name=m[1];functions[name]=[]
        m = re.match(r'\s*[0-9a-f]+:\s+([0-9a-f]{8})\s', line)
        if m and name: functions[name].append(int(m[1],16))
    count = lambda values, code: sum((v & 0xfe00707f)==code for v in values)
    assert bool(count(functions['audit_pulp'],0x9000107b))==bool(not a.disable_pulp)
    assert count(functions['audit_scalar'],0x9000107b)==0
    assert not any(count(v,0xa800107b) for v in functions.values())
    assert any(count(v,0x9000107b) for k,v in functions.items() if 'invoke(' in k)==bool(not a.disable_pulp)
    if a.disable_pulp:assert not any(count(v,0x9000107b) for v in functions.values())
    symbols = subprocess.check_output(['riscv64-unknown-elf-nm', '-C', str(elf)], text=True)
    assert not re.search(r'\b(malloc|calloc|realloc|operator new(?:\[\])?\(.*)\s*$', symbols, re.M), 'unexpected allocator linked'
    (build / 'encoding.json').write_text(json.dumps({k:count(v,0x9000107b) for k,v in functions.items()
                                                   if count(v,0x9000107b) or k=='audit_scalar'},indent=2)+'\n')
    subprocess.run(['riscv64-unknown-elf-objcopy', '-O', 'binary', str(elf), str(build / 'pulp_fc.bin')],check=True)
    data = (build / 'pulp_fc.bin').read_bytes()
    assert len(data)<128*1024-8192
    mem = build / 'sim/mem';mem.mkdir(parents=True, exist_ok=True)
    (mem / 'test_program.mem').write_text(''.join(f'{int.from_bytes(data[i:i+4],"little"):08x}\n'
                                                for i in range(0,16384,4)))
    print('PASS: RV32 ELF encoding and no allocator symbols; firmware bytes=',len(data),flush=True)
    if a.build_only:return
    from cocotb_tools.runner import get_runner
    mk = build / 'sources.mk'
    mk.write_text(f'include {sim}/Makefile.cpu\n' +
                  'pulp_sources:\n\t@echo $(abspath $(INPUT_FILE_PSCONE))\n')
    env=dict(os.environ, PATH=str(Path(sys.executable).parent)+':'+os.environ['PATH'])
    sources=subprocess.check_output(['make','--no-print-directory','-s','-f',str(mk),
                                      'CPU_VERSION=v1','NPU_VERSION=legacy','SIM_FAST=1','pulp_sources'],
                                     cwd=sim,env=env,text=True).split()
    runner=get_runner('verilator')
    runner.build(sources=sources,hdl_toplevel='PSC_ONE_Chip_sim',build_dir=build/'verilator',
                 build_args=['-O3','-CFLAGS','-O3','--bbox-sys','--x-assign','fast','--x-initial','fast',
                             '-Wno-fatal','-DTOP_SIM'],always=False,waves=False,log_file=build/'compile.log')
    run=build/'run';(run/'wave').mkdir(parents=True,exist_ok=True)
    runner.test(hdl_toplevel='PSC_ONE_Chip_sim',test_module='target_cocotb',test_dir=run,
                extra_env={'PYTHONPATH':str(HERE),'PYTHONDONTWRITEBYTECODE':'1','PSC_PULP_BUILD':str(build)},
                results_xml=str(build/'results.xml'),log_file=build/'simulation.log')
    root=ET.parse(build/'results.xml')
    assert len(root.findall('.//testcase'))==1 and not any(root.findall('.//'+x) for x in ('failure','error','skipped'))
    print('PASS: unchanged CPU v1 / legacy Synap RTL; results:',build/'timing.json')


if __name__=='__main__':main()
