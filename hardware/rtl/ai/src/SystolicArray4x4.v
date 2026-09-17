// SystolicArray4x4.v
`timescale 1ns/1ps

module SystolicArray4x4 #(
    parameter integer DW      = 8,
    parameter integer PW      = 32,
    parameter integer SW      = 32,
    parameter integer MUL_NUM = 2
)(
    input  wire              clock,
    input  wire              reset_n,

    // Shared controls
    input  wire              data_clear,
    input  wire              en_b_shift_bottom,
    input  wire              en_shift_right,
    input  wire              start_pulse,

    // External boundaries
    //
    // a_left_in_bus:
    //   [DW-1:0]       = row 0
    //   [2*DW-1:DW]    = row 1
    //   [3*DW-1:2*DW]  = row 2
    //   [4*DW-1:3*DW]  = row 3
    //
    // b_top_in_bus:
    //   [DW-1:0]       = column 0
    //   [2*DW-1:DW]    = column 1
    //   [3*DW-1:2*DW]  = column 2
    //   [4*DW-1:3*DW]  = column 3
    input  wire [4*DW-1:0]   a_left_in_bus,
    input  wire [4*DW-1:0]   b_top_in_bus,

    // Output select: 0～15
    //
    //  0  1  2  3
    //  4  5  6  7
    //  8  9 10 11
    // 12 13 14 15
    input  wire [5:0]        ps_select,
    output reg  [SW-1:0]     ps_acc_out,

    // Status
    output wire              busy_out,
    output wire              done_out
);

    // ========================================================
    // Simulation dump
    // ========================================================

    `ifdef COCOTB_SIM
    `ifdef DUMP_VCD_SA
    initial begin
        `ifdef DUMP_VCD
            $display("COCOTB_SIM SA4x4 DUMP_VCD ENABLE");
            $dumpfile("./wave/SystolicArray4x4_test.vcd");
            $dumpvars(0, SystolicArray4x4);
        `else
            $display("COCOTB_SIM SA4x4 verilator FST ENABLE");
            $dumpfile("./wave/SystolicArray4x4_test.fst");
            $dumpvars(0, SystolicArray4x4);
        `endif
    end
    `endif
    `endif

    // ========================================================
    // Thread allocation
    //
    // Thread index = row * 4 + column
    //
    //      col0 col1 col2 col3
    // row0   0    1    2    3
    // row1   4    5    6    7
    // row2   8    9   10   11
    // row3  12   13   14   15
    // ========================================================

    localparam integer ARRAY_SIZE = 4;
    localparam integer THREADS    = ARRAY_SIZE * ARRAY_SIZE;

    // ========================================================
    // PE_INT packed interface
    // ========================================================

    wire [THREADS*DW-1:0] a_in_threads;
    wire [THREADS*DW-1:0] b_in_threads;

    wire [THREADS*DW-1:0] a_shift_threads;
    wire [THREADS*DW-1:0] b_shift_threads;

    wire [THREADS*SW-1:0] ps_acc_threads;

    // ========================================================
    // Shared multiplier interface
    // ========================================================

    wire [THREADS-1:0]    data_out_valid;
    wire [THREADS-1:0]    data_in_ready;

    wire [THREADS*DW-1:0] data_A_threads;
    wire [THREADS*DW-1:0] data_B_threads;
    wire [THREADS*PW-1:0] result_C_threads;

    // ========================================================
    // 4x4 systolic routing
    //
    // A:
    //   column 0 <- external left boundary
    //   column n <- previous columnのPE出力
    //
    // B:
    //   row 0 <- external top boundary
    //   row n <- previous rowのPE出力
    //
    // PE_INT内部のnonblocking assignmentにより、
    // 隣接PEには前サイクルの値が伝搬する。
    // ========================================================

    genvar row;
    genvar col;

    generate
        for (row = 0; row < ARRAY_SIZE; row = row + 1) begin : GEN_ROW
            for (col = 0; col < ARRAY_SIZE; col = col + 1) begin : GEN_COL

                localparam integer THREAD_INDEX =
                    row * ARRAY_SIZE + col;

                // ------------------------------------------------
                // A routing: left -> right
                // ------------------------------------------------

                if (col == 0) begin : GEN_A_LEFT_BOUNDARY

                    assign a_in_threads[
                        THREAD_INDEX*DW +: DW
                    ] = a_left_in_bus[row*DW +: DW];

                end
                else begin : GEN_A_FROM_LEFT_PE

                    localparam integer LEFT_THREAD_INDEX =
                        row * ARRAY_SIZE + (col - 1);

                    assign a_in_threads[
                        THREAD_INDEX*DW +: DW
                    ] = a_shift_threads[
                        LEFT_THREAD_INDEX*DW +: DW
                    ];

                end

                // ------------------------------------------------
                // B routing: top -> bottom
                // ------------------------------------------------

                if (row == 0) begin : GEN_B_TOP_BOUNDARY

                    assign b_in_threads[
                        THREAD_INDEX*DW +: DW
                    ] = b_top_in_bus[col*DW +: DW];

                end
                else begin : GEN_B_FROM_TOP_PE

                    localparam integer TOP_THREAD_INDEX =
                        (row - 1) * ARRAY_SIZE + col;

                    assign b_in_threads[
                        THREAD_INDEX*DW +: DW
                    ] = b_shift_threads[
                        TOP_THREAD_INDEX*DW +: DW
                    ];

                end
            end
        end
    endgenerate

    // ========================================================
    // One PE_INT
    //
    // FSM      : 1 set
    // Datapath : 16 thread contexts
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
    // MUL_NUM=16:
    //   16論理PEを1サイクルで同時乗算
    //
    // MUL_NUM=4:
    //   最大4件ずつ、4グループに分けて処理
    //
    // MUL_NUM=2:
    //   最大2件ずつ、8グループに分けて処理
    //
    // MUL_NUM=1:
    //   1個の乗算器で16論理PEを順次処理
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
    // Output Stationary accumulator select
    //
    // ps_select:
    //  0  = PE(0,0)
    //  1  = PE(0,1)
    //  ...
    // 15  = PE(3,3)
    // ========================================================

    always @(*) begin
        ps_acc_out =
            ps_acc_threads[ps_select*SW +: SW];
    end

endmodule