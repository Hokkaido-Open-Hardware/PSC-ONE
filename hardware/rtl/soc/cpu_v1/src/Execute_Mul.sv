// NISHIHARU

module Execute_Mul #(
    parameter bit ENABLE_PULP = 1'b1
)(
    input  logic        clk,
    input  logic        reset_n,

    input  logic        start,

    input  logic [1:0]  alucon,
    input  logic        dotup_h,
    input  logic        dotsp_b,
    input  logic [31:0] data_1,
    input  logic [31:0] data_2,

    output logic        busy,
    output logic        done,

    output logic [31:0] mul_out
);

    typedef enum logic [2:0] {
        IDLE, RUN, DOT_SUM, BYTE_PAIR, BYTE_SUM, MUL_RESULT
    } state_t;

    state_t state;

    // Snapshot the request in IDLE so issue.valid/control and operand muxes
    // end at these registers, not at the multiplier result.
    logic signed [32:0] data_1_q, data_2_q;
    logic [1:0] alucon_q;
    logic dotup_h_q, dotsp_b_q;
    logic [63:0] mul_product_q;
    logic signed [65:0] mul_product;

    // Explicit unsigned lanes/products; register products before the adder
    // to avoid a multiplier-plus-adder path in one cycle.
    logic [15:0] dot_a0, dot_a1, dot_b0, dot_b1;
    logic [31:0] dot_lo, dot_hi;
    logic [32:0] dot_sum;
    // Native signed 8x8 products allow Gowin MULT9X9 inference. Every adder
    // level is separated from the multipliers and from the next adder by FFs.
    logic signed [7:0] byte_a [0:3], byte_b [0:3];
    logic signed [15:0] byte_product [0:3];
    logic signed [16:0] byte_pair0, byte_pair1;
    logic signed [17:0] byte_sum;
    genvar lane;
    generate for (lane = 0; lane < 4; lane = lane + 1) begin : signed_lanes
        assign byte_a[lane] = $signed(data_1_q[lane*8 +: 8]);
        assign byte_b[lane] = $signed(data_2_q[lane*8 +: 8]);
    end endgenerate
    assign byte_sum = $signed({byte_pair0[16], byte_pair0}) +
                      $signed({byte_pair1[16], byte_pair1});
    integer k;
    assign dot_a0 = data_1_q[15:0];
    assign dot_a1 = data_1_q[31:16];
    assign dot_b0 = data_2_q[15:0];
    assign dot_b1 = data_2_q[31:16];
    assign dot_sum = {1'b0, dot_lo} + {1'b0, dot_hi};

    assign busy = (state != IDLE);

    // One signed 33x33 multiplier covers all RV32M products. The sign bits
    // are captured with the operands, keeping mode decode off the DSP path.
    // MUL only uses the low word, where signed/unsigned products agree.
    assign mul_product = data_1_q * data_2_q;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state   <= IDLE;
            done    <= 1'b0;
            mul_out <= 32'd0;
            data_1_q <= 33'sd0;
            data_2_q <= 33'sd0;
            alucon_q <= 2'd0;
            dotup_h_q <= 1'b0;
            dotsp_b_q <= 1'b0;
            mul_product_q <= 64'd0;
            dot_lo  <= 32'd0;
            dot_hi  <= 32'd0;
            for (k = 0; k < 4; k = k + 1) byte_product[k] <= 16'sd0;
            byte_pair0 <= 17'sd0;
            byte_pair1 <= 17'sd0;
        end else begin
            done <= 1'b0;

            unique case (state)
                IDLE: begin
                    if (start) begin
                        data_1_q <= {(alucon == 2'b01 || alucon == 2'b10) && data_1[31], data_1};
                        data_2_q <= {(alucon == 2'b01) && data_2[31], data_2};
                        alucon_q <= alucon;
                        dotup_h_q <= ENABLE_PULP && dotup_h;
                        dotsp_b_q <= ENABLE_PULP && dotsp_b;
                        state <= RUN;
                    end
                end

                RUN: begin
                    if (ENABLE_PULP && dotsp_b_q) begin
                        for (k = 0; k < 4; k = k + 1)
                            byte_product[k] <= byte_a[k] * byte_b[k];
                        state <= BYTE_PAIR;
                    end else if (ENABLE_PULP && dotup_h_q) begin
                        dot_lo <= {16'b0, dot_a0} * {16'b0, dot_b0};
                        dot_hi <= {16'b0, dot_a1} * {16'b0, dot_b1};
                        state <= DOT_SUM;
                    end else begin
                        mul_product_q <= mul_product[63:0];
                        state <= MUL_RESULT;
                    end
                end

                MUL_RESULT: begin
                    mul_out <= (alucon_q == 2'b00)
                             ? mul_product_q[31:0] : mul_product_q[63:32];

                    done <= 1'b1;
                    state <= IDLE;
                end

                DOT_SUM: begin
                    mul_out <= dot_sum[31:0];
                    done <= 1'b1;
                    state <= IDLE;
                end

                BYTE_PAIR: begin
                    byte_pair0 <= $signed({byte_product[0][15], byte_product[0]}) +
                                  $signed({byte_product[1][15], byte_product[1]});
                    byte_pair1 <= $signed({byte_product[2][15], byte_product[2]}) +
                                  $signed({byte_product[3][15], byte_product[3]});
                    state <= BYTE_SUM;
                end

                BYTE_SUM: begin
                    mul_out <= {{14{byte_sum[17]}}, byte_sum};
                    done <= 1'b1;
                    state <= IDLE;
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
