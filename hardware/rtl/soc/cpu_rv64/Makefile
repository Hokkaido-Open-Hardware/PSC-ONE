# Convenience entry point; all outputs stay in the RV64-specific build directory.
.DEFAULT_GOAL := simulate_RV64_CORE
RV64_DESIGN_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
.PHONY: simulate_RV64_CORE lint_RV64_CORE lint_RV64_ALL
simulate_RV64_CORE lint_RV64_CORE lint_RV64_ALL:
	+$(MAKE) -f "$(RV64_DESIGN_DIR)/../../../sim/Makefile.cpu_rv64.core" $@
