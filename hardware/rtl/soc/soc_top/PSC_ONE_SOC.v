`timescale 1ns / 1ps

// Phase Flow Engine OFF mode
//`define PFE_OFF

// Yosys mode
//`define YOSYS

module PSC_ONE_SOC #(
    parameter integer CLK_FREQ     = 80,
    parameter integer ADDR_WIDTH   = 32,
    parameter integer ID_WIDTH     = 1,
    parameter integer DATA_WIDTH   = 32,   // AXI Data bus. fixed 32bit Bus

    // MMIO MASK BITS
    parameter [ADDR_WIDTH-1:0]  MMMIO_BASK_BITS     = 32'h1000_F00F,
    // MMIO アドレス（0なら無効）
    parameter [ADDR_WIDTH-1:0]  UART_ADDRESS_TX     = 32'h1000_0000,
    parameter [ADDR_WIDTH-1:0]  UART_ADDRESS_RX     = 32'h1000_0004,
    parameter [ADDR_WIDTH-1:0]  UART_ADDRESS_ST     = 32'h1000_0008,
    parameter [ADDR_WIDTH-1:0]  UART_ADDRESS_CT     = 32'h1000_000C,
    parameter [ADDR_WIDTH-1:0]  PIO_ADDRESS         = 32'h1000_1000,
    parameter [ADDR_WIDTH-1:0]  TIMER_WRITE_ADDR    = 32'h1000_2000,
    parameter [ADDR_WIDTH-1:0]  TIMER_READ_ADDR     = 32'h1000_2004,
    parameter [ADDR_WIDTH-1:0]  TIMER_ST_ADDR       = 32'h1000_2008,
    parameter [ADDR_WIDTH-1:0]  LCD_PIXS_DATA       = 32'h1000_3000,
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
    input  wire         clock,
    input  wire         reset_n,
    input  wire         cpu_stop,
    input  wire         sdram_init_fin,
    output wire         Boot_rom_done,

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
    output wire [5:0]   PSCONE_LED_OUT,

    // ---------------- Program AXI I/F ----------------
    output wire [ID_WIDTH-1:0]       p_axi_awid,
    output wire [ADDR_WIDTH-1:0]     p_axi_awaddr,
    output wire [7:0]                p_axi_awlen,
    output wire [2:0]                p_axi_awsize,
    output wire [1:0]                p_axi_awburst,
    output wire                      p_axi_awvalid,
    input  wire                      p_axi_awready,
    output wire [DATA_WIDTH-1:0]     p_axi_wdata,
    output wire [(DATA_WIDTH/8)-1:0] p_axi_wstrb,
    output wire                      p_axi_wlast,
    output wire                      p_axi_wvalid,
    input  wire                      p_axi_wready,
    input  wire [ID_WIDTH-1:0]       p_axi_bid,
    input  wire [1:0]                p_axi_bresp,
    input  wire                      p_axi_bvalid,
    output wire                      p_axi_bready,
    output wire [ID_WIDTH-1:0]       p_axi_arid,
    output wire [ADDR_WIDTH-1:0]     p_axi_araddr,
    output wire [7:0]                p_axi_arlen,
    output wire [2:0]                p_axi_arsize,
    output wire [1:0]                p_axi_arburst,
    output wire                      p_axi_arvalid,
    input  wire                      p_axi_arready,
    input  wire [ID_WIDTH-1:0]       p_axi_rid,
    input  wire [DATA_WIDTH-1:0]     p_axi_rdata,
    input  wire [1:0]                p_axi_rresp,
    input  wire                      p_axi_rlast,
    input  wire                      p_axi_rvalid,
    output wire                      p_axi_rready,

    // ---------------- Data AXI I/F ----------------
    output wire [ID_WIDTH-1:0]       d_axi_awid,
    output wire [ADDR_WIDTH-1:0]     d_axi_awaddr,
    output wire [7:0]                d_axi_awlen,
    output wire [2:0]                d_axi_awsize,
    output wire [1:0]                d_axi_awburst,
    output wire                      d_axi_awvalid,
    input  wire                      d_axi_awready,
    output wire [DATA_WIDTH-1:0]     d_axi_wdata,
    output wire [(DATA_WIDTH/8)-1:0] d_axi_wstrb,
    output wire                      d_axi_wlast,
    output wire                      d_axi_wvalid,
    input  wire                      d_axi_wready,
    input  wire [ID_WIDTH-1:0]       d_axi_bid,
    input  wire [1:0]                d_axi_bresp,
    input  wire                      d_axi_bvalid,
    output wire                      d_axi_bready,
    output wire [ID_WIDTH-1:0]       d_axi_arid,
    output wire [ADDR_WIDTH-1:0]     d_axi_araddr,
    output wire [7:0]                d_axi_arlen,
    output wire [2:0]                d_axi_arsize,
    output wire [1:0]                d_axi_arburst,
    output wire                      d_axi_arvalid,
    input  wire                      d_axi_arready,
    input  wire [ID_WIDTH-1:0]       d_axi_rid,
    input  wire [DATA_WIDTH-1:0]     d_axi_rdata,
    input  wire [1:0]                d_axi_rresp,
    input  wire                      d_axi_rlast,
    input  wire                      d_axi_rvalid,
    output wire                      d_axi_rready,

    // ---------------- DMA / SA AXI I/F ----------------
    output wire [ID_WIDTH-1:0]       dma_axi_awid,
    output wire [ADDR_WIDTH-1:0]     dma_axi_awaddr,
    output wire [7:0]                dma_axi_awlen,
    output wire [2:0]                dma_axi_awsize,
    output wire [1:0]                dma_axi_awburst,
    output wire                      dma_axi_awvalid,
    input  wire                      dma_axi_awready,
    output wire [DATA_WIDTH-1:0]     dma_axi_wdata,
    output wire [(DATA_WIDTH/8)-1:0] dma_axi_wstrb,
    output wire                      dma_axi_wlast,
    output wire                      dma_axi_wvalid,
    input  wire                      dma_axi_wready,
    input  wire [ID_WIDTH-1:0]       dma_axi_bid,
    input  wire [1:0]                dma_axi_bresp,
    input  wire                      dma_axi_bvalid,
    output wire                      dma_axi_bready,
    output wire [ID_WIDTH-1:0]       dma_axi_arid,
    output wire [ADDR_WIDTH-1:0]     dma_axi_araddr,
    output wire [7:0]                dma_axi_arlen,
    output wire [2:0]                dma_axi_arsize,
    output wire [1:0]                dma_axi_arburst,
    output wire                      dma_axi_arvalid,
    input  wire                      dma_axi_arready,
    input  wire [ID_WIDTH-1:0]       dma_axi_rid,
    input  wire [DATA_WIDTH-1:0]     dma_axi_rdata,
    input  wire [1:0]                dma_axi_rresp,
    input  wire                      dma_axi_rlast,
    input  wire                      dma_axi_rvalid,
    output wire                      dma_axi_rready,

    // ---------------- Boot ROM AXI I/F ----------------
    output wire [ID_WIDTH-1:0]       bt_axi_awid,
    output wire [ADDR_WIDTH-1:0]     bt_axi_awaddr,
    output wire [7:0]                bt_axi_awlen,
    output wire [2:0]                bt_axi_awsize,
    output wire [1:0]                bt_axi_awburst,
    output wire                      bt_axi_awvalid,
    input  wire                      bt_axi_awready,
    output wire [DATA_WIDTH-1:0]     bt_axi_wdata,
    output wire [(DATA_WIDTH/8)-1:0] bt_axi_wstrb,
    output wire                      bt_axi_wlast,
    output wire                      bt_axi_wvalid,
    input  wire                      bt_axi_wready,
    input  wire [ID_WIDTH-1:0]       bt_axi_bid,
    input  wire [1:0]                bt_axi_bresp,
    input  wire                      bt_axi_bvalid,
    output wire                      bt_axi_bready,
    output wire [ID_WIDTH-1:0]       bt_axi_arid,
    output wire [ADDR_WIDTH-1:0]     bt_axi_araddr,
    output wire [7:0]                bt_axi_arlen,
    output wire [2:0]                bt_axi_arsize,
    output wire [1:0]                bt_axi_arburst,
    output wire                      bt_axi_arvalid,
    input  wire                      bt_axi_arready,
    input  wire [ID_WIDTH-1:0]       bt_axi_rid,
    input  wire [DATA_WIDTH-1:0]     bt_axi_rdata,
    input  wire [1:0]                bt_axi_rresp,
    input  wire                      bt_axi_rlast,
    input  wire                      bt_axi_rvalid,
    output wire                      bt_axi_rready
);

    //assign UART_TXD = UART_RXD;
    assign PSCONE_LCD_BL = 1'b1;

    // LED（MMIO）
    wire [7:0] LED_external_out;
	//assign  PSCONE_LED_OUT = {LED_external_out[2:0], PSCONE_TP_PEN, PSCONE_SW1, PSCONE_SW2};
	assign  PSCONE_LED_OUT = ~LED_external_out[5:0];

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

    wire [31:0] addr_mmio_masked = mmio_addr & MMMIO_BASK_BITS;
    
    always @(*) begin
        case(mmio_addr)    // byte address.
            PIO_ADDRESS:         mmio_rdata = mmio_rdata_pio;
            UART_ADDRESS_TX:     mmio_rdata = mmio_rdata_uart;
            UART_ADDRESS_RX:     mmio_rdata = mmio_rdata_uart;
            UART_ADDRESS_ST:     mmio_rdata = mmio_rdata_uart;
            UART_ADDRESS_CT:     mmio_rdata = mmio_rdata_uart;
            LCD_PIXS_ST:         mmio_rdata = mmio_rdata_lcd;
            PSC_SD_IF_READ_DATA: mmio_rdata = mmio_rdata_sd;
            PSC_SD_IF_CTRL:      mmio_rdata = mmio_rdata_sd;
            PSC_I2S_ADDR_RX:     mmio_rdata = mmio_rdata_i2s;
            PSC_I2S_ADDR_ST:     mmio_rdata = mmio_rdata_i2s;
            TIMER_READ_ADDR:     mmio_rdata = mmio_rdata_timer;
            TIMER_ST_ADDR:       mmio_rdata = mmio_rdata_timer;
            PSC_PFE_IF_DATA:     mmio_rdata = mmio_rdata_pfe;
            PSC_PFE_IF_CTRL:     mmio_rdata = mmio_rdata_pfe;
            default: mmio_rdata = 32'd0;
        endcase
    end

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

    // irq
    wire        irq_tx;

    PSC_ONE_RV32_core #(
        .ADDR_WIDTH          (ADDR_WIDTH),
        .ID_WIDTH            (ID_WIDTH),
        .DATA_WIDTH          (DATA_WIDTH),
        // MMIO MASK BITS
        .MMMIO_BASK_BITS     (MMMIO_BASK_BITS),
        // MMIO ADDRESS
        .UART_ADDRESS_TX     (UART_ADDRESS_TX),
        .UART_ADDRESS_RX     (UART_ADDRESS_RX),
        .UART_ADDRESS_ST     (UART_ADDRESS_ST),
        .UART_ADDRESS_CT     (UART_ADDRESS_CT),
        .PIO_ADDRESS         (PIO_ADDRESS),
        .TIMER_WRITE_ADDR    (TIMER_WRITE_ADDR),
        .TIMER_READ_ADDR     (TIMER_READ_ADDR),
        .TIMER_ST_ADDR       (TIMER_ST_ADDR),
        .LCD_PIXS_DATA       (LCD_PIXS_DATA),
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
    ) u_rv32_core_axi (
        .clock              (clock),
        .reset_n            (reset_n),
        .cpu_stop           (cpu_stop),
        .timer_irq_ext      (irq_tx),
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
    // Boot
    //==========================================================

    // Boot Module
    PSC_ONE_Boot_axi #(
        .ADDR_WIDTH         (ADDR_WIDTH),
        .ID_WIDTH           (ID_WIDTH),
        .DATA_WIDTH         (DATA_WIDTH)
    ) u_bt_rom (
        .clock              (clock),
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
        .ADDR_WIDTH         (ADDR_WIDTH),
        .ID_WIDTH           (1),
        .DATA_WIDTH         (32)
    ) u_dma (
        .clock              (clock),
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
        .clock          (clock),
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
        .ADDR_WIDTH       (ADDR_WIDTH),
        .QUBO_NUM_VARS    (8),
        .PFE_IF_DATA      (PSC_PFE_IF_DATA),
        .PFE_IF_CTRL      (PSC_PFE_IF_CTRL)
    ) u_pfe (
        .clock            (clock),
        `ifdef PFE_OFF
        .reset_n          (1'b0),
        `else
        .reset_n          (reset_n),
        `endif

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
        .ADDR_WIDTH       (ADDR_WIDTH),
        .TIMER_WRITE_ADDR (TIMER_WRITE_ADDR),
        .TIMER_READ_ADDR  (TIMER_READ_ADDR),
        .TIMER_ST_ADDR    (TIMER_ST_ADDR)
    ) u_timer (
        .clock            (clock),
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
        .irq_tx           (irq_tx)
    );

    //==========================================================
    // LED x 8
    //==========================================================

    // MMIO インスタンス
    PSC_RV32IS_LED #(
        .LED_NUMBER     (8),
        .LED_ADDRESS    (LED_ADDRESS)
    ) u_led (
        .clock          (clock),
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
        .LCD_PIXS_DATA  (LCD_PIXS_DATA),
        .LCD_PIXS_ST    (LCD_PIXS_ST)
    ) u_lcd (
        .clock          (clock),
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
        .ADDR_WIDTH     (ADDR_WIDTH),
        .INIT_80CLK     (80),
        .SD_IF_DATA     (PSC_SD_IF_READ_DATA),
        .SD_IF_SECTOR   (PSC_SD_IF_SECTOR),
		.SD_IF_CTRL     (PSC_SD_IF_CTRL),
        .FIFO_DEPTH     (512)     // max: 512
    ) u_sd_if (
        .clock          (clock),
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
        .clock          (clock),
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
        .clock          (clock),
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
