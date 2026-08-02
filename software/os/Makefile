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
# Mode (sbi default / psc)
# ========================
# sim / sbi / psc
MODE ?= sim

ifeq ($(MODE),sim)
  BOOT_FLOW     := direct
  RUN_QEMU      := 1
  #KCPPFLAGS     :=
  KCPPFLAGS     := -DBSS_CLEAR_OFF=1
  USER_BASE_VAL := 0x00400000

else ifeq ($(MODE),fpga_mem)
  BOOT_FLOW     := direct
  RUN_QEMU      := 1
  #KCPPFLAGS     :=
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
  #KCPPFLAGS     :=
  KCPPFLAGS     := -DBSS_CLEAR_OFF=0
  USER_BASE_VAL := 0x00400000

else
  $(error Unknown MODE '$(MODE)' (use: sim | fpga_mem |sbi | psc))
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
# USER_BASE define
# ========================
DEFUSERBASE := -Wl,-defsym,USER_BASE=$(USER_BASE_VAL)
DUSERBASE   := -DUSER_BASE=$(USER_BASE_VAL)

# ========================
# ARCH / FLAGS
# ========================
ARCH := -march=rv32im_zicsr_zifencei -mabi=ilp32 -mno-relax

CFLAGS ?= -std=c11 -O2 -g3 -Wall -Wextra \
          --target=riscv64-unknown-elf $(ARCH) \
          -fno-stack-protector -ffreestanding -nostdlib \
		  -fomit-frame-pointer \
		  -mstrict-align

# ★ LDFLAGS_KERNEL は後でターゲット依存で上書きされる
LDFLAGS_USER := -Wl,-T$(Src)/user.ld   -Wl,-Map=$(Build)/shell.map  -Wl,--no-relax
#LDFLAGS_KERNEL := -Wl,-Map=$(Build)/kernel.map -Wl,--no-relax
#LDFLAGS_KERNEL = -Wl,-T$$(KERNEL_LD) -Wl,-Map=$(Build)/kernel.map -Wl,--no-relax
LDFLAGS_KERNEL = -Wl,-Map=$(Build)/kernel.map -Wl,--no-relax



# ========================
# Builtins autodetect
# ========================
GCC_PREFIX ?= riscv64-unknown-elf
#LIBGCC := $(shell $(GCC_PREFIX)-gcc -print-libgcc-file-name 2>/dev/null)
LIBGCC := $(shell riscv64-unknown-elf-gcc -print-libgcc-file-name)
CLANG_RES := $(shell $(CC) --print-resource-dir 2>/dev/null)
CRT_BUILTINS := $(CLANG_RES)/lib/linux/libclang_rt.builtins-riscv32.a

ifeq ($(LIBGCC),)
  ifneq ("$(wildcard $(CRT_BUILTINS))","")
    BUILTINS_LIB := $(CRT_BUILTINS)
  else
    $(error libgcc も compiler-rt も見つかりません)
  endif
else
  BUILTINS_LIB := $(LIBGCC)
endif

# ========================
# Sources
# ========================
SRCS_USER   := $(Src)/shell.c $(Src)/user.c $(Src)/fat32.c
SRCS_KERNEL := $(Src)/kernel.c $(Src)/common.c $(Src)/dma.c $(Src)/synap_api.c $(Src)/sdcard_api.c \
							   $(Src)/mic_api.c $(Src)/lcd_api.c $(Src)/fft_api.c $(Src)/mem_test.c \
							   $(Src)/speech_recognition_api.c
SRCS_MBIOS  := $(Src)/psc_mbios.S

USER_ELF    := $(Build)/shell.elf
USER_BIN    := $(Build)/shell.bin
USER_BINO   := $(Build)/shell.bin.o
KERNEL_ELF  := $(Build)/kernel.elf
KERNEL_BIN  := $(Build)/kernel.bin
MEM_FILE    := $(Build)/kernel.mem

RISCV_CLANG := clang
RISCV_TARGET := --target=riscv64-unknown-elf
RISCV_ARCH   := -march=rv32im_zicsr_zifencei -mabi=ilp32

$(Build)/mulsi3.o: $(Src)/mulsi3.c | $(Build)
	$(RISCV_CLANG) $(RISCV_TARGET) $(RISCV_ARCH) \
		-O2 -ffreestanding -nostdlib -c $< -o $@

$(Build)/divmodsi3.o: $(Src)/divmodsi3.c | $(Build)
	$(RISCV_CLANG) $(RISCV_TARGET) $(RISCV_ARCH) \
		-O2 -ffreestanding -nostdlib -c $< -o $@

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
	$(CC) $(CFLAGS)  $(BIOS_FLAGS) -Wl,-T$(Src)/bootrom.ld \
		-o $@ $(SRCS_MBIOS) $(BUILTINS_LIB)

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
	    -o $@ $(SRCS_BOOT) $(BUILTINS_LIB)

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
	    -o $@ $(SRCS_BOOT_FAT32) $(BUILTINS_LIB)

$(BOOTLOADER_FAT32_BIN): $(BOOTLOADER_FAT32_ELF)
	$(OBJCOPY) -O binary $< $@

$(BOOTLOADER_FAT32_MEM): $(BOOTLOADER_FAT32_BIN)
	hexdump -v -e '1/4 "%08x\n"' $< > $@
	@echo "[BOOTLOADER] $@ generated."

# ========================
# Kernel
# ========================
$(USER_ELF): $(Build) $(SRCS_USER) $(Build)/divmodsi3.o
	$(CC) $(CFLAGS) $(KCPPFLAGS) $(DUSERBASE) $(DEFUSERBASE) \
		$(LDFLAGS_USER) -o $@ $(SRCS_USER) \
		$(Build)/divmodsi3.o

$(USER_BIN): $(USER_ELF)
	$(OBJCOPY) --set-section-flags .bss=alloc,contents -O binary $< $@

$(USER_BINO): $(USER_BIN)
	cd $(Build) && \
	$(OBJCOPY) \
	    --binary-architecture=riscv \
	    -I binary -O elf32-littleriscv shell.bin shell.bin.o \
	    --rename-section .data=.rodata,alloc,load,readonly,data
		
USER_MEM := $(Build)/user.mem

$(USER_MEM): $(USER_BIN)
	hexdump -v -e '1/4 "%08x\n"' $< > $@
	@echo "[USER] $@ generated."

# ------------------------
# ★ KERNEL_LD をターゲット依存で切替（安全版）
# ------------------------
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

$(KERNEL_ELF): $(Build) $(SRCS_KERNEL) $(USER_BINO) $(Build)/divmodsi3.o
	$(CC) $(CFLAGS) $(KCPPFLAGS) $(DUSERBASE) \
		-Wl,-T$(KERNEL_LD) $(LDFLAGS_KERNEL) \
		-o $@ $(SRCS_KERNEL) $(USER_BINO) \
		$(Build)/divmodsi3.o

kernel_mem: $(KERNEL_ELF)
	$(OBJCOPY) --strip-debug --strip-unneeded -O binary $(KERNEL_ELF) $(KERNEL_BIN)
	@size=$$(stat -c%s $(KERNEL_BIN)); pad=$$(( (4-($$size%4))%4 )); \
	[ $$pad -ne 0 ] && dd if=/dev/zero bs=1 count=$$pad status=none >> $(KERNEL_BIN) || true
	hexdump -v -e '1/4 "%08x\n"' $(KERNEL_BIN) > $(MEM_FILE)
	@echo "[KERNEL] $(MEM_FILE) generated."

# ========================
# Unified MEM (boot + kernel + user)
# ========================
.PHONY: sim_mem fpga_boot
sim_mem:
	@echo "[SIM] BootROM + Kernel + User"
	$(MAKE) MODE=sim $(BOOT_MEM)
	$(MAKE) MODE=sim kernel_mem
	$(MAKE) MODE=sim $(USER_MEM)

fpga_mem:
	@echo "[SIM] BootROM + Kernel + User"
	$(MAKE) MODE=fpga_mem $(BOOT_MEM)
	$(MAKE) MODE=fpga_mem kernel_mem
	$(MAKE) MODE=fpga_mem $(USER_MEM)

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
	$(QEMU) -machine virt -m 128M -bios $(QEMU_BIOS32) \
	    -nographic -serial mon:stdio --no-reboot \
	    -kernel $(KERNEL_ELF)
else
	@echo "PSC モードのため QEMU 起動しません（FPGA専用）"
endif

# ============================================================
# Disassemble BootROM / Kernel
# ============================================================
RISCV_OBJDUMP = riscv64-unknown-elf-objdump

disasm: 
	@echo "[INFO] Rebuilding kernel.elf in PSC mode for disassembly"
	$(MAKE) MODE=psc $(KERNEL_ELF)

	@echo "[INFO] Disassembling BootROM"
	$(RISCV_OBJDUMP) -D -S ./build/bootrom.elf > ./build/bootrom.S
	@echo "[OK] Generated ./build/bootrom.S"

	@echo "[INFO] Disassembling Kernel"
	$(RISCV_OBJDUMP) -D -S ./build/kernel.elf > ./build/kernel.S
	@echo "[OK] Generated ./build/kernel.S"

	@echo "[INFO] Disassembling Shell"
	$(RISCV_OBJDUMP) -D -S ./build/shell.elf > ./build/shell.S
	@echo "[OK] Generated ./build/shell.S"

disasm_bootloader: 
	@echo "[INFO] Disassembling Bootloader"
	$(RISCV_OBJDUMP) -D -S ./build/bootloader.elf > ./build/bootloader.S
	@echo "[OK] Generated ./build/bootloader.S"

disasm_bootloader_fat32: 
	@echo "[INFO] Disassembling Bootloader"
	$(RISCV_OBJDUMP) -D -S ./build/bootloader_fat32.elf > ./build/bootloader_fat32.S
	@echo "[OK] Generated ./build/bootloader.S"

# ========================
# Clean
# ========================
clean:
	rm -rf $(Build)