# JPEG表示 Phase 1 実装報告

## 1. 変更ファイル一覧

コード・手順は実装済みです。実機LCDとCPU上のJPEG end-to-endは未検証です。
既存ファイルの削除はありません。CPU/SD/LCD RTL、MicroPython APIは変更していません。

- `.gitmodules`
- `PSC-ONE/software/README.md`
- `PSC-ONE/software/os/Makefile`
- `PSC-ONE/software/os/PHASE1_REPORT.md`
- `PSC-ONE/software/os/README.md`
- `PSC-ONE/software/os/src/fat32.h`
- `PSC-ONE/software/os/src/fat32_stream.c`
- `PSC-ONE/software/os/src/jpeg/jpeg_headers.c`
- `PSC-ONE/software/os/src/jpeg/jpeg_view.c`
- `PSC-ONE/software/os/src/jpeg/jpeg_view.h`
- `PSC-ONE/software/os/src/jpeg/tjpgd_port.c`
- `PSC-ONE/software/os/src/jpeg/tjpgd_port.h`
- `PSC-ONE/software/os/src/jpeg/tjpgdcnf.h`
- `PSC-ONE/software/os/src/kernel.h`
- `PSC-ONE/software/os/src/kernel_fpga.ld`
- `PSC-ONE/software/os/src/kernel_process.c`
- `PSC-ONE/software/os/src/kernel_syscall.c`
- `PSC-ONE/software/os/src/kernel_trap.c`
- `PSC-ONE/software/os/src/lcd_api.c`
- `PSC-ONE/software/os/src/lcd_api.h`
- `PSC-ONE/software/os/src/shell.c`
- `PSC-ONE/software/os/src/syscall.h`
- `PSC-ONE/software/os/src/timer_api.h`
- `PSC-ONE/software/os/src/timer_measure.c`
- `PSC-ONE/software/os/src/user.c`
- `PSC-ONE/software/os/src/user.h`
- `PSC-ONE/software/os/tests/jpeg/check_boundaries.py`
- `PSC-ONE/software/os/tests/jpeg/host.c`
- `PSC-ONE/software/os/tests/jpeg/run.py`
- `PSC-ONE/software/os/third_party/README.md`
- `PSC-ONE/software/os/third_party/tjpgd`

## 2. TJpgDec情報

- Repository: Bodmer/TJpg_Decoder
- URL: https://github.com/Bodmer/TJpg_Decoder
- Tag: V1.1.0
- Commit: `71bfc2607b6963ee3334ff6f601345c5d2b7a8da`
- 選定理由: 公開タグ、ChaN TJpgDec R0.03、公式2023年パッチを含む安定したC実装。
- License: ChaNのBSD系許諾。Bodmer追加部分はFreeBSD/BSD-2-Clause。
- 著作権・ライセンスはsubmodule内で維持。third_party/README.mdにも記載。

## 3. submodule構成

`PSC-ONE/software/os/third_party/tjpgd`が上記commitを参照します。
`.gitmodules`とgitlinkだけstage済み（許可されたsubmodule登録操作）。
submodule内はcleanです。ビルド用の設定切替はbuild内の相対symlinkを使用します。

対象を指定したinit/updateに加え、空の検証用親リポジトリのindexへ同じgitlinkを
登録し、`git submodule update --init --recursive`でGitHubから取得できることを
確認しました。検証先は`/tmp/psc-jpeg-submodule-ipfc4mv0`です。
commitは検証リポジトリにも作っていません。変更済み親リポジトリの
`git clone --recurse-submodules`自体は、ユーザーのcommit/push後に検証する必要があります。
取得手順はREADMEに記載済みです。

## 4. 実装データフロー

```text
jpeg command -> jpeg_view -> FAT32 stream -> TJpgDec
 -> RGB888 MCU -> LCD rectangle syscall -> kernel LCD driver -> ILI9488 RGB666
```

ヘッダを安全確認後に読み直します。圧縮画素のデコードは一度で、フルフレーム
バッファはありません。1 MCUにつき1 window設定・1 syscallです。

## 5. FAT32変更

既存fat32_readは変更せず、fat32_stream.cにopen/read/skip/closeを追加。
ファイル位置・クラスタ・セクタ・volume状態・512Bキャッシュを保持します。
通常EOFは成功＋短いread。SDエラー、BPBエラー、途中EOC、不正クラスタを区別。
Brent循環検出とvolumeサイズによる走査上限を設定しています。

## 6. LCD変更

lcd_begin_rgb888でCOLMOD=0x66、MADCTL=0x88、scroll=0を明示。
lcd_write_rgb888_rectで最大16×16のpacked RGB888を送信します。
既存のIPS反転・RGB/BGR設定を維持しています。RGB565変換はありません。

syscall 92=begin、93=rect。既存ABIのa3=sysno、a0=x、a1=y、a2=width、
a4=height、a5=buffer。Sv32各ページのV/U/R、user範囲、座標を検査し、
最大768Bのスタック上スナップショットを同期転送します。

## 7. 対応範囲

Baseline DCT、8bit、YCbCr 4:4:4/横4:2:2/4:2:0、grayscale、restart marker。
1〜320 × 1〜480、原寸・左上。FAT32、MBR先頭パーティション、ルート、大文字8.3。

## 8. 非対応範囲

Progressive、CMYK/YCCK/RGB JPEG、12bit、Lossless、複数scan、EXIF回転、
縦4:2:2、LFN、subdirectory、縮小・resize・framebuffer・MicroPython API・DMA。
表再定義、特殊な成分ID/Huffman表割当、512Bを超える表セグメントも非対応です。
詳細はREADMEの対応範囲を参照してください。

## 9. RAM使用量

| 項目 | RV32での量 |
|---|---:|
| TJpgDec work | 4,096B（内部入力512B・MCU/outputを含む） |
| FAT32 stream | 580B（sector buffer 512Bを含む） |
| JDEC | 132B |
| その他session状態 | 16B |
| session合計 | 4,824B |
| user BSS増分 | 4,832B（busy/alignment込み） |
| LCD temporary | 最大768B、staticではなく呼出中stack |
| kernel BSS増分 | 4,112B |
| 全static増分 | 8,944B = 約8.73KiB |

計測のため既存Machine IRQ stack 4KiBがLTOで除去されなくなったことが、
6〜8KiB目標を少し超える主因です。デコーダ経路自体は約4.72KiBです。
malloc/free/MicroPython heapは使用していません。

## 10. ビルドサイズ・配置

| 対象 | section | 前(B) | 後(B) | 差分(B) |
|---|---|---:|---:|---:|
| kernel | .text | 26576 | 28560 | +1984 |
| kernel | .rodata | 194880 | 194936 | +56 |
| kernel | .data | 0 | 0 | 0 |
| kernel | .bss | 904928 | 909040 | +4112 |
| shell | .text | 191724 | 203552 | +11828 |
| shell | .rodata | 52788 | 54548 | +1760 |
| shell | .data | 16 | 16 | 0 |
| shell | .bss | 272872 | 277704 | +4832 |

TJpgDec本体は.text=5716B、.rodata=1336B、合計7052B。
アダプタはshell text/rodata、work/stream/JDECはshell BSSのsessionに配置。
mapには.srodata等の別セクションも存在し、上表と分けて確認しています。

page poolを`0x00335000〜0x00400000`に制限し、shell読込先との重複を解消。
基点は維持。831488Bのpoolからshell切上げ540672B、stack131072B、
page tables予算32768Bを引き、126976Bの余裕があります。リンカASSERTで確認。
旧poolは`0x00333000〜0x00433000`。user VA上限は0x00500000のままです。
map比較はbuild/jpeg_phase1_beforeとbuild/jpeg_phase1_afterに保存済み。

## 11. ビルド・テスト

| コマンド | 結果 |
|---|---|
| `make -C PSC-ONE/software/os MODE=psc Build=build/jpeg_phase1_before kernel_mem build/jpeg_phase1_before/user.mem` | PASS（変更前） |
| `make -C PSC-ONE/software/os MODE=psc Build=build/jpeg_phase1_after kernel_mem build/jpeg_phase1_after/user.mem` | PASS（変更後） |
| `make -C PSC-ONE/software/os MODE=psc kernel_mem build/user.mem build/bootrom.mem build/bootloader_fat32.mem` | PASS（最終） |
| `make -C PSC-ONE/software/os MODE=psc SIM_USER=minimal Build=build/jpeg_phase1_minimal kernel_mem build/jpeg_phase1_minimal/user.mem` | PASS |
| `myenv/bin/python PSC-ONE/software/os/tests/jpeg/run.py` | PASS、AddressSanitizer・画素比較・異常系 |
| `python3 PSC-ONE/software/os/tests/jpeg/check_boundaries.py` | PASS、LCD列/色/timeout・Sv32・timerモデル |
| `python3 PSC-ONE/hardware/sim/tests/review_regressions/run.py` | PASS、MMU legacy/v1/v2・timer・DMA RTL/C・UART・FAT32・psc.run |
| `git diff --check` / `git diff --cached --check` | PASS |
| 全CPU ISA/coreテスト・simulate_PSCOS・実機LCD | 未実施 |

64×64、128×128、320×240、320×480を3サンプリングで確認。
17×19、1×1、grayscale、restart、APP skip、SD/LCD途中障害後の再表示も確認。
Progressive、壊れたヘッダ、途中切断、EOI欠落、大画像、CMYK、12bitはエラー。

初回の`user_mem`という存在しないターゲット指定は、実際の`build/.../user.mem`
へ修正してPASS。ASan初回はサンドボックスのLeakSanitizer/ptrace制限で停止し、
同一テストを許可された制限外実行でPASS。LCDホストモデルの変数名衝突は
モデル側の最小修正で解消。これらを最終PASSと混同していません。
最終OSビルドに新規警告はなく、既存の未使用変数・関数とRWX segment警告が残ります。

通常simulate_PSCOSは複数のcleanを含むため、既存生成物を削除するそのターゲットは
実行せず、限定回帰を実施しました。テスト削除・弱体化はしていません。
ログはbuild/jpeg_phase1_after/*.logに保存しています。

## 12. 実機テスト手順

1. `git submodule update --init --recursive`。
2. 上記最終ビルド。必要に応じて現在のMBIOS/ブートローダを既存手順で更新。
3. kernel.memをKERNEL.MEM、user.memをUSER.MEMとしてSDルートへコピー。
4. Baseline・LCD以内の画像をTEST.JPGとしてSDルートへコピー。
5. 起動してUARTから`jpeg TEST.JPG`。
6. LCD表示、decode OK、time: xxx msを確認。

試験用COLORS.JPG、17X192.JPG等はbuild/jpeg_testsに生成済み。
詳細はREADMEの手順を参照してください。

## 13. 実機確認ポイント

R/B・反転・色の階調、portrait、上下左右/鏡像、TOP LEFT、原寸、MCU境界と端、
SDエラー後のシェル復帰、再表示、表示時間、既存LCD text/boot logo/MP/NPU。
既存タイマー使用中は計測を省略し、画像表示は継続することも確認してください。

## 14. 残る課題

実機の色・方向・実効時間、Machine timer IRQを含むCPU end-to-end確認。
Phase 2: 1/2・1/4・1/8縮小、センタリング、320×16 band、LCD FIFO/burst、
MicroPython psc.jpeg_view。今回は未実装です。

## 15. Git状態

commit/push/tagは未実施。submodule登録の2パス以外はstageしていません。
通常のgit diffにはuntrackedの新規実装ファイルが出ない点に注意してください。

```text
$ git diff --stat
 PSC-ONE/software/README.md               |   9 ++-
 PSC-ONE/software/os/Makefile             |  33 +++++++++-
 PSC-ONE/software/os/src/fat32.h          |  24 ++++++-
 PSC-ONE/software/os/src/kernel.h         |   2 +
 PSC-ONE/software/os/src/kernel_fpga.ld   |  11 +++-
 PSC-ONE/software/os/src/kernel_process.c |  10 ++-
 PSC-ONE/software/os/src/kernel_syscall.c |  42 ++++++++++++
 PSC-ONE/software/os/src/kernel_trap.c    |   1 +
 PSC-ONE/software/os/src/lcd_api.c        | 110 +++++++++++++++----------------
 PSC-ONE/software/os/src/lcd_api.h        |   6 +-
 PSC-ONE/software/os/src/shell.c          |  15 +++++
 PSC-ONE/software/os/src/syscall.h        |   4 ++
 PSC-ONE/software/os/src/timer_api.h      |   4 ++
 PSC-ONE/software/os/src/user.c           |  24 ++++++-
 PSC-ONE/software/os/src/user.h           |  19 ++++--
 15 files changed, 240 insertions(+), 74 deletions(-)
```

```text
$ git diff --cached --stat
 .gitmodules                           | 3 +++
 PSC-ONE/software/os/third_party/tjpgd | 1 +
 2 files changed, 4 insertions(+)
```

```text
$ git status --short
M  .gitmodules
 M PSC-ONE/software/README.md
 M PSC-ONE/software/os/Makefile
 M PSC-ONE/software/os/src/fat32.h
 M PSC-ONE/software/os/src/kernel.h
 M PSC-ONE/software/os/src/kernel_fpga.ld
 M PSC-ONE/software/os/src/kernel_process.c
 M PSC-ONE/software/os/src/kernel_syscall.c
 M PSC-ONE/software/os/src/kernel_trap.c
 M PSC-ONE/software/os/src/lcd_api.c
 M PSC-ONE/software/os/src/lcd_api.h
 M PSC-ONE/software/os/src/shell.c
 M PSC-ONE/software/os/src/syscall.h
 M PSC-ONE/software/os/src/timer_api.h
 M PSC-ONE/software/os/src/user.c
 M PSC-ONE/software/os/src/user.h
A  PSC-ONE/software/os/third_party/tjpgd
?? PSC-ONE/software/os/PHASE1_REPORT.md
?? PSC-ONE/software/os/README.md
?? PSC-ONE/software/os/src/fat32_stream.c
?? PSC-ONE/software/os/src/jpeg/
?? PSC-ONE/software/os/src/timer_measure.c
?? PSC-ONE/software/os/tests/
?? PSC-ONE/software/os/third_party/README.md
```

```text
$ git submodule status
 ec8e5a29845b97b515299b89c523831b41367cda PSC-ONE/hardware/sim/riscv_tests (heads/master)
 c30457480f8a905e252fb09ea688713a86e9da49 PSC-ONE/hardware/sim/yosys (v0.68-136-gc30457480)
 7de32aa1aed87595ec399772e624e0c1f790ebd5 PSC-ONE/software/micropython/micropython (v1.28.0-728-g7de32aa1a)
 71bfc2607b6963ee3334ff6f601345c5d2b7a8da PSC-ONE/software/os/third_party/tjpgd (V1.1.0)
```

```text
$ git -C PSC-ONE/software/os/third_party/tjpgd status --short
(出力なし: clean)
```

