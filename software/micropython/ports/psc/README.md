# MicroPython PSC port

[PSC-ONE](../../../../README.md) · [Documentation](../../../../docs/README.md)

This port targets RV32IM with Zicsr/Zifencei. The standalone [Makefile](Makefile) uses Clang/LLVM and picolibc; the embedded PSC-OS build is managed by the [OS Makefile](../../../os/Makefile).

## PSC-OS TFLite bindings

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

## Build modes

From the repository root, build the PSC-OS image with:

```sh
make -C PSC-ONE/software/os MODE=psc kernel_mem
```

For the standalone port, inspect the compiler and picolibc paths in the local
Makefile, then run `make -C PSC-ONE/software/micropython/ports/psc`.
The standalone image does not include the PSC-OS TFLite runtime.
