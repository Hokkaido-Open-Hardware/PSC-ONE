# PSC-ONE / PSC_RV64

PSC_RV64用のボード設定を配置します。ドライバ/API実装は元の共通ディレクトリで管理します。

現在のPSC-OSはRV32専用です。`config.h` はボード名・XLEN・未対応状態を明示し、
`BOARD=psc_one_rv64` / `CPU_VERSION=rv64` は `board.mk` で説明付きエラーにします。
RV32のメモリマップやABIをRV64用として暗黙に流用しません。

RV64への移植では、実機のMMIO/メモリ配置を確認して設定を追加するとともに、
startup、LP64型・ABI、trap/context保存、Sv39、linkerを別途対応させてください。
