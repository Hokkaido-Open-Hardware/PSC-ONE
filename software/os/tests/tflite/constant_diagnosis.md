指定MODEL.TFLのraw accumulator調査（2026-09-13）

原因はモデルの取り違え。ユーザー指定ファイル
`tests/tflite/build/tflite-model/MODEL.TFL` は、全weight/biasを0にした
parser/FAT32検査用fixtureである。hostでも実機報告と同じ全20 channel acc=0、
FC1 requant/output=-128、FC2 requant/output=7、最終[7,7,7,7]を再現した。
推論用モデルは `tests/tflite/build/tflite-model/phase3/MODEL.TFL`。
こちらは同じhost/FAT32/runtimeで[-36,27,18,8]となりdemo oracle PASS。
パスはPSC-ONE/software/osからの相対パス。

| 項目 | 指定モデル | 推論用phase3モデル |
|---|---|---|
| bytes | 1568 | 1568 |
| SHA-256 | 2534b4a0928d710fff4601c1c6a520a57d00971cc02b588bbda2c1048dc6c6bf | cced9beaa289713f1eb6fe614df9e68d7147959bc5d0ed7c143003a7be70cd1e |
| 全ファイルunsigned byte sum | 27658 | 76304 |
| FC1 output zero-point | -128 | -17 |
| 最終出力 | [7,7,7,7] | [-36,27,18,8] |

生成元の証拠: `model_fixture.h` のfixture()が各Bufferを0で初期化し、
`host.cc`が検査出力ディレクトリ直下のMODEL.TFLへ書く。
`run.py`はその後generate_model.pyをphase3サブディレクトリで実行する。
`phase3.cc`のdemo()はweight/biasを設定しhidden zero-pointを-17に変更する。
同名・同サイズだが同じバイト列ではない。

| Tensor | Buffer index | model先頭からのdata offset | length | 指定モデルbyte sum | 推論用byte sum |
|---|---:|---:|---:|---:|---:|
| 1 / FC1 weight | 1 | 288 | 256 | 0 | 30716 |
| 2 / FC1 bias | 2 | 192 | 64 | 0 | 8256 |
| 4 / FC2 weight | 3 | 112 | 64 | 0 | 7427 |
| 5 / FC2 bias | 4 | 80 | 16 | 0 | 2136 |

全てmodel base + offsetを参照する。全biasアドレスは4-byte aligned。
以下はhost実測（実機アドレスではない）。最初のダンプには要求された
先頭32 byte、全biasのlittle-endian byte復元とReadScalar値を含む。

指定モデルの定数:

```text
MODEL pointer=0x00000000005d0be0 bytes=1568 byte_sum=27658
Tensor=1 buffer=1 data_offset=288 length=256 pointer=0x00000000005d0d00 align_mod4=0 byte_sum=0
 first32 hex: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
Tensor=2 buffer=2 data_offset=192 length=64 pointer=0x00000000005d0ca0 align_mod4=0 byte_sum=0
 first32 hex: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
 bias LE32: 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
 bias ReadScalar: 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
Tensor=4 buffer=3 data_offset=112 length=64 pointer=0x00000000005d0c50 align_mod4=0 byte_sum=0
 first32 hex: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
Tensor=5 buffer=4 data_offset=80 length=16 pointer=0x00000000005d0c30 align_mod4=0 byte_sum=0
 first32 hex: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
 bias LE32: 0 0 0 0
 bias ReadScalar: 0 0 0 0
```

指定モデルのFC1 channel 0:

```text
FC1 c=0 k=0 input=-128 weight=0 product=0 running_dot=0
FC1 c=0 k=1 input=127 weight=0 product=0 running_dot=0
FC1 c=0 k=2 input=-3 weight=0 product=0 running_dot=0
FC1 c=0 k=3 input=0 weight=0 product=0 running_dot=0
FC1 c=0 k=4 input=1 weight=0 product=0 running_dot=0
FC1 c=0 k=5 input=-1 weight=0 product=0 running_dot=0
FC1 c=0 k=6 input=64 weight=0 product=0 running_dot=0
FC1 c=0 k=7 input=-64 weight=0 product=0 running_dot=0
FC1 c=0 k=8 input=7 weight=0 product=0 running_dot=0
FC1 c=0 k=9 input=-11 weight=0 product=0 running_dot=0
FC1 c=0 k=10 input=31 weight=0 product=0 running_dot=0
FC1 c=0 k=11 input=-32 weight=0 product=0 running_dot=0
FC1 c=0 k=12 input=90 weight=0 product=0 running_dot=0
FC1 c=0 k=13 input=-100 weight=0 product=0 running_dot=0
FC1 c=0 k=14 input=2 weight=0 product=0 running_dot=0
FC1 c=0 k=15 input=-2 weight=0 product=0 running_dot=0
FC1 c=0 raw_dot=0 row_sum=0 bias=0
```

推論用モデルの定数:

```text
MODEL pointer=0x00000000005d0be0 bytes=1568 byte_sum=76304
Tensor=1 buffer=1 data_offset=288 length=256 pointer=0x00000000005d0d00 align_mod4=0 byte_sum=30716
 first32 hex: fc 03 fb 02 fa 01 f9 00 07 ff 06 fe 05 fd 04 fc fe 05 fd 04 fc 03 fb 02 fa 01 f9 00 07 ff 06 fe
Tensor=2 buffer=2 data_offset=192 length=64 pointer=0x00000000005d0ca0 align_mod4=0 byte_sum=8256
 first32 hex: 77 ff ff ff 8a ff ff ff 9d ff ff ff b0 ff ff ff c3 ff ff ff d6 ff ff ff e9 ff ff ff fc ff ff ff
 bias LE32: -137 -118 -99 -80 -61 -42 -23 -4 15 34 53 72 91 110 129 148
 bias ReadScalar: -137 -118 -99 -80 -61 -42 -23 -4 15 34 53 72 91 110 129 148
Tensor=4 buffer=3 data_offset=112 length=64 pointer=0x00000000005d0c50 align_mod4=0 byte_sum=7427
 first32 hex: fb 00 05 fd 02 fa ff 04 fc 01 06 fe 03 fb 00 05 06 fe 03 fb 00 05 fd 02 fa ff 04 fc 01 06 fe 03
Tensor=5 buffer=4 data_offset=80 length=16 pointer=0x00000000005d0c30 align_mod4=0 byte_sum=2136
 first32 hex: 9b ff ff ff ee ff ff ff 41 00 00 00 94 00 00 00
 bias LE32: -101 -18 65 148
 bias ReadScalar: -101 -18 65 148
```

推論用モデルのFC1 channel 0:

```text
FC1 c=0 k=0 input=-128 weight=-4 product=512 running_dot=512
FC1 c=0 k=1 input=127 weight=3 product=381 running_dot=893
FC1 c=0 k=2 input=-3 weight=-5 product=15 running_dot=908
FC1 c=0 k=3 input=0 weight=2 product=0 running_dot=908
FC1 c=0 k=4 input=1 weight=-6 product=-6 running_dot=902
FC1 c=0 k=5 input=-1 weight=1 product=-1 running_dot=901
FC1 c=0 k=6 input=64 weight=-7 product=-448 running_dot=453
FC1 c=0 k=7 input=-64 weight=0 product=0 running_dot=453
FC1 c=0 k=8 input=7 weight=7 product=49 running_dot=502
FC1 c=0 k=9 input=-11 weight=-1 product=11 running_dot=513
FC1 c=0 k=10 input=31 weight=6 product=186 running_dot=699
FC1 c=0 k=11 input=-32 weight=-2 product=64 running_dot=763
FC1 c=0 k=12 input=90 weight=5 product=450 running_dot=1213
FC1 c=0 k=13 input=-100 weight=-3 product=300 running_dot=1513
FC1 c=0 k=14 input=2 weight=4 product=8 running_dot=1521
FC1 c=0 k=15 input=-2 weight=-4 product=8 running_dot=1529
FC1 c=0 raw_dot=1529 row_sum=-4 bias=-137
```

寿命・production配置の確認:

- model_bufferは16-byte alignedの静的8192-byte配列。read_modelのローカル
  fat32_file_t.sector_bufとは別領域。fat32_stream_readはsector_bufからコピーし、
  closeはopened/cached_lbaだけを変更する。
- prepareのFC.w/FC.biasはmodel_buffer内を借用する。resetはRuntimeだけをクリアする。
  load/inspect_fileは前モデルを無効化してから読み直す。invokeはモデルに書かない。
- hostの両モデルでread/close直後、prepare後、最初のinvoke後の全定数ダンプ一致を確認。
- MODE=pscで新規ビルドしたshell.elfではmodel_buffer=[0x004513f0,0x004533f0)、
  Runtime=[0x004546e0,0x004558b0)。linker上のstack bottom=0x00477680。
  これは今回ビルドしたELFの仮想アドレスで、実機搭載済みELFの実測ではない。
- user.ldは.bssを配置し、Makefileのobjcopyは.bssをbinへ含める。
  create_processはuser imageをページ単位でコピー・マップする。
  kernelのSD syscallも静的kbufから呼び出し側sector_bufへコピーする。
- INT32 biasはFlatBuffers::ReadScalarで読む。診断用byte単位LE32復元とも一致。
  全INT8 weightがファイルそのものから0なので、unaligned accessやcacheを仮定せず
  raw dot=0を説明できる。production cache/RTLに不具合がないと証明したわけではない。

追加した診断:

- tflite_api.h / tflite_runtime.cc: 読み取り専用のmodel/FC診断API。
- tflite_file.c: tflite_runのread/prepare/invoke間でダンプし、最初のFC channelを計算表示。
  timed invoke内にはログを追加していない。load時間にはsectorアドレス出力が入るため
  今回の診断ビルドをload速度の比較には使わない。
- tests/tflite/host.cc: `tflite_host --diagnose /path/to/MODEL.TFL`で任意ファイルを
  実際のFAT32 readerとCPU runtimeに通す。終了コードは診断実行の成否で、
  demo oracleのPASS/FAILはログで確認する。
- production RTL、量子化処理、SynapEngine、Makefileは変更していない。

検証:

- host run.py: PASS。3628 parser/profile/FAT32 checks、47 models/cases、
  712 channel比較、65560 multiplier比較、Phase4 288 invokes/2880 stage比較、driver checks。
- 指定モデル: 現象再現PASS、demo oracle比較は意図どおりFAIL。
- phase3モデル: demo oracle PASS、[-36,27,18,8]。
- 両モデルの定数寿命比較: PASS（read/prepare/invokeの3地点）。
- MODE=psc shell.binビルド: PASS。既存のRWX LOAD segment警告あり。
- git diff --check: PASS。
- 最初のsandbox内host実行はLeakSanitizerのptrace制約で終了。
  sandbox外でASan/UBSan/LeakSanitizerを有効のまま再実行しPASS。
- 今回RTL再実行と実機UART測定は未実施。既存phase4 RTL UARTログには
  [-36,27,18,8]とPASSがあるが、今回の指定モデルを使った新規測定ではない。
  FPGA接続デバイス(/dev/ttyUSB*, /dev/ttyACM*)はこの環境では見つからなかった。

次の実機確認ではphase3/MODEL.TFLをSDカードのMODEL.TFLとして使用する。
定数ダンプを続ける場合は今回の診断ビルドでtflite_run MODEL.TFL cpuを実行し、
上記sum/offset/biasと照合する。SDカードの書き換えや実機への転送は実施していない。

ログ/生成物:

- /tmp/psc-tflite-specified-model.log
- /tmp/psc-tflite-inference-model.log
- /tmp/psc-tflite-constant-debug.log
- /tmp/psc-tflite-constant-fpga.log
- /tmp/psc-tflite-constant-fpga/shell.elf, shell.bin, shell.map

Git: add/commit/push等は実施せず。開始時からのshell.cとPSC_ONE_Boot_axi.vの
変更はそのまま保持。今回の変更4ファイルと本報告の新規1ファイル。削除なし。
