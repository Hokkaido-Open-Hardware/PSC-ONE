// NISHIHARU

import PSC_Types::*;

module Execute #(
    parameter bit ENABLE_MUL = 1'b1,
    parameter bit ENABLE_DIV = 1'b1
)(
    input  logic        clock,
    input  logic        reset_n,
    input  logic        execute_enb,
    input  logic [31:0] reg_data_addr1,
    input  logic [31:0] reg_data_addr2,
    input  dec_ctrl_t   decoder_ctrl,

    output logic [31:0] alu_data,
    output logic [31:0] r_data1,
    output logic [31:0] r_data2,
    output logic [31:0] out_pc,
    output logic        alu_done
);

    typedef enum logic [2:0] {
        IDLE, ALU_DIV_WAIT, ALU_DIV_DONE, ALU_MUL_WAIT
    } state_t;

    state_t state;

    logic [31:0] s_data1, s_data2;
    logic div_start, div_busy, div_done, div_signed;
    logic mul_start, mul_busy, mul_done;
    logic [31:0] div_quotient, div_remainder, mul_out;

    assign s_data1 = decoder_ctrl.op1sel ? decoder_ctrl.out_pc : reg_data_addr1;
    assign s_data2 = decoder_ctrl.op2sel ? decoder_ctrl.imm : reg_data_addr2;

    assign div_signed = (decoder_ctrl.alucon == 5'b1_1100) ||
                        (decoder_ctrl.alucon == 5'b1_1110);

    assign div_start =
                ENABLE_DIV &&
                execute_enb &&
                (state == IDLE) &&
                (decoder_ctrl.alucon[4:2] == 3'b111);

    assign mul_start =
                ENABLE_MUL &&
                execute_enb &&
                (state == IDLE) &&
                (decoder_ctrl.alucon[4:2] == 3'b110);

generate
    if (ENABLE_DIV) begin : g_divider
        Execute_Divider u_divider (
            .clk         (clock),
            .reset_n     (reset_n),
            .start       (div_start),
            .signed_mode (div_signed),
            .dividend    (s_data1),
            .divisor     (s_data2),
            .busy        (div_busy),
            .done        (div_done),
            .quotient    (div_quotient),
            .remainder   (div_remainder)
        );
    end else begin : g_no_divider
        assign div_busy      = 1'b0;
        assign div_done      = 1'b0;
        assign div_quotient  = 32'd0;
        assign div_remainder = 32'd0;
    end
endgenerate

generate
    if (ENABLE_MUL) begin : g_multiplier
        Execute_Mul u_multiplier (
            .clk     (clock),
            .reset_n (reset_n),
            .start   (mul_start),
            .alucon  (decoder_ctrl.alucon[1:0]),
            .data_1  (s_data1),
            .data_2  (s_data2),
            .busy    (mul_busy),
            .done    (mul_done),
            .mul_out (mul_out)
        );
    end else begin : g_no_multiplier
        assign mul_busy = 1'b0;
        assign mul_done = 1'b0;
        assign mul_out  = 32'd0;
    end
endgenerate

    function automatic logic [31:0] alu_exec(
        input logic [4:0] control,
        input logic [31:0] data1,
        input logic [31:0] data2
    );
        case (control)
            5'b0_0000: alu_exec = data1 + data2;
            5'b1_0000: alu_exec = data1 - data2;
            5'b0_0001: alu_exec = data1 << data2[4:0];
            5'b0_0010: alu_exec = {31'd0, $signed(data1) < $signed(data2)};
            5'b0_0011: alu_exec = {31'd0, data1 < data2};
            5'b0_0100: alu_exec = data1 ^ data2;
            5'b0_0101: alu_exec = data1 >> data2[4:0];
            5'b1_0101: alu_exec = $signed(data1) >>> data2[4:0];
            5'b0_0110: alu_exec = data1 | data2;
            5'b0_0111: alu_exec = data1 & data2;
            default:   alu_exec = 32'd0;
        endcase
    endfunction

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            state    <= IDLE;
            alu_data <= 32'd0;
            r_data1  <= 32'd0;
            r_data2  <= 32'd0;
            out_pc   <= 32'd0;
            alu_done <= 1'b0;
        end else begin
            alu_done <= 1'b0;

            case (state)
                IDLE: begin
                    if (div_start)
                        state <= ALU_DIV_WAIT;
                    else if (mul_start)
                        state <= ALU_MUL_WAIT;
                    else if (execute_enb) begin
                        alu_data <= alu_exec(decoder_ctrl.alucon, s_data1, s_data2);
                        alu_done <= 1'b1;
                    end

                    if (execute_enb) begin
                        r_data1 <= reg_data_addr1;
                        r_data2 <= reg_data_addr2;
                        out_pc  <= decoder_ctrl.out_pc;
                    end
                end

                ALU_DIV_WAIT:
                    if (div_done) state <= ALU_DIV_DONE;

                ALU_DIV_DONE: begin
                    alu_data <= decoder_ctrl.alucon[1] ? div_remainder
                                                       : div_quotient;
                    alu_done <= 1'b1;
                    state    <= IDLE;
                end

                ALU_MUL_WAIT:
                    if (mul_done) begin
                        alu_data <= mul_out;
                        alu_done <= 1'b1;
                        state    <= IDLE;
                    end

                default: state <= IDLE;
            endcase
        end
    end

endmodule