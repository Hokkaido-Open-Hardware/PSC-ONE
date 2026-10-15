`timescale 1ns/1ps
// Restoring RV64 divider: eight byte-subtractions per quotient bit.
// The remainder's extra bit is retained across each subtraction. The
// original remainder is rotated, not overwritten, until borrow is known.
module Execute_Divider (
    input logic clk, reset_n, cancel, start, signed_mode,
    input logic [63:0] dividend, divisor,
    output logic busy, done,
    output logic [63:0] quotient, remainder
);
    typedef enum logic [3:0] {IDLE, ABS_Q, ABS_D, SHIFT, SUBTRACT,
                             CHOOSE, FIX_Q, FIX_R, FINISH} state_t;
    state_t state;
    logic [63:0] q, d, trial;
    logic [64:0] r;
    logic [5:0] bit_count;
    logic [2:0] byte_count;
    logic carry, quotient_neg, remainder_neg, divisor_neg;
    logic [7:0] lhs, rhs;
    logic [8:0] sum;

    assign busy = state != IDLE && state != FINISH;
    assign done = state == FINISH;
    assign quotient = q;
    assign remainder = r[63:0];

    // Shared adder also performs two's-complement normalization/correction.
    always_comb begin
        lhs = 0;
        rhs = 0;
        case (state)
            ABS_Q, FIX_Q: rhs = ~q[7:0];
            ABS_D: rhs = ~d[7:0];
            FIX_R: rhs = ~r[7:0];
            SUBTRACT: begin lhs = r[7:0]; rhs = ~d[7:0]; end
            default: ;
        endcase
        sum = {1'b0, lhs} + {1'b0, rhs} + {8'b0, carry};
    end

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            state <= IDLE;
        else if (cancel)
            state <= IDLE;
        else case (state)
            IDLE: if (start) begin
                q <= dividend;
                d <= divisor;
                r <= 0;
                trial <= 0;
                byte_count <= 0;
                bit_count <= 0;
                carry <= 1;
                quotient_neg <= signed_mode && (dividend[63] ^ divisor[63]);
                remainder_neg <= signed_mode && dividend[63];
                divisor_neg <= signed_mode && divisor[63];
                if (divisor == 0) begin
                    q <= 64'hffffffffffffffff;
                    r <= {1'b0, dividend};
                    state <= FINISH;
                end else if (signed_mode && dividend[63]) state <= ABS_Q;
                else if (signed_mode && divisor[63]) state <= ABS_D;
                else state <= SHIFT;
            end
            ABS_Q, ABS_D, FIX_Q, FIX_R: begin
                case (state)
                    ABS_Q, FIX_Q: q <= {sum[7:0], q[63:8]};
                    ABS_D: d <= {sum[7:0], d[63:8]};
                    default: r <= {1'b0, sum[7:0], r[63:8]};
                endcase
                carry <= sum[8];
                byte_count <= byte_count + 1'b1;
                if (byte_count == 7) begin
                    carry <= 1;
                    case (state)
                        ABS_Q: state <= divisor_neg ? ABS_D : SHIFT;
                        ABS_D: state <= SHIFT;
                        FIX_Q: state <= remainder_neg ? FIX_R : FINISH;
                        default: state <= FINISH;
                    endcase
                end
            end
            SHIFT: begin
                r <= {r[63:0], q[63]};
                q <= {q[62:0], 1'b0};
                carry <= 1;
                byte_count <= 0;
                state <= SUBTRACT;
            end
            SUBTRACT: begin
                trial <= {sum[7:0], trial[63:8]};
                r <= {r[64], r[7:0], r[63:8]};
                d <= {d[7:0], d[63:8]};
                carry <= sum[8];
                byte_count <= byte_count + 1'b1;
                if (byte_count == 7) state <= CHOOSE;
            end
            CHOOSE: begin
                if (r[64] || carry) begin
                    r <= {1'b0, trial};
                    q[0] <= 1;
                end
                bit_count <= bit_count + 1'b1;
                carry <= 1;
                byte_count <= 0;
                if (bit_count != 63) state <= SHIFT;
                else if (quotient_neg) state <= FIX_Q;
                else if (remainder_neg) state <= FIX_R;
                else state <= FINISH;
            end
            FINISH: state <= IDLE;
            default: state <= IDLE;
        endcase
    end
endmodule
