# PSC-ONE / PSC_RV64: RV64IM + CSR/fence.i, soft-float LP64, no A/C/F/D.
# Rebuild core and compiler_builtins: an IMAC prebuilt core can contain A/C
# instructions even when the application is compiled with -a,-c.
TARGET := riscv64im-unknown-none-elf
RUST_TOOLCHAIN ?= +nightly-2026-09-04
CARGO_TARGET_FLAGS := -Z build-std=core,compiler_builtins
BOARD_RUSTFLAGS := -C target-feature=+zicsr,+zifencei -C relocation-model=static -C code-model=medium
ARCH := --target=riscv64-unknown-elf -march=rv64im_zicsr_zifencei -mabi=lp64 -mno-relax
LIBDIR := /usr/lib/picolibc/riscv64-unknown-elf/lib/rv64im/lp64
LIBGCC := $(shell riscv64-unknown-elf-gcc -march=rv64im -mabi=lp64 -print-libgcc-file-name)

MP_BOARD_FLAGS := -f Makefile -f $(BOARD_DIR)/micropython.mk ARCH="$(ARCH) --sysroot=/usr/lib/picolibc/riscv64-unknown-elf" SRC_S=shared/runtime/gchelper_rv64i.s PSC_MPY_LONGINT_IMPL=mpz
