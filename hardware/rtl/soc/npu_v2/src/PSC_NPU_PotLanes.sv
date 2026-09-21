`timescale 1ns/1ps

// B bytes are two signed powers: low nibble first, high nibble second.
// Entire byte 0 is a special zero, preserving zero padding in the controller.
// A is signed INT8 when signed_mode=1, unsigned UINT8 otherwise.
module PSC_NPU_PotLanes #(parameter integer LANES = 8) (
    input wire clock, reset_n, capture, issue, phase,
    input wire [1:0] group_index,
    input wire signed_mode,
    input wire [127:0] data_A, data_B,
    output reg [LANES-1:0] wb_valid,
    output wire [LANES*4-1:0] wb_id,
    output wire [LANES*32-1:0] wb_data
);
    reg [127:0] a_snapshot, b_snapshot;
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            a_snapshot <= 0;
            b_snapshot <= 0;
            wb_valid <= 0;
        end else begin
            if (capture) begin
                a_snapshot <= data_A;
                b_snapshot <= data_B;
            end
            wb_valid <= {LANES{issue}};
        end
    end
    genvar lane, group;
    generate for (lane=0; lane<LANES; lane=lane+1) begin : GEN_LANE
        wire [(16/LANES)*8-1:0] lane_a, lane_b;
        for (group=0; group<16/LANES; group=group+1) begin : GEN_OPERANDS
            assign lane_a[group*8 +: 8] = a_snapshot[(group*LANES+lane)*8 +: 8];
            assign lane_b[group*8 +: 8] = b_snapshot[(group*LANES+lane)*8 +: 8];
        end
        wire [7:0] a = lane_a[group_index*8 +: 8];
        wire [7:0] code = lane_b[group_index*8 +: 8];
        wire [3:0] nibble = phase ? code[7:4] : code[3:0];
        wire [15:0] x = {{8{signed_mode && a[7]}}, a};
        reg [15:0] shifted;
        // Constant concatenations: no variable shift operator / barrel shifter.
        always @* begin
            case (nibble[2:0])
                3'd0: shifted = x;
                3'd1: shifted = {x[14:0],1'b0};
                3'd2: shifted = {x[13:0],2'b0};
                3'd3: shifted = {x[12:0],3'b0};
                3'd4: shifted = {x[11:0],4'b0};
                3'd5: shifted = {x[10:0],5'b0};
                3'd6: shifted = {x[9:0],6'b0};
                3'd7: shifted = {x[8:0],7'b0};
            endcase
        end
        wire [15:0] term_data = code == 8'd0 ? 16'd0 : (nibble[3] ? -shifted : shifted);
        reg [3:0] destination;
        reg [15:0] data;
        assign wb_id[lane*4 +: 4] = destination;
        assign wb_data[lane*32 +: 32] = {{16{data[15]}},data};
        always @(posedge clock or negedge reset_n) begin
            if (!reset_n) begin
                destination <= 0;
                data <= 0;
            end else if (issue) begin
                destination <= group_index*LANES+lane;
                data <= term_data;
            end
        end
    end endgenerate
endmodule
