// Functional model of the 1:4, x32, fixed-BL8 user port.
// The SoC maps a 24-bit byte address window (16 MiB).
`timescale 1ns/1ps
module ddr3_app_model (
    input  wire         clk,
    input  wire         rst_n,
    output reg          init_calib_complete,
    output wire         cmd_ready,
    input  wire         cmd_en,
    input  wire [2:0]   cmd,
    input  wire [28:0]  addr,
    output wire         wr_data_rdy,
    input  wire         wr_data_en,
    input  wire         wr_data_end,
    input  wire [255:0] wr_data,
    input  wire [31:0]  wr_data_mask,
    output reg  [255:0] rd_data,
    output reg          rd_data_valid
);
    reg [255:0] mem [0:(1<<19)-1];
    reg [2:0] cycle;
    assign cmd_ready = init_calib_complete && cycle != 0;
    assign wr_data_rdy = init_calib_complete && cycle != 3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle <= 0;
            init_calib_complete <= 0;
            rd_data_valid <= 0;
        end else begin
            cycle <= cycle + 1'b1;
            if (&cycle) init_calib_complete <= 1;
            rd_data_valid <= 0;
            if (cmd_en && cmd_ready) begin
                if (addr[2:0] != 0 || addr[28:22] != 0)
                    $fatal(1, "DDR3 address outside aligned 16 MiB window: %h", addr);
                case (cmd)
                    3'b000: begin
                        if (!(wr_data_en && wr_data_end && wr_data_rdy))
                            $fatal(1, "DDR3 bridge write without data");
                        for (integer i=0; i<32; i=i+1)
                            if (!wr_data_mask[i])
                                mem[addr[21:3]][i*8 +: 8] <= wr_data[i*8 +: 8];
                    end
                    3'b001: begin
                        rd_data <= mem[addr[21:3]];
                        rd_data_valid <= 1;
                    end
                    default: $fatal(1, "Unsupported DDR3 command %h", cmd);
                endcase
            end
        end
    end
endmodule
