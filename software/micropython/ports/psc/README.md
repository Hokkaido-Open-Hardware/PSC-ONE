# PSC-OS TFLite bindings

PSC-OS embeds this port in the same user image as the existing TFLite runtime.
The seven functions below call that C API directly; no new syscall is used.
This integration targets the embedded PSC-OS build, not standalone
`micropython.elf` (which does not link the TFLite runtime).

| API | Result / behavior |
| --- | --- |
| `psc.tflite_load(name)` | Load and prepare an uppercase 8.3 filename from the SD root; returns `None`. |
| `psc.tflite_reset()` | Reset model, results and settings; returns `None`. |
| `psc.tflite_input_size()` | Required input size in bytes; raises `OSError` when unprepared. |
| `psc.tflite_run(data)` | Copy input, synchronously invoke, and return a Python-owned `bytes` copy. |
| `psc.tflite_set_fc_backend(backend)` | `0` = CPU, `1` = Synap; returns `None`. |
| `psc.tflite_set_synap_tile_size(size)` | Select `4`, `8`, `12` or `16`; returns `None`. |
| `psc.tflite_arena_used()` | C arena bytes used, zero after reset. |

`tflite_run` accepts a readable byte buffer, rejects text strings, and requires
exactly the model input byte count. INT8 values use two's-complement encoding
(`-1` is byte `255`). It exposes no arena or internal buffer memoryview.
Returned bytes survive subsequent inference, load and reset operations.
Wrong types raise `TypeError`; wrong input lengths, backend/tile values and
embedded NUL filenames raise `ValueError`. C API failures raise `OSError`
with the original negative error code in `args[0]`.

The shell and Python share one resident model. A C API load failure also
invalidates the old model; shell `tflite_info` invalidates it too. Leaving the
REPL does not reset TFLite. Load/reset restores CPU backend and tile size 4.
Synap errors do not fall back to CPU. Inference is synchronous and provides
no Python callback or cancellation hook. The existing limited INT8 FC model
profile, 8 KiB model capacity and 4 KiB arena still apply.

Build from `PSC-ONE/software/os` with `make MODE=psc kernel_mem`.
For a board/RTL smoke test, generate the existing deterministic model:

```sh
python3 PSC-ONE/software/os/tests/tflite/generate_model.py --build /tmp/psc-tflite-demo
```

Copy `/tmp/psc-tflite-demo/MODEL.TFL` and
`PSC-ONE/software/os/tests/tflite/MP_TFL.PY` to the SD root (ensure
`ABSENT.TFL` does not exist). In the PSC-OS MicroPython REPL run:

```python
import psc
psc.run("MP_TFL.PY")
```

The script checks known CPU output, all four Synap tile sizes, argument errors,
load/reset behavior and output-copy lifetime. It requires working Synap
hardware (or RTL simulation), and ends with
`PASS: MicroPython TFLite all checks` only when every assertion succeeds.

# The minimal port

This port is intended to be a minimal MicroPython port that actually runs.
It can run under Linux (or similar) and on any STM32F4xx MCU (eg the pyboard).

## Building and running Linux version

By default the port will be built for the host machine:

    $ make

To run the executable and get a basic working REPL do:

    $ make run

## Building for an STM32 MCU

The Makefile has the ability to build for a Cortex-M CPU, and by default
includes some start-up code for an STM32F4xx MCU and also enables a UART
for communication.  To build:

    $ make CROSS=1

If you previously built the Linux version, you will need to first run
`make clean` to get rid of incompatible object files.

Building will produce the build/firmware.dfu file which can be programmed
to an MCU using:

    $ make CROSS=1 deploy

This version of the build will work out-of-the-box on a pyboard (and
anything similar), and will give you a MicroPython REPL on UART1 at 9600
baud.  Pin PA13 will also be driven high, and this turns on the red LED on
the pyboard.

## Building without the built-in MicroPython compiler

This minimal port can be built with the built-in MicroPython compiler
disabled.  This will reduce the firmware by about 20k on a Thumb2 machine,
and by about 40k on 32-bit x86.  Without the compiler the REPL will be
disabled, but pre-compiled scripts can still be executed.

To test out this feature, change the `MICROPY_ENABLE_COMPILER` config
option to "0" in the mpconfigport.h file in this directory.  Then
recompile and run the firmware and it will execute the frozentest.py
file.
