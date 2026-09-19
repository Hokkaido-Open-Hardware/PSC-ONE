#!/usr/bin/env python3
"""Run the same standalone regression against either cache-controller revision."""
import argparse
from pathlib import Path
import subprocess
import tempfile


def main():
    tests = Path(__file__).resolve().parent
    src = tests.parent / 'src'
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--rtl', type=Path, default=src / 'cache_dma_controller_io.sv')
    parser.add_argument('--build', type=Path)
    args = parser.parse_args()
    build = args.build or Path(tempfile.mkdtemp(prefix='cache-io-regression-'))
    build.mkdir(parents=True, exist_ok=True)
    executable = build / 'regression.vvp'
    with (build / 'compile.log').open('w') as log:
        subprocess.run([
            'iverilog', '-g2012', '-s', 'cache_io_regression', '-o', str(executable),
            str(tests / 'cache_io_regression.sv'), str(args.rtl.resolve()),
            str(src / 'dm_cache_data.v'), str(src / 'dm_cache_tag.v'),
        ], stdout=log, stderr=subprocess.STDOUT, check=True)
    result = subprocess.run(['vvp', str(executable)], text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    (build / 'simulation.log').write_text(result.stdout)
    print(result.stdout, end='')
    result.check_returncode()
    if 'PASS cache_io_regression' not in result.stdout:
        raise RuntimeError('Simulation ended without the PASS marker')
    print(f'Logs: {build.resolve()}')


if __name__ == '__main__':
    main()
