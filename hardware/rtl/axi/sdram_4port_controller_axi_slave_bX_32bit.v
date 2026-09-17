/*
NISHIHARU — SDRAM Controller AXI4 4-port Slave
- 4x AXI4-S (32-bit) -> Single SDRAM controller
- INCR only, SIZE=2(4B), LEN={0,1,3,7}
*/
`timescale 1ns/1ps

module sdram_4port_controller_axi_slave_bX_32bit #(
    parameter integer CLK_FREQ_MHz      = 100,
    parameter integer ADDR_WIDTH        = 24,
    parameter integer DATA_WIDTH        = 32,
    parameter integer ID_WIDTH          = 1,
    parameter integer SD_ADDR_BUS_WIDTH = 11
)(
    input  wire                      aclk,
    input  wire                      aresetn,

    // -------- Port 0 --------
    input  wire [ID_WIDTH-1:0]       s0_axi_awid,
    input  wire [ADDR_WIDTH-1:0]     s0_axi_awaddr,
    input  wire [7:0]                s0_axi_awlen,
    input  wire [2:0]                s0_axi_awsize,
    input  wire [1:0]                s0_axi_awburst,
    input  wire                      s0_axi_awvalid,
    output reg                       s0_axi_awready,

    input  wire [DATA_WIDTH-1:0]     s0_axi_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] s0_axi_wstrb,
    input  wire                      s0_axi_wlast,
    input  wire                      s0_axi_wvalid,
    output reg                       s0_axi_wready,

    output reg  [ID_WIDTH-1:0]       s0_axi_bid,
    output reg  [1:0]                s0_axi_bresp,
    output reg                       s0_axi_bvalid,
    input  wire                      s0_axi_bready,

    input  wire [ID_WIDTH-1:0]       s0_axi_arid,
    input  wire [ADDR_WIDTH-1:0]     s0_axi_araddr,
    input  wire [7:0]                s0_axi_arlen,
    input  wire [2:0]                s0_axi_arsize,
    input  wire [1:0]                s0_axi_arburst,
    input  wire                      s0_axi_arvalid,
    output reg                       s0_axi_arready,

    output reg  [ID_WIDTH-1:0]       s0_axi_rid,
    output reg  [DATA_WIDTH-1:0]     s0_axi_rdata,
    output reg  [1:0]                s0_axi_rresp,
    output reg                       s0_axi_rlast,
    output reg                       s0_axi_rvalid,
    input  wire                      s0_axi_rready,

    // -------- Port 1 --------
    input  wire [ID_WIDTH-1:0]       s1_axi_awid,
    input  wire [ADDR_WIDTH-1:0]     s1_axi_awaddr,
    input  wire [7:0]                s1_axi_awlen,
    input  wire [2:0]                s1_axi_awsize,
    input  wire [1:0]                s1_axi_awburst,
    input  wire                      s1_axi_awvalid,
    output reg                       s1_axi_awready,

    input  wire [DATA_WIDTH-1:0]     s1_axi_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] s1_axi_wstrb,
    input  wire                      s1_axi_wlast,
    input  wire                      s1_axi_wvalid,
    output reg                       s1_axi_wready,

    output reg  [ID_WIDTH-1:0]       s1_axi_bid,
    output reg  [1:0]                s1_axi_bresp,
    output reg                       s1_axi_bvalid,
    input  wire                      s1_axi_bready,

    input  wire [ID_WIDTH-1:0]       s1_axi_arid,
    input  wire [ADDR_WIDTH-1:0]     s1_axi_araddr,
    input  wire [7:0]                s1_axi_arlen,
    input  wire [2:0]                s1_axi_arsize,
    input  wire [1:0]                s1_axi_arburst,
    input  wire                      s1_axi_arvalid,
    output reg                       s1_axi_arready,

    output reg  [ID_WIDTH-1:0]       s1_axi_rid,
    output reg  [DATA_WIDTH-1:0]     s1_axi_rdata,
    output reg  [1:0]                s1_axi_rresp,
    output reg                       s1_axi_rlast,
    output reg                       s1_axi_rvalid,
    input  wire                      s1_axi_rready,

    // -------- Port 2 --------
    input  wire [ID_WIDTH-1:0]       s2_axi_awid,
    input  wire [ADDR_WIDTH-1:0]     s2_axi_awaddr,
    input  wire [7:0]                s2_axi_awlen,
    input  wire [2:0]                s2_axi_awsize,
    input  wire [1:0]                s2_axi_awburst,
    input  wire                      s2_axi_awvalid,
    output reg                       s2_axi_awready,

    input  wire [DATA_WIDTH-1:0]     s2_axi_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] s2_axi_wstrb,
    input  wire                      s2_axi_wlast,
    input  wire                      s2_axi_wvalid,
    output reg                       s2_axi_wready,

    output reg  [ID_WIDTH-1:0]       s2_axi_bid,
    output reg  [1:0]                s2_axi_bresp,
    output reg                       s2_axi_bvalid,
    input  wire                      s2_axi_bready,

    input  wire [ID_WIDTH-1:0]       s2_axi_arid,
    input  wire [ADDR_WIDTH-1:0]     s2_axi_araddr,
    input  wire [7:0]                s2_axi_arlen,
    input  wire [2:0]                s2_axi_arsize,
    input  wire [1:0]                s2_axi_arburst,
    input  wire                      s2_axi_arvalid,
    output reg                       s2_axi_arready,

    output reg  [ID_WIDTH-1:0]       s2_axi_rid,
    output reg  [DATA_WIDTH-1:0]     s2_axi_rdata,
    output reg  [1:0]                s2_axi_rresp,
    output reg                       s2_axi_rlast,
    output reg                       s2_axi_rvalid,
    input  wire                      s2_axi_rready,

    // -------- Port 3 --------
    input  wire [ID_WIDTH-1:0]       s3_axi_awid,
    input  wire [ADDR_WIDTH-1:0]     s3_axi_awaddr,
    input  wire [7:0]                s3_axi_awlen,
    input  wire [2:0]                s3_axi_awsize,
    input  wire [1:0]                s3_axi_awburst,
    input  wire                      s3_axi_awvalid,
    output reg                       s3_axi_awready,

    input  wire [DATA_WIDTH-1:0]     s3_axi_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] s3_axi_wstrb,
    input  wire                      s3_axi_wlast,
    input  wire                      s3_axi_wvalid,
    output reg                       s3_axi_wready,

    output reg  [ID_WIDTH-1:0]       s3_axi_bid,
    output reg  [1:0]                s3_axi_bresp,
    output reg                       s3_axi_bvalid,
    input  wire                      s3_axi_bready,

    input  wire [ID_WIDTH-1:0]       s3_axi_arid,
    input  wire [ADDR_WIDTH-1:0]     s3_axi_araddr,
    input  wire [7:0]                s3_axi_arlen,
    input  wire [2:0]                s3_axi_arsize,
    input  wire [1:0]                s3_axi_arburst,
    input  wire                      s3_axi_arvalid,
    output reg                       s3_axi_arready,

    output reg  [ID_WIDTH-1:0]       s3_axi_rid,
    output reg  [DATA_WIDTH-1:0]     s3_axi_rdata,
    output reg  [1:0]                s3_axi_rresp,
    output reg                       s3_axi_rlast,
    output reg                       s3_axi_rvalid,
    input  wire                      s3_axi_rready,

    // -------- SDRAM physical --------
    output wire                      sdram_clk,
    output wire                      sdram_cs,
    output wire                      sdram_ras,
    output wire                      sdram_cas,
    output wire                      sdram_we,
    output wire [10:0]               sdram_adr,
    output wire [1:0]                sdram_ba,
    output wire [3:0]                sdram_dqm,
    inout  wire [31:0]               sdram_dq,
    output wire                      sdram_init_fin
);

    // ============================================================
    // SDRAM controller legacy/simple IF
    // ============================================================
    wire                  req_ready;

    reg                   read_valid;
    wire                  read_ready;
    reg  [ADDR_WIDTH-1:0] read_addr;
    wire [DATA_WIDTH-1:0] read_data;

    reg                   write_valid;
    wire                  write_ready;
    reg  [ADDR_WIDTH-1:0] write_addr;
    reg  [DATA_WIDTH-1:0] write_data;

    reg  [3:0]            rw_length;

    /*
    // MT48LC16M16
    wire [1:0]  read_ba   = read_addr [23:22];
    wire [12:0] read_row  = read_addr [21:9];
    wire [8:0]  read_col  = read_addr [8:0];

    wire [1:0]  write_ba  = write_addr[23:22];
    wire [12:0] write_row = write_addr[21:9];
    wire [8:0]  write_col = write_addr[8:0];
    */

    // GW2AR 64Mbit SDRAM spec.
    wire [1:0]  read_ba   = read_addr [20:19];
    wire [10:0] read_row  = read_addr [18:8];
    wire [7:0]  read_col  = read_addr [7:0];

    wire [1:0]  write_ba  = write_addr[20:19];
    wire [10:0] write_row = write_addr[18:8];
    wire [7:0]  write_col = write_addr[7:0];

    sdram_controller #(
        .clk_dly_ps             (0),
        .CLK_FREQ_MHz           (CLK_FREQ_MHz),
        .COL_ADDR_BUS_WIDTH     (8),
        .ROW_ADDR_BUS_WIDTH     (11),
        .BNK_ADDR_BUS_WIDTH     (2),
        .DQ_BUS_WIDTH           (32),
        .DQM_BUS_WIDTH          (4),
        .SD_ADDR_BUS_WIDTH      (SD_ADDR_BUS_WIDTH)
    ) u_sdram_controller (
        .clock          (aclk),
        .reset_n        (aresetn),
        .rw_length      (rw_length),
        .req_ready      (req_ready),
        .sdram_init_fin (sdram_init_fin),

        .read_valid     (read_valid),
        .read_ready     (read_ready),
        .read_addr_ba   (read_ba),
        .read_addr_row  (read_row),
        .read_addr_col  (read_col),
        .read_data      (read_data),

        .write_valid    (write_valid),
        .write_ready    (write_ready),
        .write_addr_ba  (write_ba),
        .write_addr_row (write_row),
        .write_addr_col (write_col),
        .write_data     (write_data),

        .sdram_clk      (sdram_clk),
        .sdram_cs       (sdram_cs),
        .sdram_ras      (sdram_ras),
        .sdram_cas      (sdram_cas),
        .sdram_we       (sdram_we),
        .sdram_adr      (sdram_adr),
        .sdram_ba       (sdram_ba),
        .sdram_dqm      (sdram_dqm),
        .sdram_dq       (sdram_dq)
    );

    // ============================================================
    // helpers
    // ============================================================
    localparam [ADDR_WIDTH-1:0] WORD_INC = {{(ADDR_WIDTH-1){1'b0}}, 1'b1};

    function [3:0] len_to_beats;
        input [7:0] len;
        begin
            case (len)
                8'd0: len_to_beats = 4'd1;
                8'd1: len_to_beats = 4'd2;
                8'd3: len_to_beats = 4'd4;
                8'd7: len_to_beats = 4'd8;
                default: len_to_beats = 4'd0;
            endcase
        end
    endfunction

    function bad_len;
        input [7:0] len;
        begin
            bad_len = !((len==8'd0)||(len==8'd1)||(len==8'd3)||(len==8'd7));
        end
    endfunction

    function bad_aw;
        input [7:0] len;
        input [2:0] size;
        input [1:0] burst;
        input [1:0] addr_lsb;
        begin
            bad_aw = bad_len(len) || (size != 3'd2) || (burst != 2'b01) || (addr_lsb != 2'b00);
        end
    endfunction

    function bad_ar;
        input [7:0] len;
        input [2:0] size;
        input [1:0] burst;
        input [1:0] addr_lsb;
        begin
            bad_ar = bad_len(len) || (size != 3'd2) || (burst != 2'b01) || (addr_lsb != 2'b00);
        end
    endfunction

    // ============================================================
    // state
    // ============================================================
    localparam [3:0]
        IDLE         = 4'd0,

        W_AW         = 4'd1,
        W_COLLECT    = 4'd2,
        W_WAIT_START = 4'd3,
        W_ISSUE      = 4'd4,
        W_WAIT_B     = 4'd5,
        W_RESP       = 4'd6,
        W_DRAIN      = 4'd7,

        R_AR         = 4'd8,
        R_WAIT_START = 4'd9,
        R_ISSUE      = 4'd10,
        R_SEND       = 4'd11;

    reg [3:0] st;
    reg [1:0] cur_port;
    reg       cur_is_write;

    // WRITE regs
    reg [ID_WIDTH-1:0]   w_id;
    reg [ADDR_WIDTH-1:0] w_base_word;
    reg [ADDR_WIDTH-1:0] w_cur_word;
    reg [3:0]            w_beats_total;
    reg [3:0]            w_cnt;
    reg                  w_err;

    reg [31:0] wbuf0;
    reg [31:0] wbuf1;
    reg [31:0] wbuf2;
    reg [31:0] wbuf3;
    reg [31:0] wbuf4;
    reg [31:0] wbuf5;
    reg [31:0] wbuf6;
    reg [31:0] wbuf7;

    // READ regs
    reg [ID_WIDTH-1:0]   r_id;
    reg [ADDR_WIDTH-1:0] r_base_word;
    reg [ADDR_WIDTH-1:0] r_cur_word;
    reg [3:0]            r_beats_total;
    reg [3:0]            r_issue_cnt;
    reg [3:0]            r_recv_cnt;
    reg [3:0]            r_send_cnt;
    reg                  r_err;

    reg [31:0] rbuf0;
    reg [31:0] rbuf1;
    reg [31:0] rbuf2;
    reg [31:0] rbuf3;
    reg [31:0] rbuf4;
    reg [31:0] rbuf5;
    reg [31:0] rbuf6;
    reg [31:0] rbuf7;

    // ============================================================
    // selected port signals
    // ============================================================
    wire [ID_WIDTH-1:0] sel_awid =
        (cur_port==2'd0) ? s0_axi_awid :
        (cur_port==2'd1) ? s1_axi_awid :
        (cur_port==2'd2) ? s2_axi_awid : s3_axi_awid;

    wire [ADDR_WIDTH-1:0] sel_awaddr =
        (cur_port==2'd0) ? s0_axi_awaddr :
        (cur_port==2'd1) ? s1_axi_awaddr :
        (cur_port==2'd2) ? s2_axi_awaddr : s3_axi_awaddr;

    wire [7:0] sel_awlen =
        (cur_port==2'd0) ? s0_axi_awlen :
        (cur_port==2'd1) ? s1_axi_awlen :
        (cur_port==2'd2) ? s2_axi_awlen : s3_axi_awlen;

    wire [2:0] sel_awsize =
        (cur_port==2'd0) ? s0_axi_awsize :
        (cur_port==2'd1) ? s1_axi_awsize :
        (cur_port==2'd2) ? s2_axi_awsize : s3_axi_awsize;

    wire [1:0] sel_awburst =
        (cur_port==2'd0) ? s0_axi_awburst :
        (cur_port==2'd1) ? s1_axi_awburst :
        (cur_port==2'd2) ? s2_axi_awburst : s3_axi_awburst;

    wire [ID_WIDTH-1:0] sel_arid =
        (cur_port==2'd0) ? s0_axi_arid :
        (cur_port==2'd1) ? s1_axi_arid :
        (cur_port==2'd2) ? s2_axi_arid : s3_axi_arid;

    wire [ADDR_WIDTH-1:0] sel_araddr =
        (cur_port==2'd0) ? s0_axi_araddr :
        (cur_port==2'd1) ? s1_axi_araddr :
        (cur_port==2'd2) ? s2_axi_araddr : s3_axi_araddr;

    wire [7:0] sel_arlen =
        (cur_port==2'd0) ? s0_axi_arlen :
        (cur_port==2'd1) ? s1_axi_arlen :
        (cur_port==2'd2) ? s2_axi_arlen : s3_axi_arlen;

    wire [2:0] sel_arsize =
        (cur_port==2'd0) ? s0_axi_arsize :
        (cur_port==2'd1) ? s1_axi_arsize :
        (cur_port==2'd2) ? s2_axi_arsize : s3_axi_arsize;

    wire [1:0] sel_arburst =
        (cur_port==2'd0) ? s0_axi_arburst :
        (cur_port==2'd1) ? s1_axi_arburst :
        (cur_port==2'd2) ? s2_axi_arburst : s3_axi_arburst;

    wire sel_wvalid =
        (cur_port==2'd0) ? s0_axi_wvalid :
        (cur_port==2'd1) ? s1_axi_wvalid :
        (cur_port==2'd2) ? s2_axi_wvalid : s3_axi_wvalid;

    wire [DATA_WIDTH-1:0] sel_wdata =
        (cur_port==2'd0) ? s0_axi_wdata :
        (cur_port==2'd1) ? s1_axi_wdata :
        (cur_port==2'd2) ? s2_axi_wdata : s3_axi_wdata;

    wire [(DATA_WIDTH/8)-1:0] sel_wstrb =
        (cur_port==2'd0) ? s0_axi_wstrb :
        (cur_port==2'd1) ? s1_axi_wstrb :
        (cur_port==2'd2) ? s2_axi_wstrb : s3_axi_wstrb;

    wire sel_wlast =
        (cur_port==2'd0) ? s0_axi_wlast :
        (cur_port==2'd1) ? s1_axi_wlast :
        (cur_port==2'd2) ? s2_axi_wlast : s3_axi_wlast;

    wire sel_bready =
        (cur_port==2'd0) ? s0_axi_bready :
        (cur_port==2'd1) ? s1_axi_bready :
        (cur_port==2'd2) ? s2_axi_bready : s3_axi_bready;

    wire sel_rready =
        (cur_port==2'd0) ? s0_axi_rready :
        (cur_port==2'd1) ? s1_axi_rready :
        (cur_port==2'd2) ? s2_axi_rready : s3_axi_rready;

    wire sel_rvalid_now =
        (cur_port==2'd0) ? s0_axi_rvalid :
        (cur_port==2'd1) ? s1_axi_rvalid :
        (cur_port==2'd2) ? s2_axi_rvalid : s3_axi_rvalid;

    wire sel_wready_now =
        (cur_port==2'd0) ? s0_axi_wready :
        (cur_port==2'd1) ? s1_axi_wready :
        (cur_port==2'd2) ? s2_axi_wready : s3_axi_wready;

    wire w_fire = sel_wvalid & sel_wready_now;

    // ============================================================
    // tasks
    // ============================================================
    task clear_ready_only;
        begin
            s0_axi_awready <= 1'b0;
            s1_axi_awready <= 1'b0;
            s2_axi_awready <= 1'b0;
            s3_axi_awready <= 1'b0;

            s0_axi_wready  <= 1'b0;
            s1_axi_wready  <= 1'b0;
            s2_axi_wready  <= 1'b0;
            s3_axi_wready  <= 1'b0;

            s0_axi_arready <= 1'b0;
            s1_axi_arready <= 1'b0;
            s2_axi_arready <= 1'b0;
            s3_axi_arready <= 1'b0;

            s0_axi_rlast   <= 1'b0;
            s1_axi_rlast   <= 1'b0;
            s2_axi_rlast   <= 1'b0;
            s3_axi_rlast   <= 1'b0;
        end
    endtask

    task set_awready_port;
        input [1:0] p;
        begin
            case (p)
                2'd0: s0_axi_awready <= 1'b1;
                2'd1: s1_axi_awready <= 1'b1;
                2'd2: s2_axi_awready <= 1'b1;
                default: s3_axi_awready <= 1'b1;
            endcase
        end
    endtask

    task set_arready_port;
        input [1:0] p;
        begin
            case (p)
                2'd0: s0_axi_arready <= 1'b1;
                2'd1: s1_axi_arready <= 1'b1;
                2'd2: s2_axi_arready <= 1'b1;
                default: s3_axi_arready <= 1'b1;
            endcase
        end
    endtask

    task set_wready_port;
        input [1:0] p;
        input       v;
        begin
            case (p)
                2'd0: s0_axi_wready <= v;
                2'd1: s1_axi_wready <= v;
                2'd2: s2_axi_wready <= v;
                default: s3_axi_wready <= v;
            endcase
        end
    endtask

    task drive_bresp_port;
        input [1:0] p;
        input [ID_WIDTH-1:0] id;
        input [1:0] resp;
        input set_valid;
        begin
            case (p)
                2'd0: begin s0_axi_bid <= id; s0_axi_bresp <= resp; s0_axi_bvalid <= set_valid; end
                2'd1: begin s1_axi_bid <= id; s1_axi_bresp <= resp; s1_axi_bvalid <= set_valid; end
                2'd2: begin s2_axi_bid <= id; s2_axi_bresp <= resp; s2_axi_bvalid <= set_valid; end
                default: begin s3_axi_bid <= id; s3_axi_bresp <= resp; s3_axi_bvalid <= set_valid; end
            endcase
        end
    endtask

    task drop_bvalid_port;
        input [1:0] p;
        begin
            case (p)
                2'd0: s0_axi_bvalid <= 1'b0;
                2'd1: s1_axi_bvalid <= 1'b0;
                2'd2: s2_axi_bvalid <= 1'b0;
                default: s3_axi_bvalid <= 1'b0;
            endcase
        end
    endtask

    task drive_rdata_port;
        input [1:0] p;
        input [ID_WIDTH-1:0] id;
        input [DATA_WIDTH-1:0] data;
        input [1:0] resp;
        input last;
        input set_valid;
        begin
            case (p)
                2'd0: begin s0_axi_rid <= id; s0_axi_rdata <= data; s0_axi_rresp <= resp; s0_axi_rlast <= last; s0_axi_rvalid <= set_valid; end
                2'd1: begin s1_axi_rid <= id; s1_axi_rdata <= data; s1_axi_rresp <= resp; s1_axi_rlast <= last; s1_axi_rvalid <= set_valid; end
                2'd2: begin s2_axi_rid <= id; s2_axi_rdata <= data; s2_axi_rresp <= resp; s2_axi_rlast <= last; s2_axi_rvalid <= set_valid; end
                default: begin s3_axi_rid <= id; s3_axi_rdata <= data; s3_axi_rresp <= resp; s3_axi_rlast <= last; s3_axi_rvalid <= set_valid; end
            endcase
        end
    endtask

    task drop_rvalid_port;
        input [1:0] p;
        begin
            case (p)
                2'd0: begin s0_axi_rvalid <= 1'b0; s0_axi_rlast <= 1'b0; end
                2'd1: begin s1_axi_rvalid <= 1'b0; s1_axi_rlast <= 1'b0; end
                2'd2: begin s2_axi_rvalid <= 1'b0; s2_axi_rlast <= 1'b0; end
                default: begin s3_axi_rvalid <= 1'b0; s3_axi_rlast <= 1'b0; end
            endcase
        end
    endtask

    // ============================================================
    // FSM
    // ============================================================
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s0_axi_awready <= 1'b0;
            s1_axi_awready <= 1'b0;
            s2_axi_awready <= 1'b0;
            s3_axi_awready <= 1'b0;

            s0_axi_wready  <= 1'b0;
            s1_axi_wready  <= 1'b0;
            s2_axi_wready  <= 1'b0;
            s3_axi_wready  <= 1'b0;

            s0_axi_bvalid <= 1'b0;
            s1_axi_bvalid <= 1'b0;
            s2_axi_bvalid <= 1'b0;
            s3_axi_bvalid <= 1'b0;

            s0_axi_bresp <= 2'b00;
            s1_axi_bresp <= 2'b00;
            s2_axi_bresp <= 2'b00;
            s3_axi_bresp <= 2'b00;

            s0_axi_bid <= {ID_WIDTH{1'b0}};
            s1_axi_bid <= {ID_WIDTH{1'b0}};
            s2_axi_bid <= {ID_WIDTH{1'b0}};
            s3_axi_bid <= {ID_WIDTH{1'b0}};

            s0_axi_arready <= 1'b0;
            s1_axi_arready <= 1'b0;
            s2_axi_arready <= 1'b0;
            s3_axi_arready <= 1'b0;

            s0_axi_rvalid <= 1'b0;
            s1_axi_rvalid <= 1'b0;
            s2_axi_rvalid <= 1'b0;
            s3_axi_rvalid <= 1'b0;

            s0_axi_rresp <= 2'b00;
            s1_axi_rresp <= 2'b00;
            s2_axi_rresp <= 2'b00;
            s3_axi_rresp <= 2'b00;

            s0_axi_rid <= {ID_WIDTH{1'b0}};
            s1_axi_rid <= {ID_WIDTH{1'b0}};
            s2_axi_rid <= {ID_WIDTH{1'b0}};
            s3_axi_rid <= {ID_WIDTH{1'b0}};

            s0_axi_rdata <= {DATA_WIDTH{1'b0}};
            s1_axi_rdata <= {DATA_WIDTH{1'b0}};
            s2_axi_rdata <= {DATA_WIDTH{1'b0}};
            s3_axi_rdata <= {DATA_WIDTH{1'b0}};

            s0_axi_rlast <= 1'b0;
            s1_axi_rlast <= 1'b0;
            s2_axi_rlast <= 1'b0;
            s3_axi_rlast <= 1'b0;

            read_valid  <= 1'b0;
            write_valid <= 1'b0;
            read_addr   <= {ADDR_WIDTH{1'b0}};
            write_addr  <= {ADDR_WIDTH{1'b0}};
            write_data  <= 32'h0000_0000;
            rw_length   <= 4'd0;

            st           <= IDLE;
            cur_port     <= 2'd0;
            cur_is_write <= 1'b0;

            w_id          <= {ID_WIDTH{1'b0}};
            w_base_word   <= {ADDR_WIDTH{1'b0}};
            w_cur_word    <= {ADDR_WIDTH{1'b0}};
            w_beats_total <= 4'd0;
            w_cnt         <= 4'd0;
            w_err         <= 1'b0;

            r_id          <= {ID_WIDTH{1'b0}};
            r_base_word   <= {ADDR_WIDTH{1'b0}};
            r_cur_word    <= {ADDR_WIDTH{1'b0}};
            r_beats_total <= 4'd0;
            r_issue_cnt   <= 4'd0;
            r_recv_cnt    <= 4'd0;
            r_send_cnt    <= 4'd0;
            r_err         <= 1'b0;

            wbuf0 <= 32'h0; wbuf1 <= 32'h0; wbuf2 <= 32'h0; wbuf3 <= 32'h0;
            wbuf4 <= 32'h0; wbuf5 <= 32'h0; wbuf6 <= 32'h0; wbuf7 <= 32'h0;

            rbuf0 <= 32'h0; rbuf1 <= 32'h0; rbuf2 <= 32'h0; rbuf3 <= 32'h0;
            rbuf4 <= 32'h0; rbuf5 <= 32'h0; rbuf6 <= 32'h0; rbuf7 <= 32'h0;

        end else begin
            clear_ready_only();

            if (st != R_ISSUE) begin
                read_valid <= 1'b0;
            end

            if (st != W_ISSUE && st != W_WAIT_START) begin
                write_valid <= 1'b0;
            end

            case (st)
                IDLE: begin
                    if      (s0_axi_awvalid) begin cur_port <= 2'd0; cur_is_write <= 1'b1; st <= W_AW; end
                    else if (s0_axi_arvalid) begin cur_port <= 2'd0; cur_is_write <= 1'b0; st <= R_AR; end
                    else if (s1_axi_awvalid) begin cur_port <= 2'd1; cur_is_write <= 1'b1; st <= W_AW; end
                    else if (s1_axi_arvalid) begin cur_port <= 2'd1; cur_is_write <= 1'b0; st <= R_AR; end
                    else if (s2_axi_awvalid) begin cur_port <= 2'd2; cur_is_write <= 1'b1; st <= W_AW; end
                    else if (s2_axi_arvalid) begin cur_port <= 2'd2; cur_is_write <= 1'b0; st <= R_AR; end
                    else if (s3_axi_awvalid) begin cur_port <= 2'd3; cur_is_write <= 1'b1; st <= W_AW; end
                    else if (s3_axi_arvalid) begin cur_port <= 2'd3; cur_is_write <= 1'b0; st <= R_AR; end

                    w_err <= 1'b0;
                    r_err <= 1'b0;
                end

                W_AW: begin
                    set_awready_port(cur_port);

                    if ((cur_port==2'd0 && s0_axi_awvalid) ||
                        (cur_port==2'd1 && s1_axi_awvalid) ||
                        (cur_port==2'd2 && s2_axi_awvalid) ||
                        (cur_port==2'd3 && s3_axi_awvalid)) begin

                        w_id          <= sel_awid;
                        w_base_word   <= {2'b00, sel_awaddr[ADDR_WIDTH-1:2]};   // word addressへ変換
                        w_cur_word    <= {2'b00, sel_awaddr[ADDR_WIDTH-1:2]};   // word addressへ変換
                        w_beats_total <= len_to_beats(sel_awlen);
                        w_err         <= bad_aw(sel_awlen, sel_awsize, sel_awburst, sel_awaddr[1:0]);
                        w_cnt         <= 4'd0;
                        st            <= W_COLLECT;
                    end
                end

                W_COLLECT: begin
                    set_wready_port(cur_port, 1'b1);

                    if (w_fire) begin
                        case (w_cnt)
                            4'd0: wbuf0 <= sel_wdata;
                            4'd1: wbuf1 <= sel_wdata;
                            4'd2: wbuf2 <= sel_wdata;
                            4'd3: wbuf3 <= sel_wdata;
                            4'd4: wbuf4 <= sel_wdata;
                            4'd5: wbuf5 <= sel_wdata;
                            4'd6: wbuf6 <= sel_wdata;
                            default: wbuf7 <= sel_wdata;
                        endcase

                        w_err <= w_err ||
                                 (sel_wstrb != 4'b1111) ||
                                 (sel_wlast != (w_cnt == (w_beats_total - 1'b1)));

                        if (w_cnt == (w_beats_total - 1'b1)) begin
                            w_cnt      <= 4'd0;
                            w_cur_word <= w_base_word;
                            st         <= W_WAIT_START;
                        end else begin
                            w_cnt <= w_cnt + 4'd1;
                        end
                    end
                end

                W_WAIT_START: begin
                    if (req_ready) begin
                        rw_length   <= w_beats_total;
                        write_valid <= 1'b1;
                        write_addr  <= w_cur_word;
                        write_data  <= wbuf0;

                        if (w_beats_total == 4'd1) begin
                            st <= W_WAIT_B;
                        end else begin
                            w_cnt      <= 4'd1;
                            w_cur_word <= w_cur_word + WORD_INC;
                            st         <= W_ISSUE;
                        end
                    end
                end

                W_ISSUE: begin
                    write_valid <= 1'b1;
                    write_addr  <= w_cur_word;

                    case (w_cnt)
                        4'd1: write_data <= wbuf1;
                        4'd2: write_data <= wbuf2;
                        4'd3: write_data <= wbuf3;
                        4'd4: write_data <= wbuf4;
                        4'd5: write_data <= wbuf5;
                        4'd6: write_data <= wbuf6;
                        default: write_data <= wbuf7;
                    endcase

                    if (w_cnt == (w_beats_total - 1'b1)) begin
                        st <= W_WAIT_B;
                    end else begin
                        w_cnt      <= w_cnt + 4'd1;
                        w_cur_word <= w_cur_word + WORD_INC;
                    end
                end

                W_WAIT_B: begin
                    if (write_ready || w_err) begin
                        drive_bresp_port(cur_port, w_id, (w_err ? 2'b10 : 2'b00), 1'b1);
                        st <= W_RESP;
                    end
                end

                W_RESP: begin
                    if (sel_bready) begin
                        drop_bvalid_port(cur_port);
                        st <= W_DRAIN;
                    end
                end

                W_DRAIN: begin
                    if (!write_ready && req_ready) begin
                        st <= IDLE;
                    end
                end

                R_AR: begin
                    set_arready_port(cur_port);

                    if ((cur_port==2'd0 && s0_axi_arvalid) ||
                        (cur_port==2'd1 && s1_axi_arvalid) ||
                        (cur_port==2'd2 && s2_axi_arvalid) ||
                        (cur_port==2'd3 && s3_axi_arvalid)) begin

                        r_id          <= sel_arid;
                        r_base_word   <= {2'b00, sel_araddr[ADDR_WIDTH-1:2]};   // word addressへ変換
                        r_cur_word    <= {2'b00, sel_araddr[ADDR_WIDTH-1:2]};   // word addressへ変換
                        r_beats_total <= len_to_beats(sel_arlen);
                        r_err         <= bad_ar(sel_arlen, sel_arsize, sel_arburst, sel_araddr[1:0]);
                        r_issue_cnt   <= 4'd0;
                        r_recv_cnt    <= 4'd0;
                        r_send_cnt    <= 4'd0;
                        st            <= R_WAIT_START;
                    end
                end

                R_WAIT_START: begin
                    if (req_ready) begin
                        rw_length   <= r_beats_total;
                        read_valid  <= 1'b1;
                        read_addr   <= r_cur_word;
                        r_cur_word  <= r_cur_word + WORD_INC;
                        r_issue_cnt <= 4'd1;
                        st          <= R_ISSUE;
                    end
                end

                R_ISSUE: begin
                    read_valid <= 1'b1;

                    if (r_issue_cnt < r_beats_total) begin
                        read_addr   <= r_cur_word;
                        r_cur_word  <= r_cur_word + WORD_INC;
                        r_issue_cnt <= r_issue_cnt + 4'd1;
                    end else begin
                        st <= R_SEND;
                    end

                    if (read_ready && (r_recv_cnt < r_beats_total)) begin
                        case (r_recv_cnt)
                            4'd0: rbuf0 <= read_data;
                            4'd1: rbuf1 <= read_data;
                            4'd2: rbuf2 <= read_data;
                            4'd3: rbuf3 <= read_data;
                            4'd4: rbuf4 <= read_data;
                            4'd5: rbuf5 <= read_data;
                            4'd6: rbuf6 <= read_data;
                            default: rbuf7 <= read_data;
                        endcase
                        r_recv_cnt <= r_recv_cnt + 4'd1;
                    end
                end

                R_SEND: begin
                    if (read_ready && (r_recv_cnt < r_beats_total)) begin
                        case (r_recv_cnt)
                            4'd0: rbuf0 <= read_data;
                            4'd1: rbuf1 <= read_data;
                            4'd2: rbuf2 <= read_data;
                            4'd3: rbuf3 <= read_data;
                            4'd4: rbuf4 <= read_data;
                            4'd5: rbuf5 <= read_data;
                            4'd6: rbuf6 <= read_data;
                            default: rbuf7 <= read_data;
                        endcase
                        r_recv_cnt <= r_recv_cnt + 4'd1;
                    end

                    if (!sel_rvalid_now) begin
                        if (r_send_cnt < r_recv_cnt) begin
                            case (r_send_cnt)
                                4'd0: drive_rdata_port(cur_port, r_id, rbuf0, (r_err ? 2'b10 : 2'b00), (r_send_cnt == (r_beats_total - 1'b1)), 1'b1);
                                4'd1: drive_rdata_port(cur_port, r_id, rbuf1, (r_err ? 2'b10 : 2'b00), (r_send_cnt == (r_beats_total - 1'b1)), 1'b1);
                                4'd2: drive_rdata_port(cur_port, r_id, rbuf2, (r_err ? 2'b10 : 2'b00), (r_send_cnt == (r_beats_total - 1'b1)), 1'b1);
                                4'd3: drive_rdata_port(cur_port, r_id, rbuf3, (r_err ? 2'b10 : 2'b00), (r_send_cnt == (r_beats_total - 1'b1)), 1'b1);
                                4'd4: drive_rdata_port(cur_port, r_id, rbuf4, (r_err ? 2'b10 : 2'b00), (r_send_cnt == (r_beats_total - 1'b1)), 1'b1);
                                4'd5: drive_rdata_port(cur_port, r_id, rbuf5, (r_err ? 2'b10 : 2'b00), (r_send_cnt == (r_beats_total - 1'b1)), 1'b1);
                                4'd6: drive_rdata_port(cur_port, r_id, rbuf6, (r_err ? 2'b10 : 2'b00), (r_send_cnt == (r_beats_total - 1'b1)), 1'b1);
                                default: drive_rdata_port(cur_port, r_id, rbuf7, (r_err ? 2'b10 : 2'b00), (r_send_cnt == (r_beats_total - 1'b1)), 1'b1);
                            endcase
                        end
                    end

                    if (sel_rvalid_now && sel_rready) begin
                        drop_rvalid_port(cur_port);
                        r_send_cnt <= r_send_cnt + 4'd1;

                        if (r_send_cnt == (r_beats_total - 1'b1)) begin
                            st <= IDLE;
                        end
                    end
                end

                default: begin
                    st <= IDLE;
                end
            endcase
        end
    end

endmodule