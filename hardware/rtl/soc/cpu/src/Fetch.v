// NISHIHARU

module Fetch(
    input wire              clock,
    input wire              reset_n,
    input wire              fetch_enb,
    input wire [31:0]       mem_read_data,
    output reg              program_mem_read_valid,
    input wire              program_mem_read_ready,
    input wire              program_mem_req_ready,
    // Threw sig.
    output wire             opcode_read_valid,
    output wire [31:0]      opcode_read_data,
    // PSC_RV32IS sig.
    output reg [31:0]       opcode
);

    // FETCH
    // state = FETCH & FETCH_W
    //assign program_mem_read_valid = fetch_enb;

    // Threw
    assign opcode_read_valid = program_mem_read_ready;
    assign opcode_read_data  = mem_read_data;

    always @(posedge clock or negedge reset_n) begin
        if(!reset_n) begin
            program_mem_read_valid <= 1'b0;
            opcode  <= 32'h0;
        end else begin
            // default
            program_mem_read_valid <= 1'b0;
            
            if (fetch_enb & program_mem_req_ready) begin
                program_mem_read_valid <= 1'b1;
            end
            if (program_mem_read_ready) begin
                opcode  <= mem_read_data;
            end
        end
    end

endmodule