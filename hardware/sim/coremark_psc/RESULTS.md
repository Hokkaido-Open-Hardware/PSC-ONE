# CoreMark測定レポート（2026-09-11）

## 測定条件

| 項目 | 値 |
| --- | --- |
| PSC-ONE HEAD | `409ede610f49621d712ab3cc95a38e4bdee6cd61` |
| CoreMark repository | https://github.com/eembc/coremark.git |
| CoreMark submodule commit | `1f483d5b8316753a742cbf5590caf5bd0a4e4777` |
| Toolchain | `riscv64-unknown-elf-gcc` |
| Compiler version | GCC 14.2.0（14.2.0+19） |
| `-march` | `rv32im_zicsr_zifencei` |
| `-mabi` | `ilp32` |
| Optimization | `-O2` |
| CPU clock | 100 MHz |
| Run | PERFORMANCE、400 iterations、2000 bytes |
| Simulator | Verilator 5.050、cocotb 2.0.1 |
| Simulation設定 | `SIM_FAST=1 COREMARK_VPI=minimal`、ホストC++ `-O3` |
| 時間計測 | 既存PSC-OS MMIO timer stopwatch、1 tick = 1 ms |

両CPUに対して同じバイナリを使用しています。`coremark.bin`のSHA-256は
`cbeadb6628f833fc05e04f708942babc352776383052af46faaa77d79f632cfa`です。
CPU RTL、既存`cpp/Makefile`、CoreMark本体は変更していません。

共通CFLAGSは以下です。include pathとdefineを含む完全なフラグは各UARTログに記録しています。

```text
-march=rv32im_zicsr_zifencei -mabi=ilp32 -O2 -g -ffreestanding -nostdlib
-mstrict-align -std=c11 -mno-relax -ffunction-sections -fdata-sections -Wall -Wextra
```

## 結果

| 項目 | cpu_v1 | cpu_v2 |
| --- | ---: | ---: |
| Total ticks（ms） | 12236 | 13434 |
| Target time（s） | 12.236 | 13.434 |
| Iterations | 400 | 400 |
| CoreMark | 32.690422 | 29.775197 |
| CoreMark/MHz | 0.326904 | 0.297752 |
| CRC validation | PASS | PASS |
| Correct operation validated. | YES | YES |
| make終了コード | 0 | 0 |

RTL timer running区間はv1が12,236,230,430 ns、v2が13,434,092,550 nsで、
両方ともターゲットの整数msと分解能内で一致します。
スコアは`iterations / (ticks / 1000)`、CoreMark/MHzはその値を100で割って算出します。
公式出力は整数演算のため、`Iterations/Sec`はv1が33、v2が30と表示されます。
上表は整数秒に丸める前のtick値から計算しています。

両CPUのCRCはseed=`e9f5`、list=`e714`、matrix=`1fd7`、state=`8e3a`、final=`25b5`です。
今回の同一条件ではv2のCoreMarkはv1より約8.92%低い結果でした。
性能差の原因を特定する解析は今回の対象に含めていません。

### 実行コマンドとログ

```bash
cd PSC-ONE/hardware/sim
make -f Makefile.coremark
make -f Makefile.coremark CPU_VERSION=v2
```

- v1: [UARTログ](../log_uart/coremark_v1_verilator_PERFORMANCE_400_20260911_173808.log)
- v2: [UARTログ](../log_uart/coremark_v2_verilator_PERFORMANCE_400_20260911_180308.log)
- 集計JSON: `build/coremark/<CPU>/verilator/PERFORMANCE-400/result.json`
- timer区間: 同ディレクトリの`timer.json`
- ELF / BIN / MEM: 同ディレクトリの`coremark.elf` / `coremark.bin` / `coremark.mem`

### cpu_legacy

`make -f Makefile.coremark CPU_VERSION=legacy`で同じ条件のビルドとVerilator起動を
実行しました。起動後、UARTへ次のエラーが出たため、指示に従い測定を中止しました。

```text
ERROR! Target timer is busy
ERROR! Unexpected scheduler interrupt
```

CRC validationおよび`Correct operation validated.`は未確認、CoreMark / MHzは未取得です。
makeは中止により終了コード2でした。原因の切り分けやRTL修正、workaroundは行っていません。
記録: [legacy UARTログ](../log_uart/coremark_legacy_verilator_PERFORMANCE_400_20260911_182252.log)。

## 既存回帰テスト

| Verilatorでの確認 | v1 | v2 |
| --- | ---: | ---: |
| RISC-V ISA tests | 49 PASS | 49 PASS |
| CPU core選定テスト | 12 PASS | 12 PASS |
| SoC選定テスト | 5 PASS | 未実施 |

合計127項目PASSです。既存Makefileからソース・コンパイル設定を取得し、
既存cocotb testとrunnerを一時ディレクトリで実行しました。
既存のfirmware生成、ISA image生成も再実行しています。

CPU coreはadd、forwarding、store、jal/jalr、mul、rem/div、CSR、memcpy、
SoCはadd、mul、CSR、timer IRQ、UARTを含みます。
詳細ログは今回の環境の`/tmp/psc-coremark-regression-z8f9zht3/`と
`/tmp/psc-coremark-chip-regression-dme29imt/`にあります。

## 制限事項

- SDRAM・cache・timer IRQを含むRTL構成の測定です。FPGAの最大動作周波数は測定していません。
- timerの分解能は1 msです。ホストの実行時間はスコアに使用していません。
- 今回の本測定はPERFORMANCE seedです。公式提出にはVALIDATION seedなど追加のrun rulesを満たす必要があります。
- 上流`make check`は取得commit自身の`coremark.h`コメント修正とMD5 manifestの不一致でFAILします。詳細は[README](README.md#上流md5検査について)を参照してください。
- Icarusは追加測定の対象外です。指定前の回帰確認で見つかったv2の既存elaboration問題は[README](README.md#再利用するsimulation環境)に記載しています。
