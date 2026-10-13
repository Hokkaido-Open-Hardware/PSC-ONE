# シミュレーション用FAT32 SDカードイメージ

`PSC-ONE/hardware/sim/` で実行します。生成に必要なのはPython 3とmakeだけです。
root権限、mount、loop device、実SDカード、追加Pythonパッケージは不要です。

```sh
make -f Makefile.sdcard
make -f Makefile.sdcard verify
```

`sdcard/sdcard.img` とSPIモデル用の `sdcard/sdcard.hex` を生成します。
生イメージのMBR、BPB、ルートディレクトリ、FATチェーンを
読み戻して、両入力とのバイト単位の完全一致を自動検証します。
`verify` は既存イメージを変更せずに検証だけを行います。
デフォルトの生成コマンドは毎回再生成するため、別の入力や古いタイムスタンプの
入力を指定しても、前回のイメージが使われ続けることはありません。

## 入力ファイル

`software/os/Makefile` の `kernel_mem` が `software/os/build/kernel.mem`、
`./build/user.mem` が `software/os/build/user.mem` を生成します。
`hardware/sim/Makefile.pscos` の `simulate_PSCOS` は両方を `hardware/sim/mem/`
へコピーし、その後OSの `build/` を削除します。

そのため、`Makefile.sdcard` は次の順で入力ディレクトリを選びます。

1. 両ファイルが存在すれば `../../software/os/build/`。
2. それ以外は `mem/` の両ファイル。

異なるディレクトリから一方ずつ自動選択することはありません。
実際の入力パスは実行コマンドに表示されます。更新日時による新旧の自動判定は
しないため、特定のビルドを使う場合は明示指定してください。

```sh
make -f Makefile.sdcard INPUT_DIR=mem
make -f Makefile.sdcard KERNEL_MEM=/path/to/kernel.mem USER_MEM=/path/to/user.mem
```

入力がない場合は生成前にエラーとビルド手順を表示し、既存イメージを維持します。
シミュレーションを走らせずに入力を用意するには、既存OSのビルド環境で次を実行します。

```sh
make -C ../../software/os MODE=sim kernel_mem ./build/user.mem
make -f Makefile.sdcard INPUT_DIR=../../software/os/build
```

入力のHEX文字、改行、空白などはそのままファイル内容として格納します。
HEXから命令バイナリへの変換、エンディアン変換、改行変換は行いません。
ルートの8.3名は `KERNEL  MEM` / `USER    MEM`、小文字表示フラグを設定して
`kernel.mem` / `user.mem` としています。PSC-OSのstream APIには大文字名で渡します。

## 生イメージの構成と互換性

| 項目 | 値 |
|---|---|
| カード全体 | 64 MiB = 67,108,864 bytes = 131,072 sectors |
| セクタ長 / クラスタ長 | 512 bytes / 1 sector |
| LBA 0 | MBR、第1パーティションのtypeは `0x0c` (FAT32 LBA) |
| パーティション | LBA 8192から122,880 sectors、カード末尾まで |
| 予約領域 | 32 sectors |
| ブートセクタ / FSInfo | LBA 8192 / 8193 |
| 予備ブートセクタ / FSInfo | LBA 8198 / 8199 |
| FAT | 2面、各945 sectors、LBA 8224 / 9169 |
| データ領域 | LBA 10114から、120,958 clusters |
| ルート | cluster 2、1クラスタで完結 |

FAT32判定に必要な65,525以上のデータクラスタを確保しています。
空き領域はゼロです。ホスト上では疎ファイルになることがありますが、読み出した
バイト列は通常のカード全体の生イメージと同じです。容量不足はエラーにします。
ファイル末尾のセクタ余白はゼロで、ディレクトリエントリのサイズに含めません。
タイムスタンプとボリュームIDは固定で、同じ入力から同じイメージを生成します。

互換性の根拠となる既存実装:

- `software/os/src/fs/fat32.c`: MBRの第1パーティション開始LBAを参照。
- `software/os/src/fs/fat32_stream.c`: 512-byte sector、BPBとFATチェーン、8.3名を参照。
- `software/os/src/boot/boot_fat32.c`: MBRに対応し、検索時にroot cluster 2を前提とする。
- `hardware/rtl/soc/mmio/PSC_SDCARD/src/PSC_SDCard.sv`: LBA `<= 0x1000` の
  書き込み保護があるため、FAT・ルートを含むパーティション全体をその後方に配置。

生イメージのLBA `n` は、ファイル先頭から `n * 512` バイトの位置にある512バイトです。
MBR以前のヘッダや、セクタ間の区切りデータはありません。

## シミュレータ用HEX

既存イメージから指定LBAの1セクタを追加生成できます。LBAは10進または `0x` 付き16進です。

```sh
make -f Makefile.sdcard sector LBA=0       # sdcard/sector_00000000.hex (MBR)
make -f Makefile.sdcard sector LBA=0x2000  # sdcard/sector_00002000.hex (BPB)
```

ファイル名の8桁はLBAの16進表記です。各HEXファイルには2桁の16進数を1行1バイト、
512行格納します。行番号 `i + 1` は `sdcard.img` のオフセット `LBA * 512 + i`
のバイトに一致し、`$readmemh` で `reg [7:0] sector_data [0:511]` に読み込めます。
入力 `.mem` の32-bitワードを並べた形式とは異なります。

カード全体の `sdcard.hex` は、`@バイトオフセット` と8-bit HEXトークンによる
`$readmemh` 形式です。全ゼロのセクタを省略するため、モデルは配列をゼロ初期化して
から読み込みます。HEXを復元したバイト列は `sdcard.img` と一致します。
既存の生イメージからHEXだけを再生成する場合は次を実行します。

```sh
make -f Makefile.sdcard hex
```

`hardware/rtl/model/SDCARD_model/sdcard_spi_model.v` は、起動時に
`IMAGE_HEX`（既定値 `sdcard/sdcard.hex`）を `$readmemh` で読み込みます。
`IMAGE_SECTORS` の既定値は131,072（64 MiB）です。CMD17では指定LBAの512バイトを
返し、CMD24では同じ配列へ書き込みます。書き込み内容はシミュレーション中だけ保持し、
ホスト上の `.img` / `.hex` は変更しません。範囲外LBAはR1 address errorを返します。
HEXファイルが見つからない場合は `$fatal` で停止します。
固定パターンと `DATA_HEX`、4セクタの `stored_data` は廃止しました。
既存コントローラはこのR1エラーで `ST_WAIT_R1` に留まるため、範囲外テストでは
コントローラがSPI経由で受けた `0x20` と、読み書きが行われていないことを確認します。
コントローラ側でのエラーステータスへの遷移は未対応です。

`PSC_ONE_Chip_sim.v` もこのHEXを読み込みます。SoCシミュレーションを始める前に、
使用したいkernel/userの組から `make -f Makefile.sdcard` を実行してください。
この変更はカードモデルの接続であり、SoCの起動方式をSDブートへ切り替えるものではありません。

## 検証と管理対象

```sh
make -f Makefile.sdcard test
make -f Makefile.mmio.sd simulate_PSC_SD MODE=verilator
# Icarusでも実行可能
make -f Makefile.mmio.sd simulate_PSC_SD MODE=icarus
```

Pythonの境界サイズ・空ファイル・任意バイト・壊れたFATチェーン・入力不足・
HEX/LBA対応・カード全体のHEX復元一致の検査に加え、ホストCコンパイラでPSC-OSの `boot_fat32.c` と
`fat32_stream.c` をコンパイルし、ASan/UBSan付きで検索と読み戻しを検証します。
`test` は通常の入力からイメージを再生成し、テスト用データと実際の入力の両方を
PSC-OSのコードで検証するため、入力 `.mem` ファイルも必要です。
この追加テストにはGCC互換のCコンパイラが必要です（`CC` で指定可）。
ブートコードのホスト検証用コピーでは、RV32専用の型定義を含む `common.h` のincludeを
必要なconsole関数宣言に置き換えます。FAT32関数本体とOSソースは変更しません。
テスト生成物は `hardware/sim/build/sdcard-tests/` に保存します。

SPIモデルのCocotbテストは `cocotb_tb/mmio/sd_test.py` に集約しています。
リセット・初期化、MBR/BPB/FAT/ルート/kernel/userの代表セクタとCRC、6セクタの
書き戻しとLBA分離、範囲外LBAの拒否を確認します。Cocotbを使用できるPython環境を
有効化してください。`simulate_PSC_SD` は先に `Makefile.sdcard` でイメージを生成し、
既存のclean処理を呼ばず、`build/sdcard-model-<MODE>/` で実行します。
`make -f Makefile.sdcard test-model` からも同じテストを呼び出せます。

生成スクリプトは `python_tool/make_sdcard.py`、検証コードは
`python_tool/test_sdcard.py` と `python_tool/sdcard_host_check.c` です。
Makefile・スクリプト・このREADME・`.gitignore` を管理対象とし、
`sdcard/` の生成物は `.gitignore` で除外しています。既存の `.gitkeep` は維持します。
既存のcleanターゲットを呼ぶ処理やファイルを削除するターゲットはありません。
