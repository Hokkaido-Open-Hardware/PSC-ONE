import cocotb
import random
from cocotb.triggers import Timer, RisingEdge, ReadOnly, ReadWrite

CLK_NS = 10

# ------------------------------------------------
# clock
# ------------------------------------------------
async def gen_clock(dut):
    while True:
        dut.clock.value = 0
        await Timer(CLK_NS // 2, unit="ns")
        dut.clock.value = 1
        await Timer(CLK_NS // 2, unit="ns")



# ------------------------------------------------
# sdram init fin wait
# ------------------------------------------------
async def sdram_init_fin_wait(dut, timeout=10000):

    for _ in range(timeout):
        await RisingEdge(dut.clock)
        await ReadOnly()

        if int(dut.sdram_init_fin.value) == 1:
            # ReadOnlyフェーズのまま戻らない
            await RisingEdge(dut.clock)
            return

    raise AssertionError("sdram_init_fin timeout")

# ------------------------------------------------
# data cache wb start
# ------------------------------------------------
async def data_cache_wb_start(dut, time=10000):

    dut.data_cache_wb.value    = 1
    for _ in range(time):
        await RisingEdge(dut.clock)

    dut.data_cache_wb.value    = 0

# ------------------------------------------------
# data cache clear start
# ------------------------------------------------
async def data_cache_clear_start(dut, time=10000):

    # ReadOnlyフェーズを抜ける
    await RisingEdge(dut.clock)

    dut.data_cache_clear.value    = 1
    for _ in range(time):
        await RisingEdge(dut.clock)

    dut.data_cache_clear.value    = 0

# ------------------------------------------------
# reset
# ------------------------------------------------
async def reset_dut(dut):
    dut.reset_n.value                   = 0
    dut.program_mem_read_valid.value    = 0
    dut.program_mem_read_address.value  = 0
    dut.cpu_cache_clear.value           = 0
    dut.burst_mode.value                = 0
    
    dut.data_mem_read_valid.value       = 0
    dut.data_mem_read_address.value     = 0
    dut.data_mem_write_valid.value      = 0
    dut.mem_write_sel.value             = 0
    dut.data_mem_write_address.value    = 0
    dut.mem_write_data.value            = 0
    dut.data_cache_clear.value          = 0
    dut.data_cache_wb.value             = 0
    
    dut.mmu_data_mem_read_valid.value   = 0
    dut.mmu_data_mem_read_address.value = 0

    dut.sa_mem_read_valid.value         = 0
    dut.sa_mem_read_address.value       = 0
    dut.sa_mem_read_valid.value         = 0
    dut.sa_mem_write_valid.value        = 0
    dut.sa_mem_write_address.value      = 0
    dut.sa_mem_write_data.value         = 0

    for _ in range(10):
        await RisingEdge(dut.clock)

    dut.reset_n.value = 1

    for _ in range(10):
        await RisingEdge(dut.clock)

# ------------------------------------------------
# CPU data write
# ------------------------------------------------
async def cpu_data_write(
    dut,
    addr,
    data,
    mode="CPU",
    timeout=1000
):

    mode = mode.upper()

    if mode == "CPU":
        req_ready     = dut.cpu_req_ready
        write_address = dut.data_mem_write_address
        write_valid   = dut.data_mem_write_valid
        write_sel     = dut.mem_write_sel
        write_data    = dut.mem_write_data
        write_ready   = dut.data_mem_write_ready

    elif mode == "SA":
        req_ready     = dut.sa_req_ready
        write_address = dut.sa_mem_write_address
        write_valid   = dut.sa_mem_write_valid
        write_sel     = dut.sa_mem_write_sel
        write_data    = dut.sa_mem_write_data
        write_ready   = dut.sa_mem_write_ready

    else:
        raise ValueError(
            f'Unknown mode="{mode}". Use "CPU" or "SA".'
        )

    # 呼び出し元がReadOnlyフェーズにいる可能性があるため、
    # 最初に次のクロックまで進める
    await RisingEdge(dut.clock)

    write_valid.value = 0

    # ------------------------------------------------
    # req_ready wait
    # ------------------------------------------------
    for _ in range(timeout):
        await RisingEdge(dut.clock)
        await ReadOnly()

        if int(req_ready.value) == 1:
            break
    else:
        raise AssertionError(
            f"{mode} req_ready timeout addr=0x{addr:08x}"
        )

    # ReadOnlyフェーズを抜ける
    await RisingEdge(dut.clock)

    # ------------------------------------------------
    # アドレス設定
    # ------------------------------------------------
    write_address.value = addr

    await RisingEdge(dut.clock)

    # ------------------------------------------------
    # 32bit write request
    # ------------------------------------------------
    write_valid.value = 1
    write_sel.value   = 0b010
    write_data.value  = data & 0xFFFF_FFFF

    await RisingEdge(dut.clock)

    write_valid.value = 0

    # ------------------------------------------------
    # Write completion wait
    # ------------------------------------------------
    for _ in range(timeout):
        await RisingEdge(dut.clock)
        await ReadOnly()

        if int(write_ready.value) == 1:
            break
    else:
        raise AssertionError(
            f"{mode} write_ready timeout "
            f"addr=0x{addr:08x} "
            f"data=0x{data & 0xFFFF_FFFF:08x}"
        )

    # ReadOnly状態のまま呼び出し元へ戻らない
    await RisingEdge(dut.clock)

    return data & 0xFFFF_FFFF

# ------------------------------------------------
# CPU program read
# ------------------------------------------------
async def cpu_program_read(dut, addr, timeout=1000):

    # cpu_req_ready wait
    for _ in range(timeout):
        await RisingEdge(dut.clock)
        if int(dut.cpu_req_ready.value) == 1:
            break
    else:
        raise AssertionError(f"cpu_req_ready timeout")

    dut.program_mem_read_address.value = addr

    dut.program_mem_read_valid.value = 1
    await RisingEdge(dut.clock)
    dut.program_mem_read_valid.value = 0

    for _ in range(timeout):
        await RisingEdge(dut.clock)
        await ReadOnly()

        if int(dut.program_mem_read_ready.value) == 1:
            data = dut.program_mem_read_data.value
            break
    else:
        raise AssertionError(f"program_mem_read_ready timeout addr=0x{addr:08x}")

    await RisingEdge(dut.clock)

    return data

# ------------------------------------------------
# CPU monitor pulse counter
# ------------------------------------------------
class CpuMonitorCounter:
    def __init__(self):
        self.program_cache_hit_count    = 0
        self.program_cache_miss_count   = 0
        self.data_cache_hit_count       = 0
        self.data_cache_miss_count      = 0

async def cpu_monitor_count(dut, mon):
    while True:
        await RisingEdge(dut.clock)
        await ReadOnly()

        if int(dut.program_cache_hit_pulse.value) != 0:
            mon.program_cache_hit_count += 1

        if int(dut.program_cache_miss_pulse.value) != 0:
            mon.program_cache_miss_count += 1

        if int(dut.data_cache_hit_pulse.value) != 0:
            mon.data_cache_hit_count += 1

        if int(dut.data_cache_miss_pulse.value) != 0:
            mon.data_cache_miss_count += 1

# ------------------------------------------------
# CPU program burst read
# 128bit cache line -> 32bit x 4
# ------------------------------------------------
async def cpu_program_burst_read(dut, addr, timeout=1000):

    # 16byte align
    addr = addr & ~0xF

    # req_ready wait
    for _ in range(timeout):
        await RisingEdge(dut.clock)
        if int(dut.cpu_req_ready.value) == 1:
            break
    else:
        raise AssertionError(
            f"cpu_req_ready timeout addr=0x{addr:08x}"
        )

    dut.program_mem_read_address.value = addr
    dut.program_mem_read_valid.value = 1

    await RisingEdge(dut.clock)

    dut.program_mem_read_valid.value = 0

    result = []

    # 32bit x 4を受信
    for _ in range(timeout):
        await RisingEdge(dut.clock)
        await ReadOnly()

        if int(dut.program_mem_read_ready.value) == 1:

            v = dut.program_mem_read_data.value

            assert v.is_resolvable, (
                f"Unresolved burst data "
                f"addr=0x{addr:08X} "
                f"word={len(result)}"
            )

            result.append(int(v))

            if len(result) == 4:
                break

    else:
        raise AssertionError(
            f"program burst read timeout "
            f"addr=0x{addr:08x}"
        )

    # ReadOnlyのままreturnしない
    await RisingEdge(dut.clock)

    return result

# ------------------------------------------------
# TEST 1: program dm cache burst test
# ------------------------------------------------
@cocotb.test()
async def cache_program_test(dut):

    dut._log.info("--------------------------------------------------")
    dut._log.info("==== PSC_ONE program cache burst test start ====")

    # CPU MONITOR START
    mon = CpuMonitorCounter()
    cocotb.start_soon(cpu_monitor_count(dut, mon))

    cocotb.start_soon(gen_clock(dut))

    await reset_dut(dut)
    await sdram_init_fin_wait(dut)

    # ------------------------------------------------
    # burst mode
    # ------------------------------------------------
    dut.burst_mode.value = 1

    random.seed(1324)

    test_data = {}

    # ------------------------------------------------
    # WRITE
    # 256 x 32bit
    # ------------------------------------------------
    for i in range(256):

        address = i * 4
        data = random.getrandbits(32)

        test_data[address] = data

        await cpu_data_write(
            dut,
            address,
            data,
            mode="CPU"
        )

    dut._log.info("WRITE 1000 words finished")

    # ------------------------------------------------
    # Data Cache -> SDRAM writeback
    # Program Cacheから読むため、dirty dataをSDRAMへ反映
    # ------------------------------------------------
    await data_cache_wb_start(
        dut,
        time=10000
    )

    dut._log.info("Data Cache writeback finished")

    # ------------------------------------------------
    # BURST READ + CHECK
    #
    # 1000 words / 4 words per line = 30 burst
    # ------------------------------------------------
    for line in range(30):

        base_addr = line * 16

        values = await cpu_program_burst_read(
            dut,
            base_addr
        )

        for word in range(4):

            address = base_addr + word * 4

            value = values[word]
            expected = test_data[address]

            assert value == expected, (
                f"Data mismatch: "
                f"addr=0x{address:08X}, "
                f"line={line}, "
                f"word={word}, "
                f"expected=0x{expected:08X}, "
                f"got=0x{value:08X}"
            )

        for _ in range(10):
            await RisingEdge(dut.clock)

    
    # ------------------------------------------------
    # BURST READ + CHECK
    # 2 times 
    # ------------------------------------------------
    for line in range(30):

        base_addr = line * 16

        values = await cpu_program_burst_read(
            dut,
            base_addr
        )

        for word in range(4):

            address = base_addr + word * 4

            value = values[word]
            expected = test_data[address]

            assert value == expected, (
                f"Data mismatch: "
                f"addr=0x{address:08X}, "
                f"line={line}, "
                f"word={word}, "
                f"expected=0x{expected:08X}, "
                f"got=0x{value:08X}"
            )

    dut._log.info(
        "BURST READ 250 lines / 1000 words CHECK PASS"
    )

    for _ in range(1000):
        await RisingEdge(dut.clock)

    dut._log.info(
        f"CPU MONITOR: \n"
        f"program_cache_hit={mon.program_cache_hit_count} \n"
        f"program_cache_miss={mon.program_cache_miss_count} \n"
        f"data_cache_hit={mon.data_cache_hit_count} \n"
        f"data_cache_miss={mon.data_cache_miss_count} \n"
    )

    dut._log.info("==== PASS test ====")