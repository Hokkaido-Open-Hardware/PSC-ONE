# legacy / v2 の status_extra 接続修正

## 原因と修正

CPU legacy（`rtl/soc/cpu`）と v2（`rtl/soc/cpu_v2_experimental`）の
`src/PSC_ONE_RV32_core.v` で NPU の `status_extra` が未接続だった。
両方に32ビットの `sa_status_extra` を宣言し、`u_npu.status_extra` に接続した。
`csr_SA_STATUS` は v1 と同様に `sa_status_extra | {30'b0, sa_busy, sa_done}`
として、拡張ステータスを反映する。

## 作業結果

- 変更: 上記RTL 2ファイル。
- 新規作成: 本レポート。
- 削除: なし。`sim/tmp/` は使用していない。
- 検証: ユーザーの「検証は不要」という指示により実行していない。PASS / FAIL 判定なし。
- 残事項: 実行時の動作・回帰・合成タイミングは未検証。
- Git: add / commit / push などの状態変更操作なし。
- 既存の RV64 RTL 4ファイル、MicroPython サブモジュールの変更と未追跡レポートは保持。
