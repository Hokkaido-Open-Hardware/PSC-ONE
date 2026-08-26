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

    (* syn_keep = 1 *) logic [WIDTH-1:0] mem    [0:DEPTH-1];
    (* syn_keep = 1 *) logic [WIDTH-1:0] pc_mem [0:DEPTH-1];

    logic [ADDR_BITS-1:0] wptr, rptr;
    logic push, pop;
    integer i;

    assign full          = (count == DEPTH);
    assign empty         = (count == 0);
    assign in_ready      = !full;
    assign out_req_ready = !empty;
    assign push          = in_valid && in_ready;
    assign pop           = out_valid && out_req_ready;

    // First-word fall-through output.  The instruction at the head of the
    // FIFO is visible before it is popped, allowing decode and dispatch to
    // accept one instruction on every clock.
    always_comb begin
        out_data    = mem[rptr];
        out_pc_data = pc_mem[rptr];
        out_ready   = pop;
    end

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            wptr        <= '0;
            rptr        <= '0;
            count       <= '0;
            for (i = 0; i < DEPTH; i++) begin
                mem[i]    <= '0;
                pc_mem[i] <= '0;
            end
        end else if (flush) begin
            wptr      <= '0;
            rptr      <= '0;
            count     <= '0;
            for (i = 0; i < DEPTH; i++) begin
                mem[i]    <= '0;
                pc_mem[i] <= '0;
            end
        end else begin
            case ({push, pop})
                2'b10: begin
                    mem[wptr]    <= in_data;
                    pc_mem[wptr] <= in_pc_data;
                    wptr         <= (wptr == ADDR_BITS'(DEPTH-1)) ? '0 : wptr + 1'b1;
                    count        <= count + 1'b1;
                end

                2'b01: begin
                    rptr        <= (rptr == ADDR_BITS'(DEPTH-1)) ? '0 : rptr + 1'b1;
                    count       <= count - 1'b1;
                end

                2'b11: begin
                    mem[wptr]    <= in_data;
                    pc_mem[wptr] <= in_pc_data;
                    wptr         <= (wptr == ADDR_BITS'(DEPTH-1)) ? '0 : wptr + 1'b1;
                    rptr         <= (rptr == ADDR_BITS'(DEPTH-1)) ? '0 : rptr + 1'b1;
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
