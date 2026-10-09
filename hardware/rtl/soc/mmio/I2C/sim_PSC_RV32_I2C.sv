`timescale 1ns / 1ps

// Standalone I2C test wrapper for cocotb + Verilator.
// master_sda_low=1 drives SDA low; 0 releases SDA (pulled high).
// No Verilog 'z' needs to cross the Verilator / cocotb boundary.
module sim_PSC_RV32_I2C (
    input  wire        clock,
    input  wire        reset_n,
    input  wire        scl_master,
    input  wire        master_sda_low,
    output wire        sda_bus,
    output wire        slave_sda_low,

    input  wire        cpu_wvalid,
    input  wire [31:0] cpu_waddr,
    input  wire [31:0] cpu_wdata,
    output wire        cpu_wready,
    input  wire        cpu_rvalid,
    input  wire [31:0] cpu_raddr,
    output wire [31:0] cpu_rdata,
    output wire        cpu_rready,
    output wire        irq_rx
);

    // Open drain, wired-AND and pull-up model:
    // either driver low => 0, otherwise pulled to 1.
    assign sda_bus = ~(master_sda_low | slave_sda_low);

    PSC_RV32_I2C #(
        .ADDR_WIDTH       (32),
        .SLAVE_ADDRESS    (7'h42),
        .I2C_BASE         (32'h1000_2000),
        .I2C_ADDR_INPUT   (32'h1000_2000),
        .I2C_ADDR_STATUS  (32'h1000_2004),
        .I2C_ADDR_OUTPUT  (32'h1000_2008),
        .I2C_ADDR_CONTROL (32'h1000_200C),
        .I2C_ADDR_SEQ     (32'h1000_2010)
    ) dut (
        .clock         (clock),
        .reset_n       (reset_n),
        .scl_i         (scl_master),
        .sda_i         (sda_bus),
        .sda_drive_low (slave_sda_low),
        .cpu_wvalid    (cpu_wvalid),
        .cpu_waddr     (cpu_waddr),
        .cpu_wdata     (cpu_wdata),
        .cpu_wready    (cpu_wready),
        .cpu_rvalid    (cpu_rvalid),
        .cpu_raddr     (cpu_raddr),
        .cpu_rdata     (cpu_rdata),
        .cpu_rready    (cpu_rready),
        .irq_rx        (irq_rx)
    );
endmodule
