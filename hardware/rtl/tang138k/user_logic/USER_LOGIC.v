`timescale 1ns/1ps

module USER_LOGIC #(
    // Parameter
    parameter integer ADDR_WIDTH   = 32,
    parameter integer ID_WIDTH     = 1,
    parameter integer DATA_WIDTH   = 32     // AXI bus. fixed 32
    
)(
    // CLK, RESET
    input  wire                         clock,
    input  wire                         reset_n,

    // -------------------------------
    // 外部：Shared I/D 32bit AXI IF (u_axi_*)
    // -------------------------------
    // ===== AXI4 Master (16-bit) =====
    // Write Address
    output wire  [ID_WIDTH-1:0]      u_axi_awid,
    output wire  [ADDR_WIDTH-1:0]    u_axi_awaddr,
    output wire  [7:0]               u_axi_awlen,         // 7 (=8beat)
    output wire  [2:0]               u_axi_awsize,        // 1 (2B)
    output wire  [1:0]               u_axi_awburst,       // INCR=01
    output wire                      u_axi_awvalid,
    input  wire                      u_axi_awready,

    // Write Data
    output wire  [DATA_WIDTH-1:0]    u_axi_wdata,
    output wire  [(DATA_WIDTH/8)-1:0]u_axi_wstrb,         // 2'b11
    output wire                      u_axi_wlast,
    output wire                      u_axi_wvalid,
    input  wire                      u_axi_wready,

    // Write Response
    input  wire [ID_WIDTH-1:0]       u_axi_bid,
    input  wire [1:0]                u_axi_bresp,
    input  wire                      u_axi_bvalid,
    output wire                      u_axi_bready,

    // Read Address
    output wire  [ID_WIDTH-1:0]      u_axi_arid,
    output wire  [ADDR_WIDTH-1:0]    u_axi_araddr,
    output wire  [7:0]               u_axi_arlen,         // 7 (=8beat)
    output wire  [2:0]               u_axi_arsize,        // 1
    output wire  [1:0]               u_axi_arburst,       // INCR
    output wire                      u_axi_arvalid,
    input  wire                      u_axi_arready,

    // Read Data
    input  wire [ID_WIDTH-1:0]       u_axi_rid,
    input  wire [DATA_WIDTH-1:0]     u_axi_rdata,
    input  wire [1:0]                u_axi_rresp,
    input  wire                      u_axi_rlast,
    input  wire                      u_axi_rvalid,
    output wire                      u_axi_rready
);

    // Compatibility only: the former D-Cache AXI master is inactive.
    // No u_axi_* input participates in the shared bridge's control.
    assign u_axi_awid    = '0;
    assign u_axi_awaddr  = '0;
    assign u_axi_awlen   = '0;
    assign u_axi_awsize  = '0;
    assign u_axi_awburst = '0;
    assign u_axi_awvalid = '0;
    assign u_axi_wdata   = '0;
    assign u_axi_wstrb   = '0;
    assign u_axi_wlast   = '0;
    assign u_axi_wvalid  = '0;
    assign u_axi_bready  = '0;
    assign u_axi_arid    = '0;
    assign u_axi_araddr  = '0;
    assign u_axi_arlen   = '0;
    assign u_axi_arsize  = '0;
    assign u_axi_arburst = '0;
    assign u_axi_arvalid = '0;
    assign u_axi_rready  = '0;

endmodule