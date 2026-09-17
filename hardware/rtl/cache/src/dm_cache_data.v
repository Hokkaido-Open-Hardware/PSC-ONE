// ===============================================================
// dm_cache_data : 128bit line data RAM (sync read, write-first)
// ===============================================================
`timescale 1ns/1ps

module dm_cache_data #(
    parameter DATA_WIDTH  = 128,
    parameter INDEX_WIDTH = 10,
    parameter DEPTH       = (1 << INDEX_WIDTH)
)(
    input  wire                     clk,
    input  wire                     we,
    input  wire [INDEX_WIDTH-1:0]   index,
    input  wire [DATA_WIDTH-1:0]    data_write,
    output reg  [DATA_WIDTH-1:0]    data_read   // sync read (1clk)
);

    reg [DATA_WIDTH-1:0] data_mem [0:DEPTH-1];

`ifdef COCOTB_SIM
    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            data_mem[i] = {DATA_WIDTH{1'b0}};
    end
`endif

    always @(posedge clk) begin
        if (we)
            data_mem[index] <= data_write;

        // write-first (同一index R/W時に新データを返す)
        data_read <= we ? data_write : data_mem[index];
    end

endmodule
