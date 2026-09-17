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
            break
    else:
        raise AssertionError(f"sdram_init_fin timeout")

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
# CPU / SA data read
# ------------------------------------------------
async def cpu_data_read(dut, addr, mode="CPU", timeout=1000):

    """
    mode="CPU" : キャッシュのCPUポートから読み込み
    mode="SA"  : キャッシュのSAポートから読み込み
    """

    mode = mode.upper()

    if mode == "CPU":
        req_ready    = dut.cpu_req_ready
        read_address = dut.data_mem_read_address
        read_valid   = dut.data_mem_read_valid
        read_sel     = dut.mem_write_sel
        read_data    = dut.data_mem_read_data
        read_ready   = dut.data_mem_read_ready

    elif mode == "SA":
        req_ready    = dut.sa_req_ready
        read_address = dut.sa_mem_read_address
        read_valid   = dut.sa_mem_read_valid
        read_sel     = dut.sa_mem_write_sel
        read_data    = dut.sa_mem_read_data
        read_ready   = dut.sa_mem_read_ready

    else:
        raise ValueError(
            f'Unknown mode="{mode}". Use "CPU" or "SA".'
        )

    read_valid.value = 0

    # ------------------------------------------------
    # req_ready待ち
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
    read_address.value = addr
    read_sel.value     = 0b010

    await RisingEdge(dut.clock)

    # ------------------------------------------------
    # read valid
    # ------------------------------------------------
    read_valid.value = 1

    await RisingEdge(dut.clock)

    read_valid.value = 0

    # ------------------------------------------------
    # 読み出し完了待ち
    # ------------------------------------------------
    for _ in range(timeout):
        await RisingEdge(dut.clock)
        await ReadOnly()

        if int(read_ready.value) == 1:
            data = int(read_data.value)
            break
    else:
        raise AssertionError(
            f"{mode} read_ready timeout addr=0x{addr:08x}"
        )

    await RisingEdge(dut.clock)

    return data

# ------------------------------------------------
# CPU data write (byte)
# ------------------------------------------------
async def cpu_data_byte_write(dut, addr, data, mode="CPU", timeout=1000):

    # cpu_req_ready wait
    for _ in range(timeout):
        await RisingEdge(dut.clock)
        if int(dut.cpu_req_ready.value) == 1:
            break
    else:
        raise AssertionError(f"cpu_req_ready timeout")

    dut.data_mem_write_address.value  = addr
    await RisingEdge(dut.clock)

    dut.data_mem_write_valid.value    = 1
    dut.mem_write_sel.value           = 0b000   # SB
    dut.mem_write_data.value          = data & 0x00FF
    await RisingEdge(dut.clock)
    dut.data_mem_write_valid.value    = 0

    for _ in range(timeout):
        await RisingEdge(dut.clock)
        await ReadOnly()

        if int(dut.data_mem_write_ready.value) == 1:
            break
    else:
        raise AssertionError(f"data_mem_write_ready timeout addr=0x{addr:08x}")

    await RisingEdge(dut.clock)

    return data

# ------------------------------------------------
# CPU data read (byte)
# ------------------------------------------------
async def cpu_data_byte_read(dut, addr, timeout=1000):

    # cpu_req_ready wait
    for _ in range(timeout):
        await RisingEdge(dut.clock)
        if int(dut.cpu_req_ready.value) == 1:
            break
    else:
        raise AssertionError("cpu_req_ready timeout")

    dut.data_mem_read_address.value = addr
    await RisingEdge(dut.clock)

    dut.data_mem_read_valid.value = 1
    dut.mem_write_sel.value       = 0b000   # SB (byte read)
    await RisingEdge(dut.clock)
    dut.data_mem_read_valid.value = 0

    for _ in range(timeout):
        await RisingEdge(dut.clock)
        await ReadOnly()

        if int(dut.data_mem_read_ready.value) == 1:
            data_value = dut.data_mem_read_data.value

            shift = (addr & 0x3) * 8
            selected_byte = data_value[shift + 7 : shift]

            assert selected_byte.is_resolvable, (
                f"Selected byte contains X/Z: "
                f"addr=0x{addr:08x}, "
                f"data={data_value}"
            )

            data = int(selected_byte)
            break
    else:
        raise AssertionError(
            f"data_mem_read_ready timeout addr=0x{addr:08x}"
        )

    await RisingEdge(dut.clock)

    return data

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
# TEST 1: data dm cache test.
# ------------------------------------------------
@cocotb.test()
async def cache_data_test(dut):
    dut._log.info("--------------------------------------------------")
    dut._log.info("==== PSC_ONE data cache test start ====")

    # CPU MONITOR START
    mon = CpuMonitorCounter()
    cocotb.start_soon(cpu_monitor_count(dut, mon))

    cocotb.start_soon(gen_clock(dut))
    await reset_dut(dut)
    await sdram_init_fin_wait(dut)

    # data dm Cache random test.
    random.seed(1234)

    for _ in range(1000):

        # 0x0000_0040 ～ 0x0040_0000 の範囲（4byteアライン）
        address = random.randrange(0x00000040, 0x00400000, 4)

        data = random.getrandbits(32)

        await cpu_data_write(dut, address, data, mode="CPU")
        value = await cpu_data_read(dut, address, mode="CPU")

        '''
        print(
            f"addr=0x{address:08X} "
            f"write=0x{data:08X} "
            f"read=0x{value:08X}"
        )
        '''

        assert value == data, (
            f"Data mismatch: "
            f"addr=0x{address:08X}, "
            f"expected=0x{data:08X}, "
            f"got=0x{value:08X}"
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

# ------------------------------------------------
# TEST 2: program dm cache test.
# ------------------------------------------------
@cocotb.test()
async def cache_program_test(dut):
    dut._log.info("--------------------------------------------------")
    dut._log.info("==== PSC_ONE program cache test start ====")

    # CPU MONITOR START
    mon = CpuMonitorCounter()
    cocotb.start_soon(cpu_monitor_count(dut, mon))

    cocotb.start_soon(gen_clock(dut))
    await reset_dut(dut)
    await sdram_init_fin_wait(dut)

    # data dm Cache random test.
    random.seed(1324)

    for _ in range(500):

        address = random.randrange(0x00000040, 0x00400000, 4)

        v = await cpu_program_read(dut, address)

        #print(v)
        #programメモリをWしていないのでXXXXが正常
        #Assertなし

        '''
        assert v.is_resolvable, (
            f"Unresolved value addr=0x{address:08X}"
        )

        value = int(v)
        expected = address    # 初期メモリパターンに合わせて変更

        assert value == expected, (
            f"Data mismatch: "
            f"addr=0x{address:08X}, "
            f"expected=0x{expected:08X}, "
            f"got=0x{value:08X}"
        )
        '''

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

# ------------------------------------------------
# TEST 3: data cache write back test.
# ------------------------------------------------
@cocotb.test()
async def cache_data_wb_test(dut):
    dut._log.info("--------------------------------------------------")
    dut._log.info("==== PSC_ONE data cache write back test start ====")

    # CPU MONITOR START
    mon = CpuMonitorCounter()
    cocotb.start_soon(cpu_monitor_count(dut, mon))

    cocotb.start_soon(gen_clock(dut))
    await reset_dut(dut)
    await sdram_init_fin_wait(dut)

    # data dm Cache random test.
    random.seed(1464)

    test_times = 5000

    for i in range(test_times):

        # 0x0000_0040 ～ 0x0010_0000 の範囲（4byteアライン）
        address = 4 * i
        #address = random.randrange(0x00000040, 0x00100000, 4)

        data    = random.getrandbits(32)
        await cpu_data_write(dut, address, data)

    # === WB Start ====
    await data_cache_wb_start(dut)

    # verify
    random.seed(1464)
    for i in range(test_times):

        # 0x0000_0040 ～ 0x0010_0000 の範囲（4byteアライン）
        address = 4 * i
        #address = random.randrange(0x00000040, 0x00100000, 4)

        data    = random.getrandbits(32)

        v = await cpu_program_read(dut, address)

        if v.is_resolvable:
            value = int(v)
            '''
            print(
                f"addr=0x{address:08X} "
                f"write=0x{data:08X} "
                f"read=0x{value:08X}"
            )
            '''

            assert value == data, (
                f"Data mismatch: "
                f"addr=0x{address:08X}, "
                f"expected=0x{data:08X}, "
                f"got=0x{value:08X}"
            )
        else:
            print(f"addr=0x{address:08X} value={v}")

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

# ------------------------------------------------
# TEST 4: data cache clear back test.
# ------------------------------------------------
@cocotb.test()
async def cache_data_clear_test(dut):
    dut._log.info("--------------------------------------------------")
    dut._log.info("==== PSC_ONE data cache clear test start ====")

    # CPU MONITOR START
    mon = CpuMonitorCounter()
    cocotb.start_soon(cpu_monitor_count(dut, mon))

    cocotb.start_soon(gen_clock(dut))
    await reset_dut(dut)
    await sdram_init_fin_wait(dut)

    # data dm Cache random test.
    random.seed(1234)

    expected = {}

    for _ in range(1000):
        address = random.randrange(0x40, 0x00400000, 4)
        data = random.getrandbits(32)

        expected[address] = data
        await cpu_data_write(dut, address, data)

    # === WB Start ====
    await data_cache_wb_start(dut)
    
    # === Cache Clear Start ====
    await data_cache_clear_start(dut)

    # verify
    random.seed(1234)

    for address, data in expected.items():
        value = await cpu_data_read(dut, address)

        '''
        print(
            f"addr=0x{address:08X} "
            f"write=0x{data:08X} "
            f"read=0x{value:08X}"
        )
        '''

        if value != data:
            print(
                f"ERROR addr=0x{address:08X} "
                f"expected=0x{data:08X} "
                f"actual=0x{value:08X}"
            )

        assert value == data

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


# ------------------------------------------------
# TEST 5: data dm cache test. (byte)
# ------------------------------------------------
@cocotb.test()
async def cache_data_byte_test(dut):
    dut._log.info("--------------------------------------------------")
    dut._log.info("==== PSC_ONE data cache byte test start ====")

    mon = CpuMonitorCounter()
    cocotb.start_soon(cpu_monitor_count(dut, mon))

    cocotb.start_soon(gen_clock(dut))
    await reset_dut(dut)
    await sdram_init_fin_wait(dut)

    # data dm Cache random test.
    random.seed(1234)

    for _ in range(3000):

        # 0x0000_0040 ～ 0x0040_0000 の範囲（1byteアライン）
        address = random.randrange(0x00000040, 0x00400000, 1)

        data = random.getrandbits(32) & 0x00FF

        await cpu_data_byte_write(dut, address, data)
        value = await cpu_data_byte_read(dut, address)

        '''
        print(
            f"addr=0x{address:08X} "
            f"write=0x{data:08X} "
            f"read=0x{value:08X}"
        )
        '''

        assert value == data, (
            f"Data mismatch: "
            f"addr=0x{address:08X}, "
            f"expected=0x{data:08X}, "
            f"got=0x{value:08X}"
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

# ------------------------------------------------
# TEST 6: data dm cache test. (sa port)
# ------------------------------------------------
@cocotb.test()
async def cache_data_sa_test(dut):
    dut._log.info("--------------------------------------------------")
    dut._log.info("==== PSC_ONE data cache test start ====")

    # CPU MONITOR START
    mon = CpuMonitorCounter()
    cocotb.start_soon(cpu_monitor_count(dut, mon))

    cocotb.start_soon(gen_clock(dut))
    await reset_dut(dut)
    await sdram_init_fin_wait(dut)

    # data dm Cache random test.
    random.seed(1234)

    for _ in range(1000):

        # 0x0000_0040 ～ 0x0040_0000 の範囲（4byteアライン）
        address = random.randrange(0x00000040, 0x00400000, 4)

        data = random.getrandbits(32)

        await cpu_data_write(dut, address, data, mode="SA")
        value = await cpu_data_read(dut, address, mode="SA")

        '''
        print(
            f"addr=0x{address:08X} "
            f"write=0x{data:08X} "
            f"read=0x{value:08X}"
        )
        '''

        assert value == data, (
            f"Data mismatch: "
            f"addr=0x{address:08X}, "
            f"expected=0x{data:08X}, "
            f"got=0x{value:08X}"
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

# ================================================================
# CPU / SA same-clock Write + Read test additions
#
# このブロックを既存の cocotb テストファイル末尾へ追加してください。
#
# Test:
#   1. CPU Write + SA Read を同一クロックで開始
#   2. SA Write  + CPU Read を同一クロックで開始
#
# Read と Write は別アドレスを使用します。
# 同一アドレスへの同時 Read/Write はキャッシュの read-during-write
# 仕様に依存するため、このテストでは扱いません。
# ================================================================

async def cpu_sa_same_clock_cpu_write_sa_read(
    dut,
    cpu_write_addr,
    cpu_write_data,
    sa_read_addr,
    expected_sa_read_data,
    timeout=2000
):
    """
    CPU Write と SA Read の valid を同じクロック区間で立てる。
    """

    dut.data_mem_write_valid.value = 0
    dut.sa_mem_read_valid.value    = 0

    # ------------------------------------------------------------
    # CPU/SA の両ポートが要求受付可能になるまで待つ
    # ------------------------------------------------------------
    for _ in range(timeout):
        await RisingEdge(dut.clock)
        await ReadOnly()

        if (
            int(dut.cpu_req_ready.value) == 1
            and
            int(dut.sa_req_ready.value) == 1
        ):
            break
    else:
        raise AssertionError(
            "CPU/SA req_ready timeout "
            f"cpu_write_addr=0x{cpu_write_addr:08X} "
            f"sa_read_addr=0x{sa_read_addr:08X}"
        )

    # ReadOnlyフェーズを抜ける
    await RisingEdge(dut.clock)

    # ------------------------------------------------------------
    # 要求内容を先に設定
    # ------------------------------------------------------------
    dut.data_mem_write_address.value = cpu_write_addr
    dut.mem_write_data.value         = cpu_write_data & 0xFFFF_FFFF
    dut.mem_write_sel.value          = 0b010

    dut.sa_mem_read_address.value    = sa_read_addr
    dut.sa_mem_write_sel.value       = 0b010

    # ------------------------------------------------------------
    # 同一クロック区間で valid を同時アサート
    # ------------------------------------------------------------
    dut.data_mem_write_valid.value = 1
    dut.sa_mem_read_valid.value    = 1

    await RisingEdge(dut.clock)

    dut.data_mem_write_valid.value = 0
    dut.sa_mem_read_valid.value    = 0

    cpu_write_done = False
    sa_read_done   = False
    sa_read_data   = None

    # ------------------------------------------------------------
    # CPU Write / SA Read の双方が完了するまで待つ
    # ------------------------------------------------------------
    for _ in range(timeout):
        await RisingEdge(dut.clock)
        await ReadOnly()

        if int(dut.data_mem_write_ready.value) == 1:
            cpu_write_done = True

        if int(dut.sa_mem_read_ready.value) == 1:
            sa_read_done = True
            sa_read_data = int(dut.sa_mem_read_data.value)

        if cpu_write_done and sa_read_done:
            break
    else:
        raise AssertionError(
            "same-clock CPU Write + SA Read timeout "
            f"cpu_write_done={cpu_write_done} "
            f"sa_read_done={sa_read_done}"
        )

    assert sa_read_data == expected_sa_read_data, (
        "SA read mismatch during CPU Write + SA Read: "
        f"addr=0x{sa_read_addr:08X}, "
        f"expected=0x{expected_sa_read_data:08X}, "
        f"got=0x{sa_read_data:08X}"
    )

    await RisingEdge(dut.clock)

    return sa_read_data

async def cpu_sa_same_clock_sa_write_cpu_read(
    dut,
    sa_write_addr,
    sa_write_data,
    cpu_read_addr,
    expected_cpu_read_data,
    timeout=2000
):
    """
    SA Write と CPU Read の valid を同じクロック区間で立てる。
    """

    dut.sa_mem_write_valid.value  = 0
    dut.data_mem_read_valid.value = 0

    # ------------------------------------------------------------
    # CPU/SA の両ポートが要求受付可能になるまで待つ
    # ------------------------------------------------------------
    for _ in range(timeout):
        await RisingEdge(dut.clock)
        await ReadOnly()

        if (
            int(dut.cpu_req_ready.value) == 1
            and
            int(dut.sa_req_ready.value) == 1
        ):
            break
    else:
        raise AssertionError(
            "CPU/SA req_ready timeout "
            f"sa_write_addr=0x{sa_write_addr:08X} "
            f"cpu_read_addr=0x{cpu_read_addr:08X}"
        )

    # ReadOnlyフェーズを抜ける
    await RisingEdge(dut.clock)

    # ------------------------------------------------------------
    # 要求内容を先に設定
    # ------------------------------------------------------------
    dut.sa_mem_write_address.value = sa_write_addr
    dut.sa_mem_write_data.value    = sa_write_data & 0xFFFF_FFFF
    dut.sa_mem_write_sel.value     = 0b010

    dut.data_mem_read_address.value = cpu_read_addr
    dut.mem_write_sel.value         = 0b010

    # ------------------------------------------------------------
    # 同一クロック区間で valid を同時アサート
    # ------------------------------------------------------------
    dut.sa_mem_write_valid.value  = 1
    dut.data_mem_read_valid.value = 1

    await RisingEdge(dut.clock)

    dut.sa_mem_write_valid.value  = 0
    dut.data_mem_read_valid.value = 0

    sa_write_done = False
    cpu_read_done = False
    cpu_read_data = None

    # ------------------------------------------------------------
    # SA Write / CPU Read の双方が完了するまで待つ
    # ------------------------------------------------------------
    for _ in range(timeout):
        await RisingEdge(dut.clock)
        await ReadOnly()

        if int(dut.sa_mem_write_ready.value) == 1:
            sa_write_done = True

        if int(dut.data_mem_read_ready.value) == 1:
            cpu_read_done = True
            cpu_read_data = int(dut.data_mem_read_data.value)

        if sa_write_done and cpu_read_done:
            break
    else:
        raise AssertionError(
            "same-clock SA Write + CPU Read timeout "
            f"sa_write_done={sa_write_done} "
            f"cpu_read_done={cpu_read_done}"
        )

    assert cpu_read_data == expected_cpu_read_data, (
        "CPU read mismatch during SA Write + CPU Read: "
        f"addr=0x{cpu_read_addr:08X}, "
        f"expected=0x{expected_cpu_read_data:08X}, "
        f"got=0x{cpu_read_data:08X}"
    )

    await RisingEdge(dut.clock)

    return cpu_read_data

# ------------------------------------------------
# TEST 7:
# CPU Write + SA Read / SA Write + CPU Read
# same clock request test
# ------------------------------------------------
@cocotb.test()
async def cache_cpu_sa_same_clock_write_read_test(dut):
    dut._log.info("--------------------------------------------------")
    dut._log.info(
        "==== CPU/SA same-clock Write + Read test start ===="
    )

    cocotb.start_soon(gen_clock(dut))

    await reset_dut(dut)
    await sdram_init_fin_wait(dut)

    random.seed(0x43505553)

    # 各用途で異なるアドレス範囲を使う
    cpu_write_base = 0x0010_0000
    sa_read_base   = 0x0011_0000
    sa_write_base  = 0x0012_0000
    cpu_read_base  = 0x0013_0000

    test_count = 256

    for index in range(test_count):
        cpu_write_addr = cpu_write_base + index * 4
        sa_read_addr   = sa_read_base   + index * 4
        sa_write_addr  = sa_write_base  + index * 4
        cpu_read_addr  = cpu_read_base  + index * 4

        cpu_write_data = random.getrandbits(32)
        sa_read_data   = random.getrandbits(32)
        sa_write_data  = random.getrandbits(32)
        cpu_read_data  = random.getrandbits(32)

        # --------------------------------------------------------
        # 同時Read側のデータを事前に用意
        # --------------------------------------------------------
        await cpu_data_write(
            dut,
            sa_read_addr,
            sa_read_data,
            mode="CPU"
        )

        await cpu_data_write(
            dut,
            cpu_read_addr,
            cpu_read_data,
            mode="CPU"
        )

        # --------------------------------------------------------
        # CPU Write + SA Read
        # --------------------------------------------------------
        await cpu_sa_same_clock_cpu_write_sa_read(
            dut=dut,
            cpu_write_addr=cpu_write_addr,
            cpu_write_data=cpu_write_data,
            sa_read_addr=sa_read_addr,
            expected_sa_read_data=sa_read_data
        )

        # CPU側Write結果をSA側から確認
        cpu_written_value = await cpu_data_read(
            dut,
            cpu_write_addr,
            mode="SA"
        )

        assert cpu_written_value == cpu_write_data, (
            "CPU write result mismatch: "
            f"addr=0x{cpu_write_addr:08X}, "
            f"expected=0x{cpu_write_data:08X}, "
            f"got=0x{cpu_written_value:08X}"
        )

        # --------------------------------------------------------
        # SA Write + CPU Read
        # --------------------------------------------------------
        await cpu_sa_same_clock_sa_write_cpu_read(
            dut=dut,
            sa_write_addr=sa_write_addr,
            sa_write_data=sa_write_data,
            cpu_read_addr=cpu_read_addr,
            expected_cpu_read_data=cpu_read_data
        )

        # SA側Write結果をCPU側から確認
        sa_written_value = await cpu_data_read(
            dut,
            sa_write_addr,
            mode="CPU"
        )

        assert sa_written_value == sa_write_data, (
            "SA write result mismatch: "
            f"addr=0x{sa_write_addr:08X}, "
            f"expected=0x{sa_write_data:08X}, "
            f"got=0x{sa_written_value:08X}"
        )

    dut._log.info(
        f"same-clock test count={test_count}"
    )
    dut._log.info(
        "==== PASS CPU/SA same-clock Write + Read test ===="
    )

# ------------------------------------------------
# TEST 8:
# Write Miss時に同一16Bラインの未更新ワードが保持されることを確認
# ------------------------------------------------
@cocotb.test()
async def cache_write_miss_preserve_line_test(dut):
    dut._log.info("--------------------------------------------------")
    dut._log.info(
        "==== Write Miss preserve existing line test start ===="
    )

    cocotb.start_soon(gen_clock(dut))

    await reset_dut(dut)
    await sdram_init_fin_wait(dut)

    # 16Bアラインされた1キャッシュライン
    base_addr = 0x0018_0000

    initial_words = [
        0x1111_1111,
        0x2222_2222,
        0x3333_3333,
        0x4444_4444,
    ]

    updated_word = 0xAAAA_AAAA
    updated_index = 2

    # --------------------------------------------------------
    # 外部メモリへ非ゼロの既存ラインを作る
    # 最初のStore後は同一ラインへのHitになるため、4ワードを構築できる
    # --------------------------------------------------------
    for index, data in enumerate(initial_words):
        await cpu_data_write(
            dut,
            base_addr + index * 4,
            data,
            mode="CPU"
        )

    # dirtyラインを外部メモリへ反映し、キャッシュをinvalid化する
    await data_cache_wb_start(dut)
    await data_cache_clear_start(dut)

    # --------------------------------------------------------
    # キャッシュにラインがない状態でword2だけを書き換える
    # --------------------------------------------------------
    await cpu_data_write(
        dut,
        base_addr + updated_index * 4,
        updated_word,
        mode="CPU"
    )

    expected_words = initial_words.copy()
    expected_words[updated_index] = updated_word

    # 更新対象以外の3ワードも、外部メモリの値を保持していることを確認
    for index, expected in enumerate(expected_words):
        address = base_addr + index * 4
        actual = await cpu_data_read(dut, address, mode="CPU")

        assert actual == expected, (
            "Write Miss corrupted existing cache line: "
            f"addr=0x{address:08X}, "
            f"expected=0x{expected:08X}, "
            f"got=0x{actual:08X}"
        )

    dut._log.info(
        "==== PASS Write Miss preserve existing line test ===="
    )