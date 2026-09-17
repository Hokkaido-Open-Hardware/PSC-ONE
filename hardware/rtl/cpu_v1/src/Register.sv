// NISHIHARU

module Register (
    input  logic        clock,
    input  logic        reset_n,
    input  logic        store_enb,
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
            for (i = 0; i < 32; i++) begin
                registers[i] <= 32'd0;
            end

            reg_data_1 <= 32'd0;
            reg_data_2 <= 32'd0;
        end else begin
            if (store_enb) begin
                if (rf_wen && (w_addr != 5'd0)) begin
                    registers[w_addr] <= w_data;
                end
            end else begin
                reg_data_1 <= (r_addr1 == 5'd0)
                            ? 32'd0
                            : registers[r_addr1];

                reg_data_2 <= (r_addr2 == 5'd0)
                            ? 32'd0
                            : registers[r_addr2];
            end
        end
    end

`ifdef COCOTB_SIM
    // Debug signals for GTKWave
    logic [31:0] reg_0;
    logic [31:0] reg_1;
    logic [31:0] reg_2;
    logic [31:0] reg_3;
    logic [31:0] reg_10;
    logic [31:0] reg_11;
    logic [31:0] reg_12;
    logic [31:0] reg_13;
    logic [31:0] reg_14;
    logic [31:0] reg_15;

    always_comb begin
        reg_0  = registers[0];
        reg_1  = registers[1];
        reg_2  = registers[2];
        reg_3  = registers[3];
        reg_10 = registers[10];
        reg_11 = registers[11];
        reg_12 = registers[12];
        reg_13 = registers[13];
        reg_14 = registers[14];
        reg_15 = registers[15];
    end
`endif

endmodule