# Independent Rust build. No target cleans or changes the original OS tree.
.DEFAULT_GOAL := all
ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
OS := $(abspath $(ROOT)/../os)
BUILD = $(ROOT)/build$(if $(filter psc_one_rv64,$(BOARD)),/psc_one_rv64)
CPU_VERSION ?= v1
BOARD ?= $(if $(filter rv64,$(CPU_VERSION)),psc_one_rv64,psc_one)
ifeq ($(filter $(BOARD),psc_one psc_one_rv64),)
$(error Unsupported BOARD '$(BOARD)' (use psc_one | psc_one_rv64))
endif
BOARD_DIR := $(ROOT)/src/board/$(BOARD)
include $(BOARD_DIR)/board.mk
BOARD_FILES := $(wildcard $(BOARD_DIR)/*)
# Direct RTL preload is no longer supported, including stale command lines.
ifneq ($(filter-out sd,$(USER_SOURCE)),)
$(error USER_SOURCE=rtl is removed; the kernel reads USER.MEM from SD)
endif
comma := ,
MICROPYTHON ?= 0
ifeq ($(filter $(MICROPYTHON),0 1),)
$(error MICROPYTHON must be 0 or 1)
endif
USER_FEATURES = firmware,user$(if $(and $(filter psc_one,$(BOARD)),$(filter v1,$(CPU_VERSION))),$(comma)pulp)$(if $(filter 1,$(MICROPYTHON)),$(comma)micropython)
KERNEL_FEATURES = firmware$(if $(filter 1,$(MICROPYTHON)),$(comma)micropython)
CARGO ?= cargo
OBJCOPY ?= llvm-objcopy
CC := clang
MP_PORT := $(OS)/micropython/ports/psc
MP_BUILD ?= $(BUILD)/micropython
MP_LIB := $(MP_BUILD)/libmicropython_psc.a
MP_PRINTF := $(MP_BUILD)/shared/libc/printf.o
ifeq ($(MICROPYTHON),1)
MP_DEPS := $(MP_LIB) $(MP_PRINTF)
MP_LINK_FLAGS := $(foreach file,$(MP_DEPS),-C link-arg=$(file))
endif
RUST_SOURCES := $(shell rg --files $(ROOT)/src $(ROOT)/assets)
CFLAGS := $(ARCH) -Os -ffreestanding -fno-stack-protector -ffunction-sections -fdata-sections --sysroot=/usr/lib/picolibc/riscv64-unknown-elf
.PHONY: all check verify micropython config FORCE bios lib check-target print-config

# Apply board ISA flags to core/compiler_builtins as well as this crate. RV64IM
# has no prebuilt rustup core, so its board profile selects nightly build-std.
lib:
	RUSTFLAGS="$(RUSTFLAGS) $(BOARD_RUSTFLAGS)" $(CARGO) $(RUST_TOOLCHAIN) build --offline $(CARGO_TARGET_FLAGS) --manifest-path $(ROOT)/Cargo.toml --target $(TARGET) --release --lib

check-target:
	RUSTFLAGS="$(RUSTFLAGS) $(BOARD_RUSTFLAGS)" $(CARGO) $(RUST_TOOLCHAIN) check --offline $(CARGO_TARGET_FLAGS) --manifest-path $(ROOT)/Cargo.toml --target $(TARGET) --release --lib

print-config:
	@echo "BOARD=$(BOARD)"
	@echo "TARGET=$(TARGET)"
	@echo "ARCH=$(ARCH)"
	@echo "RUST_TOOLCHAIN=$(RUST_TOOLCHAIN)"
	@echo "BOARD_RUSTFLAGS=$(BOARD_RUSTFLAGS)"
	@echo "CARGO_TARGET_FLAGS=$(CARGO_TARGET_FLAGS)"
	@echo "USER_FEATURES=$(USER_FEATURES)"

config: $(BUILD)/kernel.config

# Update the stamp in its own recipe. An order-only helper can change the file
# after Make has cached its old mtime, leaving the previous boot mode in kernel.mem.
# FORCE checks the requested mode each time; unchanged contents preserve its mtime.
FORCE:

$(BUILD)/kernel.config: FORCE
	@python3 -c 'from pathlib import Path; import sys; p=Path(sys.argv[1]); s=sys.argv[2]; p.parent.mkdir(parents=True,exist_ok=True); p.write_text(s) if not p.exists() or p.read_text()!=s else None' $(BUILD)/kernel.config "$(BOARD):kernel-sd:$(KERNEL_FEATURES)"

$(BUILD)/user.config: FORCE
	@python3 -c 'from pathlib import Path; import sys; p=Path(sys.argv[1]); s=sys.argv[2]; p.parent.mkdir(parents=True,exist_ok=True); p.write_text(s) if not p.exists() or p.read_text()!=s else None' $@ "$(BOARD):$(USER_FEATURES)"

all: $(BUILD)/kernel.mem $(BUILD)/user.mem $(BUILD)/image_layout.h bios

ifeq ($(BOARD),psc_one_rv64)
bios: $(BUILD)/bootrom.mem $(BUILD)/bootloader_fat32.mem

$(BUILD)/bootrom.elf: $(RUST_SOURCES) $(ROOT)/Cargo.toml $(BOARD_FILES) $(ROOT)/Makefile | $(BUILD)
	RUSTFLAGS="$(RUSTFLAGS) $(BOARD_RUSTFLAGS)" $(CARGO) $(RUST_TOOLCHAIN) rustc --offline $(CARGO_TARGET_FLAGS) --manifest-path $(ROOT)/Cargo.toml --target $(TARGET) --release --features firmware --bin bootrom -- -C link-arg=-T$(BOARD_DIR)/bootrom.ld -C link-arg=--no-relax
	cp $(ROOT)/target/$(TARGET)/release/bootrom $@

$(BUILD)/bootloader_fat32.elf: $(RUST_SOURCES) $(ROOT)/Cargo.toml $(BOARD_FILES) $(ROOT)/Makefile | $(BUILD)
	RUSTFLAGS="$(RUSTFLAGS) $(BOARD_RUSTFLAGS)" $(CARGO) $(RUST_TOOLCHAIN) rustc --offline $(CARGO_TARGET_FLAGS) --manifest-path $(ROOT)/Cargo.toml --target $(TARGET) --release --features firmware --bin bootloader_fat32 -- -C link-arg=-T$(BOARD_DIR)/bootloader.ld -C link-arg=--no-relax
	cp $(ROOT)/target/$(TARGET)/release/bootloader_fat32 $@

$(BUILD)/bootrom.bin: $(BUILD)/bootrom.elf
	$(OBJCOPY) -O binary $< $@
$(BUILD)/bootloader_fat32.bin: $(BUILD)/bootloader_fat32.elf
	$(OBJCOPY) -O binary $< $@
$(BUILD)/bootrom.mem: $(BUILD)/bootrom.bin $(ROOT)/tools/bin_to_mem.py
	python3 $(ROOT)/tools/bin_to_mem.py $< $@
$(BUILD)/bootloader_fat32.mem: $(BUILD)/bootloader_fat32.bin $(ROOT)/tools/bin_to_mem.py
	python3 $(ROOT)/tools/bin_to_mem.py $< $@
else
# Use the same unmodified SBI ROM and FAT32 kernel loader as the C OS.
# A separate directory prevents older Rust-specific loader artifacts being reused.
bios: | $(BUILD)
	$(MAKE) -C $(OS) PSC_PATCH_READY_FOR=$(OS)/Makefile Build=$(BUILD)/bios-sd fpga_fat32_boot
	cp $(foreach name,bootrom bootloader_fat32,$(foreach ext,elf bin mem,$(BUILD)/bios-sd/$(name).$(ext))) $(BUILD)/

endif

$(BUILD):
	mkdir -p $@

# Build the current MicroPython checkout into os_rust/build only. The outer port
# wrapper may apply a Git patch, so explicitly enter its build body instead.
# Existing PSC source patches must already be present; no Git mutation is performed.
# Build core/generated headers first: main_embedded.o in the original port lacks
# a root_pointers.h prerequisite and can race on a fresh parallel build.
micropython: | $(BUILD)
	$(MAKE) -C $(MP_PORT) BUILD=$(MP_BUILD) PSC_PATCH_READY_FOR=$(MP_PORT)/Makefile $(MP_BOARD_FLAGS) all
	$(MAKE) -C $(MP_PORT) BUILD=$(MP_BUILD) PSC_PATCH_READY_FOR=$(MP_PORT)/Makefile $(MP_BOARD_FLAGS) embedded

$(MP_LIB) $(MP_PRINTF): | micropython
	@test -f "$@"

# Copy unchanged vendor sources next to our fixed configuration. Quoted includes
# must resolve locally, otherwise the upstream RGB565 configuration would win.
$(BUILD)/tjpgd.o: $(OS)/third_party/tjpgd/src/tjpgd.c $(OS)/third_party/tjpgd/src/tjpgd.h $(ROOT)/tools/tjpgdcnf.h $(BOARD_FILES) | $(BUILD)
	mkdir -p $(BUILD)/tjpgd
	cp $(OS)/third_party/tjpgd/src/tjpgd.c $(OS)/third_party/tjpgd/src/tjpgd.h $(ROOT)/tools/tjpgdcnf.h $(BUILD)/tjpgd/
	$(CC) $(CFLAGS) -I$(BUILD)/tjpgd -c $(BUILD)/tjpgd/tjpgd.c -o $@

$(BUILD)/user.elf: $(BUILD)/user.config $(RUST_SOURCES) $(ROOT)/Cargo.toml $(BOARD_FILES) $(BOARD_DIR)/user.ld $(BUILD)/tjpgd.o $(MP_DEPS) $(ROOT)/Makefile
	RUSTFLAGS="$(RUSTFLAGS) $(BOARD_RUSTFLAGS)" $(CARGO) $(RUST_TOOLCHAIN) rustc --offline $(CARGO_TARGET_FLAGS) --manifest-path $(ROOT)/Cargo.toml --target $(TARGET) --release --features $(USER_FEATURES) --bin user -- -C link-arg=-L$(BOARD_DIR) -C link-arg=-T$(BOARD_DIR)/user.ld -C link-arg=--no-relax -C link-arg=$(BUILD)/tjpgd.o $(MP_LINK_FLAGS) -C link-arg=$(LIBDIR)/libm.a -C link-arg=$(LIBDIR)/libc.a -C link-arg=$(LIBGCC) -C link-arg=-Map=$(BUILD)/user.map
	cp $(ROOT)/target/$(TARGET)/release/user $@

$(BUILD)/shell.bin: $(BUILD)/user.elf
	$(OBJCOPY) --set-section-flags .bss=alloc,contents -O binary $< $@

$(BUILD)/kernel.elf: $(RUST_SOURCES) $(ROOT)/Cargo.toml $(BOARD_FILES) $(BOARD_DIR)/kernel.ld $(BUILD)/shell.bin $(BUILD)/kernel.config $(ROOT)/Makefile
	RUSTFLAGS="$(RUSTFLAGS) $(BOARD_RUSTFLAGS)" $(CARGO) $(RUST_TOOLCHAIN) rustc --offline $(CARGO_TARGET_FLAGS) --manifest-path $(ROOT)/Cargo.toml --target $(TARGET) --release --features $(KERNEL_FEATURES) --bin kernel -- -C link-arg=-L$(BOARD_DIR) -C link-arg=-T$(BOARD_DIR)/kernel.ld -C link-arg=--no-relax -C link-arg=--defsym=__shell_image_size=$$(stat -c %s $(BUILD)/shell.bin) -C link-arg=-Map=$(BUILD)/kernel.map
	cp $(ROOT)/target/$(TARGET)/release/kernel $@

$(BUILD)/kernel.bin: $(BUILD)/kernel.elf
	$(OBJCOPY) -O binary $< $@

$(BUILD)/user.mem: $(BUILD)/shell.bin $(ROOT)/tools/bin_to_mem.py
	python3 $(ROOT)/tools/bin_to_mem.py $< $@

$(BUILD)/kernel.mem: $(BUILD)/kernel.bin $(ROOT)/tools/bin_to_mem.py
	python3 $(ROOT)/tools/bin_to_mem.py $< $@

$(BUILD)/image_layout.h: $(BUILD)/kernel.elf $(BUILD)/kernel.bin $(BUILD)/shell.bin $(ROOT)/tools/boot_config.py
	python3 $(ROOT)/tools/boot_config.py --build $(BUILD)

verify: all
	python3 $(ROOT)/tools/verify_images.py --build $(BUILD) --board $(BOARD) --micropython $(MICROPYTHON)

check:
	python3 $(ROOT)/tools/generate_tflite_schema.py --check
	$(CARGO) fmt --manifest-path $(ROOT)/Cargo.toml -- --check
	$(CARGO) test --offline --manifest-path $(ROOT)/Cargo.toml --tests
