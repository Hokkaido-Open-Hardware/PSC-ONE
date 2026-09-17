# cache_dma_controller 最適化結果

## 結果

対象: `PSC-ONE/hardware/rtl/cache/src/cache_dma_controller.sv`。2026-09-15測定。
外部module宣言・parameter defaultは変更前と一致。CPU RTL、共有BRAMモジュール、測定用Makefile／TimingTop／CSTは変更していません。
`<=`と`=`は関連する記述で縦に揃えています。

| Resource | Before | 共通datapath化 | 中継段削減 | Final: タグ判定分離 |
|---|---:|---:|---:|---:|
| LUT4 | 3525 | 3099 | 2022 | 1316 |
| MUX2_LUT5 | 1377 | 1153 | 674 | 291 |
| MUX2_LUT6 | 574 | 524 | 245 | 78 |
| MUX2_LUT7 | 225 | 253 | 113 | 33 |
| MUX2_LUT8 | 110 | 121 | 30 | 9 |
| ALU | 80 | 80 | 80 | 80 |
| DFF | 947 | 943 | 665 | 668 |
| BSRAM | 10 | 10 | 10 | 10 |
| Fmax | 139.26 | 160.69 | 111.37 | 204.25 |

Fmaxの単位はMHz。配置配線完了後の最終値です。LUT4はYosysのLUT4単独個数ではなく、baselineと同じnextpnrのDevice utilisationを使用しています。
全3候補でcache 9/9、CPU basic 53/53、81 MHz timingがPASSしています。
最終版はLUT4を62.7%、MUX5〜8の合計を82.0%、DFFを29.5%削減し、Fmaxを46.7%改善しました。

## 巨大MUXの原因と変更

- `data_write`の更新／保持条件がhit、clean miss、writeback完了、fillのFSM分岐に分散していました。`cpu_ready`、`cpu_data_out`、外部要求、tag/data書込みにも同じ条件が重複し、wide datapathとFF enableへ深い選択回路が入っていました。
- `write_event`、`write_data`、`memory_request`、`memory_request_addr`、`response_valid`、`response_data`へ集約。storeのword選択と、hitで他wordを保存／missでゼロにする処理を共通化しました。
- `data_write`は毎周期更新し、BRAMが取り込む周期だけ`data_we`を立てます。128bitの保持enableを除去しました。外部`mem_*`と`cpu_data_out`は有効なイベント時のみ更新し、従来の保持動作を維持しています。
- 単にBRAM出力を直結した中継段削減版は、タグBRAM→比較→tag書込みenableが8.98 nsとなり、Fmaxが111.37 MHzへ低下しました。
- 最終版はhit／dirty判定を2bitのレジスタで保持し、タグ比較器をwide datapathから切り離しました。IDLE中にタグRAMを先読みします。直前のtag書込みまたはINITの最終無効化と競合する場合は、旧indexで書込みを完了してISSUEで1周期待ちます。データRAMの同期読み出し周期は維持しています。

## State／register

- FSM: **10 → 9 states**。`S_ALLOC_RESP`を削除し、fill取込みと同じ周期に応答します。
- 通常は`S_LOOKUP_ISSUE`をbypassし、タグRAM書込みと競合する場合に使用します。`S_LOOKUP_READ`では小さな判定結果だけを保持します。
- `S_POST_WBALLOC`は外部要求受付待ちのため維持しています。
- `line_read_r` 128bit、`fill_line_r` 128bit、victim tag/valid/dirty 20bitを削除。
- burstの先頭wordをhit／fill時に返し、保持する残り3wordを`burst_tail_r` 96bitへ縮小（従来128bit）。
- `lookup_hit_r`／`lookup_dirty_r`を追加。上記datapath registerはRTL上で差引306bit削減。物理DFFの最終差分は947→668（279個削減）です。
- 冗長なword address／slot表現を除去し、byte address slotの[3:2]からword位置を取得。これらの重複bitは合成時に共有され得るため、別途FF削減数には加算していません。

## レイテンシ Before／After

`cpu_valid`を取り込んだ立上りをcycle 0とし、対応する`cpu_ready`を観測する立上りまでを測定。
単体テストの`TAGLSB=6, STALL=0`、競合のない単独要求、外部要求出力から応答取込みまで3周期のメモリモデルです。

| Access | Before | Final |
|---|---:|---:|
| read hit | 4 | 3 |
| write hit | 4 | 3 |
| clean read miss | 8 | 6 |
| dirty read miss | 12 | 10 |
| clean write miss | 4 | 3 |
| dirty write miss | 7 | 6 |
| burst hit: first / last | 5 / 8 | 3 / 6 |
| burst clean miss: first / last | 8 / 11 | 6 / 9 |
| burst dirty miss: first / last | 12 / 15 | 10 / 13 |

burstは従来どおりラインのword 0から4周期連続で返却します。
最終版でタグポートが直前の書込みと競合すると、表の値に1周期追加されます。
キュー待ち、外部受付停止、メモリ応答遅延は別途加算されます。実SDRAMの固定レイテンシを示す値ではありません。

## Critical path

| | Before | Final |
|---|---|---|
| 経路 | control → deep MUX → data_write DFFCE.CE | data BRAM DO14 → word/response選択 → cpu_data_out[8] DFFCE.D |
| logic（clk-to-q/setupを含む） | 2.63 ns | 3.85 ns |
| routing | 4.55 ns | 1.04 ns |
| total | 7.18 ns | 4.90 ns |
| Final Fmax | 139.26 MHz | 204.25 MHz |

合計と内訳には表示桁の丸め差があります。最終経路のBRAM clk-to-qは2.26 nsです。
測定は既存のstandalone TimingTop、GW2AR-LV18QN88C8/I7、FAMILY=GW2A-18C、FREQ=81を使用しました。

## 最終検証

| Command | Result |
|---|---|
| `make -f Makefile.cache simulate_CACHE` | **PASS**: 8 data/cache + 1 I-cache、FAIL=0、SKIP=0 |
| `make -f Makefile.cpu simulate_PSC_ONE_TESTS TEST_PROGRAM_LIST=basic` | **PASS**: default CPU_VERSION=v1、53/53のPIO実値が期待値と一致 |
| `make -f Makefile.nextpnr.cache clean` → `make -f Makefile.nextpnr.cache timing` | **PASS** |
| 81 MHz timing | **PASS** |
| `python3 PSC-ONE/hardware/rtl/cache/tests/run_cache_regression.py` | **PASS**: 3条件 × 622要求 |
| `git diff --check -- PSC-ONE/hardware/rtl/cache/src/cache_dma_controller.sv` | **PASS** |

CPU basicは`CCACHE_DIR=/tmp/cache-dma-opt/ccache`のみ環境用に指定しました。
元のMakefile／テストを作業用の`hardware/sim`構成にコピーして実行し、既存生成物を保護しました。
最終CPUテスト用RTLと最終ソースは、コメント／空白を除く全トークンが一致することを確認しています。
既存CPUテストはデータ不一致でもcocotbがPASSを出す設定のため、cocotb集計だけでなく53件の実値比較ログも確認しています。

初期の環境起因失敗はccache書込み先とROM相対パスでした。ccacheを/tmpへ指定し、ROMが参照する`../sim/mem/test_program.mem`に合わせて作業構造を修正して、全件を再実行しました。

### 単体回帰の内容・再現

```bash
python3 PSC-ONE/hardware/rtl/cache/tests/run_cache_regression.py   --build /tmp/cache-check
python3 PSC-ONE/hardware/rtl/cache/tests/run_cache_regression.py   --rtl /tmp/cache-dma-opt/baseline/cache_dma_controller.sv   --build /tmp/cache-before-check
```

- TAGLSB=6（4ライン）で固定応答／受付停止・可変応答、TAGLSB=14（1024ライン）で受付停止・可変応答。
- read/write hit、clean/dirty miss、write missの未更新wordのゼロ埋め、dirtyデータ退避。
- burstの値・順序・連続4beat、非ゼロword offsetからのburst要求、hit/missパルス数。
- busy中の次要求、write直後の同一ラインread、要求捕捉後のlive bus変更。
- clear、処理中に届いたclear、reset、INIT中の要求と最終ライン無効化。
- 各設定で600件の決定的ランダムアクセスを含む622要求。
- メモリ要求の順序・アドレス・rw・writeback値を参照モデルと比較し、未受付時の要求・重複要求も検出。

変更前RTLでも同じ単体テストがPASSしました。初回の共通化のみの版では、変更前との10万周期の全外部出力比較も一致しました（最終版はレイテンシを変更しているため周期一致の対象ではありません）。

## ログ

- 最終cache: `/tmp/cache-dma-opt/final-cache.log`
- 最終basic: `/tmp/cache-dma-opt/phase3-basic.log`、実値集計 `/tmp/cache-dma-opt/final/basic-results.log`
- 最終単体回帰: `/tmp/cache-dma-opt/final-unit/`
- 最終timing: `PSC-ONE/hardware/sim/build_nextpnr_cache/nextpnr_cache.log`、`timing_cache.json`、`yosys_cache.log`
- 変更前および各候補の合成結果: `/tmp/cache-dma-opt/{baseline,phase1,phase2,final}/build_nextpnr_cache/`

## 変更ファイルとGit

- 変更: `PSC-ONE/hardware/rtl/cache/src/cache_dma_controller.sv`
- 新規: `cache_regression.sv`、`run_cache_regression.py`、本レポート（このtestsディレクトリ内）
- ソース削除: なし。指定のcleanで合成生成物を再生成。変更前ログは/tmpに保管。
- 残存問題: 今回の検証範囲でFAILなし。要求された全リソース削減目標とFmax目標を達成。
- Git add/commit/push等の状態変更操作は未実施。他作業のIO版・monitor・Makefile等の差分は保持。
