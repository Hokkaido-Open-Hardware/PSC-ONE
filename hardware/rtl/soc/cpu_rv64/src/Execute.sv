`timescale 1ns/1ps
import PSC_Types::*;

// Execution handshake controller. Arithmetic datapaths/FSMs live in the
// byte ALU, multiplier and divider modules. A result remains stable until
// the pipeline accepts it; cancel discards every outstanding operation.
module Execute #(
    parameter bit ENABLE_MUL = 1'b1,
    parameter bit ENABLE_DIV = 1'b1,
    parameter bit ENABLE_PULP = 1'b0
)(
    input logic clock, reset_n, cancel, execute_enb,
    input logic [63:0] reg_data_addr1, reg_data_addr2,
    input dec_ctrl_t decoder_ctrl,
    output logic [63:0] alu_data, r_data1, r_data2, out_pc,
    output logic busy, done
);
    typedef enum logic [2:0] {IDLE, ALU_WAIT, DIV_WAIT, MUL_WAIT, RESULT_HOLD} state_t;
    state_t state;
    logic [63:0] operand_1, operand_2, div_operand_1, div_operand_2;
    logic [63:0] byte_result, div_quotient, div_remainder, mul_out, result_q;
    logic is_div_op, is_mul_op, div_signed;
    logic byte_start, div_start, mul_start, byte_done, div_done, mul_done;
    logic word_q, remainder_q;

    assign operand_1 = decoder_ctrl.op1sel ? decoder_ctrl.out_pc : reg_data_addr1;
    assign operand_2 = decoder_ctrl.op2sel ? decoder_ctrl.imm : reg_data_addr2;
    assign is_div_op = ENABLE_DIV && decoder_ctrl.alucon[4:2] == 3'b111;
    assign is_mul_op = ENABLE_MUL && decoder_ctrl.alucon[4:2] == 3'b110;
    assign div_signed = !decoder_ctrl.alucon[0];
    assign div_operand_1 = !decoder_ctrl.word_op ? operand_1 : div_signed ?
                          {{32{operand_1[31]}}, operand_1[31:0]} : {32'b0, operand_1[31:0]};
    assign div_operand_2 = !decoder_ctrl.word_op ? operand_2 : div_signed ?
                          {{32{operand_2[31]}}, operand_2[31:0]} : {32'b0, operand_2[31:0]};
    assign byte_start = execute_enb && !cancel && state == IDLE && !is_div_op && !is_mul_op;
    assign div_start = execute_enb && !cancel && state == IDLE && is_div_op;
    assign mul_start = execute_enb && !cancel && state == IDLE && is_mul_op;
    assign r_data1 = reg_data_addr1;
    assign r_data2 = reg_data_addr2;
    assign out_pc = decoder_ctrl.out_pc;
    assign busy = state != IDLE;
    assign done = state == RESULT_HOLD && execute_enb && !cancel;
    assign alu_data = word_q ? {{32{result_q[31]}}, result_q[31:0]} : result_q;

    Execute_ByteALU u_byte_alu (
        .clk(clock), .reset_n(reset_n), .cancel(cancel), .start(byte_start),
        .operation(decoder_ctrl.alucon), .word_op(decoder_ctrl.word_op),
        .data_1(operand_1), .data_2(operand_2), .done(byte_done), .result(byte_result)
    );
    Execute_Divider u_divider (
        .clk(clock), .reset_n(reset_n), .cancel(cancel), .start(div_start),
        .signed_mode(div_signed), .dividend(div_operand_1), .divisor(div_operand_2),
        .busy(), .done(div_done), .quotient(div_quotient), .remainder(div_remainder)
    );
    Execute_Mul #(.ENABLE_PULP(ENABLE_PULP)) u_multiplier (
        .clk(clock), .reset_n(reset_n), .cancel(cancel), .start(mul_start),
        .word_op(decoder_ctrl.word_op),
        .alucon(decoder_ctrl.alucon[1:0]), .dotup_h(1'b0), .dotsp_b(1'b0),
        .data_1(operand_1), .data_2(operand_2), .busy(), .done(mul_done), .mul_out(mul_out)
    );

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            state <= IDLE;
        else if (cancel)
            state <= IDLE;
        else case (state)
            IDLE: if (execute_enb) begin
                word_q <= decoder_ctrl.word_op;
                remainder_q <= decoder_ctrl.alucon[1];
                if (is_div_op) state <= DIV_WAIT;
                else if (is_mul_op) state <= MUL_WAIT;
                else state <= ALU_WAIT;
            end
            ALU_WAIT: if (byte_done) begin result_q <= byte_result; state <= RESULT_HOLD; end
            DIV_WAIT: if (div_done) begin
                result_q <= remainder_q ? div_remainder : div_quotient;
                state <= RESULT_HOLD;
            end
            MUL_WAIT: if (mul_done) begin result_q <= mul_out; state <= RESULT_HOLD; end
            RESULT_HOLD: if (execute_enb) state <= IDLE;
            default: state <= IDLE;
        endcase
    end
endmodule
