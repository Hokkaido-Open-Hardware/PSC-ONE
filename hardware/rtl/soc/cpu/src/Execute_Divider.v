// NISHIHARU

module Execute_Divider(

    input  wire        clk,
    input  wire        reset_n,

    input  wire        start,
    input  wire        signed_mode,

    input  wire [31:0] dividend,
    input  wire [31:0] divisor,

    output wire        busy,
    output wire        done,

    output wire [31:0] quotient,
    output wire [31:0] remainder
);

    localparam IDLE = 4'd0;
    localparam INIT = 4'd1;
    localparam RUN  = 4'd2;
    localparam FIX  = 4'd3;
    localparam DONE = 4'd4;

    reg [3:0] state;

    reg [31:0] dividend_abs;
    reg [31:0] divisor_abs;

    reg [31:0] quotient_reg;
    reg [32:0] remainder_reg;

    reg [5:0]  count;

    reg        quotient_neg;
    reg        remainder_neg;

    reg [31:0] quotient_out;
    reg [31:0] remainder_out;

    assign busy      = (state != IDLE) && (state != DONE);
    assign done      = (state == DONE);

    assign quotient  = quotient_out;
    assign remainder = remainder_out;

    wire dividend_is_neg    = signed_mode && dividend[31];
    wire divisor_is_neg     = signed_mode && divisor[31];

    wire [31:0] dividend_abs_w  = dividend_is_neg ? (~dividend + 32'd1) : dividend;
    wire [31:0] divisor_abs_w   = divisor_is_neg ? (~divisor + 32'd1) : divisor;

    wire quotient_neg_w     = signed_mode && (dividend[31] ^ divisor[31]);
    wire remainder_neg_w    = signed_mode && dividend[31];

    wire [32:0] rem_shift_w = {remainder_reg[31:0], dividend_abs[31]};
    wire rem_ge_div_w       = (rem_shift_w >= {1'b0, divisor_abs});
    wire [32:0] rem_sub_w   = rem_shift_w - {1'b0, divisor_abs};

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state         <= IDLE;
            dividend_abs  <= 32'd0;
            divisor_abs   <= 32'd0;
            quotient_reg  <= 32'd0;
            remainder_reg <= 33'd0;
            count         <= 6'd0;

            quotient_neg  <= 1'b0;
            remainder_neg <= 1'b0;
            quotient_out  <= 32'd0;
            remainder_out <= 32'd0;

        end else begin

            case (state)

                IDLE: begin
                    if (start) begin
                        state <= INIT;
                    end
                end
                INIT: begin
                    dividend_abs  <= dividend_abs_w;
                    divisor_abs   <= divisor_abs_w;

                    quotient_reg  <= 32'd0;
                    remainder_reg <= 33'd0;

                    count         <= 6'd32;

                    quotient_neg  <= quotient_neg_w;
                    remainder_neg <= remainder_neg_w;

                    quotient_out  <= 32'd0;
                    remainder_out <= 32'd0;

                    state         <= RUN;
                end
                RUN: begin
                    if (divisor_abs == 32'd0) begin
                        quotient_reg  <= 32'hFFFF_FFFF;
                        remainder_reg <= {1'b0, dividend_abs};
                        state         <= FIX;
                    end else begin
                        dividend_abs <= {dividend_abs[30:0], 1'b0};

                        if (rem_ge_div_w) begin
                            remainder_reg <= rem_sub_w;
                            quotient_reg  <= {quotient_reg[30:0], 1'b1};
                        end else begin
                            remainder_reg <= rem_shift_w;
                            quotient_reg  <= {quotient_reg[30:0], 1'b0};
                        end

                        count <= count - 6'd1;

                        if (count == 6'd1) begin
                            state <= FIX;
                        end
                    end
                end
                FIX: begin
                    if (divisor_abs == 32'd0) begin
                        quotient_out  <= 32'hFFFF_FFFF;
                        remainder_out <= dividend;
                    end else begin
                        quotient_out  <= quotient_neg
                                       ? (~quotient_reg + 32'd1)
                                       : quotient_reg;

                        remainder_out <= remainder_neg
                                       ? (~remainder_reg[31:0] + 32'd1)
                                       : remainder_reg[31:0];
                    end

                    state <= DONE;
                end
                DONE: begin
                    if (!start) begin
                        state <= IDLE;
                    end
                end
                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule