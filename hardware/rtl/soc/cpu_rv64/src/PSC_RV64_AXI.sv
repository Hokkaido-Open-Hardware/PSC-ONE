`timescale 1ns/1ps
// Uncached RV64 memory-to-AXI bridge. Separate I/D request slots preserve
// simultaneous request pulses. One external transaction is outstanding.
// Program bursts are four 64-bit INCR beats; data transfers are single beats.
module PSC_RV64_AXI #(
    parameter integer ID_WIDTH = 1
)(
    input logic clock, reset_n,
    input logic i_valid, i_burst,
    input logic [63:0] i_addr,
    output logic i_req_ready, i_ready,
    output logic [63:0] i_data,
    input logic d_rvalid, d_wvalid,
    input logic [63:0] d_raddr, d_waddr, d_wdata,
    input logic [2:0] d_sel,
    input logic d_is_mmio,
    output logic d_req_ready, d_rready, d_wready,
    output logic [63:0] d_rdata,
    output logic mmio_valid, mmio_rw,
    output logic [63:0] mmio_addr, mmio_wdata,
    input logic [63:0] mmio_rdata,
    input logic mmio_ready,
    output logic fault,
    output logic [ID_WIDTH-1:0] axi_awid,
    output logic [63:0] axi_awaddr,
    output logic [7:0] axi_awlen,
    output logic [2:0] axi_awsize,
    output logic [1:0] axi_awburst,
    output logic axi_awvalid,
    input logic axi_awready,
    output logic [63:0] axi_wdata,
    output logic [7:0] axi_wstrb,
    output logic axi_wlast, axi_wvalid,
    input logic axi_wready,
    input logic [ID_WIDTH-1:0] axi_bid,
    input logic [1:0] axi_bresp,
    input logic axi_bvalid,
    output logic axi_bready,
    output logic [ID_WIDTH-1:0] axi_arid,
    output logic [63:0] axi_araddr,
    output logic [7:0] axi_arlen,
    output logic [2:0] axi_arsize,
    output logic [1:0] axi_arburst,
    output logic axi_arvalid,
    input logic axi_arready,
    input logic [ID_WIDTH-1:0] axi_rid,
    input logic [63:0] axi_rdata,
    input logic [1:0] axi_rresp,
    input logic axi_rlast, axi_rvalid,
    output logic axi_rready
);
    typedef enum logic [2:0] {IDLE, READ_ADDR, READ_DATA, WRITE_CHANNELS,
                             WRITE_RESPONSE, MMIO, ERROR} state_t;
    state_t state;
    logic ipending, dpending, iburst_q, dwrite_q, dmmio_q;
    logic [63:0] iaddr_q, daddr_q, ddata_q;
    logic [2:0] dsel_q;
    logic owner_i, aw_sent, w_sent;
    logic [1:0] beats_left;
    logic [8:0] byte_mask;

    assign i_req_ready = !ipending && !fault;
    assign d_req_ready = !dpending && !fault;
    assign axi_awid = '0;
    assign axi_arid = '0;
    assign axi_awaddr = daddr_q;
    assign axi_awlen = 0;
    assign axi_awsize = dsel_q;
    assign axi_awburst = 2'b01;
    assign axi_awvalid = state == WRITE_CHANNELS && !aw_sent;
    assign axi_wdata = ddata_q << {daddr_q[2:0], 3'b0};
    assign byte_mask = (9'b1 << (4'b1 << dsel_q)) - 9'b1;
    assign axi_wstrb = byte_mask[7:0] << daddr_q[2:0];
    assign axi_wlast = 1'b1;
    assign axi_wvalid = state == WRITE_CHANNELS && !w_sent;
    assign axi_bready = state == WRITE_RESPONSE;
    assign axi_araddr = owner_i ? iaddr_q : {daddr_q[63:3], 3'b0};
    assign axi_arlen = owner_i && iburst_q ? 8'd3 : 8'd0;
    assign axi_arsize = 3'd3;
    assign axi_arburst = 2'b01;
    assign axi_arvalid = state == READ_ADDR;
    assign axi_rready = state == READ_DATA;
    assign mmio_valid = state == MMIO;
    assign mmio_rw = dwrite_q;
    assign mmio_addr = daddr_q;
    assign mmio_wdata = ddata_q;

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE; ipending <= 0; dpending <= 0;
            iburst_q <= 0; dwrite_q <= 0; dmmio_q <= 0;
            iaddr_q <= 0; daddr_q <= 0; ddata_q <= 0; dsel_q <= 0;
            owner_i <= 0; aw_sent <= 0; w_sent <= 0; beats_left <= 0;
            i_ready <= 0; d_rready <= 0; d_wready <= 0;
            i_data <= 0; d_rdata <= 0; fault <= 0;
        end else begin
            i_ready <= 0; d_rready <= 0; d_wready <= 0;
            if (i_valid && i_req_ready) begin
                ipending <= 1;
                iaddr_q <= i_addr;
                iburst_q <= i_burst;
            end
            if ((d_rvalid || d_wvalid) && d_req_ready) begin
                dpending <= 1;
                daddr_q <= d_wvalid ? d_waddr : d_raddr;
                ddata_q <= d_wdata; dsel_q <= d_sel;
                dwrite_q <= d_wvalid; dmmio_q <= d_is_mmio;
            end
            case (state)
                IDLE: begin
                    if (dpending) begin
                        owner_i <= 0; beats_left <= 0;
                        aw_sent <= 0; w_sent <= 0;
                        if (dmmio_q) state <= MMIO;
                        else if (dwrite_q) state <= WRITE_CHANNELS;
                        else state <= READ_ADDR;
                    end else if (ipending) begin
                        owner_i <= 1;
                        beats_left <= iburst_q ? 2'd3 : 2'd0;
                        state <= READ_ADDR;
                    end
                end
                READ_ADDR: if (axi_arready) state <= READ_DATA;
                READ_DATA: if (axi_rvalid) begin
                    if (axi_rresp != 0 || axi_rid != 0 ||
                        axi_rlast != (beats_left == 0)) begin
                        fault <= 1;
                        state <= ERROR;
                    end else begin
                        if (owner_i) begin i_data <= axi_rdata; i_ready <= 1; end
                        else begin d_rdata <= axi_rdata; d_rready <= 1; end
                        if (beats_left == 0) begin
                            if (owner_i) ipending <= 0;
                            else dpending <= 0;
                            state <= IDLE;
                        end else beats_left <= beats_left - 1'b1;
                    end
                end
                WRITE_CHANNELS: begin
                    if (axi_awready) aw_sent <= 1;
                    if (axi_wready) w_sent <= 1;
                    if ((aw_sent || axi_awready) && (w_sent || axi_wready))
                        state <= WRITE_RESPONSE;
                end
                WRITE_RESPONSE: if (axi_bvalid) begin
                    if (axi_bresp != 0 || axi_bid != 0) begin
                        fault <= 1;
                        state <= ERROR;
                    end else begin
                        d_wready <= 1; dpending <= 0; state <= IDLE;
                    end
                end
                MMIO: if (mmio_ready) begin
                    // MMIO responder uses the same aligned 64-bit read lanes.
                    d_rdata <= mmio_rdata;
                    d_rready <= !dwrite_q;
                    d_wready <= dwrite_q;
                    dpending <= 0; state <= IDLE;
                end
                ERROR: ; // sticky halt; reset required (no access-fault port on core yet)
                default: state <= IDLE;
            endcase
        end
    end
endmodule
