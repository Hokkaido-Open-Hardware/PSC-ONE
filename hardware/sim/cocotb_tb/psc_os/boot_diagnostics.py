"""Opt-in RV32 boot evidence. Observes buses/RAM without changing DUT state."""
import hashlib
import os
from pathlib import Path
import struct
import subprocess

import cocotb
from cocotb.triggers import RisingEdge, ReadOnly


class BootDiagnostics:
    def __init__(self, dut):
        self.dut = dut
        self.cpu = dut.u_chip.u_soc.u_rv32_core_axi
        self.core = self.cpu.u_core
        self.cache = self.cpu.u_data_dma_ctrl
        self.mmu = self.core.u_fetch_unit.u_mmu_i
        self.entered = False
        self.walks = 0
        self.free = int(os.getenv("PSC_OS_PT_POOL", "0"), 0)
        elf = os.getenv("PSC_OS_KERNEL_ELF")
        if elf:
            symbols = subprocess.check_output(
                ["riscv64-unknown-elf-nm", "-n", elf], text=True)
            for line in symbols.splitlines():
                fields = line.split()
                if len(fields) == 3 and fields[2] == "__free_ram":
                    self.free = int(fields[0], 16)
        self.out = Path(os.getenv("PSC_OS_DIAGNOSTIC_DIR", "boot-diagnostics"))
        self.out.mkdir(parents=True, exist_ok=True)

    def value(self, handle):
        return int(handle.value)

    def ram(self, addr):
        return self.value(self.dut.u_sdram_model.mem[addr >> 2])

    def cached(self, addr):
        """Backing D-cache snapshot, not a CPU transaction or a cache flush."""
        bits = self.value(self.cache.TAGLSB)
        index = (addr & ((1 << bits) - 1)) >> 5
        tag = self.value(self.cache.u_tag.tag_mem[index])
        if tag & 2 and tag >> 2 == addr >> bits:
            line = self.value(self.cache.u_data.data_mem[index])
            return (line >> ((addr & 31) * 8)) & 0xffffffff, bool(tag & 1)
        return self.ram(addr), False

    def log(self, message):
        self.dut._log.info("[BOOT DIAG] " + message)

    def snapshot(self, reason):
        satp = self.value(self.core.u_csr.csr_satp)
        va = self.value(self.mmu.vaddr)
        self.log(f"{reason} pc={self.value(self.core.pc):08x} "
                 f"priv={self.value(self.core.priv_mode)} satp={satp:08x} "
                 f"fetch_va={va:08x} mmu_state={self.value(self.mmu.state)} "
                 f"l1={self.value(self.mmu.l1_pte):08x} l0={self.value(self.mmu.l0_pte):08x}")
        if satp >> 31:
            root = (satp & 0x3fffff) << 12
            for index in sorted({0, 1, 64, va >> 22}):
                addr = root + index * 4
                word, dirty = self.cached(addr)
                self.log(f"ROOT[{index}] pa={addr:08x} sdram={self.ram(addr):08x} "
                         f"dcache_view={word:08x} dirty={int(dirty)}")
                if index == va >> 22 and word & 1 and not word & 14:
                    leaf = ((word >> 10) << 12) + ((va >> 12) & 1023) * 4
                    data, dirty = self.cached(leaf)
                    self.log(f"LEAF pa={leaf:08x} sdram={self.ram(leaf):08x} "
                             f"dcache_view={data:08x} dirty={int(dirty)}")
            (self.out / f"root-{satp:08x}-{reason}.bin").write_bytes(
                b"".join(struct.pack("<I", self.ram(root + i)) for i in range(0, 4096, 4)))

    def check_kernel_entry(self):
        if self.value(self.core.pc) != 0x200000:
            return
        self.entered = True
        self.snapshot("KERNEL_ENTRY")
        for name, base in (("kernel", 0x200000), ("user", 0x400000)):
            expected = b"".join(struct.pack("<I", int(w, 16))
                                for w in Path(f"mem/{name}.mem").read_text().split())
            ram = b"".join(struct.pack("<I", self.ram(base + i))
                           for i in range(0, len(expected), 4))
            view = b"".join(struct.pack("<I", self.cached(base + i)[0])
                            for i in range(0, len(expected), 4))
            for kind, data in (("sdram", ram), ("dcache-view", view)):
                mismatches = [i for i in range(0, len(data), 4)
                              if data[i:i+4] != expected[i:i+4]]
                self.log(f"IMAGE {name} {kind} bytes={len(data)} "
                         f"sha256={hashlib.sha256(data).hexdigest()} "
                         f"mismatched_words={len(mismatches)} "
                         f"first_offsets={mismatches[:8]}")
                (self.out / f"{name}-{kind}.bin").write_bytes(data)

    async def satp_changes(self):
        while True:
            await self.core.u_csr.csr_satp.value_change
            await ReadOnly()
            self.snapshot("SATP")

    async def pte_reads(self):
        while True:
            await RisingEdge(self.mmu.mem_ready)
            await ReadOnly()
            if self.walks < 80:
                self.walks += 1
                addr = self.value(self.mmu.mem_addr)
                self.log(f"PTE state={self.value(self.mmu.state)} "
                         f"va={self.value(self.mmu.vaddr):08x} pa={addr:08x} "
                         f"bus={self.value(self.mmu.mem_rdata):08x} sdram={self.ram(addr):08x}")

    async def stores(self):
        while True:
            await RisingEdge(self.cache.cpu_wvalid)
            await ReadOnly()
            addr = self.value(self.cache.cpu_waddr)
            data = self.value(self.cache.cpu_data)
            if self.entered and self.free and self.free <= addr < self.free + 6 * 4096 and data:
                self.log(f"CPU_STORE pc={self.value(self.core.pc):08x} "
                         f"pa={addr:08x} data={data:08x} sel={self.value(self.cache.cpu_write_sel)}")

    async def loads(self):
        while True:
            await RisingEdge(self.cache.cpu_ready)
            await ReadOnly()
            addr = self.value(self.cache.req_addr_b)
            if (self.entered and self.free and self.free <= addr < self.free + 6 * 4096
                    and not self.value(self.cache.req_is_write)
                    and not self.value(self.cache.req_from_mmu)
                    and not self.value(self.cache.req_from_sa)):
                self.log(f"CPU_LOAD pa={addr:08x} bus={self.value(self.cache.cpu_data_out):08x} "
                         f"sdram={self.ram(addr):08x}")

    def start(self):
        for monitor in (self.satp_changes, self.pte_reads, self.stores, self.loads):
            cocotb.start_soon(monitor())
