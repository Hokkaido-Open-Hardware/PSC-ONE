# INT8 FC automatic backend selection

CLI:

```text
tflite_run MODEL.TFL [cpu|npu|pulp|auto]
tflite_diag [on|off]
tflite_bench MODEL.TFL [quick]
```

Omitting the backend still selects CPU. Explicit `npu` still defaults to tile 4;
`psc_tflite_set_synap_tile_size()` selects multiples of 4 up to the shared `SA_MAT_MAX=64` for that mode. `pulp` uses the
existing signed `cv.dotsp.b` primitive. `auto` chooses once per FC, without
benchmarking, heap allocation, or input-dependent tuning during inference.
Backend enum values 0/1/2 remain unchanged; AUTO is 3. The MicroPython binding's
existing public backend restrictions are unchanged.

The shell supplies the existing 16-byte demo input; for larger/smaller input
shapes it repeats/truncates that vector. Application inputs should be supplied
through `psc_tflite_get_input()`. The demo oracle is meaningful only for the
original demo model. The benchmark command retains the original two-layer demo benchmark. Other
input sizes use the general graph benchmark: CPU, PULP, AUTO and NPU tiles
4/8/12/16/32/64, three rotated warm samples, all output bytes compared.
`quick` keeps CPU/PULP/NPU16/NPU32/AUTO and the same three-sample validation,
and prints an output-byte summary. The original 16-byte demo benchmark is unchanged.

## Shapes and arithmetic

The runtime supports static rank-2 INT8 FULLY_CONNECTED v4 with constant
symmetric INT8 weights: input A[M,K], stored weights W[N,K], output Y[M,N].
The mathematical B[K,N] is W transposed. `[1,16]` FC input means **M=1**, whereas
16x16 matrix multiplication means **M=16, K=16, N=16**.

Batch FC support extends the existing scalar FC and reuses its row sums,
zero-point correction, bias, upstream double-rounding requantization, and
INT8/RELU clamp. No new quantization implementation is introduced. Model/arena
limits remain 8192/4096 bytes. NPU scratch is fixed size: 40 KiB total in the adapter/runtime for two INT8
64x64 tiles and two INT32 64x64 tiles. These buffers are static, protected by
the existing invoke guard, and do not enlarge the invoke stack by 16 KiB.
Kernel transfer buffers are separate. There is no inference-time heap use.

NPU uses the existing adapter, platform boundary and hardware driver. It packs
W tiles into A and transposed input rows into B, zero-pads the edges, runs the
square engine, and accumulates K tiles. The tile count is
`ceil(M/T)*ceil(K/T)*ceil(N/T)`. All dot products, including edge tiles, use the
same CPU postprocessing. Trace `channel` is flattened `row*N+column`; batched
NPU traces can visit channels in tile order rather than monotonically.
Here `npu_tiles` counts adapter requests/engine launches. A tile-32 request
still uses the existing engine's internal 4x4 tiling; it is not a new 32x32
hardware datapath. That internal execution cost is included in the measurements.

Unsupported acceleration falls back to the existing scalar FC. K<4 cannot use
SIMD. Builds without `PSC_HAS_CV_DOTSP_B` emit no PULP instruction; host emulation
is test-only. Operators that the existing CPU runtime cannot execute (e.g.
CONV_2D), unsupported quantization, and invalid models still return their
existing errors at prepare; auto does not turn them into successful inference.
NPU device errors propagate and invalidate output, including in auto mode.

## Selection policy

The shipped policy is an intentionally small measured allowlist for CPU v1 /
legacy NPU. FC **M=K=N=16 or 32** selects NPU tile M (one launch, no
padding), independently of PULP availability. Other FC depths of at least four
use PULP; shallow FC and unavailable PULP fall back to CPU. PULP-disabled auto
therefore still uses NPU for the calibrated shape and emits no SIMD instruction.
Performance on other CPU/NPU versions requires separate measurement. No backend is speculatively executed to choose the next one.

The distinction is based on **OS** measurements including copies and syscalls:
32x32 benefits from one tile-32 launch, while eight tile-16 launches lose that
advantage. An initial smaller-buffer build did not show an OS advantage for
16x16. The 64-limit OS build subsequently measured NPU16 at 6069 us versus
PULP at 6843 us (two samples each), so the policy was expanded to include 16x16.
This also shows why calibration must specify the exact firmware/cache layout.
Unmeasured larger or padded shapes remain on PULP even if a future benchmark
might establish a faster NPU path. This is not a claim of global optimality.

**Report status (2026-09-29):** the final two-shape policy passes both host
configurations. Its final OS RTL timing rerun is still in progress at the user's
requested reporting point. The completed 32x32 table below is from the preceding
OS binary (already using auto NPU32, before adding auto NPU16). Do not label it
as final-binary timing. See [AUTO_REPORT.md](AUTO_REPORT.md) for the report snapshot.

## Diagnostics and timing

`psc_tflite_debug_selection(log,user)` prints each FC's M/K/N, candidate NPU tile
size, tile count, remainders, selected backend and reason. It is a read-only call
outside inference. `tflite_diag off` suppresses shell selection, constant and
per-channel dumps. Invoke never prints diagnostic text. Timed calls have no
per-channel trace, no diagnostic output and no detailed profiling. Layer timing
is measured in a separate invocation; it includes selection, packing, launch,
completion wait, result copy, partial sums and quantization.

The API's existing optional NPU profiling still separates packing, platform
call, copy-in/execute/copy-out, partial-sum and postprocessing times. Profiling
adds timer overhead, so it must be disabled for backend speed comparisons.

## Reproduction

Run from the repository root; all builds are isolated and do not invoke clean:

```sh
myenv/bin/python PSC-ONE/software/os/tests/tflite/auto_host.py --build /tmp/psc-auto-host
myenv/bin/python PSC-ONE/software/os/tests/tflite/auto_target.py --build /tmp/psc-auto-rtl --fixtures /tmp/psc-auto-host
myenv/bin/python PSC-ONE/software/os/tests/tflite/auto_target.py --build /tmp/psc-auto-disabled --fixtures /tmp/psc-auto-host --disable-pulp --dispatch-only --rtl-build /tmp/psc-auto-rtl/verilator
python3 PSC-ONE/software/os/third_party/tflite/psc/run_host.py --build /tmp/psc-auto-pulp-regression
python3 PSC-ONE/software/os/tests/tflite/run.py --build /tmp/psc-auto-file
```

Host tests use ASan/UBSan, the pinned official TFLM reference, SIMD emulation and
a square-matmul NPU mock. They verify raw dot, zero-point correction, biased
accumulator, requantized result and clamp. Allocation wrappers reject heap use
during invoke. Protected-page and all four pointer-alignment tests come from
the unchanged existing PULP suite. **Host times are not hardware performance.**

Target tests execute real CPU v1 and legacy Synap RTL at 100 MHz, with the same
SDRAM/cache configuration and firmware for all modes. Every timed inference is
preceded by a warm inference of that mode. Three samples rotate mode order.
Tables report the minimum total invoke sample and its separately measured layer
time; JSON retains all samples. The firmware checks all five stages on target,
including a host-oracle checksum, outside timing. Disassembly checks instruction
encodings, scalar paths, disabled PULP builds and absence of linked allocators.

This target harness calls the real `sa_run_checked` driver in bare metal. It
includes driver setup, synchronization and result reads, but **does not include
PSC-OS syscall/MMU validation or user/kernel copies**. The separate OS RTL
test below measures those costs through the actual shell. Board measurements, cold-cache performance and
other CPU/NPU versions require their own calibration.


`src/api/sa_limits.h` is the common C/C++ size definition. It preserves the
user-requested `SA_MAT_MAX=64`, formerly defined directly in `synap_api.h`.
The OS Makefile adds this header to TFLite dependencies; kernel dependencies
already include `src/api/*.h`. No clean target or RTL is changed. Increasing
the NPU transfer limit does not increase the model or tensor-arena limits.
A full 64x64 input and output together still exceed the 4 KiB tensor arena.

The OS measurement can be reproduced with:

```sh
myenv/bin/python PSC-ONE/software/os/tests/tflite/rtl_run.py --build /tmp/psc-auto-os-rtl --model /tmp/psc-auto-host/shape_5.tfl --test-module auto_os_cocotb
# Final two-shape selection rerun, retaining three samples and all output checks:
CCACHE_DIR=/tmp/psc-auto-os-selected/ccache myenv/bin/python PSC-ONE/software/os/tests/tflite/rtl_run.py --build /tmp/psc-auto-os-selected --model /tmp/psc-auto-host/shape_5.tfl --test-module auto_os_cocotb --quick-bench --rtl-build /tmp/psc-auto-os-rtl/verilator
```

This boots the actual shell and uses `tflite_bench` on the same generated
models. It includes MMU, syscalls, user/kernel copying and timer overhead.
The test-only top increases SD fixture storage; CPU/NPU RTL is unchanged.

The 64x64 result transfer also needs four supervisor pages (16 KiB), not the
previous single 4 KiB mapping. `kernel_process.c` now sizes the SA input/result
mappings from `SA_MAT_MAX`; PAGE_U is not added. This fixes the page fault
encountered when reading a tile-64 result past the first page. A tile-32 INT32
result fits in one page and was unaffected by that original mapping limit.


## Changed sources and checks

- Runtime/API/diagnostics: `tflite_api.h`, `tflite_runtime.cc`, `tflite_inspect.cc`,
  `tflite_synap.h/.cc`, `tflite_file.c`, and `src/shell/shell.c`.
- Shared NPU size: new `src/api/sa_limits.h`, included by `synap_api.h`; OS
  `Makefile` header dependency and `src/kernel/kernel_process.c` result mapping.
- Existing tests extended: `tests/tflite/host.cc`, `phase3.cc`, `phase4.cc`,
  `synap_mock.cc`, `driver_test.py`, `run.py`, `rtl_run.py`, and `rtl_test.py`.
- New tests: `auto_host.cc/.py`, `auto_target.cc/.py`, `auto_cocotb.py`,
  `auto_os_cocotb.py`; saved measurements in `auto_results.json`.
- Documentation: this file, new `AUTO_REPORT.md`, `README.md`, and the pointer in historical `PHASE4.md`.
- No source files removed. No CPU/NPU/cache RTL changes; no Git staging/commit/push.

Full 64-tile intermediate verification, separate from performance measurement:

```sh
myenv/bin/python PSC-ONE/software/os/tests/tflite/auto_target.py --build /tmp/psc-auto64-correctness --fixtures /tmp/psc-auto-host --shape 9 --validate64-only --rtl-build /tmp/psc-auto-rtl/verilator
```

## Validation scope and calibration history

Machine-readable samples, firmware hashes and provenance are retained in
[`tests/tflite/auto_results.json`](../../../tests/tflite/auto_results.json).
For **M=K=N=32 on full PSC-OS RTL**, the corrected 64-limit calibration build
(before adding auto NPU16) measured:

| Backend | Adapter launches | FC time (us) | Total invoke (us) |
|---|---:|---:|---:|
| CPU | 0 | 67951 | 67970 |
| PULP | 0 | 32670 | 32687 |
| NPU tile 4 (explicit mode default) | 512 | 168765 | 168791 |
| NPU tile 8 | 64 | 72592 | 72621 |
| NPU tile 12 | 27 | 62872 | 62902 |
| NPU tile 16 | 8 | 38848 | 38879 |
| NPU tile 32 | 1 | 26220 | 26247 |
| NPU tile 64 | 1 | 70644 | 70684 |
| AUTO (selects NPU tile 32) | 1 | 26217 | 26247 |

All three rotated samples agreed on each value in this table. NPU tile 32
reduces total time by **19.7% versus PULP** (1.245x speedup), and by 61.4%
versus CPU. Tile 64 pads each dimension by two and does more internal work and
copying; increasing `SA_MAT_MAX` does not make the maximum tile optimal.
These figures include the OS MMU/syscalls/copies and all integer postprocessing.

The 64-limit bare-metal calibration results below use the same ELF within each
row and precede the auto NPU16 addition. Each entry
is **total invoke / separately measured FC**, in microseconds, at 100 MHz:

| M,K,N | CPU | PULP | NPU tile 16 | NPU tile 32 | AUTO |
|---|---:|---:|---:|---:|---:|
| 32,32,32 | 34263 / 34245 | 21901 / 21879 | 14325 / 14305 | 11731 / 11712 | 11731 / 11712 |
| 16,64,16 | 11675 / 11663 | 4964 / 4951 | 5374 / 5362 | 9091 / 9077 | 4965 / 4952 |

For the PULP-disabled 32x32 RTL calibration build, CPU is 33995 / 33976 us, explicit
PULP falls back to CPU (33993 / 33977 us), and AUTO uses NPU tile 32
(11852 / 11838 us, one launch). These numbers belong to a different ELF and must
not be used to compare enabled/disabled build speed. NPU tile 64 separately
passed all five intermediate stages against CPU and the host oracle on real RTL.

Historical complete rows from the early bare-metal sweep (before the 64 limit
and final dispatch; total invoke us) explain the initial shape screening:

| M,K,N | CPU | PULP | Fastest measured NPU (tile) |
|---|---:|---:|---:|
| 1,3,5 | 94 | 93 (scalar fallback) | 184 (4) |
| 1,16,16 | 347 | 248 | 776 (16) |
| 1,17,15 | 350 | 267 | 972 (8) |
| 1,64,32 | 1693 | 691 | 4902 (8) |
| 4,16,16 | 1217 | 820 | 1060 (16) |
| 16,16,16 | 4750 | 3143 | 2256 (16) |
| 15,17,19 | 6211 | 4151 | 4226 (16) |
| 17,31,17 | 8893 | 5384 | 6168 (12) |

These historical numbers are not final-OS results. In particular, neither
the single-sample 16-input/16-output FC nor the two padded shapes showed an
NPU advantage over PULP, even before adding OS copying and syscall overhead.

Host checks passed with ASan/UBSan in both scalar-only and emulated-PULP builds:
ten shapes, CPU/NPU/PULP/AUTO, tiles 4/8/12/16/32/64, and mixed two-layer batch
graphs. All five integer stages are checked against CPU and the pinned TFLM
oracle. Mixed graphs include NPU then PULP/CPU dispatch, zero-point extrema,
bias/no bias, RELU/NONE, and NPU failure/output invalidation/recovery. The existing
PULP suite also passed 1,950 invokes and 31,200 stage comparisons per build,
with 3,048 protected-boundary dot products in the emulated build.

The file/CLI suite passed 3,628 parser/profile/FAT32 checks, all four modes with
diagnostics on/off, and the generic graph benchmark through tile 64. Its existing
reference checks passed 47 cases, 712 channels, 65,560 multiplier comparisons,
and 288 CPU/NPU invokes with 2,880 five-stage comparisons. The driver mock checks
all supported tile sizes through 64, argument errors, busy, timeout and recovery.
Host mock/emulation results are correctness evidence, not NPU or SIMD speed data.

An early bare-metal sweep reached its 3,000 ms simulated deadline after complete
records for shapes 0–7. The overall run is **TIMEOUT**, not PASS; its retained
complete per-shape samples are explicitly historical. Larger shapes were rerun
separately. Initial investigation also found the tile-64 OS result-page fault
described above; it was a real failure and was fixed in the page mappings.
ASan initially found a test fixture whose model buffer went out of scope; the
fixture lifetime was fixed and both host configurations passed on rerun.

No physical-board performance, cold-cache calibration, other CPU/NPU versions,
or full repository RTL regression/synthesis is claimed. No CPU/NPU RTL changed.
The exact-shape policy intentionally leaves unmeasured shapes on PULP/CPU.
