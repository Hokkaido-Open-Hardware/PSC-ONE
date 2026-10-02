`timescale 1ns/1ps

// PSC-LPU v0.1. One outstanding pulse/response memory transaction.
// A: row-major signed bytes; B: 4x4 ternary tiles packed into 32-bit words.
// C: row-major packed INT8, or raw row-major INT32 for CPU postprocessing.
module PSC_LPU_Controller #(
    parameter integer OUT_SHIFT    = 0,
    parameter bit     OUTPUT_INT32 = 1'b0
)(
    input  wire             clock,
    input  wire             reset_n,
    input  wire             start,
    input  wire             sa_state_reset,
    input  wire             sa_clear,
    input  wire [7:0]       matrix_size_x,
    input  wire [7:0]       matrix_size_y,
    input  wire [7:0]       matrix_size_m,
    input  wire [31:0]      BASE_ADDR_A,
    input  wire [31:0]      BASE_ADDR_B,
    input  wire [31:0]      BASE_ADDR_C,
    input  wire             sa_req_ready,
    output reg  [31:0]      rd_read_addr,
    output reg              rd_read_valid,
    input  wire             rd_read_ready,
    input  wire [31:0]      rd_read_data,
    output reg              c_write_valid,
    output reg  [31:0]      c_write_addr,
    output reg  [31:0]      c_write_wdata,
    input  wire             c_write_ready,
    output reg              busy,
    output reg              done
);
    generate
        if (OUT_SHIFT < 0 || OUT_SHIFT > 31) begin : g_bad_shift
            PSC_LPU_ERROR_OUT_SHIFT_MUST_BE_0_TO_31 invalid_shift();
        end
    endgenerate

    localparam [3:0]
        S_IDLE       = 4'd0,
        S_CLEAR      = 4'd1,
        S_A_REQ      = 4'd2,
        S_A_WAIT     = 4'd3,
        S_B_REQ      = 4'd4,
        S_B_WAIT     = 4'd5,
        S_MAC        = 4'd6,
        S_WRITE_PREP = 4'd7,
        S_WRITE_REQ  = 4'd8,
        S_WRITE_WAIT = 4'd9,
        S_ADVANCE    = 4'd10,
        S_DONE       = 4'd11;
    reg [3:0] state;
    reg [7:0] size_k, size_n, rows_left, k_base, n_base;
    reg [1:0] last_row, read_row, mac_row, mac_k, write_row, write_col;
    reg [31:0] a_m_base, a_k_base, a_cursor;
    reg [31:0] b_base, b_n_base, b_cursor;
    reg [31:0] c_m_base, c_tile_base, c_row_base, c_stride;

    // Datapath: four A words, one B word, sixteen signed accumulators.
    reg [31:0] a_words [0:3];
    reg [31:0] b_word;
    reg signed [31:0] acc [0:15];
    wire [7:0] a_byte = a_words[mac_row][{mac_k, 3'b000} +: 8];
    // Sign-extend to INT32 before subtraction: -(-128) must be +128.
    // Negation is shared; each accumulation lane uses one 32-bit adder.
    wire signed [31:0] a_signed = {{24{a_byte[7]}}, a_byte};
    wire signed [31:0] a_negated = -a_signed;
    wire clear_acc = (state == S_CLEAR) || ((state == S_IDLE) && sa_clear);
    genvar lane, acc_row;
    generate
        for (lane = 0; lane < 4; lane = lane + 1) begin : g_lane
            wire [1:0] code = b_word[({mac_k, 3'b000} + lane*2) +: 2];
            wire signed [31:0] term = code == 2'b10 ? a_negated : a_signed;
            wire signed [31:0] lane_sum = acc[{mac_row, 2'b00}+lane] + term;
            // Fixed write indices avoid ambiguous cross-process array
            // writes in Yosys. All four rows share this lane's single adder.
            for (acc_row = 0; acc_row < 4; acc_row = acc_row + 1) begin : g_row
                always @(posedge clock or negedge reset_n) begin
                    if (!reset_n) acc[acc_row*4+lane] <= 32'sd0;
                    else if (clear_acc) acc[acc_row*4+lane] <= 32'sd0;
                    else if ((state == S_MAC) && (mac_row == acc_row) &&
                             ((code == 2'b01) || (code == 2'b10)))
                        acc[acc_row*4+lane] <= lane_sum;
                end
            end
        end
    endgenerate

    function automatic [7:0] quantize;
        input signed [31:0] value;
        reg signed [31:0] shifted;
        begin
            shifted = value >>> OUT_SHIFT;
            if (shifted > 32'sd127) quantize = 8'h7f;
            else if (shifted < -32'sd128) quantize = 8'h80;
            else quantize = shifted[7:0];
        end
    endfunction

    wire [7:0] requested_m = (matrix_size_m == 0) ? matrix_size_y : matrix_size_m;
    // No error port is available. Invalid dimensions/alignment are ignored
    // in IDLE (busy/done remain low and no memory request is issued).
    wire valid_config = (matrix_size_x >= 4) && (matrix_size_y >= 4) &&
        (matrix_size_x[1:0] == 0) && (matrix_size_y[1:0] == 0) &&
        (BASE_ADDR_A[1:0] == 0) && (BASE_ADDR_B[1:0] == 0) &&
        (BASE_ADDR_C[1:0] == 0);
    integer idx;
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            state             <= S_IDLE;
            busy              <= 0;
            done              <= 0;
            rd_read_valid     <= 0;
            rd_read_addr      <= 0;
            c_write_valid     <= 0;
            c_write_addr      <= 0;
            c_write_wdata     <= 0;
            size_k            <= 0;
            size_n            <= 0;
            rows_left         <= 0;
            k_base            <= 0;
            n_base            <= 0;
            last_row          <= 0;
            read_row          <= 0;
            mac_row           <= 0;
            mac_k             <= 0;
            write_row         <= 0;
            write_col         <= 0;
            a_m_base          <= 0;
            a_k_base          <= 0;
            a_cursor          <= 0;
            b_base            <= 0;
            b_n_base          <= 0;
            b_cursor          <= 0;
            c_m_base          <= 0;
            c_tile_base       <= 0;
            c_row_base        <= 0;
            c_stride          <= 0;
            b_word            <= 0;
            for (idx = 0; idx < 4; idx = idx + 1) a_words[idx] <= 0;
        end else begin
            rd_read_valid     <= 0;
            c_write_valid     <= 0;
            case (state)
                S_IDLE: begin
                    if (sa_clear) begin
                        b_word            <= 0;
                        for (idx = 0; idx < 4; idx = idx + 1) a_words[idx] <= 0;
                    end
                    if (start && valid_config) begin
                        size_k            <= matrix_size_x;
                        size_n            <= matrix_size_y;
                        rows_left         <= requested_m;
                        a_m_base          <= BASE_ADDR_A;
                        b_base            <= BASE_ADDR_B;
                        b_n_base          <= BASE_ADDR_B;
                        c_m_base          <= BASE_ADDR_C;
                        c_tile_base       <= BASE_ADDR_C;
                        c_stride          <= OUTPUT_INT32 ? {22'd0, matrix_size_y, 2'b00}
                                                 : {24'd0, matrix_size_y};
                        n_base            <= 0;
                        busy              <= 1;
                        state             <= S_CLEAR;
                    end
                end
                S_CLEAR: begin
                    last_row          <= (rows_left < 4) ? (rows_left[1:0] - 2'd1) : 2'd3;
                    k_base            <= 0;
                    a_k_base          <= a_m_base;
                    a_cursor          <= a_m_base;
                    b_cursor          <= b_n_base;
                    read_row          <= 0;
                    state             <= S_A_REQ;
                end
                S_A_REQ: if (sa_req_ready) begin
                    rd_read_addr      <= a_cursor;
                    rd_read_valid     <= 1;
                    state             <= S_A_WAIT;
                end
                S_A_WAIT: if (rd_read_ready) begin
                    a_words[read_row] <= rd_read_data;
                    if (read_row == last_row) state <= S_B_REQ;
                    else begin
                        read_row          <= read_row + 2'd1;
                        a_cursor          <= a_cursor + {24'd0, size_k};
                        state             <= S_A_REQ;
                    end
                end
                S_B_REQ: if (sa_req_ready) begin
                    rd_read_addr      <= b_cursor;
                    rd_read_valid     <= 1;
                    state             <= S_B_WAIT;
                end
                S_B_WAIT: if (rd_read_ready) begin
                    b_word            <= rd_read_data;
                    mac_row           <= 0;
                    mac_k             <= 0;
                    state             <= S_MAC;
                end
                S_MAC: begin
                    // Exactly 16 updates for a full 4x4x4 tile.
                    if (mac_k != 3) mac_k <= mac_k + 2'd1;
                    else if (mac_row != last_row) begin
                        mac_k             <= 0;
                        mac_row           <= mac_row + 2'd1;
                    end else if (k_base != size_k - 8'd4) begin
                        k_base            <= k_base + 8'd4;
                        a_k_base          <= a_k_base + 32'd4;
                        a_cursor          <= a_k_base + 32'd4;
                        // B tile-row stride = 4 * (N/4) = N bytes.
                        b_cursor          <= b_cursor + {24'd0, size_n};
                        read_row          <= 0;
                        state             <= S_A_REQ;
                    end else begin
                        write_row         <= 0;
                        write_col         <= 0;
                        c_row_base        <= c_tile_base;
                        state             <= S_WRITE_PREP;
                    end
                end
                S_WRITE_PREP: begin
                    if (OUTPUT_INT32) begin
                        c_write_addr      <= c_row_base + {28'd0, write_col, 2'b00};
                        c_write_wdata     <= acc[{write_row, write_col}];
                    end else begin
                        c_write_addr      <= c_row_base;
                        c_write_wdata     <= {
                            quantize(acc[{write_row, 2'b11}]),
                            quantize(acc[{write_row, 2'b10}]),
                            quantize(acc[{write_row, 2'b01}]),
                            quantize(acc[{write_row, 2'b00}])};
                    end
                    state             <= S_WRITE_REQ;
                end
                S_WRITE_REQ: if (sa_req_ready) begin
                    c_write_valid     <= 1;
                    state             <= S_WRITE_WAIT;
                end
                S_WRITE_WAIT: if (c_write_ready) begin
                    if (OUTPUT_INT32 && (write_col != 3)) begin
                        write_col         <= write_col + 2'd1;
                        state             <= S_WRITE_PREP;
                    end else if (write_row != last_row) begin
                        write_row         <= write_row + 2'd1;
                        write_col         <= 0;
                        c_row_base        <= c_row_base + c_stride;
                        state             <= S_WRITE_PREP;
                    end else state <= S_ADVANCE;
                end
                S_ADVANCE: begin
                    if (n_base != size_n - 8'd4) begin
                        n_base            <= n_base + 8'd4;
                        b_n_base          <= b_n_base + 32'd4;
                        c_tile_base       <= c_tile_base + (OUTPUT_INT32 ? 32'd16 : 32'd4);
                        state             <= S_CLEAR;
                    end else if (rows_left > 4) begin
                        rows_left         <= rows_left - 8'd4;
                        n_base            <= 0;
                        a_m_base          <= a_m_base + {22'd0, size_k, 2'b00};
                        b_n_base          <= b_base;
                        c_m_base          <= c_m_base + (c_stride << 2);
                        c_tile_base       <= c_m_base + (c_stride << 2);
                        state             <= S_CLEAR;
                    end else begin
                        busy              <= 0;
                        done              <= 1;
                        state             <= S_DONE;
                    end
                end
                S_DONE: if (sa_state_reset) begin
                    done              <= 0;
                    state             <= S_IDLE;
                end
                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
