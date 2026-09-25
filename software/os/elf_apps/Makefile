.DEFAULT_GOAL := all

# Same Clang cross target, startup and linker layout as ../Makefile:user_elf.
CXX := clang++
READELF ?= riscv64-unknown-elf-readelf
USER_BASE_VAL ?= 0x00400000
STARTUP := ../tests/elf/start.S
LINKER_SCRIPT := ../tests/elf/user.ld
ARCH := --target=riscv64-unknown-elf -march=rv32im_zicsr_zifencei -mabi=ilp32
APP_FLAGS := $(ARCH) -O2 -ffreestanding -nostdlib -fno-exceptions -fno-rtti \
	-fno-threadsafe-statics -fno-use-cxa-atexit -fno-unwind-tables \
	-fno-asynchronous-unwind-tables -fno-pic -fno-pie \
	-fno-stack-protector -fomit-frame-pointer -mstrict-align \
	-mno-relax -msmall-data-limit=0 -Wall -Wextra
APP_LINK_FLAGS := -Wl,--defsym,USER_BASE=$(USER_BASE_VAL) \
	-Wl,-T,$(LINKER_SCRIPT) -Wl,--no-relax -Wl,-z,max-page-size=16 -Wl,-s
BIN_DIR := elf_bin
# Final executables use uppercase FAT32 8.3 names for direct SD-card copying.
APPS := $(addprefix $(BIN_DIR)/,HELLO.ELF ARITH.ELF LOOPTEST.ELF)
COMMON := $(STARTUP) $(LINKER_SCRIPT) ../src/kernel/syscall.h syscall.hpp Makefile

.PHONY: all hello arithmetic loop_test inspect clean
all: $(APPS)
hello: $(BIN_DIR)/HELLO.ELF
arithmetic: $(BIN_DIR)/ARITH.ELF
loop_test: $(BIN_DIR)/LOOPTEST.ELF

$(BIN_DIR):
	mkdir -p $@

$(BIN_DIR)/HELLO.ELF: elf_cpp/hello.cpp $(COMMON)
$(BIN_DIR)/ARITH.ELF: elf_cpp/arithmetic.cpp $(COMMON)
$(BIN_DIR)/LOOPTEST.ELF: elf_cpp/loop_test.cpp $(COMMON)
$(APPS): | $(BIN_DIR)
	$(CXX) $(CPPFLAGS) -I../src -I. $(APP_FLAGS) $(CXXFLAGS) \
		$(APP_LINK_FLAGS) $(LDFLAGS) $(STARTUP) $< -o $@

inspect: $(APPS)
	$(READELF) -h -l $(APPS)

# Only this Makefile's three outputs; no recursive clean or wildcard deletion.
clean:
	$(RM) $(APPS)
