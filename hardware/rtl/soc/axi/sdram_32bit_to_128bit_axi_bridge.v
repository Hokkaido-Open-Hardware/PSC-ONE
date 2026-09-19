/*
NISHIHARU — 32bit × 4 beat ⇄ 128bit line bridge
 - Cache side : 128-bit read/write
 - AXI side   : 32-bit AXI4 master, INCR, SIZE=2(4B), LEN=3(=4beat)
 - Order      : beat0->LSB ... beat3->MSB
*/
`timescale 1ns/1ps

module sdram_32bit_to_128bit_axi_bridge #(
    parameter integer ADDR_WIDTH   = 32,
    parameter integer ID_WIDTH     = 1,
    parameter integer DATA_WIDTH   = 32,
    parameter integer FENCE_CYCLES = 2
)(
    input  wire                     clock,
    input  wire                     reset_n,

    // Cache requests are one-cycle pulses, with at most one outstanding
    // request per cache. Address/data remain stable until completion, as in
    // cache_dma_controller{,_io}. ready is a completion pulse, not acceptance.
    input  wire                     i_read_valid,
    output wire                     i_read_ready,
    input  wire [ADDR_WIDTH-1:0]     i_read_addr,
    output wire [127:0]              i_read_data,

    input  wire                     d_read_valid,
    output wire                     d_read_ready,
    input  wire [ADDR_WIDTH-1:0]     d_read_addr,
    output wire [127:0]              d_read_data,
    input  wire                     d_write_valid,
    output reg                      d_write_ready,
    input  wire [ADDR_WIDTH-1:0]     d_write_addr,
    input  wire [127:0]              d_write_data,

    output reg  [ID_WIDTH-1:0]      m_axi_awid,
    output reg  [ADDR_WIDTH-1:0]    m_axi_awaddr,
    output reg  [7:0]               m_axi_awlen,
    output reg  [2:0]               m_axi_awsize,
    output reg  [1:0]               m_axi_awburst,
    output reg                      m_axi_awvalid,
    input  wire                     m_axi_awready,

    output reg  [DATA_WIDTH-1:0]    m_axi_wdata,
    output reg  [(DATA_WIDTH/8)-1:0]m_axi_wstrb,
    output reg                      m_axi_wlast,
    output reg                      m_axi_wvalid,
    input  wire                     m_axi_wready,

    input  wire [ID_WIDTH-1:0]      m_axi_bid,
    input  wire [1:0]               m_axi_bresp,
    input  wire                     m_axi_bvalid,
    output reg                      m_axi_bready,

    output reg  [ID_WIDTH-1:0]      m_axi_arid,
    output reg  [ADDR_WIDTH-1:0]    m_axi_araddr,
    output reg  [7:0]               m_axi_arlen,
    output reg  [2:0]               m_axi_arsize,
    output reg  [1:0]               m_axi_arburst,
    output reg                      m_axi_arvalid,
    input  wire                     m_axi_arready,

    input  wire [ID_WIDTH-1:0]      m_axi_rid,
    input  wire [DATA_WIDTH-1:0]    m_axi_rdata,
    input  wire [1:0]               m_axi_rresp,
    input  wire                     m_axi_rlast,
    input  wire                     m_axi_rvalid,
    output reg                      m_axi_rready
);

    localparam integer FENCE_CNT_WIDTH =
        (FENCE_CYCLES <= 1) ? 1 : $clog2(FENCE_CYCLES + 1);

    function automatic [ADDR_WIDTH-1:0] align16(input [ADDR_WIDTH-1:0] ba);
        align16 = {ba[ADDR_WIDTH-1:4], 4'b0000};
    endfunction

    function automatic [31:0] slc32(input [127:0] v, input [1:0] idx);
        case (idx)
            2'd0: slc32 = v[ 31:  0];
            2'd1: slc32 = v[ 63: 32];
            2'd2: slc32 = v[ 95: 64];
            default: slc32 = v[127: 96];
        endcase
    endfunction

    localparam [3:0] ST_IDLE  = 4'd0,
                     ST_W_AW  = 4'd1,
                     ST_W_W0  = 4'd2,
                     ST_W_W   = 4'd3,
                     ST_W_B   = 4'd4,
                     ST_FENCE = 4'd5,
                     ST_R_AR  = 4'd6,
                     ST_R_R0  = 4'd7,
                     ST_R_R   = 4'd8;

    reg [3:0]                    st;
    reg [127:0]                  rbuf;
    reg [127:0]                  wbuf;
    reg [1:0]                    beat;
    reg [FENCE_CNT_WIDTH-1:0]    fence_cnt;

    // owner also records the last grant for round-robin arbitration.
    // 0 = I-Cache, 1 = D-Cache. Hold it through the entire transaction/fence.
    reg owner;
    reg i_pending, d_pending, d_pending_write;
    reg read_done;
    // The caches emit one pulse per outstanding request. No busy-state
    // feedback is needed on the direct IDLE arbitration/address-mux path.
    wire i_new = i_read_valid;
    wire d_new = d_read_valid || d_write_valid;
    wire i_request = i_pending || i_new;
    wire d_request = d_pending || d_new;
    wire select_d = d_request && (!i_request || !owner);
    wire select_write = select_d && (d_pending ? d_pending_write : d_write_valid);
    wire [ADDR_WIDTH-1:0] selected_read_addr = select_d ? d_read_addr : i_read_addr;

    assign i_read_ready = read_done && !owner;
    assign d_read_ready = read_done && owner;
    // One shared line buffer, including the final beat. Data is meaningful only with that port's ready.
    assign i_read_data = rbuf;
    assign d_read_data = rbuf;

    wire aw_fire = m_axi_awvalid & m_axi_awready;
    wire w_fire  = m_axi_wvalid  & m_axi_wready;
    wire b_fire  = m_axi_bvalid  & m_axi_bready;
    wire ar_fire = m_axi_arvalid & m_axi_arready;
    wire r_fire  = m_axi_rvalid  & m_axi_rready;

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            owner         <= 1'b1; // First simultaneous request favors I.
            i_pending     <= 1'b0;
            d_pending     <= 1'b0;
            d_pending_write <= 1'b0;
            st            <= ST_IDLE;
            rbuf          <= 128'h0;
            wbuf          <= 128'h0;
            beat          <= 2'd0;
            fence_cnt     <= {FENCE_CNT_WIDTH{1'b0}};

            read_done    <= 1'b0;
            d_write_ready <= 1'b0;

            m_axi_awid    <= {ID_WIDTH{1'b0}};
            m_axi_awaddr  <= {ADDR_WIDTH{1'b0}};
            m_axi_awlen   <= 8'd3;     // 4 beat
            m_axi_awsize  <= 3'd2;     // 4 byte
            m_axi_awburst <= 2'b01;
            m_axi_awvalid <= 1'b0;

            m_axi_wdata   <= {DATA_WIDTH{1'b0}};
            m_axi_wstrb   <= {(DATA_WIDTH/8){1'b1}};
            m_axi_wlast   <= 1'b0;
            m_axi_wvalid  <= 1'b0;
            m_axi_bready  <= 1'b0;

            m_axi_arid    <= {ID_WIDTH{1'b0}};
            m_axi_araddr  <= {ADDR_WIDTH{1'b0}};
            m_axi_arlen   <= 8'd3;     // 4 beat
            m_axi_arsize  <= 3'd2;     // 4 byte
            m_axi_arburst <= 2'b01;
            m_axi_arvalid <= 1'b0;

            m_axi_rready  <= 1'b0;

        end else begin
            read_done  <= 1'b0;
            d_write_ready <= 1'b0;

            // Preserve a losing pulse or a request arriving while AXI is busy.
            // Payload stays in the requesting cache, not in a second datapath.
            if (i_new) i_pending <= 1'b1;
            if (d_new) begin
                d_pending <= 1'b1;
                d_pending_write <= d_write_valid;
            end

            if (m_axi_wvalid) begin
                m_axi_wstrb <= {(DATA_WIDTH/8){1'b1}};
            end

            case (st)
                ST_IDLE: begin
                    m_axi_awvalid <= 1'b0;
                    m_axi_wvalid  <= 1'b0;
                    m_axi_wlast   <= 1'b0;
                    m_axi_bready  <= 1'b0;
                    m_axi_arvalid <= 1'b0;
                    m_axi_rready  <= 1'b0;
                    beat          <= 2'd0;

                    if (fence_cnt != 0) begin
                        st <= ST_FENCE;
                    end else if (select_write) begin
                        owner         <= 1'b1;
                        d_pending     <= 1'b0;
                        wbuf          <= d_write_data;

                        m_axi_awid    <= {ID_WIDTH{1'b0}};
                        m_axi_awaddr  <= align16(d_write_addr);
                        m_axi_awlen   <= 8'd3;
                        m_axi_awsize  <= 3'd2;
                        m_axi_awburst <= 2'b01;
                        m_axi_awvalid <= 1'b1;

                        st            <= ST_W_AW;

                    end else if (i_request || d_request) begin
                        owner <= select_d;
                        if (select_d) d_pending <= 1'b0;
                        else          i_pending <= 1'b0;
                        m_axi_arid    <= {ID_WIDTH{1'b0}};
                        m_axi_araddr  <= align16(selected_read_addr);
                        m_axi_arlen   <= 8'd3;
                        m_axi_arsize  <= 3'd2;
                        m_axi_arburst <= 2'b01;
                        m_axi_arvalid <= 1'b1;

                        st            <= ST_R_AR;
                    end
                end

                ST_FENCE: begin
                    if (fence_cnt != 0) begin
                        fence_cnt <= fence_cnt - 1'b1;
                    end
                    if (fence_cnt == 1) begin
                        st <= ST_IDLE;
                    end
                end

                ST_W_AW: begin
                    if (aw_fire) begin
                        m_axi_awvalid <= 1'b0;
                        beat          <= 2'd0;
                        st            <= ST_W_W0;
                    end
                end

                ST_W_W0: begin
                    m_axi_wdata  <= slc32(wbuf, 2'd0);
                    m_axi_wlast  <= 1'b0;
                    m_axi_wvalid <= 1'b1;
                    st           <= ST_W_W;
                end

                ST_W_W: begin
                    if (w_fire) begin
                        if (beat == 2'd3) begin
                            m_axi_wvalid <= 1'b0;
                            m_axi_wlast  <= 1'b0;
                            m_axi_bready <= 1'b1;
                            st           <= ST_W_B;
                        end else begin
                            beat        <= beat + 2'd1;
                            m_axi_wdata <= slc32(wbuf, beat + 2'd1);
                            m_axi_wlast <= (beat + 2'd1 == 2'd3);
                        end
                    end
                end

                ST_W_B: begin
                    if (b_fire) begin
                        m_axi_bready <= 1'b0;
                        d_write_ready <= 1'b1;

                        fence_cnt    <= (FENCE_CYCLES == 0)
                                      ? {FENCE_CNT_WIDTH{1'b0}}
                                      : FENCE_CYCLES[FENCE_CNT_WIDTH-1:0];

                        st           <= (FENCE_CYCLES == 0) ? ST_IDLE : ST_FENCE;
                    end
                end

                ST_R_AR: begin
                    if (ar_fire) begin
                        m_axi_arvalid <= 1'b0;
                        beat          <= 2'd0;
                        st            <= ST_R_R0;
                    end
                end

                ST_R_R0: begin
                    m_axi_rready <= 1'b1;
                    st           <= ST_R_R;
                end

                ST_R_R: begin
                    if (r_fire) begin
                        case (beat)
                            2'd0: rbuf[ 31:  0] <= m_axi_rdata;
                            2'd1: rbuf[ 63: 32] <= m_axi_rdata;
                            2'd2: rbuf[ 95: 64] <= m_axi_rdata;
                            default: rbuf[127:96] <= m_axi_rdata;
                        endcase

                        if (m_axi_rlast || (beat == 2'd3)) begin
                            m_axi_rready <= 1'b0;
                            read_done   <= 1'b1;
                            st           <= ST_IDLE;
                        end else begin
                            beat <= beat + 2'd1;
                        end
                    end
                end

                default: begin
                    st <= ST_IDLE;
                end
            endcase
        end
    end

endmodule
