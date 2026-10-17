`timescale 1ns/1ps
// 32-bit arithmetic/logic datapath and fixed 1/8-bit iterative shifter.
// Non-shift RV64 operations take two datapath cycles; W operations take one.
// All input context is captured on start; DONE is a one-cycle completion.
module Execute_ByteALU (
    input logic clk, reset_n, cancel, start,
    input logic [4:0] operation,
    input logic word_op,
    input logic [63:0] data_1, data_2,
    output logic done,
    output logic [63:0] result
);
    typedef enum logic [1:0] {IDLE, WORDS, SHIFT, FINISH} state_t;
    state_t state;
    logic [63:0] a, b, value;
    logic [4:0] op;
    logic word_q, carry, sign_a, sign_b;
    logic index;
    logic [5:0] shift_count;
    logic subtract, compare_op, shift_op;
    logic [32:0] sum;
    logic [31:0] word_value;
    logic less;

    assign subtract = (op == 5'b10000) || (op == 5'b00010) || (op == 5'b00011);
    assign compare_op = (op == 5'b00010) || (op == 5'b00011);
    assign shift_op = (op == 5'b00001) || (op == 5'b00101) || (op == 5'b10101);
    assign sum = {1'b0, a[31:0]} + {1'b0, (b[31:0] ^ {32{subtract}})} + {32'b0, carry};
    assign less = (op == 5'b00010 && sign_a != sign_b) ? sign_a : !carry;
    assign done = state == FINISH;

    // Datapath: one 32-bit adder; operand rotation uses fixed wiring.
    always_comb begin
        case (op)
            5'b00000, 5'b10000, 5'b00010, 5'b00011: word_value = sum[31:0];
            5'b00100: word_value = a[31:0] ^ b[31:0];
            5'b00110: word_value = a[31:0] | b[31:0];
            5'b00111: word_value = a[31:0] & b[31:0];
            default: word_value = 32'b0;
        endcase
        if (compare_op)
            result = {63'b0, less};
        else if (word_q && !shift_op)
            result = {{32{value[63]}}, value[63:32]};
        else if (word_q)
            result = {{32{value[31]}}, value[31:0]};
        else
            result = value;
    end

    // Control only resets validity/state. Every payload is initialized at start.
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            state <= IDLE;
        else if (cancel)
            state <= IDLE;
        else case (state)
            IDLE: if (start) begin
                a <= data_1;
                b <= data_2;
                op <= operation;
                word_q <= word_op;
                sign_a <= data_1[63];
                sign_b <= data_2[63];
                carry <= (operation == 5'b10000) ||
                         (operation == 5'b00010) || (operation == 5'b00011);
                index <= 0;
                shift_count <= word_op ? {1'b0, data_2[4:0]} : data_2[5:0];
                if (operation == 5'b00001 || operation == 5'b00101 || operation == 5'b10101) begin
                    value <= !word_op ? data_1 : operation == 5'b10101 ?
                             {{32{data_1[31]}}, data_1[31:0]} : {32'b0, data_1[31:0]};
                    state <= SHIFT;
                end else begin
                    value <= 0;
                    state <= WORDS;
                end
            end
            WORDS: begin
                a <= {a[31:0], a[63:32]};
                b <= {b[31:0], b[63:32]};
                value <= {word_value, value[63:32]};
                carry <= sum[32];
                index <= index + 1'b1;
                if (word_q || index) state <= FINISH;
            end
            SHIFT: begin
                if (shift_count == 0)
                    state <= FINISH;
                else if (shift_count >= 8) begin
                    shift_count <= shift_count - 6'd8;
                    if (op == 5'b00001) value <= {value[55:0], 8'b0};
                    else value <= {{8{op[4] && value[63]}}, value[63:8]};
                end else begin
                    shift_count <= shift_count - 1'b1;
                    if (op == 5'b00001) value <= {value[62:0], 1'b0};
                    else value <= {op[4] && value[63], value[63:1]};
                end
            end
            FINISH: state <= IDLE;
            default: state <= IDLE;
        endcase
    end
endmodule
