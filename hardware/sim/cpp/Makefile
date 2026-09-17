###############################################################################
# ユーザ設定
###############################################################################
RISCV_PREFIX ?= riscv64-unknown-elf-
CC      := $(RISCV_PREFIX)g++
OBJCOPY := $(RISCV_PREFIX)objcopy
LINKER  := link.ld
STARTUP := sp_start.S
MEM_WORDS ?= 16384         # 出力 .mem 行数（0埋め）

###############################################################################
# PHONY ゴールとターゲット名の自動選定
###############################################################################
.PHONY: all clean disasm
PHONY_GOALS := all clean disasm
FIRST       := $(firstword $(MAKECMDGOALS))

ifeq ($(filter $(FIRST),$(PHONY_GOALS)),)
TARGET := $(FIRST)
endif
TARGET ?= divmod_test1

###############################################################################
# 自動生成ファイル名（TARGET を使って再評価）
###############################################################################
CPP_SRC := $(TARGET).cpp
# rv32i_zicsr_zifencei (RV32I)
#OBJ     := $(STARTUP:.S=.o) $(CPP_SRC:.cpp=.o) mulsi3.o divmodsi3.o
# rv32i_zmmul_zicsr_zifencei (RV32I M)
#OBJ     := $(STARTUP:.S=.o) $(CPP_SRC:.cpp=.o) divmodsi3.o
# rv32im_zicsr_zifencei (RV32IM)
OBJ     := $(STARTUP:.S=.o) $(CPP_SRC:.cpp=.o)
ELF     := $(TARGET).elf
BIN     := $(TARGET).bin
MEM     := $(TARGET).mem

mulsi3.o: mulsi3.c
	$(CC) $(CXXFLAGS) -c $< -o $@

divmodsi3.o: divmodsi3.c
	$(CC) $(CXXFLAGS) -c $< -o $@

###############################################################################
# コンパイル/リンクフラグ
###############################################################################
CXXFLAGS := -std=c++23 -march=rv32im_zicsr_zifencei -mabi=ilp32 -O2 -g \
  -ffreestanding -nostdlib -fno-rtti -fno-exceptions -fimplicit-constexpr \
  -fno-toplevel-reorder -Wfatal-errors -Werror -Wall -Wextra -Wpedantic \
  -Wshadow -Wnon-virtual-dtor -Wcast-align -Woverloaded-virtual \
  -Wconversion -Wsign-conversion -Wmisleading-indentation -Wduplicated-cond \
  -Wduplicated-branches -Wlogical-op -Wnull-dereference -Wuseless-cast \
  -Wdouble-promotion -Wformat=2 -Wimplicit-fallthrough \
  -Wno-stringop-overflow -Wno-unused-function -Wno-unused-parameter \
  -Wl,-T,$(LINKER) -Wl,--no-warn-rwx-segment \
  -mstrict-align

###############################################################################
# 拡張子ルール（明示的）
###############################################################################
.SUFFIXES:

%.o: %.cpp
	$(CC) $(CXXFLAGS) -c $< -o $@

%.o: %.S
	$(CC) $(CXXFLAGS) -c $< -o $@

###############################################################################
# ビルドチェーン
###############################################################################

# デフォルトターゲット: mem まで作る
all: $(TARGET)

# make add_test1 → add_test1.mem まで作成
$(TARGET): $(MEM)

# ELF生成
$(ELF): $(OBJ)
	$(CC) $(CXXFLAGS) $^ -o $@

# バイナリ生成
$(BIN): $(ELF)
	$(OBJCOPY) -O binary $< $@

# MEM生成（16進4バイトずつ出力：32bit × N行）
$(MEM): $(BIN)
	@hexdump -v -e '1/4 "%08x\n"' $< > $@
	@MAX=$(MEM_WORDS); \
	LINES=$$(wc -l < $@ | tr -d ' '); \
	if [ $$LINES -lt $$MAX ]; then \
		DIFF=$$((MAX - LINES)); \
		for i in $$(seq 1 $$DIFF); do echo "00000000" >> $@; done \
	fi
	@mkdir -p ../mem
	@cp $@ ../mem/$(notdir $@)

###############################################################################
# ディスアセンブルとクリーン
###############################################################################
# Usage
# make disasm TARGET=add_test1

disasm: $(ELF)
	$(RISCV_PREFIX)objdump -d $(ELF) > $(TARGET).S
	@echo "Disassembly saved to $(TARGET).S"

clean:
	rm -f *.o *.elf *.bin *.mem
	find . -maxdepth 1 -type f -name '*.S' ! -name 'sp_start.S' -delete