`timescale 1ns/1ps

// Common registered boundary for arithmetic-only comparisons. No PE sharing,
// scheduler, WB destination or AccBank. The 128-bit stimulus is identical in
// all three builds; only BLOCKS and KIND change. KIND=0 matches v1 arithmetic.
module PSC_NPU_DatapathTiming #(
    parameter integer BLOCKS=4,
    parameter integer KIND=0
)(input wire clock,reset_n, output reg timing_keep);
    (* keep = "true" *) reg [127:0] stimulus;
    (* keep = "true" *) reg [BLOCKS*8-1:0] operand_a,operand_b;
    (* keep = "true" *) reg mode;
    (* keep = "true" *) reg [BLOCKS*17-1:0] results;
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            stimulus <= 128'h8912ab45_1aef6342_97da8329_ab931f65;
            operand_a <= 0;
            operand_b <= 0;
            mode <= 0;
        end else begin
            stimulus <= {stimulus[126:0],stimulus[127]^stimulus[125]^stimulus[100]^stimulus[98]};
            if (stimulus[1]) begin
                operand_a <= stimulus[BLOCKS*8-1:0];
                operand_b <= stimulus[64 +: BLOCKS*8];
                mode <= stimulus[5];
            end
        end
    end
    genvar block_id;
    generate for (block_id=0; block_id<BLOCKS; block_id=block_id+1) begin : GEN_BLOCK
        wire [7:0] a=operand_a[block_id*8 +: 8];
        wire [7:0] b=operand_b[block_id*8 +: 8];
        wire [16:0] product;
        if (KIND == 0) begin : GEN_MUL
            wire signed [8:0] mul_a={mode && a[7],a};
            wire signed [8:0] mul_b={mode && b[7],b};
            // Identical input extension/product semantics to v1 Mul4.
            wire [15:0] raw_product=mul_a*mul_b;
            assign product={mode && raw_product[15],raw_product};
        end else begin : GEN_SHIFTADD
            PSC_NPU_ShiftAdd2 u_shiftadd (
                .activation(a),.weight_code(b),.signed_mode(mode),.product(product));
        end
        always @(posedge clock or negedge reset_n) begin
            if (!reset_n) results[block_id*17 +: 17] <= 0;
            else results[block_id*17 +: 17] <= product;
        end
    end endgenerate
    // Keep all registered products without introducing a wide XOR critical path.
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) timing_keep <= 0;
        else timing_keep <= results[0] ^ results[BLOCKS*17-2];
    end
endmodule
