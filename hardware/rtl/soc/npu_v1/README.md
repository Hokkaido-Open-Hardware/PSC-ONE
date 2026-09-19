# PSC-NPU v1: fixed four-lane streaming MAC

Production datapath:

```text
PSC_NPU_Controller
  └─ PSC_NPU_SystolicArray4x4
       ├─ A/B shift registers (unchanged routing)
       ├─ PSC_NPU_MACScheduler
       ├─ PSC_NPU_Mul4: operand snapshot → four MUL → registered WB
       └─ PSC_NPU_AccBank: sixteen FSM-less accumulators
```

INT8 signed/unsigned operands and 32-bit wrapping accumulators are fixed.
There is no `MUL_NUM` parameter. Lane `n` serves IDs `n, n+4, n+8, n+12`.
Each accumulator connects to one lane only. The destination group, data and
valid are registered together; the ID's low two bits are compile-time lane
constants. No sixteen-entry product holding bank or atomic commit remains.

| Edge relative to accepted start | Action |
|---|---|
| E0 | Accept start, assert busy |
| E1 | Align with the existing input-capture contract |
| E2 | Capture A/B and signed mode |
| E3–E6 | Register WB groups 0–3 |
| E4–E7 | Accumulate WB groups 0–3 |
| E8 | Pulse done, release busy |

ACC clear and start are accepted only while idle; clear has priority. The A/B
shift registers still respond to their enables/clear during a batch, while the
snapshot protects in-flight operands. `ps_acc_out` can change while busy; the
Controller reads it after done. The public Controller ports, CSR/software
format, memory handshakes and Controller done/reset behavior remain unchanged.

`../npu` is the unmodified legacy implementation. It supplies the legacy PE
atomic-commit, 2x2 and one-MUL Controller regression tests. Do not compile both
versions together: their public module names intentionally match, so the CPU
RTL does not need to change.

From `hardware/sim`:

```bash
make -f Makefile.npu validate_streaming NPU_VERSION=v1 SIM_BUILD=/tmp/npu-v1-tests
make -f Makefile.nextpnr.npu timing NPU_VERSION=v1 BUILD_DIR=/tmp/npu-v1-timing
```

`npu_sources.mk` selects `NPU_VERSION=v1` by default; `NPU_VERSION=legacy` selects
the original design. The same selection is used by Makefile.cpu and
Makefile.pscos. `NPU_ASSERTIONS` enables simulation checks for lane/ID ownership,
duplicate destinations and premature clear/done.

See [implementation and measured results](../../../docs/npu_v1_streaming_results.md).
