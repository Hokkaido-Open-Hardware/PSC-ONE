#!/usr/bin/env python3
"""Run the same standalone regression against either cache-controller revision."""
import argparse
from pathlib import Path
import re
import subprocess
import tempfile


def main():
    tests = Path(__file__).resolve().parent
    src = tests.parent / 'src'
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--rtl', type=Path, help='Alternative controller for revision comparisons')
    parser.add_argument('--build', type=Path)
    args = parser.parse_args()
    build = args.build or Path(tempfile.mkdtemp(prefix='cache-io-regression-'))
    build.mkdir(parents=True, exist_ok=True)
    rtl = args.rtl or src / 'cache_dma_controller_io.sv'
    legacy = args.rtl and not re.search(r'\bPSC_CACHE_IO_2WAY\b', rtl.read_text())
    flags = ['-DCACHE_TEST_LEGACY_RTL'] if legacy else []
    cases = [(0, 6)] if legacy else [(0, 6), (1, 6), (1, 9)]
    for mode, tag_lsb in cases:
        name = f'{mode+1}way-tag{tag_lsb}'
        executable = build / f"{name}.vvp"
        with (build / f"{name}-compile.log").open('w') as log:
            subprocess.run([
                'iverilog', '-g2012', '-s', 'cache_io_regression', *flags,
                f'-Pcache_io_regression.PSC_CACHE_IO_2WAY={mode}',
                f'-Pcache_io_regression.TAGLSB={tag_lsb}', '-o', str(executable),
                str(tests / 'cache_io_regression.sv'), str(rtl.resolve()),
                str(src / 'dm_cache_data.v'), str(src / 'dm_cache_tag.v'),
            ], stdout=log, stderr=subprocess.STDOUT, check=True)
        result = subprocess.run(['vvp', str(executable)], text=True,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        (build / f"{name}.log").write_text(result.stdout)
        print(result.stdout, end='')
        result.check_returncode()
        if 'PASS cache_io_regression' not in result.stdout:
            raise RuntimeError('Simulation ended without the PASS marker')
    print(f'Logs: {build.resolve()}')


if __name__ == '__main__':
    main()
