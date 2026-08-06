// ============================================================================
//  PSC_ONE_Chip  —  PSC-ONE SoC Top Module
// ----------------------------------------------------------------------------
//  Author : NISHIHARU
//  File   : PSC_ONE_Chip.v
//
//  Brief
//      PSC-ONE プロジェクト向け SoC トップレベルモジュール。
//      RV32ISP CPU コア、SDRAM コントローラ、キャッシュ、Boot ROM、
//      UART、Timer、LCD、SD Card、I2S、および SynapEngine AI
//      アクセラレータを統合する。
//
//      本モジュールは FPGA 実装およびシミュレーションの双方を対象とし、
//      外部 SDR SDRAM と各種メモリマップド I/O を接続する。
//      また cocotb テストベンチからアクセス可能な AXI インタフェースを
//      提供し、メモリ初期化やデバッグを容易にする。
//
//  Main Components
//      - PSC RV32ISP CPU Core
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
//
//  Revision History
//      2025-09-14 : Initial version
//      2026-05-30 : Header updated for PSC-ONE architecture
// ============================================================================
`timescale 1ns / 1ps

module PSC_ONE_Chip #(
    parameter integer CLK_FREQ     = 80,
    parameter integer ADDR_WIDTH   = 32,
    parameter integer ID_WIDTH     = 1,
    parameter integer DATA_WIDTH   = 32,   // AXI Data bus. fixed 32bit Bus

    // PIO アドレス（0なら無効）
    parameter [ADDR_WIDTH-1:0]  UART_ADDRESS_TX     = 32'h1000_0000,
    parameter [ADDR_WIDTH-1:0]  UART_ADDRESS_RX     = 32'h1000_0004,
    parameter [ADDR_WIDTH-1:0]  UART_ADDRESS_ST     = 32'h1000_0008,
    parameter [ADDR_WIDTH-1:0]  UART_ADDRESS_CT     = 32'h1000_000C,
    parameter [ADDR_WIDTH-1:0]  PIO_ADDRESS         = 32'h1000_1000,
    parameter [ADDR_WIDTH-1:0]  TIMER_WRITE_ADDR    = 32'h1000_2000,
    parameter [ADDR_WIDTH-1:0]  TIMER_READ_ADDR     = 32'h1000_2004,
    parameter [ADDR_WIDTH-1:0]  TIMER_ST_ADDR       = 32'h1000_2008,
    parameter [ADDR_WIDTH-1:0]  LCD_PIX_DATA        = 32'h1000_3000,
    parameter [ADDR_WIDTH-1:0]  LCD_PIXS_ST         = 32'h1000_3004,
    parameter [ADDR_WIDTH-1:0]  LED_ADDRESS         = 32'h1000_4000,
    parameter [ADDR_WIDTH-1:0]  PSC_SA_CTRL         = 32'h0,
    parameter [ADDR_WIDTH-1:0]  PSC_SA_STATUS       = 32'h0,
    parameter [ADDR_WIDTH-1:0]  PSC_SD_IF_READ_DATA = 32'h1000_6000,
    parameter [ADDR_WIDTH-1:0]  PSC_SD_IF_SECTOR    = 32'h1000_6004,
    parameter [ADDR_WIDTH-1:0]  PSC_SD_IF_CTRL      = 32'h1000_6008,
    parameter [ADDR_WIDTH-1:0]  PSC_I2S_ADDR_RX     = 32'h1000_7000,
    parameter [ADDR_WIDTH-1:0]  PSC_I2S_ADDR_ST     = 32'h1000_7004,
    parameter [ADDR_WIDTH-1:0]  PSC_PFE_IF_DATA     = 32'h1000_8000,    // TBD
    parameter [ADDR_WIDTH-1:0]  PSC_PFE_IF_CTRL     = 32'h1000_8004     // TBD
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

    //assign UART_TXD = UART_RXD;
    assign PSCONE_LCD_BL = 1'b1;

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

    // LED（MMIO）
    wire [7:0] LED_external_out;
	assign  PSCONE_LED_OUT = {LED_external_out[2:0], PSCONE_TP_PEN, PSCONE_SW1, PSCONE_SW2};  

    // --------------------------------
    // MMIO bus
    // --------------------------------
    wire [31:0] mmio_addr;
    wire [31:0] mmio_wdata;
    reg [31:0]  mmio_rdata;
    wire [31:0] mmio_rdata_pio;
    wire [31:0] mmio_rdata_uart;
    wire [31:0] mmio_rdata_timer;
    wire [31:0] mmio_rdata_led;     // not used
    wire [31:0] mmio_rdata_lcd;
    wire [31:0] mmio_rdata_sd;
    wire [31:0] mmio_rdata_i2s;
    wire [31:0] mmio_rdata_pfe;

    always @(*) begin
        case(mmio_addr)    // byte address.
            PIO_ADDRESS:        mmio_rdata <= mmio_rdata_pio;
            UART_ADDRESS_TX:    mmio_rdata <= mmio_rdata_uart;
            UART_ADDRESS_RX:    mmio_rdata <= mmio_rdata_uart;
            UART_ADDRESS_ST:    mmio_rdata <= mmio_rdata_uart;
            UART_ADDRESS_CT:    mmio_rdata <= mmio_rdata_uart;
            LCD_PIXS_ST:        mmio_rdata <= mmio_rdata_lcd;
            PSC_SD_IF_READ_DATA: mmio_rdata <= mmio_rdata_sd;
            PSC_SD_IF_CTRL:      mmio_rdata <= mmio_rdata_sd;
            PSC_I2S_ADDR_RX:     mmio_rdata <= mmio_rdata_i2s;
            PSC_I2S_ADDR_ST:     mmio_rdata <= mmio_rdata_i2s;
            TIMER_READ_ADDR:     mmio_rdata <= mmio_rdata_timer;
            PSC_PFE_IF_DATA:     mmio_rdata <= mmio_rdata_pfe;
            PSC_PFE_IF_CTRL:     mmio_rdata <= mmio_rdata_pfe;
            default: mmio_rdata <= 32'd0;
        endcase
    end

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
    // RISC-V CPU: 
    // PSC_RV32IS_core_cache_axi
    //==========================================================
    wire    mmio_valid;
    wire    mmio_rw;
    wire    mmio_rready_pio;
    wire    mmio_wready_pio;
    wire    mmio_rready_uart;
    wire    mmio_wready_uart;
    wire    mmio_wready_timer;
    wire    mmio_rready_timer;
    wire    mmio_rready_sd;
    wire    mmio_wready_sd;
    wire    mmio_rready_i2s;
    wire    mmio_wready_i2s;
    wire    mmio_rready_led;
    wire    mmio_wready_led;
    wire    mmio_rready_lcd;
    wire    mmio_wready_lcd;
    wire    mmio_rready_pfe;
    wire    mmio_wready_pfe;

    wire    mmio_ready = 
                mmio_rready_pio | mmio_wready_pio | 
                mmio_rready_uart | mmio_wready_uart | 
                mmio_wready_timer | mmio_rready_timer | 
                mmio_rready_sd | 
                mmio_rready_i2s | 
                mmio_wready_i2s | 
                mmio_wready_led | 
                mmio_rready_led | 
                mmio_rready_lcd | 
                mmio_wready_lcd |
                mmio_rready_pfe |
                mmio_wready_pfe |
                mmio_wready_sd;

    // CPU to DMA
    wire [31:0] csr_DMA_CTRL;
    wire [31:0] csr_DMA_WORDS;
    wire [31:0] csr_DMA_SRC;
    wire [31:0] csr_DMA_DST;

    wire        dma_busy;
    wire        dma_done;
    wire [31:0] csr_DMA_STATUS = {30'd0, dma_busy, dma_done};

    PSC_ONE_RV32ISP_core #(
        .ADDR_WIDTH         (ADDR_W),
        .ID_WIDTH           (ID_W),
        .DATA_WIDTH         (DW),
        // MMIO ADDRESS
        .UART_ADDRESS_TX     (UART_ADDRESS_TX),
        .UART_ADDRESS_RX     (UART_ADDRESS_RX),
        .UART_ADDRESS_ST     (UART_ADDRESS_ST),
        .UART_ADDRESS_CT     (UART_ADDRESS_CT),
        .PIO_ADDRESS         (PIO_ADDRESS),
        .TIMER_WRITE_ADDR    (TIMER_WRITE_ADDR),
        .TIMER_READ_ADDR     (TIMER_READ_ADDR),
        .LCD_PIX_DATA        (LCD_PIX_DATA),
        .LCD_PIXS_ST         (LCD_PIXS_ST),
        .LED_ADDRESS         (LED_ADDRESS),
        .PSC_SA_CTRL         (PSC_SA_CTRL),
        .PSC_SA_STATUS       (PSC_SA_STATUS),
        .PSC_SD_IF_READ_DATA (PSC_SD_IF_READ_DATA),
        .PSC_SD_IF_SECTOR    (PSC_SD_IF_SECTOR),
        .PSC_SD_IF_CTRL      (PSC_SD_IF_CTRL),
        .PSC_I2S_ADDR_RX     (PSC_I2S_ADDR_RX),
        .PSC_I2S_ADDR_ST     (PSC_I2S_ADDR_ST),
        .PSC_PFE_IF_DATA     (PSC_PFE_IF_DATA),
        .PSC_PFE_IF_CTRL     (PSC_PFE_IF_CTRL)
    ) u_core_axi (
        .clock              (clock_100MHz),
        .reset_n            (reset_n),
        .cpu_stop           (cpu_stop),
        .uart_out           (),

        // ---- 外部 IO ----
        .mmio_valid         (mmio_valid),
        .mmio_rw            (mmio_rw),
        .mmio_addr          (mmio_addr),
        .mmio_rdata         (mmio_rdata),
        .mmio_ready         (mmio_ready),
        .mmio_wdata         (mmio_wdata),

        // ---- DMA ----
        .csr_DMA_CTRL       (csr_DMA_CTRL),
        .csr_DMA_WORDS      (csr_DMA_WORDS),
        .csr_DMA_SRC        (csr_DMA_SRC),
        .csr_DMA_DST        (csr_DMA_DST),
        .csr_DMA_STATUS     (csr_DMA_STATUS),

        // ---- Program AXI (SLAVE interface of this module) ----
        .p_axi_awid         (p_axi_awid),
        .p_axi_awaddr       (p_axi_awaddr),
        .p_axi_awlen        (p_axi_awlen),
        .p_axi_awsize       (p_axi_awsize),
        .p_axi_awburst      (p_axi_awburst),
        .p_axi_awvalid      (p_axi_awvalid),
        .p_axi_awready      (p_axi_awready),

        .p_axi_wdata        (p_axi_wdata),
        .p_axi_wstrb        (p_axi_wstrb),
        .p_axi_wlast        (p_axi_wlast),
        .p_axi_wvalid       (p_axi_wvalid),
        .p_axi_wready       (p_axi_wready),

        .p_axi_bid          (p_axi_bid),
        .p_axi_bresp        (p_axi_bresp),
        .p_axi_bvalid       (p_axi_bvalid),
        .p_axi_bready       (p_axi_bready),

        .p_axi_arid         (p_axi_arid),
        .p_axi_araddr       (p_axi_araddr),
        .p_axi_arlen        (p_axi_arlen),
        .p_axi_arsize       (p_axi_arsize),
        .p_axi_arburst      (p_axi_arburst),
        .p_axi_arvalid      (p_axi_arvalid),
        .p_axi_arready      (p_axi_arready),

        .p_axi_rid          (p_axi_rid),
        .p_axi_rdata        (p_axi_rdata),
        .p_axi_rresp        (p_axi_rresp),
        .p_axi_rlast        (p_axi_rlast),
        .p_axi_rvalid       (p_axi_rvalid),
        .p_axi_rready       (p_axi_rready),

        // ---- Data AXI (SLAVE interface of this module) ----
        .d_axi_awid         (d_axi_awid),
        .d_axi_awaddr       (d_axi_awaddr),
        .d_axi_awlen        (d_axi_awlen),
        .d_axi_awsize       (d_axi_awsize),
        .d_axi_awburst      (d_axi_awburst),
        .d_axi_awvalid      (d_axi_awvalid),
        .d_axi_awready      (d_axi_awready),

        .d_axi_wdata        (d_axi_wdata),
        .d_axi_wstrb        (d_axi_wstrb),
        .d_axi_wlast        (d_axi_wlast),
        .d_axi_wvalid       (d_axi_wvalid),
        .d_axi_wready       (d_axi_wready),

        .d_axi_bid          (d_axi_bid),
        .d_axi_bresp        (d_axi_bresp),
        .d_axi_bvalid       (d_axi_bvalid),
        .d_axi_bready       (d_axi_bready),

        .d_axi_arid         (d_axi_arid),
        .d_axi_araddr       (d_axi_araddr),
        .d_axi_arlen        (d_axi_arlen),
        .d_axi_arsize       (d_axi_arsize),
        .d_axi_arburst      (d_axi_arburst),
        .d_axi_arvalid      (d_axi_arvalid),
        .d_axi_arready      (d_axi_arready),

        .d_axi_rid          (d_axi_rid),
        .d_axi_rdata        (d_axi_rdata),
        .d_axi_rresp        (d_axi_rresp),
        .d_axi_rlast        (d_axi_rlast),
        .d_axi_rvalid       (d_axi_rvalid),
        .d_axi_rready       (d_axi_rready)
    );

    //==========================================================
    // AXI But Sdram I/F
    //==========================================================
    //wire [1:0]          dummy_O_sdram_addr;
    wire   sdram_init_fin;
    assign O_sdram_cke   = 1'b1;

    sdram_4port_controller_axi_slave_bX_32bit #(
        .CLK_FREQ_MHz       (CLK_FREQ),
        .ADDR_WIDTH         (24),
        .DATA_WIDTH         (32),
        .ID_WIDTH           (1)
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
    // Boot
    //==========================================================

    // Boot Module
    PSC_ONE_Boot_axi #(
        .ADDR_WIDTH         (ADDR_W),
        .ID_WIDTH           (ID_W),
        .DATA_WIDTH         (DW)
    ) u_bt_rom (
        .clock              (clock_100MHz),
        .reset_n            (reset_n),

        .sdram_init_fin     (sdram_init_fin),
        .done               (Boot_rom_done),

        // ---- Boot (AXI Master) ----
        .bt_axi_awid        (bt_axi_awid),
        .bt_axi_awaddr      (bt_axi_awaddr),
        .bt_axi_awlen       (bt_axi_awlen),
        .bt_axi_awsize      (bt_axi_awsize),
        .bt_axi_awburst     (bt_axi_awburst),
        .bt_axi_awvalid     (bt_axi_awvalid),
        .bt_axi_awready     (bt_axi_awready),

        .bt_axi_wdata       (bt_axi_wdata),
        .bt_axi_wstrb       (bt_axi_wstrb),
        .bt_axi_wlast       (bt_axi_wlast),
        .bt_axi_wvalid      (bt_axi_wvalid),
        .bt_axi_wready      (bt_axi_wready),

        .bt_axi_bid         (bt_axi_bid),
        .bt_axi_bresp       (bt_axi_bresp),
        .bt_axi_bvalid      (bt_axi_bvalid),
        .bt_axi_bready      (bt_axi_bready),

        .bt_axi_arid        (bt_axi_arid),
        .bt_axi_araddr      (bt_axi_araddr),
        .bt_axi_arlen       (bt_axi_arlen),
        .bt_axi_arsize      (bt_axi_arsize),
        .bt_axi_arburst     (bt_axi_arburst),
        .bt_axi_arvalid     (bt_axi_arvalid),
        .bt_axi_arready     (bt_axi_arready),

        .bt_axi_rid         (bt_axi_rid),
        .bt_axi_rdata       (bt_axi_rdata),
        .bt_axi_rresp       (bt_axi_rresp),
        .bt_axi_rlast       (bt_axi_rlast),
        .bt_axi_rvalid      (bt_axi_rvalid),
        .bt_axi_rready      (bt_axi_rready)
    );

    //==========================================================
    // Boot
    //==========================================================

    PSC_ONE_DMA_axi #(
        .ADDR_WIDTH         (32),
        .ID_WIDTH           (1),
        .DATA_WIDTH         (32)
    ) u_dma (
        .clock              (clock_100MHz),
        .reset_n            (reset_n),

        // DMA Control
        .dma_start          (csr_DMA_CTRL[0]),
        .dma_busy           (dma_busy),
        .dma_done           (dma_done),

        // Transfer Mount & Address
        .DMA_WORDS          (csr_DMA_WORDS),
        .BASE_ADDR_READ     (csr_DMA_SRC),
        .BASE_ADDR_WRITE    (csr_DMA_DST),

        //================ Write Address =================
        .dma_axi_awid       (dma_axi_awid),
        .dma_axi_awaddr     (dma_axi_awaddr),
        .dma_axi_awlen      (dma_axi_awlen),
        .dma_axi_awsize     (dma_axi_awsize),
        .dma_axi_awburst    (dma_axi_awburst),
        .dma_axi_awvalid    (dma_axi_awvalid),
        .dma_axi_awready    (dma_axi_awready),

        //================ Write Data =================
        .dma_axi_wdata      (dma_axi_wdata),
        .dma_axi_wstrb      (dma_axi_wstrb),
        .dma_axi_wlast      (dma_axi_wlast),
        .dma_axi_wvalid     (dma_axi_wvalid),
        .dma_axi_wready     (dma_axi_wready),

        //================ Write Response =================
        .dma_axi_bid        (dma_axi_bid),
        .dma_axi_bresp      (dma_axi_bresp),
        .dma_axi_bvalid     (dma_axi_bvalid),
        .dma_axi_bready     (dma_axi_bready),

        //================ Read Address =================
        .dma_axi_arid       (dma_axi_arid),
        .dma_axi_araddr     (dma_axi_araddr),
        .dma_axi_arlen      (dma_axi_arlen),
        .dma_axi_arsize     (dma_axi_arsize),
        .dma_axi_arburst    (dma_axi_arburst),
        .dma_axi_arvalid    (dma_axi_arvalid),
        .dma_axi_arready    (dma_axi_arready),

        //================ Read Data =================
        .dma_axi_rid        (dma_axi_rid),
        .dma_axi_rdata      (dma_axi_rdata),
        .dma_axi_rresp      (dma_axi_rresp),
        .dma_axi_rlast      (dma_axi_rlast),
        .dma_axi_rvalid     (dma_axi_rvalid),
        .dma_axi_rready     (dma_axi_rready)
    );

    //==========================================================
    // UART:
    //==========================================================

    // UART インスタンス
    PSC_RV32IS_UART #(
        .CLK_FREQ_MHz   (CLK_FREQ),
`ifdef FST_UART_MODE
        .BAUDRATE       (11520000*2),        // Simulation高速化のため200倍にする
`else
        .BAUDRATE       (115200),
`endif
        .UART_ADDR_TX   (UART_ADDRESS_TX),
        .UART_ADDR_RX   (UART_ADDRESS_RX),
        .UART_ADDR_ST   (UART_ADDRESS_ST),
        .UART_ADDR_CT   (UART_ADDRESS_CT)
    ) u_uart (
        .clock          (clock_100MHz),
        .reset_n        (reset_n),

        .uart_rx        (UART_RXD),
        .uart_tx        (UART_TXD),

        .cpu_wvalid     (mmio_valid & mmio_rw),
        .cpu_waddr      (mmio_addr),
        .cpu_wdata      (mmio_wdata),
        .cpu_wready     (mmio_wready_uart),

        .cpu_rvalid     (mmio_valid & ~mmio_rw),
        .cpu_raddr      (mmio_addr),
        .cpu_rdata      (mmio_rdata_uart),
        .cpu_rready     (mmio_rready_uart),

        .irq_rx         ()
    );

    //==========================================================
    // PSC_PFE:
    // TBD
    //==========================================================

    // PSC_PFE インスタンス
    PSC_PFE #(
        .ADDR_WIDTH       (32),
        .QUBO_NUM_VARS    (8),
        .PFE_IF_DATA      (PSC_PFE_IF_DATA),
        .PFE_IF_CTRL      (PSC_PFE_IF_CTRL)
    ) u_pfe (
        .clock            (clock_100MHz),
        .reset_n          (reset_n),

        // CPU read IF（1clkパルス）
        .cpu_rvalid       (mmio_valid & ~mmio_rw),
        .cpu_raddr        (mmio_addr),
        .cpu_rdata        (mmio_rdata_pfe),
        .cpu_rready       (mmio_rready_pfe),

        // CPU write IF（1clkパルス）
        .cpu_wvalid       (mmio_valid & mmio_rw),
        .cpu_waddr        (mmio_addr),
        .cpu_wdata        (mmio_wdata),
        .cpu_wready       (mmio_wready_pfe)
    );

    //==========================================================
    // TIMER:
    //==========================================================

    // TIMER インスタンス
    PSC_RV32IS_TIMER #(
        .CLK_FREQ_MHz     (CLK_FREQ),
        .FRAC             (1),
        .TIMER_BITS       (16),
        .ADDR_WIDTH       (32),
        .TIMER_WRITE_ADDR (TIMER_WRITE_ADDR),
        .TIMER_READ_ADDR  (TIMER_READ_ADDR),
        .TIMER_ST_ADDR    (TIMER_ST_ADDR)
    ) u_timer (
        .clock            (clock_100MHz),
        .reset_n          (reset_n),

        // CPU write IF（1clkパルス）
        .cpu_wvalid       (mmio_valid & mmio_rw),
        .cpu_waddr        (mmio_addr),
        .cpu_wdata        (mmio_wdata),
        .cpu_wready       (mmio_wready_timer),

        // CPU read IF（1clkパルス）
        .cpu_rvalid       (mmio_valid & ~mmio_rw),
        .cpu_raddr        (mmio_addr),
        .cpu_rdata        (mmio_rdata_timer),
        .cpu_rready       (mmio_rready_timer),

        // 割り込み出力
        .irq_tx           ()
    );

    //==========================================================
    // LED x 8
    //==========================================================

    // MMIO インスタンス
    PSC_RV32IS_LED #(
        .LED_NUMBER     (8),
        .LED_ADDRESS    (LED_ADDRESS)
    ) u_mmap_led (
        .clock          (clock_100MHz),
        .reset_n        (reset_n),

        .LED_out        (LED_external_out), // 実際の外部へ出力   : 8bit bus

        // CPU BUS
		.cpu_rvalid     (mmio_valid & ~mmio_rw),
        .cpu_raddr      (mmio_addr),
        .cpu_rdata      (mmio_rdata_led),
        .cpu_rready     (mmio_rready_led),

        .cpu_wvalid     (mmio_valid & mmio_rw),
        .cpu_waddr      (mmio_addr),
        .cpu_wdata      (mmio_wdata),
        .cpu_wready     (mmio_wready_led)
    );


    //==========================================================
    // TFT LCD
    //==========================================================
    PSC_ONE_LCD #(
        .CLK_FREQ       (CLK_FREQ),
        .LCD_PIXS_DATA  (LCD_PIX_DATA),
        .LCD_PIXS_ST    (LCD_PIXS_ST)
    ) u_lcd (
        .clock          (clock_100MHz),
        .reset_n        (reset_n),
        .tft_sdo        (PSCONE_LCD_SDO),
        .tft_sck        (PSCONE_LCD_SCK),
        .tft_sdi        (PSCONE_LCD_SDI),
        .tft_dc         (PSCONE_LCD_DC),
        .tft_reset      (PSCONE_LCD_RST),
        .tft_cs         (PSCONE_LCD_CS),

        // CPU BUS
		.cpu_rvalid     (mmio_valid & ~mmio_rw),
        .cpu_raddr      (mmio_addr),
        .cpu_rdata      (mmio_rdata_lcd),
        .cpu_rready     (mmio_rready_lcd),

        .cpu_wvalid     (mmio_valid & mmio_rw),
        .cpu_waddr      (mmio_addr),
        .cpu_wdata      (mmio_wdata),
        .cpu_wready     (mmio_wready_lcd)
    );

    //==========================================================
    // SD Card I/F
    //==========================================================
    PSC_SDCard #(
        .CLK_FREQ_MHz   (CLK_FREQ),
        .ADDR_WIDTH     (32),
        .INIT_80CLK     (80),
        .SD_IF_DATA     (PSC_SD_IF_READ_DATA),
        .SD_IF_SECTOR   (PSC_SD_IF_SECTOR),
		.SD_IF_CTRL     (PSC_SD_IF_CTRL),
        .FIFO_DEPTH     (512)     // max: 512
    ) u_sd_if (
        .clock          (clock_100MHz),
        .reset_n        (reset_n),

        // CPU BUS
		.cpu_rvalid     (mmio_valid & ~mmio_rw),
        .cpu_raddr      (mmio_addr),
        .cpu_rdata      (mmio_rdata_sd),
        .cpu_rready     (mmio_rready_sd),

        .cpu_wvalid     (mmio_valid & mmio_rw),
        .cpu_waddr      (mmio_addr),
        .cpu_wdata      (mmio_wdata),
        .cpu_wready     (mmio_wready_sd),

        // SPI PINS
        .sd_cs_n        (SD_D3),
        .sd_sck         (SD_CLK),
        .sd_mosi        (SD_CMD),
        .sd_miso        (SD_D0)     // input
    );

    //==========================================================
    // I2S I/F
    //==========================================================
    PSC_I2SRX #(
        .CLK_FREQ_MHz   (CLK_FREQ),
        .FIFO_DEPTH     (64),        // max: 256
        .I2S_ADDR_RX    (PSC_I2S_ADDR_RX),
        .I2S_ADDR_ST    (PSC_I2S_ADDR_ST)
    ) u_i2s_if (
        .clock          (clock_100MHz),
        .reset_n        (reset_n),

        // CPU BUS
		.cpu_rvalid     (mmio_valid & ~mmio_rw),
        .cpu_raddr      (mmio_addr),
        .cpu_rdata      (mmio_rdata_i2s),
        .cpu_rready     (mmio_rready_i2s),

		.cpu_wvalid     (mmio_valid & mmio_rw),
        .cpu_waddr      (mmio_addr),
        .cpu_wdata      (mmio_wdata),
        .cpu_wready     (mmio_wready_i2s),


        // I2S IF
        .I2S_SCK        (I2S_SCK),
        .I2S_WS         (I2S_WS),
        .I2S_LR         (I2S_LR),
        .I2S_SD         (I2S_SD)
    );


    // ==============================================
    // MMapped IO インスタンス化
    // ==============================================
    wire [7:0]  PIO_external_out;

    // MMIO インスタンス
    PSC_RV32IS_MMapped_IO #(
        .PIO_DATA_WIDTH (8),
        .PIO_ADDRESS    (PIO_ADDRESS)
    ) u_mmap_io (
        .clock          (clock_100MHz),
        .reset_n        (reset_n),

        .PIO_out        (PIO_external_out), // 実際の外部へ出力   : 8bit bus
        `ifdef COCOTB_SIM
        .PIO_in         (8'h03),            // pio_test1.cpp 対応
        `else
        .PIO_in         ({6'd0, PSCONE_SW2, PSCONE_SW1}),
        `endif

        .cpu_wvalid     (mmio_valid & mmio_rw),
        .cpu_waddr      (mmio_addr),
        .cpu_wdata      (mmio_wdata),
        .cpu_wready     (mmio_wready_pio),

        .cpu_rvalid     (mmio_valid & ~mmio_rw),
        .cpu_raddr      (mmio_addr),
        .cpu_rdata      (mmio_rdata_pio),
        .cpu_rready     (mmio_rready_pio)
    );

endmodule
