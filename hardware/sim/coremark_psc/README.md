# PSC-ONE / RV32ISP CoreMark

測定条件、CPU別の結果、回帰確認は[測定レポート](RESULTS.md)に記録しています。

## 取得と実行

リポジトリのルートで実行します。

```bash
git submodule update --init --recursive
cd PSC-ONE/hardware/sim
make -f Makefile.coremark
```

CoreMark本体は公式リポジトリ <https://github.com/eembc/coremark.git> の
`sim/coremark/` submoduleです。porting codeはこの`coremark_psc/`に置き、
公式ソース、LICENSE、copyrightは変更していません。

```text
sim/
├── Makefile.coremark
├── coremark/                         # EEMBC公式submodule
├── coremark_psc/                     # porting code、結果集計
├── cocotb_tb/coremark/coremark_test.py
├── log_uart/coremark_*.log            # UARTから復元した標準出力
└── build/coremark/                   # ELF、BIN、MEM、simulation生成物
```

必要なツールは既存環境と同じRISC-V GCC、binutils、GNU make、Python、
cocotb 2、Verilator、`hexdump`です。リポジトリの`myenv/bin`をPATHへ追加します。
初回はRTLモデルのコンパイルが必要です。CoreMarkの標準validationにはターゲット時間で
10秒以上が必要なため、ホスト上のRTL実行には長時間かかります。

## 個別操作

以下は`PSC-ONE/hardware/sim`で実行します。

```bash
make -f Makefile.coremark build
make -f Makefile.coremark run
make -f Makefile.coremark clean
make -f Makefile.coremark check-source

# 実験版CPU
make -f Makefile.coremark CPU_VERSION=v2

# もう一方の公式seed設定
make -f Makefile.coremark COREMARK_RUN=VALIDATION

# 反復回数、実行タイムアウトを明示
make -f Makefile.coremark ITERATIONS=400 RUN_CYCLES=3000000000
```

`clean`は`build/coremark/`だけを削除します。submodule、UARTログ、既存の
`mem/`、`riscv_build/`、OS生成物は対象外です。既存Makefileの`clean`は呼びません。

短い`ITERATIONS=1`などでもCRCの切り分けはできますが、10秒未満なら
CoreMark自身の時間条件によりFAILし、性能結果は採用しません。
CPUやコンパイラを変更して10秒未満になった場合は`ITERATIONS`を増やしてください。
`ITERATIONS=0`による上流の自動反復回数選択も使用できますが、予備測定を含めて
`RUN_CYCLES`内に収まる必要があります。

## ビルド設定

| 項目 | 設定 |
| --- | --- |
| デフォルトCPU | `v1` |
| CPU clock | 100 MHz、10 ns周期 |
| Compiler | 既存`cpp/Makefile`の`RISCV_PREFIX` + `gcc` |
| GCC prefix | 通常は`riscv64-unknown-elf-` |
| `-march` | `rv32im_zicsr_zifencei` |
| `-mabi` | `ilp32` |
| Optimization | `-O2` |
| Run | `PERFORMANCE_RUN=1`、400反復、2000 bytes |
| Memory | SDRAM上のcode / static data、既存I/D cacheを使用 |
| Startup / linker | 既存`cpp/sp_start.S` / `cpp/link.ld` |

`cpp/Makefile`は変更せず、makeで展開した設定値を読み取ります。
GCC prefix、ISA、ABI、最適化設定をCoreMark側に再定義していません。
共通フラグに`-std=c11 -mno-relax -ffunction-sections -fdata-sections -Wall -Wextra`を追加します。
`-mno-relax`は既存startupがgpを初期化しないことに対応し、section分割と
`--gc-sections`はPSC-OSから必要なUART・timer・trap関数だけをリンクするためです。
CoreMarkの5つの公式Cソースはすべて同じフラグでコンパイルします。
全コンパイルフラグとGCC versionはUART出力と`config.h`に記録します。

メモリは既存linkerのRAM `0x00000000..0x0000ffff`を使用し、stack topは`0x10000`です。
既存startupがBSSをゼロクリアします。ELFのentryが0、BSSが4-byte境界、
main stackの空きが8 KiB以上であることをビルド時に確認します。
BIN生成には既存prefixのobjcopy、MEM生成には変更していない`cpp/Makefile`の
変換ルールを専用作業ディレクトリで呼び出します。
boot ROMの4096-word容量を超えるBINは、切り捨てずエラーにします。

## Consoleと時間計測

Consoleは既存PSC-OSの`kernel.c`にある`uart_putchar`と`common.c`の`s_printf`を使用します。
`console.c`はCoreMarkで使う整数formatを既存printfへ変換するだけです。
CRCの16進値は既存printfに合わせて8桁で表示します。
UART driverは新設していません。simulationでは既存`FST_UART_MODE`を有効にし、
既存PSC-OSのUART decoderでTX信号を復元します。

v1 / v2には標準`mcycle`の実装がなく、独自CSR `0xBC4`の
`CPU_MON_CYCLE`も経過cycle数ではなくcache hit/missイベント数です。
そのため、既存MMIO timerとPSC-OSの`timer_measure_begin/end/irq`を使います。

- UART: `0x10000000`（TX）、`0x10000008`（status）
- Timer: `0x10002000`（control）、`0x10002004`（count）、`0x10002008`（status）
- 終了通知: 既存PIO `0x10001000`に`0xEE01`

100 MHzの既存SoC testbenchではtimerは100 cycleごとに1 tick進みます。
PSC-OSのstopwatchは50 msごとのtimer IRQで16-bit counterを拡張し、
合計時間を整数msで返します。既存`machine_trap_entry`をそのまま使用し、
bare-metalのM-modeから有効化する部分だけを`runtime.c`で接続しています。
IRQ処理の時間も測定区間に含まれます。cocotbではtimerのrunning信号を監視し、
RTL上の経過時間とターゲットから出力されたms値が分解能内で一致することも確認します。

PSC-OSは通常Clangでビルドされるため、GCCとの整数typedefおよびalignment builtinの
違いを`os_include/`で接続しています。既存OSソースへの変更はありません。

## 結果の読み方

公式ソースのCRC検証と`Correct operation validated.`を必須とします。
さらに集計側でseed CRC、list / matrix / state CRC、標準data size、
10秒以上の実行時間、RTL timerとの一致を確認します。
CRC不一致、時間不足、timeout、simulation失敗はmakeの非ゼロ終了になります。

`HAS_FLOAT=0`のため公式の`Total time (secs)`と`Iterations/Sec`は整数表示です。
最終集計は丸めた秒数ではなく`Total ticks`の整数msから計算します。

```text
target seconds = Total ticks / 1000
CoreMark       = Iterations / target seconds
CoreMark/MHz   = CoreMark / 100
```

集計結果は`build/coremark/<CPU>/<SIM>/<RUN>-<ITERATIONS>/result.json`にも保存します。
ホストの実行時間やcocotbのREAL TIMEを性能値の計算には使いません。
CPU clockは既存SoCの100 MHzに固定しています。周波数変更にはtestbench、
timer換算、UART設定を一致させる必要があるため、単にスコアの除数だけを変更しないでください。

これはSDRAM・cache・timer IRQを含むRTL構成の測定です。FPGA上で達成できる
最大周波数の測定ではありません。EEMBCへ公開結果を提出する場合は
PERFORMANCEとVALIDATIONの両seed設定を含む[公式run rules](../coremark/README.md#run-rules)も満たしてください。

## 再利用するsimulation環境

RTL source listとCPU切り替えは`Makefile.cpu`をincludeし、既存の
`PSC_ONE_Chip_sim`とcocotb runnerを使います。CoreMark用testはboot/resetと
UART decoderを既存testから再利用し、終了通知・ログ保存・validationを追加しています。
Verilatorは既存`SIM_FAST=1`設定を使い、ホストC++も`-O3`でビルドします。
デフォルトの`COREMARK_VPI=minimal`では、`coremark.vlt`でclock/reset、boot完了、
UART、PIO、timer監視に必要な信号を公開します。全信号を公開する既存設定は
`COREMARK_VPI=full`で選択できます。両設定の3反復実行で同一firmwareのCRCと
RTL timer測定区間（91,794,200 ns）が一致することを確認しています。
`MODE=icarus`も既存Makefileの経路を利用しますが、利用可否は既存RTLの
Icarus対応状況に依存します。CPU RTLと既存testbench本体は変更していません。

今回の既存CPU回帰確認では、v1のVerilator / Icarus 12.0と、v2のVerilatorで
ISA全49項目およびCPU core選定12項目がPASSしました。
v2 / Icarus 12.0では既存`PSC_InstructionUnit.sv:260`の`rob[rob_head]`アクセスで
Icarus自身がelaboration assertionにより異常終了します。
CoreMarkに依存しない既存core / ISAテストでも同じエラーになり、RTLは変更していません。
以降の動作確認はVerilatorを対象とします。Verilatorでは上記122項目に加えて、
v1のSoCテスト（add、mul、CSR、timer IRQ、UART）5項目もPASSしています。

## 上流MD5検査について

取得commit `1f483d5b8316753a742cbf5590caf5bd0a4e4777`では、公式`make check`が
`coremark.h`だけFAILします。上流commit `4ee6eca`でコメントのtypoが修正された後、
`coremark.md5`が更新されていないためです。5つのベンチマークCソースはすべてOKです。
この検査は変更せず、`check-source`でも上流のFAILをそのまま返します。

submoduleの作業ツリーが取得commitと一致することは、以下でも確認できます。

```bash
git -C coremark status --short
git -C coremark diff HEAD --exit-code
git -C coremark rev-parse HEAD
```
