"""Standalone RV64 Sv39 MMU tests.

Profile: 64-bit PTEs, 56-bit physical addresses, Svade, SUM=MXR=0,
no TLB/PTE cache. MPRV is resolved by the caller (effective priv_mode).
The memory interface grants a one-cycle request with mem_req_ready, then
returns one atomic PTE with mem_ready. These tests use only public ports.
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, Timer

CLOCK_PERIOD_NS = 10
TIMEOUT_CYCLES = 30
U_MODE, S_MODE, M_MODE = 0, 1, 3
V, R, W, X, U, G, A, D = (1 << bit for bit in range(8))
MASK64 = (1 << 64) - 1
VA = 0x0000_0012_3456_7ABC
ROOT = 0x0012_3456_0000_0000
L1 = 0x0000_0009_8765_4000
L0 = 0x0000_0001_2345_6000
PA = 0x00AB_CDEF_1234_5000


def satp_value(root=ROOT, asid=0xABCD, mode=8):
    return (mode << 60) | (asid << 44) | (root >> 12)


def pte_value(physical, flags):
    assert physical & 0xFFF == 0
    assert 0 <= physical < (1 << 56)
    return ((physical >> 12) << 10) | flags


def pte_address(table, va, level):
    return table + ((va >> (12 + 9 * level)) & 0x1FF) * 8


async def tick(dut):
    # Sample after nonblocking RTL updates; drive inputs on falling edges.
    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")


async def reset_dut(dut):
    cocotb.start_soon(Clock(dut.clk, CLOCK_PERIOD_NS, unit="ns").start())
    for name in (
        "reset_n", "MMU_enb", "vaddr", "satp", "priv_mode", "access_r",
        "access_w", "access_x", "mem_req_ready", "mem_rdata", "mem_ready",
        "cpu_state_done", "sfence_vma",
    ):
        getattr(dut, name).value = 0
    for _ in range(5):
        await tick(dut)
    await FallingEdge(dut.clk)
    dut.reset_n.value = 1
    await tick(dut)
    assert not int(dut.mmu_done.value)
    assert not int(dut.page_fault.value)
    assert not int(dut.mem_valid.value)
    for name in ("vaddr", "satp", "mem_addr", "mem_rdata", "paddr"):
        assert len(getattr(dut, name)) == 64, f"{name} must be RV64 width"


async def start_translation(dut, va=VA, satp=None, priv=S_MODE, access="r"):
    await FallingEdge(dut.clk)
    dut.vaddr.value = va
    dut.satp.value = satp_value() if satp is None else satp
    dut.priv_mode.value = priv
    dut.access_r.value = int(access == "r")
    dut.access_w.value = int(access == "w")
    dut.access_x.value = int(access == "x")
    dut.MMU_enb.value = 1
    await tick(dut)
    assert not int(dut.mem_valid.value), "Request before memory grant"
    await FallingEdge(dut.clk)
    dut.MMU_enb.value = 0


async def request_pte(dut, address, stall=2):
    """Check backpressure, exact 8-byte PTE address and request pulse."""
    for _ in range(stall):
        await tick(dut)
        assert not int(dut.mem_valid.value), "Request without mem_req_ready"
        assert not int(dut.mmu_done.value), "Completed before reading PTE"
    await FallingEdge(dut.clk)
    dut.mem_req_ready.value = 1
    for _ in range(TIMEOUT_CYCLES):
        await tick(dut)
        assert not int(dut.mmu_done.value), "Completed before PTE response"
        if int(dut.mem_valid.value):
            actual = int(dut.mem_addr.value)
            assert actual == address, f"PTE address: {actual:#018x} != {address:#018x}"
            await FallingEdge(dut.clk)
            dut.mem_req_ready.value = 0
            return
    raise AssertionError(f"PTE request timeout: {address:#018x}")


async def deliver_pte(dut, address, pte, latency=2):
    # Poison data must be ignored until mem_ready. Hold the request address.
    dut.mem_rdata.value = MASK64
    for _ in range(latency):
        await tick(dut)
        assert not int(dut.mem_valid.value), "Duplicate PTE request"
        assert not int(dut.mmu_done.value), "Consumed PTE before mem_ready"
        assert int(dut.mem_addr.value) == address, "Outstanding address changed"
    await FallingEdge(dut.clk)
    dut.mem_rdata.value = pte
    dut.mem_ready.value = 1
    await tick(dut)
    assert not int(dut.mem_valid.value), "Duplicate request at response"
    await FallingEdge(dut.clk)
    dut.mem_ready.value = 0
    dut.mem_rdata.value = 0


async def respond_pte_read(dut, address, pte, stall=2, latency=2):
    await request_pte(dut, address, stall)
    await deliver_pte(dut, address, pte, latency)


async def finish_translation(dut, physical=None, fault=False):
    for _ in range(TIMEOUT_CYCLES):
        assert not int(dut.mem_valid.value), "Unexpected extra PTE read"
        if int(dut.mmu_done.value):
            break
        await tick(dut)
    else:
        raise AssertionError("MMU completion timeout")
    assert bool(dut.page_fault.value) == fault, f"Expected page_fault={fault}"
    if not fault:
        actual = int(dut.paddr.value)
        assert actual == physical, f"PA: {actual:#018x} != {physical:#018x}"
    # done is a pulse; a fault stays visible until the CPU acknowledges it.
    for _ in range(2):
        await tick(dut)
        assert not int(dut.mmu_done.value), "mmu_done must be one cycle"
        assert not int(dut.mem_valid.value), "Read after completion"
        assert bool(dut.page_fault.value) == fault, "Fault lost before acknowledgment"
    await FallingEdge(dut.clk)
    dut.cpu_state_done.value = 1
    await tick(dut)
    assert not int(dut.page_fault.value), "Fault not cleared by CPU acknowledgment"
    await FallingEdge(dut.clk)
    dut.cpu_state_done.value = 0


async def walk_to_level(dut, level, va=VA, root=ROOT):
    """Supply valid non-leaves above level, returning the final PTE address."""
    tables = {2: root, 1: L1, 0: L0}
    for current in range(2, level, -1):
        await respond_pte_read(
            dut, pte_address(tables[current], va, current),
            pte_value(tables[current - 1], V | G | 0x300),
        )
    return pte_address(tables[level], va, level)


async def pulse_fence(dut):
    await FallingEdge(dut.clk)
    dut.sfence_vma.value = 1
    await tick(dut)
    assert not int(dut.mem_valid.value)
    assert not int(dut.mmu_done.value), "Stale translation completed during fence"
    await FallingEdge(dut.clk)
    dut.sfence_vma.value = 0


@cocotb.test()
async def mmu_bare_mode_test(dut):
    """Bare preserves all 64 address bits, irrespective of ASID/PPN fields."""
    await reset_dut(dut)
    for va in (0, 0x278, 0x8000_0000, 0x1_2345_6789, 0xFEDC_BA98_7654_3210, MASK64):
        for priv in (U_MODE, S_MODE, M_MODE):
            await start_translation(dut, va, satp_value(mode=0), priv)
            assert not int(dut.mode_translate.value)
            await finish_translation(dut, va)


@cocotb.test()
async def mmu_m_mode_bypass_test(dut):
    """Effective M-mode bypasses even noncanonical VA/unsupported satp.MODE."""
    await reset_dut(dut)
    for mode in (8, 9, 15):
        for va in (0, VA, 0x0000_0040_0000_0000, 0xFEDC_BA98_7654_3210, MASK64):
            await start_translation(dut, va, satp_value(mode=mode), M_MODE)
            assert not int(dut.mode_translate.value)
            await finish_translation(dut, va)


@cocotb.test()
async def mmu_sv39_page_sizes_test(dut):
    """L2/L1/L0 leaves: 1 GiB, 2 MiB and 4 KiB; full PPN and both VA halves."""
    await reset_dut(dut)
    for level in (2, 1, 0):
        offset_mask = (1 << (12 + 9 * level)) - 1
        physical = PA & ~offset_mask
        for va in (0, VA, (1 << 38) - 1, 0xFFFF_FFC0_0000_0000,
                   0xFFFF_FFFF_C123_4567, MASK64):
            await start_translation(dut, va)
            assert int(dut.mode_translate.value)
            address = await walk_to_level(dut, level, va)
            await respond_pte_read(dut, address, pte_value(physical, V | R | A | G | 0x300))
            await finish_translation(dut, physical | (va & offset_mask))


@cocotb.test()
async def mmu_invalid_address_mode_test(dut):
    """Reject noncanonical Sv39 addresses and unsupported non-Bare modes."""
    await reset_dut(dut)
    for va in (1 << 38, 1 << 39, 0xFFFF_FF80_0000_0000, 0xFFFF_FFBF_FFFF_FFFF):
        await start_translation(dut, va)
        await finish_translation(dut, fault=True)
    for mode in range(1, 16):
        if mode != 8:
            await start_translation(dut, satp=satp_value(mode=mode))
            await finish_translation(dut, fault=True)
    await start_translation(dut, priv=2)
    await finish_translation(dut, fault=True)


@cocotb.test()
async def mmu_invalid_pte_test(dut):
    """Invalid/reserved PTEs at every level, exhausted walk, misaligned leaves."""
    await reset_dut(dut)
    for level in (2, 1, 0):
        invalid = [0, V | W | A | D]
        invalid += [V | R | A | (1 << bit) for bit in range(54, 64)]
        invalid += [pte_value(L0, V | flag) for flag in (U, A, D)]
        if level == 0:
            invalid.append(pte_value(L0, V))  # No next level below L0.
        else:
            # Every lower PPN bit is reserved for this superpage size.
            invalid += [pte_value(1 << bit, V | R | A)
                        for bit in range(12, 12 + 9 * level)]
        for pte in invalid:
            await start_translation(dut)
            address = await walk_to_level(dut, level)
            await respond_pte_read(dut, address, pte)
            await finish_translation(dut, fault=True)
    # A valid walk immediately after the faults proves recovery.
    await start_translation(dut)
    address = await walk_to_level(dut, 0)
    await respond_pte_read(dut, address, pte_value(PA, V | R | A))
    await finish_translation(dut, PA | (VA & 0xFFF))


@cocotb.test()
async def mmu_leaf_permissions_test(dut):
    """All 256 flag combinations x U/S x load/store/fetch (Svade, SUM=MXR=0)."""
    await reset_dut(dut)
    count = 0
    for access, required in (("r", R), ("w", W), ("x", X)):
        for priv in (U_MODE, S_MODE):
            for flags in range(256):
                valid = bool(flags & V) and not (flags & W and not flags & R)
                leaf = bool(flags & (R | X))
                user_ok = bool(flags & U) == (priv == U_MODE)
                allowed = bool(flags & required) and bool(flags & A)
                if access == "w":
                    allowed = allowed and bool(flags & D)
                fault = not (valid and leaf and user_ok and allowed)
                await start_translation(dut, priv=priv, access=access)
                address = await walk_to_level(dut, 0)
                await respond_pte_read(dut, address, pte_value(PA, flags))
                try:
                    await finish_translation(dut, PA | (VA & 0xFFF), fault)
                except AssertionError as exc:
                    raise AssertionError(
                        f"flags={flags:#04x}, priv={priv}, access={access}: {exc}"
                    ) from exc
                count += 1
    dut._log.info("PASS: %d leaf permission combinations", count)


@cocotb.test()
async def mmu_latched_context_test(dut):
    """Accepted VA/root/privilege/access remain stable while live inputs change."""
    await reset_dut(dut)
    await start_translation(dut)
    dut.vaddr.value = MASK64
    dut.satp.value = 0
    dut.priv_mode.value = U_MODE
    dut.access_r.value = 0
    dut.access_w.value = 1
    dut.access_x.value = 1
    address = await walk_to_level(dut, 0)
    await respond_pte_read(dut, address, pte_value(PA, V | R | A))
    await finish_translation(dut, PA | (VA & 0xFFF))


@cocotb.test()
async def mmu_rewalk_asid_test(dut):
    """No cache: same VA re-reads changed PTEs, with same or different ASID/root."""
    await reset_dut(dut)
    for index, (root, asid) in enumerate(((ROOT, 0), (ROOT, 0), (ROOT, 0xFFFF), (L1, 1))):
        if index == 2:
            await pulse_fence(dut)  # Idle SFENCE does not complete a transaction.
        await start_translation(dut, satp=satp_value(root, asid))
        address = await walk_to_level(dut, 0, root=root)
        physical = PA + index * 0x1000
        await respond_pte_read(dut, address, pte_value(physical, V | R | A),
                               stall=index, latency=index)
        await finish_translation(dut, physical | (VA & 0xFFF))


@cocotb.test()
async def mmu_sfence_vma_rewalk_test(dut):
    """Fence drains each outstanding level, discards old PTE and restarts at root."""
    await reset_dut(dut)
    for level in (2, 1, 0):
        await start_translation(dut)
        address = await walk_to_level(dut, level)
        await request_pte(dut, address)
        await pulse_fence(dut)
        # If used, this valid stale leaf would produce a different PA.
        await deliver_pte(dut, address, pte_value(0, V | R | A), latency=4)
        address = await walk_to_level(dut, 0)
        await respond_pte_read(dut, address, pte_value(PA, V | R | A))
        await finish_translation(dut, PA | (VA & 0xFFF))


@cocotb.test()
async def mmu_sfence_before_request_test(dut):
    """Fence with an ungranted lower-level read restarts without waiting for data."""
    await reset_dut(dut)
    await start_translation(dut)
    await respond_pte_read(dut, pte_address(ROOT, VA, 2), pte_value(L1, V))
    for _ in range(3):
        await tick(dut)
        assert not int(dut.mem_valid.value)
    assert int(dut.mem_addr.value) == pte_address(L1, VA, 1)
    await pulse_fence(dut)
    address = await walk_to_level(dut, 0)
    await respond_pte_read(dut, address, pte_value(PA, V | R | A))
    await finish_translation(dut, PA | (VA & 0xFFF))
