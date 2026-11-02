# Reserved for PSC-ONE / PSC_RV64. Do not silently emit an RV32 image.
$(error BOARD=psc_one_rv64 targets PSC_RV64; the PSC-OS RV64 port is not implemented yet (startup, LP64 ABI, traps and Sv39 required))
