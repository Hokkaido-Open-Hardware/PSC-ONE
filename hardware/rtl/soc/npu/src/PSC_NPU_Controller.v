`timescale 1ns/1ps

module PSC_NPU_Controller #(
    // Exclusive accelerator selection (default: existing NPU).
    parameter bit ENABLE_NPU = 1'b1,
    parameter bit ENABLE_LPU = 1'b0,
    // Param
    parameter integer PE_N     = 4,     // Physical SA size: 4x4 fixed
    parameter integer MATRIX_N = 4,     // Default matrix size
    parameter integer MUL_NUM  = 4,     // Number of physical multipliers
    parameter integer OUT_SHIFT = 0,   // LPU INT8 arithmetic shift, 0..31
    parameter bit LPU_OUTPUT_INT32 = 1'b0 // Raw accumulators, row-major INT32
)(
    input  wire             clock,
    input  wire             reset_n,
    input  wire             signed_mode,

    // SA control
    input  wire             start,
    input  wire             sa_state_reset,
    input  wire [3:0]       sa_os_instruction,  // Reserved
    input  wire             sa_clear,

    // Runtime matrix size: 4, 8, 12, 16, ...
    input  wire [7:0]       matrix_size_x,
    input  wire [7:0]       matrix_size_y,

    // A/C rows: 1..255. Zero (or omitted port) preserves M=matrix_size_y.
    input  wire [7:0]       matrix_size_m,

    // SDRAM base address
    input  wire [31:0]      BASE_ADDR_A,
    input  wire [31:0]      BASE_ADDR_B,
    input  wire [31:0]      BASE_ADDR_C,

    // Cache request ready
    input  wire             sa_req_ready,

    // READ port
    output wire [31:0]      rd_read_addr,
    output wire             rd_read_valid,
    input  wire             rd_read_ready,
    input  wire [31:0]      rd_read_data,

    // WRITE port
    output reg              c_write_valid,
    output reg  [31:0]      c_write_addr,
    output reg  [31:0]      c_write_wdata,
    input  wire             c_write_ready,

    output reg              busy,
    output reg              done
);

    `ifdef COCOTB_SIM
    `ifdef DUMP_VCD_CTRL
    initial begin
        `ifdef DUMP_VCD
        $display("COCOTB_SIM SA DUMP_VCD ENABLE");
        $dumpfile("./wave/SystolicArray4x4_Ctrl_test.vcd");
        $dumpvars(0);
        `else
        $display("COCOTB_SIM SA verilator FST ENABLE");
        $dumpfile("./wave/SystolicArray4x4_Ctrl_test.fst");
        $dumpvars(0);
        `endif
    end
    `endif
    `endif

// ====================================================
// NPU
// ====================================================
generate
    if (ENABLE_NPU && ENABLE_LPU) begin : g_invalid_config
        // Intentionally unresolved: reject this configuration in synthesis
        // and elaboration, including tools that ignore initial assertions.
        PSC_NPU_ERROR_ENABLE_NPU_AND_ENABLE_LPU_ARE_EXCLUSIVE invalid_config();
    end else if (ENABLE_NPU) begin : g_npu_enabled

        PSC_NPU_Engine #(
            .PE_N                   (PE_N),
            .MATRIX_N               (MATRIX_N),
            .MUL_NUM                (MUL_NUM)
        ) u_npu (
            .clock                  (clock),
            .reset_n                (reset_n),
            .signed_mode            (signed_mode),
            .start                  (start),
            .sa_state_reset         (sa_state_reset),
            .sa_os_instruction      (sa_os_instruction),
            .sa_clear               (sa_clear),
            .matrix_size_x          (matrix_size_x),
            .matrix_size_y          (matrix_size_y),
            .matrix_size_m          (matrix_size_m),
            .BASE_ADDR_A            (BASE_ADDR_A),
            .BASE_ADDR_B            (BASE_ADDR_B),
            .BASE_ADDR_C            (BASE_ADDR_C),
            .sa_req_ready           (sa_req_ready),
            .rd_read_addr           (rd_read_addr),
            .rd_read_valid          (rd_read_valid),
            .rd_read_ready          (rd_read_ready),
            .rd_read_data           (rd_read_data),
            .c_write_valid          (c_write_valid),
            .c_write_addr           (c_write_addr),
            .c_write_wdata          (c_write_wdata),
            .c_write_ready          (c_write_ready),
            .busy                   (busy),
            .done                   (done)
        );
    end else if (ENABLE_LPU) begin : g_lpu_enabled
        PSC_LPU_Controller #(
            .OUT_SHIFT              (OUT_SHIFT),
            .OUTPUT_INT32           (LPU_OUTPUT_INT32)
        ) u_lpu (
            .clock                  (clock),
            .reset_n                (reset_n),
            .start                  (start),
            .sa_state_reset         (sa_state_reset),
            .sa_clear               (sa_clear),
            .matrix_size_x          (matrix_size_x),
            .matrix_size_y          (matrix_size_y),
            .matrix_size_m          (matrix_size_m),
            .BASE_ADDR_A            (BASE_ADDR_A),
            .BASE_ADDR_B            (BASE_ADDR_B),
            .BASE_ADDR_C            (BASE_ADDR_C),
            .sa_req_ready           (sa_req_ready),
            .rd_read_addr           (rd_read_addr),
            .rd_read_valid          (rd_read_valid),
            .rd_read_ready          (rd_read_ready),
            .rd_read_data           (rd_read_data),
            .c_write_valid          (c_write_valid),
            .c_write_addr           (c_write_addr),
            .c_write_wdata          (c_write_wdata),
            .c_write_ready          (c_write_ready),
            .busy                   (busy),
            .done                   (done)
        );
    end else begin : g_disabled
        assign rd_read_addr = 32'd0;
        assign rd_read_valid = 1'b0;
        assign c_write_valid = 1'b0;
        assign c_write_addr = 32'd0;
        assign c_write_wdata = 32'd0;
        assign busy = 1'b0;
        assign done = 1'b0;
    end
endgenerate

endmodule
