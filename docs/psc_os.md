<p align="center">
  <a href="https://github.com/QPSC-Design/PSC-ONE">
    <img src="images/PSC-ONE_Logo.png" width="640" alt="PSC-ONE logo">
  </a>
</p>

# PSC-OS

[ドキュメント一覧](README.md) · [MMU](cpu_mmu.md) · [API](psc_os_api.md) · [ソフトウェア](../software/README.md)

PSC-OSはPSC-ONEのRISC-V CPU、メモリ、周辺回路を検証・利用するための独自OSです。
BootROM、M-modeの低レベル処理、S-modeカーネル、U-modeシェル／アプリケーションを組み合わせます。
Linuxや既存RTOSをベースにしたOSではなく、MicroPython、JPEGデコーダ、TFLite関連部品を個別に取り込んでいます。

<!-- contents -->
- [構成とソース](#構成とソース)
- [起動フロー](#起動フロー)
- [ビルド構成](#ビルド構成)
- [メモリと権限](#メモリと権限)
- [タスク実行と割込み](#タスク実行と割込み)
- [シェルとファイル](#シェルとファイル)
- [外部ELFの実行](#外部elfの実行)
- [MicroPython、JPEG、推論](#micropythonjpeg推論)
- [検証](#検証)
<!-- /contents -->

## 構成とソース

| 層 | 主な役割 | ソース |
| --- | --- | --- |
| BootROM / MBIOS | 起動、特権移行、trap delegation | [psc_mbios.S](../software/os/src/boot/psc_mbios.S) |
| SD bootloader | SDからkernel/userイメージをロード | [raw-sector版](../software/os/src/boot/bootloader.c)、[FAT32版](../software/os/src/boot/bootloader_fat32.c) |
| カーネル | ページ確保、プロセス初期化、コード公開 | [kernel.c](../software/os/src/kernel/kernel.c) |
| タスク切替 | 実行可能タスクの選択、SATP/context切替 | [kernel_process.c](../software/os/src/kernel/kernel_process.c) |
| trap / syscall | 例外・割込み、ECALLの受付 | [kernel_trap.c](../software/os/src/kernel/kernel_trap.c)、[kernel_syscall.c](../software/os/src/kernel/kernel_syscall.c) |
| シェル | コマンド実行、FAT32、ELF起動、MicroPython | [shell.c](../software/os/src/shell/shell.c) |
| ELF | 形式検査、配置、実行と復帰 | [elf_loader.c](../software/os/src/kernel/elf_loader.c)、[kernel_elf.c](../software/os/src/kernel/kernel_elf.c) |

<img src="images/PSC_OS.jpg" width="800" alt="PSC-OS conceptual software architecture">

> 画像は従来の概念図を維持しています。図ではFAT32がカーネル内にありますが、現行のshell/ELF経路は
> FAT32をユーザーイメージへリンクし、SDアクセスをシステムコール経由で行います。
> この図を実装上の特権境界やリンク配置そのものとは解釈しないでください。

## 起動フロー

FAT32 boot構成は次の順序でシェルまで進みます。

```text
BootROM / MBIOS
  → FAT32 bootloader
  → KERNEL.MEMを0x00200000、USER.MEMを0x00400000へロード
  → kernelの初期化
  → ページテーブル、idle、shellの準備
  → U-mode shell
  → PSC_OS>
```

ロードアドレスは既定のPSC構成です。ビルド時の定義とリンカスクリプトが最終的な配置を決めます。
raw-sector版は別のイメージ配置を使います。FAT32上のMEMファイルとrawセクタのIMGを混同しないでください。
[ボードの起動案内](../board/PSC-ONE/README.md)に方式の区別を記載しています。

カーネルは実行用のページへシェルをコピーし、`sync_user_code()` でD-cacheの書戻しとI-cacheの同期を行います。
UARTの `PSC_OS>` は起動完了の目安です。boot log内のBSS位置・サイズ・バージョンはビルドごとに変わります。

## ビルド構成

[OS Makefile](../software/os/Makefile)の主なMODEは次のとおりです。

| MODE | 起動構成 | USER_BASE |
| --- | --- | --- |
| `sim` | direct、シミュレーション用 | `0x00400000` |
| `fpga_mem` | direct、FPGAメモリイメージ用 | `0x00400000` |
| `psc` | SD bootloader経由 | `0x00400000` |
| `sbi` | OpenSBI用の別構成 | `0x01000000` |

Clang、LLVM objcopy、RISC-Vツールチェーンと、Makefileが指定するライブラリ・依存ソースが必要です。
MicroPythonやTJpgDecなどの取得方式は[依存関係の案内](../software/os/third_party/README.md)を参照してください。
`CPU_VERSION` はソフトウェア機能の選択にも使われます。OSの設定だけでFPGA内のCPUが切り替わるわけではありません。

リポジトリルートからの例：

```sh
# PSC用のkernelと、別ロードするuserイメージをビルド
make -C PSC-ONE/software/os MODE=psc kernel_mem build/user.mem

# BootROMとFAT32 bootloaderをビルド
make -C PSC-ONE/software/os fpga_fat32_boot

# 最小の外部ELFサンプル
make -C PSC-ONE/software/os user_elf
```

生成物は `software/os/build/` 以下です。ビルドはSDカードへ自動コピーする手順ではありません。
FPGAへ登録するBootROM/bootloaderと、カード上のkernel/userを同じ構成に揃えてください。

## メモリと権限

カーネルはS-mode、シェルと通常のユーザーコードはU-modeで動作します。
ページテーブルは4 KiBの2段構成です。既定のユーザー仮想領域は
`0x00400000` から `0x00500000` 未満、通常シェルのスタックは128 KiBです。

`alloc_pages()` は起動後に前方へ確保するアロケータです。一般的なfree、swap、demand pagingは提供しません。
実際の空き領域はリンカシンボルで管理します。kernel/MMIOとuserのPTEフラグは分けていますが、
現行MMUはU/S・A/Dを検査しません。特権modeの区別を完全なメモリ隔離とみなすことはできません。
[MMUの動作と制限](cpu_mmu.md)を参照してください。

## タスク実行と割込み

`yield()` は実行可能タスクを選び、ページテーブルと実行contextを切り替えます。
M-mode timer trapによるプリエンプション経路もあり、スケジューラ用tickは1 msです。
通常起動はidleとshellを作り、`yield()`でshellへ移ります。
`kernel_main()` 内の追加kernel taskと `preemption_start()` は現在 `#if 0` です。
プリエンプションの実装があることと、通常起動で有効なことを区別してください。

U-mode trapではユーザーSPをそのままカーネルスタックに使わず、プロセスごとの8 KiBスタックへ切り替えます。
trap frameには整数レジスタとSEPC/SSTATUS/cause/valueを保存します。
M-mode割込み側も、S-mode処理の途中から再開できるcontextを保存します。

これは小規模な実験用タスク実行環境で、POSIXプロセス、fork、一般的なexecve、動的リンク、
優先度やリアルタイム期限の保証を提供するものではありません。

## シェルとファイル

シェルはUARTからコマンドを受け、診断、ファイル操作、描画、推論、MicroPythonを呼び出します。

```text
PSC_OS> fat32_ls
PSC_OS> run HELLO.ELF
PSC_OS> micropython
```

FAT32の一覧表示はLFNとUTF-8出力に対応します。一方、ELF・モデル・stream APIのファイル指定は
root内の大文字8.3名が基本です。一覧に長い名前が出ることは、その名前でopenできることを意味しません。

FAT32処理はシェル側、SDセクタI/Oはカーネルのドライバ経由です。
[API](psc_os_api.md)と[FAT32回帰](../software/os/tests/fat32/README.md)に利用条件があります。

## 外部ELFの実行

`run HELLO.ELF` はFAT32から最大32 KiBのELF32 RISC-V ET_EXECを読み、
PT_LOAD、範囲、整列、権限、重複、entryを検査してからkernel所有ページへ配置します。
`p_memsz - p_filesz` とページ余白はゼロ初期化します。

サンプル `HELLO.ELF` の実行例:

```text
PSC_OS> run HELLO.ELF
ELF: entry=00400000 sp=00500000 pages=3
Hello from user ELF!
run: exit 0
PSC_OS>
```

- 同時に1つのforeground ELF。
- 最大8 program headers、PT_LOAD用16ページ（64 KiB）。
- スタック4ページ（16 KiB）と未マップguard。
- entryは実行可能なfile-backed領域内。
- relocation、PIE、共有ライブラリ、TLS、引数・環境変数には未対応。

元シェルのtrap frameとルートテーブルを保存し、一時的にELFのアドレス空間へ切り替えます。
EXITまたは処理可能なユーザーfaultでシェルへ復帰します。新しいschedulerプロセスを生成する処理ではありません。
タイムアウトやkill機能はなく、無限ループするELFはforegroundを占有します。

| 既定PSC構成のVA | ELF実行時の用途 |
| --- | --- |
| `0x00400000..0x004fafff` | 必要なPT_LOADページのみをマップ |
| `0x004fb000..0x004fbfff` | stack guard、未マップ |
| `0x004fc000..0x004fffff` | U+R+Wスタック、Xなし |

外部ELFに許可するECALLは文字入出力、タイムアウト付き入力、整数出力、EXITだけです。
正確なABIは[API文書](psc_os_api.md)、制限と回帰は[ELFローダ](../software/os/tests/elf/README.md)を参照してください。

## MicroPython、JPEG、推論

MicroPythonはシェルと同じユーザーイメージへ組み込まれ、REPLと `psc` モジュールから
LED、timer、FAT32、SynapEngine、TFLiteを呼び出します。
独立した汎用Pythonプロセス環境ではありません。[PSCポート](../software/micropython/ports/psc/README.md)を参照してください。

JPEGはTJpgDecで順次デコードし、小さいRGB888矩形をsyscall経由でILI9488へ転送します。
全画面framebufferの確保を前提としません。対応形式とlandscape表示は[OS README](../software/os/README.md)にあります。

TFLiteは限定されたINT8 fully connectedモデルを扱う同期runtimeです。
TFLMインタプリタ全体を搭載しているわけではありません。CPU/Synap/PULPのC backend、
モデル上限8 KiB、arena 4 KiBなどの条件は[TFLite仕様](../software/os/src/api/tflite/README.md)を参照してください。

## 検証

RTLでOSを起動する場合は、リポジトリルートから次を実行します。

```sh
cd PSC-ONE/hardware/sim
make -f Makefile.pscos simulate_PSCOS CPU_VERSION=v1
```

長時間かかる試験です。通常起動の確認と、各機能のassert付き回帰は分けて扱います。

| 対象 | 検証手順 |
| --- | --- |
| fetch / Sv32 | [CPU別の非恒等マッピング回帰](../hardware/sim/tests/fetch_sv32/README.md) |
| ELF・例外・復帰 | [host / RTL回帰](../software/os/tests/elf/README.md) |
| FAT32一覧 | [sector/cluster境界、LFN、エラー回帰](../software/os/tests/fat32/README.md) |
| JPEG | [host検証と実機確認範囲](../software/os/README.md) |
| TFLite | [API回帰](../software/os/src/api/tflite/README.md)、[backend検証](../software/os/third_party/tflite/README.md) |

本書はソースを調べて作成したもので、新たなOS／RTL／実機PASSの報告ではありません。
