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
            reg_data_1 <= 32'd0;
            reg_data_2 <= 32'd0;
            for (i = 0; i < 32; i++)
                registers[i] <= 32'd0;
                
        end else begin
            // WB
            if (register_wenb && rf_wen && (w_addr != 5'd0))
                registers[w_addr] <= w_data;

            // ID＋WB→ID forwarding
            reg_data_1 <=
                (r_addr1 == 5'd0) ? 32'd0 :
                (register_wenb && rf_wen &&
                (w_addr != 5'd0) &&
                (w_addr == r_addr1)) ? w_data :
                registers[r_addr1];

            reg_data_2 <=
                (r_addr2 == 5'd0) ? 32'd0 :
                (register_wenb && rf_wen &&
                (w_addr != 5'd0) &&
                (w_addr == r_addr2)) ? w_data :
                registers[r_addr2];
        end
    end

endmodule