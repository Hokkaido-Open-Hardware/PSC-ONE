<p align="center">
  <a href="https://github.com/QPSC-Design/PSC-ONE">
    <img src="images/PSC-ONE_Logo.png" width="640" alt="PSC-ONE logo">
  </a>
</p>

# PSC-ONE MMU

[ドキュメント一覧](README.md) · [OS](psc_os.md) · [API](psc_os_api.md) · [ハードウェア](../hardware/README.md)

PSC-ONEのMMUは、32-bit仮想アドレスを2段のページテーブルで変換します。
本書はリポジトリ内の実装を説明します。Sv32の全機能への準拠を保証する仕様書ではありません。
特にU/SとA/Dの検査が省略されているため、現状のMMUを信頼できないプログラムの隔離境界として扱うことはできません。

<!-- contents -->
- [実装と対象CPU](#実装と対象cpu)
- [変換の有効条件とSATP](#変換の有効条件とsatp)
- [仮想アドレスとPTE](#仮想アドレスとpte)
- [ページテーブルウォーク](#ページテーブルウォーク)
- [インターフェースと完了通知](#インターフェースと完了通知)
- [PTEキャッシュとSFENCE.VMA](#pteキャッシュとsfencevma)
- [PSC-OSのページ管理](#psc-osのページ管理)
- [実装上の制限](#実装上の制限)
- [検証手順](#検証手順)
<!-- /contents -->

## 実装と対象CPU

| CPU | 実装 | 構成 |
| --- | --- | --- |
| legacy | [MMU.v](../hardware/rtl/soc/cpu/src/MMU.v) | Verilog版の2段ウォーカと各段1エントリのPTEキャッシュ |
| v1 | [MMU.sv](../hardware/rtl/soc/cpu_v1/src/MMU.sv) | 安定版CPUの命令・データ変換 |
| v2 | [MMU.sv](../hardware/rtl/soc/cpu_v2_experimental/src/MMU.sv) | 文書作成時点でv1と同一内容 |

以下の信号・状態名はv1/v2を基準にします。legacyでは制御タイミングと信号構成が異なるため、
同じサイクル数やハンドシェイクを仮定しないでください。

v1は[FetchUnit](../hardware/rtl/soc/cpu_v1/src/PSC_RV32_FetchUnit.sv)に命令用MMU、
[InstructionEngine](../hardware/rtl/soc/cpu_v1/src/PSC_RV32_InstructionEngine.sv)にデータ用MMUを持ちます。
命令側はX、LOADはR、STOREはWを要求します。ページテーブルの読出しには物理アドレスを使います。

## 変換の有効条件とSATP

| 条件 | 動作 |
| --- | --- |
| `satp[31] = 0` | Bare：`paddr = vaddr` |
| `priv_mode = 2'b11`（M-mode） | SATPにかかわらず変換をバイパス |
| `satp[31] = 1`、U/S-mode | ページテーブルを使って変換 |

`mode_sv32` 出力は `satp[31]` そのものであり、M-modeで実際に変換したことを意味しません。

| SATPフィールド | bit | このMMUでの扱い |
| --- | --- | --- |
| MODE | 31 | 0=Bare、1=Sv32経路 |
| ASID | 30:22 | PTEキャッシュのキーには使わない |
| PPN | 21:0 | ルートページテーブルの物理ページ番号 |

CSR側でSATPを保持しても、ASID別の変換キャッシュを提供するわけではありません。
ルートは `satp[21:0] << 12` です。MMU内には34-bitのアドレス信号がありますが、
外部 `paddr` とPTE読出し用 `mem_addr` は下位32 bitだけを出力します。
4 GiB以上の物理アドレスを別領域として利用する構成は対象外です。

## 仮想アドレスとPTE

```text
VA[31:22] = VPN[1]  （上位テーブルのindex、10 bit）
VA[21:12] = VPN[0]  （下位テーブルのindex、10 bit）
VA[11:0]  = offset  （ページ内offset、12 bit）
```

各テーブルは1,024個の32-bit PTEからなり、4 KiBを占有します。

| PTEフィールド | bit | 実装での利用 |
| --- | --- | --- |
| PPN | 31:10 | 下位テーブルまたはleafの物理ページ番号 |
| RSW | 9:8 | 変換・権限判定では参照しない |
| D / A | 7 / 6 | 検査・自動更新なし |
| G | 5 | globalエントリとしての特別扱いなし |
| U | 4 | U/Sのアクセス制限には使わない |
| X / W / R | 3 / 2 / 1 | 要求アクセスの許可判定 |
| V | 0 | 有効判定 |

`V=0` または `W=1,R=0` は不正PTEです。`R=1` または `X=1` ならleaf、
それ以外の有効PTEは次段テーブルへの参照として扱います。

## ページテーブルウォーク

1. 上位PTEを `root + VPN[1] * 4` から読みます。キャッシュhit時は読出しを省略します。
2. 上位PTEが不正ならpage faultにします。
3. 上位PTEがleafなら4 MiBページです。`PTE[19:10]`（PPN[0]）が0であることとアクセス許可を確認します。
4. 非leafなら `PTE[31:10] << 12` を下位テーブルのベースとし、`VPN[0] * 4` を加えて読みます。
5. 下位PTEは有効なleafで、要求したR/W/Xを満たす必要があります。成功時は4 KiBページとして変換します。

```text
4 KiB: PA = (leaf.PPN << 12) | VA[11:0]
4 MiB: PA = (leaf.PPN[1] << 22) | VA[21:0]
外部出力: PA[31:0]
```

例としてVA `0x00400014` をPA `0x00215014` へ変換する場合、
VPN[1]=1、VPN[0]=0、offset=`0x014`、leafのPPN=`0x215`です。
この非恒等マッピングは既存の[fetch回帰](../hardware/sim/tests/fetch_sv32/README.md)でも使用します。

## インターフェースと完了通知

| 信号 | 役割 |
| --- | --- |
| `MMU_enb` | idleから変換を開始 |
| `vaddr`, `satp`, `priv_mode`, `access_r/w/x` | 変換要求の内容 |
| `mem_req_ready` | PTE読出し要求を出せることを示す |
| `mem_addr`, `mem_valid` | PTEの物理アドレスと1サイクルの要求pulse |
| `mem_ready`, `mem_rdata` | PTE応答。データを採用するのはready時のみ |
| `paddr`, `page_fault`, `mmu_done` | 結果、fault、1サイクルの完了pulse |
| `cpu_state_done` | 直前のfault状態をクリア |
| `sfence_vma` | PTEキャッシュ無効化要求 |

要求一式を内部で一括ラッチする設計ではないため、呼出し側は変換中の入力を保持します。
主な遷移は `S_IDLE → S_START → S_L1_REQ/WAIT/CHECK → S_L0_REQ/WAIT/CHECK → S_DONE`。
Bare、キャッシュhit、上位leafでは一部を省略します。応答待ちがあるため固定レイテンシではありません。

fault時も `mmu_done` が出ます。`paddr` 単独を有効な変換結果として使用せず、
`page_fault` と合わせて判定します。MMU自身はtrap CSRを書かず、上位CPUへfaultを通知します。
v1の[CPUトップ](../hardware/rtl/soc/cpu_v1/src/PSC_RV32_core.sv)は、命令page fault=12、
LOAD page fault=13、STORE page fault=15を選びます。アラインメント例外は別に判定します。

[Fetch.sv](../hardware/rtl/soc/cpu_v1/src/Fetch.sv)は変換完了時のPAを保持し、
命令メモリのstall中もその値を使います。命令FIFOへ渡すPCはVAのままです。
バースト時の32-byte境界への整列もPAに対して行います。

## PTEキャッシュとSFENCE.VMA

汎用の多エントリTLBではなく、上位・下位PTEを各1エントリ保持します。

- 上位キー：ルートPPNとVPN[1]。
- 下位キー：上位cache hitに加えてVPN[0]。
- 新しい上位PTEを読み込むと下位エントリを無効化。
- hit後もPTEの有効性とR/W/Xを確認。
- resetと `sfence_vma` で両エントリを無効化。

v1/v2では `sfence_vma` をラッチし、idleで無効化を処理します。
VAやASIDを受け取るポートはなく、選択的な無効化は実装していません。
同じルートのPTEを書き換えた場合、書込みだけでキャッシュは更新されません。

PSC-OSの[ELFアドレス空間切替](../software/os/src/kernel/kernel_elf.c)は、
`fence rw,rw → sfence.vma → csrw satp → sfence.vma → fence.i` を使います。
PTEキャッシュの無効化と、実行コードのD/Iキャッシュ同期は別の処理です。
コピーしたコードの公開には[kernel.c](../software/os/src/kernel/kernel.c)の `sync_user_code()` を使います。

## PSC-OSのページ管理

`map_page()` はVA/PAの4 KiB整列を確認し、必要なら下位テーブルを確保してPTEを書きます。
`alloc_pages()` はゼロ初期化付きの単方向アロケータで、一般的なページ解放APIはありません。

通常のユーザー領域とELF実行時の領域は[OS文書](psc_os.md)を参照してください。
ELFではU/R/W/XおよびA/Dを設定しますが、ソフトウェアがbitを設定していることと、
ハードウェアが全bitを強制することは異なります。

## 実装上の制限

- U/S権限チェックなし。U=0のカーネルマッピングでもU-modeからアクセスできる可能性があります。
- A/Dの検査・更新なし。未設定bitを理由とするfaultも生成しません。
- SUM/MXR/MPRVを入力に持たず、これらに基づく権限制御・実効特権切替は行いません。
- ASIDタグ、globalページの最適化、選択的flushなし。
- 物理アドレス出力は32 bit。上位bitの非ゼロをfaultとして検出する処理はありません。
- PTE読出しのbus-error入力やタイムアウトはなく、応答が来なければ待ち続けます。

OS側のELF検査やポインタ検査はこれらのハードウェア制限を解消しません。
詳細は[ELFの保護上の制限](../software/os/tests/elf/README.md#remaining-protection-limitation)を参照してください。

## 検証手順

リポジトリルートから、Icarus Verilogを使う既存のfetch/MMU回帰を実行できます。

```sh
python3 PSC-ONE/hardware/sim/tests/fetch_sv32/run.py --build /tmp/psc-fetch-sv32
```

Bare、M-mode、U/Sの変換、4 KiB/4 MiB、ページ境界、PTE応答遅延、命令メモリstall、
PAによる命令取得とVAのPC保持を検証します。U/Sの「変換成功」はU/S隔離の検証ではありません。
OSを含む非恒等マッピング・RX/NX・未マップfaultの試験は[ELF回帰](../software/os/tests/elf/README.md)を参照してください。
