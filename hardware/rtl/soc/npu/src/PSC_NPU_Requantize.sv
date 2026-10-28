`timescale 1ns/1ps

module PSC_NPU_Requantize (
    input  wire                    clock,
    input  wire                    reset_n,
    input  wire                    start,

    // INT32 accumulator / per-channel quantization parameters
    input  wire signed [31:0]      value,
    input  wire signed [31:0]      multiplier,
    input  wire signed [31:0]      shift,

    output reg                     busy,
    output reg                     done,
    output reg  signed [31:0]      result
);

    //======================================================
    // Datapath registers
    //======================================================
    reg signed [31:0] lhs;
    reg signed [31:0] rhs;
    reg signed [63:0] product;
    reg signed [31:0] high;
    reg signed [31:0] divided;

    reg [31:0] mask;
    reg [31:0] remainder;
    reg [31:0] threshold;
    reg [4:0]  left_shift;
    reg [4:0]  right_shift;

    reg        special;
    reg        increment;

    //--------------------------------------------
    // FSM
    //--------------------------------------------
    localparam [2:0]
        S_IDLE       = 3'd0,
        S_MULTIPLY   = 3'd1,
        S_HIGH_MUL   = 3'd2,
        S_DIVIDE     = 3'd3,
        S_ROUND      = 3'd4,
        S_DONE       = 3'd5,
        S_SHIFT      = 3'd6;

    reg [2:0] state;

    //--------------------------------------------
    // Main FSM
    //--------------------------------------------
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            state       <= S_IDLE;

            lhs         <= 32'd0;
            rhs         <= 32'd0;
            product     <= 64'd0;
            high        <= 32'd0;
            divided     <= 32'd0;

            mask        <= 32'd0;
            remainder   <= 32'd0;
            threshold   <= 32'd0;
            left_shift  <= 5'd0;
            right_shift <= 5'd0;
            special     <= 1'b0;
            increment   <= 1'b0;

            busy        <= 1'b0;
            done        <= 1'b0;
            result      <= 32'd0;
        end else begin
            // Default one-cycle pulse
            done <= 1'b0;

            case (state)
                //--------------------------------------------
                // shift: -31..30
                // ACC選択MUXの出力とシフト量を先に登録する。
                // ACC選択から左シフトまでを同一サイクルにしない。
                //--------------------------------------------
                S_IDLE: begin
                    if (start) begin
                        lhs         <= value;
                        rhs         <= multiplier;
                        left_shift  <= (shift > 0) ? shift[4:0] : 5'd0;
                        right_shift <= (shift < 0) ? -shift : 0;
                        busy        <= 1'b1;
                        state       <= S_SHIFT;
                    end
                end

                //--------------------------------------------
                // 左シフトはRV32と同じ下位32bitを保持する。
                //--------------------------------------------
                S_SHIFT: begin
                    lhs   <= lhs << left_shift;
                    state <= S_MULTIPLY;
                end

                //--------------------------------------------
                // Signed INT32 x INT32 -> INT64
                //--------------------------------------------
                S_MULTIPLY: begin
                    product <= lhs * rhs;
                    mask    <= (32'd1 << right_shift) - 32'd1;
                    special <= (lhs == 32'sh80000000)
                               && (rhs == 32'sh80000000);
                    state   <= S_HIGH_MUL;
                end

                //--------------------------------------------
                // SaturatingRoundingDoublingHighMul
                //
                // 正負ともに以下は同値:
                //   trunc((product + nudge) / 2^31)
                //   floor((product + 2^30) / 2^31)
                // bit30をbits62:31への繰上がりとして使用する。
                // INT32_MIN x INT32_MINのみINT32_MAXへ飽和。
                //--------------------------------------------
                S_HIGH_MUL: begin
                    high  <= special
                             ? 32'sh7fffffff
                             : product[62:31] + {31'd0, product[30]};
                    state <= S_DIVIDE;
                end

                //--------------------------------------------
                // RoundingDivideByPOT: shift / remainder
                //--------------------------------------------
                S_DIVIDE: begin
                    divided   <= high >>> right_shift;
                    remainder <= high & mask;
                    threshold <= (mask >> 1) + {31'd0, high[31]};
                    state     <= S_ROUND;
                end

                //--------------------------------------------
                // 負数を含む丸め判定
                //--------------------------------------------
                S_ROUND: begin
                    increment <= remainder > threshold;
                    state     <= S_DONE;
                end

                //--------------------------------------------
                // Final INT32 result
                //--------------------------------------------
                S_DONE: begin
                    result <= divided + {31'd0, increment};
                    busy   <= 1'b0;
                    done   <= 1'b1;
                    state  <= S_IDLE;
                end

                default: begin
                    state <= S_IDLE;
                    busy  <= 1'b0;
                end
            endcase
        end
    end

endmodule
