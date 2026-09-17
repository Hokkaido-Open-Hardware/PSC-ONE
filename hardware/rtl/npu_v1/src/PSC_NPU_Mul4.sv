`timescale 1ns/1ps

// Four INT8 multipliers. Each owns one column of the sixteen-entry ACC bank.
// The only product storage is the four registered write-back lanes.
module PSC_NPU_Mul4 (
    input  wire         clock,
    input  wire         reset_n,
    input  wire         capture,
    input  wire         issue,
    input  wire [1:0]   group_index,
    input  wire         signed_mode,
    input  wire [127:0] data_A,
    input  wire [127:0] data_B,
    output reg  [3:0]   wb_valid,
    output wire [15:0]  wb_id,
    output wire [127:0] wb_data
);
    reg [127:0] a_snapshot;
    reg [127:0] b_snapshot;
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            a_snapshot <= 128'd0;
            b_snapshot <= 128'd0;
            wb_valid   <= 4'd0;
        end else begin
            if (capture) begin
                a_snapshot <= data_A;
                b_snapshot <= data_B;
            end
            wb_valid <= {4{issue}};
        end
    end

    genvar lane;
    generate for (lane = 0; lane < 4; lane = lane + 1) begin : GEN_LANE
        localparam [1:0] LANE_ID = lane;
        // Fixed four-to-one operand muxes, not sixteen-to-one crossbars.
        wire [31:0] lane_a = {a_snapshot[(12+lane)*8 +: 8],
                             a_snapshot[(8+lane)*8 +: 8],
                             a_snapshot[(4+lane)*8 +: 8],
                             a_snapshot[lane*8 +: 8]};
        wire [31:0] lane_b = {b_snapshot[(12+lane)*8 +: 8],
                             b_snapshot[(8+lane)*8 +: 8],
                             b_snapshot[(4+lane)*8 +: 8],
                             b_snapshot[lane*8 +: 8]};
        wire [7:0] a = lane_a[group_index*8 +: 8];
        wire [7:0] b = lane_b[group_index*8 +: 8];
        // One signed 9x9 operation per lane handles both INT8 modes.
        // The INT8 product fits in 16 bits; unsigned extension is always zero.
        wire signed [8:0] mul_a = {signed_mode && a[7], a};
        wire signed [8:0] mul_b = {signed_mode && b[7], b};
        wire [15:0] product = mul_a * mul_b;
        reg [1:0] destination_group;
        reg [31:0] data;
        assign wb_id[lane*4 +: 4] = {destination_group, LANE_ID};
        assign wb_data[lane*32 +: 32] = data;
        always @(posedge clock or negedge reset_n) begin
            if (!reset_n) begin
                destination_group <= 2'd0;
                data <= 32'd0;
            end else if (issue) begin
                destination_group <= group_index;
                data <= {{16{signed_mode && product[15]}}, product};
            end
        end
    end endgenerate
endmodule
