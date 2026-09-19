// ============================================================================
//  PSC_ONE_Chip  —  PSC-ONE SoC Top Module
// ----------------------------------------------------------------------------
//  Author : NISHIHARU
//  File   : PSC_ONE_Chip.v
//
//  Brief
//      PSC-ONE プロジェクト向け SoC トップレベルモジュール。
//      RV32 CPU コア、SDRAM コントローラ、キャッシュ、Boot ROM、
//      UART、Timer、LCD、SD Card、I2S、および SynapEngine AI
//      アクセラレータを統合する。
//
//      本モジュールは FPGA 実装およびシミュレーションの双方を対象とし、
//      外部 SDR SDRAM と各種メモリマップド I/O を接続する。
//      また cocotb テストベンチからアクセス可能な AXI インタフェースを
//      提供し、メモリ初期化やデバッグを容易にする。
//
//  Main Components
//      - PSC RV32 CPU Core
//      - SDR SDRAM Controller
//      - DMA Cache Controller
//      - Boot AXI Interface
//      - UART
//      - Timer
//      - LCD Controller
//      - SD Card Interface
//      - I2S Audio Interface
//      - SynapEngine AI Accelerator
//
//  Notes
//      - GW2AR 内蔵 SDR SDRAM (32bit) 対応
//      - PSC-ONE FPGA プラットフォーム向け
//      - cocotb / Verilator / Icarus Verilog シミュレーション対応
// ============================================================================
`timescale 1ns / 1ps

// Phase Flow Engine OFF mode
//`define PFE_OFF

// Yosys mode
//`define YOSYS

module PSC_ONE_Chip #(
    parameter integer CLK_FREQ           = 80,
    parameter integer SDRAM_ADDR_WIDTH   = 24,
    parameter integer ID_WIDTH           = 1,
    parameter integer DATA_WIDTH         = 32    // AXI Data bus. fixed 32bit Bus
)(
    // ==== RV32IS CPU IF ====
    input  wire         sys_clk,
    input  wire         sys_reset,

    // ---- UART(RS-232C) ----
    input  wire         UART_RXD,
    output wire         UART_TXD,

    // ---------------- PSC-ONE SW ----------------
    input wire          PSCONE_SW1,
    input wire          PSCONE_SW2,

    // ------------------ I2S ------------------
    output  wire        I2S_SCK,
    output  wire        I2S_WS,
    output  wire        I2S_LR,
    input  wire         I2S_SD,

    // ---- SD-CARD I/F ----
    output wire         SD_D3,
    output wire         SD_CLK,
    output wire         SD_CMD,
    input  wire         SD_D0,  // sd_miso

    // ---------------- PSC-ONE SDRAM I/F ----------------
    output wire         O_sdram_clk,
    output wire         O_sdram_cke,
    output wire         O_sdram_cs_n,           // chip select
    output wire         O_sdram_cas_n,          // columns address select
    output wire         O_sdram_ras_n,          // row address select
    output wire         O_sdram_wen_n,          // write enable

    inout  wire [31:0]  IO_sdram_dq,            // 32 bit bidirectional data bus
    output wire [10:0]  O_sdram_addr,           // 11 bit multiplexed address bus
    output wire [1:0]   O_sdram_ba,             // two banks
    output wire [3:0]   O_sdram_dqm,            // 32/4

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

    // ------------------ LEDs ------------------
    output wire [5:0]   PSCONE_LED_OUT
);

    // --------------------------------
    // define 確認
    // --------------------------------
`ifdef COCOTB_SIM
    wire cocotb_sim_mode = 1'b1;
`endif
`ifdef TOP_SIM
    wire top_sim_mode = 1'b1;
`endif
`ifdef OS_SIM
    wire os_sim_mode = 1'b1;
`endif
`ifdef FST_UART_MODE
    wire fst_uart_mode = 1'b1;
`endif
`ifdef FPGA_BOOT_LOADER_MODE
    wire fpga_boot_loader_mode = 1'b1;
`endif
`ifdef INIT_CLEAR_MEM_BANKS
    wire init_clear_mem_banks_mode = 1'b1;
`endif

    // --------------------------------
    // 内部クロック/リセット
    // --------------------------------

`ifdef COCOTB_SIM
    wire clock_100MHz = sys_clk;
    wire clk = clock_100MHz;
    assign O_sdram_clk = clock_100MHz;
`else
    // tang20k PLL
    Gowin_rPLL m_PLL(
        .clkout     (clock_100MHz),         //output clkout
        .clkoutp    (O_sdram_clk),      //output clkoutp
        .clkin      (sys_clk)               //input clkin
    );
    wire clk = clock_100MHz;
`endif

    wire reset_n = ~sys_reset;    // FPGAのrset端子
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
    wire [ID_W-1:0]         d_axi_awid;
    wire [ADDR_W-1:0]       d_axi_awaddr;
    wire [7:0]              d_axi_awlen;
    wire [2:0]              d_axi_awsize;
    wire [1:0]              d_axi_awburst;
    wire                    d_axi_awvalid;
    wire                    d_axi_awready;

    wire [DW-1:0]           d_axi_wdata;
    wire [(DW/8)-1:0]       d_axi_wstrb;
    wire                    d_axi_wlast;
    wire                    d_axi_wvalid;
    wire                    d_axi_wready;

    wire [ID_W-1:0]         d_axi_bid;
    wire [1:0]              d_axi_bresp;
    wire                    d_axi_bvalid;
    wire                    d_axi_bready;

    wire [ID_W-1:0]         d_axi_arid;
    wire [ADDR_W-1:0]       d_axi_araddr;
    wire [7:0]              d_axi_arlen;
    wire [2:0]              d_axi_arsize;
    wire [1:0]              d_axi_arburst;
    wire                    d_axi_arvalid;
    wire                    d_axi_arready;

    wire [ID_W-1:0]         d_axi_rid;
    wire [DW-1:0]           d_axi_rdata;
    wire [1:0]              d_axi_rresp;
    wire                    d_axi_rlast;
    wire                    d_axi_rvalid;
    wire                    d_axi_rready;

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
    //wire [1:0]          dummy_O_sdram_addr;
    wire   sdram_init_fin;
    assign O_sdram_cke   = 1'b1;

    sdram_axi_controller #(
        .CLK_FREQ_MHz       (CLK_FREQ),
        .ADDR_WIDTH         (SDRAM_ADDR_WIDTH),
        .DATA_WIDTH         (DATA_WIDTH),
        .ID_WIDTH           (ID_WIDTH)
    ) u_4port_sdram_axi (
        .aclk               (clk),
        .aresetn            (reset_n),

        // ==== ch:0 (Program) ====
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

        // ==== ch:0 (Data) ====
        // AXI4 Write Address
        .s1_axi_awid        (d_axi_awid),
        .s1_axi_awaddr      (d_axi_awaddr[23:0]),   // 下位24bitへスライス
        .s1_axi_awlen       (d_axi_awlen),
        .s1_axi_awsize      (d_axi_awsize),
        .s1_axi_awburst     (d_axi_awburst),
        .s1_axi_awvalid     (d_axi_awvalid),
        .s1_axi_awready     (d_axi_awready),

        // AXI4 Write Data
        .s1_axi_wdata       (d_axi_wdata),
        .s1_axi_wstrb       (d_axi_wstrb),
        .s1_axi_wlast       (d_axi_wlast),
        .s1_axi_wvalid      (d_axi_wvalid),
        .s1_axi_wready      (d_axi_wready),

        // AXI4 Write Response
        .s1_axi_bid         (d_axi_bid),
        .s1_axi_bresp       (d_axi_bresp),
        .s1_axi_bvalid      (d_axi_bvalid),
        .s1_axi_bready      (d_axi_bready),

        // AXI4 Read Address
        .s1_axi_arid        (d_axi_arid),
        .s1_axi_araddr      (d_axi_araddr[23:0]),
        .s1_axi_arlen       (d_axi_arlen),
        .s1_axi_arsize      (d_axi_arsize),
        .s1_axi_arburst     (d_axi_arburst),
        .s1_axi_arvalid     (d_axi_arvalid),
        .s1_axi_arready     (d_axi_arready),

        // AXI4 Read Data
        .s1_axi_rid         (d_axi_rid),
        .s1_axi_rdata       (d_axi_rdata),
        .s1_axi_rresp       (d_axi_rresp),
        .s1_axi_rlast       (d_axi_rlast),
        .s1_axi_rvalid      (d_axi_rvalid),
        .s1_axi_rready      (d_axi_rready),

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

        // ==== SDRAM to SDRAM_model ====
        // SDRAM pins
        .sdram_clk          (/*sdram_clk*/),    // FPGAでは位相調整する.
        .sdram_cs           (O_sdram_cs_n),
        .sdram_ras          (O_sdram_ras_n),
        .sdram_cas          (O_sdram_cas_n),
        .sdram_we           (O_sdram_wen_n),
        .sdram_adr          (O_sdram_addr), 
        .sdram_ba           (O_sdram_ba),
        .sdram_dqm          (O_sdram_dqm),
        .sdram_dq           (IO_sdram_dq),

        .sdram_init_fin     (sdram_init_fin)
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
        .clock              (clock_100MHz),
        .reset_n            (reset_n),
        .cpu_stop           (cpu_stop),
        .sdram_init_fin     (sdram_init_fin),
        .Boot_rom_done      (Boot_rom_done),

        // UART
        .UART_RXD           (UART_RXD),
        .UART_TXD           (UART_TXD),

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

        // LED
        .PSCONE_LED_OUT     (PSCONE_LED_OUT),

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
        // Data AXI
        // =========================================================

        // Write Address
        .d_axi_awid         (d_axi_awid),
        .d_axi_awaddr       (d_axi_awaddr),
        .d_axi_awlen        (d_axi_awlen),
        .d_axi_awsize       (d_axi_awsize),
        .d_axi_awburst      (d_axi_awburst),
        .d_axi_awvalid      (d_axi_awvalid),
        .d_axi_awready      (d_axi_awready),

        // Write Data
        .d_axi_wdata        (d_axi_wdata),
        .d_axi_wstrb        (d_axi_wstrb),
        .d_axi_wlast        (d_axi_wlast),
        .d_axi_wvalid       (d_axi_wvalid),
        .d_axi_wready       (d_axi_wready),

        // Write Response
        .d_axi_bid          (d_axi_bid),
        .d_axi_bresp        (d_axi_bresp),
        .d_axi_bvalid       (d_axi_bvalid),
        .d_axi_bready       (d_axi_bready),

        // Read Address
        .d_axi_arid         (d_axi_arid),
        .d_axi_araddr       (d_axi_araddr),
        .d_axi_arlen        (d_axi_arlen),
        .d_axi_arsize       (d_axi_arsize),
        .d_axi_arburst      (d_axi_arburst),
        .d_axi_arvalid      (d_axi_arvalid),
        .d_axi_arready      (d_axi_arready),

        // Read Data
        .d_axi_rid          (d_axi_rid),
        .d_axi_rdata        (d_axi_rdata),
        .d_axi_rresp        (d_axi_rresp),
        .d_axi_rlast        (d_axi_rlast),
        .d_axi_rvalid       (d_axi_rvalid),
        .d_axi_rready       (d_axi_rready),

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

endmodule

`ifdef YOSYS

// ============================================================
// Gowin_rPLL passthrough wrapper for nextpnr / Yosys
// ============================================================

module Gowin_rPLL (
    output wire clkout,
    output wire clkoutp,
    input  wire clkin
);

    // No PLL for timing synthesis.
    // Pass the input clock directly through.
    assign clkout  = clkin;
    assign clkoutp = clkin;

endmodule

// ============================================================
// Gowin_CLKDIV passthrough wrapper for nextpnr / Yosys
// ============================================================

module Gowin_CLKDIV (
    output wire clkout,
    input  wire hclkin,
    input  wire resetn
);

    // nextpnr timing analysis:
    // bypass Gowin CLKDIV primitive.
    assign clkout = hclkin;

endmodule

`endif