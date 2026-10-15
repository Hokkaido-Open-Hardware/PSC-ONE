# RV64 Bareコアと単体テスト雛形

## MEM応答制御のタイミング修正（2026-10-15）

Gowinの既存レポート（19:21:56／19:38:07）を読み取り比較しました。
EDAは再実行していません。変更前はWNS −1.424ns／72.623MHz、変更後は
WNS −4.289nsで、上位25経路すべてが`ex_mem.ctrl.funct3[2]`から開始します。

原因となる依存は次の2系統です。

- `funct3` → valid付きサイズデコード → 非整列判定 → バイト結合・レーン選択
  → 符号拡張 → WB選択 → `mem_wb.w_data`。
- `funct3` → 非整列／最終バイト判定 → `mem_done` → `memory_complete`
  → `mem_fire` → `ex_mem_ready` → Execute完了条件 → `ex_fire`
  → EX/MEM保持MUX。これにより`funct3`自身へのフィードバックも生じます。

最悪経路は8 LUT段（reportのLogic Levelは9）、cell 3.591ns、route 12.777ns、
clock-to-Q 0.232nsです。配線が76.969%を占めます。EX/MEM更新側には
fanout 176／201／102のノードと最大3.198nsの単一配線遅延があります。
合成後の`u_memory/n658_s4`はvalidとfunct3によるサイズデコードです。
レポート中の`u_mmu_d/n1497_s13`にはbyte_indexとサイズ判定が接続されており、
階層名だけを根拠にMMU walkerが原因とは判断できません。

直前の差分はPC選択・即値生成・Fetch PCの連結化・内部MMIO選択のレジスタ化です。
`Branch.sv`とパイプラインのstall/flush RTLはその差分では未変更でした。
既存の組み合わせ依存と高ファンアウトが、最適化後のマッピング／配置で悪化しています。
単独の変更がGowin悪化の全量を生んだとは断定していません。

今回の採用変更：

- `Branch.sv`に2 FFを追加。要求発行時に非整列判定と最終バイト判定を保持し、
  応答の完了判定・ロードデータ選択に使用します。要求／完了のサイクルは追加しません。
  EX/MEMの保持、flush、例外、MMU要求／応答の条件は維持します。
- `Decorder.sv`の即値選択と`PSC_PC.sv`のPC選択を直前の最適化前へ戻しました。
  MMIO選択レジスタ化とFetch PC連結化は保持しています。
- `pipeline_valid_tb.sv`は現RTLのリセット値を検査してからinvalid payloadへXを注入。
  validは0に保ちます。既存の機能検査は残しています。
- 新規`tests/mem_response_tb.sv`、`tests/run_mem_response.sh`で要求・応答制御を検査します。

同一device `GW2AR-LV18QN88C8/I7`、81MHz制約、既定seed、コア＋timing wrapper：

| Yosys / nextpnr | −1.424ns当時のRTL¹ | 今回の作業開始時 | 最終採用 | cpu_v1 |
|---|---:|---:|---:|---:|
| Fmax MHz | 111.371 | 97.238 | **111.869** | 109.733 |
| 最悪setup余裕 ns² | +3.367 | +2.062 | **+3.407** | +3.233 |
| 合成LUT1〜4合計 | 8,697 | 9,282 | 8,854 | 7,461 |
| 配置後LUT4使用数 | 10,773 | 11,372 | 10,974 | 10,080 |
| FF | 5,029 | 5,031 | 5,033 | 4,125 |
| ALU | 830 | 826 | 822 | 696 |
| BSRAM | 4 | 4 | 4 | 0 |
| DSP primitive | 1×MULT36X36 | 同左 | 同左 | 1×MULT36X36＋2×MULT18X18＋4×MULT9X9 |

¹ 当時の保存済みnextpnr結果。² `1000/81 − 1000/Fmax`による最悪setup余裕。
DSPはprimitive種別の個数であり、物理DSPブロック数の単純合計ではありません。
MEM修正単独は96.339MHz、分岐予測デコード整理案は97.771MHzでした。
後者は等価性証明に成功しましたが採用していません。最終案の残る最悪経路は
Fetchから予測器側への経路で、60 ALUセルのcarry chainを含みます。

**81MHz達成はnextpnrのコア＋wrapperに限定されます。** Gowin SoCのWNS改善・
81MHz達成は未確認です。旧RTLとの差は約0.5MHzで、seedを変えた頑健性評価はしていません。
false_path／multicycle_pathやMakefile、cpu_v1 RTLは変更していません。

検証状況：MEM修正段階ではRV64UI＋UM 67/67、core 27/27、compact 4/4、
乗算器Verilator／Icarus、4値pipeline、MMU 60,625チェック、CSR 32/64がPASS。
MEM単体は修正前後とも707アクセス／2,019ビート、同一142,860nsでPASSしました。
更新したpipelineテストは修正前RTLでもPASSし、旧テストはリセット期待値でFAILします。
cpu_v1 ISA／coreもPASSしました。

最終採用RTLはcore lintがPASS。最終ISA再実行とv1 SoC回帰はユーザーの
「テストは私がやります」という指示で停止しました。最終RTLの全件PASSとは扱いません。
SoC全体の`lint_RV64_ALL`はcache／NPU／wrapperの既存幅警告23件でFAILです。

証跡：リポジトリルートの`build/rv64-mem-timing-20261015/`。
`comparison.json`、`control-dependency.json`、`rollback-timing/`、
`final-source-sha256.json`、`STOPPED_BY_USER.txt`に結果と停止状態を保存しています。
Yosysのビット依存解析では、funct3[2]からdone／mem_fire／ex_fire／load_unalignedへの
組み合わせ到達性が修正前の有から修正後の無へ変わることを確認しました。

再現コマンド（リポジトリルート）：

```sh
source myenv/bin/activate
bash PSC-ONE/hardware/rtl/soc/cpu_rv64/tests/run_mem_response.sh build/rv64-mem-check
make -C PSC-ONE/hardware/sim -f Makefile.riscv.sim simulate_RISCV_TESTS CPU_VERSION=rv64 ISA='rv64ui rv64um'
make -f PSC-ONE/hardware/sim/Makefile.cpu_rv64.core simulate_RV64_CORE
make -C PSC-ONE/hardware/sim -f Makefile.nextpnr.cpu timing CPU_VERSION=rv64 BUILD_DIR="$PWD/build/rv64-mem-timing-recheck"
```

## 乗算累積加算の32bit逐次化（2026-10-15）

`Execute_Mul.sv` の共有65bit加算を、carry付き32bit加算器による下位・上位の
2サイクル処理へ変更しました。32×32 unsigned乗算式は1個のままです。
交差積と上位積を64bitの`product_q`に保持し、DSP出力から累積加算までを
同じサイクルに通さない構成です。最初のAL×BLは加算不要なので従来どおり
`low`と`acc`へ直接保持します。

変更前のGowin SoCレポートでは、最悪経路は`part_0_s0/Q`→乗算入力MUX→
DSP→加算入力MUX→65bit加算→`acc_43_s0/D`でした。`part`は部分積の
選択カウンタです。59.479MHz、setup WNS −4.467ns、TNS −1132.241ns、
違反1364 endpointsという既存結果は、今回の比較用に保存しています。
途中の指示によりGowin EDAの再実行は中止し、以下はYosys／nextpnrの結果です。

演算と制御の契約：

- `acc`は65bitを保持し、交差積のbit 64を上位積計算へ渡す。
- MULH/MULHSUの符号補正も同じ32bit加算器を2サイクル使い、下位の
  carry（借りなし）を上位へ渡す。128bit全積や64bit加減算器は追加しない。
- 要求受理時にオペランド・命令種を保持する。`busy`は演算中、`done`は
  FINISHの1サイクル。cancelはFINISHのdoneも即時に抑止し、次のedgeでIDLEへ戻す。
- Executeの結果保持・バックプレッシャー・flush接続は変更しない。
  このRV64コアにはROBはなく、順序実行パイプラインのretireを検証する。

| 要求受理後からdoneまで | 変更前 | 変更後 |
|---|---:|---:|
| MULW | 1 | 1 |
| MUL | 3 | 7 |
| MULHU | 4 | 10 |
| MULHSU | 4〜5 | 10〜12 |
| MULH | 4〜6 | 10〜14 |

Executeの完了は上表に結果保持の1サイクルを加えます。既存テストの
レイテンシ期待値を更新し、cancel／warm resetの検査範囲も全サイクルへ拡張しました。

同一device `GW2AR-LV18QN88C8/I7`、81MHz制約、既存timing wrapperでの比較：

| コア＋timing wrapper | 変更前 | 変更後 |
|---|---:|---:|
| Yosys LUT1〜4合計 | 9,037 | 8,697 |
| 配置配線後LUT4使用数 | 10,955 | 10,773 |
| FF | 4,929 | 5,029 |
| 配置配線後ALU | 830 | 830 |
| BSRAM | 4 | 4 |
| DSP / MULT36X36 | 1 | 1 |
| nextpnr最終Fmax | 97.447MHz | **111.371MHz** |

乗算器単体のYosys合成はLUT 543→850、FF 235→301、ALU 65→33、
MULT36X36 1→1です。部分積保持と半word選択MUXにより単体のLUT/FFは増えます。
コア全体のflatten合成・配置ではLUTは減少しています。単体と全体の結果は
階層横断の最適化が異なるため、単純に差し引いて扱わないでください。

**81MHzを確認した対象はnextpnrによるコア＋wrapperです。** キャッシュ・周辺を
含むSoC全体のGowinタイミング達成を意味しません。変更前もこのnextpnr条件では
81MHzを満たしており、Gowinの59.479MHzとは直接比較できません。

証跡はリポジトリルートの`build/rv64-mul-timing-20261015/`に保存しています。
`resource-comparison.json`、`before-timing/`、`after-timing/`、変更前後のRTLコピー、
`source-sha256.json`、テストログを含みます。

機能検証：

| テスト | 結果 |
|---|---|
| `run_mul32.py` / Verilator・Icarus | 両方PASS。各3,540演算、全phaseのcancel/reset、Execute保持、連続要求を確認 |
| 同runnerの4値MUL pipeline | PASS。branch flush、fault/stop kill、I-fault時の先行MUL、RAW、再開 |
| `run_compact_units.py` | 4/4 PASS。うちMUL連続演算1,280件と全phaseのcancelを確認 |
| RV64UI＋RV64UM | 67/67 PASS（乗算5命令を含む） |
| RV64 core basic | 27/27 PASS |
| RV64 core lint | PASS |
| 汎用`run_pipeline_valid.sh` | FAIL。変更前後ともTB:117の`expected uninitialized payload after reset`で停止。現行パイプラインがpayloadをresetすることとの既存不整合。テスト・対象RTLは未変更 |
| v1 ISA / core回帰 | PASS |
| v1 SoC basic / long回帰 | 48 PASS・7 FAIL / 17 PASS・2 FAIL。過去ログと同じNN/SA系の失敗 |

v1 SoC失敗：basicは`nn_test2`、`nn_test3`、`sa_test4`、`sa_test3`、
`sa_test2`、`sa_test1`、`sa_matrix_test1`、longは`nn_64x16x1_test1`、`nn_test4`。
最初の`nn_test2`ではCPU参照結果が期待どおり`0x170`、SA結果が`0x10`で不一致です。
v1構成は今回変更したRV64乗算器を使用せず、
`build/rv64-compact-implementation-20261015/`の既存ログと同じ失敗一覧です。
v1 RTLは変更していません。v2・legacyとの比較は途中の指示により対象外とし、
進行中のv2 SoC回帰を停止しました。回帰全体を全件PASSとは扱いません。

RV64 ISAの初回実行はccacheの書込み制限でコンパイルに失敗しました。
作業ディレクトリ内の`CCACHE_DIR`を指定した再実行で全67件がPASSしました。
compactテストの初回失敗は旧乗算レイテンシの期待値で、新スケジュールへの
更新後に全4ケースを再実行しています。演算期待値・検査件数は削減していません。

リポジトリルートからの主な再現コマンド：

```sh
myenv/bin/python PSC-ONE/hardware/rtl/soc/cpu_rv64/tests/run_mul32.py \
  --build build/rv64-mul-check
myenv/bin/python PSC-ONE/hardware/rtl/soc/cpu_rv64/tests/run_mul32.py \
  --sim icarus --build build/rv64-mul-check-icarus
make -C PSC-ONE/hardware/sim -f Makefile.nextpnr.cpu timing CPU_VERSION=rv64 \
  BUILD_DIR="$PWD/build/rv64-mul-check-timing"
```

## パイプライン保持データの削減（2026-10-15）

`PSC_InstructionUnit.sv` の5段について、validをpayloadから分離しました。
reset／stop／fault／flushでは従来と同じ段のvalidを無効化し、payloadの
非同期リセットと一括ゼロクリアを廃止しています。payloadは各段への転送時に
全フィールドを更新し、MEM待ち中はEX/MEMを保持します。

| 段 | 保持する情報／削減内容 |
|---|---|
| ID/ISSUE | デコード制御。PCは`ctrl.out_pc`に統一し、重複したPCを除去 |
| ISSUE/EX | デコード制御とrs1/rs2。PCは`ctrl.out_pc`に統一 |
| EX/MEM | 45bitの後段用制御、PC、ALU結果、分岐判定1bit、CSR rs1／store rs2の共有64bitデータ |
| MEM/WB | 後段用制御、分岐フィードバック用PC、CSR source、ALU／分岐先、分岐判定、最終書戻し値 |
| Commit | MEM/WBのretire情報。PCは`PIPELINE_TRACE`用で、通常合成では除去される |

EX以降の制御から、即値、ALU制御、ソースレジスタ番号、重複PCなどを除去しました。
分岐比較はEX完了時に行い、結果のみMEMへ送ります。分岐フィードバックとPC更新は
従来どおりMEM/WB、レジスタ／CSR更新はcommitです。CSR命令とstoreは排他的なので、
EX/MEMでは両者のソースデータを共有します。`memory_reg_data_1`はCSR命令時のみ有効です。

安全性の条件：

- 要求・転送・ハザードproducer・書戻し・分岐通知は対応するvalidで抑止する。
- IDのrs1/rs2ハザード検査もID validで抑止する。
- execute／memory／commitの制御出力は無効段でゼロにする。特にcommitの
  例外・return・fenceは、外部でcommit handshakeとは独立に参照されるため保護を残す。
- 無効段のデータ値は未定義。組合せデータ出力やCSR読出しアドレスがXでも、
  対応するvalidが立つまで結果を採用しない。段が有効になる際には必ずpayloadを上書きする。

4値テスト（sv2vとIcarus Verilogが必要、リポジトリルートから）：

```sh
bash PSC-ONE/hardware/rtl/soc/cpu_rv64/tests/run_pipeline_valid.sh
```

未初期化／Xを注入した無効段、RAW依存、待ち状態のload/store、64bit CSR source、
分岐、fence、fault／stop／再reset後の再開、空パイプラインでのtimer IRQを検査します。
出力先は`build/rv64-pipeline-valid/`（第1引数で変更可）です。

確認結果：`simulate_RISCV_TESTS ISA=rv64ui`は54/54 PASS、
`Makefile.cpu_rv64.core simulate_RV64_CORE`は27/27 PASS、4値テストとcore lintはPASS。
`lint_RV64_ALL`は周辺cache/NPU/wrapperの既存幅警告23件でFAILし、変更前も同じ警告でした。
同じ`Makefile.nextpnr.cpu synth CPU_VERSION=rv64`の条件では、コア＋timing wrapperの
LUT1〜4合計は12,213→11,263、FF合計は6,734→6,703、MULT36X36は4個のままです。
ALUセルは1,321→1,353であり、全種類のセルが一様に減少したわけではありません。
RV32全回帰と実機動作は今回の対象外です。以下の初期雛形の記述は、当時の履歴です。

対象はRV64IM + Zicsr/Zifencei、XLEN=64、アドレス／データバス=64bit、命令データバス=32bit、
Bareのみです。命令コードは32bit、レジスタ番号は5bitのままです。
既存のRV32パイプライン構成をもとに、PC・レジスタ・即値・CSR・演算／メモリ経路を
64bit化し、W系演算、LD/SD/LWU、6bitシフト量、64bit乗除算を追加しています。

**この段階ではISA準拠・命令実行の正しさを検証完了していません。**
単体テストのPASSは、入力初期化・リセット・所定サイクルの進行が成功したことだけを
意味します。レジスタ値／メモリ値による命令のPASS判定はTODOです。

## 実行

リポジトリルートから（Verilator、C++コンパイラ、cocotb 2.xが必要）：

```sh
source myenv/bin/activate
make -f PSC-ONE/hardware/sim/Makefile.cpu_rv64.core lint_RV64_ALL
make -f PSC-ONE/hardware/sim/Makefile.cpu_rv64.core simulate_RV64_CORE
```

`cpu_rv64/` 内からも `make simulate_RV64_CORE` / `make lint_RV64_ALL` で起動できます。
ソースはMakefileに明示列挙しています。`PSC_RV64_core` を直接トップにするため、
テスト用RTLラッパーは不要です。RV32側のRTL・Makefileには依存しません。

- デフォルト：10nsクロック、10サイクルリセット、解除後2,000サイクル。
- プログラム指定なし：未配置の命令メモリをNOPで埋めます。データの初期値は0です。
- 出力先：`build/rv64-core/`（`RV64_BUILD=/absolute/path` で変更可能）。
- `RUN_CYCLES`、`RESET_CYCLES`、`CLK_PERIOD_NS`、`MEM_LATENCY` を指定できます。
- `TIMEOUT_NS` はリセットを含むシミュレーション時間の上限です。
  既定値は `(RESET_CYCLES + RUN_CYCLES + 10) * CLK_PERIOD_NS * 2`。
  CPUの命令進捗監視やビルドの実時間タイムアウトとは別です。
- 他のMakefileのビルドやcleanは呼びません。削除用ターゲットはありません。

外部プログラムの読み込み例（相対パスは `hardware/sim/` 基準）：

```sh
make -f PSC-ONE/hardware/sim/Makefile.cpu_rv64.core simulate_RV64_CORE \
  PROGRAM_FILE=/absolute/path/program.mem PROGRAM_BASE=0 \
  RUN_CYCLES=5000 MEM_LATENCY=2
```

形式は32bitワードのreadmemhサブセットです。空白区切り、`_`、`//` と `#` コメント、
`@` による16進ワード位置指定に対応します。`@10` はベースから64バイトです。
`PROGRAM_BASE` は配置位置のみを変え、リセットPC（0）は変えません。
ELF／バイナリの直接ロード、リンク・クロスコンパイルはTODOです。

```text
@0
00000013 00000013 // NOP x 2
```

## メモリ接続

| 信号／動作 | 仕様 |
|---|---|
| 命令・データアドレス | 64bitバイトアドレス |
| 命令読出し応答 | little endian、4バイト境界に整列した32bit |
| データ読出し応答 | 64bit幅。64bitアクセスは8バイト、その他は4バイト境界のデータを返す。4バイト応答はアドレスbit 2で選ぶ上下32bitレーンに配置 |
| `data_rw_double` | 64bitバスアクセスは1、32bit以下は0。非整列LD/SDをバイトに分割した各要求も0。要求時に参照 |
| `*_req_ready` | 要求受付可能。RTLは確認後に1サイクルのvalidを発行 |
| `*_read_ready` / `data_mem_write_ready` | 読出し応答／書込み完了のパルス |
| 命令単発 | 32bitを1ビート。アドレスは4バイト境界 |
| 命令burst | 32バイト境界から8ビート（+0,+4,…,+28） |
| `mem_write_sel` | funct3：0=SB、1=SH、2=SW、3=SD。byte-enableではない |
| 書込みデータ | 整列アクセスは未シフトのrs2。非整列分割では対象バイトを下位8bitに配置。メモリ側がアドレスとサイズを使用 |
| 非整列アクセス | コアでバイト要求へ分割し、最終応答で命令を完了。ロードはバイトを結合して符号／ゼロ拡張 |
| MMU | `satp=0`、Bare固定。ページテーブルアクセスなし |

cocotbモデルは命令・データで共有する疎なバイトメモリです。
常時受付可能、固定応答遅延、burstは連続応答とし、MMU要求、不正なstoreサイズ、
非整列storeは明示的に失敗させます。立下りで要求を採取し、次の立上り後1psに応答を
駆動するため、RTLとの同一エッジの書込み競合を避けています。

`RV64_core_test.py` の `observe_cycle()`、`check_results()` が判定追加箇所です。
`memory.read(address, size)` でメモリ値を参照できます。
レジスタの参照経路、終了シグネチャ、命令の進捗タイムアウトはTODOです。

## ラッパーと制限

`PSC_ONE_RV64_core.v` は共通の命令・データキャッシュとNPUを接続しています。
キャッシュの256bitラインを `PSC_RV64_CacheAXI.sv` でAXIへ変換します。
外部AXI幅は32bitまたは64bitに対応し、既存SoCでは32bitを使用します。
I/D要求を個別に保持し、外部トランザクションは1件ずつ処理します。
`p_axi_*` のみ使用し、`d_axi_*` は従来どおり非稼働です。

- コア単体シミュレーションではこのラッパーを使用しません。
  SoCでの検証には `Makefile.cpu` の `CPU_VERSION=rv64` を使用します。
- キャッシュ制御CSRをデータキャッシュへ接続しています。LPUは無効です。
  保護モード、独自PULP命令は未対応です。
- 既存SoCではMMIO幅も32bitを使用します。MMIOアドレス設定は既存の名前を保持。
  サブワードwrite用ストローブのMMIOへの公開はTODOです。
- AXIエラーは内部 `bus_fault` を保持して停止します。アクセスフォルトへの変換はTODO。
- Sv39、SDカード、PSC-OS、FPGA合成・タイミングは今回の確認対象外です。
- CSRの完全な特権／未実装アドレス検査、命令アドレス非整列例外を含む
  例外仕様の適合性は別途整備・検証が必要です。ISA準拠を保証する段階ではありません。

## 今回の確認

Verilator 5.050 / cocotb 2.0.1で、コアのビルドおよびリセット10サイクル＋
2,000サイクルのsmoke実行を確認しました（命令メモリ要求65回、64bit応答260回）。
データload/storeはこのNOP smokeでは発生しません。
命令テスト、RV32全回帰、FPGA合成／Fmax、Icarus/Yosysでの検証は未実施です。

ISAの参照：
[RV64I](https://github.com/riscv/riscv-isa-manual/blob/main/src/unpriv/rv64.adoc)、
[M拡張](https://github.com/riscv/riscv-isa-manual/blob/main/src/unpriv/m-st-ext.adoc)。

## Sv39 MMU仮設計と周辺CSR出力幅（2026-10-15）

`src/MMU.sv` は `cpu_v1/src/MMU.sv` の要求／応答方式を参考にした
単体Sv39 walkerです。コアの `Csr.sv` は引き続き `satp=0` 固定のため、
上記のコア／SoC動作はBareのままです。

- 64bit VAの符号拡張検査、3段ページテーブル、64bit PTE、56bit PAを扱います。
- 4 KiB／2 MiB／1 GiBページ、superpage整列、V/R/W/X/U、予約ビットを検査します。
- A=0、またはstoreでD=0ならSvade方式のpage fault。PTE書込みは行いません。
- 既存ポートを維持する仮構成としてSUM=0／MXR=0相当です。
  `priv_mode` は実効特権として扱い、M-modeは変換を迂回します。
- PTE/TLBキャッシュはありません。ASID/Gによるキャッシュ再利用も行いません。
  `sfence_vma` は全体fenceとし、walk中なら未完了応答を受け取って破棄し、
  保存した要求のrootから再walkします。fenceに先立つPTE書込みの可視化は接続側の責務です。
- `MMU_enb` はidle時だけ受け付ける1サイクルパルスです。
  VA、root PPN、MODE、特権、アクセス種別は受付時に保存します。
  `mmu_done` は1サイクルパルスで、`page_fault=0` のときだけPAを使用できます。
  faultは次要求またはidle時の `cpu_state_done` で解除します。
- PTE要求は `mem_req_ready` 確認後に1サイクルの `mem_valid` を発行します。
  アドレスは要求前から応答まで安定し、同時に未完了となる要求は1件です。
  メモリはPTEを不可分な8バイトとして読み、`mem_ready` とともに64bit値を返す必要があります。
  `mem_ready` は要求パルスと同じサイクル以降に返し、要求前には返しません。
- 未対応の非Bare MODEを直接入力するとpage faultになります。これは仮モジュールの
  防御的処理です。正式統合ではCSR側のWARL処理で未対応MODEへの書込みを拒否してください。

今後の統合項目は、satp WARL、動的SUM/MXR、データアクセスのMPRV、PMP/PMAと
PTE読出し失敗のaccess fault、fetch/load/storeのfault時アクセス抑止、例外cause/tval、
PTE用8バイトバス要求です。特に現FetchはMMU完了後にメモリ要求へ進むため、
このままsatpを有効化するだけでは保護機構として完成しません。
FPGA配置配線／FmaxやCPU全体のSv39適合性は未検証です。

仕様参照：[RISC-V Supervisor-Level ISA v1.13, Sv39 / Virtual Address Translation Process](https://docs.riscv.org/reference/isa/v20240411/priv/supervisor.html)。

`Csr` の `PERIPHERAL_CSR_WIDTH`（既定値32）は、Cache・DMA・SynapEngine・
CPU Monitor向け `out_*` の幅を指定します。下位ビットを出力し、64を指定すると
64bitすべてを出力します。CSR内部レジスタ、CSR命令の `csr_rdata`、CPU内部向け
CSR出力（satp・例外アドレス等）、status入力は64bitを維持します。
`PSC_RV64_core` では32を明示指定し、既存64bitのSoC出力バスへゼロ拡張します。
したがって周辺回路へ渡すアドレスも現構成では下位32bitです。

単体テストの再実行（リポジトリルートから、生成物は `build/rv64-sv39/`）：

```sh
mkdir -p build/rv64-sv39
iverilog -g2012 -s mmu_sv39_tb -o build/rv64-sv39/mmu_tb \
  PSC-ONE/hardware/rtl/soc/cpu_rv64/src/MMU.sv \
  PSC-ONE/hardware/rtl/soc/cpu_rv64/tests/mmu_sv39_tb.sv
vvp build/rv64-sv39/mmu_tb
for width in 32 64; do
  iverilog -g2012 -s csr_width_tb -Pcsr_width_tb.PERIPHERAL_CSR_WIDTH=$width \
    -o build/rv64-sv39/csr${width}_tb \
    PSC-ONE/hardware/rtl/soc/cpu_rv64/src/Csr.sv \
    PSC-ONE/hardware/rtl/soc/cpu_rv64/tests/csr_width_tb.sv
  vvp build/rv64-sv39/csr${width}_tb
done
```

MMUテストは3ページサイズ、canonical VA、56bit PA、全leaf低位8bitとU/S・R/W/Xの
組合せ、不正PTE、要求backpressure、応答遅延、要求context保存、SFENCE中の再walkを
確認します。CSRテストは全11周辺出力の幅／下位ビットと、CPU内部の64bit値保持を確認します。

今回の確認結果：MMUはIcarus／Verilatorとも60,625チェックPASS、Yosysの汎用合成と
`check` は問題0件でした。CSR出力幅32／64の単体テスト、RV64コアlint、
`simulate_RV64_CORE` のbasic 27件はPASSです。`lint_RV64_ALL` はSoCラッパーの
既存幅警告23件でFAILし、変更前HEADのRTLでも同じ警告を確認しました。
RV32全回帰、FPGA合成／配置配線／Fmaxは未実施です。
