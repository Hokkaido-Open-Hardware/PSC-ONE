// NISHIHARU

module Execute_Mul (
    input  logic        clk,
    input  logic        reset_n,

    input  logic        start,

    input  logic [1:0]  alucon,
    input  logic [31:0] data_1,
    input  logic [31:0] data_2,

    output logic        busy,
    output logic        done,

    output logic [31:0] mul_out
);

    typedef enum logic [1:0] {
        IDLE = 2'd0,
        RUN  = 2'd1
    } state_t;

    state_t state;

    logic signed [32:0] multiplicand_q;
    logic signed [32:0] multiplier_q;
    logic signed [65:0] product;
    logic               high_result_q;

    assign busy = (state != IDLE);

    // One signed 33x33 multiplier covers all four RV32M multiply variants.
    // Zero extension selects unsigned input interpretation; sign extension
    // selects signed interpretation.  Registering these inputs also removes
    // the issue/control muxes from the DSP-to-result critical path.
    assign product = multiplicand_q * multiplier_q;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state   <= IDLE;
            done    <= 1'b0;
            mul_out <= 32'd0;
            multiplicand_q <= 33'sd0;
            multiplier_q   <= 33'sd0;
            high_result_q  <= 1'b0;
        end else begin
            done <= 1'b0;

            unique case (state)
                IDLE: begin
                    if (start) begin
                        multiplicand_q <= (alucon == 2'b01 || alucon == 2'b10)
                                          ? $signed({data_1[31], data_1})
                                          : $signed({1'b0, data_1});
                        multiplier_q <= (alucon == 2'b01)
                                        ? $signed({data_2[31], data_2})
                                        : $signed({1'b0, data_2});
                        high_result_q <= (alucon != 2'b00);
                        state         <= RUN;
                    end
                end

                RUN: begin
                    mul_out <= high_result_q ? product[63:32]
                                             : product[31:0];
                    done  <= 1'b1;
                    state <= IDLE;
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
