module Fetch_Fifo #(
    parameter WIDTH = 32,
    parameter DEPTH = 4,
    parameter ADDR_BITS = $clog2(DEPTH)
)(
    input  wire              clock,
    input  wire              reset_n,

    // push side (from memory)
    input  wire              in_valid,
    input  wire [WIDTH-1:0]  in_data,
    input  wire [WIDTH-1:0]  in_pc_data,
    output wire              in_ready,

    // pop side (to CPU)
    output wire              out_req_ready,     // !enmpy: READ対応
    input  wire              out_valid,
    output reg               out_ready,
    output reg [WIDTH-1:0]   out_data,
    output reg [WIDTH-1:0]   out_pc_data,

    // fifo state
    output wire              full,
    output wire              empty,

    // flush (branch/jump)
    input  wire              flush
);

    // =====================================
    // FIFO memory
    // =====================================
    (* syn_keep = 1 *) reg [WIDTH-1:0] mem [0:DEPTH-1];
    (* syn_keep = 1 *) reg [WIDTH-1:0] pc_mem [0:DEPTH-1];

    reg [ADDR_BITS-1:0] wptr;
    reg [ADDR_BITS-1:0] rptr;
    reg [ADDR_BITS:0]   count;   // 0〜DEPTH

    // =====================================
    // status
    // =====================================
    assign full  = (count == DEPTH);
    assign empty = (count == 0);

    assign in_ready  = !full;
    assign out_req_ready = !empty;

    // =====================================
    // push / pop condition
    // =====================================
    wire push = in_valid  && in_ready;
    wire pop  = out_req_ready && out_valid;

    localparam PTR_W = $clog2(DEPTH);

    integer i;

    // =====================================
    // sequential logic
    // =====================================
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            wptr  <= 0;
            rptr  <= 0;
            count <= 0;
            out_data <= 0;
            out_pc_data <= 0;
            out_ready <= 0;
            for (i=0; i<DEPTH; i++) mem[i] <= 0;
            for (i=0; i<DEPTH; i++) pc_mem[i] <= 0;
        end
        else if (flush) begin
            wptr  <= 0;
            rptr  <= 0;
            count <= 0;
            for (i=0; i<DEPTH; i++) mem[i] <= 0;
            for (i=0; i<DEPTH; i++) pc_mem[i] <= 0;
        end
        else begin
            out_ready <= 1'b0;

            case ({push, pop})
                2'b10: begin
                    mem[wptr]    <= in_data;
                    pc_mem[wptr] <= in_pc_data;
                    wptr  <= (wptr == PTR_W'(DEPTH-1)) ? PTR_W'(0) : (wptr + PTR_W'(1));
                    count <= count + 1'b1;
                end

                2'b01: begin
                    rptr  <= (rptr == PTR_W'(DEPTH-1)) ? PTR_W'(0) : (rptr + PTR_W'(1));
                    count <= count - 1'b1;
                    out_data    <= mem[rptr];
                    out_pc_data <= pc_mem[rptr];
                    out_ready   <= 1'b1;
                end

                2'b11: begin
                    mem[wptr]    <= in_data;
                    pc_mem[wptr] <= in_pc_data;

                    wptr <= (wptr == PTR_W'(DEPTH-1)) ? PTR_W'(0) : (wptr + PTR_W'(1));
                    rptr <= (rptr == PTR_W'(DEPTH-1)) ? PTR_W'(0) : (rptr + PTR_W'(1));

                    out_data    <= mem[rptr];
                    out_pc_data <= pc_mem[rptr];
                    out_ready   <= 1'b1;
                end
                default: begin
                end
            endcase
        end
    end

    // debug
    wire [WIDTH-1:0] mem_0 = mem[0];
    wire [WIDTH-1:0] mem_1 = mem[1];
    wire [WIDTH-1:0] mem_2 = mem[2];
    wire [WIDTH-1:0] mem_3 = mem[3];

endmodule