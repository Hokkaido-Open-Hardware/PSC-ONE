# cache_dma_controller_io 単体検証

[PSC-ONE](../../../../../README.md) · [Documentation](../../../../../docs/README.md)

Icarus Verilogで、外部メモリ／MMIOモデルと参照メモリを使って検証します。
既存のcocotbテストやTimingTopは変更しません。

```bash
python3 PSC-ONE/hardware/rtl/soc/cache/tests/run_cache_io_regression.py
# 変更前のRTLに対しても同じテストを実行可能
python3 PSC-ONE/hardware/rtl/soc/cache/tests/run_cache_io_regression.py \
  --rtl /path/to/before.sv --build /tmp/cache-before
```

`--build`省略時は新しい一時ディレクトリを作成します。ログ・生成物は削除しません。

## 検証内容

- CPU、SA、MMUのread hit／miss、CPU／SAのwrite hit／miss。
- 全16 byte位置と全8 storeサイズ符号。SB、SHと既存のdefault→SW処理。
- dirty victim退避、全ラインwrite-back、cleanラインの再write-back抑制。
- cache clear／reset後の無効化、reset時の外部出力。
- MMIOのread／write要求と返却データ。
- CPUの書込み保護、SAの既存の保護領域動作（missは無変更、hitは更新）。
- 3ポート同時要求のMMU→SA→CPU優先処理。
- 外部メモリの受付停止、応答遅延、write-back中の受付停止。
- 決定的な乱数列による300トランザクションと、最後のwrite-back／再読出し。

比較を短時間で再現するため、単体テストのcacheは4ライン（`TAGLSB=6`）です。
既存のcache／SoCテストと合成測定は、それぞれ既存のパラメータを使用します。

## レイテンシの定義

validを最初にサンプリングした立上りをcycle 0とし、対応するreadyが
観測される立上りまでのクロック周期数を表示します。validはその前の立下りで
assertするため、その立下りから測る場合は表示値に0.5周期を加えます。
競合のない単独要求が基本です。

最初の測定群ではメモリモデルの`response_delay=3`を使用します。
DUTが`mem_valid`を出した立上りから、その応答をDUTが取り込む立上りまでは
5周期です。MMIOモデルも要求出力から応答取込みまで5周期です。
missの絶対値はこのモデル条件に依存し、実SDRAM全般の固定値ではありません。
メモリ受付停止を含む測定と、応答遅延を変える乱数検証は別に実行します。
