# RV64 Bareコアと単体テスト雛形

対象はRV64IM + Zicsr/Zifencei、XLEN=64、アドレス／メモリデータバス=64bit、
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
| 命令・データ読出し応答 | little endian、8バイト境界に整列した64bit |
| `*_req_ready` | 要求受付可能。RTLは確認後に1サイクルのvalidを発行 |
| `*_read_ready` / `data_mem_write_ready` | 読出し応答／書込み完了のパルス |
| 命令単発 | 64bitを1ビート。アドレスは8バイト境界 |
| 命令burst | 32バイト境界から4ビート（+0,+8,+16,+24）。Fetch内で32bit命令へ展開 |
| `mem_write_sel` | funct3：0=SB、1=SH、2=SW、3=SD。byte-enableではない |
| 書込みデータ | 未シフトのrs2。メモリ側がアドレスの下位bitとサイズを使用 |
| MMU | `satp=0`、Bare固定。ページテーブルアクセスなし |

cocotbモデルは命令・データで共有する疎なバイトメモリです。
常時受付可能、固定応答遅延、burstは連続応答とし、MMU要求、不正なstoreサイズ、
非整列storeは明示的に失敗させます。立下りで要求を採取し、次の立上り後1psに応答を
駆動するため、RTLとの同一エッジの書込み競合を避けています。

`RV64_core_test.py` の `observe_cycle()`、`check_results()` が判定追加箇所です。
`memory.read(address, size)` でメモリ値を参照できます。
レジスタの参照経路、終了シグネチャ、命令の進捗タイムアウトはTODOです。

## ラッパーと制限

`PSC_ONE_RV64_core.v` は旧32bitキャッシュ／NPU接続を使わず、
`PSC_RV64_AXI.sv` によるキャッシュなし64bit AXI接続へ変更しています。
従来の外部信号名を維持していますが、32bitの既存SoCへの直接接続はできません。
I/D要求を個別に保持し、外部トランザクションは1件ずつ処理します。
`p_axi_*` のみ使用し、`d_axi_*` は従来どおり非稼働です。

- このラッパーは単体シミュレーション対象外です。構文・接続幅のみ確認します。
- キャッシュ、NPU、保護モード、独自PULP命令は未対応。
  キャッシュ制御CSRはこのラッパーでは効果を持ちません。
- MMIO応答も64bitの整列済みデータが必要です。MMIOアドレス設定は既存の名前を保持。
  サブワードwrite用ストローブのMMIOへの公開はTODOです。
- AXIエラーは内部 `bus_fault` を保持して停止します。アクセスフォルトへの変換はTODO。
- Sv39、SoC全体、SDカード、PSC-OS、FPGA合成・タイミングは今回の確認対象外です。
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
