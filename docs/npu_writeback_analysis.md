# PSC-NPU PE簡略化・共有Write-back構成の検討

調査日: 2026-09-17。対象は作業開始時の現行RTL。本体RTL、既存テスト、Makefile、softwareは変更していない。

## 結論

- **現行4×4には16個の個別PE FSMはない。** `PSC_NPU_PE_INT` 1 instance、`THREADS=16`、共有FSM 1個である。各論理PEに個別counterもない。
- **共有乗算器から16 entryへの512bitインターフェースは存在する。** ただし16本の独立演算laneではなく、時分割で埋めた積を保持するレジスタbankの出力である。現行合成では上位ビットが共有され、実体は272 FF / 272独立bitになる。
- **ID付きWrite-backは成立する。** lane数は`clamp(MUL_NUM, 1, 16)`に合わせる。SoCおよび既存timing wrapperは`MUL_NUM=4`なので、性能維持の第一案は4 lane。SA4x4単体の既定値は2 laneである。
- **ACC entryのFSMは不要。** 現行の共有FSMが担う開始・完了・clear・operand snapshotの契約は、global schedulerに残す必要がある。
- **積保持の撤去と既存のcycle契約には衝突がある。** `test_pe_cycle_contract`は全ACCの一括更新を毎cycle確認している。逐次ACC更新への無条件置換は、このテストを壊す。テストを弱めて採用してはならない。
- 最初は「固定laneのID bus + entryごとのpending product + ACC + global commit」で契約を保ち、配線・RTL構造を整理する。積保持まで撤去するstreaming ACCは、controller内での限定利用や互換adapterを含む次段階の検討とする。

## Current Architecture

### 実際のデータフロー

```text
PSC_NPU_Controller
  read_start / i_idx / j_idx / k_idx
      ↓
  PSC_NPU_ReadController u_systolic_array_read_ctrl
    rd_read_addr, rd_read_valid → cache/memory
    rd_read_ready, rd_read_data ← cache/memory
    a_data_out_cur[127:0], b_data_out_cur[127:0]
      ↓ func_a_os_data / func_b_os_data
    cur_a_data, cur_b_data
      ↓ a_left_in_bus[31:0], b_top_in_bus[31:0]
  PSC_NPU_SystolicArray4x4 u_sa
    a_in_threads / b_in_threads : 隣接entry間のA右シフト/B下シフト
      ↓ en_shift_right / en_b_shift_bottom
    PSC_NPU_PE_INT u_pe_threads (THREADS=16, RESULT_HELD=1)
      data_A[127:0], data_B[127:0] : operand shift registers
      data_out_valid[15:0]        : 16件まとめて乗算要求
      ↓
    PSC_NPU_PE_Mult u_mult
      valid_latch, signed_mode_latch, data_A_latch[], data_B_latch[]
      group_index → operand mux → mul_A_bus / mul_B_bus
      GEN_MULT[] → mul_result_bus (16bit/physical lane)
      result_C[511:0]             : entry別に更新・保持
      data_out_ready[15:0]        : 完了entryを1cycle通知
      ↓ result_C_threads / data_in_ready
    u_pe_threads
      mul_done | data_in_ready → all_mul_done
      S_PARTIAL_SUM → ps_acc_threads[511:0] を一括加算
      ↓ ps_select=row_s による16:1選択
    ps_acc_out[31:0], done_out
      ↓
  S_OUTPUT_MEMORY / S_OUTPUT_MEMORY_W
    sa_req_ready → c_write_valid, c_write_addr, c_write_wdata
    c_write_ready待ち → 次entry / 次tile / S_DONE
```

`PE_ID = row*4+column`。A/Bのshift registerは単なる入力bufferではなく、Virtual Systolic Arrayの空間的なoperand配置を表す。これを撤去する場合は、同じ時間・座標対応をscheduler側で再現する必要がある。

ControllerはCの4×4 tileごとにACCをclearし、K方向の各tileの結果を同じACCへ蓄積する。各K tileで8回の入力stepと4回のflush stepを実行する。各stepは`done_out`を待ってから次のshiftへ進む。出力は最後に16個のACCを順番に32bitで書く。

### 乗算lane数とDSPの実数

| 構成 | 指定値 | 最大完了数/cycle | 16件のACTIVE処理cycle数 |
|---|---:|---:|---:|
| `PSC_NPU_PE_Mult`の既定値 | 2 | 2 | 8 |
| `PSC_NPU_SystolicArray4x4`単体の既定値 | 2 | 2 | 8 |
| `PSC_NPU_Controller`の既定値 | 4 | 4 | 4 |
| legacy/v1/v2のSoC instance | Controller既定値 | 4 | 4 |
| `PSC_NPU_Timing` wrapper | 明示的に4 | 4 | 4 |
| `PSC_NPU_PE_SimTop`既定値 | 1、THREADS=2 | 1 | 2件を2cycle |

乗算器は可変latencyの独立workerではなく、固定group順の組合せ乗算と結果registerである。各ACTIVE cycleに最大`PARALLEL_NUM`個が完成し、その結果とreadyをregisterへ書く。受信側は次のedgeでreadyを認識する。

RTLには各laneでsigned用とunsigned用の2つの`*`が書かれているため、operatorの文字数だけでDSP個数は確定できない。今回の現行timing top合成では、**NPU演算用MULT9X9は4個**、address計算用3個、計7個になった。

### PE内部のregisterと制御

| 要素 | 宣言上の量、4×4標準構成 | 現行での意味 | 判定 |
|---|---|---|---|
| `ps_acc` | 16×32=512bit | C tileの部分和、16加算器 | PE/ACC bankに必要 |
| `data_A`, `data_B` | 各16×8=128bit | 右/下へのshift context | 必要。別datapath moduleへ分離可能 |
| `state` | 3bit、共有1個 | 4状態で全16entryを同期制御 | global schedulerへ移動可能 |
| `mul_done` | 16bit | 異なるcycleに来る完了を記憶 | 共有状態。固定scheduleなら最終group/drainへ置換可能 |
| `data_out_valid` | 16bit | 未完了entryの要求を継続 | 共有batch handshakeへ置換可能 |
| `busy`, `done` | 各1bit | 全体のbusyと完了pulse | global側に必要、外部契約を維持 |
| `product` | 16×32=512bit | RESULT_HELD=0時の積capture | 現行SAでは**すでに合成除去** |
| `signed_mode_latch` | 1bit | PW→SWの加算時拡張 | PW=SW=32では**すでに合成除去** |
| `mul_complete_next`, `all_mul_done` | 組合せ | 完了bitmapのOR/reduction | 固定scheduleでは削除候補 |
| `a_shift_to_right`, `b_shift_to_bottom` | wire alias | `data_A/B`の隣接接続 | 追加registerではない |
| `PE_ID` | 現状はpacked位置で表現 | entryの座標 | generateのlocalparamでよく、FF不要 |

`data_clear`はA/B shift registerには全状態で作用する。一方、ACCのclearは`S_INIT`でのみ受け付ける。`start`も`S_INIT`で、clearが無いときだけ受け付ける。busy中のclearを即ACC clearに変えると互換性が変わる。

### PE FSM

| state | 現行動作 | PE固有状態か | 移動/置換/削除 |
|---|---|---|---|
| `S_INIT` | busy解除、要求/完了mask初期化、clear/start受理 | いいえ、全entry共通 | global IDLEへ。entryには`acc_clear`/enableだけ渡す |
| `S_MUL` | 全threadのrequestを立てる | いいえ | global batch_accept/issueへ。pulse化は受付時刻の互換性に注意 |
| `S_MUL_WAIT` | readyを集計、未完了request保持、全完了待ち | いいえ | group counterとpipeline drainへ。可変latencyなら完了trackingをglobalに残す |
| `S_PARTIAL_SUM` | 全ACCを同じedgeで更新、done pulse | いいえ | 一括更新互換案ではglobal `commit`へ。streaming案では加算phaseを削除し最終WBの受理で完了 |

したがってentryのFSMは完全になくせる。ただし現在すでに1個に共有されており、「16個のFSMを削除する」規模の削減は得られない。Yosysは共有stateを4 FFのone-hot表現へ変換した。

### 共有乗算器側に残る状態

`STATE_IDLE`は入力batchのsnapshot、`STATE_ACTIVE`は`group_index`による順次実行、`STATE_WAIT_CLEAR`は要求が下がるまで再受付を防ぐ役割を持つ。これらはglobal schedulerへ統合できる。

`WAIT_CLEAR`は現在のlevel型requestに必要である。requestをそのまま残して状態だけ削除すると同一batchを重複受付する。明示的な`batch_valid/batch_ready`または1cycleの受付pulseへ置換して初めて削除できる。

`data_A_latch/B_latch`は合計256bitで、PE側shift registerの256bitとは別物である。既存cycleテストはbusy中にもshift/clear/modeを変えるため、snapshotの保持は必要。Controller内ではshiftが停止するので将来的な除去余地はあるが、外部PE契約と同じものとして扱ってはならない。

## Write-back

### current

`PSC_NPU_PE_Mult`のACTIVE処理は、entry `seq_i`ごとに次を行う。

```text
group_index == seq_i / PARALLEL_NUM
かつ mul_lane_valid[seq_i % PARALLEL_NUM]
    → result_C[seq_i*32 +: 32] を更新
    → data_out_ready[seq_i] を1にする
```

つまり既に**固定lane→entryのdemuxとholding register**であり、16乗算器から16PEへ結ぶfull crossbarではない。以前の可変wide slice書込みを避けるconstant-slice実装になっている。

512bitを残す理由は「乗算器共有に必要だから」ではなく、**早く完成した積を保存し、最後に16個のACCを同時更新するため**である。積を到着時に消費してよいなら、この全entry分の中間保持は原理的には不要。

INT8×INT8の積は16bitである。現行はsigned/unsigned両対応なので、bit[15:0]と、signed時の符号/unsigned時の0を表す拡張bitの計17bitが独立になる。bit[31:16]は同じbitである。Yosysのtechnology-map前netlistで`u_mult.result_C`のdriverが272個の`$_DFFE_PN0P_`になることを確認した。ACCは512個で残り、PEの`product`と` signed_mode_latch`は除去される。

従って「512 FF削減」「物理配線が512→64で1/8」はそのまま実効果を表さない。RTL上の幅、独立net数、fanout先のpin数、配置配線で使用するwire資源は区別する必要がある。

### proposed

```text
PSC_NPU_Controller（既存memory/API境界を維持）
        |
Global MAC scheduler
  batch snapshot / group index / signed mode / clear / commit / drain
        |
Shared multipliers × P
        |
registered WB lanes × P
  {valid, pe_id[3:0], data[31:0]}
        |
ACC bank: 16 entries
  PE_ID = row*4+column（合成時定数）
  接続先LANE = PE_ID % P（合成時定数）
        |
ps_select → ps_acc_out → 既存C-memory write controller
```

P=2なら`2×37=74bit`、P=4なら`4×37=148bit`の論理bus。INT8積の拡張を合成器が共有すれば独立data bitは各lane約17bitになる。IDをregisterにするのは**結果の宛先tagをlatency分保持するため**であり、entryの固定PE_IDをFFにするわけではない。

#### A: 一括更新契約を守る第一段階

```systemverilog
// 各entryの概念。reset、clear、valid管理は省略。
localparam [3:0] PE_ID = ENTRY_INDEX;
localparam integer LANE = ENTRY_INDEX % WB_LANES;
wire hit = wb_valid[LANE] && (wb_pe_id[LANE] == PE_ID);

always @(posedge clock) begin
    if (hit)
        pending_product <= wb_data[LANE];
    if (global_commit)
        accumulator <= accumulator + pending_product;
end
```

entryのFSMは不要。積の保持をmultiplier側からentry側へ移すだけなので、大幅なFF削減は期待しない。共有busを物理laneとその担当entryの近くに配置し、pending→ACCの経路を局所化できる可能性があるが、現行のflatten後構造も同形に近いためrouting改善も未保証。

group scheduleと最終結果のdrainでglobal commitを生成する。現行と同じedgeでcommitし、clear/start/snapshotの時刻を維持すれば既存PE cycle契約を保つ構成を作れる。完了bitmapの削減は固定latencyを前提にしていることを明記する。

#### B: 積保持を撤去するstreaming案

```systemverilog
// resetと、global schedulerが許可したclearを別途優先処理する。
if (wb_valid[LANE] && wb_pe_id[LANE] == PE_ID)
    accumulator <= accumulator + wb_data[LANE];
```

こちらはACC、固定ID comparator、write enable、32bit adderだけになる。A/B shift contextは別moduleへ置く。**ACC += dataにはadderが必要**であり、16 entryなら基本的に16加算器のままである。

Controllerは`done_out`後だけ結果を使うので、内部実装としては計算結果を維持できる見込みが高い。ただしSAの`ps_acc_out`やPEの`ps_acc`はbusy中にも変化する。既存PE cycleテストに対しては互換ではない。公開PEを互換実装として残し、SA内だけstreaming bankを使う構成などを検討できるが、それは内部の観測契約が異なる2構成を保守するという追加コストになる。

古いACCをshadowへ複製してbusy中の読出しを維持する案は512 FFを追加するため、今回省きたい272 FFの積bankより大きくなり得る。単純に出力を0やhold値に固定するだけでは、任意entryの従来値を返す契約を維持できない。

### 同一PEへの同時Write-back

現行は`id(lane) = group_index*P + lane`。`0 <= lane < P`なので有効lane間のIDは異なる。末尾groupの範囲外IDをvalid=0にすれば、NがPで割り切れない構成も同様。固定latencyでtagとvalidを同じだけ遅延すればこの性質は維持される。

| 方法 | 回路/制御コスト | 評価 |
|---|---|---|
| schedulerで重複禁止、固定lane所有 | 最小。構造的に重複が生じない | 推奨 |
| `ACC + wb0 + wb1` | 追加adder/段数。muxやtiming悪化 | 現行では不要 |
| arbitration | loserを保持するqueue/ready/replayが必要 | 可変latency・動的割当に拡張するときだけ検討 |

`if (...) acc<=acc+d0; if (...) acc<=acc+d1;`では同一entryへの前半更新が消える。priority選択だけでも片方を失う。将来の実装には「validなIDが同cycleに重複しない」「id%Pがlaneと一致する」のassertionを置く。

### 全lane broadcastと中央decoder

全ACCが全laneを受け取る実装では、entryごとにP個のID比較とP:1のdata選択が必要になる。32/64bitの幹線が減っても、全entryへ枝分かれするfanoutやmux入力配線は増え得る。

推奨の固定lane方式なら、P=2ではlane0→偶数entry、lane1→奇数entry、P=4では各lane→4 entryとできる。32bit data muxをなくしつつ、`valid && id==PE_ID`という読みやすいRTLを保てる。

中央decoderによるone-hot write enableも論理的には同等で、合成器が共通decodeを共有する余地がある。まずlocalparam ID方式を採用し、合成後に比較器の複製や高fanout enableが問題になったときだけ中央化する。

## Estimated Resource Impact

### 現行RTLの再合成・配置配線

既存`build_nextpnr_npu`のログは今回の再合成値と一致しなかったため、現行の基準値として流用していない。既存Makefileを読み、cleanを呼ばない`synth` targetで独立した`/tmp`へ再合成した。

条件: `PSC_NPU_Timing`、MUL_NUM=4、GW2AR-LV18QN88C8/I7、family=GW2A-18C、81 MHz制約、nextpnr seed=1。

| 指標 | 現行NPU timing top |
|---|---:|
| Yosys LUT1～LUT4合計 | 2,217 |
| Yosys FF合計 | 1,945 |
| Yosys ALU | 762 |
| Yosys MUX2_LUT5 | 197 |
| MULT9X9 | 7（演算4、address3） |
| nextpnr LUT4資源表示 | 3,037 |
| nextpnr ALU表示 | 820 |
| nextpnr FF表示 | 1,945 |
| routed Fmax報告 | 190.37 MHz、81 MHz PASS |
| critical path遅延 | logic 1.68 ns + routing 3.57 ns |

Yosysの論理cell数とnextpnrのresource bucketは定義が異なるため混ぜて差分を出さない。今回の最長pathはACC出力選択側を通って`c_write_wdata`へ至り、共有乗算結果の返却busそのものではない。従ってWB改善だけでNPU全体のFmax改善を保証できない。

### 独立PoCの実測

ファイル: `hardware/sim/tests/npu_writeback_poc/writeback_poc.sv`、`run.py`。本体NPUへの組込みなし。

- 16×32bit ACC、2/4 lane、4bit ID。
- `STYLE=0`: 固定lane別に積を保持し、commitで一括加算する現行相当回路。
- `STYLE=1`: 全laneをpriority muxで受け取るstreaming回路。
- `STYLE=2`: 固定laneだけを受け取るstreaming回路。
- `STYLE=3`: 全laneをone-hot条件のORで受け取るstreaming回路。
- STYLE=0には疎なvalidに対応するpending bitmap 16bitを置いた。現行NPU全体の忠実なコピーではなく、保持型とstreaming型の比較用回路である。
- 各variantは同じregistered stimulusと出力read muxを使う。タイミングwrapperは回路を残すための疑似入力で、正常なbatch protocolの生成器ではない。動作検証は別testbenchで合法な入力を与える。
- 32bit portの上位を符号拡張した17独立bitとして合成し、INT8積のbit共有を再現した。全32bitが独立するケースも別途合成した。
- 乗算器、operand mux、NPU controller、memory interfaceは含めない。従ってDSPはすべて0で、全NPUの削減量・Fmaxではない。
- 各variantを同じdevice/constraintでseed=1,2,3の配置配線にかけた。

| lane数 | 方式 | LUT1～4 | FF | MUX5～8 | routed wire資源数の範囲 | Fmax報告範囲 MHz |
|---:|---|---:|---:|---:|---:|---:|
| 2 | 保持、一括commit | 662 | 957 | 32 | 17,736～18,247 | 340.60～367.24 |
| 2 | 全lane、priority | 1,210 | 669 | 324 | 19,756～20,301 | 260.35～301.11 |
| 2 | **固定lane、streaming** | **595** | **669** | **32** | **14,238～14,518** | 336.81～350.51 |
| 2 | 全lane、one-hot OR | 1,281 | 669 | 407 | 21,700～21,995 | 203.79～250.19 |
| 4 | 保持、一括commit | 700 | 975 | 32 | 17,961～18,675 | 343.52～363.37 |
| 4 | 全lane、priority | 3,513 | 687 | 2,168 | 37,076～38,197 | 183.49～197.39 |
| 4 | **固定lane、streaming** | **599** | **687** | **32** | **14,142～14,514** | 384.02～396.83 |
| 4 | 全lane、one-hot OR | 1,951 | 687 | 738 | 28,369～28,648 | 192.20～208.33 |

全variantでALUは512個。FFはwrapperを含む比較値である。使用wire数はnextpnrのROUTING属性から重複を除いたbound wire ID数であり、配線のbit数、総延長、局所混雑率ではない。clock/reset等も含む。PoCの絶対Fmaxを実機やNPU全体の保証値として扱ってはならない。

固定lane streamingは、2 laneで67 LUT / 288 FF減、3 seed平均のwire資源数が19.7%減。4 laneでは101 LUT / 288 FF減、wire資源数21.2%減。288 FFの内訳は272bitの積保持と16bitのpending bitmapである。入力WB registerは両variantに共通なので、このFF差をそのまま現行NPUから引くことはできない。

2 laneではFmax範囲が重なり、改善は確認できない。4 laneではこのPoC内で改善した。全lane受信はどちらのRTL記述でも本PoCではLUT・routingを悪化させた。合成器や記述による最適化余地は残るが、固定scheduleに不要な汎用muxを導入する理由は乏しい。

32bit全独立、2 laneの補助合成では保持型1,209 FFに対しstreaming型681 FFで528 FF減だった。これは512bitの積保持+16bit pendingを消した結果で、INT8現行の見積りにこの値を使うのは過大評価になる。

### 本体への見積り

| 指標 | 一括更新互換案A | 積保持撤去案B |
|---|---|---|
| LUT | FSM統合やdecode整理による小幅削減の可能性。ほぼ同じ回路へ合成される可能性もある | 固定laneなら削減が期待できる。全lane mux追加は増加リスク |
| FF | 積保持272bitとACC512bitは必要。tag register追加との相殺がある | 積保持272bitを削除。ただし新WB pipelineのdata/ID/valid FFを追加 |
| DSP | 同じPなら変更なし | 同じPなら変更なし |
| routing | busの責務と配置を整理できる。実物の削減は未測定 | 保持bankとそのclock/reset/enable配線を削減できる。固定lane分割が重要 |
| critical path | pending→adder→ACCを維持可能 | registered WB→adder→ACC。registerを省くとoperand mux→multiply→addの長いpathになる |
| Fmax | 全NPUで要再測定 | 改善未保証。WB data/tagのregister境界を保持する |

例えば単純な登録済みWB busを新設すると、独立17bit data + 4bit ID + validで最大22 FF/lane必要になる。積bank272bitだけと比べた粗い差はP=2で228 FF減、P=4で184 FF減。固定scheduleによるtag共有・定数bit最適化や既存ready/mul_done/requestの撤去により変わるので、これは全体合成の測定値ではない。

## Risks

1. **Atomic commit互換性。** 到着時ACC更新はPE cycle契約を破る。一括commit型ならpending積を保持する必要がある。
2. **4→2 laneの性能低下。** 現行4結果/cycleを2本で無条件に受けることはできない。queue/serializeで受ける場合も8 cycle分の出力が必要になる。MUL_NUM自体を4→2に変えるとgroup処理は4→8 cycle、現行制御のままなら12 stepのK tile当たり48 cycle増える。最終行列結果が同じでも性能維持ではない。
3. **latencyとtagの整合。** `group_index`更新と結果registerのedgeを揃える。最終group発行ではなく、最終WBがACC/pendingへ受理された後にcommit/doneを生成する。
4. **reset/clearと残留WB。** resetはvalid pipelineも落とす。現行のidle限定ACC clearを維持する。busy中のabortやclear優先を新しく導入すると既存契約が変わる。
5. **signed modeとoperand snapshot。** 現行PEはstartでmodeを保持するが、乗算器は2cycle後のbatch capture時のmodeを使う。PW=SW=32ではPE側modeは算術に影響しない。modeをstart時固定へ統一する変更でも、busy-time入力変化を試す既存テストとの差が出る。
6. **input/output networkは残る。** operand shiftの256bit、snapshotの256bit、ACCの512bitと16:1出力選択は別の回路。WB busだけでNPU全配線が縮むわけではない。
7. **可変latency化。** 将来はissue時の非衝突だけでは完了時の非衝突を保証できない。completion schedulingやqueueが必要になる。
8. **Fmaxの外挿。** PoCには乗算器も全体controllerもなく、配置密度もSoCと異なる。3 seed結果は傾向確認であり、局所混雑heatmapや実機動作の検証ではない。

## Compatibility

INT8 signedの積を32bitへ符号拡張、unsignedでは0拡張してbusへ出せば、ACCは同じ32bit加算でよい。オーバーフローは現行同様の32bit moduloであり、飽和演算を追加しない。IDはC tileのrow-major順を保つ。

`PSC_NPU_Controller`のport、CSR、`BASE_ADDR_A/B/C`、matrix dimension、Cの32bit format、read/write handshake、`busy/done`の外部意味は維持できる。softwareの`sa_run()` / `sa_run_checked()`はsigned_modeを設定しCSR完了をpollするため、内部lane構造を知る必要はない。laneを減らすとtimeout budgetへの影響があり得る。

`sa_state_reset`は現行ではS_DONEからIDLEへ戻す操作であり、実行中の一般abortではない。互換性を保つ実装ではこの意味も変えない。

既存cocotbは次のすべてを維持する必要がある。

- PEのsigned/unsigned、累積、毎cycleのatomic commitとsnapshot契約。
- 2×2/4×4のshiftと行列積、signed extremes。
- Controllerの正方/長方行列、K tile蓄積、memory待ち、write backpressure、restart。
- MUL_NUM=1の低並列構成。新WBはPをparameter化し、P=1/2/4、将来のP=16と末尾groupのvalidを明確にする。

## Implementation Complexity

- **低～中:** global MAC scheduler、A/B shift datapath、固定lane WB、pending+ACC entryへ責務分離する案A。既存のcapture/commitタイミングを保つ検証が中心になる。
- **中:** streamingをController内部へ限定し、既存PE module/SimTopは互換実装として維持する案B。行列scoreboardと境界契約の両方を保守する必要がある。
- **高:** ACC加算器までP個に共有するread-modify-write bank。ACC read mux、bank port、read-after-write forwarding、外部readとの競合が増える。16entryのregister bankを単純なdual-port RAMに置き換えるだけでは、2結果に必要な2 read+2 writeを同時には賄えない。固定bank分割やread/write phase分離まで検討が必要なので、今回の第一案にはしない。

## Recommendation

**採用すべき方向は「個別PE FSMの削除」より、「既に共有されている制御を明示的なglobal schedulerへ整理し、固定laneのID付きWBとACC bankへ分離すること」である。**

まず4 laneのまま、案Aで既存のatomic commitと全テストを保つ。IDは合成時定数、各entryの接続laneも合成時定数にする。広いbus記述が整理されても、同じholding bankが必要なので、この段階で大きなFF/配線削減を約束しない。

大きい削減を求める次段階では、Controller内で結果をdone後にだけ読む契約を根拠に案Bを検討する。既存の公開PE契約は互換module等で維持し、テストを削除・弱体化しない。PoCは固定lane streamingの有望性を示したが、本体置換の機能・性能互換性を証明したものではない。

本体の変更対象はNPU内のPE/Mult/SA接続と小さなglobal schedulerに限定でき、CPU v1やsoftware APIを変える必要はない。本報告ではその変更は実施していない。

## 検証・再現・作業状態

### 実施結果

| 検証 | 結果 |
|---|---|
| 現行PE cocotb | 2/2 PASS（cycle contractを含む） |
| 現行SA2x2 cocotb | 1/1 PASS |
| 現行SA4x4 cocotb | 1/1 PASS |
| 現行Controller MUL_NUM=4 | 7/7 PASS |
| 現行Controller MUL_NUM=1 | 7/7 PASS |
| PoC independent scoreboard | 2/4 lane × 固定/任意IDの4試験 PASS |
| PoC Yosys | 12 variantすべてPASS |
| PoC nextpnr | 17bit実効幅の8 variant × 3 seed、24/24 PASS at 81 MHz |
| 現行NPU再合成・nextpnr | PASS at 81 MHz |
| `git diff --check` | PASS |

PoC scoreboardは各case 200 batch、計5,648 cycle。signed/unsigned積、32bit任意値とwraparound、疎なvalid、clear、ID配送を独立Pythonモデルで確認する。保持型は各cycleの旧ACC保持も確認し、streaming型は各cycleの逐次加算を確認する。両方式のcycle-equivalenceを主張しない。任意ID試験では全lane受信型だけを対象にし、同cycleの同一IDは入力契約により生成しない。

解析用の中間JSON出力を最初に試した際、Yosys primitiveのprocessをJSONに出せないエラーが1回発生した。`blackbox =A:whitebox`を適用して再出力し解消した。RTL/testの不具合やテストFAILではない。

新構造を本体へ組み込んでいないため、新構造での既存cocotb/OS/実機互換性は未検証。CPU RTL未変更なのでCPUのRISC-V/core/basic/long回帰は実行していない。

### 成果物

- 新規: この報告書。
- 新規: `hardware/sim/tests/npu_writeback_poc/writeback_poc.sv`。
- 新規: `hardware/sim/tests/npu_writeback_poc/run.py`。
- 生成物: `/tmp/psc-npu-writeback-20260917-gvI5XU/`内に現行/PoCのJSON、合成・P&Rログ、生成testbench、cocotb XML/log。`poc/summary.json`に全比較結果。PoC directory内にはPython importで生成された`__pycache__/run.cpython-313.pyc`もある。
- 既存ファイル変更: なし。削除: なし。
- Git: 作業開始前からの変更を維持。add/commit/push等は実行していない。PoC directoryは既存`.gitignore`の`hardware/sim/tests/*`によりignoredであり、報告書だけが新規untrackedとして表示される。

PoC再現例（repository rootで実行、新規のbuild directoryを指定）:

```bash
python3 PSC-ONE/hardware/sim/tests/npu_writeback_poc/run.py \
  --build /tmp/psc-npu-wb-reproduce --pnr --seeds 1,2,3
```

現行NPU合成は`hardware/sim`で以下を実行した。

```bash
make -f Makefile.nextpnr.npu synth \
  BUILD_DIR=/tmp/psc-npu-writeback-20260917-gvI5XU/current
```

P&Rには同Makefileのdevice/family/CSTを使い`--seed 1`を指定した。cocotbは同じ既存module/testをIcarusで実行し、結果とbuildを`/tmp`へ分離、波形dumpのdefineは付けていない。test本体のskip/変更はない。

使用ツール: Yosys 0.68+136 (c30457480)、nextpnr 0.11.1-18-gdec04b3b。Gowin用のHimbaechel/Apicula flowの構成は[公式nextpnr README](https://github.com/YosysHQ/nextpnr#gowin)にも記載されている。今回の数値は上記local toolで得た測定値であり、外部文献の数値ではない。
