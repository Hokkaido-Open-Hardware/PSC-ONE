# TFLite dependencies: vendor, not submodule

This directory contains **vendored, unmodified upstream files**. It is not a
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
`flatbuffers/LICENSE` and `gemmlowp/LICENSE`. Local patches: none.

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
`src/tflite/tflite_quant.cc`; a partial link discards all functions except the
two helper entry points and their dependencies. `TFLITE_SINGLE_ROUNDING=0` is
explicit on host and target. Upstream checks remain active; the target adapter
maps their abort action to a trap rather than importing an OS abort function.

The integer FC reference header runs on the host only. `generate_model.py`
creates a tracing copy in its build directory by adding one observer call and
changing the namespace/include guard. The original, unmodified FC kernel also
runs and must produce the same output. This generated test copy is not a vendor
patch; all 56 upstream files remain byte-identical to the manifest.
