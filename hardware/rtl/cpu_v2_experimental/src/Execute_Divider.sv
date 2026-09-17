// NISHIHARU

module Execute_Divider(
    input  logic        clk,
    input  logic        reset_n,
    input  logic        start,
    input  logic        signed_mode,
    input  logic [31:0] dividend,
    input  logic [31:0] divisor,

    output logic        busy,
    output logic        done,
    output logic [31:0] quotient,
    output logic [31:0] remainder
);

    typedef enum logic [2:0] {IDLE, INIT, RUN, FIX, DONE} state_t;
    state_t state;

    logic [31:0] dividend_abs, divisor_abs, quotient_reg;
    logic [32:0] remainder_reg;
    logic [5:0]  count;
    logic quotient_neg, remainder_neg;

    logic dividend_is_neg, divisor_is_neg;
    logic [31:0] dividend_abs_w, divisor_abs_w;
    logic quotient_neg_w, remainder_neg_w;
    logic [32:0] rem_shift_w, rem_sub_w;
    logic rem_ge_div_w;

    assign busy = (state != IDLE) && (state != DONE);
    assign done = (state == DONE);

    assign dividend_is_neg = signed_mode && dividend[31];
    assign divisor_is_neg  = signed_mode && divisor[31];
    assign dividend_abs_w  = dividend_is_neg ? (~dividend + 1'b1) : dividend;
    assign divisor_abs_w   = divisor_is_neg  ? (~divisor  + 1'b1) : divisor;
    assign quotient_neg_w  = signed_mode && (dividend[31] ^ divisor[31]);
    assign remainder_neg_w = signed_mode && dividend[31];

    assign rem_shift_w  = {remainder_reg[31:0], dividend_abs[31]};
    assign rem_ge_div_w = (rem_shift_w >= {1'b0, divisor_abs});
    assign rem_sub_w    = rem_shift_w - {1'b0, divisor_abs};

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state         <= IDLE;
            dividend_abs  <= '0;
            divisor_abs   <= '0;
            quotient_reg  <= '0;
            remainder_reg <= '0;
            count         <= '0;
            quotient_neg  <= 1'b0;
            remainder_neg <= 1'b0;
            quotient      <= '0;
            remainder     <= '0;
        end else begin
            case (state)
                IDLE:
                    if (start) state <= INIT;

                INIT: begin
                    dividend_abs  <= dividend_abs_w;
                    divisor_abs   <= divisor_abs_w;
                    quotient_reg  <= '0;
                    remainder_reg <= '0;
                    count         <= 6'd32;
                    quotient_neg  <= quotient_neg_w;
                    remainder_neg <= remainder_neg_w;
                    quotient      <= '0;
                    remainder     <= '0;
                    state         <= RUN;
                end

                RUN: begin
                    if (divisor_abs == 0) begin
                        quotient_reg  <= 32'hFFFF_FFFF;
                        remainder_reg <= {1'b0, dividend_abs};
                        state         <= FIX;
                    end else begin
                        dividend_abs <= {dividend_abs[30:0], 1'b0};
                        remainder_reg <= rem_ge_div_w ? rem_sub_w : rem_shift_w;
                        quotient_reg  <= {quotient_reg[30:0], rem_ge_div_w};
                        count         <= count - 1'b1;
                        if (count == 1) state <= FIX;
                    end
                end

                FIX: begin
                    if (divisor_abs == 0) begin
                        quotient  <= 32'hFFFF_FFFF;
                        remainder <= dividend;
                    end else begin
                        quotient  <= quotient_neg  ? (~quotient_reg + 1'b1) :
                                                     quotient_reg;
                        remainder <= remainder_neg ? (~remainder_reg[31:0] + 1'b1) :
                                                     remainder_reg[31:0];
                    end
                    state <= DONE;
                end

                DONE:
                    if (!start) state <= IDLE;

                default: state <= IDLE;
            endcase
        end
    end

endmodule