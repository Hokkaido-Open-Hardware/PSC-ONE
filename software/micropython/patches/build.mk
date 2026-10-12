# Run the real build in a fresh make only after the patch prerequisite finishes.
# This also prevents generated headers / dependency files from reading unpatched
# sources, and ensures make observes source timestamps AFTER git apply.
PSC_PATCH_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
PSC_PATCH_BUILD_BODY := $(if $(filter $(PSC_BUILD_MAKEFILE),$(PSC_PATCH_READY_FOR)),1,0)

ifeq ($(PSC_PATCH_BUILD_BODY),0)
.DEFAULT_GOAL := psc-patched-build
.PHONY: psc-patched-build psc-micropython-patch $(MAKECMDGOALS)

# No goals means the normal default build; only explicit clean-only skips apply.
ifeq ($(strip $(MAKECMDGOALS)),)
psc-patched-build: psc-micropython-patch
else ifneq ($(filter-out clean,$(MAKECMDGOALS)),)
psc-patched-build: psc-micropython-patch
endif

psc-micropython-patch:
	python3 "$(PSC_PATCH_DIR)apply.py"

psc-patched-build:
	+$(MAKE) -C "$(dir $(PSC_BUILD_MAKEFILE))" -f "$(notdir $(PSC_BUILD_MAKEFILE))" PSC_PATCH_READY_FOR="$(PSC_BUILD_MAKEFILE)" $(MAKECMDGOALS)

$(filter-out psc-patched-build psc-micropython-patch,$(MAKECMDGOALS)): psc-patched-build
endif
