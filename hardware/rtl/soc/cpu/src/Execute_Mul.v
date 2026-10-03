// NISHIHARU

module Execute_Mul (
    input  wire        clk,
    input  wire        reset_n,

    input  wire        start,

    input  wire [1:0]  alucon,
    input  wire [31:0] data_1,
    input  wire [31:0] data_2,

    output wire        busy,
    output reg         done,

    output reg  [31:0] mul_out
);

    localparam IDLE = 2'd0;
    localparam RUN  = 2'd1;

    reg [1:0] state;

    wire signed [32:0] multiplicand;
    wire signed [32:0] multiplier;
    wire signed [65:0] product;

    assign busy = (state != IDLE);

    // One signed 33x33 product implements all four RV32M variants.
    // Preserve the legacy live-input contract: RUN samples these operands
    // and alucon, with no new registers or extra completion cycles.
    assign multiplicand = {(alucon == 2'b01 || alucon == 2'b10) && data_1[31], data_1};
    assign multiplier = {(alucon == 2'b01) && data_2[31], data_2};
    assign product = multiplicand * multiplier;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state      <= IDLE;
            done       <= 1'b0;
            mul_out    <= 32'd0;
        end else begin
            done <= 1'b0;

            case (state)

                IDLE: begin
                    if (start) begin
                        state      <= RUN;
                    end
                end

                RUN: begin
                    mul_out <= (alucon == 2'b00) ? product[31:0]
                                                : product[63:32];

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
