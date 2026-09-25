# PSC-OS source layout

Paths below are relative to `src/`. Only paths and includes change.

| Original | Destination |
|---|---|
| `boot_fat32.c` | `boot/boot_fat32.c` |
| `boot_fat32.h` | `boot/boot_fat32.h` |
| `boot_logo.h` | `boot/boot_logo.h` |
| `bootloader.c` | `boot/bootloader.c` |
| `bootloader.ld` | `boot/bootloader.ld` |
| `bootloader_entry.S` | `boot/bootloader_entry.S` |
| `bootloader_fat32.c` | `boot/bootloader_fat32.c` |
| `bootrom.ld` | `boot/bootrom.ld` |
| `common.c` | `lib/common.c` |
| `common.h` | `lib/common.h` |
| `divmodsi3.c` | `lib/divmodsi3.c` |
| `dma.c` | `drivers/dma.c` |
| `dma.h` | `drivers/dma.h` |
| `elf_command.c` | `shell/elf_command.c` |
| `elf_loader.c` | `kernel/elf_loader.c` |
| `elf_loader.h` | `kernel/elf_loader.h` |
| `fat32.c` | `fs/fat32.c` |
| `fat32.h` | `fs/fat32.h` |
| `fat32_stream.c` | `fs/fat32_stream.c` |
| `fft_api.c` | `api/fft_api.c` |
| `fft_api.h` | `api/fft_api.h` |
| `font.h` | `drivers/font.h` |
| `jpeg/jpeg_headers.c` | `api/jpeg/jpeg_headers.c` |
| `jpeg/jpeg_view.c` | `api/jpeg/jpeg_view.c` |
| `jpeg/jpeg_view.h` | `api/jpeg/jpeg_view.h` |
| `jpeg/tjpgd_port.c` | `api/jpeg/tjpgd_port.c` |
| `jpeg/tjpgd_port.h` | `api/jpeg/tjpgd_port.h` |
| `jpeg/tjpgdcnf.h` | `api/jpeg/tjpgdcnf.h` |
| `jpeg_display.h` | `api/jpeg_display.h` |
| `kernel.bin` | `kernel.bin` |
| `kernel.c` | `kernel/kernel.c` |
| `kernel.h` | `kernel/kernel.h` |
| `kernel.ld` | `kernel/kernel.ld` |
| `kernel_bare.ld` | `kernel/kernel_bare.ld` |
| `kernel_elf.c` | `kernel/kernel_elf.c` |
| `kernel_fpga.ld` | `kernel/kernel_fpga.ld` |
| `kernel_process.c` | `kernel/kernel_process.c` |
| `kernel_syscall.c` | `kernel/kernel_syscall.c` |
| `kernel_trap.c` | `kernel/kernel_trap.c` |
| `lcd_api.c` | `drivers/lcd_api.c` |
| `lcd_api.h` | `drivers/lcd_api.h` |
| `led_api.c` | `drivers/led_api.c` |
| `led_api.h` | `drivers/led_api.h` |
| `mem_test.c` | `drivers/mem_test.c` |
| `mem_test.h` | `drivers/mem_test.h` |
| `mic_api.c` | `drivers/mic_api.c` |
| `mic_api.h` | `drivers/mic_api.h` |
| `mulsi3.c` | `lib/mulsi3.c` |
| `multitask_test.c` | `kernel/multitask_test.c` |
| `psc_mbios.S` | `boot/psc_mbios.S` |
| `run.sh` | `run.sh` |
| `sa_transfer.h` | `api/sa_transfer.h` |
| `sdcard_api.c` | `drivers/sdcard_api.c` |
| `sdcard_api.h` | `drivers/sdcard_api.h` |
| `shell.c` | `shell/shell.c` |
| `sim_shell.c` | `shell/sim_shell.c` |
| `speech_recognition_api.c` | `api/speech_recognition_api.c` |
| `speech_recognition_api.h` | `api/speech_recognition_api.h` |
| `synap_api.c` | `api/synap_api.c` |
| `synap_api.h` | `api/synap_api.h` |
| `syscall.h` | `kernel/syscall.h` |
| `tflite/PHASE3.md` | `api/tflite/PHASE3.md` |
| `tflite/PHASE4.md` | `api/tflite/PHASE4.md` |
| `tflite/README.md` | `api/tflite/README.md` |
| `tflite/tflite_api.h` | `api/tflite/tflite_api.h` |
| `tflite/tflite_demo.h` | `api/tflite/tflite_demo.h` |
| `tflite/tflite_file.c` | `api/tflite/tflite_file.c` |
| `tflite/tflite_inspect.cc` | `api/tflite/tflite_inspect.cc` |
| `tflite/tflite_inspect.h` | `api/tflite/tflite_inspect.h` |
| `tflite/tflite_platform.c` | `api/tflite/tflite_platform.c` |
| `tflite/tflite_quant.cc` | `api/tflite/tflite_quant.cc` |
| `tflite/tflite_quant.h` | `api/tflite/tflite_quant.h` |
| `tflite/tflite_runtime.cc` | `api/tflite/tflite_runtime.cc` |
| `tflite/tflite_synap.cc` | `api/tflite/tflite_synap.cc` |
| `tflite/tflite_synap.h` | `api/tflite/tflite_synap.h` |
| `timer_api.c` | `drivers/timer_api.c` |
| `timer_api.h` | `drivers/timer_api.h` |
| `timer_measure.c` | `drivers/timer_measure.c` |
| `user.c` | `api/user.c` |
| `user.h` | `api/user.h` |
| `user.ld` | `shell/user.ld` |
| `user_memory.h` | `kernel/user_memory.h` |

`run.sh` remains at its existing entry point; `kernel.bin` is an existing tracked artifact and stays at its existing output location.

`user.c/.h` provide user APIs; `user.ld` links the shell. `mem_test.c/.h` exercise hardware memory directly. `sa_transfer.h` defines the shared SynapEngine API. `common.c/.h` remain together in lib (including their existing console helpers); no implementation is split.

## 新しい構成と参照調査

```text
src/
├── boot/
├── kernel/
├── fs/
├── drivers/
├── api/
│   ├── jpeg/
│   └── tflite/
├── lib/
├── shell/
├── run.sh       # 既存の実行入口を維持
└── kernel.bin   # 既存の追跡済み生成物を維持
```

移動前にリポジトリ全体を、OS source pathと各ファイル名で検索した。
OS Makefileのsource/linker/header依存パス、MicroPythonのinclude、CoreMarkのinclude/vpath、
OSテストとNPUモデル評価script、TFLiteローカル統合script/patch、関連文書のpathを更新した。
TFLite manifestはpathを変更したローカル統合3ファイルのSHA-256のみ更新し、vendor検証を維持した。
`.gitignore`には移動したboot assembly 2ファイルの例外を追加した（既存の`*.S`除外対策）。

`hardware/sim/Makefile.pscos`、`hardware/bootloader/Makefile`のimageコピー先と、
`PSC_ONE_Boot_axi.v`の`mem/bootrom.mem`・`mem/kernel.mem`・`mem/user.mem`参照は変更不要。
RTL、testbench、生成物の名称・配置、clean targetの内容は変更していない。

変更した既存の参照ファイル（リポジトリルートからの相対path）:

- `.gitignore`
- `PSC-ONE/hardware/rtl/soc/npu_v2/README.md`
- `PSC-ONE/hardware/rtl/soc/npu_v2/reference/evaluate_model.py`
- `PSC-ONE/hardware/sim/Makefile.coremark`
- `PSC-ONE/software/micropython/ports/psc/modpsc.c`
- `PSC-ONE/software/micropython/ports/psc/mphalport.c`
- `PSC-ONE/software/os/Makefile`
- `PSC-ONE/software/os/README.md`
- `PSC-ONE/software/os/src/run.sh`
- `PSC-ONE/software/os/tests/elf/REPORT.md`
- `PSC-ONE/software/os/tests/elf/fault.S`
- `PSC-ONE/software/os/tests/elf/hello.c`
- `PSC-ONE/software/os/tests/elf/host.c`
- `PSC-ONE/software/os/tests/elf/rtl_run.py`
- `PSC-ONE/software/os/tests/elf/run.py`
- `PSC-ONE/software/os/tests/elf/start.S`
- `PSC-ONE/software/os/tests/fat32/README.md`
- `PSC-ONE/software/os/tests/fat32/host.c`
- `PSC-ONE/software/os/tests/fat32/run.py`
- `PSC-ONE/software/os/tests/jpeg/check_boundaries.py`
- `PSC-ONE/software/os/tests/jpeg/host.c`
- `PSC-ONE/software/os/tests/jpeg/run.py`
- `PSC-ONE/software/os/tests/tflite/driver_test.py`
- `PSC-ONE/software/os/tests/tflite/generate_model.py`
- `PSC-ONE/software/os/tests/tflite/phase3_check.py`
- `PSC-ONE/software/os/tests/tflite/run.py`
- `PSC-ONE/software/os/third_party/README.md`
- `PSC-ONE/software/os/third_party/tflite/README.md`
- `PSC-ONE/software/os/third_party/tflite/manifest.json`
- `PSC-ONE/software/os/third_party/tflite/psc/run_host.py`
- `PSC-ONE/software/os/third_party/tflite/psc/run_target.py`
- `PSC-ONE/software/os/third_party/tflite/psc/runtime-integration.patch`

## 検証

実行ログ・移動前のソース・比較用イメージは `/tmp/psc-os-src-layout/` に保存。

| 検証 | 結果 |
|---|---|
| `make -C PSC-ONE/software/os clean` → `make -C PSC-ONE/software/os sim_mem` | PASS |
| 通常buildのbootrom.elf / bootrom.mem / kernel.elf / kernel.mem / shell.elf / user.mem | すべて`software/os/build/`に生成 |
| ELF host (`tests/elf/run.py`) | PASS、malformed入力10000件を含む |
| FAT32 host (`tests/fat32/run.py`) | PASS、ASan/UBSan |
| JPEG host (`tests/jpeg/run.py`) | PASS、画像比較・ASan |
| JPEG LCD/syscall/timer境界 (`tests/jpeg/check_boundaries.py`) | PASS |
| TFLite host (`tests/tflite/run.py`) | PASS、モデル再生成・driver検証を含む |
| TFLite `phase0_check.py` / `phase3_check.py` | PASS、RV32I/IM link・RAM・runtime依存監査 |
| `SIM_USER=minimal sim_mem` | PASS |
| `fpga_fat32_boot` | PASS |
| CoreMark `Makefile.coremark build` | PASS |
| `bash -n src/run.sh` | PASS |
| `git diff --check` | PASS |

全82ファイルの移動先/残置を照合した。C/C++、header、assembly、linker scriptは、
include行を除去すると移動前後でバイト単位で一致する。
移動前後の比較ビルドでは、日時と診断用`__FILE__`だけを検証用compiler optionで正規化し、
bootrom.bin・bootrom.mem・kernel.bin・kernel.mem・shell.bin・user.memがすべて完全一致した。
通常buildでは既存の`__DATE__`/`__TIME__`、MicroPython生成日、診断用pathに由来する差がある。
正規化optionは検証時のみ使用し、リポジトリのビルド設定には追加していない。

ホストテストの初回はsandbox下のLeakSanitizer/ptrace制限で失敗し、sandbox外の同一テストでPASS。
RTLコンパイルも初回はccacheの書き込み制限で失敗し、sandbox外で再実行した。

## 既存の問題・検証範囲

旧`fpga_boot`は`bootloader.c:362`の`PSC_SD_ADDR`未定義でFAIL。
移動前のMakefileとソースでも同じエラーを再現しており、今回の移動によるregressionではない。
FAT32等のバグ修正禁止に従い、既存の処理は変更していない。
QEMU/SBIの実起動、SD起動のRTL simulation、実機FPGAは今回の検証対象外。
`run.sh`はpath更新と構文確認のみで、従来の構成をそのまま維持した。

新規ファイルは本報告書のみ（移動先80ファイルを除く）。既存ソースの削除なし。
Git indexは変更せず、add / commit / pushは実行していない。

## RTL simulation 実行記録

既存のログや波形をcleanで削除しないよう、
`/tmp/psc-os-src-layout/standard/PSC-ONE/` に既存source/Makefileへのリンクと独立した出力領域を用意した。
標準Makefile・RTL・cocotb testbenchの内容は変更していない。
`hardware/sim`で次を実行した:

```sh
make -f Makefile.pscos simulate_PSCOS CPU_VERSION=v1 SIM_FAST=1 RUN_CYCLES=30000000
```

Boot ROM完了・CPU起動・OSの起動ロゴ描画開始を確認。
cocotb結果は `TESTS=1 PASS=1 FAIL=0 SKIP=0`、実時間932.15秒。
ただし`PSC-OS test stopped after 0 prompts`のため、この短時間実行だけではshell起動完了と判定しない。
ログ: `/tmp/psc-os-src-layout/standard-sim-retry.log`。

さらに既存のELF RTL regressionを通常のfull shellで実行:

```sh
myenv/bin/python PSC-ONE/software/os/tests/elf/rtl_run.py \
  --build /tmp/psc-os-src-layout/elf-rtl \
  --fixtures /tmp/psc-os-src-layout/elf
```

この既存runnerは`Makefile.pscos`から同じv1 RTL source listを取得し、
テスト用SD modelの保存sector数のみ既存の方法で拡大する。
Boot ROM・kernel・full shellは通常ソースを使用し、CPU RTLや起動処理を変更しない。

ELF用RTLでBoot ROM → kernel → 通常版shellの`PSC_OS>`到達を確認。
`fat32_ls`と`fat32_read READ.TXT`はPASS。
ユーザーの終了指示により、`fat32_cat`以降の検証途中で今回のrunner/simulatorを停止した。
ELF実行・異常ELF拒否・shell復帰を含むRTL suite全体の完了/PASSは未確認。
ログ: `/tmp/psc-os-src-layout/elf-rtl/elf_simulation.log`、同ディレクトリの`uart.log`。

最終Git状態: 32 modified、80旧path deleted、81 untracked（移動先80 + 本報告書1）、staged 0。
旧pathのdeleted表示はファイル移動によるもので、ソース内容の削除ではない。
