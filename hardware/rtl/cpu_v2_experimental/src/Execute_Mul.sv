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

    logic signed [63:0] mul_ss;
    logic signed [64:0] mul_su;
    logic        [63:0] mul_uu;

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
        end else begin
            done <= 1'b0;

            unique case (state)
                IDLE: begin
                    if (start) begin
                        state <= RUN;
                    end
                end

                RUN: begin
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

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule