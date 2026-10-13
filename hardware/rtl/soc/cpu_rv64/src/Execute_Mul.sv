`timescale 1ns/1ps
// RV64M multiplier. Operands/control are captured before the multiply stage.
module Execute_Mul #(
    parameter bit ENABLE_PULP = 1'b0
)(
    input logic clk, reset_n, start,
    input logic [1:0] alucon,
    // Reserved compatibility ports: RV32 custom dot-product instructions are disabled.
    input logic dotup_h, dotsp_b,
    input logic [63:0] data_1, data_2,
    output logic busy, done,
    output logic [63:0] mul_out
);
    typedef enum logic [1:0] {IDLE, PRODUCT, RESULT} state_t;
    state_t state;
    logic signed [64:0] a, b;
    logic signed [129:0] product;
    logic [127:0] product_q;
    logic [1:0] mode_q;
    assign busy = state != IDLE;
    assign product = a * b;
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            a <= '0; b <= '0; product_q <= '0; mode_q <= '0;
            done <= 1'b0; mul_out <= '0;
        end else begin
            done <= 1'b0;
            case (state)
                IDLE: if (start) begin
                    a <= {(alucon == 1 || alucon == 2) && data_1[63], data_1};
                    b <= {(alucon == 1) && data_2[63], data_2};
                    mode_q <= alucon;
                    state <= PRODUCT;
                end
                PRODUCT: begin
                    product_q <= product[127:0];
                    state <= RESULT;
                end
                RESULT: begin
                    mul_out <= mode_q == 0 ? product_q[63:0] : product_q[127:64];
                    done <= 1'b1;
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
