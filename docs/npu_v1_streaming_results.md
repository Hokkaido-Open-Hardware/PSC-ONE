# PSC-NPU v1: 4-lane streaming ACC bank 実装・検証結果

2026-09-17。

## 配置と互換性

新実装は`hardware/rtl/npu_v1/src`へ配置した。元の`hardware/rtl/npu/src`は実装前snapshotから復元し、全ファイルのSHA-256とファイル一覧の一致を確認した。元のnpuに新規RTLは残していない。

CPU RTL、CSR、software API、既存cocotb testの内容は変更していない。既存のPE単体・2x2・MUL_NUM=1 Controllerテストは元のnpuで実行し、atomic-commit契約を保った。新しい4x4本体はstreaming方式であり、busy中のACC値が順次変化する。

`npu_sources.mk`により`NPU_VERSION=v1`で新設計、`NPU_VERSION=legacy`で元のnpuを選択する。既定値はv1。両者は同名の公開moduleを持つため、ソースリストで一方だけを選ぶ。CPU RTLを変更せずに接続できる。

## 実装構造

```text
PSC_NPU_Controller（tile制御、read/write handshake）
        ↓
PSC_NPU_SystolicArray4x4
  A/B shift datapath
        ↓
  PSC_NPU_MACScheduler
    start / capture / signed mode / group index / drain / done / acc_clear
        ↓
  PSC_NPU_Mul4
    A/B snapshot → 4:1 operand mux × 4 → MUL × 4
        ↓
    registered {valid, id[3:0], data[31:0]} × 4
        ↓
  PSC_NPU_AccBank
    16 × {constant ID, fixed lane, 32bit adder, 32bit ACC}
        ↓
  ps_select → ps_acc_out → Controller → C-memory
```

- lane0 → 0,4,8,12、lane1 → 1,5,9,13、lane2 → 2,6,10,14、lane3 → 3,7,11,15。
- entryごとに`LANE=entry%4`をconstantとし、そのlaneのdataだけを接続した。全lane受信mux/crossbarはない。
- 新本体に`MUL_NUM`、legacy PE、entry FSM、16-entry product holding bank、atomic commitはない。
- signed/unsignedの切替は9bitへ符号/0拡張したoperandの乗算で行う。各laneに乗算演算子は1個。INT8積の下位16bitを取り、signed時だけbit15を32bitまで拡張する。
- WB data/宛先group/validは同じissue edgeでregisterに入る。ID下位2bitはlane定数。次のedgeでACCが加算する。
- ACCは32bit modulo加算。飽和や丸めを追加していない。
- A/Bのshiftと256bitのoperand snapshotを維持した。busy中のshift、clear、signed_mode変更が取り込み済みoperandを破壊しない。

## Schedulerとcycle性能

開始を受理したedgeをE0とする。

| edge | scheduler / multiplier | ACC |
|---|---|---|
| E0 | start受付、busy=1 | 保持 |
| E1 | ALIGN | 保持 |
| E2 | A/Bとsigned modeのsnapshot | 保持 |
| E3 | group0をWB registerへ | 保持 |
| E4 | group1をWB registerへ | ID 0～3を更新 |
| E5 | group2をWB registerへ | ID 4～7を更新 |
| E6 | group3をWB registerへ | ID 8～11を更新 |
| E7 | WB drain、valid解除 | ID 12～15を更新 |
| E8 | done pulse、busy=0 | 保持 |

MAC start→doneは変更前と同じ8 cycle。最終WBを発行しただけではdoneを出さない。公開busy/done時刻を維持するため、drainの後にFINISHを置いた。

ACC clear/startの受理はidle限定でclear優先。A/B clearは従来どおりbusy中も作用する。Controllerの`sa_state_reset`は従来どおりS_DONEから戻す操作で、実行中abortには変更していない。

独立memory scoreboardで同じ入力・transaction delayを与え、Controller start受付→doneまでを比較した。`x`はK方向長、`y`はCの行/列数。Aはy×x、Bはx×y。

| x | y | signed | read/write応答delay | 変更前cycle | npu_v1 cycle |
|---:|---:|---:|---:|---:|---:|
| 4 | 4 | 0 | 1 | 214 | 214 |
| 4 | 4 | 1 | 1 | 214 | 214 |
| 8 | 4 | 1 | 1 | 394 | 394 |
| 4 | 8 | 0 | 5 + request stall | 1,280 | 1,280 |
| 12 | 20 | 0 | 5 + request stall | 18,624 | 18,624 |
| 20 | 12 | 1 | 5 + request stall | 10,509 | 10,509 |

全出力word、address、読出し回数、重複/欠落write、最終ack後のdone、restartも検証した。MAC単体ではsigned/unsignedの2x2行列を4x4へzero paddingし、複数batchをclearなしで累積する72回のMACも前後とも8 cycleだった。

## Product holding bankの削減量

technology-map前netlistでregister driverを確認した。

| 対象 | 変更前 | npu_v1 |
|---|---:|---:|
| 積の論理data保持幅 | 16×32=512bit | 4×32=128bitのWBのみ |
| 積dataの実FF | 272 | 68 |
| 新WBのID実FF | — | 2 |
| 新WBのvalid実FF | — | 1 |
| ACC実FF | 512 | 512 |

16-entry holding bankそのものは撤去。INT8積は各wordの上位bitが共有されるため、**積dataの保持量は272→68 FF、204 FF減**である。ID上位2bitとvalidは4laneで同じcycleに動くため合成で共有され、ID下位2bitは定数になった。

旧request/ready/mul_done等の制御整理も含めた、timing top全体のFF差は**266 FF減**。16個の32bit ACC加算器は残しており、ALU数を減らす変更ではない。

## Yosys / nextpnr比較

条件は前後共通: `PSC_NPU_Timing`、GW2AR-LV18QN88C8/I7、family GW2A-18C、81 MHz、seed=1,2,3。Yosys 0.68+136 (c30457480)、nextpnr 0.11.1-18-gdec04b3b。

変更前は保存済みRTLを使用。入力刺激wrapperは同じlogicであり、新版では削除したMUL_NUM parameter指定だけを外している。sourceの読込順を固定したrunnerで比較し、途中の暫定合成値は以下に混ぜていない。

| Yosys cell | 変更前 | npu_v1 | 差 |
|---|---:|---:|---:|
| LUT1～LUT4合計 | 2,217 | 2,145 | −72（−3.25%） |
| FF合計 | 1,945 | 1,679 | −266（−13.68%） |
| ALU | 762 | 762 | 0 |
| MUX2_LUT5～8合計 | 197 | 265 | **+68** |
| MULT9X9 | 7 | 7 | 0 |

MULT9X9はどちらも演算用4個とaddress計算用3個。NPU演算器を4個に維持したことをnetlistでも確認した。MUX primitive数は増加しており、すべてのresourceが削減されたわけではない。

| seed | 使用wire:前→後 | 使用pip:前→後 | Fmax MHz:前→後 |
|---:|---:|---:|---:|
| 1 | 44,428 → 41,858 | 37,165 → 35,054 | 190.37 → 202.72 |
| 2 | 44,478 → 41,578 | 37,186 → 34,797 | 201.25 → 214.13 |
| 3 | 45,255 → 41,224 | 37,958 → 34,446 | 205.30 → 192.38 |

3 seed平均で使用wire数は**7.08%減**、pip数は**7.13%減**。これはnextpnrのROUTING属性から重複を除いた使用資源数であり、配線bit幅、物理総延長、局所混雑率ではない。clock/resetやwrapper配線も含む。

seed1のcritical pathは、変更前がACC読出し選択経路→`c_write_wdata.D`でlogic 1.68 ns + routing 3.57 ns。新版はController制御経路→`c_write_addr.CE`でlogic 1.67 ns + routing 3.26 nsとなった。WBのregister境界を保持し、組合せのmultiply→ACC加算の直結はしていない。

Fmax平均は198.97→203.08 MHzだが、seed3では低下した。**一貫したFmax改善は保証できない。** 前後全seedで81 MHz制約はPASSし、同じ81 MHzでcycle性能を維持した。数値はNPU単体timing wrapperのSTA結果であり、実機・SoC全体の動作周波数保証ではない。

## 検証結果

| 検証 | 対象 | 結果 |
|---|---|---|
| 既存PE signed/unsigned・atomic cycle契約 | 元のnpu | 2/2 PASS |
| 既存2x2 array | 元のnpu | 1/1 PASS |
| 既存4x4 array signed/unsigned | npu_v1 | 1/1 PASS |
| 既存Controllerの行列・stall・restart | npu_v1 | 7/7 PASS |
| 既存MUL_NUM=1 Controller | 元のnpu | 7/7 PASS |
| snapshot/streaming/drainの独立cycle model | npu_v1 | PASS、1,400 cycle |
| zero-pad 2x2、signed extremes、K累積 | npu_v1 | PASS、72 MAC |
| Controller cycle/transaction scoreboard | npu_v1 | PASS、6条件 |
| ACC bank独立32bit scoreboard | npu_v1 | PASS、1,800 cycle、wraparound/疎valid/clear/reset |
| 乗算器全INT8入力組合せ | npu_v1 | PASS、signed/unsigned各65,536組、計131,072積 |
| lane/ID、ID重複、clear/done時のWB drain assertion | npu_v1 | PASS |
| Yosys / nextpnr | 前後各3 seed | 全PASS at 81 MHz |
| Makefile.nextpnr.npuのsynth target | npu_v1 | PASS |
| Makefile.cpu / Makefile.pscosのsource選択 | legacy/v1 | PASS |
| SoC topのVerilator lint/elaboration | npu_v1、上記2 Makefileのsource list | PASS、既存width等のwarningあり |
| git diff --check | 作業差分 | PASS |

最終回帰は23 testcase、FAIL/SKIPとも0。WB ID下位bitをconstant配線に整理した後、影響する4x4/Controller/cycle/MULの12 testcaseを再実行してPASS。変更前baselineでは既存18 testcaseと共通追加3 testcase、計21 testcaseがPASSした。

全INT8組合せテストはsoftwareの整数積で比較し、ACC testは独立Pythonモデルで各cycleを比較した。旧PEテストは削除・skip・期待値変更をしていない。新streaming testは積が到着したentryだけが更新されることを確認し、atomic方式へ戻した実装では通らない。

CPU RTLは変更していないためCPU core/RISC-V/OSの長時間回帰は実行していない。実機確認も未実施。SoCのlint/elaborationは接続確認であって、OS実行試験ではない。

## ファイルと再現方法

新規RTLはすべて`hardware/rtl/npu_v1/src`:

- `PSC_NPU_Controller.v`: 公開portとtile制御を維持、新固定arrayへ接続。
- `PSC_NPU_ReadController.v`: 元の設計と同一内容。
- `PSC_NPU_SystolicArray4x4.v`: shift配線と新3 moduleの接続。
- `PSC_NPU_MACScheduler.sv`: global MAC制御。
- `PSC_NPU_Mul4.sv`: snapshot、4 MUL、registered WB。
- `PSC_NPU_AccBank.sv`: 16個のFSM-less ACC。

その他の新規ファイル:

- `hardware/rtl/npu_v1/README.md`、この報告書。
- `hardware/sim/npu_sources.mk`: legacy/v1 source選択。
- `hardware/sim/cocotb_tb/npu/run_streaming_validation.py`。
- 同directoryの`streaming_acc_test.py`、`streaming_controller_test.py`、`streaming_bank_test.py`、`streaming_mul_test.py`。

変更した既存ファイル:

- `hardware/rtl/timing/PSC_NPU_TimingTop.sv`: MUL_NUM指定を外して両version対応。
- `hardware/sim/Makefile.npu`: source選択、legacy回帰維持、assertion、追加検証target。
- `hardware/sim/Makefile.nextpnr.npu`、`Makefile.cpu`、`Makefile.pscos`: 共通source選択を利用。

Makefile変更はsource依存関係と検証targetに限定し、clean targetの動作は変更していない。元のnpu、CPU RTL、software、既存テストの変更なし。既存ファイルの削除なし。途中で作った重複legacy fixtureは`/tmp`へ退避し、元のnpuをそのまま回帰に使用する構成へ整理した。

baselineと全生成物は`/tmp/psc-npu-streaming-20260917-mxw9w14o/`に保存:

- `baseline/manifest.json`と`baseline/PSC-ONE/...`: 変更前source/test/Makefileとhash。
- `before_tests/`: baseline21 testcase。
- `final_tests/validate_streaming/`: 23 testcase。
- `final_tag_tests/`: 最終ID整理後の12 testcase。
- `final_before_timing/`、`final_tag_timing/`: 最終比較用Yosys/nextpnr/netlist/JSON。
- `integration/`: CPU/OS Makefile sourceを使ったSoC lintログ。
- `make_synth/`: 標準Makefileからの合成確認。

検証（hardware/sim、cocotb/numpyを含む既存myenvをPATHへ設定）:

```bash
make -f Makefile.npu validate_streaming NPU_VERSION=v1 SIM_BUILD=/tmp/npu-v1-check
make -f Makefile.npu simulate_all NPU_VERSION=v1
make -f Makefile.nextpnr.npu timing NPU_VERSION=v1 BUILD_DIR=/tmp/npu-v1-timing
```

3 seed比較runner（repository root）:

```bash
myenv/bin/python PSC-ONE/hardware/sim/cocotb_tb/npu/run_streaming_validation.py \
  --build /tmp/npu-v1-timing-3seeds --timing
```

Gitのadd/commit/push/reset/restore等は実行していない。作業前から存在したCPU monitor、AXI、画像、CoreMark等の差分はそのまま保持した。
