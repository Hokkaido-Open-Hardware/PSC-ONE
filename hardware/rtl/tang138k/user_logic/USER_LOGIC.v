`timescale 1ns/1ps

module USER_LOGIC #(
    // Parameter
    parameter integer ADDR_WIDTH   = 32,
    parameter integer ID_WIDTH     = 1,
    parameter integer DATA_WIDTH   = 256,
    parameter [31:0] VRAM_ADDRESS = 32'h0090_0000
    
)(
    // CLK, RESET
    input  wire                         clock,
    input  wire                         reset_n,
    input  wire                         start,
    input  wire                         scanout_busy,
    input  wire                         displayed_page,
    output wire                         requested_page,
    output wire [3:0]                   status,

    // -------------------------------
    // AXI4 master, 32 bytes per beat
    // Write Address
    output wire  [ID_WIDTH-1:0]      u_axi_awid,
    output wire  [ADDR_WIDTH-1:0]    u_axi_awaddr,
    output wire  [7:0]               u_axi_awlen,
    output wire  [2:0]               u_axi_awsize,
    output wire  [1:0]               u_axi_awburst,       // INCR=01
    output wire                      u_axi_awvalid,
    input  wire                      u_axi_awready,

    // Write Data
    output wire  [DATA_WIDTH-1:0]    u_axi_wdata,
    output wire  [(DATA_WIDTH/8)-1:0]u_axi_wstrb,
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
    output wire  [7:0]               u_axi_arlen,
    output wire  [2:0]               u_axi_arsize,
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

    wire command, write_command, completed, failed;
    wire [31:0] command_addr;

    rgbz_to_vram #(.VRAM_ADDRESS(VRAM_ADDRESS)) converter (
        .clock(clock), .reset_n(reset_n), .start(start),
        .displayed_page(displayed_page), .requested_page(requested_page),
        .status(status), .command(command), .write_command(write_command),
        .address(command_addr), .write_data(u_axi_wdata),
        .completed(completed), .failed(failed), .read_data(u_axi_rdata)
    );

    rgbz_axi_master #(
        .ADDR_WIDTH(ADDR_WIDTH), .ID_WIDTH(ID_WIDTH), .DATA_WIDTH(DATA_WIDTH)
    ) master (
        .clock(clock), .reset_n(reset_n), .scanout_busy(scanout_busy),
        .command(command), .write_command(write_command), .command_addr(command_addr),
        .completed(completed), .failed(failed),
        .u_axi_awid(u_axi_awid),
        .u_axi_awaddr(u_axi_awaddr),
        .u_axi_awlen(u_axi_awlen),
        .u_axi_awsize(u_axi_awsize),
        .u_axi_awburst(u_axi_awburst),
        .u_axi_awvalid(u_axi_awvalid),
        .u_axi_awready(u_axi_awready),
        .u_axi_wstrb(u_axi_wstrb),
        .u_axi_wlast(u_axi_wlast),
        .u_axi_wvalid(u_axi_wvalid),
        .u_axi_wready(u_axi_wready),
        .u_axi_bid(u_axi_bid),
        .u_axi_bresp(u_axi_bresp),
        .u_axi_bvalid(u_axi_bvalid),
        .u_axi_bready(u_axi_bready),
        .u_axi_arid(u_axi_arid),
        .u_axi_araddr(u_axi_araddr),
        .u_axi_arlen(u_axi_arlen),
        .u_axi_arsize(u_axi_arsize),
        .u_axi_arburst(u_axi_arburst),
        .u_axi_arvalid(u_axi_arvalid),
        .u_axi_arready(u_axi_arready),
        .u_axi_rid(u_axi_rid),
        .u_axi_rresp(u_axi_rresp),
        .u_axi_rlast(u_axi_rlast),
        .u_axi_rvalid(u_axi_rvalid),
        .u_axi_rready(u_axi_rready)
    );
endmodule
