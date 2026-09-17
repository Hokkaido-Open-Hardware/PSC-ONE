# PSC-ONE TFLite Phase 3 — CPU INT8 FullyConnected

## 実装と対象範囲

CPUだけで `INT8 [1,16] → FC 16→16 + ReLU → FC 16→4 → INT8 [1,4]`
を実行する。SynapEngineへの呼出しは追加していない。
`NONE` / `RELU`、INT8 activation/weight、optional INT32 bias、batch=1、固定shape、
単一SubGraph、per-tensor quantization、FC builtin version 4に限定する。
Phase 2の構造・意味検証を通した後、prepareでarena容量と整数演算範囲を確認する。
`RELU6`を含む他activation、Conv/Add/Mul/Softmax/Depthwise/custom/dynamic、
per-axis quantization、MicroPython bindingは未対応。

重みはTFLiteの対称量子化範囲[-127,127]、zero_point=0。
入力・出力zero_pointは[-128,127]の任意値。scaleは正のnormal float32に限定し、
biasのscale=input_scale*weight_scale、zero_point=0を検証する。

実行手順:

1. `load`: 既存FAT32 streamでモデルを共有8 KiB bufferへ読み、ファイルを閉じる。
2. `prepare`: 公式FlatBuffers verifierとPhase 2 profile検証、tensor配置、
   multiplier/shift、各weight row sum、activation clamp、演算範囲を準備する。
3. `invoke`: `dot = Σ(qx*qw)`をINT32で計算し、
   `acc = dot - input_zero_point*row_sum + bias`、公式requantization、
   output zero_point加算、INT8 saturation / fused ReLU clampを行う。

補正・bias加算式の一時値はINT64を使用し、最終accはINT32。
prepareは全INT8入力に対する各rowの上下限を計算する。
公式double-rounding helperのINT32左shift乗算とoutput zero_point加算が溢れない
保守的な範囲（INT32上下限から128を確保）を満たさないモデルは拒否する。
したがって、一般のTFLiteが読めるすべてのINT32 bias/scale組合せを受理するわけではない。
実効multiplierのshiftは[-31,30]。極小倍率は公式仕様どおり0へflushする。

invoke本体はファイルI/O、動的メモリ確保、浮動小数点演算を行わない。
prepareだけでfloat32 scaleをdoubleへ変換し、doubleの積・除算と公式
`QuantizeMultiplier`を使用する。RV32I/IMではlibgcc/libmのソフトウェア演算になる。

## 公式依存と一致条件

[manifest](../../third_party/tflite/manifest.json)に固定済みのTFLM commit
`d0318206cf438df7d60708b49559777225ebacda`を維持する。submoduleではなくvendor。
同コミットの`common.cc`、`quantization_util.cc`、参照FCと依存ヘッダを追加し、
TFLM指定のgemmlowp commit `719139ce755a0f31cbf1c37f7f98adcc7fc9f425`を固定した。
FlatBuffersは引き続き25.9.23。56個のupstreamファイルをSHA-256検証する。

ホスト・targetの両方で`TFLITE_SINGLE_ROUNDING=0`を明示する。
`MultiplyByQuantizedMultiplier`は公式の
`SaturatingRoundingDoublingHighMul`と`RoundingDivideByPOT`による二段丸め。
単純な右shift、float再量子化、任意の近似式への置換はしていない。
将来別のPC interpreterと比較するときは、そのビルドの丸め方式も合わせること。

ホストoracleは同じMODEL.TFLを公式accessorで読み、**未変更の公式INT8 FC**を実行。
さらに公式FC headerの検証用コピーにobserverを1箇所だけ追加して、accumulatorと
output zero_point加算後・clamp前のrequant値を採取する。
このコピーと未変更FCの出力一致も確認する。
PSC実装のdot+row_sum補正に対し、参照側は公式の`Σ(weight*(input+offset))`を使う。

## C APIと所有権

```c
#include "tflite/tflite_api.h"
int rc = psc_tflite_load("MODEL.TFL"); // read + prepare
size_t bytes;
int8_t *input = rc ? 0 : psc_tflite_get_input(&bytes);
// 必要な量子化済み入力を bytes バイト設定
if (input) rc = psc_tflite_invoke();
const int8_t *output = rc ? 0 : psc_tflite_get_output(&bytes);
// output は最後の成功した invoke の結果
psc_tflite_reset();
```

モデルは同時に1個。同期・非スレッドセーフAPI。
`load`/`prepare`失敗時にも旧モデルは無効化され、outputを取得できない。
`inspect_file`も共有model bufferを使用するため、resident modelを無効化する。
`prepare(data,size)`を直接使う場合、呼出し側は16-byte alignedなモデル本体を
次のreset/load/prepareまで保持し、変更しないこと。
get_input/outputのpointerをその期間を越えて保持しないこと。
invoke中の再入load/prepare/reset/invokeはBUSYとなる。
trace/layer callbackからのlongjmp・例外・API再入は禁止。target callbackはI/Oや割当をしない。

シェルには既存`tflite_info MODEL.TFL`を残し、`tflite_run MODEL.TFL`を追加。
runは固定16要素入力を設定し、全20チャネルと最終出力を埋込みdemo oracleと比較する。
一般モデル用の入力APIではなく、このデモの診断コマンドである。
異なる入力長やoracle不一致をPASSとして扱わない。

## 再現可能なモデルと試験

リポジトリrootから実行する。出力先は任意で、/tmpの既存生成物には依存しない。

```sh
python3 PSC-ONE/software/os/tests/tflite/run.py
python3 PSC-ONE/software/os/tests/tflite/generate_model.py --build build/tflite-demo
python3 PSC-ONE/software/os/tests/tflite/phase3_check.py --build build/tflite-cross
myenv/bin/python PSC-ONE/software/os/tests/tflite/rtl_run.py --build build/tflite-rtl --model build/tflite-demo/MODEL.TFL
```

モデル生成はホストC++ compilerとvendor済みschema builderを使う。
TensorFlow Python package、flatc、ネットワークは不要。
`model_fixture.h`はPhase 2のゼロweight fixture、`phase3.cc`の`demo()`が非ゼロweight/biasを
決定的に生成する。学習済みモデルではなく、演算正しさ確認用で、分類精度は主張しない。
`--update-golden`を明示しない通常テストでは、再生成した中間値がソース内
`tflite_demo.h`と違う場合にFAILする。

- MODEL.TFL: 1,568 B、constant 400 B（weight 320 B、bias 80 B）。Softmaxなし。
- SHA-256: `cced9beaa289713f1eb6fe614df9e68d7147959bc5d0ed7c143003a7be70cd1e`
- Input: `[-128,127,-3,0,1,-1,64,-64,7,-11,31,-32,90,-100,2,-2]`
- Output: `[-36,27,18,8]`
- input scale/zp = 0.125/-3、hidden = 0.25/-17、output = 0.5/7。
- FC1 weight scale=0.25、bias scale=0.03125、実効倍率=0.125。
- FC2 weight scale=0.125、bias scale=0.03125、実効倍率=0.0625。
- 全20チャネルの中間期待値: [tflite_demo.h](tflite_demo.h)。
  同じ内容を生成先`reference.csv`へ出力する。

試験はPhase 2の3,628件を維持し、同じ破損・切詰めcorpusでprepareの後始末と
受理可能モデルのinvokeも検査する。Phase 3は47モデル/ケース、712チャネルの
accumulator/requant/clamp比較、65,560件の公式multiplier比較と既知の負値丸め期待値。
非ゼロ/ゼロzero_point、入力±極値、正負weight/bias/accumulator、biasなし/0、
K=15、丸め境界のFC実行、非2冪倍率、倍率>1、飽和、ReLU、shape/type/activation/
quantization不正、INT32範囲超過、API再入を含む。
ASan/UBSanはエラーで即停止し、leak checkを有効にする。
LeakSanitizerがptrace sandboxで動作しない環境では、検査を無効化せず制限外で実行する。

## RAMとコードサイズ

RV32IMのshellについて、Phase 2と同じllvm-size基準で比較する。

| 項目 | Phase 2 | Phase 3 | 増加 |
|---|---:|---:|---:|
| コード・定数等（llvm-size text） | 308,908 | 323,084 | 14,176 B |
| `.text` | 247,232 | 260,672 | 13,440 B |
| `.rodata` | 60,796 | 61,504 | 708 B |
| その他readonly増分 | — | — | 28 B（srodata 8、eh_frame 20） |
| `.data` | 16 | 16 | 0 B |
| `.bss` | 285,920 | 290,432 | 4,512 B |
| shell image | 594,848 | 613,536 | 18,688 B |
| shell copyのページ割当 | 598,016 | 614,400 | 16,384 B |
| ページ予算残量 | 69,632 | 53,248 | -16,384 B |

Phase 2報告の「追加コード・定数49,928 B」はPhase 3で**64,104 B**、
「追加BSS 8,216 B」は**12,728 B**となる（いずれもshell側、TFLite導入前比）。
µs計測APIのkernel側コード増分は別に144 B、kernel BSS増分0。

- model buffer: 8,192 B予約、demoは1,568 B使用。weight/biasはここから直接参照。
- runtime context: 4,512 B（arena 4,096 B + descriptor等416 B）。
- demo arena: **116 B** = input 16 + hidden 16 + output 4 + row sums 80。
  input/output/intermediateはarena内であり、別に二重計上しない。
- demo用trace 20×3×4 Bはコマンドのstack上。invoke中の保存後にUARTへ表示する。
- allocatorからの追加ページ要求はない。静的BSSを含むshell copyがページ予算を消費する。
- pool 831,488 Bからshell copy、stack 131,072 B、page table 32,768 Bを差し引く。
- RV32I全体buildでも収容: shell image 618,688 B、copy pages 622,592 B、残量45,056 B。
  MicroPythonも別BUILDでRV32Iに再コンパイルし、shell/kernelのM命令不在を検査する。

## 計測とRTL

`load`はFAT32 open/read/close、`prepare`は検証と準備を含む。
trace採取後、UART出力前に別invokeを計測し、さらに別invokeでFC1/FC2を個別計測する。
計測値にUART表示時間は含めない。FC個別計測はchannel traceなし。
既存idle-timer-only stopwatchを使い、既存ms APIを維持してµs終了API
（未使用syscall番号87）を追加した。1 µs分解能、syscall/計測開始終了の費用を含む。
タイマー使用中は借用せず-1を返す。

RTLは通常のPSC-OS + MicroPython shellをCPU v1で起動し、実際のSPI SD modelとFAT32で
MODEL.TFLを読み込む。テスト用にtopのSD保存sector数を32へ、boot moduleの固定user
ROM配列を600 KBから既存user windowに一致する1 MiBへ拡張したコピーを使用する。
画像を切り詰めず、OS RAM予算も緩和しない。production RTLは変更していない。
標準のsimulation targetはこの歴史的600 KB上限が残るため、上記専用runnerを使用する。

2026-09-13、CPU v1 / RV32IM shell、100 MHz simulation clockでPASS。
実SDカード/FPGA実機の計測ではない。

| 処理 | 時間 |
|---|---:|
| model load | 30,824 µs |
| prepare（検証を含む） | 8,630 µs |
| invoke（traceなし） | 617 µs |
| FC1（別invokeで個別計測） | 494 µs |
| FC2（別invokeで個別計測） | 156 µs |

個別計測の合計とinvoke時間は一致しない。個別計測には追加のcallback/syscall境界がある。
Phase 4比較時も同じ計測方法を使うこと。

完了結果:

- 全20チャネルのaccumulator / requant / clamp出力と最終4出力が公式TFLMと完全一致。
- Phase 2 + Phase 3ホスト、ASan / UBSan / leak check: PASS。
- RV32I/IM全体build、M命令不在、standalone runtime heap/C++依存監査: PASS。
- 既存JPEG/FAT32のホスト画像比較・AddressSanitizer回帰: PASS。
- CPU v1 RTL: 1 test、PASS=1 / FAIL=0 / SKIP=0。
  通常起動、info、missing file、SD推論、中間値、時間、`hello`、`primes 30`、
  `sd_read 11`の`CRC OK (retry=0)`、推論ファイル不存在を確認。
- RTL sim time 2,688,396,920 ns、wall time約1,196秒。
- production CPU/RTL、CRC実装、MicroPython bindingは変更していない。

測定スナップショット: [phase3_results.json](../../tests/tflite/phase3_results.json)。
残る制限は上記の対応profile、単一model、8 KiB model / 4 KiB arena、専用RTL runner、
実機未検証であり、今回のCPU Phase 3完了条件に未完了項目はない。

## Phase 4への引継ぎ

CPU実装と今回の公式oracleを保持し、最初はFCのraw signed INT8 dotだけを
SynapEngineへ置き換える。入力を`qx-zp`としてINT8へ詰めると[-255,255]を表現できないため、
現在のrow_sum補正をCPU側で適用する。bias、公式二段丸め、output zp、clampもCPUに残す。
NPUのINT32 accumulator幅、weight row/column順、Kの端数padding（ゼロweight）、
転送buffer所有権と同期を確認し、同じ中間値を比較する。
DMA/MMIO転送やpadding bufferを追加すると今回のarena/ページ予算は変わるため、
再計測してから対応modelサイズを広げること。

## ファイル一覧（Phase 2完了状態から）

新規:

- `src/tflite/tflite_api.h`: C APIと所有権規約。
- `src/tflite/tflite_runtime.cc`: prepare/arena/CPU FC/invoke/trace。
- `src/tflite/tflite_quant.h`, `tflite_quant.cc`: 公式整数補助関数adapter。
- `src/tflite/tflite_demo.h`: 再生成を照合する固定入力・全中間期待値。
- `src/tflite/PHASE3.md`: 本報告。
- `tests/tflite/model_fixture.h`: Phase 2 fixtureの共通化。
- `tests/tflite/phase3.cc`, `generate_model.py`: 非ゼロモデル生成・公式oracle・境界試験。
- `tests/tflite/phase3_check.py`: RV32I/IM全体buildとメモリ・命令・依存監査。
- `tests/tflite/phase3_results.json`: 検証・メモリ・時間の測定スナップショット。
- `third_party/tflite/tensorflow/**` 14ファイルと`gemmlowp/**` 7ファイル:
  固定upstreamの演算補助・参照kernel・header/license。

変更:

- `software/os/Makefile`: runtime/helper objectとheader依存、helper単位の不要関数除去、
  RV32I kernel用の明示的な追加builtin library指定。clean targetは変更していない。
- `src/tflite/tflite_file.c`: 共有bufferによるload/prepare、シェルdemo、時間計測。
- `src/tflite/tflite_inspect.cc/.h`, `README.md`: profile表示とPhase 3への説明更新。
- `src/shell.c`: `tflite_run`とhelp。
- `src/timer_measure.c`, `timer_api.h`, `syscall.h`, `kernel_syscall.c`, `user.c`, `user.h`:
  従来ms APIを維持するµs終了API。
- `tests/tflite/host.cc`, `run.py`: Phase 2回帰にprepare/invoke/Phase 3検査を接続。
- `tests/tflite/rtl_run.py`, `rtl_test.py`: SD推論・中間値・CRC/シェル確認と検証用ROM容量。
- `third_party/tflite/manifest.json`, `README.md`: 追加vendorの取得元・固定版・SHA記録。

既存ソースの削除、CPU/production RTLの変更、Git add/commit/pushは行わない。
Phase 0–2が未stageのため、Git上はそれらのファイルも引き続きuntrackedとして表示される。
