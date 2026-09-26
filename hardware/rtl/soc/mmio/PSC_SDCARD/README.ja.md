# PSC_SDCard

[PSC-ONE](../../../../../README.md) · [Documentation](../../../../../docs/README.md)

[English](README.md)

対象は [PSC_SDCard.sv](src/PSC_SDCard.sv) と [SPIエンジン](src/PSC_SDCard_SPI.sv)です。
制御bitは一度に1つだけ指定します。bit 7はローカルerrorのみをクリアし、
状態機械の `state_error` を含むエラー全体の解除を保証しません。
CRCはRTLで受信し、[C側の例](cpp/sdcard_api.c)で検証します。

<!-- contents -->
- [概要 (Overview)](#概要-overview)
- [特徴 (Features)](#特徴-features)
- [メモリマップ (MMIO)](#メモリマップ-mmio)
- [制御レジスタ (SD_IF_CTRL)](#制御レジスタ-sd_if_ctrl)
- [使用手順](#使用手順)
- [内部構成 (Internal Architecture)](#内部構成-internal-architecture)
- [初期化シーケンス (Initialization Sequence)](#初期化シーケンス-initialization-sequence)
- [読み出しシーケンス (Read Sequence)](#読み出しシーケンス-read-sequence)
- [FIFO の動作 (FIFO Behavior)](#fifo-の動作-fifo-behavior)
- [Busy 判定 (Busy Definition)](#busy-判定-busy-definition)
- [制限事項 (Limitations)](#制限事項-limitations)
- [今後の拡張予定 (Future Improvements)](#今後の拡張予定-future-improvements)
- [実装上の注意](#実装上の注意)
<!-- /contents -->

## 概要 (Overview)

PSC_SDCard は、FPGA ベースシステム向けに SD カード（SPI モード）の単一セクタの読み書き機能を実装したハードウェア IP コアです。

CPU からはシンプルな MMIO（メモリマップド I/O）インターフェースとして扱うことができ、内部では SD カードの初期化、コマンド制御、データ転送、FIFO バッファリング、および SPI 通信を自動的に処理します。

CPU から見ると「メモリマップされた SD カードコントローラ」として動作します。

---

## 特徴 (Features)

- SD カード初期化（SPI モード）対応
- 単一ブロック読み出し（CMD17）と書き込み（CMD24）
- 512 バイト FIFO バッファ
- メモリマップドインターフェース（MMIO）
- CRC 受信対応（検証は未実装）
- SPI クロック設定可能（初期化用 / 通常動作用）
- エラーおよびステータス管理

---

## メモリマップ (MMIO)

| アドレス     | 名前         | 説明                         |
|--------------|--------------|------------------------------|
| 0x10006000   | SD_IF_DATA   | 読出しFIFO pop / 書込みFIFO push（1バイト） |
| 0x10006004   | SD_IF_SECTOR | セクタ（LBA）設定レジスタ     |
| 0x10006008   | SD_IF_CTRL   | 制御 / ステータスレジスタ     |

---

## 制御レジスタ (SD_IF_CTRL)

### 書き込み（Control）

| ビット | 機能                 |
|--------|----------------------|
| 0      | 初期化開始           |
| 1      | 読み出し開始（CMD17）|
| 2      | FIFO フラッシュ       |
| 3      | ソフトリセット        |
| 4      | 書き込み開始（CMD24） |
| 7      | ローカルerrorラッチのクリア |

### 読み込み（Status）

| ビット | 名前         | 説明                         |
|--------|--------------|------------------------------|
| 1      | busy         | 処理中                       |
| 2      | sd_rw_ready   | FSMがST_READY             |
| 3      | fifo_empty   | FIFO が空                    |
| 4      | fifo_full    | FIFO が満杯                  |
| 5      | error        | エラー発生                   |

上位バイトには、SD カードから受信した CRC1 および CRC2 が格納されます。

---

## 使用手順

1. 読出しFIFOをflushし、必要なら初期化を開始する。
2. タイムアウト・エラーを確認しながら初期化完了を待つ。
3. `SD_IF_SECTOR`へLBAを書き、制御bit 1でCMD17を開始する。
4. データが利用可能になってから、FIFO emptyを確認しつつ512バイト読み出す。
5. 受信CRCとソフトウェア計算値を比較する。

`busy` は未読FIFOがある間も1です。読出し前にbusy=0だけを待つと停止します。
ポーリングと待ち時間の例は[C実装](cpp/sdcard_api.c)を参照してください。
書込みは512バイトをDATAレジスタへ格納し、LBAを設定して制御bit 4で開始します。

## 内部構成 (Internal Architecture)

本モジュールは以下の 3 つの主要コンポーネントで構成されています。

### SPI エンジン（PSC_SDCard_SPI）

SD カードとの SPI 通信を担当し、バイト単位での送受信およびクロック制御を行います。\
初期化時の低速クロックと通常動作時の高速クロックに対応しています。

### FIFO バッファ

SD カードから受信した 512 バイトのデータを格納します。\
SPI タイミングと CPU アクセスのタイミングを分離する役割を持ちます。

### FSM（有限状態機械）

SD カードの初期化および読み出しシーケンスを制御します。

---

## 初期化シーケンス (Initialization Sequence)

RESET\
→ CS High で 80 クロック供給\
→ CMD0\
→ CMD8\
→ CMD55\
→ ACMD41（準備完了までループ）\
→ CMD58\
→ READY\

---

## 読み出しシーケンス (Read Sequence)

READY\
→ CMD17（単一ブロック読み出し）\
→ R1 応答待ち\
→ トークン待ち（0xFE）\
→ データ受信（512 バイト）\
→ CRC 受信（2 バイト）\
→ DONE\
→ READY\

---

## FIFO の動作 (FIFO Behavior)

- SPI から受信したデータが FIFO に書き込まれる
- CPU は MMIO 経由でデータを読み出す
- セクタバッファは512バイト構成を前提とする。RTLのポインタ幅は固定

---

## Busy 判定 (Busy Definition)

```verilog
busy = (state != ST_READY) || (fifo_count != 0);
```

FSM が動作中、または FIFO に未読データが存在する場合に busy と判定されます。

---

## 制限事項 (Limitations)

- SDHC のみ対応（LBA アドレッシング前提）
- RTLはCRC受信のみ。検証はソフトウェア側で行う
- 読み出しは単一ブロックCMD17のみ（CMD18未対応）
- 書き込みはLBA > `PROTECT_ADDRESS`（既定 `0x1000`）に制限
- FIFO フル時の制御は簡易実装

---

## 今後の拡張予定 (Future Improvements)

- CRC 検証の実装
- マルチブロック読み出し（CMD18）
- DMA 対応
- SDSC 対応

---

## 実装上の注意

PSC_SDCard は、SD プロトコル処理をハードウェアで完全に管理しつつ、CPU からはシンプルなインターフェースで利用可能な軽量 SD カード IP コアです。

ベアメタル OS、FPGA SoC 設計、カスタムストレージシステムなどに適しています。

RTLの `fifo_full` は現在 `fifo_count == FIFO_DEPTH + 1` で判定されています。
通常の「512バイトでfull」という説明と異なるため、このbitを一般的な満杯判定として
利用する前に検証が必要です。この文書更新ではRTLを変更していません。
