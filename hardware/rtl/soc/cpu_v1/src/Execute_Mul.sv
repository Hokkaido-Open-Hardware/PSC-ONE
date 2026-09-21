// NISHIHARU

module Execute_Mul (
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
        IDLE, RUN, DOT_SUM, BYTE_PAIR, BYTE_SUM
    } state_t;

    state_t state;

    logic signed [63:0] mul_ss;
    logic signed [64:0] mul_su;
    logic        [63:0] mul_uu;

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
        assign byte_a[lane] = $signed(data_1[lane*8 +: 8]);
        assign byte_b[lane] = $signed(data_2[lane*8 +: 8]);
    end endgenerate
    assign byte_sum = $signed({byte_pair0[16], byte_pair0}) +
                      $signed({byte_pair1[16], byte_pair1});
    integer k;
    assign dot_a0 = data_1[15:0];
    assign dot_a1 = data_1[31:16];
    assign dot_b0 = data_2[15:0];
    assign dot_b1 = data_2[31:16];
    assign dot_sum = {1'b0, dot_lo} + {1'b0, dot_hi};

    assign busy = (state != IDLE);

    always_comb begin
        // Signed × signed
        mul_ss = $signed(data_1) * $signed(data_2);

        // Signed × unsigned
        mul_su = $signed({data_1[31], data_1})
               * $signed({1'b0, data_2});

        // Unsigned × unsigned
        mul_uu = data_1 * data_2;
    end

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state   <= IDLE;
            done    <= 1'b0;
            mul_out <= 32'd0;
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
                        state <= RUN;
                    end
                end

                RUN: begin
                    if (dotsp_b) begin
                        for (k = 0; k < 4; k = k + 1)
                            byte_product[k] <= byte_a[k] * byte_b[k];
                        state <= BYTE_PAIR;
                    end else if (dotup_h) begin
                        dot_lo <= {16'b0, dot_a0} * {16'b0, dot_b0};
                        dot_hi <= {16'b0, dot_a1} * {16'b0, dot_b1};
                        state <= DOT_SUM;
                    end else begin
                        unique case (alucon)
                            2'b00: begin
                                // MUL: lower 32 bits
                                mul_out <= mul_uu[31:0];
                            end

                            2'b01: begin
                                // MULH: signed × signed, upper 32 bits
                                mul_out <= mul_ss[63:32];
                            end

                            2'b10: begin
                                // MULHSU: signed × unsigned, upper 32 bits
                                mul_out <= mul_su[63:32];
                            end

                            2'b11: begin
                                // MULHU: unsigned × unsigned, upper 32 bits
                                mul_out <= mul_uu[63:32];
                            end

                            default: begin
                                mul_out <= 32'd0;
                            end
                        endcase

                        done  <= 1'b1;
                        state <= IDLE;
                    end
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
