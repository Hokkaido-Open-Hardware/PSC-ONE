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

