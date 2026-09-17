# ============================================================
# Usage
# ============================================================

#make -f Makefile.axi simulate_32bit_to_128bit_axi_bridge MODE=icarus
#or
#make -f Makefile.axi simulate_32bit_to_128bit_axi_bridge MODE=verilator

# ============================================================
#  SIMULATOR 切り替え (MODE=icarus / verilator)
# ============================================================
#MODE  = icarus
MODE  = verilator
SIM  := $(MODE)

# ------------------------------------------------------------
#  Verilator / Icarus ごとの設定
# ------------------------------------------------------------
ifeq ($(MODE),verilator)
# verilator
SDRAM_MODEL = ../SDRAM_model/w9825g6kh_verilator.v
GW2AR_SDRAM_MODEL 	= ../SDRAM_model/GW2AR_sdram_verilator.v

EXTRA_ARGS = \
	--trace --trace-fst --Wno-ASCRANGE --Wno-INITIALDLY --Wno-COMBDLY \
	--Wno-WIDTHEXPAND --Wno-WIDTHTRUNC --Wno-REALCVT
else ifeq ($(MODE),icarus)
# icarus
SDRAM_MODEL 		= ../SDRAM_model/w9825g6kh.v
GW2AR_SDRAM_MODEL 	= ../SDRAM_model/GW2AR_sdram.v

EXTRA_ARGS  =
else
$(error MODE=$(MODE) は不正です。MODE=icarus または MODE=verilator を指定してください)
endif

# ============================================================
#  Cocotb / コンパイル共通設定
# ============================================================
DEFS += COCOTB_SIM=1
ifeq ($(READ_MEM),1)
DEFS += READ_MEM
endif

# -D マクロ & SystemVerilog 有効化（Icarus / Verilator 両対応）
VLOG_ARGS = -g2012 $(addprefix -D,$(DEFS))

COCOTB_MAKEFILE  := $(shell cocotb-config --makefiles)/Makefile.sim

# ============================================================
#  ソース一覧
# ============================================================
SRC_BRIDGE = \
	../rtl/axi/sdram_32bit_to_128bit_axi_bridge.v

# ============================================================
#  Cocotb simulation targets
# ============================================================
# sdram_32bit_to_128bit_axi_bridge test
simulate_32bit_to_128bit_axi_bridge:
	@echo "[SIM] MODE=$(MODE), SIM=$(SIM) (sdram_32bit_to_128bit_axi_bridge test)"
	$(MAKE) clean
	COCOTB_TEST_MODULES=cocotb_tb.axi.bridge_test \
	TOPLEVEL=sdram_32bit_to_128bit_axi_bridge TOPLEVEL_LANG=verilog \
	SIM=$(SIM) \
	VERILOG_SOURCES="$(SRC_BRIDGE)" \
	VLOG_ARGS="$(VLOG_ARGS)" \
	EXTRA_ARGS="$(EXTRA_ARGS)" \
	make -f $(COCOTB_MAKEFILE)
