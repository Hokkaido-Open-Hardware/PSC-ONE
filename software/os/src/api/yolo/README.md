# YOLO JPEG detection (CPU / PULP / NPU / AUTO, UART + LCD)

```text
yolo_backend cpu
yolo YOLO.TFL TEST.JPG
yolo YOLO.TFL TEST2.JPG
```

Select a persistent preference with `yolo_backend cpu|pulp|npu|auto`; omit
its argument to show the current setting. The boot default is `cpu`.
Use two commands so two maximum-length 8.3 filenames still fit the shell's
31-character line. The preference survives model loads, errors and unrelated
`tflite_run` commands; it is reapplied **after** load/prepare resets runtime
options. `psc_yolo_set_backend()` exposes the same application preference.

All modes share JPEG preprocessing, class-wise NMS and LCD rendering.
On this model, enabled PULP executes 64 INT8 Conv operators using existing
`cv.dotsp.b`; NPU executes those 64 using existing SynapEngine tiled GEMM.
The other 225 operators use CPU. AUTO keeps the existing conservative policy:
Conv prefers PULP; only calibrated legacy FC shapes prefer NPU. Unsupported
shapes or unavailable build/platform capabilities use CPU. This command does
not add kernels or enable instructions that the selected CPU does not support.
An NPU-less FPGA requires an OS built with `TFLITE_HAS_SYNAP=0`.

Logs distinguish `requested` from completed `CPU/PULP/NPU` operator counts,
aggregate fallback reasons, and successful NPU tile calls. A successful YOLO
NPU run uses 10,642 tile calls at the existing default tile=32. These counts
are software observations of successful driver returns, not an independent
hardware cycle counter. `yolo_diag on` additionally emits all 289 intermediate
output hashes before arena reuse and per-operator backend/time/tile diagnostics.
`yolo_diag off` is the default and is recommended for timing. This setting is
independent of `tflite_diag`. Compare captured UART with
`tests/tflite/yolo_compare.py --reference REF --uart LOG`; hashes alone are
not full numerical error measurements.

`invoke_wall` measures the complete invoke, including progress/optional trace
UART, separately from load+prepare, JPEG preprocessing, NMS and LCD. The CPU,
PULP and NPU operator time sums exclude callbacks and are **only the work done
by that backend in this invocation**. In particular the CPU fallback sum is
not the CPU-only full-model baseline. NPU operator time includes packing,
syscall/copies, device execution and requantization. Do not add it to wall time.
All timers report -1 if unavailable/overflow; host mock clocks are synthetic.

Before a shell run, the LCD is cleared using the existing bounded RGB tile
path; its time is reported separately. If clearing fails, inference does not
start and UART warns that the old physical screen may remain. On inference
failure, the runtime output and saved detections are invalidated and neither
NMS detections nor overlays are published. Started NPU errors abort without
CPU retry; the existing driver handles timeout reset. Failure diagnostics are
printed before the runtime is reset. The inference-only C API never touches LCD.

Load the model and a baseline JPEG from the FAT32 root. Names must use the
existing uppercase 8.3 convention. The command fits the 31-character shell
line even with two maximum-length names. Each command reloads the model;
it does not depend on a preceding `tflite_run` or `tflite_diag` setting.
The JPEG filename and bounded header are checked before model loading.
This preflight does not validate entropy/EOI; the full decode still must pass.

This is the fixed YOLOv8n COCO80 profile tested with the files in
`PSC-ONE/hardware/sim/sdcard/sdcard_file/`. Model SHA-256:
`0e4519d74b60ecfae07eb52f4d5734bfcf6f1d39e08be64518526db847af18f9`.
The command validates FLOAT32 `[1,3,160,160]` input, FLOAT32 `[1,84,525]`
output and 289 operators. It assumes this profile's normalized xywh and
COCO class ordering; shape validation does not establish compatibility with
an arbitrary different model. Model changes require updating and rerunning
the profile tests, not only renaming a file to YOLO.TFL.

The JPEG restrictions remain unchanged: width <= 480, height <= 320,
baseline only, existing supported sampling/component formats, no EXIF
rotation. The decoder streams RGB888; no RGB565 conversion or full-frame
allocation is used. `psc_yolo_run` remains inference-only; `cmd_yolo` prints
the UART results and then calls `yolo_display` with the retained result.

Preprocessing is centered 160x160 letterbox with padding RGB=114, aspect
ratio preserved, upscaling allowed, RGB/255.0f, contiguous CHW. Resize
dimensions use rational ties-to-even rounding, at least one pixel. Pixels
use half-pixel bilinear sampling with exact rational integer weights, edge
clamping and uint8 half-up rounding before FLOAT32 division. This makes the
PC oracle and RV32 implementation deterministic; it is not a claim of
byte equality with OpenCV INTER_LINEAR's coefficient rounding. For the two
SD images, comparison on the same decoded RGB differs from OpenCV by at
most one RGB level. TJpgDec/OpenCV JPEG decoding can also differ.

480x320 -> 160x107, left/top/right/bottom padding = 0/26/0/27. A 17-row
RGB buffer preserves bilinear samples across MCU boundaries and writes
directly to the existing 307,200-byte input tensor. All callbacks must
finish, including the JPEG EOI check, before inference begins.

Postprocessing interprets `output[channel*525+anchor]`. Coordinates are
normalized cx/cy/w/h and are multiplied by 160. Class scores already have
sigmoid applied; there is no additional objectness. Each anchor contributes
its highest scoring class when score > 0.25. Stable descending-score order
uses ascending anchor ID for ties, and ascending class ID for class ties.
NMS suppresses same-class boxes only when continuous-coordinate IoU > 0.45.
It runs before clipping, with no area `+1`. Nonfinite/invalid candidates are
excluded. Boxes are restored using the saved padding and scale, clipped to
the original image, and at most 50 visible detections are returned. Candidate,
NMS, visible and truncation counts are printed.

`score_milli` is score x1000 rounded to the nearest integer.
`xyxy_milli` is original-image continuous pixel coordinates x1000, also
rounded. For example, `60971` means 60.971 pixels, not 60,971 pixels.
The UART prints input/output FNV1a32 hashes and progress every 25 operators.
`invoke_wall` includes progress UART. Times of -1 mean unavailable. Host
test timer values are synthetic, not measured inference performance.

After NMS, the same JPEG is decoded again at the top-left, at native size.
Yellow two-pixel boxes and white 12x12 bitmap labels on a dark background
are sent through the existing <=16x16 RGB888 rectangles. A 768-byte static
tile is the only added mutable image workspace. The LCD begin call resets
landscape orientation and scrolling; portrait text drawing is not used.
Continuous box coordinates become inclusive raster coordinates by
floor(start), ceil(end)-1 after clipping. Thus x2=480/y2=320 draw at 479/319.
Labels show one-decimal percentages; long names are truncated with ellipsis,
and the entire label is shifted within the 480x320 screen. Frames are drawn
before labels. Dense overlapping labels are not rearranged in this version.

`YOLO LCD us: jpeg_overlay=...` times only JPEG redisplay plus overlays.
An LCD/reload failure prints `YOLO LCD error ...; inference results retained`,
distinct from `YOLO error` during inference. A failed redisplay may leave a
partial image, but no overlays are drawn until full JPEG decoding succeeds.
Changed image dimensions are rejected. Keep the SD file unchanged during
inference: same-size content changes cannot be detected by a header check.

All new workspaces are static and the API is synchronous/non-reentrant.
The model and arena have separate existing mappings. On a run failure the
result is cleared, inference state is reset after load/decode/invoke failures,
and no prior detections are printed. The generic JPEG sink's begin/rect
callbacks may run before a later EOF/SD error; clients must commit only after
`jpeg_decode_rgb` returns success. RGB pointers expire on callback return.

Validation commands (from repository root; Python must have numpy, OpenCV,
Pillow and ai-edge-litert installed):

```sh
/home/haruhiko/Program/YOLOv8/myenv/bin/python -B \
  PSC-ONE/software/os/tests/yolo/run.py --build build/yolo-lcd-20261026/host
/home/haruhiko/Program/YOLOv8/myenv/bin/python -B \
  PSC-ONE/software/os/tests/yolo/run.py --build build/yolo-lcd-20261026/replay --display-only
python3 -B PSC-ONE/software/os/tests/yolo/memory_audit.py \
  --firmware build/yolo-lcd-20261026/firmware \
  --build build/yolo-lcd-20261026/memory-audit
```

`tests/yolo/golden.json` records independently validated input/output hashes
and detections; the runner never updates it automatically. Tests compare
full inputs and all 289 intermediate outputs, not only hashes, and use an
independent Python NMS implementation. Production FAT32 and JPEG code are
linked with host SD/LCD boundaries; the CPU runtime is not mocked. NPU calls
must stay zero; the inference API makes no LCD calls. `--display-only` replays
saved detections without invoking the model, creates `display/*/preview.png`,
and checks clipping, long labels, zero detections and error recovery.
Tests require ASan/UBSan/LSan; run in
an environment without ptrace restrictions rather than disabling sanitizers.

Larger JPEGs, configurable thresholds, PULP/NPU acceleration
and physical-board performance validation are subsequent work.


Mixed real-image validation (host PULP arithmetic emulation / NPU mock):

```sh
/home/haruhiko/Program/YOLOv8/myenv/bin/python -B PSC-ONE/software/os/tests/yolo/run.py --build build/yolo-image-backends-20261026/host --mixed
```

This compares two JPEGs across all four modes, all intermediate tensor bytes,
full final output, NMS, UART hashes, backend/tile counts and failure recovery.
Hardware evidence and SD artifacts are recorded in
[the backend connection report](../../../../../../report/psc-os-yolo-image-backends-20261026.md).
