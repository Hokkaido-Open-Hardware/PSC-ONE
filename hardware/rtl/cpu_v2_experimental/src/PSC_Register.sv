// NISHIHARU

module PSC_Register #(
    parameter int THREADS_NUM = 1
)(
    input  logic        clock,
    input  logic        reset_n,
    input  logic        register_wenb,
    input  logic        rf_wen,
    input  logic [4:0]  w_addr,
    input  logic [31:0] w_data,
    input  logic [4:0]  r_addr1,
    input  logic [4:0]  r_addr2,

    output logic [31:0] reg_data_1,
    output logic [31:0] reg_data_2
);

    // 32-bit × 32 general-purpose registers
    logic [31:0] registers [0:31];

    integer i;

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            for (i = 0; i < 32; i++)
                registers[i] <= 32'd0;
                
        end else begin
            // WB
            if (register_wenb && rf_wen && (w_addr != 5'd0))
                registers[w_addr] <= w_data;
        end
    end

    // Combinational read ports let the v2 issue stage consume the current
    // FIFO head without adding a register-read bubble.  A same-cycle commit
    // dependency is interlocked in PSC_InstructionUnit; keeping that bypass
    // out of the register file prevents commit write data from feeding the
    // issue operand path combinationally.
    always_comb begin
        reg_data_1 = (r_addr1 == 5'd0) ? 32'd0 : registers[r_addr1];
        reg_data_2 = (r_addr2 == 5'd0) ? 32'd0 : registers[r_addr2];
    end

endmodule
