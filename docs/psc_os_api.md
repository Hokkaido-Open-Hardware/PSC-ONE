<p align="center">
  <a href="https://github.com/QPSC-Design/PSC-ONE">
    <img src="images/PSC-ONE_Logo.png" width="640" alt="PSC-ONE logo">
  </a>
</p>

# PSC-ONE API

[ドキュメント一覧](README.md) · [OS](psc_os.md) · [MMU](cpu_mmu.md) · [ソフトウェア](../software/README.md)

PSC-OSの組込みアプリケーション、ロードしたELF、MicroPythonでは利用できるAPIが異なります。
本書は公開ヘッダと実際のdispatchに基づく案内です。POSIXやLinuxのシステムコールABIではありません。

<!-- contents -->
- [APIの層と参照先](#apiの層と参照先)
- [ECALL規約](#ecall規約)
- [システムコール一覧](#システムコール一覧)
- [組込みC API](#組込みc-api)
- [MicroPythonのpscモジュール](#micropythonのpscモジュール)
- [戻り値と実行上の注意](#戻り値と実行上の注意)
<!-- /contents -->

## APIの層と参照先

| 利用箇所 | 入口 | 用途 |
| --- | --- | --- |
| 組込みCアプリ／シェル | [user.h](../software/os/src/api/user.h) / [user.c](../software/os/src/api/user.c) | ECALLラッパー、コンソール、デバイス呼出し |
| カーネル | [syscall.h](../software/os/src/kernel/syscall.h) / [dispatch](../software/os/src/kernel/kernel_syscall.c) | 呼出し番号、引数、許可範囲 |
| FAT32 | [fat32.h](../software/os/src/fs/fat32.h) | rootディレクトリ、ファイル読出し |
| JPEG | [jpeg_view.h](../software/os/src/api/jpeg/jpeg_view.h) | FAT32のJPEGをLCDへ表示 |
| TFLite | [tflite_api.h](../software/os/src/api/tflite/tflite_api.h) | モデル準備・推論・backend選択 |
| MicroPython | [modpsc.c](../software/micropython/ports/psc/modpsc.c) | `import psc` |
| 外部ELF | [ELFアプリケーション](../software/os/elf_apps/README.md) | 限定されたコンソール／終了ABI |

ドライバ内の `timer_*` や `led_*` と、ユーザー用ECALLラッパーは実行層が異なります。
カーネル関数を外部ELFへそのままリンクできるわけではありません。

## ECALL規約

- `a3`：システムコール番号。
- `a0`〜`a2`：基本引数。サービスにより `a4`〜`a6` も使用。
- `a0`：値またはstatus。`SYS_ELF_RUN` は `a1` にELF終了コードも返す。
- 呼出し：`ecall`。コンソール出力など戻り値を設定しないサービスの `a0` は利用しない。

`user.c` に残る「PSCではecallなし」という古いコメントと異なり、実際のラッパーはECALLを使います。
既存のラッパーを使用し、番号・引数レジスタを独自に割り当てないでください。

## システムコール一覧

以下は `kernel_syscall.c` にcaseがあるサービスです。番号定義だけのものは次節に分けます。

| 番号 | 名前 | 主な入力／結果 |
| --- | --- | --- |
| 1 | `SYS_PUTCHAR` | `a0`の文字を出力 |
| 2 | `SYS_GETCHAR` | 文字待ち。待機中はyieldし、文字を`a0`へ返す |
| 3 | `SYS_GETCHAR_TIMEOUT` | タイムアウト付き受信。内部で`uart_getchar_timeout(1000)`を使用 |
| 10 | `SYS_SA_RUN` | `a0=A`, `a1=B`, `a2=C`, `a4=n`, `a5=option/profile`, 任意の`a6=profile` |
| 20 / 21 | `I2S_MIC_READ` / `I2S_MIC_WRITE` | サンプル数を`a0`、write側は`a1`も渡す |
| 30 | `SYS_SD_READ` | `a0=LBA`、診断用のセクタ読出し |
| 31 | `SYS_SD_WRITE_TEST` | `a0=LBA`へ512-byte試験パターンを書込む |
| 32 / 33 | `SYS_SD_WRITE` / `SYS_SD_READ_BUF` | `a0=LBA`, `a1=512-byte buffer`、statusを返す |
| 40 | `SYS_DUMP` | `a0=address`, `a1=length`。0なら256 bytes、最大4096 bytes |
| 50 | `SYS_SW_READ` | PIO下位2 bitを返す |
| 60 | `SYS_SPEECH_RECOGNITION` | 音声認識処理の結果を返す |
| 70 / 71 | `SYS_TIMER_START` / `SYS_TIMER_START_AUTO` | `a0=reload`、単発／自動リロード |
| 72 | `SYS_TIMER_STOP` | タイマー停止 |
| 73 / 74 / 75 | `SYS_TIMER_GET_COUNT` / `GET_STATUS` / `IS_RUNNING` | カウント／status／動作状態 |
| 76 / 77 | `SYS_TIMER_WAIT_US` / `WAIT_MS` | `a0`で指定したµs／ms待機 |
| 78 / 79 | `SYS_TIMER_MEASURE_BEGIN` / `MEASURE_END` | 計測開始／msで終了結果 |
| 87 / 88 | `SYS_TIMER_MEASURE_END_US` / `MEASURE_READ_US` | µsで終了／途中経過 |
| 80 | `SYS_LED_WRITE` | `a0`をLED値として設定 |
| 81 / 82 / 83 | `SYS_LED_ON` / `OFF` / `TOGGLE` | `a0=LED番号` |
| 84 / 85 / 86 | `SYS_LED_ALL_ON` / `ALL_OFF` / `GET_STATE` | 全点灯／全消灯／状態取得 |
| 92 | `SYS_LCD_RGB888_BEGIN` | RGB888描画初期化 |
| 93 | `SYS_LCD_RGB888_RECT` | `a0=x`, `a1=y`, `a2=width`, `a4=height`, `a5=RGB buffer` |
| 100 | `SYS_EXIT` | ELFなら`a0=終了コード`でシェルへ復帰。通常シェルでは再起動 |
| 101 | `SYS_PRINT_INT` | `a0`の整数を表示 |
| 102 | `SYS_ELF_RUN` | `a0=ELF buffer`, `a1=size`。戻りは`a0=status`, `a1=exit code` |

### 定義済みだがdispatchのない番号

`SYS_READFILE=51`、`SYS_WRITEFILE=52`、`SYS_LCD_INIT=90`、`SYS_LCD_FILL_RGB=91`
はヘッダにありますが、現行dispatchにcaseがありません。利用可能なAPIとして呼び出さないでください。
通常のシェル経路で未知の番号を呼ぶと `PANIC` になります。

### 外部ELFの制限

実行中のforeground ELFに許可されるのは1、2、3、100、101のみです。
他の番号は `a0=-1` を返します。シェルが利用するSD、LCD、NPUやFAT32機能を、
ELFから同じように呼び出せるわけではありません。
引数規約とサンプルのビルドは[ELFアプリガイド](../software/os/elf_apps/README.md)を参照してください。

## 組込みC API

### FAT32

```c
int fat32_open(fat32_file_t *file, const char *name);
int fat32_stream_read(fat32_file_t *file, void *dst,
                      uint32_t count, uint32_t *actual);
int fat32_skip(fat32_file_t *file, uint32_t count, uint32_t *actual);
void fat32_close(fat32_file_t *file);
```

stream APIはroot内の大文字8.3名、読出し専用です。短い正常読出しや0 bytesはEOFを表します。
エラーは負値で、close/openまで保持します。`FAT32_ERR_NAME=-2`、NOT_FOUND=-3、SD=-4、
FORMAT=-5、CHAIN=-6、STATE=-7です。`fat32_ls()` のLFN表示対応は、
open/read時の長い名前やパスへの対応を意味しません。

`fat32_mount()`、`fat32_cat()`、`fat32_find()`、`fat32_touch()`、`fat32_read()` も
[ヘッダ](../software/os/src/fs/fat32.h)に定義されています。
[回帰と名前制限](../software/os/tests/fat32/README.md)も参照してください。

### LCDとJPEG

`call_lcd_rgb888_begin()` と `call_lcd_rgb888_rect(x,y,width,height,rgb)` は
ECALL経由でLCDを操作します。1矩形は最大16×16、RGB888で3 bytes/pixel、
画面内の座標と読出し可能なユーザーバッファが必要です。カーネル内へコピーして送信します。

`jpeg_view(filename)` はファイルを開き、デコードして表示し、statusを返します。
`jpeg_error_string(error)` でエラー文を取得できます。
対応JPEG形式・サイズ・480×320 landscape表示の条件は[OS README](../software/os/README.md)を参照してください。

### SynapEngine

`call_sa_matmul_int8(a,b,c,n,profile)` はsigned int8の正方行列積を実行します。
現行のサイズは4、8、12、16。出力はint32、`profile` は任意です。
カーネル側は入力を専用バッファへコピーし、NPU完了後に結果を戻します。
C出力は4-byte整列が必要です。statusが非ゼロなら結果を成功として使わないでください。

`call_sa_api(matrix_size,option)` は組込みの行列生成・表示を含むデモ用関数です。
任意行列の呼出しと区別してください。
関連定義は[sa_transfer.h](../software/os/src/api/sa_transfer.h)と
[synap_api.h](../software/os/src/api/synap_api.h)にあります。

### TFLite

通常の流れは `psc_tflite_load()` または `psc_tflite_prepare()`、
`psc_tflite_get_input()`、入力設定、`psc_tflite_invoke()`、`psc_tflite_get_output()` です。

- モデルは同時に1つ。同期実行で、再入不可。
- `prepare()` は整列された不変モデルバイト列を借用する。モデル領域は処理中も保持する。
- 入出力ポインタはreset/load/prepare/inspectで無効になる。出力はinvoke成功後のみ有効。
- arenaは4 KiB。モデルファイル上限8 KiB、限定されたINT8 FCプロファイル。
- C backendはCPU=0、Synap=1、PULP=2。PULP利用不可時はCPUへfallbackし、Synapの失敗はfallbackしない。
- Synap tileは4、8、12、16。load/prepare/reset後はCPU、tile=4へ戻る。

正確な演算・量子化制限は[TFLite仕様](../software/os/src/api/tflite/README.md)、
PULP対応条件は[backend記録](../software/os/third_party/tflite/README.md)を参照してください。

## MicroPythonのpscモジュール

PSC-OSシェルで `micropython` を実行し、REPLで `import psc` します。

| API | 動作／結果 |
| --- | --- |
| `fat32_ls()` | root一覧を出力、`None` |
| `run(name)` | SD上の最大4 KiBのPythonスクリプトを実行、`None` |
| `timer_start(count)`, `timer_start_auto(count)`, `timer_stop()` | タイマー制御、`None` |
| `timer_count()`, `timer_status()`, `timer_running()` | 整数、整数、bool |
| `wait_us(us)`, `wait_ms(ms)` | 同期的な待機、`None` |
| `led_write(value)` | LED値を設定、`None` |
| `led_on(led)`, `led_off(led)`, `led_toggle(led)` | 指定LEDを操作、`None` |
| `led_all_on()`, `led_all_off()`, `led_state()` | 全点灯、全消灯、状態整数 |
| `sa_run(A,B,signed_mode)` | 正方行列積を計算し、行ごとのlistを返す |
| `tflite_load(name)`, `tflite_reset()` | モデル管理、`None` |
| `tflite_input_size()` | 必要入力byte数 |
| `tflite_run(data)` | 推論結果の独立した`bytes`コピー |
| `tflite_set_fc_backend(backend)` | Pythonでは0=CPU、1=Synapのみ |
| `tflite_set_synap_tile_size(size)` | 4、8、12、16を選択 |
| `tflite_arena_used()` | C arena使用byte数。Pythonヒープとは別 |

Pythonのbackend指定はCと異なり、PULP=2を受け付けません。
`sa_run` は4/8/12/16の正方行列で、signedなら−128..127、unsignedなら0..255を受け付けます。
LED番号は0〜5、`led_state()` はドライバが保持する6-bitの状態値です。
行列の寸法・値の不正は `ValueError`、デバイス失敗は `OSError` になります。

```python
import psc

psc.led_on(0)
psc.wait_ms(100)
psc.led_off(0)

A = [[1 if i == j else 0 for j in range(4)] for i in range(4)]
B = [[i * 4 + j for j in range(4)] for i in range(4)]
print(psc.sa_run(A, B, True))  # identity × B
```

TFLiteは読出し可能なbyte bufferを受け取り、入力長の完全一致が必要です。
INT8の−1はbyte値255で表します。型の不正は `TypeError`、長さなどの不正は `ValueError`、
C側失敗は `OSError`。shellとPythonはモデルを共有し、REPL終了ではresetしません。
詳細とテストスクリプトは[PSCポート](../software/micropython/ports/psc/README.md)を参照してください。

## 戻り値と実行上の注意

全API共通のerrno規約はありません。void関数の戻り値を読まず、各ヘッダのstatusを確認してください。
タイマー計測は既存タイマーの使用状態に依存し、利用できない場合は−1を返します。
長時間の推論・描画・待機は同期処理です。

既存シェルにはraw pointerを扱う診断APIがあり、全サービスで同じポインタ検査を行うわけではありません。
ELFの呼出し制限も、[MMUのU/S制限](cpu_mmu.md#実装上の制限)を補う完全な隔離機構ではありません。
