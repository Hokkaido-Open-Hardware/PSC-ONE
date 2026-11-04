# RV64 NPU status_extra 接続漏れの調査

## 修正前の原因

ユーザー提示ログでは、Verilator が PINMISSING 警告を致命的として扱い、シミュレータ生成前に停止している。add_test1 の実行結果による失敗ではない。

- `../rtl/soc/npu/src/PSC_NPU_Controller.v:53` に `output wire [31:0] status_extra` が存在する。
- `../rtl/soc/cpu_rv64/src/PSC_ONE_RV64_core.v:347` の `u_npu` にそのポート接続がない。
- RV64 の `csr_SA_STATUS` は310行目で busy/done のみを反映している。
- v1 は `sa_status_extra` を接続し、CSR に OR している。v2 も接続が欠落しているが、今回v2のビルド再現は未実施。

## 実施した修正

ユーザーの修正指示を受け、RV64 に32ビットの `sa_status_extra` を宣言し、`u_npu.status_extra` を接続した。CSR は `{32'b0, sa_status_extra} | {62'b0, sa_busy, sa_done}` とし、v1 と同様に拡張ステータスを反映する。LPU/無効構成ではコントローラが status_extra をゼロにしているため、この接続で既存の busy/done 値は維持される。

## 作業・検証状況

- ソースのポート宣言、インスタンス、v1との比較を実施し、提示ログと一致する原因を確認。
- 変更ファイル: `../rtl/soc/cpu_rv64/src/PSC_ONE_RV64_core.v`、本レポート。v1/v2、Makefileは未変更。
- 下記の RV64 add_test1 は PASS（PASS=1 FAIL=0、終了コード0）。PINMISSING 警告の解消も確認。
- 初回実行は ccache の書き込み制限で FAIL。権限付きで同じコマンドを再実行して PASS。
- `git diff --check -- ../rtl/soc/cpu_rv64/src/PSC_ONE_RV64_core.v` は PASS。
- 全CPUリグレッション・FPGAタイミング検証は未実施。今回確認した範囲はRV64 SoCのビルドとadd_test1であり、NPU有効構成での拡張ステータス動作は未検証。
- 削除ファイルなし。テスト生成物とログは保持。作業用の `sim/tmp/` は使用していない。
- Git変更操作なし。開始時から RV64 の Csr.sv、PSC_InstructionUnit.sv、PSC_RV64_core.sv、MicroPythonサブモジュールに変更があり、リポジトリ直下 report/ に未追跡レポートがある。

```bash
make -f Makefile.cpu simulate_PSC_ONE_TESTS CPU_VERSION=rv64 \
  TEST_PROGRAM_LIST=single \
  PSCONE_SINGLE_TEST=add_test1:RV32_chip_test:./mem/add_test1.mem:0xff00ff0b \
  TEST_BUILD_ROOT=/tmp/psc-rv64-status-extra-validation
```

ログ:
- `/tmp/psc-rv64-status-extra-add-test1.log`（初回の環境制限）
- `/tmp/psc-rv64-status-extra-add-test1-retry.log`（PASS）
- `log/test_result_20261104_202629.log`（テスト結果）
