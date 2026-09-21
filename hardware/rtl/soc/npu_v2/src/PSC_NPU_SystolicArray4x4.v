// SystolicArray4x4.v
`timescale 1ns/1ps

// Two-term 4x4 virtual array: scheduler -> shift/sign lanes -> WB -> ACC16.
module PSC_NPU_SystolicArray4x4 #(parameter integer LANES = 8) (
    input  wire              clock,
    input  wire              reset_n,
    input  wire              signed_mode,

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
    //   [4*DW-1:3*DW] = row 3
    //
    // b_top_in_bus:
    //   [DW-1:0]       = column 0
    //   [2*DW-1:DW]    = column 1
    //   [3*DW-1:2*DW]  = column 2
    //   [4*DW-1:3*DW] = column 3
    input  wire [31:0]       a_left_in_bus,
    input  wire [31:0]       b_top_in_bus,

    // Output select: 0～15
    //
    //  0  1  2  3
    //  4  5  6  7
    //  8  9 10 11
    // 12 13 14 15
    input  wire [5:0]        ps_select,
    output reg  [31:0]       ps_acc_out,

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
            $dumpvars(0, PSC_NPU_SystolicArray4x4);
        `else
            $display("COCOTB_SIM SA4x4 verilator FST ENABLE");
            $dumpfile("./wave/SystolicArray4x4_test.fst");
            $dumpvars(0, PSC_NPU_SystolicArray4x4);
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

    localparam integer DW = 8;
    localparam integer SW = 32;
    localparam integer ARRAY_SIZE = 4;
    localparam integer THREADS    = ARRAY_SIZE * ARRAY_SIZE;

    // ========================================================
    // Packed shift contexts and accumulator outputs
    // ========================================================

    wire [THREADS*DW-1:0] a_in_threads;
    wire [THREADS*DW-1:0] b_in_threads;

    wire [THREADS*DW-1:0] a_shift_threads;
    wire [THREADS*DW-1:0] b_shift_threads;

    wire [THREADS*SW-1:0] ps_acc_threads;

    // A/B shift context is unchanged. Snapshot storage lives in u_pot.
    reg [127:0] data_A_threads;
    reg [127:0] data_B_threads;
    assign a_shift_threads = data_A_threads;
    assign b_shift_threads = data_B_threads;

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            data_A_threads <= 128'd0;
            data_B_threads <= 128'd0;
        end else if (data_clear) begin
            data_A_threads <= 128'd0;
            data_B_threads <= 128'd0;
        end else begin
            if (en_shift_right) data_A_threads <= a_in_threads;
            if (en_b_shift_bottom) data_B_threads <= b_in_threads;
        end
    end

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
    // shift registerのnonblocking assignmentにより、
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

    wire capture;
    wire issue;
    wire phase;
    wire [1:0] group_index;
    wire signed_mode_latched;
    wire acc_clear;
    wire [LANES-1:0] wb_valid;
    wire [LANES*4-1:0] wb_id;
    wire [LANES*32-1:0] wb_data;

    PSC_NPU_MACScheduler #(.LANES(LANES)) u_scheduler (
        .clock(clock), .reset_n(reset_n), .start(start_pulse),
        .data_clear(data_clear), .signed_mode(signed_mode),
        .capture(capture), .issue(issue), .phase(phase), .group_index(group_index),
        .signed_mode_latched(signed_mode_latched), .acc_clear(acc_clear),
        .busy(busy_out), .done(done_out)
    );

    PSC_NPU_PotLanes #(.LANES(LANES)) u_pot (
        .clock(clock), .reset_n(reset_n), .capture(capture), .issue(issue),
        .phase(phase), .group_index(group_index), .signed_mode(signed_mode_latched),
        .data_A(data_A_threads), .data_B(data_B_threads),
        .wb_valid(wb_valid), .wb_id(wb_id), .wb_data(wb_data)
    );

    PSC_NPU_AccBank #(.LANES(LANES)) u_acc_bank (
        .clock(clock), .reset_n(reset_n), .clear(acc_clear),
        .wb_valid(wb_valid), .wb_id(wb_id), .wb_data(wb_data),
        .ps_acc(ps_acc_threads)
    );

    `ifdef NPU_ASSERTIONS
    integer check_lane;
    integer other_lane;
    always @(posedge clock) begin
        if (reset_n) begin
            if (acc_clear && |wb_valid)
                $fatal(1, "NPU clear overlaps pending write-back");
            if (done_out && |wb_valid)
                $fatal(1, "NPU done before write-back drain");
            for (check_lane = 0; check_lane < LANES; check_lane = check_lane + 1) begin
                if (wb_valid[check_lane]) begin
                    if ((wb_id[check_lane*4 +: 4] % LANES) != check_lane)
                        $fatal(1, "NPU write-back lane/ID mismatch");
                    for (other_lane = check_lane + 1; other_lane < LANES; other_lane = other_lane + 1)
                        if (wb_valid[other_lane] &&
                            wb_id[check_lane*4 +: 4] == wb_id[other_lane*4 +: 4])
                            $fatal(1, "NPU duplicate write-back destination");
                end
            end
        end
    end
    `endif

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
