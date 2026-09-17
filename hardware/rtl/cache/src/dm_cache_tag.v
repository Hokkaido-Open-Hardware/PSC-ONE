`timescale 1ns/1ps

module dm_cache_tag #(
    parameter TAG_WIDTH   = 32,
    parameter INDEX_WIDTH = 10,
    parameter DEPTH       = (1 << INDEX_WIDTH)
)(
    input  wire                    clk,
    input  wire                    we,
    input  wire [INDEX_WIDTH-1:0]  index,
    input  wire [TAG_WIDTH-1:0]    tag_write,
    output reg  [TAG_WIDTH-1:0]    tag_read
);

    reg [TAG_WIDTH-1:0] tag_mem [0:DEPTH-1];

    integer i;

    always @(posedge clk) begin
        if (we)
            tag_mem[index] <= tag_write;
        // read
        tag_read <= we ? tag_write : tag_mem[index];
    end

endmodule
