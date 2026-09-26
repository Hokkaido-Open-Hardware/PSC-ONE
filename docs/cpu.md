<p align="center">
  <a href="https://github.com/QPSC-Design/PSC-ONE">
    <img src="images/PSC-ONE_Logo.png" width="640" alt="PSC-ONE logo">
  </a>
</p>

# PSC-ONE CPUs

[Project](../README.md) · [Hardware](../hardware/README.md) · [Documentation](README.md)

PSC-ONE maintains a legacy CPU, stable CPU v1, and experimental CPU v2.
Select them through `CPU_VERSION=legacy`, `v1`, or `v2` in the simulation
Makefiles. CPU and NPU selections are independent.

<!-- contents -->
- [CPU variants](#cpu-variants)
- [Legacy architecture](#legacy-architecture)
- [CPU v1 architecture](#cpu-v1-architecture)
- [CPU v2 architecture](#cpu-v2-architecture)
- [Verification and performance](#verification-and-performance)
- [PSC_RV32 vs PicoRV32 (Yosys Analysis)](#psc_rv32-vs-picorv32-yosys-analysis)
<!-- /contents -->

## CPU variants

| Selection | Design | Source |
| --- | --- | --- |
| `legacy` | Original state-controlled CPU with optional overlap | [cpu](../hardware/rtl/soc/cpu/src/) |
| `v1` | Stable valid/ready pipeline with branch prediction | [cpu_v1](../hardware/rtl/soc/cpu_v1/src/) |
| `v2` | Small experimental out-of-order backend | [cpu_v2_experimental](../hardware/rtl/soc/cpu_v2_experimental/src/) |

The SoC adds caches, SDRAM, MMIO peripherals and accelerators around these
cores. NPU commands use custom CPU CSRs; matrix data uses the shared memory
subsystem. The CPU-only Yosys measurement below does not include those external
caches, the NPU, SDRAM controller or peripherals.

## Legacy architecture

<img src="images/PSC_RV32.jpg" width="800" alt="PSC-RV32 legacy CPU and memory paths">

The diagram shows instruction/data MMUs and the connections to the SoC caches
and SDRAM. It is a system-context diagram, not the boundary of the CPU-only
synthesis top. The legacy implementation remains a regression reference.

## CPU v1 architecture

<img src="images/PSC_RV32_V1.jpg" width="800" alt="PSC-RV32 v1 fetch and instruction engine">

> The drawing labels the main instruction FIFO as 32 words. Current v1 RTL
> defaults to 16 words, with an 8-word predicted-target FIFO. The image is
> retained as an earlier configuration.

CPU v1 overlaps fetch, decode, execution and commit using pipeline control,
forwarding and stalls. Branch prediction is enabled by the source define in
[PSC_RV32_FetchUnit.sv](../hardware/rtl/soc/cpu_v1/src/PSC_RV32_FetchUnit.sv).
The [branch-prediction regression](../hardware/sim/tests/v1_branch_predict/README.md)
documents the normal/target FIFO behavior.

The core implements RV32I, integer multiply/divide/remainder, CSR and fence
instructions, M/S/U privilege modes, exceptions and interrupts. Its selected
PULP instructions are `cv.dotup.h` and `cv.dotsp.b`; see the
[PULP specification](cpu_pulp.md) ([日本語](cpu_pulp_JP.md)).

Instruction and data MMUs perform page translation. R/W/X permissions are
checked, but U/S and A/D enforcement is omitted: see the [MMU guide](cpu_mmu.md).
The presence of privilege modes does not establish complete user/kernel isolation.

## CPU v2 architecture

<img src="images/PSC_RV32_V2.jpg" width="800" alt="PSC-RV32 v2 renaming, ROB and issue logic">

CPU v2 implements register renaming, an instruction queue and a reorder buffer.
The [instruction unit](../hardware/rtl/soc/cpu_v2_experimental/src/PSC_InstructionUnit.sv)
defaults to ROB=2, IQ=2 and PRF=34. Ready independent instructions can execute
ahead of older stalled operations while architectural retirement stays in order.
Memory/CSR side effects are controlled at the ROB head.

Two in-flight slots do not imply two instructions issued or retired each cycle.
The design explores a small scheduling window, variable-latency execution and
FPGA timing/resource trade-offs. It remains experimental; v1 is the stable CPU.

## Verification and performance

Run from `PSC-ONE/hardware/sim` with Verilator, cocotb and the RISC-V toolchain:

```sh
make -f Makefile.riscv.sim simulate_RISCV_TESTS_PARALLEL CPU_VERSION=v2
make -f Makefile.cpu.core simulate_CPU_CORE CPU_VERSION=v2
make -f Makefile.cpu simulate_PSC_ONE_TESTS TEST_PROGRAM_LIST=basic CPU_VERSION=v2
make -f Makefile.cpu simulate_PSC_ONE_TESTS TEST_PROGRAM_LIST=long CPU_VERSION=v2
```

Use `CPU_VERSION=v1` for the stable core. PULP has a separate v1 suite:

```sh
make -f Makefile.cpu simulate_PSC_ONE_TESTS TEST_PROGRAM_LIST=pulp CPU_VERSION=v1
```

The recorded v1 RISC-V ISA regression passed 49/49 tests. The misaligned-data
test `rv32ui-ma_data` is excluded by the existing suite; naturally aligned
access is expected. These are historical results, not a new full CPU regression.
The [fetch/Sv32 regression](../hardware/sim/tests/fetch_sv32/README.md) covers
nonidentity mappings and virtual-PC retention on all three CPUs.

For CPU-only CoreMark, see the [recorded comparison](../README.md#coremark-cpu-core-only)
and [reproduction guide](../hardware/sim/coremark_psc/README.md). The original v1
iteration count conflicts with its score/time pair; the overview preserves the
values and explains the unresolved discrepancy.

## PSC_RV32 vs PicoRV32 (Yosys Analysis)

### Resource comparison: CPU v1

Recomputed on 2026-09-26 from **CPU v1**, top `PSC_RV32_core`, with branch
prediction, the 16/8-word fetch FIFOs and both PULP instructions enabled.
Counts are from the complete **design hierarchy**, including both MMU instances,
after `read_verilog → hierarchy → proc → opt → stat`.
No `memory`, `techmap`, `abc` or FPGA mapping pass is applied.

| Metric | PSC_RV32 CPU v1 (new run) | PicoRV32 (archived) |
| --- | ---: | ---: |
| Generic RTL cells | 1,876 | 515 |
| Adders (`$add`) | 30 | 8 |
| Subtractors (`$sub`) | 5 | 3 |
| Multipliers (`$mul`) | 9 | 0 |
| Multiplexers (`$mux` only) | 505 | 100 |
| Comparators (`$eq/$ne/$lt/$le/$gt/$ge`) | 382 | 69 |
| FF-family cells | 194 | 105 |
| Memories / memory bits (before mapping) | 2 / 768 | 1 / 1,024 |

FF-family cells are word-level register cells, **not individual flip-flop bits**.
For v1, 194 = `$adff` 36 + `$adffe` 158. For archived PicoRV32, 105 is the sum
of `$dff`, `$dffe`, `$sdff`, `$sdffce` and `$sdffe`. Memory bits are listed
separately. `$pmux` is excluded from the MUX row (v1: 50, PicoRV32: 42).
Generic `$mul` count is not a count of FPGA DSP blocks.

PicoRV32 is retained from the [archived Yosys log](../../PSC_RV32I/log/yosys_picorv32.log),
which reports Yosys 0.33 (`2584903a060`). The former MUX value 148 was inconsistent
with that log; it has been corrected to 100. The original source revision and
configuration are not fully recorded and the source is absent at the old build
path. PicoRV32 was **not rerun**. Because tool versions and CPU features differ,
this table is a structural reference, not a controlled area or performance ratio.

### Tools, scope and reproduction

The v1 run used Yosys 0.52 (`fee39a3284c90249e1d9684cf6944ffbbcbb8f90`)
and sv2v 0.0.13. It reuses [Makefile.yosys](../hardware/sim/Makefile.yosys)'s
`yosys_cpu` flow and v1 source list. The AXI/cache wrapper
`PSC_ONE_RV32_core.v` is excluded. No RTL or Makefile was changed.

From `PSC-ONE/hardware/sim`, with those tools on PATH:

```sh
make -f Makefile.yosys yosys_cpu CPU_VERSION=v1 \
  CPU_YOSYS_BUILD_DIR=build_yosys/v1-docs \
  CPU_YOSYS_LOG=build_yosys/v1-docs/yosys_cpu_v1.log
```

An additional `hierarchy -check; proc; opt; check -assert` run completed with
zero reported problems. Four array-to-register conversion warnings remained
(`pc_mem`, `mem`, `byte_product`, `registers`). This checks generic RTL structure;
it does not establish FPGA capacity, routed Fmax or full-SoC timing closure.

Source checkout: `fa894679736f94c7d6a00b2258e997a9047c370a` (CPU RTL unchanged in this documentation work).

Converted Verilog SHA-256: `64f6056055fd1a4b197ae4c64c2844de5fed59626fcf263f194f1503be06e7e8`.

### Complete v1 cell histogram

This retained summary makes the grouping above auditable without depending on
temporary build artifacts. The total is 1,876 cells.

| Yosys cell | Count |
| --- | ---: |
| `$add` | 30 |
| `$adff` | 36 |
| `$adffe` | 158 |
| `$and` | 3 |
| `$eq` | 286 |
| `$ge` | 4 |
| `$gt` | 1 |
| `$le` | 1 |
| `$logic_and` | 214 |
| `$logic_not` | 104 |
| `$logic_or` | 165 |
| `$lt` | 6 |
| `$memrd` | 2 |
| `$memwr_v2` | 2 |
| `$mul` | 9 |
| `$mux` | 505 |
| `$ne` | 84 |
| `$not` | 14 |
| `$or` | 19 |
| `$pmux` | 50 |
| `$reduce_and` | 100 |
| `$reduce_bool` | 62 |
| `$reduce_or` | 9 |
| `$shiftx` | 1 |
| `$shl` | 1 |
| `$shr` | 2 |
| `$sshr` | 1 |
| `$sub` | 5 |
| `$xor` | 2 |
