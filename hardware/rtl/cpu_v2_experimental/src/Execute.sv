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
    output logic        busy,
    output logic        done
);

    typedef enum logic [1:0] {
        IDLE, DIV_WAIT, MUL_WAIT, RESULT_HOLD
    } state_t;

    state_t state;

    logic [31:0] operand_1;
    logic [31:0] operand_2;
    logic [31:0] multi_result;
    logic        is_div_op;
    logic        is_mul_op;
    logic        div_start;
    logic        div_busy;
    logic        div_done;
    logic        div_signed;
    logic        mul_start;
    logic        mul_busy;
    logic        mul_done;
    logic [31:0] div_quotient;
    logic [31:0] div_remainder;
    logic [31:0] mul_out;

    assign operand_1 = decoder_ctrl.op1sel
                     ? decoder_ctrl.out_pc : reg_data_addr1;
    assign operand_2 = decoder_ctrl.op2sel
                     ? decoder_ctrl.imm : reg_data_addr2;

    assign is_div_op = ENABLE_DIV &&
                       (decoder_ctrl.alucon[4:2] == 3'b111);
    assign is_mul_op = ENABLE_MUL &&
                       (decoder_ctrl.alucon[4:2] == 3'b110);
    assign div_signed = (decoder_ctrl.alucon == 5'b1_1100) ||
                        (decoder_ctrl.alucon == 5'b1_1110);
    assign div_start = execute_enb && (state == IDLE) && is_div_op;
    assign mul_start = execute_enb && (state == IDLE) && is_mul_op;

    Execute_Divider u_divider (
        .clk         (clock),
        .reset_n     (reset_n),
        .start       (div_start),
        .signed_mode (div_signed),
        .dividend    (operand_1),
        .divisor     (operand_2),
        .busy        (div_busy),
        .done        (div_done),
        .quotient    (div_quotient),
        .remainder   (div_remainder)
    );

    Execute_Mul u_multiplier (
        .clk     (clock),
        .reset_n (reset_n),
        .start   (mul_start),
        .alucon  (decoder_ctrl.alucon[1:0]),
        .data_1  (operand_1),
        .data_2  (operand_2),
        .busy    (mul_busy),
        .done    (mul_done),
        .mul_out (mul_out)
    );

    function automatic logic [31:0] alu_exec(
        input logic [4:0]  control,
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

    // All results cross this registered boundary before write-back.  For a
    // normal integer operation this adds one execution cycle, but separates
    // the 32-bit ALU carry/shift network from the ROB/PRF/forwarding muxes.
    always_comb begin
        r_data1 = reg_data_addr1;
        r_data2 = reg_data_addr2;
        out_pc  = decoder_ctrl.out_pc;
        busy    = (state != IDLE);
        done    = 1'b0;
        alu_data = multi_result;

        if (state == RESULT_HOLD) begin
            done     = execute_enb;
        end
    end

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            state        <= IDLE;
            multi_result <= 32'd0;
        end else begin
            case (state)
                IDLE: begin
                    if (div_start)
                        state <= DIV_WAIT;
                    else if (mul_start)
                        state <= MUL_WAIT;
                    else if (execute_enb) begin
                        multi_result <= alu_exec(decoder_ctrl.alucon,
                                                 operand_1, operand_2);
                        state <= RESULT_HOLD;
                    end
                end

                DIV_WAIT: begin
                    if (div_done) begin
                        multi_result <= decoder_ctrl.alucon[1]
                                      ? div_remainder : div_quotient;
                        state <= RESULT_HOLD;
                    end
                end

                MUL_WAIT: begin
                    if (mul_done) begin
                        multi_result <= mul_out;
                        state <= RESULT_HOLD;
                    end
                end

                RESULT_HOLD: begin
                    if (execute_enb)
                        state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

`ifdef PIPELINE_TRACE
    always_ff @(posedge clock) begin
        if (reset_n && div_start)
            $display("DIV-START clock=%0t pc=%08x dividend=%08x divisor=%08x",
                     $time, decoder_ctrl.out_pc, operand_1, operand_2);
        if (reset_n && div_done)
            $display("DIV-DONE clock=%0t quotient=%08x remainder=%08x",
                     $time, div_quotient, div_remainder);
    end
`endif

endmodule
