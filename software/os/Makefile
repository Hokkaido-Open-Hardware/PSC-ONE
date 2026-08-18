# ========================
# Src / Build Dirs
# ========================
Src   := ./src
Build := ./build

$(Build):
	mkdir -p $(Build)

# ========================
# Tools
# ========================
QEMU    ?= qemu-system-riscv64
CC      := clang
OBJCOPY := llvm-objcopy
OBJDUMP := riscv64-unknown-elf-objdump

# ========================
# Mode
# ========================
# sim / fpga_mem / sbi / psc
MODE ?= sim

ifeq ($(MODE),sim)
  BOOT_FLOW     := direct
  RUN_QEMU      := 1
  KCPPFLAGS     := -DBSS_CLEAR_OFF=1
  USER_BASE_VAL := 0x00400000

else ifeq ($(MODE),fpga_mem)
  BOOT_FLOW     := direct
  RUN_QEMU      := 1
  KCPPFLAGS     := -DBSS_CLEAR_OFF=0
  USER_BASE_VAL := 0x00400000

else ifeq ($(MODE),sbi)
  BOOT_FLOW     := direct
  RUN_QEMU      := 1
  KCPPFLAGS     := -DUSE_SBI_CONSOLE
  USER_BASE_VAL := 0x01000000

else ifeq ($(MODE),psc)
  BOOT_FLOW     := loader
  RUN_QEMU      := 0
  KCPPFLAGS     := -DBSS_CLEAR_OFF=0
  USER_BASE_VAL := 0x00400000

else
  $(error Unknown MODE '$(MODE)' (use: sim | fpga_mem | sbi | psc))
endif

# ========================
# BIOS path (OpenSBI)
# ========================
QEMU_BIOS32 ?= $(shell \
  if [ -f $(Src)/opensbi-riscv32-generic-fw_dynamic.bin ]; then \
    echo $(Src)/opensbi-riscv32-generic-fw_dynamic.bin; \
  elif [ -f /usr/lib/riscv32-linux-gnu/opensbi/generic/fw_dynamic.bin ]; then \
    echo /usr/lib/riscv32-linux-gnu/opensbi/generic/fw_dynamic.bin; \
  elif [ -f /usr/share/qemu/opensbi-riscv32-generic-fw_dynamic.bin ]; then \
    echo /usr/share/qemu/opensbi-riscv32-generic-fw_dynamic.bin; \
  fi)

# ========================
# USER_BASE
# ========================
DEFUSERBASE := -Wl,-defsym,USER_BASE=$(USER_BASE_VAL)
DUSERBASE   := -DUSER_BASE=$(USER_BASE_VAL)

# ========================
# ARCH / FLAGS
# ========================
ARCH := \
	-march=rv32im_zicsr_zifencei \
	-mabi=ilp32 \
	-mno-relax

CFLAGS ?= \
	-std=c11 \
	-O2 \
	-g3 \
	-Wall \
	-Wextra \
	--target=riscv64-unknown-elf \
	$(ARCH) \
	-fno-stack-protector \
	-ffreestanding \
	-nostdlib \
	-fomit-frame-pointer \
	-mstrict-align

LDFLAGS_USER := \
	-Wl,-T$(Src)/user.ld \
	-Wl,-Map=$(Build)/shell.map \
	-Wl,--no-relax

LDFLAGS_KERNEL := \
	-Wl,-Map=$(Build)/kernel.map \
	-Wl,--no-relax

# ========================
# Builtins
# ========================
GCC_PREFIX ?= riscv64-unknown-elf

# ★ 必ず RV32IM / ILP32 の libgcc を取得
LIBGCC := $(shell \
	$(GCC_PREFIX)-gcc \
	-march=rv32im \
	-mabi=ilp32 \
	-print-libgcc-file-name 2>/dev/null)

CLANG_RES := $(shell $(CC) --print-resource-dir 2>/dev/null)
CRT_BUILTINS := $(CLANG_RES)/lib/linux/libclang_rt.builtins-riscv32.a

ifeq ($(LIBGCC),)
  ifneq ("$(wildcard $(CRT_BUILTINS))","")
    BUILTINS_LIB := $(CRT_BUILTINS)
  else
    $(error RV32 libgcc / compiler-rt が見つかりません)
  endif
else
  BUILTINS_LIB := $(LIBGCC)
endif

# ========================
# Sources
# ========================

# 旧shellソース。
# MicroPythonモードでは直接ビルドしないが、
# 将来戻せるよう定義だけ残す。
SRCS_USER := \
	$(Src)/shell.c \
	$(Src)/user.c \
	$(Src)/fat32.c

SRCS_KERNEL := \
	$(Src)/kernel.c \
	$(Src)/common.c \
	$(Src)/dma.c \
	$(Src)/synap_api.c \
	$(Src)/sdcard_api.c \
	$(Src)/mic_api.c \
	$(Src)/lcd_api.c \
	$(Src)/fft_api.c \
	$(Src)/mem_test.c \
	$(Src)/speech_recognition_api.c

SRCS_MBIOS := $(Src)/psc_mbios.S

# ========================
# File names
# ========================

# ★ 名前は従来通り shell.bin / shell.bin.o を維持する。
# ★ 中身だけ MicroPython にする。
USER_BIN  := $(Build)/shell.bin
USER_BINO := $(Build)/shell.bin.o
USER_MEM  := $(Build)/user.mem

KERNEL_ELF := $(Build)/kernel.elf
KERNEL_BIN := $(Build)/kernel.bin
MEM_FILE   := $(Build)/kernel.mem

RISCV_CLANG  := clang
RISCV_TARGET := --target=riscv64-unknown-elf
RISCV_ARCH   := -march=rv32im_zicsr_zifencei -mabi=ilp32

# ========================
# compiler helper objects
# ========================
$(Build)/mulsi3.o: $(Src)/mulsi3.c | $(Build)
	$(RISCV_CLANG) \
		$(RISCV_TARGET) \
		$(RISCV_ARCH) \
		-O2 \
		-ffreestanding \
		-nostdlib \
		-c $< -o $@

$(Build)/divmodsi3.o: $(Src)/divmodsi3.c | $(Build)
	$(RISCV_CLANG) \
		$(RISCV_TARGET) \
		$(RISCV_ARCH) \
		-O2 \
		-ffreestanding \
		-nostdlib \
		-c $< -o $@

# ========================
# BootROM
# ========================
BOOT_ELF := $(Build)/bootrom.elf
BOOT_BIN := $(Build)/bootrom.bin
BOOT_MEM := $(Build)/bootrom.mem

ifeq ($(BOOT_FLOW),loader)
  BIOS_FLAGS := -DUSE_BOOTLOADER
else
  BIOS_FLAGS :=
endif

$(BOOT_ELF): $(Build) $(SRCS_MBIOS) $(Src)/bootrom.ld
	$(CC) $(CFLAGS) $(BIOS_FLAGS) \
		-Wl,-T$(Src)/bootrom.ld \
		-o $@ \
		$(SRCS_MBIOS) \
		$(BUILTINS_LIB)

$(BOOT_BIN): $(BOOT_ELF)
	$(OBJCOPY) -O binary $< $@

$(BOOT_MEM): $(BOOT_BIN)
	hexdump -v -e '1/4 "%08x\n"' $(BOOT_BIN) > $(BOOT_MEM)
	@echo "[BOOTROM] $(BOOT_MEM) generated."

# ========================
# Boot Loader
# ========================
SRCS_BOOT := \
	$(Src)/bootloader_entry.S \
	$(Src)/bootloader.c \
	$(Src)/common.c \
	$(Src)/sdcard_api.c

BOOTLOADER_ELF := $(Build)/bootloader.elf
BOOTLOADER_BIN := $(Build)/bootloader.bin
BOOTLOADER_MEM := $(Build)/bootloader.mem

$(BOOTLOADER_ELF): $(Build) $(SRCS_BOOT)
	$(CC) $(CFLAGS) \
		-Wl,-T$(Src)/bootloader.ld \
		-Wl,-Map=$(Build)/bootloader.map \
		-o $@ \
		$(SRCS_BOOT) \
		$(BUILTINS_LIB)

$(BOOTLOADER_BIN): $(BOOTLOADER_ELF)
	$(OBJCOPY) -O binary $< $@

$(BOOTLOADER_MEM): $(BOOTLOADER_BIN)
	hexdump -v -e '1/4 "%08x\n"' $< > $@
	@echo "[BOOTLOADER] $@ generated."

# ========================
# Boot Loader FAT32 Ver.
# ========================
SRCS_BOOT_FAT32 := \
	$(Src)/bootloader_entry.S \
	$(Src)/bootloader_fat32.c \
	$(Src)/common.c \
	$(Src)/sdcard_api.c \
	$(Src)/boot_fat32.c

BOOTLOADER_FAT32_ELF := $(Build)/bootloader_fat32.elf
BOOTLOADER_FAT32_BIN := $(Build)/bootloader_fat32.bin
BOOTLOADER_FAT32_MEM := $(Build)/bootloader_fat32.mem

$(BOOTLOADER_FAT32_ELF): $(Build) $(SRCS_BOOT_FAT32)
	$(CC) $(CFLAGS) \
		-Wl,-T$(Src)/bootloader.ld \
		-Wl,-Map=$(Build)/bootloader.map \
		-o $@ \
		$(SRCS_BOOT_FAT32) \
		$(BUILTINS_LIB)

$(BOOTLOADER_FAT32_BIN): $(BOOTLOADER_FAT32_ELF)
	$(OBJCOPY) -O binary $< $@

$(BOOTLOADER_FAT32_MEM): $(BOOTLOADER_FAT32_BIN)
	hexdump -v -e '1/4 "%08x\n"' $< > $@
	@echo "[BOOTLOADER] $@ generated."

# ============================================================
# USER image selection
# ============================================================
#
# 使い方:
#
#   make USER_MODE=shell sim_mem
#   make USER_MODE=micropython sim_mem
#
# デフォルトは MicroPython
#
USER_MODE ?= micropython
#USER_MODE ?= shell

# ------------------------------------------------------------
# MicroPython source
# ------------------------------------------------------------
MICROPY_DIR := ../micropython/ports/psc
MICROPY_BIN := $(MICROPY_DIR)/build/micropython.bin

$(MICROPY_BIN):
	$(MAKE) -C $(MICROPY_DIR) build/micropython.bin

# ------------------------------------------------------------
# USER_MODE = shell
# ------------------------------------------------------------
ifeq ($(USER_MODE),shell)

USER_ELF := $(Build)/shell.elf

$(USER_ELF): $(Build) $(SRCS_USER) $(Build)/divmodsi3.o
	$(CC) $(CFLAGS) $(DUSERBASE) $(DEFUSERBASE) \
		$(LDFLAGS_USER) \
		-o $@ \
		$(SRCS_USER) \
		$(Build)/divmodsi3.o

$(USER_BIN): $(USER_ELF)
	$(OBJCOPY) \
		--set-section-flags .bss=alloc,contents \
		-O binary \
		$< $@
	@echo "[USER] PSC-OS shell -> $(USER_BIN)"

# ------------------------------------------------------------
# USER_MODE = micropython
# ------------------------------------------------------------
else ifeq ($(USER_MODE),micropython)

# shell.bin という名前は維持する。
# 中身だけ MicroPython に置き換える。
$(USER_BIN): $(MICROPY_BIN) | $(Build)
	cp $(MICROPY_BIN) $(USER_BIN)
	@echo "[USER] MicroPython -> $(USER_BIN)"

else

$(error USER_MODE=$(USER_MODE) is invalid. Use shell or micropython)

endif

# ------------------------------------------------------------
# Common USER outputs
# ------------------------------------------------------------
#
# shell / MicroPython のどちらでも最終形は同じ:
#
#   build/shell.bin
#        |
#        +--> build/shell.bin.o -> kernel.elf
#        |
#        +--> build/user.mem    -> RTL
#
# kernel.c は従来通り
#
#   _binary_shell_bin_start
#   _binary_shell_bin_end
#
# を使用できる。
#

$(USER_BINO): $(USER_BIN) | $(Build)
	cd $(Build) && \
	$(OBJCOPY) \
		--binary-architecture=riscv \
		-I binary \
		-O elf32-littleriscv \
		shell.bin \
		shell.bin.o \
		--rename-section .data=.rodata,alloc,load,readonly,data

$(USER_MEM): $(USER_BIN) | $(Build)
	hexdump -v -e '1/4 "%08x\n"' $(USER_BIN) > $(USER_MEM)
	@echo "[USER] USER_MODE=$(USER_MODE) -> $(USER_MEM)"

# ========================
# Kernel linker selection
# ========================
ifeq ($(MODE),sim)
$(KERNEL_ELF): KERNEL_LD := $(Src)/kernel_fpga.ld
kernel_mem:    KERNEL_LD := $(Src)/kernel_fpga.ld

else ifeq ($(MODE),fpga_mem)
$(KERNEL_ELF): KERNEL_LD := $(Src)/kernel_fpga.ld
kernel_mem:    KERNEL_LD := $(Src)/kernel_fpga.ld

else ifeq ($(MODE),sbi)
$(KERNEL_ELF): KERNEL_LD := $(Src)/kernel.ld
kernel_mem:    KERNEL_LD := $(Src)/kernel.ld

else ifeq ($(MODE),psc)
$(KERNEL_ELF): KERNEL_LD := $(Src)/kernel_fpga.ld
kernel_mem:    KERNEL_LD := $(Src)/kernel_fpga.ld
endif

# ========================
# Kernel
# ========================
#
# ★ shell.bin.o を従来通りkernelへリンクする。
# ★ ただし shell.bin の中身は MicroPython。
#
# これにより kernel.c は変更不要。
#
$(KERNEL_ELF): \
	$(Build) \
	$(SRCS_KERNEL) \
	$(USER_BINO) \
	$(Build)/divmodsi3.o

	$(CC) $(CFLAGS) $(KCPPFLAGS) $(DUSERBASE) \
		-Wl,-T$(KERNEL_LD) \
		$(LDFLAGS_KERNEL) \
		-o $@ \
		$(SRCS_KERNEL) \
		$(USER_BINO) \
		$(Build)/divmodsi3.o

kernel_mem: $(KERNEL_ELF)
	$(OBJCOPY) \
		--strip-debug \
		--strip-unneeded \
		-O binary \
		$(KERNEL_ELF) \
		$(KERNEL_BIN)

	@size=$$(stat -c%s $(KERNEL_BIN)); \
	pad=$$(( (4-($$size%4))%4 )); \
	[ $$pad -ne 0 ] && \
	dd if=/dev/zero bs=1 count=$$pad status=none >> $(KERNEL_BIN) || true

	hexdump -v -e '1/4 "%08x\n"' \
		$(KERNEL_BIN) > $(MEM_FILE)

	@echo "[KERNEL] $(MEM_FILE) generated."

# ========================
# Unified MEM
# ========================
.PHONY: sim_mem fpga_mem fpga_boot fpga_fat32_boot

sim_mem:
	@echo "[SIM] BootROM + Kernel + USER_MODE=$(USER_MODE)"
	$(MAKE) MODE=sim USER_MODE=$(USER_MODE) $(BOOT_MEM)
	$(MAKE) MODE=sim USER_MODE=$(USER_MODE) kernel_mem
	$(MAKE) MODE=sim USER_MODE=$(USER_MODE) $(USER_MEM)

fpga_mem:
	@echo "[FPGA_MEM] BootROM + Kernel + USER_MODE=$(USER_MODE)"
	$(MAKE) MODE=fpga_mem USER_MODE=$(USER_MODE) $(BOOT_MEM)
	$(MAKE) MODE=fpga_mem USER_MODE=$(USER_MODE) kernel_mem
	$(MAKE) MODE=fpga_mem USER_MODE=$(USER_MODE) $(USER_MEM)

fpga_boot:
	@echo "[FPGA] BootROM + Bootloader"
	$(MAKE) MODE=psc $(BOOT_MEM)
	$(MAKE) MODE=psc $(BOOTLOADER_MEM)

fpga_fat32_boot:
	@echo "[FPGA] BootROM + FAT32 Bootloader"
	$(MAKE) MODE=psc $(BOOT_MEM)
	$(MAKE) MODE=psc $(BOOTLOADER_FAT32_MEM)

# ========================
# Main Targets
# ========================
.PHONY: all

all: $(KERNEL_ELF)

.PHONY: sbi psc

sbi:
	$(MAKE) clean
	$(MAKE) MODE=sbi all

psc:
	$(MAKE) clean
	$(MAKE) MODE=psc all

# ========================
# Run
# ========================
run: $(KERNEL_ELF)
ifeq ($(RUN_QEMU),1)
	$(QEMU) \
		-machine virt \
		-m 128M \
		-bios $(QEMU_BIOS32) \
		-nographic \
		-serial mon:stdio \
		--no-reboot \
		-kernel $(KERNEL_ELF)
else
	@echo "PSC モードのため QEMU 起動しません（FPGA専用）"
endif

# ========================
# Disassemble
# ========================
RISCV_OBJDUMP := riscv64-unknown-elf-objdump

disasm:
	@echo "[INFO] Rebuilding kernel.elf in PSC mode"
	$(MAKE) MODE=psc $(KERNEL_ELF)

	@echo "[INFO] Disassembling BootROM"
	$(RISCV_OBJDUMP) -D -S \
		$(Build)/bootrom.elf > $(Build)/bootrom.S

	@echo "[INFO] Disassembling Kernel"
	$(RISCV_OBJDUMP) -D -S \
		$(Build)/kernel.elf > $(Build)/kernel.S

	@echo "[OK] Generated disassembly"

disasm_bootloader:
	$(RISCV_OBJDUMP) -D -S \
		$(Build)/bootloader.elf > $(Build)/bootloader.S
	@echo "[OK] Generated $(Build)/bootloader.S"

disasm_bootloader_fat32:
	$(RISCV_OBJDUMP) -D -S \
		$(Build)/bootloader_fat32.elf > \
		$(Build)/bootloader_fat32.S
	@echo "[OK] Generated $(Build)/bootloader_fat32.S"

# ========================
# Clean
# ========================
.PHONY: clean

clean:
	rm -rf $(Build)