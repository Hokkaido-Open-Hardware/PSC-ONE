# PSC-ONE用MicroPythonパッチ

パッチ: 0001-psc-micropython.patch
対象: MicroPythonのextmod/vfs_fat.c

## 通常のビルド

`software/micropython/ports/psc/Makefile` と `software/os/Makefile` は、
共通の `build.mk` / `apply.py` でビルド前にパッチを確認・適用します。
通常のビルドでは手動適用は不要です。以下は `PSC-ONE` ディレクトリからの例です。

```bash
git submodule update --init --recursive
make -C software/micropython/ports/psc -j8 embedded
make -C software/os -j8 MODE=psc all
```

サブモジュール未取得時は取得コマンドを表示して停止します。
パッチ処理のパスはMakefile・スクリプト自身の位置から決定し、
`git apply` はサブモジュールのディレクトリ内で実行します。

1. `git apply --reverse --check` が成功すれば適用済みとして続行します。
2. 未適用なら `git apply --check` を実行し、成功した場合だけ適用します。
3. 両方失敗した場合は両コマンドの診断を表示し、ビルドを停止します。
   `git diff` で既存の変更とパッチの対象バージョンを確認してください。

既存の変更を `reset` / `restore` で消すことはありません。
適用済みの場合はファイルも更新時刻も変更しません。
適用後にサブモジュールがmodified contentになるのは正常です。

パッチ処理を前提条件とする再帰makeで通常のビルドを開始します。
`make -j` でもコンパイル、QSTR・ヘッダ生成、依存ファイルの読み込みは
パッチ処理が完了した後に始まり、適用後のソース更新時刻で依存関係を評価します。
GNU makeのjobserverとコマンドライン変数は引き継ぎます。
別々のmakeを同時に起動した場合も、パッチファイルへのロックで適用を直列化します。
追加処理にはPython 3とUnixの `fcntl.flock` を使います。

`make clean` だけの実行ではパッチ処理を行わず、既存のclean処理に委譲します。
`make -n` もパッチを適用しません。適用確認はスタンプではなく毎回実行するため、
生成済みライブラリがある場合も競合を見逃しません。

## 適用済みか確認

```bash
git -C software/micropython/micropython apply --reverse --check ../patches/0001-psc-micropython.patch
```

成功すれば適用済みです。再適用は不要です。
この確認コマンドはファイルを変更しません。
順方向・逆方向の確認が両方失敗する場合は、差分を調べてください。

ビルドせず確認・適用する場合は、次を実行します。

```bash
python3 software/micropython/patches/apply.py
```

## 自動テスト

```bash
python3 software/micropython/patches/test_apply.py
```

隔離した一時ディレクトリで未適用・適用済み・競合、未取得、clean、
並列ビルド時の生成・コンパイル順、適用後の更新時刻による再ビルドを確認します。
現在のサブモジュールや作業中の変更は変更しません。
検証用ディレクトリは結果の調査用に残します。
