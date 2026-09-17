// SystolicArray2x2.v
`timescale 1ns/1ps

module SystolicArray2x2 #(
    parameter integer DW      = 8,
    parameter integer PW      = 32,
    parameter integer SW      = 32,
    parameter integer MUL_NUM = 2
)(
    input  wire         clock,
    input  wire         reset_n,

    // Shared controls
    input  wire         data_clear,
    input  wire         en_b_shift_bottom,
    input  wire         en_shift_right,
    input  wire         start_pulse,

    // External boundaries
    input  wire [15:0]  a_left_in_bus,
    input  wire [15:0]  b_top_in_bus,

    // Output select
    input  wire [5:0]   ps_select,
    output reg  [31:0]  ps_acc_out,

    // Status
    output wire         busy_out,
    output wire         done_out
);

    wire [31:0]  ps_acc_0;
    wire [31:0]  ps_acc_1;
    wire [31:0]  ps_acc_2;
    wire [31:0]  ps_acc_3;

    // ========================================================
    // Simulation dump
    // ========================================================

    `ifdef COCOTB_SIM
    `ifdef DUMP_VCD_SA
    initial begin
        `ifdef DUMP_VCD
            $display("COCOTB_SIM SA DUMP_VCD ENABLE");
            $dumpfile("./wave/SystolicArray2x2_test.vcd");
            $dumpvars(0, SystolicArray2x2);
        `else
            $display("COCOTB_SIM SA verilator FST ENABLE");
            $dumpfile("./wave/SystolicArray2x2_test.fst");
            $dumpvars(0, SystolicArray2x2);
        `endif
    end
    `endif
    `endif

    // ========================================================
    // Thread allocation
    //
    // Thread 0 = PE(0,0)
    // Thread 1 = PE(0,1)
    // Thread 2 = PE(1,0)
    // Thread 3 = PE(1,1)
    // ========================================================

    localparam integer THREADS = 4;     // 2 x 2 = 4 固定

    localparam integer T00 = 0;
    localparam integer T01 = 1;
    localparam integer T10 = 2;
    localparam integer T11 = 3;

    // ========================================================
    // External boundary signals
    // ========================================================

    wire [DW-1:0] a_left_row0;
    wire [DW-1:0] a_left_row1;

    wire [DW-1:0] b_top_col0;
    wire [DW-1:0] b_top_col1;

    assign a_left_row0 = a_left_in_bus[DW-1:0];
    assign a_left_row1 = a_left_in_bus[2*DW-1:DW];

    assign b_top_col0 = b_top_in_bus[DW-1:0];
    assign b_top_col1 = b_top_in_bus[2*DW-1:DW];

    // ========================================================
    // PE_INT packed interface
    // ========================================================

    wire [THREADS*DW-1:0] a_in_threads;
    wire [THREADS*DW-1:0] b_in_threads;

    wire [THREADS*DW-1:0] a_shift_threads;
    wire [THREADS*DW-1:0] b_shift_threads;

    wire [THREADS*SW-1:0] ps_acc_threads;

    // ========================================================
    // Current thread outputs
    // ========================================================

    wire [DW-1:0] a_t00;
    wire [DW-1:0] a_t01;
    wire [DW-1:0] a_t10;
    wire [DW-1:0] a_t11;

    wire [DW-1:0] b_t00;
    wire [DW-1:0] b_t01;
    wire [DW-1:0] b_t10;
    wire [DW-1:0] b_t11;

    wire [SW-1:0] sum_t00;
    wire [SW-1:0] sum_t01;
    wire [SW-1:0] sum_t10;
    wire [SW-1:0] sum_t11;

    assign a_t00 = a_shift_threads[T00*DW +: DW];
    assign a_t01 = a_shift_threads[T01*DW +: DW];
    assign a_t10 = a_shift_threads[T10*DW +: DW];
    assign a_t11 = a_shift_threads[T11*DW +: DW];

    assign b_t00 = b_shift_threads[T00*DW +: DW];
    assign b_t01 = b_shift_threads[T01*DW +: DW];
    assign b_t10 = b_shift_threads[T10*DW +: DW];
    assign b_t11 = b_shift_threads[T11*DW +: DW];

    // ========================================================
    // 2x2 systolic A routing
    //
    // PE00 <- external row 0
    // PE01 <- previous PE00
    // PE10 <- external row 1
    // PE11 <- previous PE10
    //
    // Nonblocking assignmentにより、PE01/PE11は前サイクル値を取得
    // ========================================================

    assign a_in_threads[T00*DW +: DW] = a_left_row0;
    assign a_in_threads[T01*DW +: DW] = a_t00;
    assign a_in_threads[T10*DW +: DW] = a_left_row1;
    assign a_in_threads[T11*DW +: DW] = a_t10;

    // ========================================================
    // 2x2 systolic B routing
    //
    // PE00 <- external column 0
    // PE01 <- external column 1
    // PE10 <- previous PE00
    // PE11 <- previous PE01
    // ========================================================

    assign b_in_threads[T00*DW +: DW] = b_top_col0;
    assign b_in_threads[T01*DW +: DW] = b_top_col1;
    assign b_in_threads[T10*DW +: DW] = b_t00;
    assign b_in_threads[T11*DW +: DW] = b_t01;

    // ========================================================
    // Shared multiplier interface
    // ========================================================

    wire [THREADS-1:0]    data_out_valid;
    wire [THREADS-1:0]    data_in_ready;

    wire [THREADS*DW-1:0] data_A_threads;
    wire [THREADS*DW-1:0] data_B_threads;
    wire [THREADS*PW-1:0] result_C_threads;

    // ========================================================
    // One PE_INT
    //
    // FSM      : 1 set
    // Datapath : 4 thread contexts
    // ========================================================

    PE_INT #(
        .DW      (DW),
        .PW      (PW),
        .SW      (SW),
        .THREADS (THREADS)
    ) u_pe_threads (
        .clock              (clock),
        .reset_n            (reset_n),

        .data_clear         (data_clear),
        .start              (start_pulse),

        .en_b_shift_bottom  (en_b_shift_bottom),
        .en_shift_right     (en_shift_right),

        .b_in               (b_in_threads),
        .a_in               (a_in_threads),

        .data_out_valid     (data_out_valid),
        .data_in_ready      (data_in_ready),

        .data_A             (data_A_threads),
        .data_B             (data_B_threads),
        .result_C           (result_C_threads),

        .busy               (busy_out),
        .done               (done_out),

        .a_shift_to_right   (a_shift_threads),
        .b_shift_to_bottom  (b_shift_threads),
        .ps_acc             (ps_acc_threads)
    );

    // ========================================================
    // Shared PE_mult
    //
    // MUL_NUM=4:
    //   4論理PEを同時乗算
    //
    // MUL_NUM=2:
    //   最大2件ずつ処理
    //
    // MUL_NUM=1:
    //   1個の乗算器で4論理PEを順次処理
    // ========================================================

    PE_mult #(
        .DW      (DW),
        .PW      (PW),
        .SW      (SW),
        .N       (THREADS),
        .MUL_NUM (MUL_NUM)
    ) u_mult (
        .clock          (clock),
        .reset_n        (reset_n),

        .data_in_valid  (data_out_valid),
        .data_out_ready (data_in_ready),

        .data_A         (data_A_threads),
        .data_B         (data_B_threads),
        .result_C       (result_C_threads)
    );

    // ========================================================
    // Output Stationary accumulators
    // ========================================================

    assign ps_acc_0 = ps_acc_threads[T00*SW +: SW];
    assign ps_acc_1 = ps_acc_threads[T01*SW +: SW];
    assign ps_acc_2 = ps_acc_threads[T10*SW +: SW];
    assign ps_acc_3 = ps_acc_threads[T11*SW +: SW];

    always @(*) begin
        case (ps_select)
            0: ps_acc_out <= ps_acc_threads[T00*SW +: SW];
            1: ps_acc_out <= ps_acc_threads[T01*SW +: SW];
            2: ps_acc_out <= ps_acc_threads[T10*SW +: SW];
            3: ps_acc_out <= ps_acc_threads[T11*SW +: SW];
            default: ;
        endcase
    end

endmodule