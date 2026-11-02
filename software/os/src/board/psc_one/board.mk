# PSC-ONE / PSC_RV32. v1 and v2 share the existing ILP32 OS ABI.
ifeq ($(CPU_VERSION),rv64)
$(error BOARD=psc_one is for PSC_RV32; use BOARD=psc_one_rv64 for PSC_RV64)
endif
BOARD_ARCH := -march=rv32im_zicsr_zifencei -mabi=ilp32
BOARD_CPPFLAGS := -DPSC_BOARD_PSC_ONE=1
BOARD_USER_BASE := 0x00400000
BOARD_SBI_USER_BASE := 0x01000000
