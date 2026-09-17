# ===============================================================
#  NISHIHARU simulate_32bit_to_128bit_axi_bridge TEST (FINAL)
# ===============================================================
import cocotb
from cocotb.triggers import Timer, RisingEdge, ReadOnly

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
# AXI slave (drive)
# ------------------------------------------------
async def axi_slave_driver(dut, state):

    dut.m_axi_awready.value = 1
    dut.m_axi_wready.value  = 1
    dut.m_axi_arready.value = 1

    dut.m_axi_bvalid.value = 0
    dut.m_axi_bresp.value  = 0

    dut.m_axi_rvalid.value = 0
    dut.m_axi_rdata.value  = 0
    dut.m_axi_rlast.value  = 0

    while True:
        await RisingEdge(dut.clock)

        # WRITE response
        if state["write_done"]:
            dut.m_axi_bvalid.value = 1
        else:
            dut.m_axi_bvalid.value = 0

        # READ data: 32bit x 4 beat = 128bit
        if state["reading"]:
            if state["read_idx"] < 4:
                dut.m_axi_rvalid.value = 1
                dut.m_axi_rdata.value  = state["memory"][state["read_idx"]]
                dut.m_axi_rlast.value  = (state["read_idx"] == 3)
            else:
                dut.m_axi_rvalid.value = 0
                dut.m_axi_rlast.value  = 0
        else:
            dut.m_axi_rvalid.value = 0
            dut.m_axi_rlast.value  = 0

# ------------------------------------------------
# AXI slave (monitor)
# ------------------------------------------------
async def axi_slave_monitor(dut, state):

    while True:
        await RisingEdge(dut.clock)
        await ReadOnly()

        # ---------------- WRITE ----------------
        if int(dut.m_axi_awvalid.value):
            state["write_idx"] = 0
            state["write_done"] = False

        if int(dut.m_axi_wvalid.value):
            data = int(dut.m_axi_wdata.value)

            idx = state["write_idx"]
            if idx < 4:
                state["memory"][idx] = data
                dut._log.info(f"W[{idx}] = 0x{data:08x}")
                state["write_idx"] += 1

            if int(dut.m_axi_wlast.value):
                state["write_done"] = True

        if int(dut.m_axi_bvalid.value) and int(dut.m_axi_bready.value):
            state["write_done"] = False

        # ---------------- READ ----------------
        if int(dut.m_axi_arvalid.value):
            state["read_idx"] = 0
            state["reading"]  = True

        if state["reading"] and int(dut.m_axi_rready.value):
            idx = state["read_idx"]

            if idx < 4:
                data = state["memory"][idx]
                dut._log.info(f"R[{idx}] = 0x{data:08x}")

                state["read_idx"] += 1

                if idx == 3:
                    state["reading"] = False

# ------------------------------------------------
# TEST
# ------------------------------------------------
@cocotb.test()
async def axi_test1(dut):

    dut._log.info("==== AXI 32bit to 128bit bridge test start ====")

    cocotb.start_soon(gen_clock(dut))

    state = {
        "memory": [0] * 4,
        "write_idx": 0,
        "read_idx": 0,
        "reading": False,
        "write_done": False
    }

    cocotb.start_soon(axi_slave_driver(dut, state))
    cocotb.start_soon(axi_slave_monitor(dut, state))

    # reset
    dut.reset_n.value = 0
    for _ in range(5):
        await RisingEdge(dut.clock)
    dut.reset_n.value = 1

    for _ in range(5):
        await RisingEdge(dut.clock)

    # ------------------------------------------------
    # WRITE
    # ------------------------------------------------
    test_data = 0x112233445566778899AABBCCDDEEFF00

    dut.write_addr.value  = 0x1000
    dut.write_data.value  = test_data
    dut.write_valid.value = 1

    while True:
        await RisingEdge(dut.clock)
        if dut.write_ready.value == 1:
            break

    dut.write_valid.value = 0
    dut._log.info("WRITE DONE")

    for _ in range(5):
        await RisingEdge(dut.clock)

    # ------------------------------------------------
    # READ
    # ------------------------------------------------
    dut.read_addr.value  = 0x1000
    dut.read_valid.value = 1

    while True:
        await RisingEdge(dut.clock)
        if dut.read_ready.value == 1:
            break

    dut.read_valid.value = 0

    read_data = int(dut.read_data.value)

    dut._log.info(f"READ DATA = 0x{read_data:032x}")

    # ------------------------------------------------
    # CHECK
    # ------------------------------------------------
    assert read_data == test_data, \
        f"Mismatch!\nread=0x{read_data:032x}\nexp =0x{test_data:032x}"

    dut._log.info("==== PASS ====")