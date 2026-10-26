> Current status (Phase 2): all 16 CPU operator kinds, YOLO 289-node execution,
> 1024 tensors / 512 operators, separate 768KiB mapped graph Arena.
> The legacy FC-only path retains its 4KiB Arena. See
> [Phase 2 report](../../../../../../report/psc-os-tflite-phase2-20261025.md)
> for current limits, memory layout and verification. Older sections below
> record the earlier development phases.

# PSC-OS TFLite

## Mixed CPU / PULP / SynapEngine execution

`tflite_run YOLO.TFL cpu|pulp|npu|auto` now selects a backend per prepared
operator. CPU keeps the reference kernels. PULP uses signed `cv.dotsp.b` for
INT8 Conv2D and FC; unsupported shapes/builds use CPU. NPU uses signed INT8
GEMM for Conv2D/FC, packing only one im2col tile at a time. Weight zero points
must be zero; the existing prepare checks validate types, geometry, bias,
per-channel quantization and accumulator bounds before dispatch. FLOAT32
quantize/dequantize and the other graph operators remain on CPU.

AUTO retains the measured FC NPU allowlist (square 16/32), otherwise chooses
PULP where supported and CPU elsewhere. Conv AUTO conservatively uses PULP:
bare-metal NPU speedups do not prove a gain after OS syscall/transfer costs on
every YOLO shape. Explicit `npu` executes supported Conv/FC on the NPU.

No full im2col tensor or extra Arena allocation is used. The existing Synap
A/B/C buffers and FC accumulator scratch are shared by synchronous invokes.
The generic graph uses a default tile size of 32; the legacy FC path retains
its default 4. `psc_tflite_set_synap_tile_size()` supports multiples of four
through 64. Tails are zero padded for GEMM; image padding uses input zero
point. Accumulation, bias correction and the existing CPU requantizer produce
the same output codes. A started NPU failure aborts and invalidates output;
there is no retry on CPU while DMA completion is uncertain.

Synap availability is a platform opt-in, not a CSR probe. The OS Makefile
enables it for PSC targets; use `TFLITE_HAS_SYNAP=0` for hardware without the
device. Generic standalone/SBI/QEMU runtime builds default to unavailable.
PULP is enabled only on the configured supporting CPU. Host tests explicitly
mock the device/emulate dot arithmetic; those results are not hardware timings.

After invoke, the shell prints actual completed CPU/PULP/NPU counts, CPU
fallbacks, per-backend times, Conv totals, and successful NPU tiles. Diagnostics
also print each operator's backend/time/status. The operator time sum excludes
layer/tensor observation and UART; the separately reported wall time includes
diagnostics. Load time includes progress UART when diagnostics are enabled.
NPU syscall time includes kernel copy/execute/copy-back, so do not add it again
to those components. `-1` indicates unavailable timing. Model output FNV is
computed from raw bytes after timing. No accelerator use is explicitly reported
when all operators run on CPU.

Useful validation entry points in `tests/tflite/`:

- `operators.py --build PATH --mixed`: shape/quantization/border/tile/error
  tests using PULP arithmetic emulation and NPU matrix multiplication mock.
- `mixed_yolo.py --build PATH --model YOLO.TFL --reference REF`: all 289
  intermediate tensors and full 44,100-element output for all four modes.
- `mixed_target.py --build PATH --fixtures FIXTURES`: actual CPU-v1 and legacy
  SynapEngine RTL, SIMD encoding audit, unaligned/tail tests, graph equality
  and bare-metal times. Run with repository `myenv/bin/python`.
- `mixed_target.py ... --tail-only --rtl-build PREVIOUS/verilator`: real NPU
  multi-tile reduction/row boundaries with padded K/N.

## YOLO numerical comparison and intermediate diagnostics

The CPU numerical contract is LiteRT `BUILTIN_REF` with double rounding
(`TFLITE_SINGLE_ROUNDING=0`). Default PC LiteRT may use XNNPACK and produce
different INT8 rounding. Disabling delegates alone still selects optimized
builtin kernels; use `BUILTIN_REF` for byte-exact comparison.

With `tflite_diag on`, `tflite_run YOLO.TFL cpu` emits `TensorTrace` for every
operator output before Arena reuse (zero-based operator/tensor id, type, byte
count and full-tensor FNV1a32). Operators 0, 3, 4, 5 and 288 also emit the
first 16 values. FLOAT32 shell values use six significant digits; compare raw
bytes or hashes for exactness. Diagnostics add UART and hashing time to the
reported inference time; `tflite_diag off` disables the observer.

From the repository root, with Python containing `ai-edge-litert` and NumPy:

```bash
python PSC-ONE/software/os/tests/tflite/yolo_reference.py --model /path/to/YOLO.TFL --build build/yolo-ref --resolver reference
python3 PSC-ONE/software/os/tests/tflite/yolo_run.py --model /path/to/YOLO.TFL --build build/yolo-host --reference build/yolo-ref --dump build/yolo-psc
python3 PSC-ONE/software/os/tests/tflite/yolo_compare.py --reference build/yolo-ref --actual build/yolo-psc
python3 PSC-ONE/software/os/tests/tflite/yolo_compare.py --reference build/yolo-ref --uart /path/to/single-invoke-uart.log
```

The host runner checks every intermediate byte, reports mismatches, finishes
the graph and exits nonzero if any output differs. `yolo_compare.py` accepts
another reference directory or PSC binary dumps; UART comparison is hash-only.
Binary comparisons also report MAE, maximum absolute error and differing
element counts for every tensor and the final output. FLOAT32 is decoded from
little-endian bytes; INT8/INT32 errors are in integer code units. Missing or
truncated tensors and non-finite values cannot be reported as zero error.
The exit status still checks exact bytes, not an assumed accuracy tolerance.
Use `--json path/to/comparison.json` to retain the complete numerical report.
UART hashes alone cannot establish MAE or obtain the 44,100 output values;
hardware accuracy measurements require a complete raw tensor dump.
It rejects missing or duplicate records. `reference.json` records model/input
SHA-256, LiteRT version, resolver, quantization metadata, hashes and first values.

`--resolver builtin` and `--resolver xnnpack` reproduce optimized backend
differences. XNNPACK diagnostics require a LiteRT build capable of preserving
delegated intermediate tensors (verified with 2.3.0); unavailable tensors fail
explicitly. Use `yolo_rounding.py --reference build/yolo-ref --xnnpack
build/yolo-xnnpack` to reproduce the zero-input Operator 9 rounding analysis.
See the [numerical diagnosis report](../../../../../../report/psc-os-yolo-numerics-20261025.md).

[PSC-ONE](../../../../../README.md) · [Documentation](../../../../../docs/README.md)

Phase 4 selectable CPU/SynapEngine backends and measured comparison: [PHASE4.md](PHASE4.md).

Historical Phase 3 CPU inference, API, tests and measurements: [PHASE3.md](PHASE3.md).

The following records the Phase 0–2 inspector and its historical measurements.

<!-- contents -->
- [Shell usage](#shell-usage)
- [Ownership and memory](#ownership-and-memory)
- [Dependencies and build changes](#dependencies-and-build-changes)
- [Reproducible checks](#reproducible-checks)
<!-- /contents -->

## Shell usage

Put `MODEL.TFL` in the SD card FAT32 root directory, then run:

```text
PSC_OS> tflite_info MODEL.TFL
```

This command reads and verifies the model and prints the schema version,
SubGraph input/output indices, Tensor names/types/shapes/buffer indices,
quantization arrays, Operator codes/versions/inputs/outputs, and FC fused
activation. **It does not perform inference.** `Profile compatible` means the
model passes the initial FC profile checks, not that prepare (including arena and accumulator bounds) has succeeded.

The filename uses the existing FAT32 reader's uppercase 8.3 subset: `.TFL` is
an SD-compatible filename for the unchanged `.tflite` bytes. Paths, lowercase
names and long extensions are not supported by this reader.

Limits for this first profile:

- Model length 8–4194304 bytes, one SubGraph, one input and one output.
- At most 32 Tensors, 8 Operators/opcodes, 64 Buffers, rank 1–4.
- Positive fixed dimensions, at most 4194304 elements per Tensor; any supplied
  shape_signature must exactly match shape. Dynamic shape is rejected.
- FC builtin version 4, dense INT8 activations/weights, optional INT32 bias
  (`-1` in the third input slot), batch 1 and rank-2 FC input/output.
- FC `DEFAULT` weight format, `NONE` or `RELU` fused activation. No keep_num_dims,
  asymmetric_quantize_inputs, custom options, external/sparse/variable Tensors.
- Per-tensor affine quantization with a positive finite **normal** float32
  scale. Weight zero_point is 0 and weight -128 is excluded. INT8 activation
  zero_point may be -128..127; INT32 bias zero_point must be 0.
- Bias scale must agree with input_scale*weight_scale within 2 float32 ULPs.
  The check uses integer mantissa/exponent arithmetic. Per-axis arrays are
  displayed (up to 64 entries) but rejected by the initial execution profile.

The FlatBuffers verifier is bounded to depth 16 and 512 tables. Structural
verification precedes pointer access. Semantic checks include buffer lengths,
indices, shape products, constant weights/bias, producer order, duplicate
outputs and quantization consistency. Unsupported operations are not skipped
or silently executed using a different interpretation.

Scale output is exact and does not require printf float support:

```text
quant[0] scale=8388608*2^-26 float32=0x3e000000 zero_point=-3 quantized_dimension=0
```

This means scale `0.125`. `float32` is the IEEE-754 raw encoding, not an address.
Names are limited to 48 printable ASCII characters to bound console output.

## Ownership and memory

As of 2026-10-25, the model buffer is independent of the 4096-byte Tensor Arena.
`psc_tflite_arena_required()` reports the complete allocation plan for supported
FC graphs; unsupported graphs have no arena plan. Arena exhaustion returns -210,
model size overflow -200, and unsupported operators/profile -202. Large YOLO
FlatBuffers can be loaded and verified, but YOLO operators are not implemented.
The backing pages preserve the retained USER.MEM image for warm restart.
See [the memory map and validation report](../../../../../../report/psc-os-tflite-large-model-20261025.md).

The section-size measurements below describe the original Phase 0 build.


`tflite_inspect.h` exposes a C ABI. `psc_tflite_inspect_file()` uses the real
`fat32_open/stream_read/close` implementation and an aligned, reserved 4 MiB model
buffer (Sv32 VA 0x00800000 on PSC, separate from the shell BSS/page pool). It closes the file and clears busy state on every outcome. Calls are
synchronous and non-reentrant; callbacks must not longjmp out of inspection.
No model pointer survives the call. Output summaries are zeroed on errors.

`psc_tflite_inspect()` also accepts caller-owned, immutable, 16-byte aligned
memory and an optional text callback. The C++ parser does not include the
C-only `user.h` or PSC MicroPython libc shims.

No tensor arena, interpreter, inference kernel, Python object, NPU buffer or
NPU syscall is added in these phases. Printed nonconstant bytes are a raw sum,
**not** a tensor arena requirement. Buffer data bytes include all serialized
Buffer data, including metadata if present; weights are not copied separately.

Measured with Clang/RV32IM, normal shell including MicroPython:

| Section | Before | Phase 0–2 | Delta |
|---|---:|---:|---:|
| shell text + read-only data | 258980 B | 308908 B | +49928 B |
| shell data | 16 B | 16 B | 0 |
| shell BSS | 277704 B | 285920 B | +8216 B |

The shell image is 594848 B (598016 B rounded to pages). Kernel page pool is
831488 B. After the shell copy, a separate 128 KiB stack, and the existing
32 KiB page-table budget, **69632 B remain**. The user-VA and kernel page-pool
linker assertions both pass. The kernel itself has unchanged section sizes.
These are link-time budgets, not runtime peak measurements. Static BSS is also
materialized in the shell load image by the existing build flow.

The object has only `memcmp`, `memcpy`, `memset`, `strncmp` undefined references
on RV32IM. A separate pure RV32I link also passes using the RV32I libc/libgcc.
No libstdc++, malloc, exception runtime or soft-float dependency is linked into
the inspector. libstdc++ headers are needed for parsing upstream declarations;
they are compiled without `-ffreestanding` because GCC 14's string declarations
reject that mode, but with `-fno-builtin`, `-nostdlib`, no exceptions and no RTTI.

## Dependencies and build changes

Dependencies are **vendored, not submodules**. See
[`../../../third_party/tflite/README.md`](../../../third_party/tflite/README.md) and its
manifest for immutable source versions and SHA-256 checks. Normal builds do
not access the network or run Git. No upstream source patch is applied.

`software/os/Makefile` adds a separately compiled C++17 inspection object and
the C file adapter only to the full user shell. The minimal simulation shell
does not link this object. The full shell depends on both new source/header
files and the vendor headers; the kernel already depends on shell.bin so its
physical-memory assertion accounts for growth. Existing clean targets and
memory-map/linker scripts are unchanged. C++ header paths are configurable via
`TFLITE_CXX_ROOT`; the default follows installed RISC-V GCC's version.

## Reproducible checks

Run from the repository root; these commands do not delete existing builds:

```sh
python3 PSC-ONE/software/os/tests/tflite/check_vendor.py
python3 PSC-ONE/software/os/tests/tflite/run.py --build /tmp/psc-tflite-host
python3 PSC-ONE/software/os/tests/tflite/phase0_check.py \
  --build /tmp/psc-tflite-phase0-check --firmware /tmp/psc-tflite-phase02
myenv/bin/python PSC-ONE/software/os/tests/tflite/rtl_run.py \
  --build /tmp/psc-tflite-rtl --model /tmp/psc-tflite-host/MODEL.TFL
```

Host tests use the official schema builder to produce a synthetic **untrained**
16→16→4 FC fixture, then verify expected metadata and malformed variants with
ASan/UBSan/LeakSanitizer. They link the production FAT32 reader against a
sector-level disk fixture with fragmented clusters. Products include
`MODEL.TFL` and `model_info.txt`; no TensorFlow Python installation is needed.
The sanitizer process must run outside ptrace-based sandboxes for LeakSanitizer.

The RTL runner uses CPU v1, the full PSC-OS/MicroPython shell, UART commands,
and the existing SPI SD model. A test-only copy of the top increases the SD
model's sector store to 32 so the fixture can be injected; production RTL is
not edited. Firmware, simulator and ROM files are isolated under `--build`.
It does not invoke `simulate_PSCOS`, whose current recipe contains clean calls.
PSCOS_SIM boots directly from bootrom/kernel/user ROMs; the current FAT32
bootloader is supplied only for the otherwise unused bootloader ROM initializer.

The legacy `bootloader.c` build was found to fail on an existing undefined
`PSC_SD_ADDR`; it is not used by this path and was not modified.

Validation results for this implementation:

| Check | Result |
|---|---|
| Vendored SHA-256 (35 upstream files) | PASS |
| Host ASan/UBSan/LeakSanitizer, 3628 checks | PASS |
| Full PSC-OS shell/kernel build and page-budget assertions | PASS |
| Minimal shell build (no TFLite object) | PASS |
| Pure RV32I reader link without libstdc++/heap | PASS |
| CPU v1 RTL: boot, UART, fragmented FAT32, Tensor/Operator/quantization display, missing file, return to prompt | PASS |
| `git diff --check` | PASS |

The final RTL run took 2.37700272 simulated seconds (about 17 minutes wall time
on this environment). The full boot dominates the test. An initial 1-second
boot timeout and an overly short 20-microsecond UART character interval were
test-harness failures, corrected to 3 seconds and the existing OS test's 2 ms
interval. The parser/FAT32 acceptance assertions were retained. The runner
checks the JUnit XML as well as the simulator process exit status. Failed-run
logs were preserved under the isolated build directory; no clean was invoked.
Actual FPGA/physical SD-card operation has not been tested in this session.

Phase 3 remains a separate task: integrate the official integer FC/reference
requantization kernels, allocate an arena, and compare layer outputs. Phase
0–2 makes no claim that an inference kernel has already been ported or measured.

Automatic CPU/NPU/PULP dispatch, batched FC, diagnostics and validation: [AUTO.md](AUTO.md).

## CPU operator graphs (2026-10-25)

The C reference kernels support INT8 CONV_2D, ADD, MUL, LOGISTIC and MAX_POOL_2D,
plus the existing FULLY_CONNECTED runtime. Mixed graphs use CPU only; the existing
FC-only CPU/PULP/Synap/AUTO path remains available. The graph parser uses the
pinned Schema v3 verifier, then validates tensor storage, quantization, producer
order and each operator's options before publishing input/output pointers.

- CONV_2D: NHWC/OHWI, stride 1/2, SAME/VALID, positive dilation, optional INT32
  bias, symmetric per-tensor/per-output-channel weights; checked INT32 bounds.
- ADD/MUL: up to four dimensions including scalar, right-aligned broadcasting,
  distinct input/output scales and zero points, double-rounding requantization.
- LOGISTIC: all INT8 codes use an Arena-resident 256-byte LUT generated with the
  pinned gemmlowp Q4 sigmoid; output scale 1/256 and zero point -128 required.
- MAX_POOL_2D: NHWC, positive filter/stride, SAME/VALID; input/output quantization
  must match. Fused NONE, RELU, RELU6 and RELU_N1_TO_1 are supported where applicable.

Execution is bounded to 32 tensors, 8 operators, one input/output, static shapes,
INT8 activations and the independent 4096-byte Arena. Unsupported types/options,
dynamic tensors and unprovable accumulator bounds return errors. These limits
are deliberate: they are not a claim that the full YOLO graph can execute.
Intermediate storage is first-fit allocated by lifetimes, aligned to four bytes;
inputs are retained for repeated invokes and outputs remain live through return.
Parameters/LUTs are allocated separately after activation storage.

`tflite_info YOLO.TFL` structurally analyzes up to 1024 tensors/operators/buffers,
including unsupported operators. It reports model/load size, out-of-line buffer
count, maximum nonconstant tensor, activation lifetime lower bound, available
Arena and operator support. `tflite_diag on|off` controls detailed operator and
load-progress logs. Unsupported-graph estimates exclude unimplemented operators'
scratch/parameters; they are not exact execution allocation requirements.

Schema v3 Buffer `offset > 1` refers to data in the same loaded file. The parser
validates 64-bit offset/size using subtraction before pointer arithmetic and
rejects conflicting inline data, truncation and overflow. Separate external-file
ExternalBuffer groups are still unsupported. No additional SD reads are needed.

Tests (host ASan/UBSan, unmodified pinned upstream reference kernels):

```sh
python3 PSC-ONE/software/os/tests/tflite/operators.py --build /tmp/psc-operators \
  --yolo /path/to/YOLO.TFL
python3 PSC-ONE/software/os/tests/tflite/run.py --build /tmp/psc-fc-regression
```

The operator runner writes CNN.TFL, OUTCNN.TFL (out-of-line constants), BAD.TFL,
CNN.shell-output and optional YOLO tensor/operator/buffer CSV inventories.
`native_ops.py` drives real UART/FAT32/kernel/Sv32 on an existing, unchanged
CPU-v1 Verilator model built by `rtl_run.py`; it checks FC, mixed CNN, out-of-line
CNN, safe errors and warm restart. Pass `--build`, `--firmware` (MODE=sim),
`--rtl-build`, `--fixtures` and `--model`. This SPI-bypass simulation does not
measure physical SD performance or constitute FPGA verification.

## Phase 2 reproducible reference tests

`tests/tflite/yolo_reference.py` uses ai-edge-litert 2.3.0 BUILTIN_REF with all
intermediates preserved. `yolo_run.py` builds the actual C/C++ runtime with
ASan/UBSan; its tensor callback compares every produced tensor before reuse.
`phase2_ops.py` supplies 111 unit/negative/integration fixtures for the ten new
operators. Reference tools require NumPy, FlatBuffers and ai-edge-litert in an
isolated Python environment; the firmware itself has no such dependencies.

`native_ops.py` additionally requires `--phase2` pointing at those fixture
outputs. It covers TENOPS.TFL and ARENA.TFL (760000 bytes) on the PSC CPU.
The optional `qemu_yolo.py` harness links in an 8MiB budget, but its execution
was not completed in this session; do not treat it as a recorded QEMU PASS.
