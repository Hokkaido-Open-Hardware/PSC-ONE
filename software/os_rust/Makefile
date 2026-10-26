# Independent Rust build. No target cleans or changes the original OS tree.
.DEFAULT_GOAL := all
ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
OS := $(abspath $(ROOT)/../os)
BUILD := $(ROOT)/build
TARGET := riscv32im-unknown-none-elf
# rtl: preload both .mem images; sd: read USER.MEM from FAT32 on cold boot.
USER_SOURCE ?= rtl
CPU_VERSION ?= v1
USER_FEATURES = firmware,user$(if $(filter v1,$(CPU_VERSION)),$(comma)pulp)
ifeq ($(filter $(USER_SOURCE),rtl sd),)
$(error USER_SOURCE must be rtl or sd)
endif
comma := ,
KERNEL_FEATURES := firmware$(if $(filter sd,$(USER_SOURCE)),$(comma)sd-user)
CARGO ?= cargo
OBJCOPY ?= llvm-objcopy
CC := clang
MP_PORT := $(OS)/micropython/ports/psc
MP_BUILD ?= $(BUILD)/micropython
MP_LIB := $(MP_BUILD)/libmicropython_psc.a
MP_PRINTF := $(MP_BUILD)/shared/libc/printf.o
LIBDIR := /usr/lib/picolibc/riscv64-unknown-elf/lib/rv32i/ilp32
LIBGCC := $(shell riscv64-unknown-elf-gcc -march=rv32im -mabi=ilp32 -print-libgcc-file-name)
RUST_SOURCES := $(shell rg --files $(ROOT)/src $(ROOT)/assets)
ARCH := --target=riscv32-unknown-elf -march=rv32im_zicsr_zifencei -mabi=ilp32 -mno-relax
CFLAGS := $(ARCH) -Os -ffreestanding -fno-stack-protector -ffunction-sections -fdata-sections --sysroot=/usr/lib/picolibc/riscv64-unknown-elf
.PHONY: all check verify micropython config FORCE
config: $(BUILD)/kernel.config

# Update the stamp in its own recipe. An order-only helper can change the file
# after Make has cached its old mtime, leaving the previous boot mode in kernel.mem.
# FORCE checks the requested mode each time; unchanged contents preserve its mtime.
FORCE:

$(BUILD)/kernel.config: FORCE
	@python3 -c 'from pathlib import Path; import sys; p=Path(sys.argv[1]); s=sys.argv[2]; p.parent.mkdir(parents=True,exist_ok=True); p.write_text(s) if not p.exists() or p.read_text()!=s else None' $(BUILD)/kernel.config "$(USER_SOURCE)"

$(BUILD)/user.config: FORCE
	@python3 -c 'from pathlib import Path; import sys; p=Path(sys.argv[1]); s=sys.argv[2]; p.parent.mkdir(parents=True,exist_ok=True); p.write_text(s) if not p.exists() or p.read_text()!=s else None' $@ "$(USER_FEATURES)"

all: $(BUILD)/kernel.mem $(BUILD)/user.mem

$(BUILD):
	mkdir -p $@

# Build the current MicroPython checkout into os_rust/build only. The outer port
# wrapper may apply a Git patch, so explicitly enter its build body instead.
# Existing PSC source patches must already be present; no Git mutation is performed.
# Build core/generated headers first: main_embedded.o in the original port lacks
# a root_pointers.h prerequisite and can race on a fresh parallel build.
micropython: | $(BUILD)
	$(MAKE) -C $(MP_PORT) BUILD=$(MP_BUILD) PSC_PATCH_READY_FOR=$(MP_PORT)/Makefile all
	$(MAKE) -C $(MP_PORT) BUILD=$(MP_BUILD) PSC_PATCH_READY_FOR=$(MP_PORT)/Makefile embedded

$(MP_LIB) $(MP_PRINTF): | micropython
	@test -f "$@"

# Copy unchanged vendor sources next to our fixed configuration. Quoted includes
# must resolve locally, otherwise the upstream RGB565 configuration would win.
$(BUILD)/tjpgd.o: $(OS)/third_party/tjpgd/src/tjpgd.c $(OS)/third_party/tjpgd/src/tjpgd.h $(ROOT)/tools/tjpgdcnf.h | $(BUILD)
	mkdir -p $(BUILD)/tjpgd
	cp $(OS)/third_party/tjpgd/src/tjpgd.c $(OS)/third_party/tjpgd/src/tjpgd.h $(ROOT)/tools/tjpgdcnf.h $(BUILD)/tjpgd/
	$(CC) $(CFLAGS) -I$(BUILD)/tjpgd -c $(BUILD)/tjpgd/tjpgd.c -o $@

$(BUILD)/user.elf: $(BUILD)/user.config $(RUST_SOURCES) $(ROOT)/Cargo.toml $(ROOT)/link/user.ld $(BUILD)/tjpgd.o $(MP_LIB) $(MP_PRINTF) $(ROOT)/Makefile
	$(CARGO) rustc --offline --manifest-path $(ROOT)/Cargo.toml --target $(TARGET) --release --features $(USER_FEATURES) --bin user -- -C link-arg=-T$(ROOT)/link/user.ld -C link-arg=--no-relax -C link-arg=$(BUILD)/tjpgd.o -C link-arg=$(MP_LIB) -C link-arg=$(MP_PRINTF) -C link-arg=$(LIBDIR)/libm.a -C link-arg=$(LIBDIR)/libc.a -C link-arg=$(LIBGCC) -C link-arg=-Map=$(BUILD)/user.map
	cp $(ROOT)/target/$(TARGET)/release/user $@

$(BUILD)/shell.bin: $(BUILD)/user.elf
	$(OBJCOPY) --set-section-flags .bss=alloc,contents -O binary $< $@

$(BUILD)/kernel.elf: $(RUST_SOURCES) $(ROOT)/Cargo.toml $(ROOT)/link/kernel.ld $(BUILD)/shell.bin $(BUILD)/kernel.config $(ROOT)/Makefile
	$(CARGO) rustc --offline --manifest-path $(ROOT)/Cargo.toml --target $(TARGET) --release --features $(KERNEL_FEATURES) --bin kernel -- -C link-arg=-T$(ROOT)/link/kernel.ld -C link-arg=--no-relax -C link-arg=--defsym=__shell_image_size=$$(stat -c %s $(BUILD)/shell.bin) -C link-arg=-Map=$(BUILD)/kernel.map
	cp $(ROOT)/target/$(TARGET)/release/kernel $@

$(BUILD)/kernel.bin: $(BUILD)/kernel.elf
	$(OBJCOPY) -O binary $< $@

$(BUILD)/user.mem: $(BUILD)/shell.bin $(ROOT)/tools/bin_to_mem.py
	python3 $(ROOT)/tools/bin_to_mem.py $< $@

$(BUILD)/kernel.mem: $(BUILD)/kernel.bin $(ROOT)/tools/bin_to_mem.py
	python3 $(ROOT)/tools/bin_to_mem.py $< $@

verify: all
	python3 $(ROOT)/tools/verify_images.py

check:
	python3 $(ROOT)/tools/generate_tflite_schema.py --check
	$(CARGO) fmt --manifest-path $(ROOT)/Cargo.toml -- --check
	$(CARGO) test --offline --manifest-path $(ROOT)/Cargo.toml --tests
