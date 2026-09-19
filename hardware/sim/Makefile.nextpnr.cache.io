# ============================================================
# PSC-ONE Cache DMA Controller IO timing flow
# with nextpnr / Himbaechel
#
# Usage:
#   make -f Makefile.nextpnr.cache.io timing
#
# Optional:
#   make -f Makefile.nextpnr.cache.io timing FREQ=81
#
# Target FPGA:
#   Tang Nano 20K
#   GW2AR-LV18QN88C8/I7
#   family = GW2A-18C
#
# Notes:
#   - Gowin IDE is not used.
#   - cache_dma_controller_io_TimingTop.sv is used as synthesis TOP.
#   - cache_dma_controller_io.sv is instantiated as the DUT.
#   - SystemVerilog sources are read directly by Yosys.
#   - This flow is intended to measure logic utilisation and timing
#     of the cache DMA controller IO block independently.
# ============================================================

SHELL := /bin/bash

YOSYS   ?= ./yosys/build/yosys
NEXTPNR ?= nextpnr-himbaechel

DEVICE ?= GW2AR-LV18QN88C8/I7
FAMILY ?= GW2A-18C
FREQ   ?= 81

# ------------------------------------------------------------
# Cache DMA Controller IO source
# ------------------------------------------------------------

TIMING_DIR  := ../rtl/tang20k/timing
CACHE_SRC_DIR := ../rtl/soc/cache/src

CACHE_FILES := \
	$(CACHE_SRC_DIR)/cache_dma_controller_io.sv \
	$(CACHE_SRC_DIR)/dm_cache_data.v \
	$(CACHE_SRC_DIR)/dm_cache_tag.v

# Timing wrapper
TIMING_WRAPPER := $(TIMING_DIR)/cache_dma_controller_io_TimingTop.sv
TIMING_CST     := $(TIMING_DIR)/cache_dma_controller_io_TimingTop.cst

TOP := cache_dma_controller_io_TimingTop

ALL_FILES := \
	$(CACHE_FILES) \
	$(TIMING_WRAPPER)

# ------------------------------------------------------------
# Build files
# ------------------------------------------------------------

BUILD_DIR   ?= build_nextpnr_cache_io
JSON        := $(BUILD_DIR)/cache_io.json
PNR_JSON    := $(BUILD_DIR)/cache_io_pnr.json
YOSYS_LOG   := $(BUILD_DIR)/yosys_cache_io.log
NEXTPNR_LOG := $(BUILD_DIR)/nextpnr_cache_io.log
REPORT      := $(BUILD_DIR)/timing_cache_io.json


.PHONY: all check-tools check-files synth pnr timing report clean

all: timing


# ------------------------------------------------------------
# Tool checks
# ------------------------------------------------------------

check-tools:
	@command -v $(YOSYS) >/dev/null 2>&1 || { \
		echo "[ERROR] yosys not found"; exit 1; }
	@command -v $(NEXTPNR) >/dev/null 2>&1 || { \
		echo "[ERROR] nextpnr-himbaechel not found"; exit 1; }
	@echo "[OK] yosys   : $$(command -v $(YOSYS))"
	@echo "[OK] nextpnr : $$(command -v $(NEXTPNR))"
	@$(NEXTPNR) --version


# ------------------------------------------------------------
# Source checks
# ------------------------------------------------------------

check-files:
	@for f in $(ALL_FILES); do \
		test -f "$$f" || { \
			echo "[ERROR] source file not found: $$f"; \
			exit 1; \
		}; \
	done
	@test -f "$(TIMING_CST)" || { \
		echo "[ERROR] CST not found: $(TIMING_CST)"; \
		exit 1; \
	}
	@echo "[OK] TOP     : $(TOP)"
	@echo "[OK] wrapper : $(TIMING_WRAPPER)"
	@echo "[OK] CST     : $(TIMING_CST)"

# ------------------------------------------------------------
# Yosys synthesis
# ------------------------------------------------------------

synth: check-tools check-files
	@mkdir -p $(BUILD_DIR)
	@echo "============================================================"
	@echo " Cache DMA Controller IO"
	@echo " TOP         : $(TOP)"
	@echo " DEVICE      : $(DEVICE)"
	@echo " FAMILY      : $(FAMILY)"
	@echo " TARGET FREQ : $(FREQ) MHz"
	@echo "============================================================"

	$(YOSYS) -l $(YOSYS_LOG) -p " \
		read_verilog -sv $(ALL_FILES); \
		hierarchy -check -top $(TOP); \
		flatten; \
		synth_gowin -top $(TOP) -family gw2a -json $(JSON); \
		stat \
	"

	@echo "[OK] JSON : $(JSON)"
	@echo "[OK] LOG  : $(YOSYS_LOG)"


# ------------------------------------------------------------
# nextpnr place and route
# ------------------------------------------------------------

pnr: synth
	@mkdir -p $(BUILD_DIR)
	@set -o pipefail; \
	$(NEXTPNR) \
		--json $(JSON) \
		--write $(PNR_JSON) \
		--device $(DEVICE) \
		--vopt family=$(FAMILY) \
		--vopt cst=$(TIMING_CST) \
		--freq $(FREQ) \
		--report $(REPORT) \
		2>&1 | tee $(NEXTPNR_LOG)

	@echo "[OK] P&R JSON : $(PNR_JSON)"
	@echo "[OK] REPORT   : $(REPORT)"
	@echo "[OK] LOG      : $(NEXTPNR_LOG)"


# ------------------------------------------------------------
# Timing summary
# ------------------------------------------------------------

timing: pnr
	@echo "============================================================"
	@echo " cache_dma_controller_io nextpnr timing summary"
	@echo "============================================================"

	@grep -Ei \
		'Max frequency|MHz|critical path|slack|timing|logic utilisation|utilization|Device utilisation' \
		$(NEXTPNR_LOG) | tail -n 200 || true

	@echo "Full log:    $(NEXTPNR_LOG)"
	@echo "JSON report: $(REPORT)"


# ------------------------------------------------------------
# Report only
# ------------------------------------------------------------

report:
	@if [ ! -f "$(NEXTPNR_LOG)" ]; then \
		echo "[ERROR] $(NEXTPNR_LOG) not found. Run timing first."; \
		exit 1; \
	fi

	@grep -Ei \
		'Max frequency|MHz|critical path|slack|timing|logic utilisation|utilization|Device utilisation' \
		$(NEXTPNR_LOG) | tail -n 240 || true


# ------------------------------------------------------------
# Clean
# ------------------------------------------------------------

clean:
	rm -rf $(BUILD_DIR)