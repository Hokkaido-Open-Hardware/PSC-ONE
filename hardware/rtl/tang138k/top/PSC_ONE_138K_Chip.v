// ============================================================================
//  PSC_ONE_Chip  —  PSC-ONE SoC Top Module for Tang Mega 138K
// ----------------------------------------------------------------------------
//  Author : NISHIHARU
//  File   : PSC_ONE_Chip.v
//
//  Brief
//      Tang Mega 138K 向け PSC-ONE SoC トップレベルモジュール。
//      既存の PSC-ONE SoC を、外部 DDR3 メモリを使用する構成へ移植する。
//
//      Gowin PLL および DDR3 Memory Interface IP を接続し、
//      DDR3 のクロック生成、初期化、および物理インタフェースを構成する。
//      CPU、キャッシュ、Boot ROM、各種周辺回路との統合に向けて、
//      Program / Data / DMA / Boot ROM 用の AXI 配線を定義する。
//
//  Main Components
//      - Gowin PLL
//      - DDR3 Memory Interface IP
//      - Program / Data / DMA / Boot ROM AXI Wiring
//      - UART Loopback Test
//      - LED Output Test
//
//  Simulation
//      COCOTB_SIM selects the functional DDR3 application-port model.
//      Boot, DMA, instruction and data accesses use the board's AXI bridge.
// ============================================================================
`timescale 1ns / 1ps

// Phase Flow Engine OFF mode
//`define PFE_OFF

// Yosys mode
//`define YOSYS

module PSC_ONE_138K_Chip #(
    parameter integer CLK_FREQ           = 100,
    parameter integer ID_WIDTH           = 1,
    parameter integer DATA_WIDTH         = 32    // AXI Data bus. fixed 32bit Bus
)(
    // ==== RV32IS CPU IF ====
    input  wire         sys_clk,
    input  wire         sys_reset,

    // ---- LED ----
    output[7:0]         led,

    // ---- UART(RS-232C) ----
    input  wire         UART_RXD,
    output wire         UART_TXD,

    input  wire         gpio_uart_rx,
    output wire         gpio_uart_tx,

    // ---- SD-CARD I/F ----
    output wire         SD_D3,
    output wire         SD_CLK,
    output wire         SD_CMD,
    input  wire         SD_D0,  // sd_miso

    // ---- HDMI ----
    output wire [2:0]   tmds_d_p_0,
    output wire         tmds_clk_p_0,

`ifdef COCOTB_SIM
    // ---------------- PSC-ONE SW ----------------
    input wire          PSCONE_SW1,
    input wire          PSCONE_SW2,

    // ------------------ I2S ------------------
    output  wire        I2S_SCK,
    output  wire        I2S_WS,
    output  wire        I2S_LR,
    input  wire         I2S_SD,

    // ---------------- PSC-ONE LCD ----------------
    output wire         PSCONE_LCD_CS,
    output wire         PSCONE_LCD_RST,
    output wire         PSCONE_LCD_BL,
    output wire         PSCONE_LCD_DC,
    output wire         PSCONE_LCD_SCK,
    output wire         PSCONE_LCD_SDI,
    input  wire         PSCONE_LCD_SDO,

    // ---------------- PSC-ONE TP ----------------
    input  wire         PSCONE_TP_PEN,
    input  wire         PSCONE_TP_TDO,
    output wire         PSCONE_TP_TDI,
    output wire         PSCONE_TP_TCS,
    output wire         PSCONE_TP_TCK,

    // ------------------ Robot ------------------
    inout  wire         PSCONE_LV1,
    inout  wire         PSCONE_LV2,
    inout  wire         PSCONE_LV3,
    inout  wire         PSCONE_LV4,

`endif
    // ---------------- PSC-ONE DDR3 SDRAM I/F ----------------
    output [15-1:0]     ddr_addr,       //ROW_WIDTH=15
    output [3-1:0]      ddr_bank,       //BANK_WIDTH=3
    output              ddr_cs,
    output              ddr_ras,
    output              ddr_cas,
    output              ddr_we,
    output              ddr_ck,
    output              ddr_ck_n,
    output              ddr_cke,
    output              ddr_odt,
    output              ddr_reset_n,
    output [4-1:0]      ddr_dm,         //DM_WIDTH=2
    inout  [32-1:0]     ddr_dq,         //DQ_WIDTH=16
    inout  [4-1:0]      ddr_dqs,        //DQS_WIDTH=2
    inout  [4-1:0]      ddr_dqs_n       //DQS_WIDTH=2
);

    // LED
    wire [5:0] soc_led;
    assign led = {2'b00, soc_led};

    // --------------------------------
    // define 確認
    // --------------------------------
`ifdef COCOTB_SIM
    wire cocotb_sim_mode = 1'b1;
`endif
`ifdef TOP_SIM
    wire top_sim_mode = 1'b1;
    initial $display("TOP_SIM ENABLE");
`ifndef PSCOS_NO_SDCARD
    `define SPI_BYPASS
    initial $display("SDCard SPI_BYPASS ENABLE");
`endif
`endif
`ifdef PSCOS_SIM
    wire os_sim_mode = 1'b1;
    initial $display("PSCOS_SIM ENABLE");
`endif
`ifdef FST_UART_MODE
    wire fst_uart_mode = 1'b1;
    initial $display("FST_UART_MODE ENABLE");
`endif
`ifdef FPGA_BOOT_LOADER_MODE
    wire fpga_boot_loader_mode = 1'b1;
    initial $display("FPGA_BOOT_LOADER_MODE ENABLE");
`endif
`ifdef INIT_CLEAR_MEM_BANKS
    wire init_clear_mem_banks_mode = 1'b1;
    initial $display("INIT_CLEAR_MEM_BANKS ENABLE");
`endif
    initial $display("========================");

    // --------------------------------
    // オープンドレイン
    // --------------------------------
    // 1 = Lowを出力、0 = Hi-Z
`ifdef COCOTB_SIM
    wire [3:0] lv_drive_low;
    wire i2c_sda_drive_low;
    // I2C slave on LV3=SCL, LV4=SDA; release SCL and unused pins.
    assign lv_drive_low = {i2c_sda_drive_low, 1'b0, 2'b00};

    // 外部ピン
    assign PSCONE_LV1 = lv_drive_low[0] ? 1'b0 : 1'bz;
    assign PSCONE_LV2 = lv_drive_low[1] ? 1'b0 : 1'bz;
    assign PSCONE_LV3 = lv_drive_low[2] ? 1'b0 : 1'bz;
    assign PSCONE_LV4 = lv_drive_low[3] ? 1'b0 : 1'bz;

    // 入力値
    wire [3:0] lv_input;

    assign lv_input = {
        PSCONE_LV4,
        PSCONE_LV3,
        PSCONE_LV2,
        PSCONE_LV1
    };

`endif
    // --------------------------------
    // 内部クロック/リセット
    // --------------------------------

    wire clock_100MHz;
    wire clk_x1;
    wire clk = clk_x1;
`ifdef COCOTB_SIM
    assign clock_100MHz = sys_clk;
    assign clk_x1       = sys_clk;
`else
    wire memory_clk, pll_lock, pll_stop;
    Gowin_PLL Gowin_PLL_inst (
        .lock       (pll_lock), 
        .clkout0    (clock_100MHz), 
        .clkout1    (), 
        .clkout2    (memory_clk),
        .clkin      (sys_clk), 


        .init_clk   (sys_clk), 
        .reset      (~sys_reset),
        .enclk0     (1'b1), 
        .enclk1     (1'b1), 
        .enclk2     (pll_stop)
    );
`endif

`ifdef COCOTB_SIM
    wire reset_n = ~sys_reset;   // The shared testbench asserts rst high.
`else
    wire reset_n = sys_reset;    // The board reset button is active low.
`endif
    wire cpu_stop;

    // cpu_stop: 30CLK 遅延
    wire    Boot_rom_done;
    delay_n #(.N(30), .WIDTH(1)) u_dly1 (
        .clk        (clk), 
        .reset_n    (reset_n),
        .din        (~Boot_rom_done),
        .dout       (cpu_stop)
    );   

    // =========================================================
    // DDR3_Memory_Interface_Top
    // =========================================================
    wire app_rdy, app_en, app_wdf_rdy, app_wdf_wren, app_wdf_end;
    wire app_rd_data_valid, app_burst, init_calib_complete, err;
    wire [2:0] app_cmd;
    wire [28:0] app_addr;
    wire [255:0] app_wdf_data, app_rd_data;
    wire [31:0] app_wdf_mask;
    wire sr_req, ref_req;

`ifdef COCOTB_SIM
    ddr3_app_model u_ddr3 (
        .clk(clk), .rst_n(reset_n), .init_calib_complete(init_calib_complete),
        .cmd_ready(app_rdy), .cmd_en(app_en), .cmd(app_cmd), .addr(app_addr),
        .wr_data_rdy(app_wdf_rdy), .wr_data_en(app_wdf_wren),
        .wr_data_end(app_wdf_end), .wr_data(app_wdf_data), .wr_data_mask(app_wdf_mask),
        .rd_data(app_rd_data), .rd_data_valid(app_rd_data_valid)
    );
`else
    DDR3_Memory_Interface_Top u_ddr3 (
        .memory_clk      (memory_clk),
        .pll_stop        (pll_stop),
        .clk             (clock_100MHz),
        .rst_n           (reset_n),   //rst_n
        //.app_burst_number(0),
        .cmd_ready       (app_rdy),
        .cmd             (app_cmd),
        .cmd_en          (app_en),
        .addr            (app_addr),
        .wr_data_rdy     (app_wdf_rdy),
        .wr_data         (app_wdf_data),
        .wr_data_en      (app_wdf_wren),
        .wr_data_end     (app_wdf_end),
        .wr_data_mask    (app_wdf_mask),
        .rd_data         (app_rd_data),
        .rd_data_valid   (app_rd_data_valid),
        .rd_data_end     (),
        .sr_req          (1'b0),
        .ref_req         (1'b0),
        .sr_ack          (),
        .ref_ack         (),
        .init_calib_complete(init_calib_complete),
        .clk_out         (clk_x1),
        .pll_lock        (pll_lock), 
        //.pll_lock        (1'b1), 
        //`ifdef ECC
        //.ecc_err         (ecc_err),
        //`endif
        .burst           (app_burst),
        // mem interface
        .ddr_rst         (),
        .O_ddr_addr      (ddr_addr),
        .O_ddr_ba        (ddr_bank),
        .O_ddr_cs_n      (ddr_cs),
        .O_ddr_ras_n     (ddr_ras),
        .O_ddr_cas_n     (ddr_cas),
        .O_ddr_we_n      (ddr_we),
        .O_ddr_clk       (ddr_ck),
        .O_ddr_clk_n     (ddr_ck_n),
        .O_ddr_cke       (ddr_cke),
        .O_ddr_odt       (ddr_odt),
        .O_ddr_reset_n   (ddr_reset_n),
        .O_ddr_dqm       (ddr_dm),
        .IO_ddr_dq       (ddr_dq),
        .IO_ddr_dqs      (ddr_dqs),
        .IO_ddr_dqs_n    (ddr_dqs_n)
    );
`endif

    // =========================================================
    // Program-side AXI (32-bit) — SLAVE-facing ports of DUT
    // Declare wires and connect them to your AXI master/bridge.
    // =========================================================
    localparam ADDR_W = 32;
    localparam ID_W   = 1;
    localparam DW     = 32;

    // Write Address
    wire [ID_W-1:0]         p_axi_awid;
    wire [ADDR_W-1:0]       p_axi_awaddr;
    wire [7:0]              p_axi_awlen;
    wire [2:0]              p_axi_awsize;
    wire [1:0]              p_axi_awburst;
    wire                    p_axi_awvalid;
    wire                    p_axi_awready;

    // Write Data
    wire [DW-1:0]           p_axi_wdata;
    wire [(DW/8)-1:0]       p_axi_wstrb;
    wire                    p_axi_wlast;
    wire                    p_axi_wvalid;
    wire                    p_axi_wready;

    // Write Response
    wire [ID_W-1:0]         p_axi_bid;
    wire [1:0]              p_axi_bresp;
    wire                    p_axi_bvalid;
    wire                    p_axi_bready;

    // Read Address
    wire [ID_W-1:0]         p_axi_arid;
    wire [ADDR_W-1:0]       p_axi_araddr;
    wire [7:0]              p_axi_arlen;
    wire [2:0]              p_axi_arsize;
    wire [1:0]              p_axi_arburst;
    wire                    p_axi_arvalid;
    wire                    p_axi_arready;

    // Read Data
    wire [ID_W-1:0]         p_axi_rid;
    wire [DW-1:0]           p_axi_rdata;
    wire [1:0]              p_axi_rresp;
    wire                    p_axi_rlast;
    wire                    p_axi_rvalid;
    wire                    p_axi_rready;

    // =========================================================
    // Data-side AXI (16-bit) — SLAVE-facing ports of DUT
    // =========================================================
    wire [ID_W-1:0]         u_axi_awid;
    wire [ADDR_W-1:0]       u_axi_awaddr;
    wire [7:0]              u_axi_awlen;
    wire [2:0]              u_axi_awsize;
    wire [1:0]              u_axi_awburst;
    wire                    u_axi_awvalid;
    wire                    u_axi_awready;

    wire [DW-1:0]           u_axi_wdata;
    wire [(DW/8)-1:0]       u_axi_wstrb;
    wire                    u_axi_wlast;
    wire                    u_axi_wvalid;
    wire                    u_axi_wready;

    wire [ID_W-1:0]         u_axi_bid;
    wire [1:0]              u_axi_bresp;
    wire                    u_axi_bvalid;
    wire                    u_axi_bready;

    wire [ID_W-1:0]         u_axi_arid;
    wire [ADDR_W-1:0]       u_axi_araddr;
    wire [7:0]              u_axi_arlen;
    wire [2:0]              u_axi_arsize;
    wire [1:0]              u_axi_arburst;
    wire                    u_axi_arvalid;
    wire                    u_axi_arready;

    wire [ID_W-1:0]         u_axi_rid;
    wire [DW-1:0]           u_axi_rdata;
    wire [1:0]              u_axi_rresp;
    wire                    u_axi_rlast;
    wire                    u_axi_rvalid;
    wire                    u_axi_rready;

    // =========================================================
    // SA module to AXI
    // =========================================================
    // Write Address
    wire [ID_W-1:0]         dma_axi_awid;
    wire [ADDR_W-1:0]       dma_axi_awaddr;
    wire [7:0]              dma_axi_awlen;
    wire [2:0]              dma_axi_awsize;
    wire [1:0]              dma_axi_awburst;
    wire                    dma_axi_awvalid;
    wire                    dma_axi_awready;

    // Write Data
    wire [DW-1:0]           dma_axi_wdata;
    wire [(DW/8)-1:0]       dma_axi_wstrb;
    wire                    dma_axi_wlast;
    wire                    dma_axi_wvalid;
    wire                    dma_axi_wready;

    // Write Response
    wire [ID_W-1:0]         dma_axi_bid;
    wire [1:0]              dma_axi_bresp;
    wire                    dma_axi_bvalid;
    wire                    dma_axi_bready;

    // Read Address
    wire [ID_W-1:0]         dma_axi_arid;
    wire [ADDR_W-1:0]       dma_axi_araddr;
    wire [7:0]              dma_axi_arlen;
    wire [2:0]              dma_axi_arsize;
    wire [1:0]              dma_axi_arburst;
    wire                    dma_axi_arvalid;
    wire                    dma_axi_arready;

    // Read Data
    wire [ID_W-1:0]         dma_axi_rid;
    wire [DW-1:0]           dma_axi_rdata;
    wire [1:0]              dma_axi_rresp;
    wire                    dma_axi_rlast;
    wire                    dma_axi_rvalid;
    wire                    dma_axi_rready;

    // =========================================================
    // Boot Rom to AXI
    // =========================================================
    // Write Address
    wire [ID_W-1:0]         bt_axi_awid;
    wire [ADDR_W-1:0]       bt_axi_awaddr;
    wire [7:0]              bt_axi_awlen;
    wire [2:0]              bt_axi_awsize;
    wire [1:0]              bt_axi_awburst;
    wire                    bt_axi_awvalid;
    wire                    bt_axi_awready;

    // Write Data
    wire [DW-1:0]           bt_axi_wdata;
    wire [(DW/8)-1:0]       bt_axi_wstrb;
    wire                    bt_axi_wlast;
    wire                    bt_axi_wvalid;
    wire                    bt_axi_wready;

    // Write Response
    wire [ID_W-1:0]         bt_axi_bid;
    wire [1:0]              bt_axi_bresp;
    wire                    bt_axi_bvalid;
    wire                    bt_axi_bready;

    // Read Address
    wire [ID_W-1:0]         bt_axi_arid;
    wire [ADDR_W-1:0]       bt_axi_araddr;
    wire [7:0]              bt_axi_arlen;
    wire [2:0]              bt_axi_arsize;
    wire [1:0]              bt_axi_arburst;
    wire                    bt_axi_arvalid;
    wire                    bt_axi_arready;

    // Read Data
    wire [ID_W-1:0]         bt_axi_rid;
    wire [DW-1:0]           bt_axi_rdata;
    wire [1:0]              bt_axi_rresp;
    wire                    bt_axi_rlast;
    wire                    bt_axi_rvalid;
    wire                    bt_axi_rready;

    //==========================================================
    // AXI But Sdram I/F
    //==========================================================
    wire sdram_init_fin = init_calib_complete;
    ddr3_axi_controller #(
        .CLK_FREQ_MHz       (CLK_FREQ),
        .ADDR_WIDTH         (24),
        .DATA_WIDTH         (DATA_WIDTH),
        .ID_WIDTH           (ID_WIDTH)
    ) u_4port_ddr3_axi (
        .aclk               (clk_x1),
        .aresetn            (reset_n),

        // ==== ch:0 (CPU) ====
        // AXI4 Write Address
        .s0_axi_awid        (p_axi_awid),
        .s0_axi_awaddr      (p_axi_awaddr[23:0]),   // 下位24bitへスライス
        .s0_axi_awlen       (p_axi_awlen),
        .s0_axi_awsize      (p_axi_awsize),
        .s0_axi_awburst     (p_axi_awburst),
        .s0_axi_awvalid     (p_axi_awvalid),
        .s0_axi_awready     (p_axi_awready),

        // AXI4 Write Data
        .s0_axi_wdata       (p_axi_wdata),
        .s0_axi_wstrb       (p_axi_wstrb),
        .s0_axi_wlast       (p_axi_wlast),
        .s0_axi_wvalid      (p_axi_wvalid),
        .s0_axi_wready      (p_axi_wready),

        // AXI4 Write Response
        .s0_axi_bid         (p_axi_bid),
        .s0_axi_bresp       (p_axi_bresp),
        .s0_axi_bvalid      (p_axi_bvalid),
        .s0_axi_bready      (p_axi_bready),

        // AXI4 Read Address
        .s0_axi_arid        (p_axi_arid),
        .s0_axi_araddr      (p_axi_araddr[23:0]),
        .s0_axi_arlen       (p_axi_arlen),
        .s0_axi_arsize      (p_axi_arsize),
        .s0_axi_arburst     (p_axi_arburst),
        .s0_axi_arvalid     (p_axi_arvalid),
        .s0_axi_arready     (p_axi_arready),

        // AXI4 Read Data
        .s0_axi_rid         (p_axi_rid),
        .s0_axi_rdata       (p_axi_rdata),
        .s0_axi_rresp       (p_axi_rresp),
        .s0_axi_rlast       (p_axi_rlast),
        .s0_axi_rvalid      (p_axi_rvalid),
        .s0_axi_rready      (p_axi_rready),

        // ==== ch:0 (USER LOGIC) ====
        // AXI4 Write Address
        .s1_axi_awid        (u_axi_awid),
        .s1_axi_awaddr      (u_axi_awaddr[23:0]),   // 下位24bitへスライス
        .s1_axi_awlen       (u_axi_awlen),
        .s1_axi_awsize      (u_axi_awsize),
        .s1_axi_awburst     (u_axi_awburst),
        .s1_axi_awvalid     (u_axi_awvalid),
        .s1_axi_awready     (u_axi_awready),

        // AXI4 Write Data
        .s1_axi_wdata       (u_axi_wdata),
        .s1_axi_wstrb       (u_axi_wstrb),
        .s1_axi_wlast       (u_axi_wlast),
        .s1_axi_wvalid      (u_axi_wvalid),
        .s1_axi_wready      (u_axi_wready),

        // AXI4 Write Response
        .s1_axi_bid         (u_axi_bid),
        .s1_axi_bresp       (u_axi_bresp),
        .s1_axi_bvalid      (u_axi_bvalid),
        .s1_axi_bready      (u_axi_bready),

        // AXI4 Read Address
        .s1_axi_arid        (u_axi_arid),
        .s1_axi_araddr      (u_axi_araddr[23:0]),
        .s1_axi_arlen       (u_axi_arlen),
        .s1_axi_arsize      (u_axi_arsize),
        .s1_axi_arburst     (u_axi_arburst),
        .s1_axi_arvalid     (u_axi_arvalid),
        .s1_axi_arready     (u_axi_arready),

        // AXI4 Read Data
        .s1_axi_rid         (u_axi_rid),
        .s1_axi_rdata       (u_axi_rdata),
        .s1_axi_rresp       (u_axi_rresp),
        .s1_axi_rlast       (u_axi_rlast),
        .s1_axi_rvalid      (u_axi_rvalid),
        .s1_axi_rready      (u_axi_rready),

        // ==== ch:2 (DMA) ====
        // AXI4 Write Address
        .s2_axi_awid        (dma_axi_awid),
        .s2_axi_awaddr      (dma_axi_awaddr[23:0]),   // 下位24bitへスライス
        .s2_axi_awlen       (dma_axi_awlen),
        .s2_axi_awsize      (dma_axi_awsize),
        .s2_axi_awburst     (dma_axi_awburst),
        .s2_axi_awvalid     (dma_axi_awvalid),
        .s2_axi_awready     (dma_axi_awready),

        // AXI4 Write Data
        .s2_axi_wdata       (dma_axi_wdata),
        .s2_axi_wstrb       (dma_axi_wstrb),
        .s2_axi_wlast       (dma_axi_wlast),
        .s2_axi_wvalid      (dma_axi_wvalid),
        .s2_axi_wready      (dma_axi_wready),

        // AXI4 Write Response
        .s2_axi_bid         (dma_axi_bid),
        .s2_axi_bresp       (dma_axi_bresp),
        .s2_axi_bvalid      (dma_axi_bvalid),
        .s2_axi_bready      (dma_axi_bready),

        // AXI4 Read Address
        .s2_axi_arid        (dma_axi_arid),
        .s2_axi_araddr      (dma_axi_araddr[23:0]),
        .s2_axi_arlen       (dma_axi_arlen),
        .s2_axi_arsize      (dma_axi_arsize),
        .s2_axi_arburst     (dma_axi_arburst),
        .s2_axi_arvalid     (dma_axi_arvalid),
        .s2_axi_arready     (dma_axi_arready),

        // AXI4 Read Data
        .s2_axi_rid         (dma_axi_rid),
        .s2_axi_rdata       (dma_axi_rdata),
        .s2_axi_rresp       (dma_axi_rresp),
        .s2_axi_rlast       (dma_axi_rlast),
        .s2_axi_rvalid      (dma_axi_rvalid),
        .s2_axi_rready      (dma_axi_rready),

        // ==== ch:3 ====
        // AXI4 Write Address
        .s3_axi_awid        (bt_axi_awid),
        .s3_axi_awaddr      (bt_axi_awaddr[23:0]),   // 下位24bitへスライス
        .s3_axi_awlen       (bt_axi_awlen),
        .s3_axi_awsize      (bt_axi_awsize),
        .s3_axi_awburst     (bt_axi_awburst),
        .s3_axi_awvalid     (bt_axi_awvalid),
        .s3_axi_awready     (bt_axi_awready),

        // AXI4 Write Data
        .s3_axi_wdata       (bt_axi_wdata),
        .s3_axi_wstrb       (bt_axi_wstrb),
        .s3_axi_wlast       (bt_axi_wlast),
        .s3_axi_wvalid      (bt_axi_wvalid),
        .s3_axi_wready      (bt_axi_wready),

        // AXI4 Write Response
        .s3_axi_bid         (bt_axi_bid),
        .s3_axi_bresp       (bt_axi_bresp),
        .s3_axi_bvalid      (bt_axi_bvalid),
        .s3_axi_bready      (bt_axi_bready),

        // AXI4 Read Address
        .s3_axi_arid        (bt_axi_arid),
        .s3_axi_araddr      (bt_axi_araddr[23:0]),
        .s3_axi_arlen       (bt_axi_arlen),
        .s3_axi_arsize      (bt_axi_arsize),
        .s3_axi_arburst     (bt_axi_arburst),
        .s3_axi_arvalid     (bt_axi_arvalid),
        .s3_axi_arready     (bt_axi_arready),

        // AXI4 Read Data
        .s3_axi_rid         (bt_axi_rid),
        .s3_axi_rdata       (bt_axi_rdata),
        .s3_axi_rresp       (bt_axi_rresp),
        .s3_axi_rlast       (bt_axi_rlast),
        .s3_axi_rvalid      (bt_axi_rvalid),
        .s3_axi_rready      (bt_axi_rready),

        // ==== DDR3 SDRAM controller IF ====
        // mem interface
        .app_rdy            (app_rdy),
        .app_en             (app_en),
        .app_cmd            (app_cmd),
        .app_addr           (app_addr),
        .app_wdf_data       (app_wdf_data),
        .app_wdf_wren       (app_wdf_wren),
        .app_wdf_end        (app_wdf_end),
        .app_wdf_mask       (app_wdf_mask),
        .app_burst          (app_burst),
        .app_rd_data_valid  (app_rd_data_valid),
        .app_rd_data        (app_rd_data), 
        .init_calib_complete(init_calib_complete),
        .wr_data_rdy        (app_wdf_rdy),
        .sr_req             (sr_req),
        .error              (err),
        .ref_req            (ref_req)
    );

    //==========================================================
    // PSC-ONE SOC TOP
    //==========================================================
    PSC_ONE_SOC #(
        .CLK_FREQ           (CLK_FREQ),
        .ADDR_WIDTH         (32),
        .ID_WIDTH           (ID_WIDTH),
        .DATA_WIDTH         (DATA_WIDTH)
    ) u_soc (
        // Clock / Reset
        .clock              (clk_x1),
        .reset_n            (reset_n),
        .cpu_stop           (cpu_stop),
        .sdram_init_fin     (sdram_init_fin),
        .Boot_rom_done      (Boot_rom_done),

`ifdef COCOTB_SIM
        // UART
        .UART_RXD           (UART_RXD),
        .UART_TXD           (UART_TXD),

        // I2C
        .PSCONE_SCL         (lv_input[2]),
        .PSCONE_SDA         (lv_input[3]),
        .PSCONE_SDA_DRIVE_LOW(i2c_sda_drive_low),

        // Switch
        .PSCONE_SW1         (PSCONE_SW1),
        .PSCONE_SW2         (PSCONE_SW2),

        // I2S
        .I2S_SCK            (I2S_SCK),
        .I2S_WS             (I2S_WS),
        .I2S_LR             (I2S_LR),
        .I2S_SD             (I2S_SD),

        // SD Card
        .SD_D3              (SD_D3),
        .SD_CLK             (SD_CLK),
        .SD_CMD             (SD_CMD),
        .SD_D0              (SD_D0),

        // LCD
        .PSCONE_LCD_CS      (PSCONE_LCD_CS),
        .PSCONE_LCD_RST     (PSCONE_LCD_RST),
        .PSCONE_LCD_BL      (PSCONE_LCD_BL),
        .PSCONE_LCD_DC      (PSCONE_LCD_DC),
        .PSCONE_LCD_SCK     (PSCONE_LCD_SCK),
        .PSCONE_LCD_SDI     (PSCONE_LCD_SDI),
        .PSCONE_LCD_SDO     (PSCONE_LCD_SDO),

        // Touch Panel
        .PSCONE_TP_PEN      (PSCONE_TP_PEN),
        .PSCONE_TP_TDO      (PSCONE_TP_TDO),
        .PSCONE_TP_TDI      (PSCONE_TP_TDI),
        .PSCONE_TP_TCS      (PSCONE_TP_TCS),
        .PSCONE_TP_TCK      (PSCONE_TP_TCK),

`else
        // UART
        .UART_RXD           (gpio_uart_rx),
        .UART_TXD           (gpio_uart_tx),

        // I2C
        .PSCONE_SCL         (),
        .PSCONE_SDA         (),
        .PSCONE_SDA_DRIVE_LOW(),

        // Switch
        .PSCONE_SW1         (),
        .PSCONE_SW2         (),

        // I2S
        .I2S_SCK            (),
        .I2S_WS             (),
        .I2S_LR             (),
        .I2S_SD             (),

        // SD Card
        .SD_D3              (SD_D3),
        .SD_CLK             (SD_CLK),
        .SD_CMD             (SD_CMD),
        .SD_D0              (SD_D0),

        // LCD
        .PSCONE_LCD_CS      (),
        .PSCONE_LCD_RST     (),
        .PSCONE_LCD_BL      (),
        .PSCONE_LCD_DC      (),
        .PSCONE_LCD_SCK     (),
        .PSCONE_LCD_SDI     (),
        .PSCONE_LCD_SDO     (),

        // Touch Panel
        .PSCONE_TP_PEN      (),
        .PSCONE_TP_TDO      (),
        .PSCONE_TP_TDI      (),
        .PSCONE_TP_TCS      (),
        .PSCONE_TP_TCK      (),

`endif
        // LED
        .PSCONE_LED_OUT     (soc_led),

        // =========================================================
        // Program AXI
        // =========================================================

        // Write Address
        .p_axi_awid         (p_axi_awid),
        .p_axi_awaddr       (p_axi_awaddr),
        .p_axi_awlen        (p_axi_awlen),
        .p_axi_awsize       (p_axi_awsize),
        .p_axi_awburst      (p_axi_awburst),
        .p_axi_awvalid      (p_axi_awvalid),
        .p_axi_awready      (p_axi_awready),

        // Write Data
        .p_axi_wdata        (p_axi_wdata),
        .p_axi_wstrb        (p_axi_wstrb),
        .p_axi_wlast        (p_axi_wlast),
        .p_axi_wvalid       (p_axi_wvalid),
        .p_axi_wready       (p_axi_wready),

        // Write Response
        .p_axi_bid          (p_axi_bid),
        .p_axi_bresp        (p_axi_bresp),
        .p_axi_bvalid       (p_axi_bvalid),
        .p_axi_bready       (p_axi_bready),

        // Read Address
        .p_axi_arid         (p_axi_arid),
        .p_axi_araddr       (p_axi_araddr),
        .p_axi_arlen        (p_axi_arlen),
        .p_axi_arsize       (p_axi_arsize),
        .p_axi_arburst      (p_axi_arburst),
        .p_axi_arvalid      (p_axi_arvalid),
        .p_axi_arready      (p_axi_arready),

        // Read Data
        .p_axi_rid          (p_axi_rid),
        .p_axi_rdata        (p_axi_rdata),
        .p_axi_rresp        (p_axi_rresp),
        .p_axi_rlast        (p_axi_rlast),
        .p_axi_rvalid       (p_axi_rvalid),
        .p_axi_rready       (p_axi_rready),

        // =========================================================
        // DMA / SA AXI
        // =========================================================

        // Write Address
        .dma_axi_awid       (dma_axi_awid),
        .dma_axi_awaddr     (dma_axi_awaddr),
        .dma_axi_awlen      (dma_axi_awlen),
        .dma_axi_awsize     (dma_axi_awsize),
        .dma_axi_awburst    (dma_axi_awburst),
        .dma_axi_awvalid    (dma_axi_awvalid),
        .dma_axi_awready    (dma_axi_awready),

        // Write Data
        .dma_axi_wdata      (dma_axi_wdata),
        .dma_axi_wstrb      (dma_axi_wstrb),
        .dma_axi_wlast      (dma_axi_wlast),
        .dma_axi_wvalid     (dma_axi_wvalid),
        .dma_axi_wready     (dma_axi_wready),

        // Write Response
        .dma_axi_bid        (dma_axi_bid),
        .dma_axi_bresp      (dma_axi_bresp),
        .dma_axi_bvalid     (dma_axi_bvalid),
        .dma_axi_bready     (dma_axi_bready),

        // Read Address
        .dma_axi_arid       (dma_axi_arid),
        .dma_axi_araddr     (dma_axi_araddr),
        .dma_axi_arlen      (dma_axi_arlen),
        .dma_axi_arsize     (dma_axi_arsize),
        .dma_axi_arburst    (dma_axi_arburst),
        .dma_axi_arvalid    (dma_axi_arvalid),
        .dma_axi_arready    (dma_axi_arready),

        // Read Data
        .dma_axi_rid        (dma_axi_rid),
        .dma_axi_rdata      (dma_axi_rdata),
        .dma_axi_rresp      (dma_axi_rresp),
        .dma_axi_rlast      (dma_axi_rlast),
        .dma_axi_rvalid     (dma_axi_rvalid),
        .dma_axi_rready     (dma_axi_rready),

        // =========================================================
        // Boot ROM AXI
        // =========================================================

        // Write Address
        .bt_axi_awid        (bt_axi_awid),
        .bt_axi_awaddr      (bt_axi_awaddr),
        .bt_axi_awlen       (bt_axi_awlen),
        .bt_axi_awsize      (bt_axi_awsize),
        .bt_axi_awburst     (bt_axi_awburst),
        .bt_axi_awvalid     (bt_axi_awvalid),
        .bt_axi_awready     (bt_axi_awready),

        // Write Data
        .bt_axi_wdata       (bt_axi_wdata),
        .bt_axi_wstrb       (bt_axi_wstrb),
        .bt_axi_wlast       (bt_axi_wlast),
        .bt_axi_wvalid      (bt_axi_wvalid),
        .bt_axi_wready      (bt_axi_wready),

        // Write Response
        .bt_axi_bid         (bt_axi_bid),
        .bt_axi_bresp       (bt_axi_bresp),
        .bt_axi_bvalid      (bt_axi_bvalid),
        .bt_axi_bready      (bt_axi_bready),

        // Read Address
        .bt_axi_arid        (bt_axi_arid),
        .bt_axi_araddr      (bt_axi_araddr),
        .bt_axi_arlen       (bt_axi_arlen),
        .bt_axi_arsize      (bt_axi_arsize),
        .bt_axi_arburst     (bt_axi_arburst),
        .bt_axi_arvalid     (bt_axi_arvalid),
        .bt_axi_arready     (bt_axi_arready),

        // Read Data
        .bt_axi_rid         (bt_axi_rid),
        .bt_axi_rdata       (bt_axi_rdata),
        .bt_axi_rresp       (bt_axi_rresp),
        .bt_axi_rlast       (bt_axi_rlast),
        .bt_axi_rvalid      (bt_axi_rvalid),
        .bt_axi_rready      (bt_axi_rready)
    );

    //==========================================================
    // USER LOGIC
    //==========================================================
    USER_LOGIC #(
        .ADDR_WIDTH (32),
        .ID_WIDTH   (1),
        .DATA_WIDTH (32)
    ) u_user_logic (
        .clock         (clk_x1),
        .reset_n       (reset_n),

        // Write Address
        .u_axi_awid    (u_axi_awid),
        .u_axi_awaddr  (u_axi_awaddr),
        .u_axi_awlen   (u_axi_awlen),
        .u_axi_awsize  (u_axi_awsize),
        .u_axi_awburst (u_axi_awburst),
        .u_axi_awvalid (u_axi_awvalid),
        .u_axi_awready (u_axi_awready),

        // Write Data
        .u_axi_wdata   (u_axi_wdata),
        .u_axi_wstrb   (u_axi_wstrb),
        .u_axi_wlast   (u_axi_wlast),
        .u_axi_wvalid  (u_axi_wvalid),
        .u_axi_wready  (u_axi_wready),

        // Write Response
        .u_axi_bid     (u_axi_bid),
        .u_axi_bresp   (u_axi_bresp),
        .u_axi_bvalid  (u_axi_bvalid),
        .u_axi_bready  (u_axi_bready),

        // Read Address
        .u_axi_arid    (u_axi_arid),
        .u_axi_araddr  (u_axi_araddr),
        .u_axi_arlen   (u_axi_arlen),
        .u_axi_arsize  (u_axi_arsize),
        .u_axi_arburst (u_axi_arburst),
        .u_axi_arvalid (u_axi_arvalid),
        .u_axi_arready (u_axi_arready),

        // Read Data
        .u_axi_rid     (u_axi_rid),
        .u_axi_rdata   (u_axi_rdata),
        .u_axi_rresp   (u_axi_rresp),
        .u_axi_rlast   (u_axi_rlast),
        .u_axi_rvalid  (u_axi_rvalid),
        .u_axi_rready  (u_axi_rready)
    );

endmodule
