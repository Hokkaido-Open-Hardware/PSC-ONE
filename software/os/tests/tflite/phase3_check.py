#!/usr/bin/env python3
"""Full RV32I/IM firmware build, standalone runtime link and RAM audit.
All outputs isolated under --build; never invokes clean. Default MicroPython
archive is left untouched: the I-only build uses its own BUILD directory.
"""
import argparse
import json
from pathlib import Path
import re
import subprocess

os_dir = Path(__file__).resolve().parents[2]
p = argparse.ArgumentParser()
p.add_argument('--build', type=Path, required=True)
p.add_argument('--phase2', type=Path, help='optional existing Phase 2 firmware for section deltas')
a = p.parse_args()
build = a.build.resolve(); build.mkdir(parents=True, exist_ok=True)

def run(args, cwd=os_dir): subprocess.run(args, cwd=cwd, check=True)
def output(args): return subprocess.check_output(args, text=True)
def symbols(path):
    return {parts[2]: int(parts[0],16) for line in output(['llvm-nm',str(path)]).splitlines()
            if len(parts := line.split()) == 3}
def sections(path):
    return {parts[0]: int(parts[1]) for line in output(['llvm-size','-A',str(path)]).splitlines()
            if len(parts := line.split()) == 3 and parts[0].startswith('.') and parts[1].isdigit()}
def memory(fw):
    k=symbols(fw/'kernel.elf'); s=symbols(fw/'shell.elf')
    image=(fw/'shell.bin').stat().st_size; pages=(image+4095)&~4095
    pool=k['__free_ram_end']-k['__free_ram']; remaining=pool-pages-128*1024-8*4096
    assert remaining >= 0 and s['__user_stack_top'] <= s['USER_MAX']
    return {'shell_sections': sections(fw/'shell.elf'), 'kernel_sections': sections(fw/'kernel.elf'),
            'model_buffer_reserved':8192, 'model_demo_bytes':1568,
            'arena_reserved':4096, 'arena_demo_used':116,
            'shell_image':image,'shell_copy_pages':pages,'pool':pool,'page_budget_remaining':remaining}

mp=os_dir.parent/'micropython/ports/psc'
mp_build=build/'micropython-rv32i'
iarch='-march=rv32i_zicsr_zifencei -mabi=ilp32 -mno-relax'
run(['make',f'BUILD={mp_build}',
     'ARCH=--target=riscv64-unknown-elf '+iarch+' --sysroot=/usr/lib/picolibc/riscv64-unknown-elf',
     'embedded'],mp)
libgcc=output(['riscv64-unknown-elf-gcc','-march=rv32i','-mabi=ilp32','-print-libgcc-file-name']).strip()
result={}
for isa in ['rv32im','rv32i']:
    fw=build/isa
    extra=[] if isa=='rv32im' else ['ARCH='+iarch, 'RISCV_ARCH='+iarch,
        'BUILTINS_LIB='+libgcc, 'KERNEL_BUILTINS='+libgcc,
        f'MICROPY_LIB={mp_build}/libmicropython_psc.a']
    run(['make','MODE=psc',f'Build={fw}',*extra,'kernel_mem'])
    for name in ['shell.elf','kernel.elf']:
        assert not output(['llvm-nm','-u',str(fw/name)]).strip()
        if isa=='rv32i':
            dis=output(['llvm-objdump','-d','--no-show-raw-insn',str(fw/name)])
            assert not re.search(r'^\s*[0-9a-f]+:\s+(?:mul|mulh|mulhu|mulhsu|div|divu|rem|remu)\s',dis,re.M), name
    result[isa]=memory(fw)

# Link complete C++ runtime including prepare/invoke, without the OS or MP,
# so their existing heap cannot hide accidental runtime allocation dependencies.
standalone=build/'runtime-rv32i.elf'
fw=build/'rv32i'
# Standalone ABI stubs replace only syscalls; actual adapter is linked/audited.
stub=build/'platform_stub.c'
stub.write_text('#include "tflite_synap.h"\nint psc_tflite_clock_us(void){return -1;}\nint psc_tflite_sa_tile(const int8_t*a,const int8_t*b,int32_t*c,unsigned n,psc_sa_profile_t*p){return -77;}\n')
run(['clang','--target=riscv64-unknown-elf',*iarch.split(),'-ffreestanding','-nostdlib',
     '-I'+str(os_dir/'src/tflite'),'-c',str(stub),'-o',str(build/'platform_stub.o')])
run(['clang' ,'--target=riscv64-unknown-elf',*iarch.split(),'-nostdlib',
     '-Wl,-e,psc_tflite_invoke',*[str(fw/(n+'.o')) for n in ['tflite_inspect','tflite_runtime','tflite_synap','tflite_quant']],str(build/'platform_stub.o'),
     '/usr/lib/picolibc/riscv64-unknown-elf/lib/rv32i/ilp32/libm.a',
     '/usr/lib/picolibc/riscv64-unknown-elf/lib/rv32i/ilp32/libc.a',libgcc,'-o',str(standalone)])
assert not output(['llvm-nm','-u',str(standalone)]).strip()
assert not any(n.startswith(('_Zn','__cxa','__gxx')) or n in ('malloc','calloc','realloc','free') for n in symbols(standalone))
result['runtime_heap_cxx_dependency_audit']='PASS'
if a.phase2:
    before=sections(a.phase2/'shell.elf'); after=result['rv32im']['shell_sections']
    result['phase2_delta']={n:after.get(n,0)-before.get(n,0) for n in ['.text','.rodata','.srodata.cst8','.eh_frame','.data','.bss']}
    result['phase2_page_budget_delta']=result['rv32im']['page_budget_remaining']-69632
(build/'phase3_memory.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2))
print('PASS: full RV32I/IM shell + kernel, I-only disassembly, standalone runtime heap/C++ audit, RAM budgets')
