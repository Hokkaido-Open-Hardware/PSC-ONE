#!/usr/bin/env python3
"""Isolated equivalent of Makefile.pscos simulation, without its clean targets.
Run with repository myenv/bin/python (cocotb 2). Uses a test-only copy of the top
to enlarge the existing SD model's sector store; production RTL stays unchanged.
"""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import xml.etree.ElementTree as ET
from cocotb_tools.runner import get_runner

os_dir = Path(__file__).resolve().parents[2]
sim = os_dir.parents[1] / 'hardware/sim'
p = argparse.ArgumentParser()
p.add_argument('--build', type=Path, required=True)
p.add_argument('--model', type=Path, required=True)
a = p.parse_args()
build = a.build.resolve(); build.mkdir(parents=True, exist_ok=True)
firmware = build / 'firmware'
subprocess.run(['make', 'MODE=sim', f'Build={firmware}', 'kernel_mem',
                str(firmware / 'bootrom.mem'), str(firmware / 'bootloader_fat32.mem'),
                str(firmware / 'user.mem')], cwd=os_dir, check=True)
run = build / 'run'; (run / 'mem').mkdir(parents=True, exist_ok=True)
(run / 'wave').mkdir(exist_ok=True)
for name in ['bootrom.mem', 'kernel.mem', 'user.mem']:
    shutil.copyfile(firmware / name, run / 'mem' / name)
# Existing optional ROM initializer expects this file even when OS_SIM is used.
shutil.copyfile(firmware / 'bootloader_fat32.mem', run / 'mem/bootloader.mem')
mk = build / 'sources.mk'
mk.write_text(f'include {sim}/Makefile.pscos\n'
              'tflite_sources:\n\t@echo $(abspath $(INPUT_FILE_PSCONE))\n')
env = dict(os.environ)
env['PATH'] = str(Path(os.sys.executable).parent) + ':' + env['PATH']
sources = subprocess.check_output(['make', '--no-print-directory', '-s', '-f', str(mk),
                                  'CPU_VERSION=v1', 'SIM_FAST=1', 'tflite_sources'],
                                 cwd=sim, env=env, text=True).split()
top = sim.parent / 'rtl/top/PSC_ONE_Chip_sim.v'
copy = build / top.name
text = top.read_text()
assert '.DATA_HEX     ("")' in text
copy.write_text(text.replace('.DATA_HEX     ("")', '.STORED_SECTORS (32),\n        .DATA_HEX     ("")'))
sources = [str(copy) if Path(s) == top else s for s in sources]
# OS_SIM's historical 600 KB preload ROM is smaller than the actual 1 MiB
# user address window. Enlarge only the test copy; do not truncate the image
# or alter production RTL/memory-map/page budgets.
boot = sim.parent / 'rtl/boot/PSC_ONE_Boot_axi.v'
boot_copy = build / boot.name
boot_text = boot.read_text()
assert boot_text.count('= 150000') == 3
assert (firmware / 'shell.bin').stat().st_size <= 1024*1024
boot_copy.write_text(boot_text.replace('= 150000', '= 262144'))
sources = [str(boot_copy) if Path(s) == boot else s for s in sources]
runner = get_runner('verilator')
runner.build(sources=sources, hdl_toplevel='PSC_ONE_Chip_sim', build_dir=build / 'verilator',
             build_args=['-O3', '-CFLAGS', '-O3', '--bbox-sys', '--x-assign', 'fast', '--x-initial', 'fast',
                         '-Wno-fatal', '-DTOP_SIM', '-DOS_SIM', '-DFST_UART_MODE'],
             always=False, waves=False, log_file=build / 'compile.log')
runner.test(hdl_toplevel='PSC_ONE_Chip_sim', test_module='rtl_test', test_dir=run,
            extra_env={'PYTHONPATH': str(Path(__file__).parent),
                       'PSC_TFLITE_MODEL': str(a.model.resolve()),
                       'PSC_TFLITE_UART': str(build / 'uart.log')},
            results_xml=str(build / 'results.xml'), log_file=build / 'simulation.log')
results = ET.parse(build / 'results.xml')
cases = results.findall('.//testcase')
if len(cases) != 1 or results.findall('.//failure') or results.findall('.//error') or results.findall('.//skipped'):
    raise SystemExit('RTL verification FAIL; see results.xml and simulation.log')
print('RTL verification PASS')
