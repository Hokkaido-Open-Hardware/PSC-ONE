`timescale 1ns/1ps

module SystolicArray4x4_Ctrl #(
    parameter integer PE_N     = 4,     // Physical SA size: 4x4 fixed
    parameter integer MATRIX_N = 4,     // Default matrix size
    parameter integer MUL_NUM  = 4      // Number of physical multipliers
)(
    input  wire             clock,
    input  wire             reset_n,

    // SA control
    input  wire             start,
    input  wire             sa_state_reset,
    input  wire [3:0]       sa_os_instruction,  // Reserved
    input  wire             sa_clear,

    // Runtime matrix size: 4, 8, 12, 16, ...
    input  wire [7:0]       matrix_size_x,
    input  wire [7:0]       matrix_size_y,

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

    localparam integer DW = 8;
    localparam integer PW = 32;
    localparam integer SW = 32;

    // Runtime dimensions:
    //   A = matrix_size_y x matrix_size_x
    //   B = matrix_size_x x matrix_size_y
    //   C = matrix_size_y x matrix_size_y
    //
    // Both dimensions must be non-zero multiples of four.
    wire [7:0] tile_count_k = matrix_size_x >> 2;
    wire [7:0] tile_count_y = matrix_size_y >> 2;

    // 4x4 tile loop indices:
    // C[i_idx][j_idx] += A[i_idx][k_idx] * B[k_idx][j_idx]
    reg [7:0] i_idx;
    reg [7:0] j_idx;
    reg [7:0] k_idx;

    //--------------------------------------------
    // C address helper
    //
    // C is uint32_t C[matrix_size_y][matrix_size_y].
    //--------------------------------------------
    function automatic [31:0] matrix_row_elements;
        input [7:0] row_idx;
        input [7:0] size;

        begin
            case (size)
                8'd4:
                    matrix_row_elements =
                        {24'd0, row_idx} << 2;

                8'd8:
                    matrix_row_elements =
                        {24'd0, row_idx} << 3;

                8'd12:
                    matrix_row_elements =
                        ({24'd0, row_idx} << 3)
                    + ({24'd0, row_idx} << 2);

                8'd16:
                    matrix_row_elements =
                        {24'd0, row_idx} << 4;

                8'd32:
                    matrix_row_elements =
                        {24'd0, row_idx} << 5;

                8'd64:
                    matrix_row_elements =
                        {24'd0, row_idx} << 6;

                default:
                    matrix_row_elements =
                        {24'd0, row_idx}
                    * {24'd0, size};
            endcase
        end
    endfunction

    function [31:0] matrix_addr_C;
        input [5:0] pe_idx;
        reg [7:0] local_row;
        reg [7:0] local_col;
        reg [7:0] global_row;
        reg [7:0] global_col;
        reg [31:0] element_idx;
        begin
            // PE_N is fixed at four.
            local_row = {2'd0, pe_idx[5:2]};
            local_col = {6'd0, pe_idx[1:0]};

            global_row = (i_idx << 2) + local_row;
            global_col = (j_idx << 2) + local_col;

            element_idx =
                matrix_row_elements(global_row, matrix_size_y)
                + {24'd0, global_col};

            matrix_addr_C = BASE_ADDR_C + (element_idx << 2);
        end
    endfunction

    //--------------------------------------------
    // SA signals
    //--------------------------------------------
    reg               data_clear;
    reg               en_b_shift_bottom;
    reg               en_shift_right;
    reg               start_pulse;

    wire [31:0]       a_left_in_bus;
    wire [31:0]       b_top_in_bus;

    wire              busy_out;
    wire              done_out;
    wire [31:0]       ps_acc_out;

    reg  [5:0]        row_s;
    reg  [31:0]       cur_a_data;
    reg  [31:0]       cur_b_data;

    //======================================================
    // SA instance
    //======================================================
    SystolicArray4x4 #(
        .DW                     (DW),
        .PW                     (PW),
        .SW                     (SW),
        .MUL_NUM                (MUL_NUM)
    ) u_sa (
        .clock                  (clock),
        .reset_n                (reset_n),

        .data_clear             (data_clear | sa_clear),
        .en_b_shift_bottom      (en_b_shift_bottom),
        .en_shift_right         (en_shift_right),
        .start_pulse            (start_pulse),

        .a_left_in_bus          (a_left_in_bus),
        .b_top_in_bus           (b_top_in_bus),

        .ps_select              (row_s),
        .ps_acc_out             (ps_acc_out),

        .busy_out               (busy_out),
        .done_out               (done_out)
    );

    //======================================================
    // ReadCtrl instance
    //======================================================
    reg          read_start;
    wire         read_end;

    wire [127:0] a_data_out_cur;
    wire [127:0] b_data_out_cur;

    SystolicArray_ReadCtrl #(
        .PE_N               (PE_N),
        .RADDR_MASK         (32'h00FF_FFFF)
    ) u_systolic_array_read_ctrl (
        .clock              (clock),
        .reset_n            (reset_n),

        .BASE_ADDR_A        (BASE_ADDR_A),
        .BASE_ADDR_B        (BASE_ADDR_B),

        .matrix_size_x      (matrix_size_x),
        .matrix_size_y      (matrix_size_y),

        .i_idx              (i_idx),
        .j_idx              (j_idx),
        .k_idx              (k_idx),

        .read_valid         (read_start),
        .read_ready         (read_end),

        .rd_read_addr       (rd_read_addr),
        .rd_read_valid      (rd_read_valid),
        .rd_read_ready      (rd_read_ready),
        .rd_read_data       (rd_read_data),

        .a_data_out         (a_data_out_cur),
        .b_data_out         (b_data_out_cur)
    );

    //--------------------------------------------
    // Output-Stationary input mapping
    //--------------------------------------------
    function [31:0] func_a_os_data;
        input [127:0] a_data;
        input [3:0]   idx;
        begin
            case (idx)
                4'd0: func_a_os_data = {
                    8'd0, 8'd0, 8'd0, a_data[7:0]
                };

                4'd1: func_a_os_data = {
                    8'd0, 8'd0, a_data[39:32], a_data[15:8]
                };

                4'd2: func_a_os_data = {
                    8'd0, a_data[71:64], a_data[47:40], a_data[23:16]
                };

                4'd3: func_a_os_data = {
                    a_data[103:96], a_data[79:72],
                    a_data[55:48], a_data[31:24]
                };

                4'd4: func_a_os_data = {
                    a_data[111:104], a_data[87:80], a_data[63:56], 8'd0
                };

                4'd5: func_a_os_data = {
                    a_data[119:112], a_data[95:88], 8'd0, 8'd0
                };

                4'd6: func_a_os_data = {
                    a_data[127:120], 8'd0, 8'd0, 8'd0
                };

                default:
                    func_a_os_data = 32'd0;
            endcase
        end
    endfunction

    function [31:0] func_b_os_data;
        input [127:0] b_data;
        input [3:0]   idx;
        begin
            case (idx)
                4'd0: func_b_os_data = {
                    8'd0, 8'd0, 8'd0, b_data[7:0]
                };

                4'd1: func_b_os_data = {
                    8'd0, 8'd0, b_data[15:8], b_data[39:32]
                };

                4'd2: func_b_os_data = {
                    8'd0, b_data[23:16], b_data[47:40], b_data[71:64]
                };

                4'd3: func_b_os_data = {
                    b_data[31:24], b_data[55:48],
                    b_data[79:72], b_data[103:96]
                };

                4'd4: func_b_os_data = {
                    b_data[63:56], b_data[87:80], b_data[111:104], 8'd0
                };

                4'd5: func_b_os_data = {
                    b_data[95:88], b_data[119:112], 8'd0, 8'd0
                };

                4'd6: func_b_os_data = {
                    b_data[127:120], 8'd0, 8'd0, 8'd0
                };

                default:
                    func_b_os_data = 32'd0;
            endcase
        end
    endfunction

    assign a_left_in_bus = cur_a_data;
    assign b_top_in_bus  = cur_b_data;

    //--------------------------------------------
    // FSM
    //--------------------------------------------
    localparam [5:0]
        S_IDLE                  = 6'd0,
        S_CLEAR                 = 6'd1,

        S_RA_START              = 6'd2,
        S_RA_WAIT               = 6'd3,

        S_OS_START              = 6'd4,
        S_OS_SHIFT              = 6'd5,
        S_OS_SHIFT_PULSE        = 6'd6,
        S_OS_START_PULSE        = 6'd7,
        S_OS_START_WAIT         = 6'd8,
        S_OS_SHIFT_WAIT         = 6'd9,
        S_OS_FLUSH              = 6'd10,
        S_OS_FLUSH_START_PULSE  = 6'd11,
        S_OS_FLUSH_WAIT         = 6'd12,

        S_OUTPUT_MEMORY         = 6'd20,
        S_OUTPUT_MEMORY_W       = 6'd21,
        S_DONE                  = 6'd31;

    reg [5:0] state;

    //--------------------------------------------
    // Main FSM
    //--------------------------------------------
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            state             <= S_IDLE;

            read_start        <= 1'b0;

            data_clear        <= 1'b0;
            en_b_shift_bottom <= 1'b0;
            en_shift_right    <= 1'b0;
            start_pulse       <= 1'b0;

            i_idx             <= 8'd0;
            j_idx             <= 8'd0;
            k_idx             <= 8'd0;

            cur_a_data        <= 32'd0;
            cur_b_data        <= 32'd0;
            row_s             <= 6'd0;

            c_write_valid     <= 1'b0;
            c_write_addr      <= 32'd0;
            c_write_wdata     <= 32'd0;

            busy              <= 1'b0;
            done              <= 1'b0;
        end else begin
            // Default one-cycle pulses
            read_start        <= 1'b0;
            data_clear        <= 1'b0;
            en_b_shift_bottom <= 1'b0;
            en_shift_right    <= 1'b0;
            start_pulse       <= 1'b0;
            c_write_valid     <= 1'b0;

            busy <= (state != S_IDLE) && (state != S_DONE);
            done <= (state == S_DONE);

            case (state)
                //--------------------------------------------
                // Start i=0, j=0, k=0.
                //--------------------------------------------
                S_IDLE: begin
                    if (start) begin
                        i_idx         <= 8'd0;
                        j_idx         <= 8'd0;
                        k_idx         <= 8'd0;
                        row_s         <= 6'd0;
                        cur_a_data    <= 32'd0;
                        cur_b_data    <= 32'd0;
                        state         <= S_CLEAR;
                    end
                end

                //--------------------------------------------
                // Clear the accumulator only when beginning a
                // new C[i_idx][j_idx] output tile.
                //--------------------------------------------
                S_CLEAR: begin
                    data_clear <= 1'b1;
                    row_s      <= 6'd0;
                    k_idx      <= 8'd0;
                    cur_a_data <= 32'd0;
                    cur_b_data <= 32'd0;
                    state      <= S_RA_START;
                end

                //--------------------------------------------
                // Read A[i_idx][k_idx] and B[k_idx][j_idx].
                //--------------------------------------------
                S_RA_START: begin
                    read_start <= 1'b1;
                    state      <= S_RA_WAIT;
                end

                S_RA_WAIT: begin
                    if (read_end)
                        state <= S_OS_START;
                end

                //==========================================================
                // Execute one 4x4 output-stationary tile multiplication.
                //==========================================================
                S_OS_START: begin
                    row_s <= 6'd0;
                    state <= S_OS_SHIFT;
                end

                S_OS_SHIFT: begin
                    cur_a_data <= func_a_os_data(a_data_out_cur, row_s[3:0]);
                    cur_b_data <= func_b_os_data(b_data_out_cur, row_s[3:0]);
                    state      <= S_OS_SHIFT_PULSE;
                end

                S_OS_SHIFT_PULSE: begin
                    en_shift_right    <= 1'b1;
                    en_b_shift_bottom <= 1'b1;
                    state             <= S_OS_START_PULSE;

                    `ifdef COCOTB_SIM
                    `ifdef DUMP_VCD_CTRL
                    /*
                    $display(
                        "OS tile=(%0d,%0d,%0d) idx=%0d A=%08x B=%08x",
                        i_idx,
                        j_idx,
                        k_idx,
                        row_s,
                        a_left_in_bus,
                        b_top_in_bus
                    );
                    */
                    `endif
                    `endif
                end

                S_OS_START_PULSE: begin
                    start_pulse <= 1'b1;
                    state       <= S_OS_START_WAIT;
                end

                S_OS_START_WAIT: begin
                    if (done_out)
                        state <= S_OS_SHIFT_WAIT;
                end

                S_OS_SHIFT_WAIT: begin
                    if (row_s == (2*PE_N - 1)) begin
                        row_s      <= 6'd0;
                        cur_a_data <= 32'd0;
                        cur_b_data <= 32'd0;
                        state      <= S_OS_FLUSH;
                    end else begin
                        row_s <= row_s + 6'd1;
                        state <= S_OS_SHIFT;
                    end
                end

                S_OS_FLUSH: begin
                    cur_a_data        <= 32'd0;
                    cur_b_data        <= 32'd0;
                    en_shift_right    <= 1'b1;
                    en_b_shift_bottom <= 1'b1;
                    state             <= S_OS_FLUSH_START_PULSE;
                end

                S_OS_FLUSH_START_PULSE: begin
                    start_pulse <= 1'b1;
                    state       <= S_OS_FLUSH_WAIT;
                end

                //--------------------------------------------
                // k loop:
                // C[i][j] += A[i][k] * B[k][j]
                //--------------------------------------------
                S_OS_FLUSH_WAIT: begin
                    if (done_out) begin
                        if (row_s == PE_N - 1) begin
                            row_s      <= 6'd0;
                            cur_a_data <= 32'd0;
                            cur_b_data <= 32'd0;

                            if (k_idx == tile_count_k - 8'd1) begin
                                // All K tiles for this C tile are complete.
                                state <= S_OUTPUT_MEMORY;
                            end else begin
                                // Keep ps_acc and process the next K tile.
                                k_idx <= k_idx + 8'd1;
                                state <= S_RA_START;
                            end
                        end else begin
                            row_s <= row_s + 6'd1;
                            state <= S_OS_FLUSH;
                        end
                    end
                end

                //--------------------------------------------
                // Write the completed C[i_idx][j_idx] 4x4 tile.
                //--------------------------------------------
                S_OUTPUT_MEMORY: begin
                    if (sa_req_ready) begin
                        c_write_valid <= 1'b1;
                        c_write_addr  <= matrix_addr_C(row_s);
                        c_write_wdata <= ps_acc_out;
                        state         <= S_OUTPUT_MEMORY_W;
                    end
                end

                //--------------------------------------------
                // j loop, then i loop.
                //--------------------------------------------
                S_OUTPUT_MEMORY_W: begin
                    if (c_write_ready) begin
                        if (row_s == PE_N*PE_N - 1) begin
                            row_s <= 6'd0;
                            k_idx <= 8'd0;

                            if (j_idx != tile_count_y - 8'd1) begin
                                j_idx <= j_idx + 8'd1;
                                state <= S_CLEAR;
                            end else if (i_idx != tile_count_y - 8'd1) begin
                                i_idx <= i_idx + 8'd1;
                                j_idx <= 8'd0;
                                state <= S_CLEAR;
                            end else begin
                                state <= S_DONE;
                            end
                        end else begin
                            row_s <= row_s + 6'd1;
                            state <= S_OUTPUT_MEMORY;
                        end
                    end
                end

                S_DONE: begin
                    if (sa_state_reset)
                        state <= S_IDLE;
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

    // Prevent unused-input warnings from becoming ambiguous in lint output.
    wire _unused_ok = &{1'b0, sa_os_instruction, 8'h00, busy_out,
                        MATRIX_N[0]};

endmodule