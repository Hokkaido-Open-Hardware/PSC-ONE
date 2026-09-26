# PSC-ONE PULP instruction extensions

[日本語](cpu_pulp_JP.md) · [Documentation](README.md) · [PSC-ONE](../README.md)

This document specifies the two dot-product instructions implemented by CPU v1
and records their implementation and validation on 2026-09-21. Specification,
recorded measurements and future proposals are separated. PASS results,
performance and resource counts below are historical evidence, not new results
from this documentation update.

<!-- contents -->
- [1. Scope](#1-scope)
- [2. Supported instructions](#2-supported-instructions)
- [3. `cv.dotup.h`](#3-cvdotuph)
- [4. `cv.dotsp.b` (signed byte SIMD)](#4-cvdotspb-signed-byte-simd)
- [5. RTL requirements and common behavior](#5-rtl-requirements-and-common-behavior)
- [6. Reference model](#6-reference-model)
- [7. Required verification](#7-required-verification)
- [8. Software integration](#8-software-integration)
- [9. CPU v1 implementation and SDOTSP removal record](#9-cpu-v1-implementation-and-sdotsp-removal-record)
- [10. Post-removal validation record (2026-09-21)](#10-post-removal-validation-record-2026-09-21)
- [11. NN performance comparison (recorded)](#11-nn-performance-comparison-recorded)
- [12. Synthesis and place-and-route around SDOTSP removal](#12-synthesis-and-place-and-route-around-sdotsp-removal)
- [13. Cost and benefit of the retained extension](#13-cost-and-benefit-of-the-retained-extension)
- [14. Possible future extensions](#14-possible-future-extensions)
- [15. Compatibility and references](#15-compatibility-and-references)
<!-- /contents -->

## 1. Scope

PSC-ONE CPU v1 implements two SIMD dot-product instructions from the PULP/CORE-V
instruction family: `cv.dotup.h` and `cv.dotsp.b`. XLEN is 32 bits.
CPU v2, the legacy CPU and the NPU are outside this extension's scope.
This is not an implementation of the entire PULP instruction set.

## 2. Supported instructions

| Instruction | Status | Operation |
| --- | --- | --- |
| `cv.dotup.h` | Implemented | Two unsigned 16-bit lane products |
| `cv.dotup.sc.h` | Unimplemented / reserved | Replicate the low halfword of `rs2` |
| `cv.dotup.sci.h` | Unimplemented / reserved | Replicate a 6-bit immediate |
| `cv.dotsp.b` | Implemented | Four signed 8-bit lane products |
| `cv.sdotsp.b` | Removed / illegal | Former experimental accumulator variant |
| Other byte forms | Unimplemented / reserved | Including `dotup.b`, `dotusp.b` |
| Other signed/mixed-sign forms | Unimplemented / reserved | Including `.h`, `.sc`, `.sci` forms |
| Other accumulating forms | Unimplemented / reserved | `sdotup`, `sdotusp`, other `sdotsp` forms |

Unsupported encodings raise Illegal Instruction, like other undefined instructions.

## 3. `cv.dotup.h`

### Assembly and operation

```asm
cv.dotup.h rd, rs1, rs2
```

Treat each source as two independent unsigned 16-bit lanes:

```text
a0 = unsigned(rs1[15:0])
a1 = unsigned(rs1[31:16])
b0 = unsigned(rs2[15:0])
b1 = unsigned(rs2[31:16])
sum33 = a0 * b0 + a1 * b1
rd = sum33[31:0]
```

Each product is 32 bits; the sum requires 33 bits. Writeback keeps the low
32 bits (modulo 2^32). There is no saturation, rounding, overflow flag or CSR
update. Writes to `x0` are discarded. Sources are read before writeback, so
`rd=rs1`, `rd=rs2` and `rs1=rs2` are permitted.

### Encoding

| Field | Bits | Value |
| --- | --- | --- |
| `funct7` | 31:25 | `1000000` (`0x40`) |
| `rs2` | 24:20 | Second source |
| `rs1` | 19:15 | First source |
| `funct3` | 14:12 | `000` |
| `rd` | 11:7 | Destination |
| `opcode` | 6:0 | `1111011` (`0x7b`, custom-3) |

```text
MATCH_CV_DOTUP_H = 0x8000007b
MASK_CV_DOTUP_H  = 0xfe00707f
(instruction & MASK_CV_DOTUP_H) == MATCH_CV_DOTUP_H

instruction = 0x8000007b | (rs2 << 20) | (rs1 << 15) | (rd << 7)
```

For assemblers without the mnemonic:

```asm
.insn r 0x7b, 0, 0x40, rd, rs1, rs2
```

## 4. `cv.dotsp.b` (signed byte SIMD)

| Instruction | Status | funct7 | funct3 | opcode | MATCH | MASK |
| --- | --- | --- | --- | --- | --- | --- |
| `cv.dotsp.b` | Implemented | `0x48` | 1 | `0x7b` | `0x9000107b` | `0xfe00707f` |
| `cv.sdotsp.b` | Removed / illegal | `0x54` | 1 | `0x7b` | `0xa800107b` | `0xfe00707f` |

```asm
.insn r 0x7b, 1, 0x48, rd, rs1, rs2  # cv.dotsp.b
```

Each `[8*i +: 8]` lane, for i=0..3, is an independent signed byte in −128..127.
Products are signed 16-bit values, pair sums are 17 bits, and the final sum is
18 bits, with range −65024..65536.

```text
dot = sum(signed8(rs1.byte[i]) * signed8(rs2.byte[i]), i=0..3)
rd = sign_extend_32(dot)
```

There are no cross-lane terms, saturation, rounding or CSR updates. A single
32×32 multiplication does not implement this operation. Register aliases,
including all three registers being equal, use the values before writeback.
`rd=x0` discards the result; an `x0` source supplies zero.

## 5. RTL requirements and common behavior

### Decode

Accept DOTUP.H only when opcode, funct3 and funct7 all match the values above.
DOTSP.B similarly uses a full masked match. Matching custom-3 alone is not
sufficient: unsupported neighboring encodings must trap.

### Datapath

The logical unsigned-halfword datapath is:

```text
mul_lo = {16'b0, rs1[15:0]}  * {16'b0, rs2[15:0]}
mul_hi = {16'b0, rs1[31:16]} * {16'b0, rs2[31:16]}
sum33  = {1'b0, mul_lo} + {1'b0, mul_hi}
result = sum33[31:0]
```

Make widths and signedness explicit in SystemVerilog. Physical multipliers may
be separate or time-shared, provided architectural results match the specification.

### Pipeline control

- Read `rs1` and `rs2`; write `rd` exactly once.
- Perform no memory, branch or CSR access.
- Hold results and stall as required for multi-cycle execution and backpressure.
- Prevent duplicate writeback across interrupt/exception recovery.
- Handle register aliases through the normal dependency and forwarding controls.

## 6. Reference model

```c
#include <stdint.h>

static inline uint32_t cv_dotup_h_ref(uint32_t rs1, uint32_t rs2)
{
    uint32_t a0 =  rs1        & 0xffffu;
    uint32_t a1 = (rs1 >> 16) & 0xffffu;
    uint32_t b0 =  rs2        & 0xffffu;
    uint32_t b1 = (rs2 >> 16) & 0xffffu;
    uint64_t sum = (uint64_t)a0 * b0 + (uint64_t)a1 * b1;
    return (uint32_t)sum;
}
```

For DOTSP.B, convert each byte independently to −128..127 before multiplying
and summing; sign-extend the result to 32 bits.

## 7. Required verification

### DOTUP.H basic vectors

| `rs1` | `rs2` | `rd` | Purpose |
| --- | --- | --- | --- |
| `0x00000000` | `0x00000000` | `0x00000000` | Zero |
| `0x00010002` | `0x00030004` | `0x0000000b` | `2×4 + 1×3` |
| `0xffff0001` | `0x00020003` | `0x00020001` | Unsigned boundary |
| `0x80008000` | `0x00020003` | `0x00028000` | Bits 15/31 are not sign bits |
| `0xffffffff` | `0xffffffff` | `0xfffc0002` | Low 32 bits of a 33-bit sum |

### Coverage

Compare random inputs with an independent C/Python model. Include `rd=x0`,
`rd=rs1`, `rd=rs2`, `rs1=rs2`, either source being `x0`, and maximum-value carry.
Check producer-to-source forwarding, immediate consumers, writeback counts near
stalls/interrupts/reset, and illegal custom-3 encodings. Halfword boundary
sampling includes `0x0000`, `0x0001`, `0x7fff`, `0x8000`, `0xfffe`, `0xffff`.

## 8. Software integration

Use `.insn` or `.word` until the assembler supports the mnemonics. Keep a C
fallback and select availability at build time. The proposed feature macro is:

```c
#define PSC_HAS_CV_DOTUP_H 1
```

This macro and a possible PSC feature CSR are proposals, not existing supported
interfaces. No standard `misa` extension bit is allocated to these custom
instructions. Examples are [cv_pulp_test1.cpp](../hardware/sim/cpp/cv_pulp_test1.cpp),
[cv_pulp_test2.cpp](../hardware/sim/cpp/cv_pulp_test2.cpp), and the
[TFLite PULP backend](../software/os/third_party/tflite/README.md).

## 9. CPU v1 implementation and SDOTSP removal record

The following describes the implementation at removal time. Consult
[Decorder.sv](../hardware/rtl/soc/cpu_v1/src/Decorder.sv),
[Execute.sv](../hardware/rtl/soc/cpu_v1/src/Execute.sv), and
[Execute_Mul.sv](../hardware/rtl/soc/cpu_v1/src/Execute_Mul.sv)
for current internal states.

- `PSC_Types.sv`: DOTUP_H ALU control `01000`, DOTSP_B `01001`.
- Full opcode/funct3/funct7 decode; other custom-3 forms trap.
- Two register-file read ports; writes use the existing commit path.
- ISSUE/EX and EX/MEM source hazards stall; MEM/WB forwards when its value is
  available. CSR/unavailable values and commit conflicts stall.
- Existing MUL_WAIT/RESULT_HOLD handle waiting and result retention.
- DOTSP uses four signed 8×8 multipliers. RUN produces products, BYTE_PAIR
  produces pair sums and BYTE_SUM the total, with registers between stages.
  Existing MUL, DIV/REM and DOTUP.H behavior is retained.

Removal covered SDOT ALU/decode control, `use_rd`, the third read port
(`r_addr3`/`reg_data_3`), `issue_accumulator`/`execute_accumulator` and their
pipeline storage, `raw_hazard_rd`/`forward_sel_rd`, old-rd forwarding/stalls,
the accumulator input, BYTE_ACC and the 32-bit accumulation adder/state.
The removal audit found no other instruction using them. Supported SIMD
instructions have two sources.

Recorded Execute-accept-to-done latency, taking the accepting edge as t=0 and
assuming no downstream stall:

| Instruction | Cycles |
| --- | ---: |
| MUL | 2 |
| `cv.dotup.h` | 3 |
| `cv.dotsp.b` | 4 |

These historical measurements exclude fetch, dependency/memory waits and final
retirement. They are not a remeasurement of current RTL or an issue-rate claim;
the multiplier does not accept a new instruction every cycle.

## 10. Post-removal validation record (2026-09-21)

See the [signed-byte regression guide](../hardware/sim/tests/v1_cv_signed_byte/README.md)
for reproduction. The [initial DOTUP.H record](cpu_pulp_validation.md) predates
DOTSP.B: its one valid / 1,023 illegal encoding count is historical.

| Check | Recorded result |
| --- | --- |
| Decoder + Execute | PASS: 79,120 vectors; all 1,024 custom-3 forms, 2 valid / 1,022 illegal |
| Signed-byte multiplication | PASS: all 256×256 byte pairs, 4,096 random and 4,096 boundary-heavy pairs |
| Existing DOTUP.H unit | PASS: 1,296 boundary + 4,096 random vectors |
| Stall/reset/latency | PASS: result backpressure, no duplicate completion, 2 instructions × 10 reset phases |
| `cv_pulp_test2` C++ | PASS: 5,765 comparisons, including 4,096 random pairs (2,048 ordinary + 2,048 boundary-heavy) |
| CPU aliases/RAW/LOAD→DOTSP→STORE | PASS: no delay + 4 delayed seeds; 6,021 SIMD retirements each |
| Existing `cv_pulp_test1` | PASS: same 5 conditions; 6,933 DOT retirements each |
| Architectural oracle | PASS: independent register state from all commits checks both sources and result |
| Exceptions/interrupts | PASS: IRQ during each SIMD instruction, all 1,022 illegal forms, each in 5 conditions |
| Removed SDOTSP.B word | PASS: funct7=`0x54`, funct3=1; `mcause=2`, unchanged rd, resumes after instruction |
| RISC-V v1 regression | PASS: 49/49, including MUL/MULH/MULHSU/MULHU/DIV/REM |
| CPU core v1 | PASS: 30/30 |
| SoC basic v1 before list split | PASS: 57/57, checking actual PIO values |

The 57 programs became basic (53) + pulp (4). The classification change retained
expected values and cocotb registration; make variable expansion confirmed no
missing/duplicate entries and unchanged long/voice/single lists.

From `PSC-ONE/hardware/sim`:

```sh
make -f Makefile.cpu simulate_PSC_ONE_TESTS CPU_VERSION=v1 TEST_PROGRAM_LIST=pulp
```

The four programs are `cv_pulp_test1`, `cv_pulp_test2`, `nn_pulp_test1`,
`nn_pulp_test2`; all expect `0x600D600D`. No SDOTSP-only program is registered.
Disassembly found 28 DOTSP words in `cv_pulp_test2.elf`, 3 in
`nn_pulp_test2.elf`, and no SDOTSP words in either. The negative SDOTSP test
emits its word separately in `traps.S`.

The existing cocotb test has `Assert=0`: a PASS summary alone does not prove
correct output. Use `check_soc_log.py` as described in the regression guide to
check PIO signatures, NN diagnostics and completion; mismatches must exit nonzero.

## 11. NN performance comparison (recorded)

[nn_pulp_test2.cpp](../hardware/sim/cpp/nn_pulp_test2.cpp) compares scalar RV32IM
with DOTSP using the original 8→4→1 model, inputs, weights and zero biases.
SIMD loads four bytes at once. Hidden values are at most 56 and can be packed
losslessly to int8 for layer 2. This does not justify truncating arbitrary int32
intermediate values to int8.

Each mode runs 16 inferences per batch and 5 samples, with identical model
initialization, warmup and output clearing before measurements. Order alternates;
the minimum batch time is selected. Packing, loads, loops and calls are timed;
initialization, comparison and PIO are not. These rules did not change during
SDOT removal.

| Metric | Scalar | `cv.dotsp.b` |
| --- | ---: | ---: |
| Cycle-equivalent total (16 inferences) | 24,100 | 7,200 |
| Per inference | 1,506.25 | 450.00 |
| SIMD instructions per batch | 0 | 144 |
| SIMD instructions per inference | 0 | 9 |
| Expected-value mismatches | 0 | 0 |
| Speedup over scalar | 1.000× | 3.347× |
| Cycle reduction | 0% | 70.12% |

All 400 values (16 inferences × 5 samples × 5 outputs) match bit-for-bit between
modes. Hidden values are `[36,56,52,16]`; final output is 368 (`0x170`).
Expected-value, cross-mode and timer errors are all zero.

An earlier binary measured 24,300 / 6,700 cycles (3.627×, 72.43% reduction).
DOTSP latency remained 4 cycles and its kernel 40 instructions, but the function
moved from `0x914` to `0x1a4` and inputs from `0xcd8` to `0x954`. Layout and
measurement order changed with the two-mode binary. Running that same two-mode
binary on saved pre-removal RTL also gave 24,100 / 7,200 with matching outputs.
Under those conditions, circuit removal itself did not increase cycle count.
The separate contributions of cache and fetch were not measured.

PIO markers: EE40 = setup; A001/A002 = scalar/DOTSP cycles; A004 = cross-mode
mismatches; A005 = two expected-value mismatch counts; A006 = timer errors;
EE20/EE30 = four hidden values and final output for each mode. Old A003/EE31
outputs were removed. EE01 precedes success `600D600D` or failure `BAD0BAD0`.

Simulation runs at 100 MHz. The MMIO timer has 100-clock (1 µs) ticks; reported
cycles are elapsed ticks × 100. Quantization is less than 100 cycles per batch,
or 6.25 cycles per inference. Timer-read overhead is not subtracted.

The removed experimental `cv.sdotsp.b` previously reached 3.857×, but its extra
benefit over DOTSP was about 6% and did not justify third-read-port LUT/MUX cost.

## 12. Synthesis and place-and-route around SDOTSP removal

Recorded tools: Yosys 0.68+136 (`c30457480`), sv2v 0.0.13,
nextpnr 0.11.1-18-gdec04b3b. Target: Tang Nano 20K /
GW2AR-LV18QN88C8/I7, family GW2A-18C, 80 MHz constraint.
Both runs used seed `0x3141592653589793`, heap/default, the same CST and CPU
evaluation top. This top has no NPU and does not measure full-SoC Fmax.

`Makefile.nextpnr.cpu` was used with a build-only copy of
`PSC_CPU_TimingTop.sv`, correcting undeclared `.timer_irq_ext(timer_irq_ext)`
to `.timer_irq_ext(irq_ext)` for both runs. The original wrapper and synthesis
Makefile were unchanged. All 33 PNR JSON settings matched.

| Packed resource | With SDOTSP | After removal | Reduction |
| --- | ---: | ---: | ---: |
| LUT4 | 10,045 | 7,845 | 2,200 |
| FF | 4,171 | 4,086 | 85 |
| MULT9X9 | 4 | 4 | 0 |
| ALU | 730 | 696 | 34 |
| MUX5/6/7/8 total | 2,883 | 1,464 | 1,419 |
| Routed Fmax | 110.23 MHz | 120.09 MHz | +9.86 MHz |

MUX breakdown (LUT5/6/7/8): 2,080→1,158 / 541→192 / 192→84 / 70→30.
Combined removal reduced MUX count 49.22% and LUT4 21.90%; the third read port's
individual contribution was not isolated. The 80 MHz constraint passed and
Fmax improved 8.95%. All four signed byte multipliers mapped to MULT9X9;
MULT18X18=2 and MULT36X36=1 were unchanged. `check -assert` found no problems,
`scc -expect 0` no loops, and latch detection no latches. Existing array-to-FF
and ABC9 carry messages remained.

Evidence paths, relative to the repository root, are ignored generated artifacts:

- `build/cv-dotsp-only/timing/`: after removal.
- `build/cv-signed-byte/timing-after-irq/`: before removal.
- `build/cv-dotsp-only/before-src/`: saved pre-removal RTL.

An earlier full-SoC configuration (CPU v1, NPU v1) already exceeded Tang Nano 20K
capacity before byte SIMD was added. These CPU-only results do not establish
full-SoC 80 MHz operation. Resolving SoC capacity and changing other CPUs, the NPU
or peripherals were outside that work.

## 13. Cost and benefit of the retained extension

For this NN, 24,100→7,200 cycles saves 16,900 cycles per 16 inferences (3.347×,
70.12%). DOTSP processes four signed byte products per instruction and avoids
halfword expansion. Loads, scalar ADDs combining dot products, hidden-value
packing and loops still cost cycles; the instruction does not guarantee 4× speedup.

The following measures adding DOTSP.B to a CPU already supporting DOTUP.H,
not comparison with a CPU without PULP. All 33 PNR settings matched.

| Resource | DOTUP.H only | DOTUP.H + DOTSP.B | Change |
| --- | ---: | ---: | ---: |
| LUT4 | 7,682 | 7,845 | +163 (2.12%) |
| FF | 3,986 | 4,086 | +100 |
| MULT9X9 | 0 | 4 | +4 |
| ALU | 638 | 696 | +58 |
| MUX5/6/7/8 total | 1,318 | 1,464 | +146 |
| Routed Fmax | 117.91 MHz | 120.09 MHz | +2.18 MHz |

For this model, a small LUT increase and four DSP multipliers significantly
reduced cycles. Removing SDOTSP recovered 2,200 LUT4 and 1,419 MUX cells while
preserving DOTSP functionality and measured instruction latency. Performance
depends on model and memory layout; Fmax is a single-seed CPU-top measurement.

## 14. Possible future extensions

Candidates, requiring separate measurement and implementation, include:

1. `cv.dotsp.h`: two signed halfword products.
2. `cv.sdotsp.h`: signed MAC using old `rd` as an accumulator.
3. `cv.dotup.b`: four unsigned byte products.
4. `.sc`: replicate the low source lane.
5. `.sci`: replicate a 6-bit immediate.

Accumulating forms need a third source and corresponding register access,
forwarding and hazard control. None of these proposals changes current support.

## 15. Compatibility and references

The recorded specification follows the CORE-V SIMD Dot Product mnemonics,
operations and encodings in these references:

- [CV32E40P User Manual](https://docs.openhwgroup.org/projects/cv32e40p-user-manual/en/latest/instruction_set_extensions.html)
- [CORE-V software builtin specification](https://github.com/openhwgroup/core-v-sw/blob/master/specifications/corev-builtin-spec.md)

Only the two implemented encodings are accepted. Results use low-32-bit wrapping
or signed extension as specified above; neither instruction saturates or rounds.
