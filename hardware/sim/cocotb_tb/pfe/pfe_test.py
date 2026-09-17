# ===============================================================
#  PSC_PFE cocotb TEST
# ===============================================================
import cocotb
from cocotb.triggers import Timer, RisingEdge, ReadOnly

CLK_NS = 10

PFE_IF_DATA = 0x10008000
PFE_IF_CTRL = 0x10008004

CMD_START   = 1
CMD_CLEAR   = 2
CMD_WRITE_Q = 3
CMD_WRITE_X = 4

READ_ENERGY = 1
READ_STATUS = 2
READ_CUR_X  = 3


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
# reset
# ------------------------------------------------
async def reset_dut(dut):

    dut.reset_n.value = 0

    dut.cpu_rvalid.value = 0
    dut.cpu_raddr.value  = 0

    dut.cpu_wvalid.value = 0
    dut.cpu_waddr.value  = 0
    dut.cpu_wdata.value  = 0

    for _ in range(10):
        await RisingEdge(dut.clock)

    dut.reset_n.value = 1

    for _ in range(10):
        await RisingEdge(dut.clock)


# ------------------------------------------------
# CPU Write
# ------------------------------------------------
async def cpu_write(dut, addr, data):

    dut.cpu_waddr.value = addr
    dut.cpu_wdata.value = data
    dut.cpu_wvalid.value = 1
    await RisingEdge(dut.clock)
    dut.cpu_wvalid.value = 0

    while True:
        await RisingEdge(dut.clock)

        if int(dut.cpu_wready.value):
            break

    dut.cpu_wvalid.value = 0

    await RisingEdge(dut.clock)


# ------------------------------------------------
# CPU Read
# ------------------------------------------------
async def cpu_read(dut, addr):

    dut.cpu_raddr.value = addr
    dut.cpu_rvalid.value = 1
    await RisingEdge(dut.clock)
    dut.cpu_rvalid.value = 0

    while True:
        await RisingEdge(dut.clock)

        if int(dut.cpu_rready.value):
            data = int(dut.cpu_rdata.value)
            break

    dut.cpu_rvalid.value = 0

    await RisingEdge(dut.clock)

    return data

# ------------------------------------------------
async def write_qubo(dut, q):

    for idx, value in enumerate(q):

        await cpu_write(dut, PFE_IF_DATA, value & 0xffffffff)
        await cpu_write(
            dut,
            PFE_IF_CTRL,
            (idx << 8) | CMD_WRITE_Q
        )

# ------------------------------------------------
async def write_x(dut, x):

    await cpu_write(
        dut,
        PFE_IF_CTRL,
        (x << 8) | CMD_WRITE_X
    )

# ------------------------------------------------
async def read_energy(dut):

    await cpu_write(
        dut,
        PFE_IF_CTRL,
        (READ_ENERGY << 16)
    )

    e = await cpu_read(dut, PFE_IF_DATA)

    if e & 0x80000000:
        e -= 1 << 32

    return e

# ------------------------------------------------
async def wait_done(dut, timeout=1000):

    for _ in range(timeout):

        await cpu_write(
            dut,
            PFE_IF_CTRL,
            (READ_STATUS << 16)
        )

        status = await cpu_read(
            dut,
            PFE_IF_DATA
        )

        done = (status >> 1) & 1

        if done:
            return

        await RisingEdge(dut.clock)

    raise AssertionError("PFE timeout")

# ------------------------------------------------
# TEST 1
# ------------------------------------------------
@cocotb.test()
async def pfe_basic_test(dut):

    dut._log.info("==== PSC_PFE TEST1 START ====")

    cocotb.start_soon(gen_clock(dut))

    await reset_dut(dut)
    await cpu_write(dut, PFE_IF_CTRL, CMD_CLEAR)

    await write_qubo(dut, [
        -1,
        2,
        2,
        -3
    ])

    await write_x(dut, 0b01)
    await cpu_write(dut, PFE_IF_CTRL, CMD_START)

    # wait
    await wait_done(dut)

    assert await read_energy(dut) == -1

    dut._log.info("==== PASS ====")


# ------------------------------------------------
# TEST 2 : 2-variable QUBO
# ------------------------------------------------
@cocotb.test()
async def pfe_qubo2_test(dut):

    dut._log.info("==== PSC_PFE TEST2 START ====")

    cocotb.start_soon(gen_clock(dut))

    await reset_dut(dut)

    for i in range(64):
        await cpu_write(dut, PFE_IF_DATA, 0)
        await cpu_write(dut, PFE_IF_CTRL, (i << 8) | CMD_WRITE_Q)

    await write_x(dut, 0b11)
    await cpu_write(dut, PFE_IF_CTRL, CMD_START)

    # wait
    await wait_done(dut)

    assert await read_energy(dut) == 0

    dut._log.info("==== PASS TEST2 ====")

# ------------------------------------------------
# TEST 3 : Full 8-bit verification
# ------------------------------------------------
@cocotb.test()
async def pfe_full8_test(dut):

    dut._log.info("==== PSC_PFE TEST3 START ====")

    cocotb.start_soon(gen_clock(dut))

    await reset_dut(dut)
    await cpu_write(dut, PFE_IF_CTRL, CMD_CLEAR)

    #
    # Q matrix (8x8)
    #
    Q = [
        [-1,  2,  1,  0,  3, -2,  1,  0],
        [ 2, -3,  2,  1,  0,  0, -1,  2],
        [ 1,  2, -2,  1,  0,  2,  0, -1],
        [ 0,  1,  1, -1,  2,  0,  1,  0],
        [ 3,  0,  0,  2, -4,  1,  0,  2],
        [-2,  0,  2,  0,  1, -2,  2,  1],
        [ 1, -1,  0,  1,  0,  2, -1,  3],
        [ 0,  2, -1,  0,  2,  1,  3, -2],
    ]

    #
    # Write Q
    #
    flat = []
    for r in Q:
        flat.extend(r)

    await write_qubo(dut, flat)

    #
    # Verify all x
    #
    for x in range(256):

        await write_x(dut, x)
        await cpu_write(dut, PFE_IF_CTRL, CMD_START)

        await wait_done(dut)

        rtl_energy = await read_energy(dut)

        #
        # CPU reference
        #
        ref = 0

        for i in range(8):
            xi = (x >> i) & 1

            for j in range(8):
                xj = (x >> j) & 1

                if xi and xj:
                    ref += Q[i][j]

        print(
            f"x={x:08b}  "
            f"RTL={rtl_energy:6d}  "
            f"REF={ref:6d}"
        )

        assert rtl_energy == ref, (
            f"x=0x{x:02X} rtl={rtl_energy} ref={ref}"
        )

    dut._log.info("==== PASS TEST3 ====")