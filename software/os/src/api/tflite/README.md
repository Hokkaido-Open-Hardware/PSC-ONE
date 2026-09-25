# PSC-OS TFLite

Phase 4 selectable CPU/SynapEngine backends and measured comparison: [PHASE4.md](PHASE4.md).

Historical Phase 3 CPU inference, API, tests and measurements: [PHASE3.md](PHASE3.md).

The following records the Phase 0–2 inspector and its historical measurements.

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

- Model length 8–8192 bytes, one SubGraph, one input and one output.
- At most 32 Tensors, 8 Operators/opcodes, 64 Buffers, rank 1–4.
- Positive fixed dimensions, at most 8192 elements per Tensor; any supplied
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

`tflite_inspect.h` exposes a C ABI. `psc_tflite_inspect_file()` uses the real
`fat32_open/stream_read/close` implementation and an aligned, static 8 KiB model
buffer. It closes the file and clears busy state on every outcome. Calls are
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
OS_SIM boots directly from bootrom/kernel/user ROMs; the current FAT32
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
