# PSC-ONE Phase Flow Engine

[PSC-ONE](../../../../README.md) · [Documentation](../../../../docs/README.md)

This directory contains the hardware design of PSC-ONE Phase Flow Engine.

---

## Overview

[PSC_PFE.v](src/PSC_PFE.v) implements an experimental memory-mapped QUBO
energy engine. The default variable count is eight, with DATA at `0x10008000`
and CTRL at `0x10008004`. Commands include coefficient/input loading, start
and clear; read selections expose energy, status and the current input.

The current PSC-OS syscall dispatcher and MicroPython `psc` module do not expose
a PFE API. Hardware presence does not imply an OS-facing service.

---

## Status

🚧 Work in Progress

The hardware design is actively evolving. Interfaces, modules, and configurations may change.
