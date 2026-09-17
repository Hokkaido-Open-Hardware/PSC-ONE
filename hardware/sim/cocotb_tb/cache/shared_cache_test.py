"""Concurrent real I/D caches, dirty eviction and shared SDRAM AXI path."""
import cocotb
from cocotb.triggers import FallingEdge, RisingEdge, ReadOnly
from cocotb_tb.cache.dm_cache_test import (
    gen_clock, reset_dut, sdram_init_fin_wait, cpu_data_write, data_cache_wb_start)
from cocotb_tb.axi.shared_monitor import SharedMonitor


async def read_word(dut, owner, address):
    prefix = 'program' if owner == 'i' else 'data'
    req_ready = dut.cpu_req_ready if owner == 'i' else dut.data_mem_req_ready
    for _ in range(3000):
        await FallingEdge(dut.clock)
        if int(req_ready.value):
            break
    else:
        assert False, 'Cache request timeout'
    valid = getattr(dut, prefix + '_mem_read_valid')
    getattr(dut, prefix + '_mem_read_address').value = address
    valid.value = 1
    await FallingEdge(dut.clock)
    valid.value = 0
    for _ in range(3000):
        await RisingEdge(dut.clock)
        await ReadOnly()
        if int(getattr(dut, prefix + '_mem_read_ready').value):
            return int(getattr(dut, prefix + '_mem_read_data').value)
    assert False, 'Cache completion timeout'


@cocotb.test()
async def shared_cache_contention(dut):
    cocotb.start_soon(gen_clock(dut))
    monitor = SharedMonitor(dut)
    cocotb.start_soon(monitor.run())
    await reset_dut(dut)
    await sdram_init_fin_wait(dut)
    expected = {}
    # Same D-cache index: force dirty eviction while constructing full lines.
    for line in range(12):
        for word in range(8):
            addr = 0x1000 + line * 0x1000 + word * 4
            value = (0xABCD1234 ^ (line * 0x9876543) ^ (word * 0x3210FEDC)) & 0xffffffff
            expected[addr] = value
            await cpu_data_write(dut, addr, value)
    await data_cache_wb_start(dut)

    async def stream(owner, addresses):
        for address in addresses:
            got = await read_word(dut, owner, address)
            assert got == expected[address], f'{owner} {address:x}: {got:x} != {expected[address]:x}'
    # Both sources run independently; many simultaneous misses and pending pulses.
    i_task = cocotb.start_soon(stream('i', list(expected)))
    d_task = cocotb.start_soon(stream('d', list(reversed(expected))))
    await i_task
    await d_task
    monitor.check()
    assert monitor.collision > 0, 'No overlapping I/D requests exercised'
