include ../../micropython/py/mkenv.mk

# ------------------------------------------------------------
# PSC-ONE / PSC-RV32ISP
# ------------------------------------------------------------

QSTR_DEFS = qstrdefsport.h

MICROPY_ROM_TEXT_COMPRESSION ?= 0

include $(TOP)/py/py.mk

CC      := clang
LD      := clang
AR      := llvm-ar
OBJCOPY := llvm-objcopy
SIZE    := llvm-size

INC += -I.
INC += -I$(TOP)
INC += -I$(BUILD)

ARCH = \
	--target=riscv64-unknown-elf \
	-march=rv32im_zicsr_zifencei \
	-mabi=ilp32 \
	-mno-relax \
	--sysroot=/usr/lib/picolibc/riscv64-unknown-elf

CFLAGS += \
	$(INC) \
	$(ARCH) \
	-std=c11 \
	-Os \
	-g \
	-Wall \
	-ffreestanding \
	-fno-stack-protector \
	-fomit-frame-pointer \
	-fdata-sections \
	-ffunction-sections \
	-mstrict-align

CSUPEROPT = -Os

# ------------------------------------------------------------
# Picolibc libraries
#
# PSC-RV32ISP は RV32IM。
# rv32i/ilp32 版なら A/C/F/D 命令を要求しないため安全。
# ------------------------------------------------------------

LIBM := /usr/lib/picolibc/riscv64-unknown-elf/lib/rv32i/ilp32/libm.a
LIBC := /usr/lib/picolibc/riscv64-unknown-elf/lib/rv32i/ilp32/libc.a

# ------------------------------------------------------------
# PSC port sources
# ------------------------------------------------------------

SRC_S = \
	start.S

SRC_C = \
	main.c \
	mphalport.c \
	shared/libc/printf.c \
	shared/libc/string0.c \
	shared/readline/readline.c \
	shared/runtime/pyexec.c \
	shared/runtime/stdout_helpers.c \
	$(BUILD)/_frozen_mpy.c

SRC_QSTR += \
	shared/readline/readline.c \
	shared/runtime/pyexec.c

OBJ += $(PY_CORE_O)
OBJ += $(addprefix $(BUILD)/, $(SRC_C:.c=.o))
OBJ += $(addprefix $(BUILD)/, $(SRC_S:.S=.o))

# ------------------------------------------------------------
# libgcc
# ------------------------------------------------------------

LIBGCC := $(shell riscv64-unknown-elf-gcc \
	-march=rv32im \
	-mabi=ilp32 \
	-print-libgcc-file-name)

# ------------------------------------------------------------
# MicroPython ELF
# ------------------------------------------------------------

MICROPY_ELF := build/micropython.elf

$(MICROPY_ELF): $(OBJ)
	$(CC) \
		--target=riscv64-unknown-elf \
		-march=rv32im_zicsr_zifencei \
		-mabi=ilp32 \
		-mno-relax \
		--sysroot=/usr/lib/picolibc/riscv64-unknown-elf \
		-nostdlib \
		-Wl,-Tpsc.ld \
		-Wl,--no-relax \
		-Wl,-e,_start \
		-o $@ \
		$(OBJ) \
		$(LIBM) \
		$(LIBC) \
		$(LIBGCC)

# ------------------------------------------------------------
# MicroPython BIN
# ------------------------------------------------------------

MICROPY_BIN := build/micropython.bin

$(MICROPY_BIN): $(MICROPY_ELF)
	$(OBJCOPY) \
		--set-section-flags .bss=alloc,contents \
		-O binary \
		$< $@

# ------------------------------------------------------------
# First target: compile objects only
# ------------------------------------------------------------

all: $(OBJ)
	@echo
	@echo "PSC MicroPython core build OK"

# ------------------------------------------------------------
# Frozen MPY
# ------------------------------------------------------------

$(BUILD)/_frozen_mpy.c: \
	$(TOP)/tests/assets/frozentest.mpy \
	$(BUILD)/genhdr/qstrdefs.generated.h

	$(ECHO) "MISC freezing bytecode"
	$(Q)$(TOP)/tools/mpy-tool.py \
		-f \
		-q $(BUILD)/genhdr/qstrdefs.preprocessed.h \
		-mlongint-impl=none \
		$< > $@

# ------------------------------------------------------------
# MicroPython common rules
# ------------------------------------------------------------

include $(TOP)/py/mkrules.mk