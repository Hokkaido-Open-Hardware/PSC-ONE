# PSC-NPU v2: 2-Term Power-of-Two 評価

> 現在のRTLは **旧v2：selector 8 lane（LANES=8）** に復元しています。保存済みselectorソースを使用し、2相で2項を処理します。実行手順は末尾の「selector 8 laneへの復元」を参照してください。Horner／Shared ShiftAddの記述・測定結果は過去の実験記録です。


Tang Nano 20K上で乗算器を2項のshift/addへ置き換える独立実験。
既存 `../npu_v1`、CPU RTL、OSソフトウェアは変更していない。
Makefileからの `NPU_VERSION=v2` 選択に対応した（末尾の手順を参照）。FPGA実機試験は行っていない。

測定結果: 演算用MULT9X9を4個削減したが、LUTが増えFmaxが低下した。
8 laneで同一clock時のv1 throughputを回復できるものの、DSP不足がない用途で
v1を置き換える優位性は確認できなかった。末尾にnextpnrの全比較を記載する。

## 既存npu_v1の解析

`../npu_v1/src` は Controller、ReadController、SystolicArray4x4、
MACScheduler、Mul4、AccBank の6モジュール。4x4は論理配置であり、
16個の乗算器を持つsystolic arrayではない。

- A（activation）は左から右、B（weight）は上から下へ、各128bitの
  shift contextを移動する。start E0、alignment E1、E2でA/Bとsigned modeをsnapshot。
- Mul4は4個のsigned 9x9乗算（INT8/UINT8共用）を持つ。
  lane nはACC ID n, n+4, n+8, n+12を担当する。
- E3～E6に4組のWBを登録、E4～E7に16 ACCを更新、E8にdone。
  WBはvalid、destination、32bit data。ACCは32bit wrap、各ACCの接続laneは固定。
  busy中にもACCは逐次変化し、Controllerはdone後に読む。
- ControllerはA=Y×X、B=X×Y、C=Y×Yを4×4 tileで処理する。
  X/Yは非ゼロの4の倍数。ReadControllerは32bit read request/response、
  Controllerは32bit C write request/responseとbackpressureを扱う。
  Controllerのdoneはstate resetまで保持され、内部MACのdoneは1クロックpulse。
- 公開APIは `software/os/src/api/synap_api.h` の `sa_run` / `sa_run_checked`。
  MMIO controlは0x10005000、既定入力0x00020000、結果0x00030000。
  CSRはCTRL=0x7C0、MODE=0x7C4、STATUS=0x7C8、A/B/C=0x7D0/0x7D4/0x7D8。
  CSR/MMIOデコードはNPU Controllerの外側にある。
- 既存cocotbは `hardware/sim/cocotb_tb/npu` にあり、
  `Makefile.npu validate_streaming` と `run_streaming_validation.py` で検証する。
  既存テストはINT8のBを期待するので、v2には独立したcode対応テストを用意した。
- 既存timing flowは `hardware/sim/Makefile.nextpnr.npu`。
  `PSC_NPU_TimingTop.sv` の登録済みpseudo stimulusとkeep信号でController全体を残し、
  `synth_gowin -family gw2a` → nextpnr-himbaechelを実行する。
  本比較もこの既存wrapper/CSTをそのまま使用する。

## 変更対象・構造・リスク

```text
Controller（v1から複製、LANES parameterの伝播のみ）
  ReadController（v1と同一）
  SystolicArray4x4（既存A/B routing、ポート、clear契約を維持）
    MACScheduler（2相、LANES=4/8/16）
    PotLanes（snapshot → 固定配線選択 → 符号処理 → 登録済みWB）
    AccBank（16×32bit、entry % LANESへ固定接続）
```

公開module名とポートをv1に合わせた。v1/v2の同名moduleを同時コンパイルしないこと。
LANESは4/8/16をサポート、既定値4。ControllerとSAのdimension契約は同じ。
BのバイトはINT8値ではなく以下のcodeになるため、既存softwareはそのまま使えない。
signed_modeはAのsigned/unsignedを選ぶ。Bは常に符号付き2項codeとして解釈する。

lane nの担当ACCは n, n+LANES, ... 。同じgroupを2クロック維持し、
phase 0で項0、phase 1で項1をWBへ登録する。次のedgeでACCに加算する。
各laneで同じ選択・符号処理回路を2項に時分割し、16個のACC加算器は維持した。
WBのdata registerは16bit、ACCへ符号拡張して渡す。
UINT8 activation 255でも各項±32640で16bitに収まる。

| startをE0としたedge | v1 4 lane | v2 4 lane | v2 8 lane | v2 16 lane |
|---|---:|---:|---:|---:|
| snapshot | E2 | E2 | E2 | E2 |
| WB登録 | E3–E6 | E3–E10 | E3–E6 | E3–E4 |
| 最終ACC更新 | E7 | E11 | E7 | E5 |
| done | E8 | E12 | E8 | E6 |
| 最短の次start | E9 | E13 | E9 | E7 |
| issue区間のweight/clk | 4 | 2 | 4 | 8 |

clearはidle時のみACCへ作用し、startより優先する。busy中のstart/ACC clearは無視。
SAのA/B shift registerはv1同様busy中もshift/clearに反応するが、snapshotは保護される。
resetは進行中のWBを破棄する。ACCは飽和せず32bit wrapする。

リスクは量子化精度、2相によるlatency増加、lane増加時のMUX/ALU増加、
メモリ転送律速によるlane増加効果の縮小。
アドレス生成の乗算は比較条件を揃えるためv1から保持した。
「INT8演算用乗算器ゼロ」と「Controller全体のDSPゼロ」は異なる。

## Weight codeと全探索

```text
bit [2:0] shift0 = 0..7     bit [3] sign0（1なら負）
bit [6:4] shift1 = 0..7     bit [7] sign1（1なら負）
code != 0: w' = (-1)^sign0 * 2^shift0 + (-1)^sign1 * 2^shift1
code == 0: w' = 0 （両phaseともゼロ）
```

0x00を特別なゼロとし、既存のゼロpadding/clearを維持する。
本来0x00が表す+2は+4−2等の別codeで表せるので表現集合は減らない。
等大反対符号のcodeもゼロになるが、encoderは0x00を選ぶ。
全codeをdecoderが扱い、INT8範囲外の復号値（最大±256）も定義される。
INT8を量子化したcanonical codeと任意のbyte codeは区別する。

`reference/pot.py` は全256 codeを各INT8値について探索し、絶対誤差最小を選ぶ。
同誤差なら復号値の絶対値が小さい方、次にbyte値が小さい方を選ぶ。
独立した符号×指数の全組合せ探索でも最小性を確認する。
指数8以上の2項からINT8範囲内に新たな非ゼロ値は作れないため、指数0～7で十分。

| 対象 | MAE | RMSE | 最大誤差 |
|---|---:|---:|---:|
| 全INT8 −128～127、指数0～7 | 1.75 | 2.663409469 | 8 |
| 比較: 指数0～6に制限 | 3.0859375 | 5.038135816 | 16 |

88/256値は完全一致、168値が変化する。
全値の元weight、code、復号weight、absolute errorは
[results/int8_quantization.csv](results/int8_quantization.csv)。

RTLはxを16bitへ符号/ゼロ拡張し、`x`, `x<<1`, ... `x<<7`相当の
constant concatenationをcase選択する。可変shift演算子は使わない。
Yosysのgeneric netlistも監査する。`$shiftx`はgroupのoperand slice選択であり、
activationを可変桁シフトするbarrel shifterではない。

## TFLite CPU比較

対象は現行の非ゼロ推論fixture
`software/os/tests/tflite/build/tflite-model/phase3/MODEL.TFL`。
一つ上の `MODEL.TFL` は全重みゼロのparser/FAT32 fixtureなので使用しない。
モデルのSHA256を [results/model_evaluation.json](results/model_evaluation.json) に記録した。

既存 `tflite_demo.h` の入力と全20ch golden（FC1 16ch＋FC2 4ch）を使用。
加えて全要素−128/−1/0/1/127の5入力、固定seedのランダム256入力、合計262入力。
20chは20サンプルの意味ではなく、既存参照の出力channel数。

`model_probe.cc` は実際のTFLite bytesを既存PSC CPU runtimeに読み込ませ、
raw dot、zero-point補正、bias加算、requant、clampを全channelで取得する。
Python側はその全段階と完全一致することを確認してからweightを置換する。
TFLiteのdouble rounding、scale、bias、fused ReLUは維持する。
zero-point補正のrow sumには量子化後weightを使う。

| 比較対象 | 数 | MAE / 最大誤差 |
|---|---:|---:|
| FC1 weight | 256 | 0 / 0 |
| FC2 weight | 64 | 0 / 0 |
| FC1 ACC・output | 4192 channel | 0 / 0 |
| FC2 ACC・output | 1048 channel | 0 / 0 |
| final output | 262×4 | 0 / 0 |
| classification（最初の最大値のindex） | 262入力 | 262/262一致 |

既存入力のfinal outputは両方式とも `[-36, 27, 18, 8]`、class indexは1（0始まり）。
全320 weightは小さい整数で、今回のcodeで全て誤差ゼロになる。
これは合成検証用の未学習モデルであり、実データに対する分類精度は評価できない。
学習済みモデル／正解ラベル付きデータセットによる精度評価は今後の課題。

全weightの比較は [results/model_weights.csv](results/model_weights.csv)、
全入力・全channelの比較は [results/model_comparison.csv](results/model_comparison.csv)。

## 検証

- 各lane構成で全activation 256値×全code 256値×signed/unsigned 2 mode。
  各項のWB data/ID、2項の和、snapshot、validをPython参照と比較。
- 各edgeのACC更新とphase、300回のidle bubbleなし連続実行、busy中start/clear、
  E2でのmode capture、全途中edgeでのreset、done/busyのタイミング。
- 32bit ACC overflow、clear優先、誤ったlane/IDの拒否を2000 transactionで確認。
- Controllerは4×4、8×4、4×8、12×20、20×12とread/write遅延・backpressure。
  全C値・アドレス・転送数を独立Python行列積と比較。
- 各lane構成でTFLite全262入力×20chの積を直接datapathで検証。
- さらに実Controllerのメモリ転送とK方向ACCを用いて全262入力×20chを計算。
  RTL FC1 → Pythonで既存requant/clamp → RTL FC2の順で実行し、
  全raw dot・bias加算後ACC・requant・FC1/FC2 output・argmaxがCPUと完全一致。
- v1の既存SA契約、Controller cycle、Mul4網羅、AccBankテストを独立buildで回帰。

cocotb結果: v2は18 testcase、v1回帰は5 testcase、全23 testcase PASS、FAIL/SKIP=0。
Icarus elaboration、Yosys合成、Verilator lintもPASS。Verilatorにはv1から引き継いだ
Controllerの比較幅warningと、新parameter式の比較/ID切り詰め幅warningが残る。
後者はLANES=4/8/16でgroup 0..3、ID 0..15の範囲内であり、網羅試験でも確認した。

CPU/OS/SoCの選択を変更しないため、CPU設計変更用RISC-V/core/OS長時間回帰は対象外。

## 再現手順（repository root）

既存myenvのcocotb 2.0.1、Icarus、g++、同梱TFLite vendor、Yosys、nextpnrを使用する。
ネットワークからの依存追加は不要。runnerはcleanを呼ばず、出力先のみ作成する。

```bash
python3 PSC-ONE/hardware/rtl/soc/npu_v2/reference/pot.py \
  --output PSC-ONE/hardware/rtl/soc/npu_v2/results
python3 PSC-ONE/hardware/rtl/soc/npu_v2/reference/evaluate_model.py \
  --build /tmp/psc-npu-v2-model
myenv/bin/python PSC-ONE/hardware/rtl/soc/npu_v2/tests/run.py \
  --build /tmp/psc-npu-v2-tests \
  --vectors /tmp/psc-npu-v2-model/rtl_vectors.json \
  --case lanes core controller bank
myenv/bin/python PSC-ONE/hardware/rtl/soc/npu_v2/tests/run.py \
  --build /tmp/psc-npu-v2-full-model \
  --vectors /tmp/psc-npu-v2-model/rtl_vectors.json --case model_controller
python3 PSC-ONE/hardware/rtl/soc/npu_v2/tests/synthesis.py \
  --build /tmp/psc-npu-v2-timing
myenv/bin/python PSC-ONE/hardware/sim/cocotb_tb/npu/run_streaming_validation.py \
  --build /tmp/psc-npu-v2-v1-regression \
  --case controller_cycles,mul4,acc_bank,sa_contract
```

モデルが未生成のcheckoutでは、先に以下でfixture/reference.csvを生成すること。

```bash
python3 PSC-ONE/software/os/tests/tflite/generate_model.py \
  --build PSC-ONE/software/os/tests/tflite/build/tflite-model/phase3
```

既存モデルを評価対象として保存し、
別の学習済みモデルに対応する際はinput/channel制約も変更して明示する。


## 成果物と残課題

新規ファイルはすべて本 `npu_v2/` 配下:

- `src/`: 上記6個のRTL module（Mul4の代わりにPotLanes）。
- `reference/`: pot.py、evaluate_model.py、model_probe.cc。
- `tests/`: CoreTop.sv、bank/core/controller/model_controller/pot_lanes各test、
  run.py、synthesis.py、report.py。
- `results/`: quantization/model CSV/JSON、Controller cycle比較、cocotb結果、
  synthesis比較JSON/Markdown、12 runのcritical path。
- README.md、.gitignore。

既存ファイルの変更・削除なし。npu_v1とCPU/OS/Makefileも変更なし。
Git状態は `?? PSC-ONE/hardware/rtl/soc/npu_v2/` のみ。
add/commit/push等、Git状態を変更する操作は行っていない。

モデル生成物・full log・netlist・PNR JSONは `/tmp/psc-npu-v2-model`、
`/tmp/psc-npu-v2-tests`、`/tmp/psc-npu-v2-full-model`、
`/tmp/psc-npu-v2-v1-regression`、`/tmp/psc-npu-v2-timing` に保存。
16 laneのoperand選択式を切り分ける補助合成は `/tmp/psc-npu-v2-select-probe` に保存。
単一groupを直接配線にしてもMUX増加は解消せず、採用RTLは変更しなかった。
一時ファイルも削除していない。

結果の再収集は以下。`--model-tests`には追加のControllerモデル試験を実行したbuildを指定する。
`run.py`の既定では全testを同じbuildに置くので、再実行時は両引数にそのbuildを指定し、
集計はtest名で分類して重複を除く。

```bash
python3 PSC-ONE/hardware/rtl/soc/npu_v2/tests/report.py \
  --timing /tmp/psc-npu-v2-timing \
  --tests /tmp/psc-npu-v2-tests \
  --model-tests /tmp/psc-npu-v2-full-model \
  --baseline /tmp/psc-npu-v2-v1-regression
```

残課題: 学習済みモデルの分類精度、SoC統合後のtiming/帯域/実測電力、FPGA実機検証。
PoTが本質的に不利という一般結論ではなく、現実装・現toolchainの比較結果である。
符号処理をshift前の狭い幅へ移す等の最適化は今回の採用RTLには含めていない。

## nextpnr測定結果

全構成で同じ既存Controller wrapper/CST、GW2AR-LV18QN88C8/I7、GW2A-18C、
81 MHz制約、seed 1/2/3。`--timing-allow-fail`は違反時にも測定値を残すために指定。
合否は81 MHz制約に対して別途判定した。今回12 runは全てPASS。
SoC全体ではなく、pseudo stimulusを含むNPU Controller単体の配置配線結果。

| 構成 | LUT4 (pnr, seed 1) | FF | MULT9X9 | MUX | ALU (pnr) | Fmax中央値 MHz | 3 seed範囲 MHz |
|---|---:|---:|---:|---:|---:|---:|---|
| v1 | 2769 | 1679 | 7 | 265 | 820 | 202.72 | 192.38–214.13 |
| v2_4 | 3482 | 1677 | 3 | 841 | 886 | 129.43 | 117.76–129.85 |
| v2_8 | 3473 | 1740 | 3 | 340 | 952 | 131.49 | 126.55–133.28 |
| v2_16 | 8504 | 1867 | 3 | 4446 | 1076 | 120.54 | 117.65–120.77 |

LUT4はnextpnrのpacked utilization値。ALU/MUXは別resource種別の報告であり、
単純合計してFPGA面積とはしない。FF/MULT/MUXも同じnextpnr reportから取得。
LUT以外の表中resource数は3 seedで同一。MULT18X18/ALU54D/BSRAMは全て0。
LUT4の3 seed範囲: v1=2769–2771、v2_4=3477–3482、v2_8=3465–3473、v2_16=8499–8504。
MULT9X9はプリミティブ数であり物理DSP macroの占有ブロック数とは異なる。
v1の7個中4個がINT8演算用、残り3個はアドレス用。v2の演算部は0個。

| 構成 | Yosys LUT1–4計 | FF | MUX | ALU | 演算部のみ MULT9X9 |
|---|---:|---:|---:|---:|---:|
| v1 | 2145 | 1679 | 265 | 762 | 4 |
| v2_4 | 2905 | 1677 | 841 | 823 | 0 |
| v2_8 | 2926 | 1740 | 340 | 884 | 0 |
| v2_16 | 7935 | 1867 | 4446 | 1002 | 0 |

nextpnrはpacking時にALU等を変換するためYosysのLUT/ALU数と異なる。

| 構成 | seed 1 Fmax | seed 2 Fmax | seed 3 Fmax | 最遅seedのlogic + routing ns |
|---|---:|---:|---:|---|
| v1 | 202.72 | 214.13 | 192.38 | 1.76 + 3.44 |
| v2_4 | 129.43 | 129.85 | 117.76 | 4.00 + 4.49 |
| v2_8 | 131.49 | 133.28 | 126.55 | 3.94 + 3.96 |
| v2_16 | 117.65 | 120.77 | 120.54 | 3.99 + 4.51 |

v1のcritical pathはController制御からwriteback register enable等へ至る経路。
v2はPoT laneのoperand/phase/shift選択と符号反転を経てWBへ至る経路が律速。
厳密な始点・終点はJSON、各段の論理/配線遅延は `critical_*_seed*.txt` に保存。

| X × Y / memory delay | v1 cycles | v2 4 cycles | v2 8 cycles | v2 16 cycles |
|---|---:|---:|---:|---:|
| 4 × 4 / 1 (signed=0) | 214 | 262 | 214 | 190 |
| 4 × 4 / 1 (signed=1) | 214 | 262 | 214 | 190 |
| 8 × 4 / 1 (signed=1) | 394 | 490 | 394 | 346 |
| 4 × 8 / 5 (signed=0) | 1280 | 1470 | 1280 | 1181 |
| 12 × 20 / 5 (signed=0) | 18624 | 22189 | 18624 | 16794 |
| 20 × 12 / 5 (signed=1) | 10509 | 12669 | 10509 | 9429 |

8 laneで2clk/weightのissue throughputとController cycle数をv1まで回復。
16 laneは同一81 MHzで約8～12%のController cycle削減に留まり、転送と制御が残る。
各設計のFmaxで動かす仮定では、代表4×4 (delay=1) の実行時間は次のとおり。

| 構成 | cycles / Fmax中央値 (µs) | 81 MHzでの時間 (µs) |
|---|---:|---:|
| v1 | 1.056 | 2.642 |
| v2_4 | 2.024 | 3.235 |
| v2_8 | 1.628 | 2.642 |
| v2_16 | 1.576 | 2.346 |

結論: 本実装・本mapping条件ではDSPを4個削減できる一方、LUT/MUX増加と
Fmax低下が大きい。DSPの不足がないTang Nano 20K用途でv1を置き換える優位性は確認できない。
DSPを他用途へ確保し、81 MHz固定で使う場合は8 laneが候補だが、面積は増加する。
16 laneはMUX増加が特に大きく、今回の速度改善に対して費用が大きい。
汎用barrel shifterはないが、固定8択selectもmapping後のコストは無視できない。
最大Fmaxは単体wrapperの推定値であり、SoC統合後や実機の保証周波数ではない。

## 追記：8:1 selector除去実験（4演算ブロックで比較）

以下が現在の採用RTL。上のselector方式の測定値は履歴としてそのまま保存した。
主比較は **v1の4 MUL、旧v2の4 selector lane、新v2の4 Horner lane**。
8/16 laneの旧表と混ぜない。新規npu_v3は作成せず、変更はnpu_v2配下に限定した。

### Python評価と方式選定

weight byteは変更せず、従来の8bit canonical codeをそのまま受け付ける。
現在の符号化ではゼロ以外は2項を格納する。単一PoTも同指数2項や隣接指数差で表されるため、
格納された項数と、数学的に簡約した最小項数の両方を集計した。

| 対象 | weight数 | 格納0/1/2項 | 簡約後0/1/2項 | exponent-majorの格納項数 | 簡約後項数 |
|---|---:|---|---|---:|---:|
| all_INT8 | 256 | 1/0/255 | 1/15/240 | 510 | 495 |
| unique_canonical | 88 | 1/0/87 | 1/15/72 | 174 | 159 |
| FC1 | 256 | 17/0/239 | 17/103/136 | 478 | 375 |
| FC2 | 64 | 5/0/59 | 5/30/29 | 118 | 88 |
| model_all | 320 | 22/0/298 | 22/133/165 | 596 | 463 |

並べ替えだけでは項数は減らない。簡約は別の変換であり採用RTLではencodingを変更しない。
all_INT8は元の−128～127を各1回量子化した分布、unique_canonicalは重複codeを除いた88種類。

| exponent | 全INT8 positive | 全INT8 negative | 現モデル positive | 現モデル negative |
|---|---:|---:|---:|---:|
| 0 | 13 | 11 | 104 | 61 |
| 1 | 19 | 14 | 154 | 44 |
| 2 | 28 | 21 | 89 | 65 |
| 3 | 41 | 30 | 17 | 62 |
| 4 | 55 | 35 | 0 | 0 |
| 5 | 60 | 22 | 0 | 0 |
| 6 | 52 | 46 | 0 | 0 |
| 7 | 23 | 40 | 0 | 0 |

モデルのzero weight率は22/320=6.875%。8-phase Hornerの寄与ゼロ率は77.578125%、
全INT8では75.390625%。2項を別phaseにする16-phaseではskip率は各88.359375%/87.548828125%。
**skipは加える寄与が0という意味で、clockを省略する意味ではない。**
Hornerはその指数の寄与が0でも固定倍化を行う必要がある。
モデルは指数0～3だけを使うが、採用実装はモデル依存にせず毎回7→0を走査する。

現在のweight encodingは8bitのまま。項ごとにvalidを追加すると10bit、簡約済みternary planeは16bit、
未簡約の±2係数も含むplaneは24bit/weight。疎なFC1 bucketは少なくとも1項あたり
sign 1 + input index 4 + output index 4 = 9bitが必要で、bucket pointer/countは別途必要。
理想的な4 lane sparse発行は全INT8 131 cycles、FC1 121 cycles、FC2 32 cycles。
これはdestination競合・転送・最終reduceを無視した下限で、今回の実装cycleではない。

| 案 | 追加状態・回路 | 判断 |
|---|---|---|
| exponent別ACC | 16出力×8指数×32bit=4096bitの一時ACC、固定shift後のwide reduction | 状態量と最終加算が大きい |
| 固定shift WB | 指数ごとの固定経路を並列に置くとwide出力選択/加算が必要。1bit反復ならcycle増 | selector移設を避けるため不採用 |
| 既存ACC全体のHorner | 過去のK tileの累積値まで倍になる。全K再走査か退避ACCが必要 | Controller/read変更を避ける |
| lane内Horner16 | 17bit部分積、1項ずつ±x/skip、feedbackのhold/double選択 | 合成して比較 |
| lane内Horner8 | 17bit部分積、同指数を合算した0/±x/±2x、feedbackは常に固定倍化 | 4 laneで最小だったため採用 |

| 4 lane候補、Yosys合成 | LUT1–4計 | FF | MUX | ALU |
|---|---:|---:|---:|---:|
| horner8 | 2263 | 1683 | 119 | 865 |
| horner16 | 2821 | 1684 | 740 | 869 |

8 laneの予備検討後、ユーザー指定に従い4 laneで選定をやり直した。
上表は4 laneの候補比較であり、全候補をFPGAで実測した最適解の主張ではない。
SERIAL_TERMS=0（既定）が採用8-phase、=1が比較用16-phase。既定LANES=4。

### 採用構造とnetlist確認

Schedulerが各groupについてexponentを7→0へ進め、laneは指数一致を比較するだけ。
coef_k = Σ(sign_t | shift_t == k)、p_next = 2*p + coef_k*x。
同指数・同符号なら±2x、反対符号なら0になる。2xと2pはconstant concatenationで実装した。
17bitの部分積はsigned/unsigned activationと全256 byte codeの範囲（最大±65280）を保持できる。
最初の指数で部分積を0から開始し、exponent 0の完了後だけ既存32bit ACCへ加算する。
16 ACCは変更せず、過去の積和を倍化しない。A/B転送・snapshot契約・MMIO・8bit weight codeも維持する。

| 16 MAC batch / 4 lane | v1 | 旧v2 selector | 新v2 Horner8 | 比較Horner16 |
|---|---:|---:|---:|---:|
| issue clocks | 4 | 8 | 32 | 64 |
| start E0からdoneまで | 8 | 12 | 36 | 68 |
| 最短start間隔 | 9 | 13 | 37 | 69 |
| issue中のweight/clock | 4 | 2 | 0.5 | 0.25 |

新Horner8のWBはE10/E18/E26/E34、ACC更新はE11/E19/E27/E35、doneはE36。
zero/clear/reset/back-to-backとbusy中のsnapshot保護を検証した。

合成前generic netlistとController全体をflattenしたnetlistを両方監査した。
演算部の `$mul/$shl/$shr/$sshl/$sshr/$pmux` は全て0。
旧版の16bit×8択 `$pmux` は消え、weightがshift済みactivationを選ぶ経路はない。
残る `$shiftx` はA/B contextの4:1選択（入力幅32bit以下）に限る。
merged係数にはx/固定2xの2:1選択が残るが、指数別8候補の選択ではない。
Schedulerも監査し、ACC/ReadControllerはbaselineとbyte一致、Controller本体は
compile-time parameter伝播以外一致を確認した。既存の16 ACC read選択などは残っているため、
「NPU全体に大きなMUXが一切ない」という意味ではない。selectorの別階層への移設はない。

### 同条件nextpnr、4演算ブロック比較

既存wrapper/CST、GW2AR-LV18QN88C8/I7、GW2A-18C、81 MHz、seed 1/2/3。
tool versionとwrapper hashも旧測定と一致。v1は今回再実行、旧v2は保存済み結果を使用した。
LUTはseed 1、Fmaxは3 seed中央値。その他のresource数は3 seedで同一。

| 構成 | LUT4 | FF | MULT9X9 | MUX | ALU | Fmax中央値 MHz |
|---|---:|---:|---:|---:|---:|---:|
| v1_4mul | 2769 | 1679 | 7 | 265 | 820 | 202.72 |
| selector_v2_4 | 3482 | 1677 | 3 | 841 | 886 | 129.43 |
| horner_v2_4 | 2795 | 1683 | 3 | 119 | 936 | 124.78 |

MULT9X9はprimitive数。v1は演算4＋アドレス3、旧/新v2は演算0＋アドレス3。
ALU/MUXは別resource種別であり、LUTと単純合算して面積とはしない。

| 構成 | Fmax seed 1 / 2 / 3 MHz | LUT4の範囲 | 最遅seed logic + routing ns |
|---|---|---|---|
| v1_4mul | 202.72 / 214.13 / 192.38 | 2769–2771 | 1.76 + 3.44 |
| selector_v2_4 | 129.43 / 129.85 / 117.76 | 3477–3482 | 4.00 + 4.49 |
| horner_v2_4 | 124.78 / 127.15 / 120.42 | 2793–2795 | 4.76 + 3.54 |

新方式のcritical pathは snapshot → context/係数/符号処理 → **17bit Horner加算のcarry chain**
→ 部分積レジスタ。旧shift selectorを除去しても、この直列経路が新しい律速になった。
詳細な始点・終点・全段の遅延は比較JSONとcritical_*.txtに保存。

| X×Y / delay | v1 cycles / µs@81MHz | 旧v2 cycles / µs | 新Horner cycles / µs |
|---|---:|---:|---:|
| 4×4 / 1 (signed=0) | 214 / 2.642 | 262 / 3.235 | 550 / 6.790 |
| 4×4 / 1 (signed=1) | 214 / 2.642 | 262 / 3.235 | 550 / 6.790 |
| 8×4 / 1 (signed=1) | 394 / 4.864 | 490 / 6.049 | 1066 / 13.160 |
| 4×8 / 5 (signed=0) | 1280 / 15.802 | 1470 / 18.148 | 2621 / 32.358 |
| 12×20 / 5 (signed=0) | 18624 / 229.926 | 22189 / 273.938 | 43794 / 540.667 |
| 20×12 / 5 (signed=1) | 10509 / 129.741 | 12669 / 156.407 | 25629 / 316.407 |

新規6 run（v1/new各3 seed）は全て81 MHz制約PASS。旧v2の保存済み3 runもPASS。
FmaxはNPU単体wrapperの推定値であり、SoC統合後や実機の保証周波数ではない。

### 判断

1. 8:1 activation shift selectorの除去: **達成**。他階層へ移していない。
2. 旧v2からのLUT削減: **達成**。3482→2795（−19.7%）、MUX 841→119（−85.9%）。
3. Fmax回復: **未達**。旧v2 129.43→新124.78 MHz、v1は202.72 MHz。
4. throughputとの釣り合い: 4×4で旧v2の262→550 cycles（約2.10倍）。約20%のLUT削減に対して性能損失が大きい。
5. v1への利点: 演算MULT9X9を4個空けられる。ただしLUT4は2769→2795とほぼ同じで、
   4×4は214→550 cycles（約2.57倍）。DSPが特に不足する場合以外、置き換える明確な総合利点は確認できない。

追加の最適化は行わず、17bit Horner加算を新しいボトルネックとして記録する。
電力は測定していない。実モデルの精度・実機・SoC統合は今回の結論の対象外。

### 検証・保存先

Pythonは全activation×全256 code×signed/unsigned×Horner2方式、262144比較PASS。
採用4 laneの5 unit/Controller testcase＋TFLite全体1 testcase、v1回帰5 testcaseが全PASS。
比較用Horner16も4 laneの網羅・core・Controller計4 testcaseがPASS。
signed/unsigned、canonical全88 codeに加えて全256 code、各途中Horner値、±256復号値、
ACC wrap、zero、reset全途中edge、clear、300回back-to-back、matrix/backpressureを含む。
TFLiteは全262入力×20ch=5240 channelをController経由で実行し、
FC1のRTL結果をrequantしてFC2へ渡し、全ACC/requant/output/argmaxがCPUと一致した。
weight変換は旧方式と同じであり、現在の検証用モデルの最終出力も `[-36,27,18,8]`、class=1。
学習済みモデルの分類精度を示す結果ではない。
Verilator lintは終了コード0。既存Controllerの幅warningと定数parameter幅warningは残る。

旧ソース・README・測定結果42ファイルを `results/selector_baseline_source.tar.gz` に保存し、
`selector_baseline_manifest.json` にSHA256を記録した。既存resultsのCSV/JSON/critical pathは上書きしていない。
今回の詳細は `results/selectorless/`、full log/netlistは以下のbuild先。

```bash
python3 PSC-ONE/hardware/rtl/soc/npu_v2/reference/exponent_schedule.py \
  --model-json /tmp/psc-npu-v2-model/model.json \
  --output PSC-ONE/hardware/rtl/soc/npu_v2/results/selectorless
myenv/bin/python PSC-ONE/hardware/rtl/soc/npu_v2/tests/run.py \
  --build /tmp/psc-npu-v2-horner4-check --lanes 4 \
  --vectors /tmp/psc-npu-v2-model/rtl_vectors.json
python3 PSC-ONE/hardware/rtl/soc/npu_v2/tests/synthesis.py \
  --build /tmp/psc-npu-v2-horner4-timing --variants v1 v2_4
```

モデルJSON/CPU trace/vectorがない場合は `reference/evaluate_model.py` を
旧READMEの手順で実行する。上のcheckは全採用testを同一buildにまとめて再実行する手順。
今回の既存実行先はunit=`/tmp/psc-npu-v2-horner-tests`（主比較は末尾4のcase）、
full model=`/tmp/psc-npu-v2-horner4-full-model`、v1=`/tmp/psc-npu-v2-horner4-v1-tests`、
候補面積=`/tmp/psc-npu-v2-horner8-lane4-area`と`/tmp/psc-npu-v2-horner16-lane4-area`。
4 laneへの指定前に走った8/16 laneのunit試験もPASSしたが、主比較の測定値には使用していない。
netlist監査の初回エラーはYosysのescaped階層名の照合ミスであり、RTL不一致ではなかった。
階層名を正規化して再合成・監査しPASSした。

変更: srcのPotLanes/MACScheduler/SystolicArray4x4/Controller、testsのCoreTop/core/pot_lanes/run/synthesis、README。
新規: reference/exponent_schedule.py、tests/selectorless_report.py、baseline archive/manifest、results/selectorless。
削除なし。npu/npu_v1、CPU、OS、SoC、既存Makefileは変更なし。Git add/commit/push等も未実施。

## 追記：16 PE / Shared 2-Term ShiftAdd ×8 と固定スライス設計

現在のRTLはこの方式。旧selector/Hornerの測定値とソースarchiveは保存している。

隣接PE (0,1), (2,3), …, (14,15) が各1個の `PSC_NPU_ShiftAdd2` を共有する。
独立した組合せ演算moduleを8個だけ生成し、even/oddの2クロックで16 PEを処理する。
各weightの2項は同じクロック内で選択・符号処理・加算し、17bit productをWBへ登録する。
AccBankは従来の32bit加算・wrap・clear契約を保ち、接続だけをentry/2の固定laneにした。
LANESは現実装では8のみ。旧方式の4/16指定は保存したarchiveのコードで再現する。

### NPU全体の設計方針と監査

**巨大なpacked vectorを可変indexで読まない。** packed bus自体は接続表現として使用し、
part-selectのindexはgenvar/localparamによる合成時定数に限定する。

| 箇所 | 現在の構造 |
|---|---|
| Controller A/B投入 | 既存caseによる固定byte slice。最大7択の32bit出力を維持 |
| ReadController | read_idxのcaseで128bitの固定32bit区画へ書く |
| A/B context | 4×4の隣接接続をgenvarで固定 |
| PE共有 | 各laneの固定2 PEだけを8bit 2:1選択。全16 PEを動的検索しない |
| ShiftAdd | 16bit固定shift候補をcase選択×2。17bit積を同一cycleで完成 |
| WB/AccBank | lane、ACC ID、32bit sliceを固定。演算をACC内部に埋め込まない |
| ACC読出し | 512bit可変part-selectを廃止。32bit 4:1×4 → 32bit 4:1 |

新しい `PSC_NPU_AccReadMux` は組合せ回路でlatencyを増やさない。ID 0..15は従来通り、
未定義だった16..63は0を返す。Controllerは0..15のみ使用する。assertionのindexもgenvar化した。
Controller全体のgeneric netlistで `$shiftx=0`、可変shift=0を確認。ACC readは幅32・4択の
`$pmux`が5個。ShiftAddは1個あたり幅16・8択が2個で、barrel shifterや乗算器、内部状態はない。
固定スライス化はMUXそのものの廃止ではない。今回の直接2項方式ではweight-controlled shift選択を
明示的に使用する。合成後は複数の選択条件が結合され、大きなMUX構造も残る。

### 検証

新v2 8 testcase、v1回帰 5 testcaseは全PASS（FAIL/SKIP=0）。
独立演算器で256 activation ×256 code × signed/unsigned = 131072組を全数比較。
共有laneも同じ全数を検証し、全shift/sign/zero/±256復号weightとUINT8 255を含む。
even/odd WB ID、reset途中全edge、clear優先、300回back-to-back、ACC wrap、行列/backpressureを検証した。
全64 ACC read IDもrandom 32bit値で確認。Verilator lintは終了コード0、既存Controller幅warningが3件。
TFLiteの262入力×20ch=5240出力はFC1/FC2のraw ACC・bias補正・requant・最終outputでCPU referenceと全一致。
argmax一致262/262、demo最終出力[-36,27,18,8]、class=1。Python/実CPU比較も再実行した。
現行モデルは全320weightがPoTで誤差0のfixtureであり、一般の学習済みモデルの精度保証ではない。

### 同条件nextpnr比較

GW2AR-LV18QN88C8/I7、GW2A-18C、81 MHz、seed 1/2/3。既存NPU wrapper/CST・tool versionを一致確認。
v1/new v2と演算器単体3構成を新規実行（計15 run）。旧selector/Hornerは保存済み同条件結果。
resourceはnextpnr seed 1、Fmaxは3 seed中央値。MUXはMUX2_LUT5..8の合計。

| Architecture | LUT4 | FF | MULT9X9 | MUX | ALU | Fmax median MHz |
|---|---:|---:|---:|---:|---:|---:|
| npu_v1 4 MUL | 2769 | 1679 | 7 | 265 | 820 | 202.72 |
| old v2 selector 4 | 3482 | 1677 | 3 | 841 | 886 | 129.43 |
| old v2 selector 8 | 3473 | 1740 | 3 | 340 | 952 | 131.49 |
| v2 Horner 4 | 2795 | 1683 | 3 | 119 | 936 | 124.78 |
| new v2 Shared ShiftAdd 8 | 9045 | 1745 | 3 | 4903 | 1236 | 224.97 |

全体のMULT9X9はv1=演算4＋アドレス3、新旧v2=演算0＋アドレス3。
DSP macroの占有数ではなくprimitive数。ALU/MUX/LUTを単純合計して面積とはしない。

| Architecture | LUT4 | FF | MULT9X9 | MUX | ALU | Fmax median MHz |
|---|---:|---:|---:|---:|---:|---:|
| 4 x 9x9 MUL (*) | 270 | 261 | 4 | 0 | 0 | 871.08 |
| 4 x 2-Term ShiftAdd | 1389 | 261 | 0 | 682 | 208 | 227.12 |
| 8 x 2-Term ShiftAdd | 2662 | 393 | 0 | 1369 | 416 | 201.45 |

演算器単体は共通の登録済み入力/出力wrapperと同じCSTで測定。Controller/Scheduler/PE共有/AccBankは含まない。
共通128bit stimulusと入出力FFは含むため、裸の組合せ回路の面積ではない。
**(*) 4 MULの871 MHzは乗算器のFmaxとして使用できない。** このnextpnr版のGowin timing生成には
MULT9X9のtiming arcがなく、未定義cellはtimingから除外される。実際の報告経路はstimulus→入力FF CE。
全体のFmaxもDSP内部遅延を含まない制約がある。数値は比較条件を保持したnextpnrの報告値で、
DSPを含む回路の実機動作周波数を保証しない。根拠とソースhashはtiming_model_audit.jsonに記録。

### critical pathとseed差

| Architecture | seed | Fmax MHz | logic ns | routing ns | LUT4 |
|---|---:|---:|---:|---:|---:|
| npu_v1 4 MUL | 1 | 202.72 | 1.672 | 3.261 | 2769 |
| npu_v1 4 MUL | 2 | 214.13 | 1.669 | 3.001 | 2771 |
| npu_v1 4 MUL | 3 | 192.38 | 1.756 | 3.442 | 2769 |
| old v2 selector 4 | 1 | 129.43 | 4.070 | 3.660 | 3482 |
| old v2 selector 4 | 2 | 129.85 | 3.590 | 4.110 | 3480 |
| old v2 selector 4 | 3 | 117.76 | 4.000 | 4.490 | 3477 |
| old v2 selector 8 | 1 | 131.49 | 3.970 | 3.630 | 3473 |
| old v2 selector 8 | 2 | 133.28 | 3.910 | 3.590 | 3469 |
| old v2 selector 8 | 3 | 126.55 | 3.940 | 3.960 | 3465 |
| v2 Horner 4 | 1 | 124.78 | 4.940 | 3.070 | 2795 |
| v2 Horner 4 | 2 | 127.15 | 4.940 | 2.920 | 2793 |
| v2 Horner 4 | 3 | 120.42 | 4.760 | 3.540 | 2794 |
| new v2 Shared ShiftAdd 8 | 1 | 226.55 | 1.751 | 2.663 | 9045 |
| new v2 Shared ShiftAdd 8 | 2 | 191.46 | 1.746 | 3.477 | 9047 |
| new v2 Shared ShiftAdd 8 | 3 | 224.97 | 1.945 | 2.500 | 9047 |
| 4 x 9x9 MUL (*) | 1 | 871.08 | 0.266 | 0.882 | 270 |
| 4 x 9x9 MUL (*) | 2 | 871.08 | 0.266 | 0.882 | 270 |
| 4 x 9x9 MUL (*) | 3 | 874.13 | 0.266 | 0.878 | 270 |
| 4 x 2-Term ShiftAdd | 1 | 238.89 | 2.733 | 1.453 | 1389 |
| 4 x 2-Term ShiftAdd | 2 | 208.29 | 2.534 | 2.267 | 1389 |
| 4 x 2-Term ShiftAdd | 3 | 227.12 | 2.713 | 1.690 | 1389 |
| 8 x 2-Term ShiftAdd | 1 | 201.45 | 2.713 | 2.251 | 2662 |
| 8 x 2-Term ShiftAdd | 2 | 177.97 | 2.661 | 2.958 | 2662 |
| 8 x 2-Term ShiftAdd | 3 | 209.56 | 2.534 | 2.238 | 2662 |

logicはclk-to-Qとsetupを含み、routingと合計すると報告critical periodになる。
端点のRTL sourceと全経路はnetlist_audit.json、comparison.json、critical_*.txtを参照。

### cyclesと81 MHz性能

| 構成 | issue clocks/16 PE | start→done | 最短次start | issue weight/clk | batch weight/clk |
|---|---:|---:|---:|---:|---:|
| v1 4 MUL | 4 | 8 | 9 | 4 | 1.778 |
| old selector 4 | 8 | 12 | 13 | 2 | 1.231 |
| old selector 8 | 4 | 8 | 9 | 4 | 1.778 |
| Horner 4 | 32 | 36 | 37 | 0.5 | 0.432 |
| new Shared ShiftAdd 8 | 2 | 6 | 7 | 8 | 2.286 |

新v2はE0 start、E2 snapshot、E3 even WB、E4 even ACC/odd WB、E5 odd ACC、E6 done、E7次start。
300 batchの実測はbatch_timingに保存。batch weight/clkは16/最短start間隔で、メモリ転送を含まない。

| X×Y / signed / delay | v1 cycles / µs | selector4 cycles / µs | Horner4 cycles / µs | Shared8 cycles / µs |
|---|---:|---:|---:|---:|
| 4×4 / 0 / 1 | 214 / 2.642 | 262 / 3.235 | 550 / 6.790 | 190 / 2.346 |
| 4×4 / 1 / 1 | 214 / 2.642 | 262 / 3.235 | 550 / 6.790 | 190 / 2.346 |
| 8×4 / 1 / 1 | 394 / 4.864 | 490 / 6.049 | 1066 / 13.160 | 346 / 4.272 |
| 4×8 / 0 / 5 | 1280 / 15.802 | 1470 / 18.148 | 2621 / 32.358 | 1181 / 14.580 |
| 12×20 / 0 / 5 | 18624 / 229.926 | 22189 / 273.938 | 43794 / 540.667 | 16794 / 207.333 |
| 20×12 / 1 / 5 | 10509 / 129.741 | 12669 / 156.407 | 25629 / 316.407 | 9429 / 116.407 |

X/YはControllerのdimension。A=Y×X、B=X×Y、C=Y×Yであり、仕事量はX×Y² MAC。
delay=5では固定パターンのrequest backpressureも含む。

| 構成 | 4×4 MMAC/s @81MHz | kMAC/s/LUT4 | 連続batch MMAC/s @81MHz |
|---|---:|---:|---:|
| npu_v1 4 MUL | 24.224 | 8.748 | 144.000 |
| old v2 selector 4 | 19.786 | 5.682 | 99.692 |
| v2 Horner 4 | 9.425 | 3.372 | 35.027 |
| new v2 Shared ShiftAdd 8 | 27.284 | 3.016 | 185.143 |

81 MHzでv1の214→新190 cycles、2.642→2.346 µs（実行時間11.2%減、throughput12.6%増）。
このcycle比較は同じ固定clockの性能であり、DSP timing未評価のFmaxから実機性能を外挿していない。

### ボトルネックと判断

新v2の全3 seedで最長経路は**ACC読出し→ControllerのC write data FF**。
seed 1/3はAccBank FFが始点、seed 2はControllerの読出し選択/control FFが始点。
最遅seed 2はlogic 1.746 ns、routing 3.477 nsで、配線が約67%を占める。
ShiftAdd、PE共有、Scheduler、product WB、ACC更新加算は今回の最長経路ではなかった。
演算器単体のShiftAddではweight入力FF→選択/符号/加算carry chain→product FFが律速になる。

面積側はproduct生成の組合せconeが支配的。136 product FFのD入力から前段FFまでをたどると、
Yosys mapping後でLUT=6612、MUX=4812、ALU=384。
このconeは共有2:1選択と8個の2項演算器を含み、ACC読出しやACC更新は含まない。
全体のmapped MUX 4903のうち4812がこのconeにあり、面積増の主因はACC readではない。
単体8 blockではMUX 1369だが、共有MUXを含むflatten/ABC mappingでは選択論理が結合・展開される。
固定スライスでもMUXの生成コストは消えないことが確認できた。大きなMUXを単に別階層へ隠したという説明はしない。

| 判断項目 | 結果 |
|---|---|
| 巨大packed vectorの動的読出し | 全体で除去。generic $shiftx=0、可変shift=0 |
| 16 PE / 8 block共有 | 達成。8 instance、even/odd各1 issue、2項は同一clock |
| LUT削減 | 未達。v1 2769→9045、旧selector8 3473→9045 |
| Fmax回復 | nextpnr報告値で旧selector8 131.49→224.97 MHz。v1 202.72 MHz。ただしDSP timing制約あり |
| 81 MHz throughput | 4×4で12.6%向上、連続16 PE batchで28.6%向上 |
| throughput/LUT | 4×4で8.748→3.016 kMAC/s/LUT、約65.5%低下 |
| v1に対する利点 | 演算MULT9X9×4を空け、同一clockのcyclesを削減できる |

**4個の専用乗算器を使える条件では、v1の方がLUT効率に優れる。**
共有8 ShiftAddは速度改善に対してLUT増が大きく、一般的な置き換えの優位性は確認できない。
今回の結果は直接2項演算・共有接続・ACC読出し変更を合わせた測定であり、
固定スライス化だけのFmax改善効果を分離測定したものではない。
追加の大規模最適化は行わず、面積は共有選択＋2項演算cone、timingはACC readと配線を課題として残す。
電力、SoC統合、FPGA実機動作、一般学習済みモデルの精度は未測定。15 runは全て81 MHz制約をツール上PASS。

### 再現・変更ファイル

旧selector/Hornerの手順は各source archiveから実行する。以下は現在のshared8専用。

```bash
myenv/bin/python PSC-ONE/hardware/rtl/soc/npu_v2/reference/pot.py \
  --output PSC-ONE/hardware/rtl/soc/npu_v2/results/shared8
myenv/bin/python PSC-ONE/hardware/rtl/soc/npu_v2/reference/evaluate_model.py \
  --build /tmp/psc-npu-v2-shared8-model-reference \
  --output PSC-ONE/hardware/rtl/soc/npu_v2/results/shared8
myenv/bin/python PSC-ONE/hardware/rtl/soc/npu_v2/tests/run.py \
  --build /tmp/psc-npu-v2-shared8-check \
  --vectors /tmp/psc-npu-v2-shared8-model-reference/rtl_vectors.json
myenv/bin/python PSC-ONE/hardware/rtl/soc/npu_v2/tests/synthesis.py \
  --build /tmp/psc-npu-v2-shared8-timing \
  --variants v1 shared8 mul4 shiftadd4 shiftadd8 --seeds 1 2 3
```

今回の実行先: full PNR=`/tmp/psc-npu-v2-shared8-pnr-main`、unit PNR=`/tmp/psc-npu-v2-shared8-pnr-unit`、
検証=`/tmp/psc-npu-v2-shared8-final-tests`、batch実測=`/tmp/psc-npu-v2-shared8-batch-timing`、
v1回帰=`/tmp/psc-npu-v2-shared8-v1-tests`。全log、generic/mapped/PNR netlistはこれらのbuildに保存。
レポート再生成は `tests/shared8_report.py --main-build <full PNR> --unit-build <unit PNR> --tests <検証>
--v1-tests <v1回帰> --batch-tests <batch実測> --lint /tmp/psc-npu-v2-shared8-final-lint.log`。
単一buildで全variantを実行した場合、main-buildとunit-buildには同じpathを指定できる。

Horner時点の63ファイルを `results/horner_baseline_source.tar.gz` とmanifestに保存。
既存のselector/Horner測定結果はSHA256で不変を確認した。元のselector archiveも保持している。

- 変更: `src/PSC_NPU_AccBank.sv`、`PSC_NPU_Controller.v`、`PSC_NPU_MACScheduler.sv`、
  `PSC_NPU_PotLanes.sv`、`PSC_NPU_SystolicArray4x4.v`、
  `tests/CoreTop.sv`、`bank_test.py`、`core_test.py`、`pot_lanes_test.py`、`run.py`、`synthesis.py`、README。
- 新規: `src/PSC_NPU_ShiftAdd2.sv`、`PSC_NPU_AccReadMux.sv`、
  `tests/shiftadd_test.py`、`acc_read_test.py`、`DatapathTiming.sv`、`shared8_report.py`、
  Horner archive/manifestと`results/shared8/`の測定・検証記録。
- 削除: なし。既存npu/npu_v1、CPU、OS、SoC、既存Makefileは変更なし。
- Git: npu_v2ディレクトリは未追跡。add/commit/pushその他の状態変更は未実施。


## selector 8 laneへの復元

現行構成は **旧v2 selector / LANES=8**。`results/selector_baseline_source.tar.gz`
のSHA256をmanifestと照合し、当時の6 RTLモジュールへ復元した。
RTLの差分はLANES既定値4→8のみ（ReadControllerは完全一致）。
8個のselectorがweightの下位／上位nibbleを2相で処理し、16 ACCを更新する。
ACC読出しとA/B routingも保存版に戻っている。Shared ShiftAdd版の
`$shiftx=0`という監査結果は現行構成には適用しない。

テストもselector版のphase/WB/done契約へ戻した。`run.py`の既定は8 lane、
`synthesis.py`の既定はv2_8。両者は使用する6 RTLを明示している。
Shared ShiftAdd/Horner専用の追加モジュール・テスト・測定記録は保持し、
現行構成のビルド対象から外した。過去の再現手順は対応するsource archiveを使う。
復元直前のソース・テスト・READMEは
`results/shared8_before_selector_restore.tar.gz` に退避した。

再現手順（リポジトリrootから、既存buildを避けた出力先を指定）:

```bash
myenv/bin/python PSC-ONE/hardware/rtl/soc/npu_v2/reference/evaluate_model.py \
  --build /tmp/psc-npu-v2-selector8-restored-model \
  --output /tmp/psc-npu-v2-selector8-restored-model/results
myenv/bin/python PSC-ONE/hardware/rtl/soc/npu_v2/tests/run.py \
  --build /tmp/psc-npu-v2-selector8-restored-tests \
  --vectors /tmp/psc-npu-v2-selector8-restored-model/rtl_vectors.json
myenv/bin/python PSC-ONE/hardware/rtl/soc/npu_v2/tests/synthesis.py \
  --build /tmp/psc-npu-v2-selector8-restored-timing
```

CPU RTL・SoC選択・既存Makefileは変更していない。

復元後の検証結果:

- cocotb 6 testcase（5 suite）全PASS、FAIL/SKIP=0。
  131072組の全数演算、2相WB・reset・clear・snapshot・300回連続実行、
  ACC wrap、行列/backpressure、TFLite 262入力×20chのCPU一致を確認。
- Controllerの6条件すべてが保存済みselector 8のcycle数と一致。
  4×4・delay=1は214 cycles（81 MHzで2.642 µs）。
- Verilator lintは終了コード0。保存版由来の幅warning 5件は残る。
- Yosys演算部監査PASS: 16bit・8択selectorが8個、演算用DSP・可変shiftなし。
- nextpnrは同じdevice/wrapper/tool version・81 MHz・seed 1/2/3で全PASS。

| seed | LUT4 | FF | MULT9X9 | MUX | ALU | Fmax MHz |
|---|---:|---:|---:|---:|---:|---:|
| 1 | 3465 | 1740 | 3 | 340 | 952 | 136.22 |
| 2 | 3467 | 1740 | 3 | 340 | 952 | 134.55 |
| 3 | 3465 | 1740 | 3 | 340 | 952 | 130.86 |

今回のFmax中央値は134.55 MHz。旧保存値の131.49 MHzは過去の測定として保持する。
RTLは既定LANESを除き保存版と一致しているが、今回の配置配線結果は旧測定と完全一致ではない。
MULT9X9の3個はアドレス生成用。このnextpnr版のDSP内部timingに関する制約も従来通り。
詳細は `results/selector8_restore_verification.json` と各build内のlog/netlistを参照。

変更: AccBank、MACScheduler、PotLanes、SystolicArray4x4、CoreTop、
bank/core/pot_lanesテスト、run.py、synthesis.py、README。
新規: 復元前archive、`selector8_restore_manifest.json`、`selector8_restore_verification.json`。
削除なし。Gitは引き続きnpu_v2未追跡、add/commit/pushは未実施。

## MakefileからのNPU_VERSION=v2選択

`PSC-ONE/hardware/sim` の以下のMakefileが `NPU_VERSION=v2` に対応。
選択されるRTLはselector 8 laneの6モジュールで、ShiftAdd2／AccReadMuxは含めない。
既定NPUと既存のlegacy/v1選択、cleanレシピは維持した。

| Makefile | 対象 | 既定NPU |
|---|---|---|
| Makefile.cpu | チップシミュレーション | legacy |
| Makefile.pscos | PSC-OSシミュレーション | legacy |
| Makefile.npu | NPU単体テスト | v1 |
| Makefile.yosys | yosys_npu | legacy |
| Makefile.nextpnr.npu | NPU単体合成・配置配線 | v1 |
| Makefile.nextpnr.chip | チップ全体合成・配置配線 | v1 |

```bash
cd PSC-ONE/hardware/sim
# cocotbを導入済みのPython環境を使用する。
make -f Makefile.npu validate_streaming NPU_VERSION=v2 SIM_BUILD=/tmp/npu-v2-check
make -f Makefile.npu simulate_SA_Ctrl NPU_VERSION=v2 SIM_BUILD=/tmp/npu-v2-controller
make -f Makefile.npu simulate_SA_4x4 NPU_VERSION=v2 SIM_BUILD=/tmp/npu-v2-core
make -f Makefile.yosys yosys_npu NPU_VERSION=v2
make -f Makefile.nextpnr.npu timing NPU_VERSION=v2 BUILD_DIR=/tmp/npu-v2-timing
make -f Makefile.nextpnr.chip timing CPU_VERSION=v1 NPU_VERSION=v2 BUILD_DIR=/tmp/chip-npu-v2
```

CPU／OSでも従来のコマンドに `NPU_VERSION=v2` を追加して選択できる。
**v2のBメモリはINT8重みではなく2項PoTコードを格納する。** Makefileの選択は
ソフトウェアの重み変換を行わない。既存INT8用sa/nnプログラムやOSの推論データを
そのまま実行した結果はv1と同じにはならない。CPU／OSのテスト一覧・期待値は変更していない。

`validate_streaming` は既存v2 runnerで6 testcaseを実行し、必要なTFLiteの
CPU reference／RTL vectorを `SIM_BUILD/model_reference` に生成する（Icarus使用）。
`simulate_SA_Ctrl` はPoT行列・transactionテスト、`simulate_SA_4x4` は
CoreTopを使った16 ACCの2相WB・reset・snapshot・モデル演算テスト。
この2ターゲットは `MODE=icarus` / `MODE=verilator` を使用できる。
PE／2x2／multicycleのターゲットは従来通りlegacy互換性テストであり、
`simulate_all` の既存依存関係にも残している。

NPU単体とPSC-OSのv2既定SIM_BUILDは `sim_build/npu_v2`。
PSC-OSでは子makeへexportし、既存INT8 NPUのシミュレータと分離する。
`SIM_BUILD` のコマンドライン指定も可能。cleanの対象は今回変更していない。

Makefile対応の検証（ログ: `/tmp/psc-npu-v2-make-validation`）:

- 6 Makefile×default/legacy/v1/v2/不正値の30選択チェック: PASS。
  default/legacy/v1のソース・出力先は変更前と一致。v2は6ファイルのみ選択。
  既存ターゲット依存関係を維持し、v2のモデル生成依存だけ追加。
- v2 `validate_streaming`: 6 testcase PASS（全数演算、262入力×20chのCPU一致を含む）。
- v1 `validate_streaming`: legacy PE／2x2／1 MUL回帰を含む23 testcaseすべてPASS。
- v2 `simulate_SA_Ctrl`: Icarus／VerilatorともPASS。
- v2 `simulate_SA_4x4`: Icarusで2 testcase PASS。
- CPU／OS／チップ全体の選択ソースをCPU legacy/v1/v2各々でVerilator lint:
  9組すべて終了コード0（既存warningあり）。NPU/chipのcheck-filesも3版ともPASS。
- `yosys_npu NPU_VERSION=v2`: PASS。
- `Makefile.nextpnr.npu timing NPU_VERSION=v2`: 81 MHz制約PASS、配置配線後122.40 MHz。
  これはMakefile既定seedの単発測定であり、先の3 seed中央値とは別の記録。
  MULT9X9内部timingについての既存制約は同じ。
- チップ全体の合成・配置配線、PSC-OS実行、CPU全回帰は今回未実施。

今回の変更ファイルは上記6 MakefileとこのREADME。RTL・ソフトウェアの変更、
新規ソースファイル、ファイル削除はなし。ログ・検証用一時ファイルは上記/tmp配下等に保存。
