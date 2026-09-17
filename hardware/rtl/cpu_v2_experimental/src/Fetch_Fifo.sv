// NISHIHARU

module Fetch_Fifo #(
    parameter int WIDTH     = 32,
    parameter int DEPTH     = 8,
    parameter int ADDR_BITS = $clog2(DEPTH)
)(
    input  logic               clock,
    input  logic               reset_n,

    // Push side
    input  logic               in_valid,
    input  logic [WIDTH-1:0]   in_data,
    input  logic [WIDTH-1:0]   in_pc_data,
    output logic               in_ready,

    // Pop side
    output logic               out_req_ready,
    input  logic               out_valid,
    output logic               out_ready,
    output logic [WIDTH-1:0]   out_data,
    output logic [WIDTH-1:0]   out_pc_data,

    output logic               full,
    output logic               empty,
    output logic [ADDR_BITS:0] count,
    input  logic               flush
);

    // Reset/flush invalidate entries through count; never clear the RAM array.
    (* ram_style = "block", syn_ramstyle = "block_ram" *)
    logic [WIDTH-1:0] mem [0:DEPTH-1];
    (* ram_style = "block", syn_ramstyle = "block_ram" *)
    logic [WIDTH-1:0] pc_mem [0:DEPTH-1];

    logic [ADDR_BITS-1:0] wptr, rptr;
    logic [ADDR_BITS-1:0] rptr_next, read_addr;
    logic [WIDTH-1:0] ram_data, ram_pc_data;
    logic [WIDTH-1:0] bypass_data, bypass_pc_data;
    logic bypass;
    logic push, pop;

    assign full          = (count == DEPTH);
    assign empty         = (count == 0);
    assign in_ready      = !full;
    assign out_req_ready = !empty;
    assign push          = in_valid && in_ready;
    assign pop           = out_valid && out_req_ready;

    assign rptr_next = (rptr == ADDR_BITS'(DEPTH-1)) ? '0 : rptr + 1'b1;
    // Read the head for the NEXT cycle, so a pop exposes its successor
    // without a bubble. The RAM read registers must not have an async reset.
    assign read_addr = pop ? rptr_next : rptr;
    always_ff @(posedge clock) begin
        if (reset_n && !flush && push) begin
            mem[wptr]    <= in_data;
            pc_mem[wptr] <= in_pc_data;
        end
        ram_data    <= mem[read_addr];
        ram_pc_data <= pc_mem[read_addr];
        bypass_data    <= in_data;
        bypass_pc_data <= in_pc_data;
    end

    // Empty->push and one-entry push+pop read the address being written.
    // Forward that write explicitly, independent of the SRAM collision mode.
    // On the following clock the normal RAM read has caught up, even if stalled.
    assign out_data    = empty ? '0 : (bypass ? bypass_data : ram_data);
    assign out_pc_data = empty ? '0 : (bypass ? bypass_pc_data : ram_pc_data);
    assign out_ready   = pop;

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            wptr        <= '0;
            rptr        <= '0;
            count       <= '0;
            bypass      <= 1'b0;
        end else if (flush) begin
            wptr      <= '0;
            rptr      <= '0;
            count     <= '0;
            bypass    <= 1'b0;
        end else begin
            bypass <= push && (wptr == read_addr);
            case ({push, pop})
                2'b10: begin
                    wptr         <= (wptr == ADDR_BITS'(DEPTH-1)) ? '0 : wptr + 1'b1;
                    count        <= count + 1'b1;
                end

                2'b01: begin
                    rptr        <= rptr_next;
                    count       <= count - 1'b1;
                end

                2'b11: begin
                    wptr         <= (wptr == ADDR_BITS'(DEPTH-1)) ? '0 : wptr + 1'b1;
                    rptr         <= rptr_next;
                end

                default: ;
            endcase
        end
    end

`ifdef COCOTB_SIM
    logic [WIDTH-1:0] mem_0, mem_1, mem_2, mem_3;
    logic [WIDTH-1:0] mem_4, mem_5, mem_6, mem_7;
    assign mem_0 = mem[0];
    assign mem_1 = mem[1];
    assign mem_2 = mem[2];
    assign mem_3 = mem[3];
    assign mem_4 = mem[4];
    assign mem_5 = mem[5];
    assign mem_6 = mem[6];
    assign mem_7 = mem[7];
`endif

endmodule
