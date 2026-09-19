#!/usr/bin/env python3
"""Run shared bridge and real-cache/SDRAM regressions without make clean.

Activate the repository's cocotb environment (myenv/bin on PATH) first.
Every run uses a new build directory, leaving existing simulation files intact.
"""
import argparse
import os
import subprocess
import tempfile
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--build', type=Path)
    parser.add_argument('--unit-only', action='store_true')
    args = parser.parse_args()
    rtl = Path(__file__).resolve().parents[2]
    sim = rtl.parent / 'sim'
    build = (args.build or Path(tempfile.mkdtemp(prefix='shared-bridge-'))).resolve()
    build.mkdir(parents=True, exist_ok=True)
    makefiles = subprocess.check_output(['cocotb-config', '--makefiles'], text=True).strip()
    env = os.environ.copy()
    env['PYTHONPATH'] = str(sim) + os.pathsep + env.get('PYTHONPATH', '')
    bridge = rtl / 'axi/sdram_32bit_to_256bit_axi_bridge.v'
    cases = [(f'bridge-fence{fence}', 'sdram_32bit_to_256bit_axi_bridge',
              'cocotb_tb.axi.bridge_test', [bridge],
              f'-Psdram_32bit_to_256bit_axi_bridge.FENCE_CYCLES={fence} '
              '-Psdram_32bit_to_256bit_axi_bridge.ID_WIDTH=3') for fence in (0, 1, 2, 5)]
    if not args.unit_only:
        sources = [rtl / 'cache/src' / n for n in (
            'sim_cache_dma_controller.v', 'cache_dma_controller.sv',
            'cache_dma_controller_io.sv', 'dm_cache_data.v', 'dm_cache_tag.v')]
        sources += [bridge, rtl / 'axi/sdram_axi_controller.v',
                    rtl / 'sdram_controller/sdram_controller.sv', rtl / 'SDRAM_model/GW2AR_sdram.v']
        cases += [(name, 'sim_cache_dma_controller', 'cocotb_tb.cache.' + name, sources, '')
                  for name in ('dm_cache_test', 'I_cache_test', 'shared_cache_test')]
    for name, top, module, sources, extra in cases:
        case = build / name
        case.mkdir()  # Refuse to overwrite a previous run's evidence.
        with (case / 'run.log').open('w') as log:
            subprocess.run(['make', '-f', str(Path(makefiles) / 'Makefile.sim'),
                            'SIM=icarus', 'TOPLEVEL=' + top, 'COCOTB_TEST_MODULES=' + module,
                            'VERILOG_SOURCES=' + ' '.join(map(str, sources)),
                            'COMPILE_ARGS=-g2012 ' + extra, 'SIM_BUILD=' + str(case / 'build'),
                            'COCOTB_RESULTS_FILE=' + str(case / 'results.xml')],
                           env=env, cwd=case, stdout=log, stderr=subprocess.STDOUT, check=True)
        print('PASS', name, flush=True)
    print('Logs:', build)


if __name__ == '__main__':
    main()
