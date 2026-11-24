`timescale 1ns/1ps

module rgbz_axi_master #(
    // Parameter
    parameter integer ADDR_WIDTH   = 32,
    parameter integer ID_WIDTH     = 1,
    parameter integer DATA_WIDTH   = 256

)(
    // CLK, RESET
    input  wire                         clock,
    input  wire                         reset_n,
    input  wire                         command, write_command,
    input  wire [31:0]                  command_addr,
    input  wire                         scanout_busy,
    output wire                         completed, failed,

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
    input  wire [1:0]                u_axi_rresp,
    input  wire                      u_axi_rlast,
    input  wire                      u_axi_rvalid,
    output wire                      u_axi_rready
);

    // One aligned 256-bit transfer at a time. Latch a command before asserting
    // VALID so a new display request cannot withdraw a stalled AXI transfer.
    localparam IDLE = 0, READ_ADDR = 1, READ_DATA = 2, WRITE = 3, WRITE_RESP = 4;
    reg [2:0] state;
    reg [ADDR_WIDTH-1:0] address;
    reg aw_pending, w_pending;
    assign completed = (state == READ_DATA && u_axi_rvalid) ||
                       (state == WRITE_RESP && u_axi_bvalid);
    assign failed = state == READ_DATA ? (u_axi_rresp != 0 || !u_axi_rlast)
                                       : (u_axi_bresp != 0);

    assign u_axi_awid = 0;
    assign u_axi_arid = 0;
    assign u_axi_awaddr = address;
    assign u_axi_araddr = address;
    assign u_axi_awlen = 0;
    assign u_axi_arlen = 0;
    assign u_axi_awsize = 5;
    assign u_axi_arsize = 5;
    assign u_axi_awburst = 2'b01;
    assign u_axi_arburst = 2'b01;
    assign u_axi_awvalid = aw_pending;
    assign u_axi_wvalid = w_pending;
    assign u_axi_wlast = 1'b1;
    assign u_axi_wstrb = {(DATA_WIDTH/8){1'b1}};
    assign u_axi_bready = state == WRITE_RESP;
    assign u_axi_arvalid = state == READ_ADDR;
    assign u_axi_rready = state == READ_DATA;

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            address <= 0;
            aw_pending <= 0;
            w_pending <= 0;
        end else case (state)
            IDLE: if (command && !scanout_busy) begin
                address <= command_addr;
                aw_pending <= write_command;
                w_pending <= write_command;
                state <= write_command ? WRITE : READ_ADDR;
            end
            READ_ADDR: if (u_axi_arready) state <= READ_DATA;
            READ_DATA: if (u_axi_rvalid) state <= IDLE;
            WRITE: begin
                if (u_axi_awready) aw_pending <= 0;
                if (u_axi_wready) w_pending <= 0;
                if ((!aw_pending || u_axi_awready) && (!w_pending || u_axi_wready))
                    state <= WRITE_RESP;
            end
            WRITE_RESP: if (u_axi_bvalid) state <= IDLE;
            default: state <= IDLE;
        endcase
    end
endmodule
