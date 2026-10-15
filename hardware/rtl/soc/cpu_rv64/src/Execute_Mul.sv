`timescale 1ns/1ps
// RV64M: one unsigned 32x32 multiplier reused for up to four partial products.
// Register each cross product before a shared 32-bit, two-cycle accumulation.
module Execute_Mul #(
    parameter bit ENABLE_PULP = 1'b0
)(
    input logic clk, reset_n, cancel, start,
    input logic [1:0] alucon,
    input logic word_op,
    // Reserved compatibility ports; custom dot products remain unsupported.
    input logic dotup_h, dotsp_b,
    input logic [63:0] data_1, data_2,
    output logic busy, done,
    output logic [63:0] mul_out
);
    typedef enum logic [2:0] {IDLE, PRODUCT, ADD_LO, ADD_HI, CORRECT_A,
                             CORRECT_B, FINISH} state_t;
    state_t state;
    logic [63:0] a, b, product, product_q;
    logic [64:0] acc;
    logic [31:0] add_lhs, add_rhs;
    logic [32:0] sum;
    logic [31:0] low, mul_a, mul_b;
    logic [1:0] mode_q, part;
    logic word_q, correct_a, correct_b, subtract, high_half, carry_q;
    logic select_high, carry_in;

    assign busy = state != IDLE && state != FINISH;
    // Cancellation wins even in the completion cycle, before the next edge.
    assign done = state == FINISH && !cancel;
    assign mul_out = word_q ? {{32{low[31]}}, low} :
                     mode_q == 0 ? {acc[31:0], low} : acc[63:0];
    // part: 0=AL*BL, 1=AH*BL, 2=AL*BH, 3=AH*BH.
    assign mul_a = part[0] ? a[63:32] : a[31:0];
    assign mul_b = part[1] ? b[63:32] : b[31:0];
    // The only multiply expression: both operands are 32-bit unsigned.
    assign product = mul_a * mul_b;
    assign subtract = state == CORRECT_A || state == CORRECT_B;
    assign select_high = state == ADD_HI || (subtract && high_half);
    assign add_lhs = select_high ? acc[63:32] : acc[31:0];
    assign add_rhs = state == CORRECT_A ? (select_high ? ~b[63:32] : ~b[31:0]) :
                     state == CORRECT_B ? (select_high ? ~a[63:32] : ~a[31:0]) :
                                         (select_high ? product_q[63:32] : product_q[31:0]);
    assign carry_in = select_high ? carry_q : subtract;
    // One 32-bit adder plus carry-out; no combinational carry across halves.
    assign sum = {1'b0, add_lhs} + {1'b0, add_rhs} + {32'b0, carry_in};

    // Payload is captured/initialized before use; only state needs reset.
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            state <= IDLE;
        else if (cancel)
            state <= IDLE;
        else case (state)
            IDLE: if (start) begin
                a <= data_1;
                b <= data_2;
                mode_q <= alucon;
                word_q <= word_op;
                correct_a <= (alucon == 1 || alucon == 2) && data_1[63];
                correct_b <= alucon == 1 && data_2[63];
                part <= 0;
                high_half <= 0;
                state <= PRODUCT;
            end
            PRODUCT: begin
                if (part == 0) begin
                    low <= product[31:0];
                    acc <= {33'b0, product[63:32]};
                    part <= 1;
                    state <= word_q ? FINISH : PRODUCT;
                end else begin
                    product_q <= product;
                    // Preserve cross-product bit 64 when forming high64.
                    if (part == 3) acc <= {32'b0, acc[64:32]};
                    state <= ADD_LO;
                end
            end
            ADD_LO: begin
                acc[31:0] <= sum[31:0];
                carry_q <= sum[32];
                state <= ADD_HI;
            end
            ADD_HI: begin
                acc[63:32] <= sum[31:0];
                acc[64] <= acc[64] ^ sum[32];
                // After part 2: high32(AL*BL) + AH*BL + AL*BH (65 bits).
                // After part 3: AH*BH + (cross-product accumulator >> 32).
                if (part == 3) begin
                    if (correct_a) state <= CORRECT_A;
                    else if (correct_b) state <= CORRECT_B;
                    else state <= FINISH;
                end else if (part == 2 && mode_q == 0)
                    state <= FINISH;
                else state <= PRODUCT;
                part <= part + 1'b1;
            end
            CORRECT_A, CORRECT_B: begin
                // Signed A = unsigned A - 2^64 when A is negative.
                // Subtract B/A modulo 2^64, carrying !borrow between halves.
                high_half <= !high_half;
                carry_q <= sum[32];
                if (!high_half) acc[31:0] <= sum[31:0];
                else begin
                    acc[63:32] <= sum[31:0];
                    state <= (state == CORRECT_A && correct_b) ? CORRECT_B : FINISH;
                end
            end
            FINISH: state <= IDLE;
            default: state <= IDLE;
        endcase
    end
endmodule
