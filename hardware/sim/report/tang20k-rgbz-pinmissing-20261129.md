# Tang 20K の RGBZ 端子接続

`make -f Makefile.cpu` の既定構成で、Verilator が SoC インスタンスの RGBZ 端子2本に対して `PINMISSING` を報告し、シミュレータ生成時に停止した。

Tang 20K は RGBZ を無効にしているため、`../rtl/tang20k/top/PSC_ONE_Chip.v` で出力 `rgbz_start` を明示的に開放し、入力 `rgbz_status` をゼロに固定した。

修正後はシミュレータが起動し、`add_test1` が通過した。`lpu_test1` は期待値 `0x0000beef` に対して `0xdead0003` で失敗した。ユーザーが検証を引き継ぐため途中で停止し、この不一致の原因と全件の結果は未確認。
