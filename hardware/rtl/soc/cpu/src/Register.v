// NISHIHARU

module Register(
    input wire              clock,
    input wire              reset_n,
    input wire              store_enb,
    input wire              rf_wen,
    input wire [4:0]        w_addr,
    input wire [31:0]       w_data,
    input wire [4:0]        r_addr1,
    input wire [4:0]        r_addr2,
    // output
    output reg [31:0]       reg_data_1,
    output reg [31:0]       reg_data_2
);

    // Register 32bit x 32
    reg [31:0] registers[0:31];

    integer i;
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'h0;
            end
            reg_data_1 <= 32'd0;
            reg_data_2 <= 32'd0;
        end else begin
            if(store_enb) begin
                if ((rf_wen == 1'b1) && (w_addr != 5'b00000))
                    registers[w_addr] <= w_data;
            end else begin
                reg_data_1 <= (r_addr1 == 5'b00000) ? 32'b0 : registers[r_addr1];
                reg_data_2 <= (r_addr2 == 5'b00000) ? 32'b0 : registers[r_addr2];
            end
        end
    end

    `ifdef COCOTB_SIM
    // debug for gtkwave
    wire [31:0] reg_0  = registers[0];
    wire [31:0] reg_1  = registers[1];
    wire [31:0] reg_2  = registers[2];
    wire [31:0] reg_3  = registers[3];
    wire [31:0] reg_10 = registers[10];
    wire [31:0] reg_11 = registers[11];
    wire [31:0] reg_12 = registers[12];
    wire [31:0] reg_13 = registers[13];
    wire [31:0] reg_14 = registers[14];
    wire [31:0] reg_15 = registers[15];
    `endif


endmodule