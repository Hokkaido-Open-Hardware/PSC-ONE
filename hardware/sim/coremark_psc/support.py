"""Build metadata, layout checks and fail-closed CoreMark result reporting."""
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys


def require(condition, message):
    if not condition:
        raise ValueError(message)


def write_changed(path, text):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    if not path.exists() or path.read_text() != text:
        path.write_text(text)


def settings(cpp, output):
    # Ask make to expand its own variables without building any firmware.
    names = ['RISCV_PREFIX', 'CXXFLAGS', 'LINKER', 'STARTUP']
    recipe = "__coremark_settings:\n\t@printf '%s\\n' " + ' '.join(
        "'$(" + name + ")'" for name in names)
    result = subprocess.check_output([
        'make', '--no-print-directory', '-s', '-C', cpp, '-f', 'Makefile',
        'TARGET=__coremark_unused', '--eval', recipe, '__coremark_settings',
    ], text=True, env={k: v for k, v in os.environ.items()
                      if k not in ('MAKEFLAGS', 'MFLAGS', 'MAKELEVEL')})
    values = result.splitlines()
    if len(values) != len(names):
        raise ValueError('Unexpected firmware configuration: ' + result)
    write_changed(output, '# Generated from cpp/Makefile; do not edit.\n' + ''.join(
        'CM_REF_' + name + ' := ' + value + '\n'
        for name, value in zip(names, values)))


def layout(path):
    symbols = {}
    for line in Path(path).read_text().splitlines():
        fields = line.split()
        if len(fields) == 3:
            symbols[fields[2]] = int(fields[0], 16)
    require(symbols['_start'] == 0, 'Existing boot ROM starts execution at address 0')
    require(symbols['__bss_start'] % 4 == symbols['__bss_end'] % 4 == 0, 'Startup clears BSS in words')
    require(symbols['__bss_end'] + 8192 <= symbols['_stack_top'], 'Reserve at least 8 KiB main stack')


def report(path, result_path):
    log = Path(path).read_text()
    print(log, end='')
    if 'Correct operation validated.' not in log or 'ERROR!' in log:
        raise ValueError('CoreMark did not validate; no performance score accepted')
    def field(label):
        match = re.search(r'^' + re.escape(label) + r'\s*:\s*(\S+)', log, re.M)
        if not match:
            raise ValueError('Missing CoreMark field: ' + label)
        return match.group(1)
    expected = {
        0xe9f5: (0xe714, 0x1fd7, 0x8e3a),
        0x18f2: (0xe3c1, 0x0747, 0x8d84),
    }
    seed = int(field('seedcrc'), 16)
    crcs = tuple(int(field('[0]' + name), 16) for name in ('crclist', 'crcmatrix', 'crcstate'))
    require(seed in expected and crcs == expected[seed], 'CRC mismatch')
    require(int(field('CoreMark Size')) == 666, 'Non-standard data size')
    ticks = int(field('Total ticks'))
    iterations = int(field('Iterations'))
    require(ticks >= 10000 and iterations > 0, 'Need at least 10 target seconds')
    seconds = ticks / 1000
    windows = json.loads(Path(result_path).with_name('timer.json').read_text())['timer_windows_ns']
    require(len(windows) >= 1, 'Missing complete timer window')
    # The existing stopwatch truncates to milliseconds. Allow one tick plus
    # 10 us for software/MMIO start/stop and IRQ synchronisation overhead.
    require(abs(windows[-1] - ticks * 1_000_000) <= 1_010_000, 'Target timer disagrees with RTL time')
    score = iterations / seconds
    result = dict(cpu_clock_hz=100_000_000, timer_ticks_ms=ticks,
                  target_seconds=seconds, iterations=iterations,
                  coremark=score, coremark_per_mhz=score / 100,
                  rtl_timer_window_ns=windows[-1],
                  seedcrc=hex(seed), crc_validation=True)
    result['uart_log'] = str(Path(path).resolve())
    Path(result_path).write_text(json.dumps(result, indent=2) + '\n')
    print(f'CPU clock       : 100 MHz\nTarget time     : {seconds:.3f} s')
    print(f'CoreMark        : {score:.6f}\nCoreMark/MHz    : {score / 100:.6f}')
    print('Timing source   : PSC-OS MMIO timer stopwatch (1 ms resolution)')


if __name__ == '__main__':
    action, *args = sys.argv[1:]
    if action == 'settings':
        settings(*args)
    elif action == 'config':
        compiler = subprocess.check_output([os.environ['CC'], '--version'], text=True).splitlines()[0]
        write_changed(os.environ['OUT'], '#define FLAGS_STR ' + json.dumps(os.environ['FLAGS']) +
                      '\n/* ' + compiler + ' */\n')
    elif action == 'layout':
        layout(*args)
    elif action == 'report':
        report(*args)
    elif action == 'clean':
        target = Path(args[0]).resolve()
        expected = Path(__file__).resolve().parents[1] / 'build' / 'coremark'
        if target != expected:
            raise ValueError('Refusing to clean outside build/coremark')
        print('Removing generated files only:', target)
        if target.exists():
            shutil.rmtree(target)
    else:
        raise ValueError(action)
