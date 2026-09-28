# TFLite 自動 backend 選択：報告時点の結果

2026-09-29。ユーザーの報告依頼時点で確定した結果を記録する。
実装済みだが、16×16 の選択を追加した最終バイナリの RTL 性能再検証は未完了。

## 32×32 の結論

**M=K=N=32 は NPU タイル 32 が PULP より 19.7% 短時間（約 1.25 倍速）。**
CPU v1 / legacy NPU、100 MHz、実 PSC-OS を起動した RTL シミュレーション。
同一モデル・入力・バイナリ・SDRAM/cache 条件で各 backend をウォームアップし、
実行順を回して３回測定。診断と細分化プロファイルは計測中無効。
以下は auto NPU16 追加前のバイナリの確定値で、３回とも一致した。

| backend | 演算時間 ms | 推論全体 ms | NPU 起動回数 |
|---|---:|---:|---:|
| CPU | 67.951 | 67.970 | 0 |
| PULP | 32.670 | 32.687 | 0 |
| NPU tile 4（既存既定値） | 168.765 | 168.791 | 512 |
| NPU tile 16 | 38.848 | 38.879 | 8 |
| NPU tile 32 | 26.220 | 26.247 | 1 |
| NPU tile 64 | 70.644 | 70.684 | 1 |
| auto → NPU tile 32 | 26.217 | 26.247 | 1 |

整形、ゼロ埋め、OS syscall、入出力コピー、起動・完了待ち、量子化処理を含む。
演算時間と推論全体は別 invoke で測定した。全モードの全出力が一致した。
`SA_MAT_MAX=64` は最大許容値であり、32×32 に最適なタイルは 32。
64 タイルではパディング・内部演算・結果コピーが増え、遅くなる。

## 実装した選択と CLI

- `tflite_run MODEL.TFL [cpu|npu|pulp|auto]`。省略時 CPU、明示 NPU の既定 tile 4 は維持。
- auto は M=K=N=16 または 32 で NPU を１回起動。それ以外は既存 PULP FC を使用し、浅い K や PULP 無効ビルドでは CPU にフォールバック。
- 単一サンプルの 16 入力・16 出力 FC は M=1 であり、16×16 行列積と区別。
- 16×16 は 64 上限の OS 構成で NPU16=6.069 ms、PULP=6.843 ms（各２サンプル）だったため追加。旧構成では逆の結果であり、最終構成の再測定が必要。
- backend を試して選択する処理は推論内に追加していない。形状による一定量の条件分岐。推論中の動的メモリ確保も追加していない。
- `tflite_diag off` で形状・選択理由等の診断を停止。`tflite_bench MODEL.TFL [quick]` で比較。
- 既存 CPU が非対応の演算は従来のエラーを維持。対応済み FC の加速非対応条件を CPU にフォールバックする。

## 検証

| 項目 | 結果 |
|---|---|
| ホスト ASan/UBSan、10 形状、全４モード、tile 4/8/12/16/32/64 | PASS |
| ゼロポイント補正、bias、requantize、clamp、TFLM oracle、混合２層 | PASS（最終 16/32 選択を含む） |
| 端数、未整列、保護ページ、PULP 無効、invoke 中の allocation 禁止 | PASS |
| FAT32/パーサ/CLI/ドライバ、通常 benchmark と quick benchmark | PASS（最終表示調整を含む再実行も完了） |
| 実 RTL の 32×32、16×64×16、NPU64 の５段階一致 | PASS（auto NPU16 追加前） |
| PULP 無効の実 RTL 32×32、命令エンコード監査 | PASS。PULP 命令なし、pulp→CPU、auto→NPU32 |
| 実 OS RTL の 32×32：９設定×３回、全出力一致 | PASS（auto NPU16 追加前） |
| 最終二形状選択バイナリの OS RTL 再測定 | 実行中・未完了 |
| 実機、cold cache、他 CPU/NPU 構成、全リポジトリ regression/合成 | 未実施 |

ホストのエミュレーション／NPU mock の時間を実性能として扱っていない。
ベアメタル RTL の値も OS のコピー／syscall を含まないため別表にした。
初回の広範囲 RTL sweep は測定用の全体期限で TIMEOUT。完全な行のみ履歴として保存し、
32×32 と 16×64×16 は分割して再実行・PASS。初回 sweep 全体を PASS とは扱わない。

64 タイルの実 OS 検証で、INT32 結果の 16 KiB に対して１ページしかマップされず
ページフォルトになる問題を発見した。結果領域を４ページの supervisor mapping に直し、
修正後の 64 タイルで出力一致を確認済み。CPU/NPU RTL は変更していない。

## 成果物と残件

変更・新規ファイルの一覧と手順は [AUTO.md](AUTO.md)、サンプルとバイナリ hash は
[auto_results.json](../../../tests/tflite/auto_results.json) に保存。
主な変更は runtime/adapter/検証器、CLI/API/help、共有 `sa_limits.h`、OS の SA mapping、
Makefile のヘッダ依存、テストと文書。削除ファイルはない。

残件は最終バイナリでの OS 性能再確認。測定ログは
`/tmp/psc-auto-os-selected/uart.log`、完了時の集計は同ディレクトリの `os_timing.json`。
全タイルの追加較正も `/tmp/psc-auto-os-rtl/` で継続している。
このレポートと JSON は報告時点のスナップショットで、自動更新されない。

Git の add/commit/push は実施していない。作業前から dirty だった
`PSC-ONE/toolchain/riscv-gnu-toolchain` は変更していない。
