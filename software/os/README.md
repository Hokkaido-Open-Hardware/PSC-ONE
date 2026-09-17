# PSC-OS JPEG表示（Phase 1）

`jpeg TEST.JPG`で、SDカードのBaseline JPEGを480×320横向きLCDの左上へ
原寸表示します。JPEG全体やフルフレームバッファはRAMへ確保しません。
LCD内部GRAMが表示画像を保持します。画像外の領域は塗りつぶしません。

## ビルドと実機テスト

リポジトリのルートから実行します。既存のRISC-V Clang/GCC builtins、
picolibc、MicroPythonビルド環境が必要です。TJpgDecの取得・ライセンスは
[third_party/README.md](third_party/README.md)を参照してください。

```sh
git submodule update --init --recursive
make -C PSC-ONE/software/os MODE=psc kernel_mem build/user.mem
```

このコマンドは既存のclean targetを呼びません。FAT32ブートローダを使う場合：

1. `software/os/build/kernel.mem`をSDルートへ`KERNEL.MEM`としてコピー。
2. 同じディレクトリの`user.mem`を`USER.MEM`としてコピー。
3. 対応形式のJPEGをSDルートへ`TEST.JPG`としてコピー。
4. PSC-ONEを再起動し、UARTシェルで`jpeg TEST.JPG`を実行。
5. 成功時は`JPEG 320x240`、`decode OK`、`time: ... ms`が表示されます。

`KERNEL.MEM`と`USER.MEM`は同じビルドから取得してください。
`.bin`を`.mem`へ名前変更して使わないでください。
FAT32ブートローダはテキスト形式のMEMファイルを読み込みます。

初回導入や古いMBIOSを使用している場合、現在のBootROM/FAT32ブートローダも
既存のFPGA書込み手順に従って更新してください。必要な生成コマンドは：

```sh
make -C PSC-ONE/software/os MODE=psc build/bootrom.mem build/bootloader_fat32.mem
```

時間計測は既存MBIOSのextension 3（Machine timer trap設定）を使用します。
50msのタイマー割り込みで16bitカウンタを延長し、open、ヘッダ確認、SD読込、
デコード、LCD完了までのtotal時間を測定します。1ms未満は切り捨てです。
既にタイマーが稼働している場合は横取りせず、画像表示だけを行い、
`time: unavailable (timer busy)`を出します。SoCのCLK_FREQ設定と実クロックが
一致することが必要です。50ms以上Machine IRQが抑止された場合や約71分を
超える計測は対象外です。現在のJPEG処理はIRQを抑止しません。

## 対応範囲

- Baseline DCT / 8bit / Huffman / 単一scan。
- YCbCr 4:4:4、横方向4:2:2、4:2:0。グレースケールも検証済み。
- 幅1〜480、高さ1〜320。縮小指定は常に0（原寸）。
- MBR先頭パーティションのFAT32、512Bセクタ、ルート直下。
- 大文字8.3名。ファイル名文字は英大文字・数字・`_`・`-`を受け付けます。
- 一般的な成分ID 1/2/3、YのHuffman表0、Cb/Crの表1を使用するJPEG。

Progressive、CMYK/YCCK/RGB JPEG、12bit、Lossless、複数scan、縦4:2:2、
EXIF自動回転、LFN、サブディレクトリ、リサイズ、MicroPython APIは対象外です。
APP/COMは読み飛ばします。ヘッダ走査は128KiBまで、表セグメントは512Bまで、
表の再定義は非対応です。4KiBの作業領域を超える表構成は明示的にエラーにします。

## 実装構造

```text
shell.c: jpeg
  -> jpeg_view.c: open / metadata / prepare / decode / close
  -> fat32_stream.c: 512Bの逐次入力・前方向skip
  -> jpeg_headers.c: セグメント長とPhase 1形式の事前確認
  -> submodule TJpgDec: RGB888 MCU矩形
  -> tjpgd_port.c: 1 MCUにつき1回のLCD syscall
  -> kernel_syscall.c: 座標・Sv32ページ・ユーザーバッファ検査
  -> lcd_api.c: window設定1回 + 3バイト/画素
  -> ILI9488: COLMOD=0x66 / MADCTL=0x88 / scroll=0
```

TJpgDecはヘッダ／表の内容を信頼する箇所があるため、PSC側で長さ、8bit精度、
サンプリング、表ID、Huffmanコード数・記号を検証してから使用します。
ヘッダだけを読み直し、圧縮画素ストリームは一度だけ読みます。
TJpgDecはMCU数を処理すると戻るため、アダプタでもEOI終端を確認します。
JPEGには画像全体のチェックサムがないため、構文として有効な画素ビット化けを
全て検出することはできません。

FAT32 APIは既存`fat32_read()`を変更せず追加しています：

- `fat32_open()`：名前・BPBを検査し、ルート検索とファイル状態を初期化。
- `fat32_stream_read()`：現在位置から読込み。0＋短い読込数は通常EOF。
- `fat32_skip()`：前方向の読捨て。SDエラーも検出。
- `fat32_close()`：状態無効化。動的メモリやclose syscallは不要。

状態は580B（RV32）：ファイル位置、サイズ、クラスタ、セクタ位置、
ボリューム情報、循環検出状態、共有512Bセクタバッファです。
不正クラスタ・途中EOCを区別し、Brent方式とボリュームサイズによる上限で
循環を検出します。破損チェーンを事前に全走査する方式ではありません。
負のエラーはclose/openまで保持します。

LCD ABIは既存のa3 syscall番号方式を使用します：

| syscall | a0 | a1 | a2 | a4 | a5 |
|---|---|---|---|---|---|
| 92: RGB888_BEGIN | — | — | — | — | — |
| 93: RGB888_RECT | x | y | width | height | RGBポインタ |

矩形は最大16×16、packed row-major RGB888です。右端・下端も実際の矩形幅で
送信します。カーネルは最大768Bをスタックへコピーして同期転送し、ポインタを
保持しません。RGB565変換はありません。既存のIPS反転とRGB/BGR設定を維持します。
タイムアウトは上位へ返し、失敗時はシェルへ戻ります。途中エラーでは部分表示が残ります。

## テスト画像・ホスト検証

PythonのPillowとホストGCCが必要です。生成物は`build/`以下です。

```sh
python3 PSC-ONE/software/os/tests/jpeg/run.py
python3 PSC-ONE/software/os/tests/jpeg/check_boundaries.py
python3 PSC-ONE/hardware/sim/tests/review_regressions/run.py
```

JPEGテストは実際のFAT32/TJpgDec/アダプタを使用し、SDとLCD境界をモデル化します。
AddressSanitizerを使うため、ptrace制限のある実行環境では通常のホスト環境で実行します。
これは実機やCPU RTL上でのJPEG表示確認の代わりではありません。

生成先`software/os/build/jpeg_tests/`：

- `64X642.JPG`、`128X1282.JPG`、`320X2402.JPG`、`480X3202.JPG`、`240X3202.JPG`：4:2:0。
- 末尾0は4:4:4、1は4:2:2。
- `17X192.JPG`：右端／下端の不完全MCU。
- `COLORS.JPG`：上から赤・緑・青・白・黒。480×320、四隅のTOP/BOTTOM LEFT/RIGHTと右向き矢印あり。
- `GRAY320.JPG`、`RESTART.JPG`：グレースケール、restart marker。
- `PROGRESS.JPG`、`BROKEN.JPG`、`TRUNC.JPG`、`NOEOI.JPG`：異常系。

任意の画像を`TEST.JPG`としてコピーして試せます。画像ビューア等による
保存時のProgressive化やEXIF回転に注意してください。

実機では以下を確認してください：

1. 物理的に左へ90度傾けたLCDで、boot logoと同じ480×320横向きになる。
2. COLORS.JPGが赤・緑・青・白・黒になり、R/B逆転や反転がない。
3. TOP LEFTが左上。上下左右・鏡像・スクロールずれがない。
4. 17×19画像の端や、MCU境界にずれ・欠けがない。
5. SD読込エラー、破損JPEG後もhelpや再度jpegを実行できる。
6. 連続jpeg、timer使用後、MicroPython復帰後も表示できる。
7. 表示時間、boot logo、LCD text、NPUの既存動作。

色の切り分けは`lcd_write_rgb888_rect()`と`IPS_MODE`、方向は
`lcd_begin_rgb888()`のMADCTL、配置は`jpeg_output()`に集約しています。

## メモリ配置とサイズ（実装時のビルド）

カーネル基点0x00200000、シェル読込先／ユーザーVA基点0x00400000は維持しました。
ページ割当上限だけをシェル読込先で打ち切り、リンカASSERTでシェルコピー、
別途割り当てる128KiBスタック、ページテーブル8ページ分の容量を検査します。
カーネル全体のメモリマップ再設計は行っていません。

| 項目 | 変更前 | 変更後 |
|---|---|---|
| kernel stack top | 0x00332FF0 | 0x00334800 |
| page pool | 0x00333000〜0x00433000 | 0x00335000〜0x00400000 |
| shell image / linked stack top | 0x0047E890 | 0x00483080 |
| user VA上限 | 0x00500000 | 同じ |

変更後のpage poolは831,488B。シェルを4KiBへ切上げて540,672B、別スタック
131,072B、ページテーブル予算32,768Bを引き、126,976Bの余裕があります。
既存のBSS内stack/guardとcreate_processの別stack割当は変更していません。

| セクション（B） | kernel前 | kernel後 | 差分 | shell前 | shell後 | 差分 |
|---|---:|---:|---:|---:|---:|---:|
| .text | 26,576 | 28,560 | +1,984 | 191,724 | 203,552 | +11,828 |
| .rodata | 194,880 | 194,936 | +56 | 52,788 | 54,548 | +1,760 |
| .data | 0 | 0 | 0 | 16 | 16 | 0 |
| .bss | 904,928 | 909,040 | +4,112 | 272,872 | 277,704 | +4,832 |

`.bss`はリンカ予約のユーザースタックも含みます。その他の.srodata等は上表の
.rodataとは別セクションです。TJpgDec本体の.textは5,716B、.rodataは1,336B、
計7,052B（Clang -O2 / RV32IM、最終map上）。

JPEG sessionはユーザーBSSに4,824B：work 4,096B、FAT32状態580B（うちbuffer
512B）、JDEC 132B、残り16B。workに内部入力512BとMCU/output作業領域を含み、
二重計上しません。busy/alignment込みのユーザーBSS増分は4,832Bです。
LCD temporaryは最大768Bの呼出中スタックで、static framebufferはありません。

時間計測を有効にしたため、それまでLTOで除去されていた既存のMachine IRQ
stack 4,096Bが残り、計測状態等と合わせてカーネルBSSが4,112B増えました。
**合計static RAM増分は8,944B（約8.73KiB）**で、6〜8KiB目標を少し超えます。
デコーダ経路自体は約4.72KiBで、超過はタイマー拡張によるものです。
IRQスタックを削って既存割り込み動作へ影響を与える最適化は行っていません。

## 検証範囲と次段階

OSビルド、JPEGホスト画素比較・異常系、LCDレジスタ列・タイムアウト、Sv32
バッファ検査、タイマー延長モデル、既存MMU/TIMER/DMA/UART/FAT32/psc.run回帰を
実施しています。実機LCD、CPU上のJPEG end-to-end、実測性能は未確認です。
通常のsimulate_PSCOS targetは複数のcleanを含むため、今回実行していません。

Phase 2候補：内蔵1/2・1/4・1/8縮小、センタリング、480×16 band buffer、
LCD TX FIFO/burst、MicroPython `psc.jpeg_view()`。現在はどれも未実装です。

## JPEG landscape修正

JPEGの寸法・MADCTLは`src/jpeg_display.h`に集約しています。
`JPEG_LCD_WIDTH=480`、`JPEG_LCD_HEIGHT=320`、`JPEG_LCD_MADCTL=0xE8`。
以前の0x88からMX/MVを変更し、MY/BGRは維持しました。textの320×480定義と
boot logoは変更していません。CASET=x、PASET=yのままで、画素のソフトウェア回転はありません。
スクロール領域はコントローラの物理480行のまま、開始位置を0に戻します。

根拠: [ILI9488 datasheet](https://files.waveshare.com/upload/2/2d/ILI9488_Data_Sheet.pdf)
§5.2.22/23 (CASET/PASET)、§5.2.30 (MADCTL)、既存tft_init_seqの0xE8。
480×320、240×320、320×240はホスト試験で受理、481×320と480×321は
image too largeを確認します。実機ではCOLORS.JPGの四隅・右向き矢印・全周枠を確認してください。
