# PSC-ONE PULP命令拡張仕様

## 1. 目的

PSC-ONEのRV32 CPUへ、PULP/CORE-V ISAのSIMDドット積命令を追加する。

初期実装では、16-bit符号なし整数を2要素ずつ並列乗算して加算する
`cv.dotup.h` のみを実装する。PULP命令群を一括して実装するものではない。

本仕様の対象CPUはRV32であり、汎用レジスタ幅 `XLEN` は32 bitとする。

## 2. 実装対象

| 命令 | 状態 | 内容 |
| --- | --- | --- |
| `cv.dotup.h` | 実装対象 | unsigned 16-bit × 2 laneのドット積 |
| `cv.dotup.sc.h` | 未実装・予約 | `rs2` の下位halfwordを2 laneへ複製 |
| `cv.dotup.sci.h` | 未実装・予約 | 6-bit即値を2 laneへ複製 |
| byte版 | 未実装・予約 | unsigned 8-bit × 4 lane |
| signed/mixed-sign版 | 未実装・予約 | `dotsp`、`dotusp` 系 |
| accumulate版 | 未実装・予約 | `sdotup`、`sdotsp`、`sdotusp` 系 |

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
3. `cv.dotsp.b`：signed 8-bit × 4 lane
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

PSC-ONE固有の決定事項は、初期実装を `cv.dotup.h` のみに限定すること、
33-bit和の下位32 bitを書き戻すこと、および未実装encodingをIllegal Instruction
として扱うことである。