# PSC-ONE TFLite Phase 4 — selectable CPU / SynapEngine FC

2026-09-13: CPU/NPUの切替、全中間値のbit-exact一致、RV32I/IM build、CPU v1 RTL、
ホストsanitizer回帰を確認した。**この小型モデルではNPUによる高速化は達成していない。**
現行CPUは966 µs、NPU最速の8×8は4,177 µsで、speedupは0.231倍。
測定スナップショットと全80行の比較値は
[phase4_results.json](../../../tests/tflite/phase4_results.json)に記録する。

## 使い方とbackend選択

```text
tflite_info MODEL.TFL
tflite_run MODEL.TFL          # 既存互換、CPU
tflite_run MODEL.TFL cpu
tflite_run MODEL.TFL npu      # NPU、初期tile=4
tflite_bench MODEL.TFL        # 同じモデルでCPUと4/8/12/16を比較
```

`run`と`bench`はPhase 3の固定16要素入力を使う診断コマンド。
通常のアプリケーションでは以下のC APIで入力を設定する。

```c
psc_tflite_load("MODEL.TFL");
size_t size;
int8_t *input = psc_tflite_get_input(&size);
/* inputに量子化済みINT8データを設定 */
psc_tflite_set_fc_backend(PSC_TFLITE_FC_CPU);
int rc = psc_tflite_invoke();
/* rcとget_outputを確認し、必要なら結果を保存 */
psc_tflite_set_synap_tile_size(8);
psc_tflite_set_fc_backend(PSC_TFLITE_FC_SYNAP);
rc = psc_tflite_invoke();
```

グローバルな単一resident modelというPhase 3の構造を維持する。
load/prepare/reset後はCPU、tile=4、profiling無効。
backend/tile切替はprepare済みモデルとinputを保持し、古いoutputの有効状態だけを解除する。
invoke中の切替・再入はBUSY。失敗時にCPUへ暗黙fallbackしない。
CPUのINT32 dot実装はreference backendとして残し、同じ後処理を共有する。

## 正方行列への配置

タイル幅Tを4/8/12/16から選ぶ。出力channelをT個ずつ、KをT個ずつ分割する。

- `A[row*T+k] = weight[(output_base+row)*K + k_base+k]`
- `B[k*T+0] = raw_input[k_base+k]`
- その他のA/B要素は0。**input - zero_pointをINT8へ変換しない。**
- signed INT8の`C=A*B`をSYS_SA_RUNで実行し、`C[row*T+0]`だけを使用する。
- K方向の部分和をCPUのINT32で加算する。最後の短いK/outputタイルも0埋めする。

| T | FC1の起動数 | FC2の起動数 | 合計 | A+B+Cのsyscallコピー量 | 有効MAC / 実行MAC |
|---:|---:|---:|---:|---:|---:|
| 4 | 16 | 4 | 20 | 1,920 B | 320 / 1,280 |
| 8 | 4 | 2 | 6 | 2,304 B | 320 / 3,072 |
| 12 | 4 | 2 | 6 | 5,184 B | 320 / 10,368 |
| 16 | 1 | 1 | 2 | 3,072 B | 320 / 8,192 |

コピー量はA/B各INT8、C全INT32の6*T*T*起動数。kernel C初期化や
アクセラレータ内部転送は含まない。固定の正方形を実行するため、有効列は1列。
最大タイルが最速とは仮定していない。今回のモデル全体では8が最速、
個別にはFC1が16、FC2が4で最速だった。backend単位の固定幅を実装し、
Operatorごとの自動選択やpackingの事前キャッシュは追加していない。

## CPUに残した処理

1. weight row sumのprepare。
2. NPU partial raw dotのK方向INT32加算。
3. `corrected = raw_dot - input_zero_point * row_sum`。
4. INT32 bias加算。
5. prepare時のmultiplier/shift計算。
6. Phase 3と同じ公式TFLM二段丸めrequantization。
7. output zero_point加算、INT8 saturation、fused NONE/RELU。

公式vendorと`tflite_quant.cc`は変更していない。Phase 3の範囲検証も維持する。
対応Operator・shape・量子化条件はPhase 3のままで、Conv2DやMicroPython bindingは追加しない。

## 比較と状態保持

旧3値trace APIに加えて、`psc_tflite_invoke_detailed`で各channelの
raw / corrected / biased / requant / clamped outputを観測する。
`requant`はoutput zero_point加算後、clamp前。

- CPU/NPU全20チャネルの5段階が、4/8/12/16のすべてで完全一致。
- biased/requant/clampは未変更のPhase 3公式oracleとも一致。
- 最終出力は両backendとも **[-36, 27, 18, 8]**。
- 一度ロードしたモデルでCPU→NPU→CPU→NPUを繰り返し、全入力を変更して再比較。
- RTLではNPU start CSRの立上りを230回観測。CPU選択時は0回。
  signed bitとA/Bがkernel物理領域のアドレスであることも確認する。
- `tflite_bench`単体では4/8/12/16の起動数が100/30/30/10回。
  各サイズ5回のNPU invoke（比較、通常計測、FC別計測、内訳計測、変更入力比較）。

## cache整合性

CPU v1はwrite-back D-cacheを持つが、SynapEngineは独立AXI DMAとして
そのcacheを迂回していない。
`hardware/rtl/cpu_v1/src/PSC_ONE_RV32_core.v`の`u_data_dma_ctrl`へCPUとSAの両方が接続される。
`hardware/rtl/cache/src/cache_dma_controller_io.sv`の`S_CASHE_START`は
CPU/SAを仲裁し、同じtag/dataの`S_LOOKUP_ISSUE`へ渡す。

- CPU→NPU: kernel_A/Bに書いたdirty lineをSA readが同じcacheから取得する。
- NPU→CPU: SA writeも同じlineを更新し、CPUのvolatile result readがそれを取得する。
- SYS_SA_RUNはuser VAを直接NPUへ渡さず、既存kernel A/Bへコピーし、物理アドレスを指定する。
  NPU結果は既存0x00030000からkernel_Cへ、その後user Cへコピーする。
- 同期実行と既存fenceを維持する。この共有cache構成ではflush/invalidateは追加不要。
  fence単体に整合性を依存させる設計ではない。
- RTLで同じuser/kernel/NPU result bufferを異なる入力・タイル・FCに再利用し、
  両方向の更新とstale data不在を確認した。

将来NPUを別DMA/cache経路へ移す場合には、この根拠は成立しない。
実際のwrite-back/完了待ち/invalidateと物理アドレス管理を改めて設計する必要がある。

## エラー処理

`sa_run_checked`を追加し、0 / 引数-1 / timeout-2 / busy-3を返す。
従来のvoid `sa_run`は互換wrapperとして残す。
SYS_SA_RUNは入力のread権限、出力・profileのwrite権限、全Sv32ページ範囲、alignment、
4/8/12/16のサイズを検証する。失敗時はuser Cに結果をコピーしない。
timeoutではcontrollerをresetしてactiveを解除する。

runtimeへの対応:

| TFLite status | 意味 |
|---:|---|
| -206 | その他のSynapEngine syscall failure |
| -207 | timeout |
| -208 | deviceのmatrix size/buffer引数異常 |
| -209 | device busy |

失敗時にoutputを無効化し、後続layerを実行しない。model/inputは保持されるため、
呼出し側が明示的にCPUへ切り替えて再実行できる。
true hardware hangの故障注入はRTLで行っていないが、実ドライバのCSR操作をmockに
置き換えたhost testでtimeout/reset/無書込み/再実行の分岐を確認した。

## 性能（CPU v1、100 MHz RTL、µs）

| Backend | Tile | invoke | FC1 | FC2 | CPU_time / invoke |
|---|---:|---:|---:|---:|---:|
| CPU | — | 966 | 732 | 228 | 1.000 |
| Synap | 4 | 5,058 | 4,010 | 1,039 | 0.191 |
| Synap | 8 | 4,177 | 2,854 | 1,313 | 0.231 |
| Synap | 12 | 7,834 | 5,308 | 2,524 | 0.123 |
| Synap | 16 | 4,910 | 2,650 | 2,263 | 0.197 |

最速NPUもCPUの約4.32倍の時間を要する。CPU defaultを維持する。
単純な正方形matrix-vector配置では演算利用率が低く、packing、コピー、syscallの費用が大きい。

Phase 3はload=30,824、prepare=8,630、invoke=617、FC1=494、FC2=156 µsだった。
Phase 4の通常CPUコマンドはload=30,533、prepare=8,767、invoke=908、FC1=709、FC2=203 µs。
上表は同一runtimeのbench内で測った値。CPU経路にも共通backend分岐・trace/profile対応が加わり、
Phase 3より遅くなっている。RV32IMの逆アセンブルでは、共有partial-dot配列へのstoreが
CPUの各MAC反復内にも残っていることを確認した。これも追加コストの候補であり、
各要因の寄与は未分離。CPU経路の性能回復は残課題とする。
古い617 µsを現行NPUに対するspeedupの分子には使わない。

通常計測ではprofilingとchannel traceを無効にし、UART出力を計測区間外に置く。
各計測は先行する検証invokeの後の1回測定。cacheの強制初期化や統計集計は行っていない。
FC1/2は別invokeで個別計測するので、合計とinvoke時間は必ずしも一致しない。
RTLでの測定であり、FPGA実機・実SDカードの時間ではない。

## 内訳（別のprofile有効run、µs）

既存stopwatchにnon-destructiveなread API（syscall 88）を追加した。
SYS_SA_RUNのa5 bit31がprofile有効フラグ、a6がprofile出力先。
従来の0/1 callerではa6を参照しない。

| Tile | profile total | packing | syscall全体 | copy-in | run | copy-out | partial | post |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 4 | 9,478 | 1,860 | 4,858 | 1,035 | 668 | 573 | 1,097 | 434 |
| 8 | 5,625 | 1,228 | 3,116 | 1,027 | 703 | 561 | 376 | 356 |
| 12 | 9,275 | 1,938 | 6,059 | 2,323 | 1,726 | 1,182 | 379 | 355 |
| 16 | 5,476 | 1,215 | 3,494 | 1,379 | 1,132 | 699 | 139 | 308 |

- copy-in = user A/B→kernel A/Bとkernel C初期化。
- run = sa_run_checkedのCSR設定・NPU待機・result→kernel C読出し。
  NPUの純粋な演算時間だけを分離した値ではない。
- copy-out = kernel C→user C。
- partial = INT32部分和に加え、profile集計の費用を含む。
- post = zero_point補正・bias・requantization・clamp。
- copy-in/run/copy-outはsyscall全体の**内数**で、重ねて加算しない。
- read-us syscallや集計の影響が大きいため、profile totalを通常invoke時間と混同しない。
  未計上のdispatcher・計測境界があり、各欄の合計もtotalとは一致しない。

## メモリ（Phase 3比）

| RV32IM shell | 増加 |
|---|---:|
| .text | 4,504 B |
| .rodata | 952 B |
| .data | 0 B |
| .bss | 1,584 B |
| コード・定数合計 | 5,456 B |

TFLite導入前比の追加コード・定数は64,104→69,560 B、追加BSSは12,728→14,312 B。
kernel側は別途コード・定数+1,140 B、BSS+4 B。

- 新規NPU workspace: A 256 + B 256 + C 1,024 = **1,536 B**（静的、16-byte aligned）。
- runtime metadata増分: 48 B。partial dotは最大16×INT32=64 Bをstackで使用。
- kernel A/B/Cの1,536 Bは既存SYS_SA_RUNの領域を再利用し、二重追加していない。
- model予約8,192 B、demo使用1,568 B。arena予約4,096 B、demo使用**116 B**で変わらない。
- RV32IM shell image 620,576 B、copy pages 622,592 B。
  ページ予算残量 **45,056 B**（Phase 3の53,248 Bから8,192 B減）。
- RV32I shell image 625,776 B、copy pages 626,688 B、残量36,864 B。
  RV32Iではkernel成長によりpoolも4,096 B減る。
- invokeのheap割当・file I/Oは追加していない。

## 検証・再現

```sh
python3 PSC-ONE/software/os/tests/tflite/run.py --build build/tflite-phase4-host
python3 PSC-ONE/software/os/tests/tflite/phase3_check.py --build build/tflite-phase4-cross
myenv/bin/python PSC-ONE/software/os/tests/tflite/rtl_run.py --build build/tflite-phase4-rtl --model build/tflite-phase4-host/phase3/MODEL.TFL
myenv/bin/python PSC-ONE/software/os/tests/jpeg/run.py --build build/tflite-phase4-jpeg
```

出力先は任意。既存/tmp生成物、ネットワーク、TensorFlow Python packageには依存しない。
モデル生成元とSHAはPhase 3から変更していない。

- Phase 2: 3,628件 PASS。
- Phase 3: 47ケース / 712チャネル / 65,560 multiplier比較 PASS。
- Phase 4: 288 CPU/NPU invokes、2,880チャネル×5段階 PASS。
  全タイル幅、K=1/3/4/5/15/16/17/31/33、正負・極値input、端数output、
  各種失敗の最初/途中tileでの注入と明示的CPU切替・NPU再実行を検査。
- 実ドライバのCSR mock test: 引数、busy、timeout、reset、無書込み、復帰、legacy wrapper PASS。
  検証用コピーだけでpoll limitを4に短縮し、productionコードの1,000万pollは変更しない。
- ASan / UBSan / leak check PASS。hostは正方形全要素のsigned matmul mockを使用。
- RV32I/IMのshell+kernel全体build PASS。RV32IはMicroPythonも別BUILDで再コンパイルし、
  M命令不在をdisassemblyで検査。単独runtime+adapterのheap/C++依存監査もPASS。
- CPU v1 RTL: tests=1 / PASS=1 / FAIL=0 / SKIP=0、simulation 3.4474722秒、wall約1,545秒。
  SD読み込み、明示CPU/NPU、全タイルの全中間値、CSR起動、入力変更、引数拒否、
  shell復帰、info、missing file、hello/primes、SD CRC OKを確認。
- 既存JPEG/FAT32の画像比較・AddressSanitizer回帰 PASS。

## ファイルと残る課題

新規: `src/api/sa_transfer.h`、`src/api/tflite/tflite_synap.cc/.h`、`tflite_platform.c`、
`PHASE4.md`、`tests/tflite/synap_mock.cc`、`phase4.cc`、`driver_test.py`、`phase4_results.json`。

変更: runtime/api/file、shell、user.c/.h、synap_api.c/.h、kernel_syscall.c、
syscall.h、timer_api.h、timer_measure.c、Makefile、TFLite README、
ホストrunner/generator/phase3 fixture入口、RV32チェック、RTLテスト。
Quantization実装・vendor pin・production RTLは変更していない。削除ファイルなし。
Git add/commit/pushは行わない。

残る課題は高速化未達、実FPGA未測定、純粋なNPU演算時間の分離、Operator別tile自動選択。
これらは今回のbit-exact切替・比較の完了を妨げないが、高速化済みとは扱わない。

Conv2Dへ進む場合は、出力位置を複数列に並べて行列利用率を上げること、
im2colの生成・SRAM容量・転送量、padding時に実数0を表すinput zero_pointを使うこと、
per-channel scale、出力channel/K/空間方向のtileと部分和を検討する必要がある。
既存のCPU referenceと量子化oracleを保持し、転送を含む総時間で効果を判断する。
