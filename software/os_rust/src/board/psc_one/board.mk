# PSC-ONE / PSC_RV32. v1 and v2 share the ILP32 OS ABI.
ifeq ($(CPU_VERSION),rv64)
$(error BOARD=psc_one is for PSC_RV32; use BOARD=psc_one_rv64 for PSC_RV64)
endif
TARGET := riscv32im-unknown-none-elf
ARCH := --target=riscv32-unknown-elf -march=rv32im_zicsr_zifencei -mabi=ilp32 -mno-relax
LIBDIR := /usr/lib/picolibc/riscv64-unknown-elf/lib/rv32i/ilp32
LIBGCC := $(shell riscv64-unknown-elf-gcc -march=rv32im -mabi=ilp32 -print-libgcc-file-name)
