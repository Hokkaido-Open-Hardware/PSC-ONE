# cpu_v1 cv.dotup.h 実装・検証記録

2026-09-21。仕様: [cpu_pulp.md](cpu_pulp.md)。対象は
`hardware/rtl/soc/cpu_v1/src`。cpu_v2、分岐予測、キャッシュ、CSR、
既存Makefileには変更していない。

## 実装

- `(opcode & 32'hfe00707f) == 32'h8000007b` の完全一致だけを受理する。
  opcode=0x7b、funct3=0、funct7=0x40。他のcustom-3はIllegal Instruction。
- `PSC_Types.sv` の未使用ALU制御値 `01000` を割り当てる。
  デコード構造体の幅やCPU外部インターフェースは変更しない。
- 両ソースの使用をデコーダへ登録し、通常のRAW interlock／forwarding、
  commitでのレジスタ書き戻し、x0の破棄を利用する。
- `Execute_Mul.sv` にunsigned 16-bit laneを4本、32-bit積レジスタを2本、
  33-bit加算を追加。RUNで2積を保持し、DOT_SUMで和の下位32 bitを出力する。
  signed変換、飽和、CSR更新はない。既存MULの処理は維持する。
- `Execute.sv` の既存MUL_WAIT／RESULT_HOLDを利用する。
  命令とオペランドは既存issueステージで保持され、下流stall中も結果を保持する。
  ドット積は既存MULより1サイクル長い。乗算と加算を同一サイクルへ直結しない。

## 検証結果

| 検証 | 結果 |
| --- | --- |
| decoder + Execute単体 | PASS: 5,392入力（境界値6^4=1,296 + 乱数4,096） |
| custom-3デコード | PASS: funct7×funct3全1,024通り、有効1／illegal 1,023 |
| 結果受理stall・リセット | PASS: 結果保持、二重完了なし、7つのリセット位相 |
| C++プログラムのfull-core実行 | PASS: 遅延なし1条件＋遅延あり4条件 |
| 独立Python oracleとのretirement比較 | PASS: 各条件6,933命令、発行と完了を1対1照合 |
| 未実装encodingの実例外と復帰 | PASS: 1,023 encoding × 5条件、mcause=2、rd不変 |
| ドット積実行中のタイマー割り込み | PASS: 5条件、復帰後の値・書き戻し回数確認 |
| 既存PSC-ONE環境でcv_pulp_test1.cpp実行 | PASS: PIO完了マーカー0xEE01、結果0 |
| RISC-V回帰 cpu_v1 | PASS: 49/49 |
| CPU core回帰 cpu_v1 | PASS: 29/29 |
| PSC-ONE basic cpu_v1 | PASS: 53/53（停止要求時点の起動済み処理が完了） |
| PSC-ONE long | 未実施: ユーザーの回帰最小化指示による |

C++は通常のRV32乗算と64-bit和による参照計算を使用する。
単体／retirement照合はPythonの任意精度整数・バイト分解を使い、RTL出力から
期待値を生成しない。C++の固定期待値には仕様書の5ベクタも含む。
各laneの0、1、0x7fff、0x8000、0xfffe、0xffff、33-bit carry、rd/rs1/rs2の
重複、x0、連続ALU→DOT→DOT→ALU、load→DOT→storeを検証した。
遅延テストのseedは1、7、19、37。IRQ試験は発行済みDOTが完了するまで
既存のprecise interrupt制御が待つことを検証する。

初回RISC-V回帰は/tmpの容量制限でコンパイルが停止した。
出力先をリポジトリの無視対象buildへ変更し、全49件を再実行してPASSした。
最初の例外用テストはM-mode例外をS-mode handlerで受ける誤りがあったため、
テストを既存のM-mode例外経路に修正した。CPUの例外処理は変更していない。

再実行（リポジトリルート）:

```sh
python3 PSC-ONE/hardware/sim/tests/v1_cv_dotup/run.py --build build/cv-dotup/directed
```

既存SoC環境での実行（`PSC-ONE/hardware/sim`から、cocotb環境を有効にする）:

```sh
make -f Makefile.cpu simulate_PSC_ONE_TESTS CPU_VERSION=v1 SIM_FAST=1 \
  TEST_PROGRAM_LIST=single \
  PSCONE_SINGLE_TEST=cv_pulp_test1:RV32ISP_chip_test:./mem/cv_pulp_test1.mem:0x00000000 \
  TEST_BUILD_ROOT=../../../build/cv-dotup
```

回帰には既存の `Makefile.riscv.sim simulate_RISCV_TESTS_PARALLEL`、
`Makefile.cpu.core simulate_CPU_CORE`、`Makefile.cpu simulate_PSC_ONE_TESTS`
を使用した。いずれもCPU_VERSION=v1、SIM_FAST=1。
RISC-Vの再実行はJOBS=4。テストの削除・skip・期待値変更は行っていない。

## 合成・配置配線

既存 `Makefile.nextpnr.cpu` の `PSC_CPU_TimingTop` を使用。
これはcpu_v1を含む既存CPU評価用ラッパーであり、PSC_ONE_Chip全体の
配置配線や実機動作を保証する数値ではない。

| 条件 | 設定（前後共通） |
| --- | --- |
| FPGA | Tang Nano 20K / GW2AR-LV18QN88C8/I7 |
| family | GW2A-18C |
| clock制約 | 81 MHz（既存デフォルト、80 MHzへ緩めていない） |
| seed | 0x3141592653589793（既存デフォルト） |
| 配置配線 | nextpnr-0.11.1-18-gdec04b3b、Himbaechel、heap/default |
| 合成 | Yosys 0.68+136、git c30457480、synth_gowin -family gw2a |
| SV変換 | sv2v 0.0.13 |
| wrapper / CST | hardware/rtl/tang20k/timing/PSC_CPU_TimingTop.sv / .cst |

実装前は保存済み `hardware/sim/build_nextpnr_v1/` を使用した。
変更前ソースから再生成したsv2v出力が保存済み出力とバイト単位で一致し、
Yosysのセル数も再現した。前後のPNR JSON内settingsは全項目一致した。
実装後は `build/cv-dotup/timing-after/` に保存した。

```sh
# PSC-ONE/hardware/sim から
make -f Makefile.nextpnr.cpu timing CPU_VERSION=v1 \
  BUILD_DIR=../../../build/cv-dotup/timing-after
```

以下はnextpnrのDevice utilisation（pack後）。LUT4欄は配置に使うLUT資源数。

| 資源 | 実装前 | 実装後 | 差分 |
| --- | ---: | ---: | ---: |
| LUT4 | 9,021 | 7,685 | -1,336 |
| DFF | 3,921 | 3,986 | +65 |
| ALU | 606 | 640 | +34 |
| MUX2_LUT5 | 1,865 | 1,116 | -749 |
| MUX2_LUT6 | 576 | 203 | -373 |
| MUX2_LUT7 | 207 | 65 | -142 |
| MUX2_LUT8 | 75 | 23 | -52 |
| MULT9X9 | 0 | 0 | 0 |
| MULT18X18 | 0 | 2 | +2 |
| MULT36X36 | 1 | 1 | 0 |
| RAM16SDP4 | 16 | 16 | 0 |
| 配置配線後Fmax | 123.61 MHz | 131.51 MHz | +7.90 MHz (+6.39%) |

**合成・配置配線は正常終了。81 MHzをPASSし、80 MHz条件も満たす。**
今回の固定条件ではFmax低下なし。LUT/MUXの減少とFmax改善は変更後の
全体マッピング・配置配線を含む結果であり、命令追加一般が回路を小さく／速くする
という意味ではない。実装後の最悪経路は7.60 ns（論理3.12 ns、配線4.48 ns）。

Yosysでproc/flatten/opt後に `scc -expect 0`、
`select -assert-none t:$dlatch t:$adlatch`、`check` を追加実行した。
組合せループ0、意図しないラッチ0、multi-driver報告0。
標準合成フローの最終CHECKは0 problems。

## 残る警告・評価範囲

- 既存timing wrapperには未駆動の `timer_irq_ext` があり、前後とも同じ警告が出る。
  評価条件を変更しない指示に従い今回は修正していない。IRQの機能確認は
  実際にIRQ入力を駆動するfull-coreテストで別途PASSしている。
- 既存のレジスタ配列展開、ABCのcarry関連メッセージが残る。
  追加RTLに起因するラッチ／multi-driver／組合せループはない。
- 実機、全チップの配置配線、long回帰は今回の確認範囲外。
  保存済み全チップnextpnrログには本変更前から配置失敗があるため、
  CPUラッパーのPASSを全チップのPASSとして扱わない。

## ファイルと保存先

変更:

- `.gitignore`: 新規テストディレクトリとtraps.Sの無視除外。
- `hardware/rtl/soc/cpu_v1/src/PSC_Types.sv`: ALU制御定数。
- `hardware/rtl/soc/cpu_v1/src/Decorder.sv`: 完全デコード、ソース使用、illegal。
- `hardware/rtl/soc/cpu_v1/src/Execute.sv`: 既存乗算待機経路への接続。
- `hardware/rtl/soc/cpu_v1/src/Execute_Mul.sv`: unsigned lane積と33-bit和。

新規（PSC-ONE以下）:

- `hardware/sim/cpp/cv_pulp_test1.cpp`
- `hardware/sim/tests/v1_cv_dotup/run.py`
- `hardware/sim/tests/v1_cv_dotup/unit_tb.sv`
- `hardware/sim/tests/v1_cv_dotup/core_tb.sv`
- `hardware/sim/tests/v1_cv_dotup/traps.S`
- `docs/cpu_pulp_validation.md`（本記録）

既存ソースの削除なし。検証ログと変更前ソースは
`build/cv-dotup/evidence/`、詳細CPU試験は`build/cv-dotup/directed/`、
RISC-V回帰は`build/cv-dotup/riscv/`に保存（Git無視対象）。
今回の`/tmp/psc-cv-dotup/`は必要な証跡を保存した後に削除済み。
Git add / commit / pushは行わない。
