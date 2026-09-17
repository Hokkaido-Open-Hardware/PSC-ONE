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

    reg signed [63:0] mul_ss;
    reg signed [64:0] mul_su;
    reg        [63:0] mul_uu;

    assign busy = (state != IDLE);

    always @(*) begin
        mul_ss = $signed(data_1) * $signed(data_2);

        mul_su = $signed({data_1[31], data_1})
               * $signed({1'b0, data_2});

        mul_uu = data_1 * data_2;
    end

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
                    case (alucon)
                        2'b00: begin
                            // MUL: 下位32bit
                            mul_out <= mul_uu[31:0];
                        end

                        2'b01: begin
                            // MULH: signed × signed 上位32bit
                            mul_out <= mul_ss[63:32];
                        end

                        2'b10: begin
                            // MULHSU: signed × unsigned 上位32bit
                            mul_out <= mul_su[63:32];
                        end

                        2'b11: begin
                            // MULHU: unsigned × unsigned 上位32bit
                            mul_out <= mul_uu[63:32];
                        end
                    endcase

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