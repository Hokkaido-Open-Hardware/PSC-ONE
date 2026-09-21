# PSC-ONE PULP命令拡張仕様

## 1. 目的

PSC-ONEのRV32 CPUへ、PULP/CORE-V ISAのSIMDドット積命令を追加する。

cpu_v1は `cv.dotup.h`、`cv.dotsp.b` の2命令を実装する。
cpu_v2、legacy CPU、NPUは今回の拡張対象ではない。PULP命令群全体は実装しない。

本仕様の対象CPUはRV32であり、汎用レジスタ幅 `XLEN` は32 bitとする。

## 2. 実装対象

| 命令 | 状態 | 内容 |
| --- | --- | --- |
| `cv.dotup.h` | 実装済み | unsigned 16-bit × 2 laneのドット積 |
| `cv.dotup.sc.h` | 未実装・予約 | `rs2` の下位halfwordを2 laneへ複製 |
| `cv.dotup.sci.h` | 未実装・予約 | 6-bit即値を2 laneへ複製 |
| `cv.dotsp.b` | 実装済み | signed 8-bit × 4 laneのドット積 |
| `cv.sdotsp.b` | 未実装 | 試験実装から撤去。Illegal Instruction |
| その他のbyte版 | 未実装・予約 | `dotup.b`、`dotusp.b` 等 |
| その他のsigned/mixed-sign版 | 未実装・予約 | `.h`、`.sc`、`.sci` 等 |
| その他のaccumulate版 | 未実装・予約 | `sdotup`、`sdotusp`、他の`sdotsp`形式 |

未実装のPULP/CORE-V命令を実行した場合は、通常の未定義命令と同様に
Illegal Instruction例外を発生させる。

## 3. `cv.dotup.h`

### 3.1 アセンブリ形式

```asm
cv.dotup.h rd, rs1, rs2
```

### 3.2 演算

`rs1` と `rs2` をそれぞれ2個のunsigned 16-bit laneとして解釈する。

```text
a0 = unsigned(rs1[15:0])
a1 = unsigned(rs1[31:16])
b0 = unsigned(rs2[15:0])
b1 = unsigned(rs2[31:16])

sum33 = (a0 * b0) + (a1 * b1)
rd    = sum33[31:0]
```

数式では次のとおりである。

```text
X[0] = X[15:0]
X[1] = X[31:16]

rd = (rs1[0] × rs2[0] + rs1[1] × rs2[1]) mod 2^32
```

- 全入力laneを符号なし整数として扱う。
- 各16×16-bit乗算結果は32 bitである。
- 2個の積の加算には33 bitが必要である。
- RV32の書き戻し値は下位32 bitとし、桁あふれは保持しない。
- 飽和演算、丸め、例外フラグ、CSR更新は行わない。
- `rd=x0` の場合は通常のRISC-V命令と同じく結果を破棄する。
- `rd` が `rs1` または `rs2` と同じでもよい。演算には書き戻し前の値を使う。

### 3.3 命令エンコーディング

```text
 31          25 24      20 19      15 14   12 11       7 6          0
+---------------+----------+----------+-------+----------+------------+
| 1000000       | rs2      | rs1      | 000   | rd       | 1111011    |
+---------------+----------+----------+-------+----------+------------+
     funct7                              funct3              opcode
```

| フィールド | bit | 値 |
| --- | ---: | --- |
| `funct7` | 31:25 | `1000000` (`0x40`) |
| `rs2` | 24:20 | 第2入力レジスタ |
| `rs1` | 19:15 | 第1入力レジスタ |
| `funct3` | 14:12 | `000` |
| `rd` | 11:7 | 出力レジスタ |
| `opcode` | 6:0 | `1111011` (`0x7b`, custom-3) |

デコーダ用の定数は次のとおりとする。

```text
MATCH_CV_DOTUP_H = 0x8000007b
MASK_CV_DOTUP_H  = 0xfe00707f

(instruction & MASK_CV_DOTUP_H) == MATCH_CV_DOTUP_H
```

命令語は次式でも生成できる。

```text
instruction = 0x8000007b
            | (rs2 << 20)
            | (rs1 << 15)
            | (rd  << 7)
```

GNU assemblerがニーモニックを認識しない場合は、次の形式で記述できる。

```asm
.insn r 0x7b, 0, 0x40, rd, rs1, rs2
```

## 4. RTL実装要件

### 4.1 デコード

以下をすべて満たす場合だけ `cv.dotup.h` と判定する。

```text
instruction[6:0]   == 7'b1111011
instruction[14:12] == 3'b000
instruction[31:25] == 7'b1000000
```

`custom-3` opcodeだけで判定してはならない。将来のPULP命令追加に備え、
`funct7` と `funct3` を含めて完全に比較する。

### 4.2 データパス

論理的には次の構成とする。

```text
mul_lo  = {16'b0, rs1[15:0]}  * {16'b0, rs2[15:0]}
mul_hi  = {16'b0, rs1[31:16]} * {16'b0, rs2[31:16]}
sum33   = {1'b0, mul_lo} + {1'b0, mul_hi}
result  = sum33[31:0]
```

SystemVerilogでは暗黙のsigned化や式幅の切り詰めを避け、lane、積、加算器の
unsigned属性とbit幅を明示する。

FPGA上で乗算器を2個使用するか、既存の乗算器を時分割するかは
マイクロアーキテクチャに依存する。ただし、どちらの場合も命令の観測可能な
結果は本仕様と一致しなければならない。

### 4.3 パイプライン制御

- `rs1` と `rs2` を読み、`rd` へ1回だけ書き戻す。
- メモリアクセス、分岐、CSRアクセスは発生しない。
- 複数サイクル化する場合、完了まで後続命令と書き戻しを適切にstallする。
- 割り込み・例外からの再開時に、同じ命令の結果を二重に書き戻してはならない。
- `rd == rs1`、`rd == rs2`、`rs1 == rs2` の依存関係を通常のRAW/WAW制御で扱う。

## 5. リファレンスモデル

```c
#include <stdint.h>

static inline uint32_t cv_dotup_h_ref(uint32_t rs1, uint32_t rs2)
{
    uint32_t a0 =  rs1        & 0xffffu;
    uint32_t a1 = (rs1 >> 16) & 0xffffu;
    uint32_t b0 =  rs2        & 0xffffu;
    uint32_t b1 = (rs2 >> 16) & 0xffffu;
    uint64_t sum = (uint64_t)a0 * b0 + (uint64_t)a1 * b1;

    return (uint32_t)sum;
}
```

## 6. 検証項目

### 6.1 基本テストベクタ

| `rs1` | `rs2` | `rd` | 確認内容 |
| --- | --- | --- | --- |
| `0x00000000` | `0x00000000` | `0x00000000` | ゼロ |
| `0x00010002` | `0x00030004` | `0x0000000b` | `2×4 + 1×3` |
| `0xffff0001` | `0x00020003` | `0x00020001` | unsigned境界値 |
| `0x80008000` | `0x00020003` | `0x00028000` | bit 15/31を符号扱いしないこと |
| `0xffffffff` | `0xffffffff` | `0xfffc0002` | 33-bit和の下位32 bit |

### 6.2 必須テスト

- ランダム入力とC/Pythonリファレンスモデルの比較
- `rd=x0`
- `rd=rs1`
- `rd=rs2`
- `rs1=rs2`
- 各入力レジスタが `x0`
- 最大値による33-bit carryの確認
- 直前命令から `rs1`/`rs2` へのRAW forwarding
- 直後命令による `rd` のRAW利用
- stall、割り込み、リセット付近での書き戻し回数
- 同じcustom-3領域にある未実装encodingがIllegal Instructionになること

ランダム試験では、最低でも通常乱数に加えて `0x0000`、`0x0001`、
`0x7fff`、`0x8000`、`0xfffe`、`0xffff` を各laneへ組み合わせる。

## 7. ソフトウェア側の扱い

正式なツールチェーン対応前は `.insn` または `.word` を用いる。
コンパイラ組み込み関数を用意する場合も、Cリファレンス実装をfallbackとして
残し、CPU機能の有無をビルド時に選択できるようにする。

推奨する機能マクロは次のとおりである。

```c
#define PSC_HAS_CV_DOTUP_H 1
```

標準RISC-V拡張ではなく独自拡張であるため、`misa` の標準拡張bitは割り当てない。
必要ならPSC固有のCPU feature CSRまたはビルド時定義で通知する。

## 8. 将来拡張

次段階では、同じSIMD Dot Product群から用途と効果を測定して追加する。

1. `cv.dotsp.h`：signed 16-bit × 2 lane
2. `cv.sdotsp.h`：`rd` をaccumulatorとして使うsigned MAC
3. `cv.dotup.b`：unsigned 8-bit × 4 lane
4. `.sc`：`rs2` の最下位laneを全laneへ複製
5. `.sci`：6-bit即値を全laneへ複製

特にaccumulate版は `rd` を入力と出力の両方に使うため、3入力命令としての
レジスタ読出し、forwarding、hazard制御を別途設計する必要がある。

## 9. 互換性と出典

本命令のニーモニック、演算内容、encodingはOpenHW Groupの
CV32E40P User Manualに記載されたCORE-V SIMD Dot Product仕様に合わせる。

- CORE-V CV32E40P User Manual:  
  <https://docs.openhwgroup.org/projects/cv32e40p-user-manual/en/latest/instruction_set_extensions.html>
- CORE-V software builtin specification:  
  <https://github.com/openhwgroup/core-v-sw/blob/master/specifications/corev-builtin-spec.md>

実装済み命令のみ完全一致で受理し、未実装encodingはIllegal Instructionとする。
結果の切り詰めは下位32 bitへのwraparoundであり、飽和や丸めは行わない。

## 10. Signed byte SIMD（2026-09-21、SDOTSP撤去後）

| 命令 | 状態 | funct7 | funct3 | opcode | MATCH | MASK |
| --- | --- | --- | --- | --- | --- | --- |
| cv.dotsp.b | 実装済み | 0x48 | 1 | 0x7b | 0x9000107b | 0xfe00707f |
| cv.sdotsp.b | 未実装・Illegal Instruction | 0x54 | 1 | 0x7b | 0xa800107b | 0xfe00707f |

```asm
.insn r 0x7b, 1, 0x48, rd, rs1, rs2  # cv.dotsp.b
```

各レジスタの `[8*i +: 8]`（i=0..3）を独立したsigned 8-bit値
（-128..127）として扱う。各laneの積はsigned 16 bit、2積の和は17 bit、
4積の和は18 bitで計算する。全体の範囲は-65024..65536である。

```text
dot = Σ signed8(rs1.byte[i]) * signed8(rs2.byte[i])
rd = sign_extend_32(dot)
```

32×32-bit乗算による代用、byte間のクロスターム、飽和、丸め、CSR更新はない。
rd=rs1、rd=rs2、rs1=rs2、3レジスタ同一でも、入力は書き戻し前の値を使う。
rd=x0の書戻しは破棄し、rs1/rs2=x0は0として扱う。

## 11. cpu_v1の実装と撤去範囲

- `PSC_Types.sv`: ALU制御DOTUP_H=01000、DOTSP_B=01001。
- `Decorder.sv`: opcode/funct3/funct7の完全一致。2形式以外のcustom-3は例外。
- レジスタファイルは従来の2 read port、書込みは既存commitのみ。
  ISSUE/EX、EX/MEMでrs1/rs2と先行書込みが一致すればstall、MEM/WBはforwardする。
  CSR等でMEM/WBの値が使えない場合およびcommit競合ではstallする。
- `Execute.sv`: 既存MUL_WAIT/RESULT_HOLDによって演算待ちと結果保持を行う。
- `Execute_Mul.sv`: DOTSPの4個のsigned 8×8乗算器を保持。
  RUNで4積、BYTE_PAIRで2部分和、BYTE_SUMで4積の和を計算し、各段をFFで分離。
  既存MUL群、DIV/REM、DOTUP.Hの演算と状態遷移は維持する。

SDOT専用だったALU制御、decode、`use_rd`、第3read port（`r_addr3`/`reg_data_3`）、
`issue_accumulator`/`execute_accumulator`とパイプライン保持、`raw_hazard_rd`/
`forward_sel_rd`、旧rd用forwarding/stallを撤去した。Executeから乗算器への累積入力、
`BYTE_ACC`、累積制御・保持レジスタ・32-bit累積加算器も撤去済み。
これらを他命令が利用していないことを確認した。現在の命令に第3入力はない。

Execute受理の立上りをt=0とした、doneまでの遅延（下流stallなし）:

| 命令 | Execute受理→done |
| --- | ---: |
| MUL | 2 cycles |
| cv.dotup.h | 3 cycles |
| cv.dotsp.b | 4 cycles |

fetch、依存stall、メモリ待ち、retirementまでの全時間とは異なる。
乗算器は非パイプライン発行であり、毎サイクル発行できるという意味ではない。

## 12. 撤去後の機能検証

再現手順は `hardware/sim/tests/v1_cv_signed_byte/README.md`。
RTL撤去時はMakefileを維持。その後のユーザー指示により、`Makefile.cpu`のPULP4件を
`TEST_PROGRAM_LIST=pulp`へ移動した。期待値・cocotb登録は変更していない。

| 検証 | 結果 |
| --- | --- |
| Decorder + Execute | PASS: 79,120ベクタ、custom-3全1,024形式（有効2、illegal 1,022） |
| signed byte乗算 | PASS: 全256×256 byte対、乱数4,096、符号境界重点4,096 |
| 既存DOTUP.H単体 | PASS: 境界1,296＋乱数4,096 |
| stall/reset/latency | PASS: 結果受理stall、二重完了なし、2命令×10 reset位相、上記遅延 |
| cv_pulp_test2 C++ | PASS: 5,765比較、ランダム4,096組（通常2,048＋境界重点2,048） |
| CPU alias/RAW/LOAD→DOTSP→STORE | PASS: 遅延なし＋遅延あり4seed、各6,021 SIMD retirements |
| 既存cv_pulp_test1 | PASS: 同じ5条件、各6,933 DOT retirements |
| architectural oracle | PASS: 全commitから独立レジスタ状態を維持し、2sourceと結果を照合 |
| 例外・割込み | PASS: SIMD2命令それぞれの実行中IRQ、全1,022 illegal、各5条件 |
| SDOTSP.Bの命令語 | PASS: funct7=0x54/funct3=1を実行しmcause=2、rd不変、命令後へ復帰 |
| RISC-V v1回帰（MUL/MULH/MULHSU/MULHU/DIV/REM含む） | PASS: 49/49 |
| CPU core v1回帰 | PASS: 30/30 |
| SoC basic v1回帰（リスト分離前） | PASS: 57/57、実PIO値を全件照合 |

この57件は現在のbasic 53件＋pulp 4件と完全に同じ集合である。
分類変更後はmakeの変数展開で重複・欠落がないことと、long/voice/singleの不変を確認した。

```sh
make -f Makefile.cpu simulate_PSC_ONE_TESTS CPU_VERSION=v1 TEST_PROGRAM_LIST=pulp
```

pulpの4件は`cv_pulp_test1`、`cv_pulp_test2`、`nn_pulp_test1`、`nn_pulp_test2`。
いずれも期待値は0x600D600D。SDOTSP専用プログラムの登録はない。

逆アセンブルで `cv_pulp_test2.elf` にDOTSP encodingが28か所、
`nn_pulp_test2.elf` に3か所あることを確認。両ELFともSDOTSP encodingは0か所。
SDOTSPの負テスト命令語は別の`traps.S`で生成して実行する。

不一致はPIO failure signatureまたはRTL/Python assertで検出する。
既存cocotbは`Assert=0`のため、集計表示だけを信用せず、追加済みの
`check_soc_log.py`で実PIO値・NN診断・完了状態を検査し、失敗なら非zero終了する。

## 13. NN性能比較

`hardware/sim/cpp/nn_pulp_test2.cpp` はScalarとDOTSPの2方式だけを比較する。
既存8→4→1モデルの入力、重み、ゼロbiasを保持。Scalarは通常RV32IM、
SIMDは4 byteずつ32-bitロードする。第2層の中間値は最大56なのでint8へ
損失なくpackingでき、この処理も計測内に含む。
一般のint32中間値をint8へ切り詰めてよいという意味ではない。

各方式とも16推論/組、5組測定、各測定前に同じモデル初期化とウォームアップ、
出力クリアを行い、最小値を採用。方式の順序を交互にする。
初期化、比較、PIOは計測外。packing、ロード、ループ、関数呼出しは計測内。
SDOT撤去前後でモデル、繰り返し回数、測定範囲は変更していない。

SDOT撤去前の参考測定はScalar 24,300 cycles / 16推論、DOTSP 6,700 cycles / 16推論、
高速化率3.627倍、削減率72.43%。**撤去後の現在の2方式バイナリでの実測**は次のとおり。

| 項目 | Scalar | cv.dotsp.b |
| --- | ---: | ---: |
| 合計サイクル換算値（16推論） | 24,100 | 7,200 |
| 1推論当たり | 1,506.25 | 450.00 |
| SIMD命令/組 | 0 | 144 |
| SIMD命令/推論 | 0 | 9 |
| 期待値不一致数 | 0 | 0 |
| Scalar比高速化率 | 1.000× | 3.347× |
| Scalar比サイクル削減率 | 0% | 70.12% |

全400要素（16推論×5組×中間4＋最終1）が方式間でbit-exact一致。
中間値[36,56,52,16]、最終値368（0x170）は既存NNの期待値と一致。
期待値不一致・方式間不一致・タイマ異常はすべて0。

前回からDOTSPの命令遅延4 cyclesは不変。逆アセンブル上もカーネルは40命令のまま、
ロード・演算・ループの列は不変だが、関数は0x914→0x1a4、入力は0xcd8→0x954へ移動。
2方式化によるコード・データ配置と測定順序の変化があり、前回バイナリの数値を
現在の実測値に置き換えて扱ってはいけない。
同じ現在の2方式バイナリを保存済みSDOT撤去前RTLでも実行し、
24,100 / 7,200 cycles、全出力一致を再確認した。したがって、この測定条件では
SDOT回路撤去自体によるサイクル増加はない。前回との差はバイナリ/実行配置側の変化であり、
キャッシュやfetchの寄与の内訳までは分離測定していない。

PIO: EE40=測定設定、A001/A002=Scalar/DOTSPのサイクル、A004=方式間不一致、
A005=Scalar/DOTSPの期待値不一致2値、A006=計測エラー。
EE20/EE30=各方式の中間4値と最終値。旧A003/EE31の出力は廃止した。
EE01の後に成功600D600Dまたは失敗BAD0BAD0を出力する。

シミュレーションは100 MHz、MMIOタイマは1 tick=100 clocks=1 us。
経過tick×100をサイクル換算値とするため、量子化誤差は1組あたり100 cycles未満、
1推論平均では6.25 cycles未満。共通のタイマ読出し等のオーバーヘッドは差し引かない。

> 過去の試験実装：`cv.sdotsp.b` は3.857倍を確認したが、第3read portによる
> LUT/MUX増加に対して `cv.dotsp.b` からの追加性能が約6%に留まったため、正式対応から除外した。

## 14. SDOTSP撤去前後の合成・配置配線

Yosys 0.68+136 (c30457480)、sv2v 0.0.13、nextpnr 0.11.1-18-gdec04b3b、
Tang Nano 20K / GW2AR-LV18QN88C8/I7、family GW2A-18C、制約80 MHz。
前後ともseed=0x3141592653589793、heap/default、同じCSTとCPU評価トップ。
このトップはNPUを含まず、SoC全体のFmaxではない。

既存`Makefile.nextpnr.cpu`を使用。既存`PSC_CPU_TimingTop.sv`には
`.timer_irq_ext(timer_irq_ext)`の未宣言/未接続netがあるため、前回と同じbuild内コピー
（`.timer_irq_ext(irq_ext)`に補正済み）を使用した。元ラッパーと合成用Makefileは変更していない。

PNR JSONのsettings全33項目が前回と一致することを確認した。

| 資源（nextpnr pack後） | SDOTSPあり | SDOTSP撤去後 | 削減量 |
| --- | ---: | ---: | ---: |
| LUT4 | 10,045 | 7,845 | 2,200 |
| FF | 4,171 | 4,086 | 85 |
| MULT9X9 | 4 | 4 | 0 |
| ALU | 730 | 696 | 34 |
| MUX5/6/7/8合計 | 2,883 | 1,464 | 1,419 |
| 配線後Fmax | 110.23 MHz | 120.09 MHz | +9.86 MHz改善 |

MUX内訳はLUT5: 2,080→1,158、LUT6: 541→192、LUT7: 192→84、LUT8: 70→30。
第3read portと付随するhazard/forwarding、累積段をまとめて撤去した結果、
MUX合計49.22%、LUT4 21.90%減少。これは撤去全体の差分であり、
第3read port単独だけを分離した合成差分ではない。

**80 MHz制約をPASS。** Fmaxは8.95%改善した。
DOTSPの4個のsigned 8×8乗算は全てMULT9X9へ推論され、LUT乗算器への置換はない。
既存MULT18X18=2、MULT36X36=1も不変。
`check -assert`は0問題、`scc -expect 0`は0 loop、latch検出0。
既存の配列→FF展開警告、ABC9のcarry関連メッセージは残る。

証跡: `build/cv-dotsp-only/timing/`（撤去後）、
`build/cv-signed-byte/timing-after-irq/`（撤去前）、
撤去直前のRTLは`build/cv-dotsp-only/before-src/`。全てGit除外の生成物。

以前試行したSoC全体（CPU v1、NPU v1）はbyte SIMD追加前からTang Nano 20K容量を
超えており配置不可だった。今回のCPU評価値をSoC全体の80 MHz達成とは扱わない。
SoC収容問題の解消、他CPUやNPU・周辺回路の変更は今回の範囲外である。

## 15. 現行PULP拡張の費用対効果

現行NNのScalar 24,100→DOTSP 7,200 cycles / 16推論は、16,900 cycles削減、
3.347倍、70.12%削減に相当する。DOTSPは4個のsigned byte積を1命令で処理し、
元のbyte列を32-bitロードできるため、halfword展開を必要としない。
CPU内で乗算・部分和・総和を複数段処理するので、4倍の高速化を保証する命令ではない。
ロード、2個のドット積の累積ADD、中間値packing、ループ等のコストは残る。

以下はDOTUP.H対応済みCPUへのDOTSP.B追加の増分であり、PULPなしCPUとの比較ではない。
前後でPNR settings全33項目の一致を確認した。

| 資源 | DOTUP.Hのみ | 現行DOTUP.H＋DOTSP.B | 増分 |
| --- | ---: | ---: | ---: |
| LUT4 | 7,682 | 7,845 | +163（2.12%） |
| FF | 3,986 | 4,086 | +100 |
| MULT9X9 | 0 | 4 | +4 |
| ALU | 638 | 696 | +58 |
| MUX5/6/7/8合計 | 1,318 | 1,464 | +146 |
| 配線後Fmax | 117.91 MHz | 120.09 MHz | +2.18 MHz |

このNNでは少量の追加LUTと4個のDSPによって大きなサイクル削減を得た。
SDOTSP試験実装の撤去によって2,200 LUT4と1,419 MUXを回収し、
DOTSPの機能と命令遅延は維持した。性能はモデルとメモリ配置に依存し、
上記Fmaxは同一seedのCPU評価トップの結果である。
