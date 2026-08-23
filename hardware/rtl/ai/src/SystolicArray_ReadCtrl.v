`timescale 1ns/1ps

module SystolicArray_ReadCtrl #(
    parameter integer PE_N = 4,
    parameter RADDR_MASK   = 32'h000F_FFFF
)(
    input  wire             clock,
    input  wire             reset_n,

    // SDRAM base address
    input  wire [31:0]      BASE_ADDR_A,
    input  wire [31:0]      BASE_ADDR_B,

    // Matrix dimensions:
    //
    // A = matrix_size_y x matrix_size_x
    // B = matrix_size_x x matrix_size_y
    // C = matrix_size_y x matrix_size_y
    //
    // Both sizes must be non-zero multiples of four.
    input  wire [7:0]       matrix_size_x,
    input  wire [7:0]       matrix_size_y,

    // Tile indices
    //
    // A tile = A[i_idx][k_idx]
    // B tile = B[k_idx][j_idx]
    input  wire [7:0]       i_idx,
    input  wire [7:0]       j_idx,
    input  wire [7:0]       k_idx,

    input  wire             read_valid,
    output reg              read_ready,

    // Memory read port
    output reg  [31:0]      rd_read_addr,
    output reg              rd_read_valid,
    input  wire             rd_read_ready,
    input  wire [31:0]      rd_read_data,

    // One 4x4 tile:
    // 4 rows x 32 bits
    output reg [127:0]      a_data_out,
    output reg [127:0]      b_data_out
);

    localparam [2:0]
        R_IDLE    = 3'd0,
        R_A_START = 3'd1,
        R_A_WAIT  = 3'd2,
        R_B_START = 3'd3,
        R_B_WAIT  = 3'd4;

    reg [2:0] state;
    reg [1:0] read_idx;

    // Request-latched tile coordinates and dimensions
    reg [7:0] i_idx_r;
    reg [7:0] j_idx_r;
    reg [7:0] k_idx_r;

    reg [7:0] matrix_size_x_r;
    reg [7:0] matrix_size_y_r;

    // Sequential address cursors.  The first address of each tile is
    // calculated once when the request is accepted; subsequent rows are
    // reached by adding the matrix row stride.  This keeps matrix_size_*
    // out of the rd_read_addr critical path.
    reg [31:0] a_addr_cur;
    reg [31:0] b_addr_cur;

    /*
     * tile_row_offset
     *
     * Returns:
     *
     *     tile_idx * PE_N * row_size
     *
     * PE_N=4の場合:
     *
     *     tile_idx * 4 * row_size
     *
     * 行列はuint8_t配列なので、要素数とバイト数は同じ。
     */
    function automatic [31:0] tile_row_offset;
        input [7:0] tile_idx;
        input [7:0] row_size;

        begin
            case (row_size)
                8'd4:
                    tile_row_offset =
                        {24'd0, tile_idx} << 4;
                    // tile_idx * 4 * 4 = tile_idx * 16

                8'd8:
                    tile_row_offset =
                        {24'd0, tile_idx} << 5;
                    // tile_idx * 4 * 8 = tile_idx * 32

                8'd12:
                    tile_row_offset =
                        ({24'd0, tile_idx} << 5)
                      + ({24'd0, tile_idx} << 4);
                    // tile_idx * 4 * 12 = tile_idx * 48

                8'd16:
                    tile_row_offset =
                        {24'd0, tile_idx} << 6;
                    // tile_idx * 4 * 16 = tile_idx * 64

                8'd32:
                    tile_row_offset =
                        {24'd0, tile_idx} << 7;
                    // tile_idx * 4 * 32 = tile_idx * 128

                8'd64:
                    tile_row_offset =
                        {24'd0, tile_idx} << 8;
                    // tile_idx * 4 * 64 = tile_idx * 256

                default:
                    tile_row_offset =
                        ({24'd0, tile_idx} << 2)
                        * {24'd0, row_size};
            endcase
        end
    endfunction

    /*
     * row_offset
     *
     * 4x4タイル内のlocal_rowに対応する行オフセット。
     *
     * uint8_t matrix[][]なので、
     * 1行のバイト数はrow_sizeと等しい。
     */
    function automatic [31:0] row_offset;
        input [1:0] local_row;
        input [7:0] row_size;

        begin
            case (local_row)
                2'd0:
                    row_offset = 32'd0;

                2'd1:
                    row_offset = {24'd0, row_size};

                2'd2:
                    row_offset = {24'd0, row_size} << 1;

                2'd3:
                    row_offset =
                        ({24'd0, row_size} << 1)
                        + {24'd0, row_size};

                default:
                    row_offset = 32'd0;
            endcase
        end
    endfunction

    /*
     * Aタイルの各行アドレス
     *
     * A:
     *     rows = matrix_size_y
     *     cols = matrix_size_x
     *
     * 対象タイル:
     *     A[i_idx][k_idx]
     *
     * 要素位置:
     *     row = i_idx * 4 + local_row
     *     col = k_idx * 4
     *
     * Aの行ストライドはmatrix_size_xバイト。
     */
    function automatic [31:0] matrix_addr_A;
        input [1:0] local_row;

        begin
            matrix_addr_A =
                RADDR_MASK
                & (
                    BASE_ADDR_A
                    + tile_row_offset(
                        i_idx_r,
                        matrix_size_x_r
                    )
                    + row_offset(
                        local_row,
                        matrix_size_x_r
                    )
                    + ({24'd0, k_idx_r} << 2)
                );
        end
    endfunction

    /*
     * Bタイルの各行アドレス
     *
     * B:
     *     rows = matrix_size_x
     *     cols = matrix_size_y
     *
     * 対象タイル:
     *     B[k_idx][j_idx]
     *
     * 要素位置:
     *     row = k_idx * 4 + local_row
     *     col = j_idx * 4
     *
     * Bの行ストライドはmatrix_size_yバイト。
     */
    function automatic [31:0] matrix_addr_B;
        input [1:0] local_row;

        begin
            matrix_addr_B =
                RADDR_MASK
                & (
                    BASE_ADDR_B
                    + tile_row_offset(
                        k_idx_r,
                        matrix_size_y_r
                    )
                    + row_offset(
                        local_row,
                        matrix_size_y_r
                    )
                    + ({24'd0, j_idx_r} << 2)
                );
        end
    endfunction

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            state             <= R_IDLE;
            read_idx          <= 2'd0;

            i_idx_r           <= 8'd0;
            j_idx_r           <= 8'd0;
            k_idx_r           <= 8'd0;

            matrix_size_x_r   <= 8'd0;
            matrix_size_y_r   <= 8'd0;
            a_addr_cur         <= 32'd0;
            b_addr_cur         <= 32'd0;

            rd_read_addr      <= 32'd0;
            rd_read_valid     <= 1'b0;
            read_ready        <= 1'b0;

            a_data_out        <= 128'd0;
            b_data_out        <= 128'd0;

        end else begin
            // Default one-cycle pulses
            rd_read_valid <= 1'b0;
            read_ready    <= 1'b0;

            case (state)
                R_IDLE: begin
                    if (read_valid) begin
                        // この読出し要求に使用する値を固定する。
                        i_idx_r         <= i_idx;
                        j_idx_r         <= j_idx;
                        k_idx_r         <= k_idx;

                        matrix_size_x_r <= matrix_size_x;
                        matrix_size_y_r <= matrix_size_y;

                        // First row of A[i_idx][k_idx] and B[k_idx][j_idx].
                        // Only this request-capture cycle contains the tile
                        // offset arithmetic; the memory issue path below is
                        // just a registered cursor.
                        a_addr_cur <= RADDR_MASK & (
                            BASE_ADDR_A
                            + tile_row_offset(i_idx, matrix_size_x)
                            + ({24'd0, k_idx} << 2)
                        );

                        b_addr_cur <= RADDR_MASK & (
                            BASE_ADDR_B
                            + tile_row_offset(k_idx, matrix_size_y)
                            + ({24'd0, j_idx} << 2)
                        );

                        read_idx        <= 2'd0;
                        a_data_out      <= 128'd0;
                        b_data_out      <= 128'd0;

                        state           <= R_A_START;
                    end
                end

                // ========================================
                // Read A[i_idx][k_idx] 4x4 tile
                // ========================================
                R_A_START: begin
                    rd_read_addr  <= a_addr_cur;
                    rd_read_valid <= 1'b1;
                    state         <= R_A_WAIT;
                end

                R_A_WAIT: begin
                    if (rd_read_ready) begin
                        case (read_idx)
                            2'd0:
                                a_data_out[31:0] <= rd_read_data;

                            2'd1:
                                a_data_out[63:32] <= rd_read_data;

                            2'd2:
                                a_data_out[95:64] <= rd_read_data;

                            2'd3:
                                a_data_out[127:96] <= rd_read_data;

                            default:
                                ;
                        endcase

                        if (read_idx == 2'd3) begin
                            read_idx <= 2'd0;
                            state    <= R_B_START;
                        end else begin
                            a_addr_cur <= a_addr_cur + {24'd0, matrix_size_x_r};
                            read_idx    <= read_idx + 2'd1;
                            state       <= R_A_START;
                        end
                    end
                end

                // ========================================
                // Read B[k_idx][j_idx] 4x4 tile
                // ========================================
                R_B_START: begin
                    rd_read_addr  <= b_addr_cur;
                    rd_read_valid <= 1'b1;
                    state         <= R_B_WAIT;
                end

                R_B_WAIT: begin
                    if (rd_read_ready) begin
                        case (read_idx)
                            2'd0:
                                b_data_out[31:0] <= rd_read_data;

                            2'd1:
                                b_data_out[63:32] <= rd_read_data;

                            2'd2:
                                b_data_out[95:64] <= rd_read_data;

                            2'd3:
                                b_data_out[127:96] <= rd_read_data;

                            default:
                                ;
                        endcase

                        if (read_idx == 2'd3) begin
                            read_idx   <= 2'd0;
                            read_ready <= 1'b1;
                            state      <= R_IDLE;
                        end else begin
                            b_addr_cur <= b_addr_cur + {24'd0, matrix_size_y_r};
                            read_idx   <= read_idx + 2'd1;
                            state      <= R_B_START;
                        end
                    end
                end

                default: begin
                    state <= R_IDLE;
                end
            endcase
        end
    end

endmodule
