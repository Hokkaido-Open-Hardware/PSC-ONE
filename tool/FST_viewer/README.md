# PSC_RV32 Trace Studio

実際のFST/VCDを命令・CPU構造単位で表示するPython＋ブラウザGUIです。RTLは変更しません。

## CPU対応

| CPU_VERSION | 対応状況 | 表示モデル |
|---|---|---|
| legacy | supported | FSM（pipeline_mode=0） |
| v1 | supported | valid/ready pipeline |
| v2 | supported | experimental OoO / scheduler（ROB=2、IQ=2、PRF=34） |

`cpu_profiles/base.py` が共通契約を定義し、各profileがCPU判別用の構造、階層探索、必須／任意信号、幅検証、packed配置、状態名、命令追跡、Inspectorを提供します。本体は共通のストリーム解析・検索・HTTP APIです。命令種別の色と逆アセンブラは全CPU共通です。

## 必要環境・起動

- Python 3.10以降。実行時の追加Pythonパッケージ不要
- `fst2vcd`（GTKWave付属、確認環境では `/usr/bin/fst2vcd`）
- JavaScript / Canvas対応ブラウザ。VCD直接入力ならfst2vcd不要

```bash
cd /home/haruhiko/Program/PSC_RV32I/PSC-ONE/tool/FST_viewer
python3 fst_viewer.py
python3 fst_viewer.py validation/legacy.fst
python3 fst_viewer.py validation/v1.fst
python3 fst_viewer.py validation/v2.fst
```

引数省略時はプログラムの配置場所を基準に `../../hardware/sim/wave/` の最新FST/VCDを選びます（起動時の作業ディレクトリには依存しません）。CPUは構造から自動判別し、画面上部にも表示します。明示指定でも必須信号・幅の検証は省略しません。

```bash
python3 fst_viewer.py trace.fst --cpu legacy
python3 fst_viewer.py trace.fst --cpu v1
python3 fst_viewer.py trace.fst --cpu v2
python3 fst_viewer.py trace.fst --no-browser --port 8000
python3 fst_viewer.py trace.fst --summary
```

既定ポートは **8000**。使用中なら **8001 → 8002 → … → 65535** と直接bindを試みます。`--port 9000`なら9000から探索、`--port 0`ならOSが空きポートを割り当てます。端末とブラウザは実際に取得したポートのURLを使用します。使用中以外のエラー（権限・無効アドレス等）は隠さず終了します。既定bind先は127.0.0.1です。終了は端末でCtrl-C。

## FST生成

```bash
cd /home/haruhiko/Program/PSC_RV32I/PSC-ONE/hardware/sim
make -f Makefile.cpu simulate_PSC_ONE_TESTS TEST_PROGRAM_LIST=single CPU_VERSION=legacy
make -f Makefile.cpu simulate_PSC_ONE_TESTS TEST_PROGRAM_LIST=single CPU_VERSION=v1
make -f Makefile.cpu simulate_PSC_ONE_TESTS TEST_PROGRAM_LIST=single CPU_VERSION=v2
```

各実行が `wave/PSC_ONE_Chip_test.fst` を生成します。既存ターゲットは前のwaveをcleanするため、比較用FSTは次の実行前に別名で保存してください。本検証では実生成物を `validation/{legacy,v1,v2}.fst` に保存しました。

## GUI操作

- 横軸はCPU clock立ち上がりcycle。ホイール／下部スクラバーで移動
- Ctrl/Command＋ホイール、＋／−ボタンでzoom
- cycle列／ステージをクリックしてCycle Inspector表示
- Cycle入力でジャンプ、左右キー／ボタンで前後cycle
- Shift＋左右キー／命令移動ボタンで前後命令
- PC検索、ニーモニック／オペランド検索、命令種別Filter
- Instruction LedgerでPC、word、逆アセンブル、開始／終了／所要cycle、retire状態を表示
- ステージバーで同一命令の占有期間とMUL/DIV待機を表示
- Inspectorで選択ステージのrs1/rs2/rd、ABI名、取得済み値、結果、memory、PC遷移、FSM、hazardを表示
- GUI下部のRegistersで選択cycleのx0〜x31をABI名・32bit hexadecimal値付きで表示。直前cycleから値が変わったレジスタを強調し、cycle移動や検索に連動します。

表示範囲だけをCanvasで描画し、cycle APIは最大500cycleに制限します。存在しない値・未確定結果は `—` です。命令台帳の最終結果を過去cycleのInspectorへ流用しません。

## CPUごとの構造・信号

実生成FSTの基準階層:
`PSC_ONE_Chip_sim.u_chip.u_core_axi.u_core`

上位testbench名が変わっても固有suffixから基準階層を探索します。複数CPU候補・必須信号欠落・幅不一致は明示エラーです。`--summary` のJSONで解決した全信号パスと幅を確認できます。正確なalias一覧は各profileの `specs` を参照してください。

### legacy

参照RTL: `PSC-ONE/hardware/rtl/cpu/src/` の `PSC_RV32_Execute.v`、`Execute.v`、`Decorder.v`、`Branch.v`、`MemoryStore.v` 等。

検出anchor: `u_execute_state.execute_state`（4bit）。packed pipelineはありません。

使用信号:

- controller: `execute_state/next_state`、`pc/opcode`、`pipeline_mode`、`decode_done`、`u_decorder.decode_enb`
- register/control: `r_addr1/r_addr2/w_addr`、`rf_wen/w_data`、`alucon/funct3`
- Execute: `state/alu_data/alu_done`、`u_execute.r_data1_w/r_data2_w`、`s_data1_w/s_data2_w`
- MUL/DIV: `u_execute.mul_*/div_*`、`u_multiplexer.state`、`u_divider.state/count`
- memory/branch: `data_mem_*`、`u_branch.state/branch_enb`、`u_memory_store.state/store_enb`、`pc_sel2`、`mem_write_sel`

FSMはIDLE / FIFO_READ / DECODE / EXECUTE / BRANCH_MMU / BRANCH_MMU_W / BRANCH / STORE_MMU / STORE_MMU_W / STORE。CURRENT行と実際の占有状態を表示します。COMMIT行はSTORE→IDLEを観測した「命令完了」の派生マーカーであり、独立したRTL pipeline段ではありません。FIFO取得前の待ちは命令へ無理に紐付けません。

MUL/DIV経路は通常ALU用の保持値 `r_data1/r_data2` を更新しないため、命令台帳のオペランドはEXECUTE入場時の実レジスタ読出しポートから取得します。InspectorはEXECUTE時の読出し値を表示し、取得前／以後は未保持値として—にします。branch/store engine enableは全命令の制御フローでも立つので、実メモリアクセスはdata_memのvalid/ready/addressで判断してください。

### v1

参照RTL: `cpu_v1/src/PSC_Types.sv`、`PSC_InstructionUnit.sv`、`Execute.sv` 等。

検出anchor: `u_inst_engine.u_inst_unit.id_issue`（163bit）。

| 表示 | payload | 検証幅 |
|---|---|---|
| ID / ISSUE | id_issue | 163 |
| EXECUTE | issue_ex | 227 |
| MEMORY | ex_mem | 259 |
| WRITEBACK | mem_wb | 260 |
| COMMIT | commit | 260 |

130bitのdec_ctrlをRTL宣言順に展開します。`decode_fire/issue_fire/ex_fire/mem_fire` 等で命令instanceを移送し、同じPCのループも区別します。使用信号はpayload、`pc_now/opcode`、RAW hazard、forward選択、backend_serial、flush、`u_execute` の結果・状態、`u_load/u_store`、`data_mem_*`、PC制御・fault類です。

Execute状態: IDLE / DIV_WAIT / MUL_WAIT / RESULT_HOLD。DIV: IDLE / INIT / RUN / FIX / DONE。MUL: IDLE / RUN。

### v2

参照RTL: `cpu_v2_experimental/src/PSC_InstructionUnit.sv` と関連ROB/IQ/rename/execute RTL。

検出anchor: `u_inst_engine.u_inst_unit.rob_count`。さらにROB/IQ構造・幅・深さを検証します。

- `rob.rob[0/1]`: 各307bitのrob_entry_t。valid、completed、address_ready、instruction、130bit ctrl、side effect、dest physical、result、branch、exception
- `iq.iq[0/1]`: 各80bitのiq_entry_t。valid、ROB tag、各sourceのready/value/physical tag
- `decode_stage_valid/opcode/ctrl`、`decode_capture_fire/dispatch_fire`
- `rob_head/tail/count`、`ROB_DEPTH/IQ_DEPTH/PRF_DEPTH`
- `alu_active_*/md_active_*`、各laneのexecute_data/wb_valid
- `commit_fire/commit_result`、`dispatch_blocked`、`rat_spec_valid/alloc_phys/free_list`
- `u_execute_alu/u_execute_mul_div` の実行系、load/storeおよびdata_mem信号

表示行はDECODE / RENAME、IQ 0/1、ALU EXECUTE、MUL / DIV、ROB 0/1、MEMORY HEAD、COMMIT。ROBスロット再利用をdispatchごとの命令instanceで区別し、ROBの実word/PCと一致することも検証します。IQ占有、2つの独立実行lane、完了済ROBのcommit待ちを別表示します。InspectorにはROB completed、物理destination、IQ source-ready、rename/free-listを表示します。共通のMUL/DIV実行カードはMD laneの状態です。全物理レジスタ値一覧はありません。

## レジスタ表示の取得元

- legacy: `u_execute_state.u_regfile.registers.registers[0..31]` の実FST値
- v1: `u_inst_engine.u_inst_unit.u_regfile.registers.registers[0..31]` の実FST値
- v2: `u_inst_engine.u_inst_unit.u_physical_register_file` の `reset_n/cpu_stop/wb3_valid/wb3_addr/wb3_data` から、RTLのarchitectural bank p0〜p31を復元。投機用p32/p33やRATの値ではありません。書込みはedge直前の入力を使用し、CSRを含む実WB3データを反映します。

配列信号がないlegacy/v1 traceや不明値は—表示します。v2も途中開始のtraceでは初期値を推測せず、リセットまたは書込みを観測するまで—です。v2のリセット復元はCPU edgeで観測できるリセットを対象とします。信号幅不一致はエラーにします。表示値は選択cycle時点の値で、命令台帳の将来の結果を使用しません。

## 対応命令

共通デコーダはRV32Iの整数ALU・即値・LOAD/STORE・BRANCH・JAL/JALR・LUI/AUIPC、RV32MのMUL/MULH/MULHSU/MULHU/DIV/DIVU/REM/REMU、CSRの6種、ECALL/EBREAK/SRET/MRET/WFI/SFENCE.VMA/FENCE/FENCE.Iを表示します。ABI名とx番号を併記できます。不正encodingは.wordです。encoding表示は各CPUでその特殊命令の全動作が実装済みであるという保証ではありません。

## 検証

```bash
python3 -m unittest discover -s tests -v
python3 validate_traces.py
python3 validate_traces.py --serve
```

2026-09-07のsingleシミュレーションは3 CPUともPASS（PIO 0xbeef）。ログはhardware/sim/logのtest_result_20260907_120956.log（legacy）、121500.log（v1）、121645.log（v2）。

| 実FST | cycles | 命令instance | 完了/retired | stage-PC照合 | MUL結果照合 |
|---|---:|---:|---:|---:|---:|
| legacy | 109003 | 994 | 993 | 29856 | 64 |
| v1 | 101922 | 1255 | 1047 | 14877 | 64 |
| v2 | 102925 | 1160 | 995 | 24068 | 64 |

v1回帰はstage-PC、全retire命令の5段連続移送、MULのEXECUTE占有90677–90680、90678で未確定結果—／90680で結果2、90560のmemory read valid、Inspector、Ledger、検索／filterを検証します。v2は全有効ROBのword・命令対応も確認します。単体テストは誤profile／誤packed幅の拒否とポート競合・異常終了も含みます。`--serve` は3つの実FSTを同時に8000からbindして競合時の自動繰上げを検証できます。

Chrome実GUIでも3 CPUの起動、CPU別行、PC/MUL検索、前後cycle、filter、zoom、CanvasクリックInspectorを確認しました。スクリーンショットは `validation/*-gui.png`。任意の開発用 `gui_smoke.py` のみ追加パッケージ `websockets` を使います（通常起動には不要）。再現には `validate_traces.py --serve` を起動し、別端末でChromeを `--headless --disable-gpu --user-data-dir=/tmp/psc-three-cpu-chrome --remote-debugging-port=9224 --window-size=1600,1200 about:blank` 付きで起動して `python3 gui_smoke.py` を実行します。テストは8000/8001/8002を使い、終了時にそのChromeを閉じます。

## 制限事項

- cycle 0は最初のCPU clock立ち上がり。同timestampの全更新適用後を表示します。組合せfireは次のedgeの受理条件です。
- v1/v2のCOMMITはcommit占有／受理条件の観測で、レジスタ書込みのedgeとは1cycle差があり得ます。legacyはSTORE→IDLE完了マーカーです。
- 開始はlegacyのdecode捕捉、v1のID入場、v2のdecode/rename捕捉。終了は最後の観測。flushとtrace末尾未完了はflushed/incompleteとして区別不能です。
- singleの実FSTにはMULがありますがDIV/REMはなく、ALU/MD同時activeも0cycleでした。DIV/REM追越しが見える実ワークロードの検証は未実施です。存在しない追越しを生成表示しません。
- v2は検証したROB=2、IQ=2、PRF=34配置専用。変更時はprofile更新が必要です。同幅でもRTL内のfield順を変更した場合は幅検証だけでは検出できません。
- FST→VCDはstdoutストリームですが全選択cycleはRAMへ保持し、解析時間とRAMはtrace長に比例します。初回解析は非同期GUIではありません。
- X/Zは不明値。任意信号波形、全物理レジスタダンプ、複数コアの同時表示は対象外です。
