#!/bin/bash
set -euo pipefail
set -x

# =========================
# Mode: sbi (default) / psc
# =========================
MODE="${1:-sbi}"   # usage: ./run.sh [sbi|psc]

QEMU=qemu-system-riscv32
CC=clang
OBJCOPY=llvm-objcopy

# 共通フラグ
CFLAGS="-std=c11 -O2 -g3 -Wall -Wextra --target=riscv32-unknown-elf -fno-stack-protector -ffreestanding -nostdlib"
LDFLAGS_USER="-Wl,-Tuser.ld -Wl,-Map=shell.map"
LDFLAGS_KERN="-Wl,-Tkernel.ld -Wl,-Map=kernel.map"

# モード別設定（USER_BASE をモードで切替）
KCPPFLAGS=""
RUN_QEMU=false
USER_BASE_VAL="0x00200000"   # default

case "$MODE" in
  sbi)
    KCPPFLAGS="-DUSE_SBI_CONSOLE"
    RUN_QEMU=true
    USER_BASE_VAL="0x01000000"
    ;;
  psc)
    KCPPFLAGS=""   # MMIO UART 0x80000000 を使用
    RUN_QEMU=false
    USER_BASE_VAL="0x00200000"
    ;;
  *)
    echo "Unknown MODE: $MODE (use: sbi | psc)" >&2
    exit 1
    ;;
esac

# リンカへ：user.ld の USER_BASE を上書き
DEFUSERBASE="-Wl,-defsym,USER_BASE=${USER_BASE_VAL}"
# コンパイラへ：C側の USER_BASE マクロも同期
DUSERBASE="-DUSER_BASE=${USER_BASE_VAL}"

# クリーン生成物
rm -f shell.elf shell.bin shell.bin.o kernel.elf shell.map kernel.map

# =========================
# 1) シェル（ユーザ）をビルド
# =========================
$CC $CFLAGS $KCPPFLAGS $DUSERBASE $DEFUSERBASE $LDFLAGS_USER -o shell.elf \
    shell.c user.c common.c

# ELF -> bin、bin -> .o（カーネルへ組込み用）
$OBJCOPY --set-section-flags .bss=alloc,contents -O binary shell.elf shell.bin
$OBJCOPY -I binary -O elf32-littleriscv shell.bin shell.bin.o

# =========================
# 2) カーネルをビルド（SBI/MMIO 切替は KCPPFLAGS、USER_BASE 同期は DUSERBASE）
# =========================
$CC $CFLAGS $KCPPFLAGS $DUSERBASE $LDFLAGS_KERN -o kernel.elf \
    kernel.c common.c shell.bin.o

# =========================
# 3) 実行
# =========================
if $RUN_QEMU; then
  # QEMU(virt) では 0x8000_0000 はRAMのため、SBI版のみ起動可能
  exec $QEMU -machine virt -bios default -nographic -serial mon:stdio --no-reboot \
       -kernel kernel.elf
else
  echo "Built PSC_RV32I (MMIO UART @0x8000_0000) version."
  echo "QEMU(virt)では動かないため起動しません。FPGA/実機で起動してください。"
fi
