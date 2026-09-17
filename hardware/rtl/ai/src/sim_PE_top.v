`timescale 1ns/1ps

module sim_PE_top #(
    parameter integer DW       = 8,
    parameter integer PW       = 32,
    parameter integer SW       = PW,
    parameter integer THREADS  = 2,
    parameter integer MUL_NUM  = 1
)(
    // Clock & Reset
    input  wire                         clock,
    input  wire                         reset_n,

    // Common control
    input  wire                         data_clear,
    input  wire                         start,
    input  wire                         en_b_shift_bottom,
    input  wire                         en_shift_right,

    // Threadごとの入力
    input  wire [THREADS*DW-1:0]        b_in,
    input  wire [THREADS*DW-1:0]        a_in,

    // Status
    output wire                         busy,
    output wire                         done,

    // Threadごとの隣接PE出力
    output wire [THREADS*DW-1:0]        a_shift_to_right,
    output wire [THREADS*DW-1:0]        b_shift_to_bottom,
    output wire [THREADS*SW-1:0]        ps_acc
);

    `ifdef COCOTB_SIM
    `ifdef DUMP_VCD_PE
    initial begin
        `ifdef DUMP_VCD
            $display("COCOTB_SIM PE DUMP_VCD ENABLE");
            $dumpfile("./wave/PE_INT_test.vcd");
            $dumpvars(0, sim_PE_top);
        `else
            $display("COCOTB_SIM PE verilator FST ENABLE");
            $dumpfile("./wave/PE_INT_test.fst");
            $dumpvars(0, sim_PE_top);
        `endif
    end
    `endif
    `endif

    // ========================================================
    // PE_INT <-> PE_mult interface
    // ========================================================

    wire [THREADS-1:0]        data_out_valid;
    wire [THREADS-1:0]        data_in_ready;

    wire [THREADS*DW-1:0]     data_A;
    wire [THREADS*DW-1:0]     data_B;
    wire [THREADS*PW-1:0]     result_C;

    // ========================================================
    // PE with shared FSM and two thread contexts
    // ========================================================

    PE_INT #(
        .DW       (DW),
        .PW       (PW),
        .SW       (SW),
        .THREADS  (THREADS)
    ) u_pe (
        .clock              (clock),
        .reset_n            (reset_n),

        .data_clear         (data_clear),
        .start              (start),

        .en_b_shift_bottom  (en_b_shift_bottom),
        .en_shift_right     (en_shift_right),

        .b_in               (b_in),
        .a_in               (a_in),

        .data_out_valid     (data_out_valid),
        .data_in_ready      (data_in_ready),

        .data_A             (data_A),
        .data_B             (data_B),
        .result_C           (result_C),

        .busy               (busy),
        .done               (done),

        .a_shift_to_right   (a_shift_to_right),
        .b_shift_to_bottom  (b_shift_to_bottom),
        .ps_acc             (ps_acc)
    );

    // ========================================================
    // Two parallel multipliers
    // ========================================================

    PE_mult #(
        .DW       (DW),
        .PW       (PW),
        .SW       (SW),
        .N        (THREADS),
        .MUL_NUM  (MUL_NUM)
    ) u_mult (
        .clock              (clock),
        .reset_n            (reset_n),

        .data_in_valid      (data_out_valid),
        .data_out_ready     (data_in_ready),

        .data_A             (data_A),
        .data_B             (data_B),
        .result_C           (result_C)
    );

endmodule