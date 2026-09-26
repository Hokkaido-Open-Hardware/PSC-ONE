# TFLite dependencies: vendor, not submodule

[PSC-ONE](../../../../README.md) · [Documentation](../../../../docs/README.md)

The upstream subtrees contain **vendored, unmodified upstream files**; `psc/`
contains separately identified PSC-owned backend and validation code. This is not a
Git submodule and does not add entries to `.gitmodules`. Normal builds are
offline: they never clone, download, regenerate, or automatically update these
files. Phase 3 adds the official integer helpers and a host reference kernel; the full
TFLM interpreter is not included.

| Component | Fixed source | Included files |
|---|---|---|
| TFLite Micro | `d0318206cf438df7d60708b49559777225ebacda` | schema, common/quantization_util, integer FC reference and dependency headers; root license |
| gemmlowp | `719139ce755a0f31cbf1c37f7f98adcc7fc9f425` (specified by the pinned TFLM) | fixedpoint headers, platform detection, license |
| FlatBuffers | `v25.9.23`, commit `187240970746d00bbd26b0f5873ed54d2477f9f3` | upstream `include/flatbuffers/` header tree, root license |

The generated schema asserts FlatBuffers **25.9.23** at compile time. We use the
official accessor/Verifier API on target, and its builder API only in host tests.
The header tree contains builder/reflection/tool declarations too; these do not
imply that their implementations or a FlatBuffers runtime library are linked.
All three components have Apache-2.0 root licenses; see `LICENSE.tflm`,
`flatbuffers/LICENSE` and `gemmlowp/LICENSE`. Upstream patches: none.

<!-- contents -->
- [Acquisition and exact verification](#acquisition-and-exact-verification)
- [Phase 3 additions](#phase-3-additions)
- [PSC INT8 PULP FC backend (2026-09-22)](#psc-int8-pulp-fc-backend-2026-09-22)
<!-- /contents -->

## Acquisition and exact verification

`manifest.json` records the exact download URLs, commits, original archive
SHA-256, and SHA-256 of **each** vendored file. Acquisition for this change was:

1. Download the generated header and license from the pinned TFLM commit URLs.
2. Download the FlatBuffers archive URL in the manifest; verify its SHA-256.
3. Extract only `include/flatbuffers/` and `LICENSE` from that archive, retaining
   the original bytes. Copy the TFLM license as `LICENSE.tflm`.
4. Verify all extracted files against `files_sha256` in the manifest.

The archive uses a version-tag URL, but **the SHA-256 is mandatory**: a retagged
or changed archive is rejected rather than silently replacing the pinned source.
Do not run upstream download scripts: they perform unrelated Git/patch actions.

From the repository root:

```sh
python3 PSC-ONE/software/os/tests/tflite/check_vendor.py
```

The PSC-OS C++ object build and the host test runner execute this local check.
It rejects missing, changed, and unexpected vendored files. README and manifest
are local provenance records, not upstream content.

Updating requires a deliberate source change: select a TFLM commit, match the
FlatBuffers version required by its generated header, update vendored files and
manifest together, review the schema/API diff, then rerun parser/FAT32 tests and
RV32 memory/link checks. Never follow `main` during a build. Git staging or
committing remains a separate, explicitly authorized action.

## Phase 3 additions

The original TFLM and FlatBuffers pins are unchanged. The manifest records the
TFLM commit archive and gemmlowp commit archive URLs and SHA-256. Copy only the
listed `tflite_micro.scope` files and gemmlowp scope, preserving upstream bytes.
The target includes `common.cc` and `quantization_util.cc` through
`src/api/tflite/tflite_quant.cc`; a partial link discards all functions except the
two helper entry points and their dependencies. `TFLITE_SINGLE_ROUNDING=0` is
explicit on host and target. Upstream checks remain active; the target adapter
maps their abort action to a trap rather than importing an OS abort function.

The integer FC reference header runs on the host only. `generate_model.py`
creates a tracing copy in its build directory by adding one observer call and
changing the namespace/include guard. The original, unmodified FC kernel also
runs and must produce the same output. This generated test copy is not a vendor
patch; all 56 upstream files remain byte-identical to the manifest.

## PSC INT8 PULP FC backend (2026-09-22)

**Integration status:** `psc/pulp_fc.h` is connected to the production runtime
through `src/api/tflite/tflite_api.h` and `src/api/tflite/tflite_runtime.cc`. These two
files were changed with explicit user authorization to extend the original
scope. `psc/runtime-integration.patch` is retained as a record of that already
applied change; do not apply it again. The test runners now compile the actual
repository sources. No RTL, CLI, Makefile or other external source was changed.
The C API can select PULP; CLI parsing and target build opt-in remain separate.

### Runtime investigation and arithmetic

The upstream `reference/integer_ops/fully_connected.h` is a host oracle, not the
PSC target kernel. Target execution is the small, synchronous, non-reentrant
runtime in `src/api/tflite/`, not a full TFLM interpreter. The existing enum is
`psc_tflite_fc_backend`: CPU=0, Synap=1. The patch preserves these values and
adds `PSC_TFLITE_FC_PULP=2`; setter signature, reset behavior, busy protection,
output invalidation, tile API, scalar code and Synap code are retained.

The resident profile accepts batch=1, INT8 input/weights/output, optional INT32
bias, per-tensor quantization, NONE/RELU and constant symmetric weights. Its
inspector rejects nonzero weight zero points, weight -128, other tensor types,
invalid metadata/shapes and unsupported activations before prepare completes.
The model size / tensor element limit is 8192; the arena is 4096 bytes. There
was no implicit fallback in the old API: Synap device errors remain errors.

For each output channel the unchanged target processing is:

1. `int32_t raw = sum(int32_t(x[k]) * w[k])`, initially zero.
2. `corrected = int32_t(int64_t(raw) - int64_t(input_zero) * row_sum[c])`.
3. `biased = int32_t(int64_t(corrected) + bias[c])`, with missing bias = 0.
4. `q = psc_tflite_requantize(biased, multiplier, shift) + output_zero`.
5. Clamp to `[minimum,127]`, where minimum is -128 or the ReLU output zero point.

The quantizer remains the pinned upstream `MultiplyByQuantizedMultiplier`, with
`TFLITE_SINGLE_ROUNDING=0`: left shift, saturating rounding high multiply, then
rounding division by a power of two. Its negative rounding behavior is unchanged.
Bias remains AFTER zero-point correction. The existing prepare step calculates
INT32 row sums in the arena and proves the biased/shifted accumulator range for
all INT8 inputs. There is no new workspace or invoke-time allocation.

`raw` partial sums have absolute bound `8192 * 16384 = 134217728`, including
-128 in the standalone primitive. Corrected sums are bounded by
`8192 * 255 * 128 = 267386880`. Thus regrouping four products cannot introduce
signed overflow; the existing prepare proof covers bias and requantization.
No wrapping, saturation or rounding rule was added. Zero-point correction is
performed once, using the original row sum; it is not folded into the PULP dot.

### Instruction, loads and fallback

Only **`cv.dotsp.b`**, encoded by
`.insn r 0x7b, 1, 0x48, rd, rs1, rs2`, is used. Four signed byte products produce
one INT32 result; ordinary C++ addition adds that result to the accumulator.
The final 1–3 elements use the scalar multiplication loop. No accumulating SIMD
instruction is used.

The arena base is aligned to 16 and its allocations to four bytes. Weight bytes
remain in the borrowed FlatBuffer. Their INT8 type alone does not guarantee word
alignment, and a row stride not divisible by four can unalign subsequent rows.
Both addresses are checked once per row. For aligned rows, four-byte builtin
`memcpy` plus `__builtin_assume_aligned` gives two `lw` instructions, without
type punning. Otherwise builtin `memcpy` produces safe byte loads and shifts.
The loop only loads a word when four bytes remain. This is safe with strict
aliasing and `-mstrict-align`.

`try_dot` returns false without changing its result for unavailable instructions,
non-INT8 metadata, nonzero weight zero point, null pointers, `k<4`, or `k>8192`.
Callers must supply validated shapes and readable `k`-byte buffers. The runtime
patch calls it only after the existing inspector/prepare has validated the
model; false executes the original scalar loop. PULP never calls Synap or uses
its MMIO/DMA/tile configuration.

**Profile limitation:** unsupported types, nonzero weight zero points and
malformed tensors already fail in the scalar runtime's prepare step. They still
return the same errors, rather than becoming runnable via fallback. The raw-dot
primitive's rejection of these conditions is tested, but a successful general
asymmetric-weight scalar FC fallback cannot be provided by this existing runtime
without extending external inspector/scalar code. Weight -128 is tested in the
primitive; its existing model-level rejection is preserved.

### Backend selection

The API/runtime connection is already applied. Compile `tflite_runtime.cc` with
`-DPSC_HAS_CV_DOTSP_B=1` on a supporting RV32 CPU. The default is 0, including generic RV32IM builds. Header inclusion alone
never enables an unsupported instruction. The host-only test macro
`PSC_PULP_TEST_EMULATE` is not a target capability switch.

```cpp
psc_tflite_set_fc_backend(PSC_TFLITE_FC_CPU);   // existing scalar
psc_tflite_set_fc_backend(PSC_TFLITE_FC_PULP);  // new; scalar fallback if disabled
psc_tflite_set_fc_backend(PSC_TFLITE_FC_SYNAP); // existing NPU
psc_tflite_set_synap_tile_size(8);             // only affects Synap
```

Additional external integration, **not performed**:

* `src/shell/shell.c`: recognize `pulp` beside `cpu`/`npu`, update command help.
* `src/api/tflite/tflite_file.c`: label PULP output and add it to `tflite_bench`'s
  CPU/NPU comparison. Existing `tflite_run` and `tflite_bench` are untouched.
* `software/os/Makefile`: arrange the target capability define and add
  `third_party/tflite/psc/pulp_fc.h` to `TFLITE_HEADERS` for incremental rebuilds.
  No new object is needed; the backend is header-only. Do not change clean rules.

### Verification and performance

The existing official TFLM oracle passes unchanged: Phase 3 has 47 cases,
712 channel comparisons and 65,560 quantizer comparisons; Phase 4 has 288
CPU/NPU invocations and 2,880 five-stage channel comparisons, including device
errors. New host tests pass ASan/UBSan/LSan in both disabled and emulated builds:
1,950 invocations and 31,200 five-stage channel comparisons **per build**.
They cover zero/mixed/extreme inputs, both zero-point input cases, bias/no bias,
multiple channels, dimensions 1/2/3 and all four remainder classes, random INT8
data, repeated PULP, and CPU→PULP→NPU→CPU. Three thousand forty-eight SIMD dots
end immediately before a protected page; independent pointer alignments and
depth 8192 are also checked. Allocation wrappers reject malloc/calloc/realloc
and C++ new during invoke. No mismatch is only logged: every failure terminates
the executable or fails the cocotb test.

Full, **unchanged** CPU v1 + legacy Synap RTL also passes. The firmware executes
528 native scalar/PULP dot comparisons across lengths 1–33 and all pointer
alignments, then the actual two-layer model, repeated/backend-switch checks and
all five stages of all 20 channels. Every measured configuration is checked
against scalar and the official demo oracle. All final outputs are
**`[-36,27,18,8]`**. No allocator symbol is linked into the target ELF.

Same ELF, same prepared model/input/arena addresses, 100 MHz, normal SoC caches;
each backend is warmed immediately before each sample. Five samples per mode,
rotating order. The table uses the minimum invoke sample and FC times from that
same sample. Timing uses the existing `psc_tflite_invoke_traced` layer callbacks
and platform clock boundary, without per-channel trace or Synap profiling in
the timed region. Clock resolution is 1 µs; callback overhead is included.

| Item | CPU scalar | CPU PULP | NPU/Synap, fastest tile=8 |
|---|---:|---:|---:|
| invoke, µs | 401 | 257 | 1039 |
| FC1, µs | 287 | 185 | 684 |
| FC2, µs | 89 | 47 | 324 |
| Final output | [-36,27,18,8] | [-36,27,18,8] | [-36,27,18,8] |
| Bit-exact | baseline | PASS | PASS |

PULP invoke is 1.56× as fast (35.9% shorter). NPU invoke minima for tiles
4/8/12/16 are 1107/1039/2063/1416 µs. See `psc/validation.json` for every sample
and all raw/corrected/biased/requantized/clamped channel values.

These are **bare-metal SoC simulation measurements**, using the unchanged
`tflite_synap.cc` and `sa_run_checked` hardware driver. The test platform adapter
calls that driver directly; it does not include PSC-OS syscall/user-copy costs.
The larger inspector firmware is preloaded into existing SDRAM by the testbench;
no RTL or ROM parameters were changed. Results must not be directly compared
with the earlier OS values 966/732/228 µs or NPU 4177 µs. Board/OS measurements
with the new selection remain pending CLI/build integration.

RV32 ELF disassembly verifies `(word & 0xfe00707f)==0x9000107b`: two encodings
in the real invoke's PULP branches (aligned and unaligned), two in the separate
native test wrapper, and none in `audit_scalar`. The existing runtime has a
shared invoke function, not a separate scalar FC symbol; its original scalar
branch remains ordinary byte loads/multiply/add. No `0xa800107b` matching word
occurs anywhere in executable instructions. The aligned inner loop is two
`lw`, `cv.dotsp.b`, ordinary add and four-byte pointer advances, with no function
calls or packing. The unaligned path uses eight byte loads plus shifts/ORs and
may not be faster than scalar for short rows; its performance is not claimed.
A separate RV32 disabled ELF also builds with no dot instruction encodings.

### Reproduction and provenance

From the repository root (all generated binaries/logs remain under `/tmp`):

```sh
python3 PSC-ONE/software/os/third_party/tflite/psc/run_host.py \
  --build /tmp/psc-tflite-pulp-host
myenv/bin/python PSC-ONE/software/os/third_party/tflite/psc/run_target.py \
  --build /tmp/psc-tflite-pulp-target \
  --model /tmp/psc-tflite-pulp-host/baseline/MODEL.TFL
myenv/bin/python PSC-ONE/software/os/third_party/tflite/psc/run_target.py \
  --build /tmp/psc-tflite-pulp-disabled --disable-pulp --build-only \
  --model /tmp/psc-tflite-pulp-host/baseline/MODEL.TFL
python3 PSC-ONE/software/os/tests/tflite/check_vendor.py
```

The runners compile the integrated repository runtime/API directly and write
build artifacts only beneath `--build`. They need the installed RISC-V compiler, Clang, Verilator and repository cocotb
environment; no network/downloads are needed. LSan needs an environment that
permits its process inspection (the restricted sandbox blocked it; the complete
sanitizer run passed outside that sandbox). An initial target link exceeded the
old 64 KiB test layout; the test-only linker layout now uses 128 KiB of existing
SDRAM. Neither issue was resolved by disabling a test.

`manifest.json` retains every original upstream hash, and records PSC source,
patch, test and result files separately under `psc_local`. The existing strict
file-set/checksum checker also checks their hashes through `files_sha256`; its
printed “upstream files” count now includes those local files. No upstream
content was modified, no files were deleted, and no Git staging/commit/push was
performed.
