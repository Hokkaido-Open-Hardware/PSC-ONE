// nishiharu
`timescale 1ns/1ps

// default cache word = 1024
`define ICache_W256
//`define DCache_W256
`define DCache_W64

module sim_cache_dma_controller #(
    parameter integer ADDR_WIDTH   = 32,
    parameter PROTECT_MODE         = 0,
    parameter PROTECT_ADDR         = 32'h0001_0000,

    // PIO アドレス（0なら無効）
    parameter [ADDR_WIDTH-1:0]  UART_ADDRESS_TX  = 32'h1000_0000,
    parameter [ADDR_WIDTH-1:0]  UART_ADDRESS_RX  = 32'h1000_0004,
    parameter [ADDR_WIDTH-1:0]  UART_ADDRESS_ST  = 32'h1000_0008,
    parameter [ADDR_WIDTH-1:0]  UART_ADDRESS_CT  = 32'h1000_000C,
    parameter [ADDR_WIDTH-1:0]  PIO_ADDRESS      = 32'h1000_1000,
    parameter [ADDR_WIDTH-1:0]  TIMER_WRITE_ADDR = 32'h1000_2000,
    parameter [ADDR_WIDTH-1:0]  TIMER_READ_ADDR  = 32'h1000_2004,
    parameter [ADDR_WIDTH-1:0]  LCD_PIXS_DATA    = 32'h1000_3000,
    parameter [ADDR_WIDTH-1:0]  LCD_PIXS_ST      = 32'h1000_3004,
    parameter [ADDR_WIDTH-1:0]  LED_ADDRESS      = 32'h1000_4000,
    parameter [ADDR_WIDTH-1:0]  PSC_SA_CTRL      = 32'h0,
    parameter [ADDR_WIDTH-1:0]  PSC_SA_STATUS    = 32'h0,
    parameter [ADDR_WIDTH-1:0]  PSC_SD_IF_READ_DATA = 32'h1000_6000,
    parameter [ADDR_WIDTH-1:0]  PSC_SD_IF_SECTOR    = 32'h1000_6004,
    parameter [ADDR_WIDTH-1:0]  PSC_SD_IF_CTRL      = 32'h1000_6008,
    parameter [ADDR_WIDTH-1:0]  PSC_I2S_ADDR_RX     = 32'h1000_7000,
    parameter [ADDR_WIDTH-1:0]  PSC_I2S_ADDR_ST     = 32'h1000_7004
)(
    input                   clock,
    input                   reset_n,
    // cpu data bus
    // Program
    input  [31:0]           program_mem_read_address,   // byte address
    input                   program_mem_read_valid,
    output [31:0]           program_mem_read_data,
    output                  program_mem_read_ready,
    output wire             cpu_req_ready,
    input  wire             cpu_cache_clear, 
    input  wire             burst_mode,
    // Data
    input  wire             data_mem_read_valid,
    output wire             data_mem_read_ready,
    input  wire [31:0]      data_mem_read_address,
    output wire [31:0]      data_mem_read_data,
    output wire             data_mem_req_ready,
    input  wire             data_mem_write_valid,    
    output wire             data_mem_write_ready,
    input  wire  [2:0]      mem_write_sel,
    input  wire [31:0]      data_mem_write_address,
    input  wire [31:0]      mem_write_data,
    input  wire             data_cache_clear, 
    input  wire             data_cache_wb, 
    // MMU
    input  wire             mmu_data_mem_read_valid,
    output wire             mmu_data_mem_read_ready,
    input  wire [31:0]      mmu_data_mem_read_address,
    output wire [31:0]      mmu_data_mem_read_data,
    output wire             mmu_data_req_ready,
    // SA
    input  wire             sa_mem_read_valid,
    output wire             sa_mem_read_ready,
    input  wire [31:0]      sa_mem_read_address,
    output wire [31:0]      sa_mem_read_data,
    input  wire             sa_mem_write_valid,
    output wire             sa_mem_write_ready,
    input  wire [31:0]      sa_mem_write_address,
    input  wire [31:0]      sa_mem_write_data,
    input  wire  [2:0]      sa_mem_write_sel,           // cocotb test port. not used.
    output wire             sa_req_ready,
    // CPU MONITOR
    output wire             program_cache_hit_pulse,
    output wire             program_cache_miss_pulse,
    output wire             data_cache_hit_pulse,
    output wire             data_cache_miss_pulse
);


    `ifdef COCOTB_SIM
    initial begin
        `ifdef DUMP_VCD
        $display("COCOTB_SIM DUMP_VCD ENABLE");
        $dumpfile("./wave/PSC_CASHE_test.vcd");  // 出力するVCDファイル名
        $dumpvars(0);     // 第1引数: 階層 (0 はこのモジュールを最上位として)
        `else
        $display("COCOTB_SIM verilator FST ENABLE");
        $dumpfile("./wave/PSC_CASHE_test.fst");  // 出力するVCDファイル名
        $dumpvars(0);     // 第1引数: 階層 (0 はこのモジュールを最上位として)
        `endif
    end
    `endif

    // cache <-> bridge（128bit ライン側）
    wire         p_mem_valid128;
    wire         p_mem_rw128;
    wire         p_mem_ready128;
    wire [127:0] p_mem_rdata128;
    wire [31:0]  p_mem_addr128;
    wire [127:0] p_mem_wdata128;

    /* cache controller */
    cache_dma_controller #(
        .ADDR_WIDTH          (32),
        .CPU_DATA_WIDTH      (32),
        .CACHE_DATA_WIDTH    (128),
        .MAIN_MEM_DATA_WIDTH (128),
        .TAGMSB              (31),
        `ifdef ICache_W256
        .TAGLSB              (12)
        `else
        .TAGLSB              (14)
        `endif
    ) u_program_dma_ctrl (
        .clock              (clock),
        .reset_n            (reset_n),
        .cpu_valid          (program_mem_read_valid),
        .cpu_rw             (1'b0),
        .cpu_addr           (program_mem_read_address),
        .cpu_data           (32'd0),            // 未使用
        .burst_mode         (burst_mode),
        .cpu_ready          (program_mem_read_ready),
        .cpu_data_out       (program_mem_read_data),
        .cpu_req_ready      (cpu_req_ready),
        .cpu_cache_clear    (cpu_cache_clear),
        // 128b 側
        .mem_req_ready      (1'b1),             // 1'b1 fix
        .mem_valid          (p_mem_valid128),
        .mem_rw             (p_mem_rw128),
        .mem_ready          (p_mem_ready128),
        .mem_data_in        (p_mem_rdata128),
        .mem_addr           (p_mem_addr128),
        .mem_data_out       (p_mem_wdata128),
        // CACHE MONITOR
        .cache_hit_pulse    (program_cache_hit_pulse),
        .cache_miss_pulse   (program_cache_miss_pulse)
    );

    // ============================================================
    // Bridge (128b ⇄ AXI4-M(32b)) と AXI配線
    // ============================================================
    localparam integer SYS_ADDR_WIDTH = 32;
    localparam integer AXI_ID_WIDTH   = 1;
    localparam integer AXI_DATA_WIDTH = 32;

    // cache(128b)側とブリッジの接続（wireで分岐）
    wire                     p_cache_rd_valid = p_mem_valid128 & ~p_mem_rw128;
    wire                     p_cache_wr_valid = p_mem_valid128 &  p_mem_rw128;
    wire [31:0]              p_cache_rd_addr  = p_mem_addr128;
    wire [31:0]              p_cache_wr_addr  = p_mem_addr128;
    wire [127:0]             p_cache_wr_data  = p_mem_wdata128;
    wire [127:0]             p_cache_rd_data;
    wire                     p_cache_rd_ready;
    wire                     p_cache_wr_ready;

    // 完了は Read/Write どちらでも1clkパルスを返す
    assign p_mem_ready128 = p_cache_rd_ready | p_cache_wr_ready;
    assign p_mem_rdata128 = p_cache_rd_data;

    // ---------------- Bridge (AXI Master, 32-bit) ----------------
    sdram_32bit_to_128bit_axi_bridge #(
        .ADDR_WIDTH         (SYS_ADDR_WIDTH),
        .ID_WIDTH           (AXI_ID_WIDTH),
        .DATA_WIDTH         (AXI_DATA_WIDTH)
    ) p_axi_bridge (
        .clock              (clock),
        .reset_n            (reset_n),

        // Cache side (128b)
        .read_valid         (p_cache_rd_valid),
        .read_ready         (p_cache_rd_ready),
        .read_addr          (p_cache_rd_addr),
        .read_data          (p_cache_rd_data),

        .write_valid        (p_cache_wr_valid),
        .write_ready        (p_cache_wr_ready),
        .write_addr         (p_cache_wr_addr),
        .write_data         (p_cache_wr_data),

        // AXI4 Master (to SDRAM AXI-S)
        .m_axi_awid         (p_axi_awid),
        .m_axi_awaddr       (p_axi_awaddr),
        .m_axi_awlen        (p_axi_awlen),
        .m_axi_awsize       (p_axi_awsize),
        .m_axi_awburst      (p_axi_awburst),
        .m_axi_awvalid      (p_axi_awvalid),
        .m_axi_awready      (p_axi_awready),

        .m_axi_wdata        (p_axi_wdata),
        .m_axi_wstrb        (p_axi_wstrb),
        .m_axi_wlast        (p_axi_wlast),
        .m_axi_wvalid       (p_axi_wvalid),
        .m_axi_wready       (p_axi_wready),

        .m_axi_bid          (p_axi_bid),
        .m_axi_bresp        (p_axi_bresp),
        .m_axi_bvalid       (p_axi_bvalid),
        .m_axi_bready       (p_axi_bready),

        .m_axi_arid         (p_axi_arid),
        .m_axi_araddr       (p_axi_araddr),
        .m_axi_arlen        (p_axi_arlen),
        .m_axi_arsize       (p_axi_arsize),
        .m_axi_arburst      (p_axi_arburst),
        .m_axi_arvalid      (p_axi_arvalid),
        .m_axi_arready      (p_axi_arready),

        .m_axi_rid          (p_axi_rid),
        .m_axi_rdata        (p_axi_rdata),
        .m_axi_rresp        (p_axi_rresp),
        .m_axi_rlast        (p_axi_rlast),
        .m_axi_rvalid       (p_axi_rvalid),
        .m_axi_rready       (p_axi_rready)
    );    
    

    // ===========================================================
    //  Data キャッシュ（D-Cache 相当）
    // ===========================================================
    wire [31:0]  cpu_data_addr = (data_mem_write_valid) ? data_mem_write_address[31:0] : data_mem_read_address[31:0];

    wire         d_mem_valid128;
    wire         d_mem_rw128;
    wire         d_mem_ready128;
    wire [127:0] d_mem_rdata128;
    wire [31:0]  d_mem_addr128;
    wire [127:0] d_mem_wdata128;

    wire dcache_ready;

    // sa_ready
    wire sa_ready;
    assign sa_mem_read_ready    = sa_ready;
    assign sa_mem_write_ready   = sa_ready;
    
    // addr, data, valid
    wire [31:0] sa_addr =   sa_mem_read_valid  ? sa_mem_read_address  : 
                            sa_mem_write_valid ? sa_mem_write_address : 32'h0;

    // コアへ返す ready（READ/WRITE 共通）
    assign data_mem_read_ready  = dcache_ready;
    assign data_mem_write_ready = dcache_ready;

    cache_dma_controller_io #(
        .PROTECT_MODE        (PROTECT_MODE),
        .PROTECT_ADDR        (PROTECT_ADDR),
        .ADDR_WIDTH          (32),
        .CPU_DATA_WIDTH      (32),
        .CACHE_DATA_WIDTH    (128),
        .MAIN_MEM_DATA_WIDTH (128),
        .TAGMSB              (31),
        `ifdef DCache_W256
        .TAGLSB              (12),
        `elsif DCache_W64
        .TAGLSB              (10),
        `else
        .TAGLSB              (14),
        `endif
        // MMIO ADDR
        .UART_ADDRESS_TX     (UART_ADDRESS_TX),
        .UART_ADDRESS_RX     (UART_ADDRESS_RX),
        .UART_ADDRESS_ST     (UART_ADDRESS_ST),
        .UART_ADDRESS_CT     (UART_ADDRESS_CT),
        .PIO_ADDRESS         (PIO_ADDRESS),
        .TIMER_WRITE_ADDR    (TIMER_WRITE_ADDR),
        .TIMER_READ_ADDR     (TIMER_READ_ADDR),
        .LCD_PIXS_DATA       (LCD_PIXS_DATA),
        .LCD_PIXS_ST         (LCD_PIXS_ST),
        .LED_ADDRESS         (LED_ADDRESS),
        .PSC_SA_CTRL         (PSC_SA_CTRL),
        .PSC_SA_STATUS       (PSC_SA_STATUS),
        .PSC_SD_IF_READ_DATA (PSC_SD_IF_READ_DATA),
        .PSC_SD_IF_SECTOR    (PSC_SD_IF_SECTOR),
        .PSC_SD_IF_CTRL      (PSC_SD_IF_CTRL),
        .PSC_I2S_ADDR_RX     (PSC_I2S_ADDR_RX),
        .PSC_I2S_ADDR_ST     (PSC_I2S_ADDR_ST)
    ) u_data_dma_ctrl (
        .clock              (clock),
        .reset_n            (reset_n),
        // CPU Data
        .cpu_valid          (data_mem_read_valid | data_mem_write_valid),
        .cpu_rw             (data_mem_write_valid),
        .cpu_write_sel      (mem_write_sel),
        .cpu_addr           (cpu_data_addr),
        .cpu_data           (mem_write_data),
        .cpu_ready          (dcache_ready),
        .cpu_data_out       (data_mem_read_data),
        .cpu_req_ready      (data_mem_req_ready),
        .cpu_cache_clear    (data_cache_clear),
        .cpu_cache_wb       (data_cache_wb),
        // SynapEngine
        .sa_valid           (sa_mem_read_valid | sa_mem_write_valid),    
        .sa_rw              (sa_mem_write_valid),    
        .sa_addr            (sa_addr),
        .sa_data            (sa_mem_write_data),
        .sa_ready           (sa_ready),
        .sa_data_out        (sa_mem_read_data),
        .sa_req_ready       (sa_req_ready),
        // MMU
        .mmu_valid          (1'b0),
        .mmu_addr           (),
        .mmu_ready          (),
        .mmu_data_out       (),
        .mmu_req_ready      (),
        // MMIO
        .mmio_valid         (),
        .mmio_rw            (),
        .mmio_addr          (),
        .mmio_rdata         (),
        .mmio_ready         (1'b0),
        .mmio_wdata         (),
        // 128b 側
        .mem_req_ready      (1'b1),             // 1'b1 fix
        .mem_valid          (d_mem_valid128),
        .mem_rw             (d_mem_rw128),
        .mem_ready          (d_mem_ready128),
        .mem_data_in        (d_mem_rdata128),
        .mem_addr           (d_mem_addr128),
        .mem_data_out       (d_mem_wdata128),
        // CACHE MONITOR
        .cache_hit_pulse    (data_cache_hit_pulse),
        .cache_miss_pulse   (data_cache_miss_pulse)
    );

    // ============================================================
    // Bridge (128b ⇄ AXI4-M(16b)) と AXI配線
    // ============================================================

    // cache(128b)側とブリッジの接続（wireで分岐）
    wire                     d_cache_rd_valid = d_mem_valid128 & ~d_mem_rw128;
    wire                     d_cache_wr_valid = d_mem_valid128 &  d_mem_rw128;
    wire [31:0]              d_cache_rd_addr  = d_mem_addr128;
    wire [31:0]              d_cache_wr_addr  = d_mem_addr128;
    wire [127:0]             d_cache_wr_data  = d_mem_wdata128;
    wire [127:0]             d_cache_rd_data;
    wire                     d_cache_rd_ready;
    wire                     d_cache_wr_ready;

    // 完了は Read/Write どちらでも1clkパルスを返す
    assign d_mem_ready128 = d_cache_rd_ready | d_cache_wr_ready;
    assign d_mem_rdata128 = d_cache_rd_data;

    // ---------------- Bridge (AXI Master, 32-bit) ----------------
    sdram_32bit_to_128bit_axi_bridge #(
        .ADDR_WIDTH         (SYS_ADDR_WIDTH),
        .ID_WIDTH           (AXI_ID_WIDTH),
        .DATA_WIDTH         (32)
    ) d_axi_bridge (
        .clock              (clock),
        .reset_n            (reset_n),

        // Cache side (128b)
        .read_valid         (d_cache_rd_valid),
        .read_ready         (d_cache_rd_ready),
        .read_addr          (d_cache_rd_addr),
        .read_data          (d_cache_rd_data),

        .write_valid        (d_cache_wr_valid),
        .write_ready        (d_cache_wr_ready),
        .write_addr         (d_cache_wr_addr),
        .write_data         (d_cache_wr_data),

        // AXI4 Master (to SDRAM AXI-S)
        .m_axi_awid         (d_axi_awid),
        .m_axi_awaddr       (d_axi_awaddr),
        .m_axi_awlen        (d_axi_awlen),
        .m_axi_awsize       (d_axi_awsize),
        .m_axi_awburst      (d_axi_awburst),
        .m_axi_awvalid      (d_axi_awvalid),
        .m_axi_awready      (d_axi_awready),

        .m_axi_wdata        (d_axi_wdata),
        .m_axi_wstrb        (d_axi_wstrb),
        .m_axi_wlast        (d_axi_wlast),
        .m_axi_wvalid       (d_axi_wvalid),
        .m_axi_wready       (d_axi_wready),

        .m_axi_bid          (d_axi_bid),
        .m_axi_bresp        (d_axi_bresp),
        .m_axi_bvalid       (d_axi_bvalid),
        .m_axi_bready       (d_axi_bready),

        .m_axi_arid         (d_axi_arid),
        .m_axi_araddr       (d_axi_araddr),
        .m_axi_arlen        (d_axi_arlen),
        .m_axi_arsize       (d_axi_arsize),
        .m_axi_arburst      (d_axi_arburst),
        .m_axi_arvalid      (d_axi_arvalid),
        .m_axi_arready      (d_axi_arready),

        .m_axi_rid          (d_axi_rid),
        .m_axi_rdata        (d_axi_rdata),
        .m_axi_rresp        (d_axi_rresp),
        .m_axi_rlast        (d_axi_rlast),
        .m_axi_rvalid       (d_axi_rvalid),
        .m_axi_rready       (d_axi_rready)
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
    wire                    dma_axi_awvalid = 1'b0;
    wire                    dma_axi_awready;

    // Write Data
    wire [DW-1:0]           dma_axi_wdata;
    wire [(DW/8)-1:0]       dma_axi_wstrb;
    wire                    dma_axi_wlast;
    wire                    dma_axi_wvalid = 1'b0;
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
    wire                    dma_axi_arvalid = 1'b0;
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
    wire                    bt_axi_awvalid = 1'b0;
    wire                    bt_axi_awready;

    // Write Data
    wire [DW-1:0]           bt_axi_wdata;
    wire [(DW/8)-1:0]       bt_axi_wstrb;
    wire                    bt_axi_wlast;
    wire                    bt_axi_wvalid = 1'b0;
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
    wire                    bt_axi_arvalid = 1'b0;
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
    // ---- ch2 (unused) tie-offs ----
    wire                s2_awready_dummy, s2_wready_dummy, s2_bvalid_dummy;
    wire                s2_arready_dummy, s2_rlast_dummy,  s2_rvalid_dummy;
    wire                s2_bid_dummy, s2_rid_dummy;
    wire [31:0]         s2_rdata_dummy;
    wire [1:0]          s2_bresp_dummy, s2_rresp_dummy;

    //wire [1:0]          dummy_O_sdram_addr;
    wire   sdram_init_fin;

    sdram_4port_controller_axi_slave_bX_32bit #(
        .CLK_FREQ_MHz       (100),
        .ADDR_WIDTH         (24),
        .DATA_WIDTH         (32),
        .ID_WIDTH           (1)
    ) u_4port_sdram_axi (
        .aclk               (clock),
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
        .sdram_clk          (O_sdram_clk),    // FPGAでは位相調整する.
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

    // SDRAM信号
    wire            O_sdram_clk;
    wire            O_sdram_cke_n = 1'b1;
    wire            O_sdram_cs_n;
    wire            O_sdram_ras_n;
    wire            O_sdram_cas_n;
    wire            O_sdram_wen_n;
    wire [10:0]     O_sdram_addr;
    wire [1:0]      O_sdram_ba;
    wire [3:0]      O_sdram_dqm;  
    wire [31:0]     IO_sdram_dq;       // 32bit bus
    
    // ------------------------------
    // SDRAM モデル（GW2AR SDRAM）
    //   - CKEは常時High
    // ------------------------------
    // SDRAMモデル（GW2AR SDRAM）
    GW2AR_sdram u_sdram_model (
        .Dq         (IO_sdram_dq),
        .Addr       (O_sdram_addr),
        .Ba         (O_sdram_ba),
        .Clk        (O_sdram_clk),
        .Cke        (O_sdram_cke_n),
        .Cs_n       (O_sdram_cs_n),
        .Ras_n      (O_sdram_ras_n),
        .Cas_n      (O_sdram_cas_n),
        .We_n       (O_sdram_wen_n),
        .Dqm        (O_sdram_dqm)
    );

endmodule
