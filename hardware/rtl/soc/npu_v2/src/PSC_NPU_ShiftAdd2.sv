`timescale 1ns/1ps

// One complete two-term product, combinational (no accumulator or phase).
// code==0 is zero; otherwise both signed powers are evaluated concurrently.
// Each term fits signed 16 bits; their sum needs 17 bits for all byte codes.
module PSC_NPU_ShiftAdd2 (
    input  wire [7:0] activation,
    input  wire [7:0] weight_code,
    input  wire signed_mode,
    output wire [16:0] product
);
    wire [15:0] x = {{8{signed_mode && activation[7]}},activation};
    function [15:0] fixed_shift;
        input [15:0] value;
        input [2:0] exponent;
        begin
            case (exponent)
                3'd0: fixed_shift = value;
                3'd1: fixed_shift = {value[14:0],1'b0};
                3'd2: fixed_shift = {value[13:0],2'b0};
                3'd3: fixed_shift = {value[12:0],3'b0};
                3'd4: fixed_shift = {value[11:0],4'b0};
                3'd5: fixed_shift = {value[10:0],5'b0};
                3'd6: fixed_shift = {value[9:0],6'b0};
                3'd7: fixed_shift = {value[8:0],7'b0};
            endcase
        end
    endfunction
    wire [15:0] shifted0 = fixed_shift(x,weight_code[2:0]);
    wire [15:0] shifted1 = fixed_shift(x,weight_code[6:4]);
    wire [15:0] term0 = weight_code[3] ? -shifted0 : shifted0;
    wire [15:0] term1 = weight_code[7] ? -shifted1 : shifted1;
    assign product = weight_code == 8'd0 ? 17'd0 :
                     {term0[15],term0} + {term1[15],term1};
endmodule
