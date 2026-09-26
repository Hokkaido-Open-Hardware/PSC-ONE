<p align="center">
  <a href="https://github.com/QPSC-Design/PSC-ONE">
    <img src="images/PSC-ONE_Logo.png" width="640" alt="PSC-ONE Logo">
  </a>
</p>

# PSC-ONE documentation

[Project overview](../README.md) · [日本語・開発の目的](../README_JP.md)

Start with the component guides, then use the specifications and regression
records for implementation details. Paths in commands are relative to the working
directory stated by each guide. Historical measurements are not guarantees for
other CPU/NPU selections or later RTL revisions.

## Architecture and specifications

| Document | Scope |
| --- | --- |
| [Getting started](getting-started.md) | General environment and FPGA workflow; use the board guide below to distinguish boot modes |
| [CPU](cpu.md) | CPU variants and recomputed v1 Yosys generic-cell counts |
| [PULP / CORE-V SIMD](cpu_pulp.md) / [日本語](cpu_pulp_JP.md) | CPU v1 DOTUP.H and DOTSP.B |
| [Initial DOTUP.H validation](cpu_pulp_validation.md) | Historical results before DOTSP.B |
| [MMU](cpu_mmu.md) | Address translation |
| [PSC-OS](psc_os.md) | OS architecture |
| [API](psc_os_api.md) | Software interfaces |
| [NPU v1 measurements](npu_v1_streaming_results.md) | Four-lane MAC implementation results |
| [NPU writeback analysis](npu_writeback_analysis.md) | Writeback investigation |
| [SoC specification PDF](PSC-ONE_SpecSheet.pdf) | Reference document; may describe earlier configurations |
| [OS specification PDF](PSC-OS_Specs.pdf) | Reference document; may describe earlier configurations |

## Component guides and regression records

- [PSC-ONE Design](../board/PSC-ONE/README.md)
- [PSC-ONE Neo](../board/PSC-ONE_Neo/README.md)
- [PSC-Robot](../board/PSC-Robot/README.md)
- [PSC-ONE Board](../board/README.md)
- [PSC-ONE Hardware](../hardware/README.md)
- [cache_dma_controller_io 単体検証](../hardware/rtl/soc/cache/tests/README.md)
- [PSC_SDCard](../hardware/rtl/soc/mmio/PSC_SDCARD/README.ja.md)
- [PSC_SDCard](../hardware/rtl/soc/mmio/PSC_SDCARD/README.md)
- [PSC-NPU legacy (SynapEngine)](../hardware/rtl/soc/npu/README.md)
- [PSC-NPU v1: fixed four-lane streaming MAC](../hardware/rtl/soc/npu_v1/README.md)
- [PSC-NPU v2: 2-Term Power-of-Two 評価](../hardware/rtl/soc/npu_v2/README.md)
- [PSC-ONE Phase Flow Engine](../hardware/rtl/soc/pfe/README.md)
- [PSC-ONE / RV32ISP CoreMark](../hardware/sim/coremark_psc/README.md)
- [Instruction-fetch physical address regression](../hardware/sim/tests/fetch_sv32/README.md)
- [Legacy timer interrupt retirement regression](../hardware/sim/tests/legacy_timer_irq/README.md)
- [Timing pipeline regression](../hardware/sim/tests/timing_pipeline/README.md)
- [cpu_v1 branch prediction / dual fetch FIFO](../hardware/sim/tests/v1_branch_predict/README.md)
- [cpu_v1 signed byte SIMD regression](../hardware/sim/tests/v1_cv_signed_byte/README.md)
- [v2 fetch FIFO SRAM regression](../hardware/sim/tests/v2_fetch_sram/README.md)
- [cpu_v2 Load/Store pipeline regression](../hardware/sim/tests/v2_load_store_pipeline/README.md)
- [Intellectual Property (IP)](../ip/README.md)
- [PSC-ONE Software](../software/README.md)
- [MicroPython PSC port](../software/micropython/ports/psc/README.md)
- [PSC-OS](../software/os/README.md)
- [PSC-OS ELF C++ applications](../software/os/elf_apps/README.md)
- [PSC-OS TFLite](../software/os/src/api/tflite/README.md)
- [Minimal PSC-OS ELF runner](../software/os/tests/elf/README.md)
- [`fat32_ls` の回帰テスト](../software/os/tests/fat32/README.md)
- [PSC-OS dependencies](../software/os/third_party/README.md)
- [TFLite dependencies: vendor, not submodule](../software/os/third_party/tflite/README.md)
- [PSC_RV32 Trace Studio](../tool/FST_viewer/README.md)

## Diagram and measurement notes

- The CPU v1 drawing labels the main FIFO as 32 words; the current RTL default
  is 16 words. Its target FIFO remains 8 words.

- The CPU v2 drawing shows renaming, a ROB and out-of-order execution, consistent
  with the current RTL. The older pipeline-only overview has been corrected.
- The NPU drawing says “share a single multiplier”; it illustrates the legacy
  sharing concept. NPU v1 has four physical multiplier lanes.
- The OS drawing places FAT32 in the kernel. The current shell/ELF path links
  FAT32 into the user image and uses system calls for SD access.
- The main README's historical CoreMark table has an unresolved iteration-count
  mismatch: v1 score × time is about 1,000 while the stated count was 500.
  Original values are retained pending confirmation from the measurement log.

Images are retained; captions describe these differences. The SD controller
README also records an existing FIFO-full expression that needs RTL validation.
