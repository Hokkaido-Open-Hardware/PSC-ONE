# nextpnr測定結果

全構成で同じ既存Controller wrapper/CST、GW2AR-LV18QN88C8/I7、GW2A-18C、
81 MHz制約、seed 1/2/3。`--timing-allow-fail`は違反時にも測定値を残すために指定。
合否は81 MHz制約に対して別途判定した。今回12 runは全てPASS。
SoC全体ではなく、pseudo stimulusを含むNPU Controller単体の配置配線結果。

| 構成 | LUT4 (pnr, seed 1) | FF | MULT9X9 | MUX | ALU (pnr) | Fmax中央値 MHz | 3 seed範囲 MHz |
|---|---:|---:|---:|---:|---:|---:|---|
| v1 | 2769 | 1679 | 7 | 265 | 820 | 202.72 | 192.38–214.13 |
| v2_4 | 3482 | 1677 | 3 | 841 | 886 | 129.43 | 117.76–129.85 |
| v2_8 | 3473 | 1740 | 3 | 340 | 952 | 131.49 | 126.55–133.28 |
| v2_16 | 8504 | 1867 | 3 | 4446 | 1076 | 120.54 | 117.65–120.77 |

LUT4はnextpnrのpacked utilization値。ALU/MUXは別resource種別の報告であり、
単純合計してFPGA面積とはしない。FF/MULT/MUXも同じnextpnr reportから取得。
LUT以外の表中resource数は3 seedで同一。MULT18X18/ALU54D/BSRAMは全て0。
LUT4の3 seed範囲: v1=2769–2771、v2_4=3477–3482、v2_8=3465–3473、v2_16=8499–8504。
MULT9X9はプリミティブ数であり物理DSP macroの占有ブロック数とは異なる。
v1の7個中4個がINT8演算用、残り3個はアドレス用。v2の演算部は0個。

| 構成 | Yosys LUT1–4計 | FF | MUX | ALU | 演算部のみ MULT9X9 |
|---|---:|---:|---:|---:|---:|
| v1 | 2145 | 1679 | 265 | 762 | 4 |
| v2_4 | 2905 | 1677 | 841 | 823 | 0 |
| v2_8 | 2926 | 1740 | 340 | 884 | 0 |
| v2_16 | 7935 | 1867 | 4446 | 1002 | 0 |

nextpnrはpacking時にALU等を変換するためYosysのLUT/ALU数と異なる。

| 構成 | seed 1 Fmax | seed 2 Fmax | seed 3 Fmax | 最遅seedのlogic + routing ns |
|---|---:|---:|---:|---|
| v1 | 202.72 | 214.13 | 192.38 | 1.76 + 3.44 |
| v2_4 | 129.43 | 129.85 | 117.76 | 4.00 + 4.49 |
| v2_8 | 131.49 | 133.28 | 126.55 | 3.94 + 3.96 |
| v2_16 | 117.65 | 120.77 | 120.54 | 3.99 + 4.51 |

v1のcritical pathはController制御からwriteback register enable等へ至る経路。
v2はPoT laneのoperand/phase/shift選択と符号反転を経てWBへ至る経路が律速。
厳密な始点・終点はJSON、各段の論理/配線遅延は `critical_*_seed*.txt` に保存。

| X × Y / memory delay | v1 cycles | v2 4 cycles | v2 8 cycles | v2 16 cycles |
|---|---:|---:|---:|---:|
| 4 × 4 / 1 (signed=0) | 214 | 262 | 214 | 190 |
| 4 × 4 / 1 (signed=1) | 214 | 262 | 214 | 190 |
| 8 × 4 / 1 (signed=1) | 394 | 490 | 394 | 346 |
| 4 × 8 / 5 (signed=0) | 1280 | 1470 | 1280 | 1181 |
| 12 × 20 / 5 (signed=0) | 18624 | 22189 | 18624 | 16794 |
| 20 × 12 / 5 (signed=1) | 10509 | 12669 | 10509 | 9429 |

8 laneで2clk/weightのissue throughputとController cycle数をv1まで回復。
16 laneは同一81 MHzで約8～12%のController cycle削減に留まり、転送と制御が残る。
各設計のFmaxで動かす仮定では、代表4×4 (delay=1) の実行時間は次のとおり。

| 構成 | cycles / Fmax中央値 (µs) | 81 MHzでの時間 (µs) |
|---|---:|---:|
| v1 | 1.056 | 2.642 |
| v2_4 | 2.024 | 3.235 |
| v2_8 | 1.628 | 2.642 |
| v2_16 | 1.576 | 2.346 |

結論: 本実装・本mapping条件ではDSPを4個削減できる一方、LUT/MUX増加と
Fmax低下が大きい。DSPの不足がないTang Nano 20K用途でv1を置き換える優位性は確認できない。
DSPを他用途へ確保し、81 MHz固定で使う場合は8 laneが候補だが、面積は増加する。
16 laneはMUX増加が特に大きく、今回の速度改善に対して費用が大きい。
汎用barrel shifterはないが、固定8択selectもmapping後のコストは無視できない。
最大Fmaxは単体wrapperの推定値であり、SoC統合後や実機の保証周波数ではない。
