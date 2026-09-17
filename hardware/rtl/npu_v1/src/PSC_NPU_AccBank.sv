`timescale 1ns/1ps

// Sixteen FSM-less accumulators. Entry i receives only lane i % 4.
module PSC_NPU_AccBank (
    input  wire         clock,
    input  wire         reset_n,
    input  wire         clear,
    input  wire [3:0]   wb_valid,
    input  wire [15:0]  wb_id,
    input  wire [127:0] wb_data,
    output wire [511:0] ps_acc
);
    genvar entry;
    generate for (entry = 0; entry < 16; entry = entry + 1) begin : GEN_ACC
        localparam [3:0] ACC_ID = entry;
        localparam integer LANE = entry % 4;
        reg [31:0] accumulator;
        wire hit = wb_valid[LANE] && wb_id[LANE*4 +: 4] == ACC_ID;
        always @(posedge clock or negedge reset_n) begin
            if (!reset_n)
                accumulator <= 32'd0;
            else if (clear)
                accumulator <= 32'd0;
            else if (hit)
                accumulator <= accumulator + wb_data[LANE*32 +: 32];
        end
        assign ps_acc[entry*32 +: 32] = accumulator;
    end endgenerate
endmodule
