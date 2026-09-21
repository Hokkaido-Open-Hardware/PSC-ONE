`timescale 1ns/1ps

// Bounded 4:1 word selections followed by one 4:1 word selection.
// Every packed-bus slice is an elaboration-time constant. No runtime
// indexing of the 512-bit accumulator bus, and no extra pipeline stage.
module PSC_NPU_AccReadMux (
    input wire [511:0] accumulators,
    input wire [5:0] select_id,
    output reg [31:0] value
);
    wire [127:0] rows;
    genvar row;
    generate for (row = 0; row < 4; row = row + 1) begin : g_row
        reg [31:0] selected;
        always @(*) begin
            case (select_id[1:0])
                2'd0: selected = accumulators[(row*4+0)*32 +: 32];
                2'd1: selected = accumulators[(row*4+1)*32 +: 32];
                2'd2: selected = accumulators[(row*4+2)*32 +: 32];
                2'd3: selected = accumulators[(row*4+3)*32 +: 32];
                default: selected = 32'b0;
            endcase
        end
        assign rows[row*32 +: 32] = selected;
    end endgenerate

    always @(*) begin
        case (select_id[3:2])
            2'd0: value = rows[31:0];
            2'd1: value = rows[63:32];
            2'd2: value = rows[95:64];
            2'd3: value = rows[127:96];
            default: value = 32'b0;
        endcase
        // The public port is six bits; only IDs 0..15 denote a PE.
        if (select_id[5:4] != 2'b00) value = 32'b0;
    end
endmodule
