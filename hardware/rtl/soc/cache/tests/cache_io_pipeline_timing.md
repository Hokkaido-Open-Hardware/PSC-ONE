# REG Line Cache request pipeline検証（2026-09-21）

機能検証はPASS。80MHzの単体setup条件は満たすが、**FPGA timing closure全体は未完了**。
nextpnrのhold違反、全SoCの資源超過、Gowin CLIのライセンス接続失敗が残っている。

## 変更内容と原因

変更前はlive requestの仲裁、REGタグ比較、word選択、出力更新が同じFF間に連結していた。
さらにqueued requestの仲裁とREG hit判定がtag RAMのindex選択へ入り、
`sa_req_slot_valid -> u_tag.tag_read`にも深い組合せ経路があった。

- `direct_addr/write/mmio`、`line_cache_direct_match/hit/word`と受付エッジの即応答を削除。
- `S_IDLE`で仲裁結果を既存の`req_addr_b`、`req_word_sel_r`、`req_from_mmu/sa`、
  `req_is_write`、`req_wdata`、`req_write_sel_r`、`cur_tag_r`等へ格納。
- `S_CASHE_START`で登録済み要求だけを使ってREG lookup・出力FF更新を実行。
- REG miss時にだけ`cur_index_r`を更新。tag/data RAMのindexは常にこのFFへ直結。
  同期RAM読出し待ちの`S_LOOKUP_READ`を追加し、`S_LOOKUP_ISSUE`でタグ結果を登録する。
- read responseのデータ選択を状態ごとの共通word muxへ整理。
  出力先は登録済みownerから決定する。

2-entryを維持した。各lineのwordを先に選択し、最後に32bitを選択する。
単体setup推定Fmaxに余裕があり、2-line交互アクセス・LRUの機能検証も維持できたためである。
Tag/Data RAMモジュールは変更していない。REGはshadow copyのままで、独立dirty管理はない。
store、clear、writeback、backing index置換に対する従来のinvalidateを維持する。

要求を選択して格納するエッジを1clk目として、REG応答は2clk目。
同時要求は従来のMMU > SA > CPU順で直列処理し、他portのslot待ち時間は別途必要。
Backing Cache hitは5clkで、既存単体回帰の期待値（受付後4周期）も変更せずPASSした。

## 機能検証

Makeコマンドの実行場所は`PSC-ONE/hardware/sim`。
既存生成物との分離のため`CACHE_BUILD_ROOT=/tmp/cache-io-pipeline/<run>`を指定した。
シミュレータは既存のIcarus設定。

| コマンド | 結果 |
|---|---|
| `make -f Makefile.cache simulate_IDCACHE TEST=1` | PASS、54 REG hits、全件2clk |
| `make -f Makefile.cache simulate_IDCACHE` | 9/9 PASS、FAIL=0、SKIP=0 |
| `make -f Makefile.cache simulate_CACHE` | D-cache 9/9 + I-cache 1/1 PASS、FAIL=0、SKIP=0 |
| `python3 PSC-ONE/hardware/rtl/soc/cache/tests/run_cache_io_regression.py --build /tmp/cache-io-pipeline/standalone-final`（repo root） | PASS、外部read 588 / write 382 / MMIO 3 |
| `git diff --check` | PASS |

単体回帰のREG応答はCPU 31件、SA 26件、MMU 25件、すべて2clk。
同時要求、全word、2-entry/LRU、backing eviction、byte/half/word store、保護領域、
MMIO、clear、writeback、外部DMA後のinvalidate、resetも確認した。
受付後にlive address/dataを変更しても正しく応答するチェックと、REG hit中に
RAM indexが変化しないチェックを追加した。

変更した既存期待値はREG応答の1clk固定から1～2clkへの変更。
削除したdirect専用内部信号の監視は登録済み要求の監視へ統合した。
データ、hit/miss、外部要求数、重複応答、LRU、Backing Cacheの期待値は緩和していない。

## FPGA単体測定

変更前は開始時のHEAD `8e125796947dc607e3d13d9f420e2e6db0b2d0a6`のソースを
`/tmp/cache-io-pipeline/before`へコピーして測定した。
既存の`cache_dma_controller_io_TimingTop`とCSTを変更せず使用。
GW2AR-LV18QN88C8/I7、family GW2A-18C、80MHz、nextpnr既定seed。
nextpnrは`0.11.1-18-gdec04b3b`、YosysはMakefile既定の`./yosys/build/yosys`。

```sh
make -f Makefile.nextpnr.cache.io timing FREQ=80 \
  CACHE_SRC_DIR=/tmp/cache-io-pipeline/before \
  BUILD_DIR=/tmp/cache-io-pipeline/timing-before
make -f Makefile.nextpnr.cache.io timing FREQ=80 \
  BUILD_DIR=/tmp/cache-io-pipeline/timing-after
```

| 配置配線後の単体指標 | 変更前 | 変更後 |
|---|---:|---:|
| LUT4（nextpnr device utilisation） | 7,765 | 4,187 |
| DFF | 1,617 | 1,601 |
| BSRAM | 9 | 9 |
| 最悪setup経路（clk-to-Q・setup含む） | 10.370 ns | 7.795 ns |
| データ経路（clk-to-Q含む、setup除く） | 10.335 ns | 7.760 ns |
| 80MHzの最悪setup slack換算値 | +2.130 ns | +4.705 ns |
| setup推定Fmax | 96.43 MHz | 128.29 MHz |
| hold違反数 | 384 | 384 |
| timingコマンド全体 | FAIL（hold） | FAIL（hold） |

setup slack換算値は`12.5 ns - 最悪setup経路`。
これは単体wrapperの結果であり、実機動作周波数や全SoCのclosureを示す値ではない。
wrapperは既定パラメータを使用し、CPU MMIOアドレス定数は無効になっている。
ユーザー提示のGowin結果（Worst Slack -6.605 ns、Data Delay 18.916 ns）とは
条件・ツールが異なるため、その数値との直接的な前後比較はできていない。

変更後の最悪setup経路は`line_cache_addr[0]`からREG entry 1のfill enableまで。
約19nsの別経路へ移動した結果ではなく、単体の全setup経路の最大値が上記7.795nsである。
2-entry用のfill選択は残るが、80MHzのsetup条件内に収まっている。

追加でYosysの`proc; flatten; opt`後の回路グラフを追跡した。
変更前に存在したslot validからtag read FF・各data/ready FFへの経路、
live MMU/SA/CPU validから各data/ready FFへの経路は、変更後はすべてFF境界で切れていた。
監査スクリプトと結果は`/tmp/cache-io-pipeline/audit_cones.py`、`cone-audit.json`。
この構造確認はSTAの代用ではない。

## 残件・実行障害

1. nextpnrは変更前後ともBRAM端子へのhold違反を384件報告した。
   変更後の表示最短経路は`cur_index_r[5] -> u_tag.tag_mem.0.0.ADB10`。
   `--timing-allow-fail`等で無視してPASSにはしていない。
   holdの原因切り分けと解消、または実装ツールによる再検証が必要。
2. 全SoCも次の既存flowで実行したが、LUT 36,702/20,736（176%）、
   DFF 20,736/15,552（133%）、BSRAM 17/46となり、legal placementに失敗。
   全SoCの配置配線後STAは得られていない。

   ```sh
   make -f Makefile.nextpnr.chip timing FREQ=80 CPU_VERSION=v1 \
     BUILD_DIR=/tmp/cache-io-pipeline/chip-after
   ```

3. インストール済みGowin CLIで同じ単体wrapper・12.5ns制約を測定するTclを用意し、
   実行したが`License verification failed Connection timeout`で開始できなかった。
   サンドボックス外で再実行しても同じ結果。元の約19nsのSTAを生成した
   プロジェクトと利用可能なGowin実行環境での再測定が必要。

## 保存したログ

`/tmp/cache-io-pipeline/`に以下を保持した（削除なし）。

- `test1.log`、`dcache.log`、`cache-all.log`、`standalone-final.log`
- `timing-before/`、`timing-after/`：合成ログ、netlist、配置配線ログ、timing JSON
- `summary.json`：資源・setup delay・推定Fmax・REG応答数
- `cone-before.json`、`cone-after.json`、`cone-audit.json`、`audit_cones.py`
- `chip-after.log`、`chip-after/`：全SoCの合成・配置失敗ログ
- `gowin-before.tcl`、`gowin-after.tcl`、`cache80.sdc`、`gowin-before.log`

変更した既存ファイルはcontroller RTLと2つのテストのみ。本書を新規追加。
CPU RTL、RAM RTL、Makefileの変更および既存ファイルの削除はない。
Gitのadd/commit/push等は実行していない。
