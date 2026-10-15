`timescale 1ns/1ps
// NISHIHARU

module PSC_Register #(
    parameter int THREADS_NUM = 1
)(
    input  logic        clock,
    input  logic        reset_n,
    input  logic        register_wenb,
    input  logic        rf_wen,
    input  logic [4:0]  w_addr,
    input  logic [63:0] w_data,
    input  logic [4:0]  r_addr1,
    input  logic [4:0]  r_addr2,

    output logic [63:0] reg_data_1,
    output logic [63:0] reg_data_2
);

    // Two synchronous read ports map to replicated BSRAM banks. Do not
    // reset the array: a small validity bitmap preserves reset-to-zero,
    // including warm reset, without turning the storage into flip-flops.
    (* ram_style = "block" *) logic [63:0] registers [0:31];
    logic [31:1] initialized;
    logic [63:0] read_1, read_2;
    logic zero_1, zero_2, bypass_1, bypass_2;
    logic [63:0] write_data_q;
    wire write_enable = reset_n && register_wenb && rf_wen && (w_addr != 0);

    always_ff @(posedge clock) begin
        if (write_enable)
            registers[w_addr] <= w_data;
        read_1 <= registers[r_addr1];
        read_2 <= registers[r_addr2];
        // Explicit write-first bypass; never depend on BSRAM collision mode.
        bypass_1 <= write_enable && (w_addr == r_addr1);
        bypass_2 <= write_enable && (w_addr == r_addr2);
        write_data_q <= w_data;
        zero_1 <= (r_addr1 == 0) || !initialized[r_addr1];
        zero_2 <= (r_addr2 == 0) || !initialized[r_addr2];
    end

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            initialized <= '0;
        else if (write_enable)
            initialized[w_addr] <= 1'b1;
    end

    assign reg_data_1 = !reset_n ? 64'b0 : bypass_1 ? write_data_q :
                        zero_1 ? 64'b0 : read_1;
    assign reg_data_2 = !reset_n ? 64'b0 : bypass_2 ? write_data_q :
                        zero_2 ? 64'b0 : read_2;

endmodule
