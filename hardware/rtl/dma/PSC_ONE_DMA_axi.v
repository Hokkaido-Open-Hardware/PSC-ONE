// NISHIHARU
`timescale 1ns/1ps

module PSC_ONE_DMA_axi #(
    parameter integer ADDR_WIDTH     = 32,
    parameter integer ID_WIDTH       = 1,
    parameter integer DATA_WIDTH     = 32                   // fixed 32. tang 20k.
)(
    input  wire                     clock,
    input  wire                     reset_n,

    // DMA controll
    input  wire                     dma_start,
    output reg                      dma_busy,
    output reg                      dma_done,

    // SDRAM base address
    input  wire [31:0]              DMA_WORDS,
    input  wire [31:0]              BASE_ADDR_READ,
    input  wire [31:0]              BASE_ADDR_WRITE,

    // ===== AXI4 Master (16-bit) : DMA Read Write =====
    // Write Address
    output reg  [ID_WIDTH-1:0]      dma_axi_awid,
    output reg  [ADDR_WIDTH-1:0]    dma_axi_awaddr,
    output reg  [7:0]               dma_axi_awlen,         // 0 (=1beat)
    output reg  [2:0]               dma_axi_awsize,        // 1 (2B)
    output reg  [1:0]               dma_axi_awburst,       // INCR=01
    output reg                      dma_axi_awvalid,
    input  wire                     dma_axi_awready,

    // Write Data
    output reg  [DATA_WIDTH-1:0]    dma_axi_wdata,
    output reg  [(DATA_WIDTH/8)-1:0]dma_axi_wstrb,         // 2'b11
    output reg                      dma_axi_wlast,
    output reg                      dma_axi_wvalid,
    input  wire                     dma_axi_wready,

    // Write Response
    input  wire [ID_WIDTH-1:0]      dma_axi_bid,
    input  wire [1:0]               dma_axi_bresp,
    input  wire                     dma_axi_bvalid,
    output reg                      dma_axi_bready,

    // Read Address
    output reg  [ID_WIDTH-1:0]      dma_axi_arid,
    output reg  [ADDR_WIDTH-1:0]    dma_axi_araddr,
    output reg  [7:0]               dma_axi_arlen,
    output reg  [2:0]               dma_axi_arsize,
    output reg  [1:0]               dma_axi_arburst,
    output reg                      dma_axi_arvalid,
    input  wire                     dma_axi_arready,

    input  wire [ID_WIDTH-1:0]      dma_axi_rid,
    input  wire [DATA_WIDTH-1:0]    dma_axi_rdata,
    input  wire [1:0]               dma_axi_rresp,
    input  wire                     dma_axi_rlast,
    input  wire                     dma_axi_rvalid,
    output reg                      dma_axi_rready
);

    localparam [3:0]
        ST_IDLE = 4'd0,
        ST_AR   = 4'd1,
        ST_R    = 4'd2,
        ST_AW   = 4'd3,
        ST_W    = 4'd4,
        ST_B    = 4'd5,
        ST_DONE = 4'd6;

    reg [3:0]  st;
    reg [31:0] word_count;
    reg [31:0] dma_buf;

    wire ar_fire = dma_axi_arvalid & dma_axi_arready;
    wire r_fire  = dma_axi_rvalid  & dma_axi_rready;
    wire aw_fire = dma_axi_awvalid & dma_axi_awready;
    wire w_fire  = dma_axi_wvalid  & dma_axi_wready;
    wire b_fire  = dma_axi_bvalid  & dma_axi_bready;

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            st <= ST_IDLE;
            word_count <= 32'd0;
            dma_buf <= 32'd0;
            dma_busy <= 1'b0;
            dma_done <= 1'b0;

            dma_axi_awid    <= {ID_WIDTH{1'b0}};
            dma_axi_awaddr  <= {ADDR_WIDTH{1'b0}};
            dma_axi_awlen   <= 8'd0;
            dma_axi_awsize  <= 3'd2;      // 32bit = 4byte
            dma_axi_awburst <= 2'b01;
            dma_axi_awvalid <= 1'b0;

            dma_axi_wdata   <= {DATA_WIDTH{1'b0}};
            dma_axi_wstrb   <= {(DATA_WIDTH/8){1'b1}};
            dma_axi_wlast   <= 1'b0;
            dma_axi_wvalid  <= 1'b0;

            dma_axi_bready  <= 1'b0;

            dma_axi_arid    <= {ID_WIDTH{1'b0}};
            dma_axi_araddr  <= {ADDR_WIDTH{1'b0}};
            dma_axi_arlen   <= 8'd0;
            dma_axi_arsize  <= 3'd2;      // 32bit = 4byte
            dma_axi_arburst <= 2'b01;
            dma_axi_arvalid <= 1'b0;

            dma_axi_rready  <= 1'b0;
        end else begin
            dma_axi_wstrb <= {(DATA_WIDTH/8){1'b1}};

            case (st)
                ST_IDLE: begin
                    dma_busy <= 1'b0;
                    dma_done <= 1'b0;

                    dma_axi_awvalid <= 1'b0;
                    dma_axi_wvalid  <= 1'b0;
                    dma_axi_wlast   <= 1'b0;
                    dma_axi_bready  <= 1'b0;
                    dma_axi_arvalid <= 1'b0;
                    dma_axi_rready  <= 1'b0;

                    if (dma_start) begin
                        word_count <= 32'd0;
                        dma_busy   <= 1'b1;
                        st <= ST_AR;
                    end
                end

                ST_AR: begin
                    dma_axi_arid    <= {ID_WIDTH{1'b0}};
                    dma_axi_araddr  <= BASE_ADDR_READ + (word_count << 2);
                    dma_axi_arlen   <= 8'd0;      // 1 beat
                    dma_axi_arsize  <= 3'd2;      // 4 byte
                    dma_axi_arburst <= 2'b01;     // INCR
                    dma_axi_arvalid <= 1'b1;

                    if (ar_fire) begin
                        dma_axi_arvalid <= 1'b0;
                        dma_axi_rready  <= 1'b1;
                        st <= ST_R;
                    end
                end

                ST_R: begin
                    if (r_fire) begin
                        dma_buf <= dma_axi_rdata;
                        dma_axi_rready <= 1'b0;
                        st <= ST_AW;
                    end
                end

                ST_AW: begin
                    dma_axi_awid    <= {ID_WIDTH{1'b0}};
                    dma_axi_awaddr  <= BASE_ADDR_WRITE + (word_count << 2);
                    dma_axi_awlen   <= 8'd0;      // 1 beat
                    dma_axi_awsize  <= 3'd2;      // 4 byte
                    dma_axi_awburst <= 2'b01;     // INCR
                    dma_axi_awvalid <= 1'b1;

                    if (aw_fire) begin
                        dma_axi_awvalid <= 1'b0;
                        dma_axi_wdata   <= dma_buf;
                        dma_axi_wlast   <= 1'b1;
                        dma_axi_wvalid  <= 1'b1;
                        st <= ST_W;
                    end
                end

                ST_W: begin
                    if (w_fire) begin
                        dma_axi_wvalid <= 1'b0;
                        dma_axi_wlast  <= 1'b0;
                        dma_axi_bready <= 1'b1;
                        st <= ST_B;
                    end
                end

                ST_B: begin
                    if (b_fire) begin
                        dma_axi_bready <= 1'b0;

                        if (word_count == DMA_WORDS - 1) begin
                            st <= ST_DONE;
                        end else begin
                            word_count <= word_count + 32'd1;
                            st <= ST_AR;
                        end
                    end
                end

                ST_DONE: begin
                    dma_busy <= 1'b0;
                    dma_done <= 1'b1;
                    if (dma_start) begin
                        st <= ST_IDLE;
                    end
                end

                default: begin
                    st <= ST_IDLE;
                end
            endcase
        end
    end

endmodule