# RV64 Bareコアと単体テスト雛形

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
