/*
NISHIHARU — SDRAM Controller AXI4 5-port Slave
- 5x AXI4-S (32-bit) -> Single SDRAM controller
- INCR only, SIZE=2(4B), LEN={0,1,3,7}. The video read port also
  accepts naturally aligned bursts of 16 and 32 words.
*/
`timescale 1ns/1ps

module ddr3_axi_controller #(
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

    // -------- Port 4 (video port) --------
    input  wire [ID_WIDTH-1:0]       s4_axi_awid,
    input  wire [ADDR_WIDTH-1:0]     s4_axi_awaddr,
    input  wire [7:0]                s4_axi_awlen,
    input  wire [2:0]                s4_axi_awsize,
    input  wire [1:0]                s4_axi_awburst,
    input  wire                      s4_axi_awvalid,
    output reg                       s4_axi_awready,

    input  wire [DATA_WIDTH-1:0]     s4_axi_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] s4_axi_wstrb,
    input  wire                      s4_axi_wlast,
    input  wire                      s4_axi_wvalid,
    output reg                       s4_axi_wready,

    output reg  [ID_WIDTH-1:0]       s4_axi_bid,
    output reg  [1:0]                s4_axi_bresp,
    output reg                       s4_axi_bvalid,
    input  wire                      s4_axi_bready,

    input  wire [ID_WIDTH-1:0]       s4_axi_arid,
    input  wire [ADDR_WIDTH-1:0]     s4_axi_araddr,
    input  wire [7:0]                s4_axi_arlen,
    input  wire [2:0]                s4_axi_arsize,
    input  wire [1:0]                s4_axi_arburst,
    input  wire                      s4_axi_arvalid,
    output reg                       s4_axi_arready,

    output reg  [ID_WIDTH-1:0]       s4_axi_rid,
    output reg  [DATA_WIDTH-1:0]     s4_axi_rdata,
    output reg  [1:0]                s4_axi_rresp,
    output reg                       s4_axi_rlast,
    output reg                       s4_axi_rvalid,
    input  wire                      s4_axi_rready,

    // -------- DDR3 controller --------
    input  wire                     app_rdy,
    input  wire                     app_rd_data_valid,
    input  wire                     wr_data_rdy,
    input  wire [255:0]             app_rd_data,
    input  wire                     init_calib_complete,

    output wire                     app_en,
    output wire [2:0]               app_cmd,
    output wire [28:0]              app_addr,
    output wire [255:0]             app_wdf_data,
    output wire                     app_wdf_wren,
    output wire                     app_wdf_end,
    output wire [31:0]              app_wdf_mask,
    output wire                     app_burst,
    output wire                     sr_req,
    output wire                     ref_req,
    output wire                     error
);

    // ============================================================
    // DDR3 controller IF
    // ============================================================
    wire req_ready, read_ready, write_ready;
    reg read_valid, write_valid;
    reg [ADDR_WIDTH-1:0] read_addr, write_addr;
    reg [31:0] write_data;
    wire [31:0] read_data;
    reg [3:0] rw_length;

	localparam DRAM_NUM = 2'd2;

    wire legacy_en, video_fetch;
    wire [2:0] legacy_cmd;
    wire [28:0] legacy_addr;

    ddr3_controller_if #(
        .ADDR_WIDTH(29),
        .WORD_ADDR_WIDTH(ADDR_WIDTH),
        .APP_DATA_WIDTH(128*DRAM_NUM) ,     //APP_DATA_WIDTH=128
        .APP_MASK_WIDTH (16*DRAM_NUM),      //APP_MASK_WIDTH=16
        .USER_REFRESH("OFF")
    ) u_ddr3_controller_if (
        .clock              (aclk),
        .reset_n            (aresetn),
        .req_ready          (req_ready),
        .rw_length          (rw_length),
        .read_valid         (read_valid),
        .read_ready         (read_ready),
        .read_addr          (read_addr),
        .read_data          (read_data),
        .write_valid        (write_valid),
        .write_ready        (write_ready),
        .write_addr         (write_addr),
        .write_data         (write_data),
        .app_rdy            (app_rdy),
        .app_en             (legacy_en),
        .app_cmd            (legacy_cmd),
        .app_addr           (legacy_addr),
        .app_wdf_data       (app_wdf_data),
        .app_wdf_wren       (app_wdf_wren),
        .app_wdf_end        (app_wdf_end),
        .app_wdf_mask       (app_wdf_mask),
        .app_burst          (app_burst),
        .app_rd_data_valid  (app_rd_data_valid && !video_fetch),
        .app_rd_data        (app_rd_data),
        .init_calib_complete(init_calib_complete),
        .wr_data_rdy        (wr_data_rdy),
        .sr_req             (sr_req),
        .error              (error),
        .ref_req            (ref_req)
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
        R_SEND       = 4'd11,
        VIDEO_FETCH  = 4'd12,
        VIDEO_SEND   = 4'd13;

    reg [3:0] st;
    reg [2:0] cur_port;
    reg       cur_is_write;

    // Consecutive BL8 reads return in command order. Reserve all response
    // slots before issuing commands, so AXI backpressure cannot lose data.
    wire video_long_read = cur_port == 4 && s4_axi_arsize == 2 &&
                           s4_axi_arburst == 2'b01 && s4_axi_araddr[5:0] == 0 &&
                           (s4_axi_arlen == 15 ||
                            (s4_axi_arlen == 31 && !s4_axi_araddr[6]));
    reg [28:0] video_base_word;
    reg [2:0] video_groups, video_issued;
    reg [1:0] video_received;
    reg [4:0] video_next_word, video_last_word;
    reg [255:0] video_lines [0:3];
    assign video_fetch = st == VIDEO_FETCH;
    wire video_issue = aresetn && req_ready && app_rdy && video_issued < video_groups;
    assign app_en   = video_fetch ? video_issue : legacy_en;
    assign app_cmd  = video_fetch ? 3'b001 : legacy_cmd;
    // Each transaction starts at a multiple of its group count. OR selects
    // the next BL8 within that block without an address-width carry chain.
    assign app_addr = video_fetch ? video_base_word | {24'b0,video_issued[1:0],3'b0} : legacy_addr;

    always @(posedge aclk)
        if (video_fetch && app_rd_data_valid)
            video_lines[video_received] <= app_rd_data;

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
        (cur_port==3'd0) ? s0_axi_awid :
        (cur_port==3'd1) ? s1_axi_awid :
        (cur_port==3'd2) ? s2_axi_awid :
        (cur_port==3'd3) ? s3_axi_awid : s4_axi_awid;

    wire [ADDR_WIDTH-1:0] sel_awaddr =
        (cur_port==3'd0) ? s0_axi_awaddr :
        (cur_port==3'd1) ? s1_axi_awaddr :
        (cur_port==3'd2) ? s2_axi_awaddr :
        (cur_port==3'd3) ? s3_axi_awaddr : s4_axi_awaddr;

    wire [7:0] sel_awlen =
        (cur_port==3'd0) ? s0_axi_awlen :
        (cur_port==3'd1) ? s1_axi_awlen :
        (cur_port==3'd2) ? s2_axi_awlen :
        (cur_port==3'd3) ? s3_axi_awlen : s4_axi_awlen;

    wire [2:0] sel_awsize =
        (cur_port==3'd0) ? s0_axi_awsize :
        (cur_port==3'd1) ? s1_axi_awsize :
        (cur_port==3'd2) ? s2_axi_awsize :
        (cur_port==3'd3) ? s3_axi_awsize : s4_axi_awsize;

    wire [1:0] sel_awburst =
        (cur_port==3'd0) ? s0_axi_awburst :
        (cur_port==3'd1) ? s1_axi_awburst :
        (cur_port==3'd2) ? s2_axi_awburst :
        (cur_port==3'd3) ? s3_axi_awburst : s4_axi_awburst;

    wire [ID_WIDTH-1:0] sel_arid =
        (cur_port==3'd0) ? s0_axi_arid :
        (cur_port==3'd1) ? s1_axi_arid :
        (cur_port==3'd2) ? s2_axi_arid :
        (cur_port==3'd3) ? s3_axi_arid : s4_axi_arid;

    wire [ADDR_WIDTH-1:0] sel_araddr =
        (cur_port==3'd0) ? s0_axi_araddr :
        (cur_port==3'd1) ? s1_axi_araddr :
        (cur_port==3'd2) ? s2_axi_araddr :
        (cur_port==3'd3) ? s3_axi_araddr : s4_axi_araddr;

    wire [7:0] sel_arlen =
        (cur_port==3'd0) ? s0_axi_arlen :
        (cur_port==3'd1) ? s1_axi_arlen :
        (cur_port==3'd2) ? s2_axi_arlen :
        (cur_port==3'd3) ? s3_axi_arlen : s4_axi_arlen;

    wire [2:0] sel_arsize =
        (cur_port==3'd0) ? s0_axi_arsize :
        (cur_port==3'd1) ? s1_axi_arsize :
        (cur_port==3'd2) ? s2_axi_arsize :
        (cur_port==3'd3) ? s3_axi_arsize : s4_axi_arsize;

    wire [1:0] sel_arburst =
        (cur_port==3'd0) ? s0_axi_arburst :
        (cur_port==3'd1) ? s1_axi_arburst :
        (cur_port==3'd2) ? s2_axi_arburst :
        (cur_port==3'd3) ? s3_axi_arburst : s4_axi_arburst;

    wire sel_wvalid =
        (cur_port==3'd0) ? s0_axi_wvalid :
        (cur_port==3'd1) ? s1_axi_wvalid :
        (cur_port==3'd2) ? s2_axi_wvalid :
        (cur_port==3'd3) ? s3_axi_wvalid : s4_axi_wvalid;

    wire [DATA_WIDTH-1:0] sel_wdata =
        (cur_port==3'd0) ? s0_axi_wdata :
        (cur_port==3'd1) ? s1_axi_wdata :
        (cur_port==3'd2) ? s2_axi_wdata :
        (cur_port==3'd3) ? s3_axi_wdata : s4_axi_wdata;

    wire [(DATA_WIDTH/8)-1:0] sel_wstrb =
        (cur_port==3'd0) ? s0_axi_wstrb :
        (cur_port==3'd1) ? s1_axi_wstrb :
        (cur_port==3'd2) ? s2_axi_wstrb :
        (cur_port==3'd3) ? s3_axi_wstrb : s4_axi_wstrb;

    wire sel_wlast =
        (cur_port==3'd0) ? s0_axi_wlast :
        (cur_port==3'd1) ? s1_axi_wlast :
        (cur_port==3'd2) ? s2_axi_wlast :
        (cur_port==3'd3) ? s3_axi_wlast : s4_axi_wlast;

    wire sel_bready =
        (cur_port==3'd0) ? s0_axi_bready :
        (cur_port==3'd1) ? s1_axi_bready :
        (cur_port==3'd2) ? s2_axi_bready :
        (cur_port==3'd3) ? s3_axi_bready : s4_axi_bready;

    wire sel_rready =
        (cur_port==3'd0) ? s0_axi_rready :
        (cur_port==3'd1) ? s1_axi_rready :
        (cur_port==3'd2) ? s2_axi_rready :
        (cur_port==3'd3) ? s3_axi_rready : s4_axi_rready;

    wire sel_rvalid_now =
        (cur_port==3'd0) ? s0_axi_rvalid :
        (cur_port==3'd1) ? s1_axi_rvalid :
        (cur_port==3'd2) ? s2_axi_rvalid :
        (cur_port==3'd3) ? s3_axi_rvalid : s4_axi_rvalid;

    wire sel_wready_now =
        (cur_port==3'd0) ? s0_axi_wready :
        (cur_port==3'd1) ? s1_axi_wready :
        (cur_port==3'd2) ? s2_axi_wready :
        (cur_port==3'd3) ? s3_axi_wready : s4_axi_wready;

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
            s4_axi_awready <= 1'b0;

            s0_axi_wready  <= 1'b0;
            s1_axi_wready  <= 1'b0;
            s2_axi_wready  <= 1'b0;
            s3_axi_wready  <= 1'b0;
            s4_axi_wready  <= 1'b0;

            s0_axi_arready <= 1'b0;
            s1_axi_arready <= 1'b0;
            s2_axi_arready <= 1'b0;
            s3_axi_arready <= 1'b0;
            s4_axi_arready <= 1'b0;
        end
    endtask

    task set_awready_port;
        input [2:0] p;
        begin
            case (p)
                3'd0: s0_axi_awready <= 1'b1;
                3'd1: s1_axi_awready <= 1'b1;
                3'd2: s2_axi_awready <= 1'b1;
                3'd3: s3_axi_awready <= 1'b1;
                3'd4: s4_axi_awready <= 1'b1;
                default: ;
            endcase
        end
    endtask

    task set_arready_port;
        input [2:0] p;
        begin
            case (p)
                3'd0: s0_axi_arready <= 1'b1;
                3'd1: s1_axi_arready <= 1'b1;
                3'd2: s2_axi_arready <= 1'b1;
                3'd3: s3_axi_arready <= 1'b1;
                3'd4: s4_axi_arready <= 1'b1;
                default: ;
            endcase
        end
    endtask

    task set_wready_port;
        input [2:0] p;
        input       v;
        begin
            case (p)
                3'd0: s0_axi_wready <= v;
                3'd1: s1_axi_wready <= v;
                3'd2: s2_axi_wready <= v;
                3'd3: s3_axi_wready <= v;
                3'd4: s4_axi_wready <= v;
                default: ;
            endcase
        end
    endtask

    task drive_bresp_port;
        input [2:0] p;
        input [ID_WIDTH-1:0] id;
        input [1:0] resp;
        input set_valid;
        begin
            case (p)
                3'd0: begin s0_axi_bid <= id; s0_axi_bresp <= resp; s0_axi_bvalid <= set_valid; end
                3'd1: begin s1_axi_bid <= id; s1_axi_bresp <= resp; s1_axi_bvalid <= set_valid; end
                3'd2: begin s2_axi_bid <= id; s2_axi_bresp <= resp; s2_axi_bvalid <= set_valid; end
                3'd3: begin s3_axi_bid <= id; s3_axi_bresp <= resp; s3_axi_bvalid <= set_valid; end
                3'd4: begin s4_axi_bid <= id; s4_axi_bresp <= resp; s4_axi_bvalid <= set_valid; end
                default: ;
            endcase
        end
    endtask

    task drop_bvalid_port;
        input [2:0] p;
        begin
            case (p)
                3'd0: s0_axi_bvalid <= 1'b0;
                3'd1: s1_axi_bvalid <= 1'b0;
                3'd2: s2_axi_bvalid <= 1'b0;
                3'd3: s3_axi_bvalid <= 1'b0;
                3'd4: s4_axi_bvalid <= 1'b0;
                default: ;
            endcase
        end
    endtask

    task drive_rdata_port;
        input [2:0] p;
        input [ID_WIDTH-1:0] id;
        input [DATA_WIDTH-1:0] data;
        input [1:0] resp;
        input last;
        input set_valid;
        begin
            case (p)
                3'd0: begin s0_axi_rid <= id; s0_axi_rdata <= data; s0_axi_rresp <= resp; s0_axi_rlast <= last; s0_axi_rvalid <= set_valid; end
                3'd1: begin s1_axi_rid <= id; s1_axi_rdata <= data; s1_axi_rresp <= resp; s1_axi_rlast <= last; s1_axi_rvalid <= set_valid; end
                3'd2: begin s2_axi_rid <= id; s2_axi_rdata <= data; s2_axi_rresp <= resp; s2_axi_rlast <= last; s2_axi_rvalid <= set_valid; end
                3'd3: begin s3_axi_rid <= id; s3_axi_rdata <= data; s3_axi_rresp <= resp; s3_axi_rlast <= last; s3_axi_rvalid <= set_valid; end
                3'd4: begin s4_axi_rid <= id; s4_axi_rdata <= data; s4_axi_rresp <= resp; s4_axi_rlast <= last; s4_axi_rvalid <= set_valid; end
                default: ;
            endcase
        end
    endtask

    task drop_rvalid_port;
        input [2:0] p;
        begin
            case (p)
                3'd0: begin s0_axi_rvalid <= 1'b0; s0_axi_rlast <= 1'b0; end
                3'd1: begin s1_axi_rvalid <= 1'b0; s1_axi_rlast <= 1'b0; end
                3'd2: begin s2_axi_rvalid <= 1'b0; s2_axi_rlast <= 1'b0; end
                3'd3: begin s3_axi_rvalid <= 1'b0; s3_axi_rlast <= 1'b0; end
                3'd4: begin s4_axi_rvalid <= 1'b0; s4_axi_rlast <= 1'b0; end
                default: ;
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
            s4_axi_awready <= 1'b0;

            s0_axi_wready  <= 1'b0;
            s1_axi_wready  <= 1'b0;
            s2_axi_wready  <= 1'b0;
            s3_axi_wready  <= 1'b0;
            s4_axi_wready  <= 1'b0;

            s0_axi_bvalid <= 1'b0;
            s1_axi_bvalid <= 1'b0;
            s2_axi_bvalid <= 1'b0;
            s3_axi_bvalid <= 1'b0;
            s4_axi_bvalid <= 1'b0;

            s0_axi_bresp <= 2'b00;
            s1_axi_bresp <= 2'b00;
            s2_axi_bresp <= 2'b00;
            s3_axi_bresp <= 2'b00;
            s4_axi_bresp <= 2'b00;

            s0_axi_bid <= {ID_WIDTH{1'b0}};
            s1_axi_bid <= {ID_WIDTH{1'b0}};
            s2_axi_bid <= {ID_WIDTH{1'b0}};
            s3_axi_bid <= {ID_WIDTH{1'b0}};
            s4_axi_bid <= {ID_WIDTH{1'b0}};

            s0_axi_arready <= 1'b0;
            s1_axi_arready <= 1'b0;
            s2_axi_arready <= 1'b0;
            s3_axi_arready <= 1'b0;
            s4_axi_arready <= 1'b0;

            s0_axi_rvalid <= 1'b0;
            s1_axi_rvalid <= 1'b0;
            s2_axi_rvalid <= 1'b0;
            s3_axi_rvalid <= 1'b0;
            s4_axi_rvalid <= 1'b0;

            s0_axi_rresp <= 2'b00;
            s1_axi_rresp <= 2'b00;
            s2_axi_rresp <= 2'b00;
            s3_axi_rresp <= 2'b00;
            s4_axi_rresp <= 2'b00;

            s0_axi_rid <= {ID_WIDTH{1'b0}};
            s1_axi_rid <= {ID_WIDTH{1'b0}};
            s2_axi_rid <= {ID_WIDTH{1'b0}};
            s3_axi_rid <= {ID_WIDTH{1'b0}};
            s4_axi_rid <= {ID_WIDTH{1'b0}};

            s0_axi_rdata <= {DATA_WIDTH{1'b0}};
            s1_axi_rdata <= {DATA_WIDTH{1'b0}};
            s2_axi_rdata <= {DATA_WIDTH{1'b0}};
            s3_axi_rdata <= {DATA_WIDTH{1'b0}};
            s4_axi_rdata <= {DATA_WIDTH{1'b0}};

            s0_axi_rlast <= 1'b0;
            s1_axi_rlast <= 1'b0;
            s2_axi_rlast <= 1'b0;
            s3_axi_rlast <= 1'b0;
            s4_axi_rlast <= 1'b0;

            read_valid  <= 1'b0;
            write_valid <= 1'b0;
            read_addr   <= {ADDR_WIDTH{1'b0}};
            write_addr  <= {ADDR_WIDTH{1'b0}};
            write_data  <= 32'h0000_0000;
            rw_length   <= 4'd0;

            video_base_word <= 0;
            video_groups <= 0;
            video_issued <= 0;
            video_received <= 0;
            video_next_word <= 0;
            video_last_word <= 0;
            st           <= IDLE;
            cur_port     <= 3'd0;
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
                    if      (s0_axi_awvalid) begin cur_port <= 3'd0; cur_is_write <= 1'b1; st <= W_AW; end
                    else if (s0_axi_arvalid) begin cur_port <= 3'd0; cur_is_write <= 1'b0; st <= R_AR; end
                    else if (s1_axi_awvalid) begin cur_port <= 3'd1; cur_is_write <= 1'b1; st <= W_AW; end
                    else if (s1_axi_arvalid) begin cur_port <= 3'd1; cur_is_write <= 1'b0; st <= R_AR; end
                    else if (s2_axi_awvalid) begin cur_port <= 3'd2; cur_is_write <= 1'b1; st <= W_AW; end
                    else if (s2_axi_arvalid) begin cur_port <= 3'd2; cur_is_write <= 1'b0; st <= R_AR; end
                    else if (s3_axi_awvalid) begin cur_port <= 3'd3; cur_is_write <= 1'b1; st <= W_AW; end
                    else if (s3_axi_arvalid) begin cur_port <= 3'd3; cur_is_write <= 1'b0; st <= R_AR; end
                    else if (s4_axi_awvalid) begin cur_port <= 3'd4; cur_is_write <= 1'b1; st <= W_AW; end
                    else if (s4_axi_arvalid) begin cur_port <= 3'd4; cur_is_write <= 1'b0; st <= R_AR; end

                    w_err <= 1'b0;
                    r_err <= 1'b0;
                end

                W_AW: begin
                    set_awready_port(cur_port);

                    if ((cur_port==3'd0 && s0_axi_awvalid) ||
                        (cur_port==3'd1 && s1_axi_awvalid) ||
                        (cur_port==3'd2 && s2_axi_awvalid) ||
                        (cur_port==3'd3 && s3_axi_awvalid) ||
                        (cur_port==3'd4 && s4_axi_awvalid)) begin

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

                        // Gowin EDA V1.9.12.03 synthesis bug workaround:
                        // In the multiport configuration, (sel_wstrb != 4'b1111)
                        // was synthesized as constant 1 even when sel_wstrb=4'hf,
                        // causing a writeback bus fault (RTL simulation passed).
                        // Reduction NAND preserves the full-byte-enable check
                        // for this 32-bit interface and avoids the miscompilation.
                        w_err <= w_err ||
                                 (~&sel_wstrb) ||
                                 (sel_wlast != (w_cnt == (w_beats_total - 1'b1)));

                        if (w_cnt == (w_beats_total - 1'b1)) begin
                            set_wready_port(cur_port, 1'b0);
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

                    if ((cur_port==3'd0 && s0_axi_arvalid) ||
                        (cur_port==3'd1 && s1_axi_arvalid) ||
                        (cur_port==3'd2 && s2_axi_arvalid) ||
                        (cur_port==3'd3 && s3_axi_arvalid) ||
                        (cur_port==3'd4 && s4_axi_arvalid)) begin

                        r_id          <= sel_arid;
                        r_base_word   <= {2'b00, sel_araddr[ADDR_WIDTH-1:2]};   // word addressへ変換
                        r_cur_word    <= {2'b00, sel_araddr[ADDR_WIDTH-1:2]};   // word addressへ変換
                        r_beats_total <= len_to_beats(sel_arlen);
                        r_err         <= bad_ar(sel_arlen, sel_arsize, sel_arburst, sel_araddr[1:0]);
                        r_issue_cnt   <= 4'd0;
                        r_recv_cnt    <= 4'd0;
                        r_send_cnt    <= 4'd0;
                        if (video_long_read) begin
                            video_base_word <= s4_axi_araddr >> 2;
                            video_groups <= s4_axi_arlen == 31 ? 3'd4 : 3'd2;
                            video_issued <= 0;
                            video_received <= 0;
                            video_next_word <= 0;
                            video_last_word <= s4_axi_arlen[4:0];
                            st <= VIDEO_FETCH;
                        end else st <= R_WAIT_START;
                    end
                end

                VIDEO_FETCH: begin
                    if (video_issue) video_issued <= video_issued + 1'b1;
                    if (app_rd_data_valid) begin
                        video_received <= video_received + 1'b1;
                        if (video_received == video_last_word[4:3]) st <= VIDEO_SEND;
                    end
                end

                VIDEO_SEND: begin
                    if (s4_axi_rvalid && s4_axi_rready && s4_axi_rlast) begin
                        s4_axi_rvalid <= 0;
                        s4_axi_rlast <= 0;
                        st <= IDLE;
                    end else if (!s4_axi_rvalid || s4_axi_rready) begin
                        s4_axi_rvalid <= 1;
                        s4_axi_rid <= r_id;
                        s4_axi_rresp <= 2'b00;
                        s4_axi_rdata <= video_lines[video_next_word[4:3]][video_next_word[2:0]*32 +: 32];
                        s4_axi_rlast <= video_next_word == video_last_word;
                        video_next_word <= video_next_word + 1'b1;
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
