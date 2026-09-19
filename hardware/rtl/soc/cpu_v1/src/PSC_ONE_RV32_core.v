// ===============================================================
//  NISHIHARU Combined Top (CORE + I-Cache + D-Cache + Shared Bridge)
//  外部I/F：32bit SDRAM 単発アクセス
// ===============================================================
`timescale 1ns/1ps

// default cache word = 1024
`define ICache_256WORD
//`define DCache_256WORD
`define DCache_64WORD

// PSC_NPU_OFF mode
//`define PSC_NPU_OFF

module PSC_ONE_RV32_core #(
    // Mode 
`ifdef OS_SIM
    parameter PROTECT_MODE         = 1,
    parameter PROTECT_ADDR         = 32'h0001_0000,
`else
    parameter PROTECT_MODE         = 0,
    parameter PROTECT_ADDR         = 32'h0001_0000,
`endif
    // Parameter
    parameter integer ADDR_WIDTH   = 32,
    parameter integer ID_WIDTH     = 1,
    parameter integer DATA_WIDTH   = 32,    // AXI bus. fixed 32
    parameter integer CPU_DATA_WIDTH  = 32,  

    // MMIO MASK BITS
    parameter [ADDR_WIDTH-1:0]  MMMIO_BASK_BITS         = 32'h1000_F00F,
    // MMIO アドレス（0なら無効）
    parameter [ADDR_WIDTH-1:0]  UART_ADDRESS_TX         = 32'h1000_0000,
    parameter [ADDR_WIDTH-1:0]  UART_ADDRESS_RX         = 32'h1000_0004,
    parameter [ADDR_WIDTH-1:0]  UART_ADDRESS_ST         = 32'h1000_0008,
    parameter [ADDR_WIDTH-1:0]  UART_ADDRESS_CT         = 32'h1000_000C,
    parameter [ADDR_WIDTH-1:0]  PIO_ADDRESS             = 32'h1000_1000,
    parameter [ADDR_WIDTH-1:0]  TIMER_WRITE_ADDR        = 32'h1000_2000,
    parameter [ADDR_WIDTH-1:0]  TIMER_READ_ADDR         = 32'h1000_2004,
    parameter [ADDR_WIDTH-1:0]  TIMER_ST_ADDR           = 32'h1000_2008,
    parameter [ADDR_WIDTH-1:0]  LCD_PIXS_DATA           = 32'h1000_3000,
    parameter [ADDR_WIDTH-1:0]  LCD_PIXS_ST             = 32'h1000_3004,
    parameter [ADDR_WIDTH-1:0]  LED_ADDRESS             = 32'h1000_4000,
    parameter [ADDR_WIDTH-1:0]  PSC_SA_CTRL             = 32'h0,
    parameter [ADDR_WIDTH-1:0]  PSC_SA_STATUS           = 32'h0,
    parameter [ADDR_WIDTH-1:0]  PSC_SD_IF_READ_DATA     = 32'h1000_6000,
    parameter [ADDR_WIDTH-1:0]  PSC_SD_IF_SECTOR        = 32'h1000_6004,
    parameter [ADDR_WIDTH-1:0]  PSC_SD_IF_CTRL          = 32'h1000_6008,
    parameter [ADDR_WIDTH-1:0]  PSC_I2S_ADDR_RX         = 32'h1000_7000,
    parameter [ADDR_WIDTH-1:0]  PSC_I2S_ADDR_ST         = 32'h1000_7004,
    parameter [ADDR_WIDTH-1:0]  PSC_PFE_IF_DATA         = 32'h1000_8000,
    parameter [ADDR_WIDTH-1:0]  PSC_PFE_IF_CTRL         = 32'h1000_8004
)(
    // CLK, RESET
    input  wire                         clock,
    input  wire                         reset_n,
    input  wire                         cpu_stop,
    input  wire                         timer_irq_ext,
    output wire [8:0]                   uart_out,

    // MMIO
    output  wire                         mmio_valid,
    output  wire                         mmio_rw,          // 1:W, 0:R
    output  wire [ADDR_WIDTH-1:0]        mmio_addr,        // word address
    input   wire [CPU_DATA_WIDTH-1:0]    mmio_rdata,
    input wire                           mmio_ready,
    output wire  [CPU_DATA_WIDTH-1:0]    mmio_wdata,

    // -------------------------------
    // DMA IF
    // -------------------------------
    output wire  [CPU_DATA_WIDTH-1:0]    csr_DMA_CTRL,
    output wire  [CPU_DATA_WIDTH-1:0]    csr_DMA_WORDS,
    output wire  [CPU_DATA_WIDTH-1:0]    csr_DMA_SRC,
    output wire  [CPU_DATA_WIDTH-1:0]    csr_DMA_DST,
    input  wire  [CPU_DATA_WIDTH-1:0]    csr_DMA_STATUS,

    // -------------------------------
    // 外部：Shared I/D 32bit AXI IF (p_axi_*)
    // -------------------------------
    // ===== AXI4 Master (16-bit) =====
    // Write Address
    output wire  [ID_WIDTH-1:0]      p_axi_awid,
    output wire  [ADDR_WIDTH-1:0]    p_axi_awaddr,
    output wire  [7:0]               p_axi_awlen,         // 7 (=8beat)
    output wire  [2:0]               p_axi_awsize,        // 1 (2B)
    output wire  [1:0]               p_axi_awburst,       // INCR=01
    output wire                      p_axi_awvalid,
    input  wire                      p_axi_awready,

    // Write Data
    output wire  [DATA_WIDTH-1:0]    p_axi_wdata,
    output wire  [(DATA_WIDTH/8)-1:0]p_axi_wstrb,         // 2'b11
    output wire                      p_axi_wlast,
    output wire                      p_axi_wvalid,
    input  wire                      p_axi_wready,

    // Write Response
    input  wire [ID_WIDTH-1:0]       p_axi_bid,
    input  wire [1:0]                p_axi_bresp,
    input  wire                      p_axi_bvalid,
    output wire                      p_axi_bready,

    // Read Address
    output wire  [ID_WIDTH-1:0]      p_axi_arid,
    output wire  [ADDR_WIDTH-1:0]    p_axi_araddr,
    output wire  [7:0]               p_axi_arlen,         // 7 (=8beat)
    output wire  [2:0]               p_axi_arsize,        // 1
    output wire  [1:0]               p_axi_arburst,       // INCR
    output wire                      p_axi_arvalid,
    input  wire                      p_axi_arready,

    // Read Data
    input  wire [ID_WIDTH-1:0]       p_axi_rid,
    input  wire [DATA_WIDTH-1:0]     p_axi_rdata,
    input  wire [1:0]                p_axi_rresp,
    input  wire                      p_axi_rlast,
    input  wire                      p_axi_rvalid,
    output wire                      p_axi_rready,

    // -------------------------------
    // 外部：Unused compatibility AXI IF (d_axi_*)
    // -------------------------------
    // ===== AXI4 Master (16-bit) =====
    // Write Address
    output wire  [ID_WIDTH-1:0]      d_axi_awid,
    output wire  [ADDR_WIDTH-1:0]    d_axi_awaddr,
    output wire  [7:0]               d_axi_awlen,         // 7 (=8beat)
    output wire  [2:0]               d_axi_awsize,        // 1 (2B)
    output wire  [1:0]               d_axi_awburst,       // INCR=01
    output wire                      d_axi_awvalid,
    input  wire                      d_axi_awready,

    // Write Data
    output wire  [DATA_WIDTH-1:0]    d_axi_wdata,
    output wire  [(DATA_WIDTH/8)-1:0]d_axi_wstrb,         // 2'b11
    output wire                      d_axi_wlast,
    output wire                      d_axi_wvalid,
    input  wire                      d_axi_wready,

    // Write Response
    input  wire [ID_WIDTH-1:0]       d_axi_bid,
    input  wire [1:0]                d_axi_bresp,
    input  wire                      d_axi_bvalid,
    output wire                      d_axi_bready,

    // Read Address
    output wire  [ID_WIDTH-1:0]      d_axi_arid,
    output wire  [ADDR_WIDTH-1:0]    d_axi_araddr,
    output wire  [7:0]               d_axi_arlen,         // 7 (=8beat)
    output wire  [2:0]               d_axi_arsize,        // 1
    output wire  [1:0]               d_axi_arburst,       // INCR
    output wire                      d_axi_arvalid,
    input  wire                      d_axi_arready,

    // Read Data
    input  wire [ID_WIDTH-1:0]       d_axi_rid,
    input  wire [DATA_WIDTH-1:0]     d_axi_rdata,
    input  wire [1:0]                d_axi_rresp,
    input  wire                      d_axi_rlast,
    input  wire                      d_axi_rvalid,
    output wire                      d_axi_rready
);

    // --------------------------------
    // Csr to Data Cache
    // --------------------------------
    wire [31:0]  csr_DCACHE_CTRL;
    
    // --------------------------------
    // Csr to SynapEngine
    // --------------------------------
    wire [31:0]  csr_SA_CTRL;
    wire [31:0]  csr_SA_MODE;
    wire [31:0]  csr_SA_STATUS;
    wire [31:0]  csr_SA_ADDR_A;
    wire [31:0]  csr_SA_ADDR_B;
    wire [31:0]  csr_SA_ADDR_C;
    
    // --------------------------------
    // Csr to CPU MONITOR
    // --------------------------------
    wire [31:0]  csr_CPU_MON_CTRL;
    wire [31:0]  csr_CPU_MON_CYCLE;

    // --------------------------------
    // CORE <-> I/D メモリIF
    // --------------------------------
    wire         program_mem_burst_mode;
    wire         program_mem_read_valid;
    wire         program_mem_read_ready;
    wire [31:0]  program_mem_read_address;
    wire [31:0]  program_mem_read_data;
    wire         program_mem_req_ready;

    wire         is_fence_i;

    wire         data_mem_read_valid;
    wire         data_mem_read_ready;
    wire [31:0]  data_mem_read_address;
    wire [31:0]  data_mem_read_data;

    wire         data_mem_write_valid;
    wire         data_mem_write_ready;
    wire [31:0]  data_mem_write_address;
 
    wire         mmu_mem_read_valid;    // MMU
    wire         mmu_mem_read_ready;
    wire [31:0]  mmu_mem_read_address;
    wire [31:0]  mmu_mem_read_data;

    wire [2:0]   mem_write_sel;
    wire [31:0]  mem_write_data;

    wire         data_mem_req_ready;
    wire         mmu_data_req_ready;

    // --------------------------------
    // CORE
    // --------------------------------
    PSC_RV32_core #(
        .COUNTER_MMIO_ADDR          (32'hF004_FFF0)
    ) u_core (
        .clock                      (clock),
        .reset_n                    (reset_n),
        .cpu_stop                   (cpu_stop),
        .timer_irq_ext              (timer_irq_ext),

        .program_mem_burst_mode     (program_mem_burst_mode),
        .program_mem_read_valid     (program_mem_read_valid),
        .program_mem_read_ready     (program_mem_read_ready),
        .program_mem_read_address   (program_mem_read_address),
        .program_mem_read_data      (program_mem_read_data),
        .program_mem_req_ready      (program_mem_req_ready),

        .data_mem_read_valid        (data_mem_read_valid),
        .data_mem_read_ready        (data_mem_read_ready),
        .data_mem_read_address      (data_mem_read_address),
        .data_mem_read_data         (data_mem_read_data),
        .data_mem_req_ready         (data_mem_req_ready),

        .data_mem_write_ready       (data_mem_write_ready),
        .data_mem_write_valid       (data_mem_write_valid),
        .mem_write_sel              (mem_write_sel),
        .mem_write_address          (data_mem_write_address),
        .mem_write_data             (mem_write_data),

        .mmu_data_mem_read_valid    (mmu_mem_read_valid),
        .mmu_data_mem_read_ready    (mmu_mem_read_ready),     
        .mmu_data_mem_read_address  (mmu_mem_read_address),
        .mmu_data_mem_read_data     (mmu_mem_read_data),
        .mmu_data_req_ready         (mmu_data_req_ready),

        .is_fence_i                 (is_fence_i),       // cache clear

        .csr_DCACHE_CTRL            (csr_DCACHE_CTRL),  // DATA Cache

        .csr_DMA_CTRL               (csr_DMA_CTRL),     // DMA
        .csr_DMA_WORDS              (csr_DMA_WORDS), 
        .csr_DMA_SRC                (csr_DMA_SRC), 
        .csr_DMA_DST                (csr_DMA_DST), 
        .csr_DMA_STATUS             (csr_DMA_STATUS), 

        .csr_SA_CTRL                (csr_SA_CTRL),      // SynapEngine
        .csr_SA_MODE                (csr_SA_MODE), 
        .csr_SA_STATUS              (csr_SA_STATUS),
        .csr_SA_ADDR_A              (csr_SA_ADDR_A),
        .csr_SA_ADDR_B              (csr_SA_ADDR_B),
        .csr_SA_ADDR_C              (csr_SA_ADDR_C),

        .csr_CPU_MON_CTRL           (csr_CPU_MON_CTRL),
        .csr_CPU_MON_CYCLE          (csr_CPU_MON_CYCLE),

        .uart_out                   (uart_out)
    );

    // ============================================================
    //  SynapEngine 4x4 or 2x2
    // ============================================================
    wire sa_read_valid;
    wire sa_read_ready;
    wire sa_write_valid;
    wire sa_write_ready;
    wire [31:0] sa_read_addr;
    wire [31:0] sa_read_data;
    wire [31:0] sa_write_addr;
    wire [31:0] sa_write_data;

    // sa controll.
    wire sa_busy;
    wire sa_done;
    assign csr_SA_STATUS = {30'b0, sa_busy, sa_done};
    wire sa_start         = csr_SA_CTRL[0];
    wire sa_state_reset   = csr_SA_CTRL[1];
    wire sa_clear         = csr_SA_CTRL[2];
    wire signed_mode      = csr_SA_CTRL[3];
    wire [3:0] sa_os_instruction 
                          = csr_SA_CTRL[11:8];
    wire [7:0] sa_matrix_size_x 
                          = csr_SA_CTRL[23:16];
    wire [7:0] sa_matrix_size_y 
                          = csr_SA_CTRL[31:24];

    //wire sa_os_mode = csr_SA_MODE[0];
    
    // addr, data, valid
    wire sa_valid = sa_read_valid | sa_write_valid;
    wire [31:0] sa_addr =   sa_read_valid  ? sa_read_addr  : 
                            sa_write_valid ? sa_write_addr : 32'h0;
    wire [31:0] sa_data =   sa_write_data;

    // sa_ready
    wire sa_ready;
    assign sa_read_ready    = sa_ready;
    assign sa_write_ready   = sa_ready;

    // sa_data_out
    wire [31:0] sa_data_out;
    assign sa_read_data = sa_data_out;

    wire sa_rw = sa_write_valid;
    wire sa_req_ready;

    //PSC_NPU_Controller u_systolic (
    PSC_NPU_Controller u_systolic (
        .clock              (clock),
        `ifdef PSC_NPU_OFF
        .reset_n            (1'b0),
        `else
        .reset_n            (reset_n),
        `endif

        // SA Control
        .signed_mode        (signed_mode),
        .start              (sa_start),
        .sa_state_reset     (sa_state_reset),
        .sa_os_instruction  (sa_os_instruction),
        .sa_clear           (sa_clear),

        .matrix_size_x      (sa_matrix_size_x),
        .matrix_size_y      (sa_matrix_size_y),

        // SDRAM base address
        .BASE_ADDR_A        (csr_SA_ADDR_A),
        .BASE_ADDR_B        (csr_SA_ADDR_B),
        .BASE_ADDR_C        (csr_SA_ADDR_C),

        // cache_io ready
        .sa_req_ready       (sa_req_ready),

        // READ port
        .rd_read_addr       (sa_read_addr),
        .rd_read_valid      (sa_read_valid),
        .rd_read_ready      (sa_read_ready),
        .rd_read_data       (sa_read_data),

        // WRITE port
        .c_write_valid      (sa_write_valid),
        .c_write_addr       (sa_write_addr),
        .c_write_wdata      (sa_write_data),
        .c_write_ready      (sa_write_ready),

        // status
        .busy               (sa_busy),
        .done               (sa_done)
    );

    // ===========================================================
    //  Program キャッシュ（I-Cache 相当）
    // ===========================================================
    // cache <-> bridge（256bit ライン側）
    wire         p_mem_valid256;
    wire         p_mem_rw256;
    wire         p_mem_ready256;
    wire [255:0] p_mem_rdata256;
    wire [31:0]  p_mem_addr256;
    wire [255:0] p_mem_wdata256;

    wire         program_cache_hit_pulse;
    wire         program_cache_miss_pulse;

    cache_dma_controller #(
        .ADDR_WIDTH          (32),
        .CPU_DATA_WIDTH      (32),
        .CACHE_DATA_WIDTH    (256),
        .MAIN_MEM_DATA_WIDTH (256),
        .TAGMSB              (31),
        `ifdef ICache_256WORD
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
        .burst_mode         (program_mem_burst_mode),
        .cpu_ready          (program_mem_read_ready),
        .cpu_data_out       (program_mem_read_data),
        .cpu_req_ready      (program_mem_req_ready),
        .cpu_cache_clear    (is_fence_i),
        // 256b 側
        .mem_req_ready      (1'b1),             // 1'b1 fix
        .mem_valid          (p_mem_valid256),
        .mem_rw             (p_mem_rw256),
        .mem_ready          (p_mem_ready256),
        .mem_data_in        (p_mem_rdata256),
        .mem_addr           (p_mem_addr256),
        .mem_data_out       (p_mem_wdata256),
        // CACHE MONITOR
        .cache_hit_pulse    (program_cache_hit_pulse),
        .cache_miss_pulse   (program_cache_miss_pulse)
    );

    // ===========================================================
    //  Data キャッシュ（D-Cache 相当）
    // ===========================================================
    wire         d_mem_valid256;
    wire         d_mem_rw256;
    wire         d_mem_ready256;
    wire [255:0] d_mem_rdata256;
    wire [31:0]  d_mem_addr256;
    wire [255:0] d_mem_wdata256;

    wire dcache_ready;

    // コアへ返す ready（READ/WRITE 共通）
    assign data_mem_read_ready  = dcache_ready;
    assign data_mem_write_ready = dcache_ready;

    // clear, WB
    wire    cpu_cache_clear = csr_DCACHE_CTRL[0];
    wire    cpu_cache_wb    = csr_DCACHE_CTRL[1];

    cache_dma_controller_io #(
        .PROTECT_MODE        (PROTECT_MODE),
        .PROTECT_ADDR        (PROTECT_ADDR),
        .ADDR_WIDTH          (32),
        .CPU_DATA_WIDTH      (32),
        .CACHE_DATA_WIDTH    (256),
        .MAIN_MEM_DATA_WIDTH (256),
        .TAGMSB              (31),
        `ifdef DCache_256WORD
        .TAGLSB              (12),
        `elsif DCache_64WORD
        .TAGLSB              (10),
        `else
        .TAGLSB              (14),
        `endif
        // MMIO MASK BITS
        .MMMIO_BASK_BITS     (MMMIO_BASK_BITS),
        // MMIO ADDR
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
    ) u_data_dma_ctrl (
        .clock              (clock),
        .reset_n            (reset_n),
        // CPU Data
        .cpu_rvalid         (data_mem_read_valid),
        .cpu_wvalid         (data_mem_write_valid),
        .cpu_rw             (data_mem_write_valid),
        .cpu_write_sel      (mem_write_sel),
        .cpu_raddr          (data_mem_read_address),
        .cpu_waddr          (data_mem_write_address),
        .cpu_data           (mem_write_data),
        .cpu_ready          (dcache_ready),
        .cpu_data_out       (data_mem_read_data),
        .cpu_req_ready      (data_mem_req_ready),
        .cpu_cache_clear    (cpu_cache_clear),
        .cpu_cache_wb       (cpu_cache_wb),
        // SynapEngine
        .sa_valid           (sa_valid),    
        .sa_rw              (sa_rw),    
        .sa_addr            (sa_addr),
        .sa_data            (sa_data),
        .sa_ready           (sa_ready),
        .sa_data_out        (sa_data_out),
        .sa_req_ready       (sa_req_ready),
        // MMU
        .mmu_valid          (mmu_mem_read_valid),
        .mmu_addr           (mmu_mem_read_address),
        .mmu_ready          (mmu_mem_read_ready),
        .mmu_data_out       (mmu_mem_read_data),
        .mmu_req_ready      (mmu_data_req_ready),
        // MMIO
        .mmio_valid         (mmio_valid),
        .mmio_rw            (mmio_rw),
        .mmio_addr          (mmio_addr),
        .mmio_rdata         (mmio_rdata),
        .mmio_ready         (mmio_ready),
        .mmio_wdata         (mmio_wdata),
        // 256b 側
        .mem_req_ready      (1'b1),             // 1'b1 fix
        .mem_valid          (d_mem_valid256),
        .mem_rw             (d_mem_rw256),
        .mem_ready          (d_mem_ready256),
        .mem_data_in        (d_mem_rdata256),
        .mem_addr           (d_mem_addr256),
        .mem_data_out       (d_mem_wdata256),
        // CACHE MONITOR
        .cache_hit_pulse    (data_cache_hit_pulse),
        .cache_miss_pulse   (data_cache_miss_pulse)
    );

    // ============================================================
    // D-Cache completion and unused AXI tie-offs
    // ============================================================

    wire d_cache_rd_ready;
    wire d_cache_wr_ready;
    assign d_mem_ready256 = d_cache_rd_ready | d_cache_wr_ready;

    // Compatibility only: the former D-Cache AXI master is inactive.
    // No d_axi_* input participates in the shared bridge's control.
    assign d_axi_awid    = '0;
    assign d_axi_awaddr  = '0;
    assign d_axi_awlen   = '0;
    assign d_axi_awsize  = '0;
    assign d_axi_awburst = '0;
    assign d_axi_awvalid = '0;
    assign d_axi_wdata   = '0;
    assign d_axi_wstrb   = '0;
    assign d_axi_wlast   = '0;
    assign d_axi_wvalid  = '0;
    assign d_axi_bready  = '0;
    assign d_axi_arid    = '0;
    assign d_axi_araddr  = '0;
    assign d_axi_arlen   = '0;
    assign d_axi_arsize  = '0;
    assign d_axi_arburst = '0;
    assign d_axi_arvalid = '0;
    assign d_axi_rready  = '0;

    // ============================================================
    // Bridge (256b ⇄ AXI4-M(32b)) と AXI配線
    // ============================================================
    localparam integer SYS_ADDR_WIDTH = 32;
    localparam integer AXI_ID_WIDTH   = 1;
    localparam integer AXI_DATA_WIDTH = 32;

    wire         data_cache_hit_pulse;
    wire         data_cache_miss_pulse;

    // ---------------- Bridge (AXI Master, 32-bit) ----------------
    sdram_32bit_to_256bit_axi_bridge #(
        .ADDR_WIDTH         (SYS_ADDR_WIDTH),
        .ID_WIDTH           (AXI_ID_WIDTH),
        .DATA_WIDTH         (AXI_DATA_WIDTH)
    ) shared_axi_bridge (
        .clock              (clock),
        .reset_n            (reset_n),

        // Independent cache line ports; all transactions use p_axi_*.
        .i_read_valid       (p_mem_valid256 & ~p_mem_rw256),
        .i_read_ready       (p_mem_ready256),
        .i_read_addr        (p_mem_addr256),
        .i_read_data        (p_mem_rdata256),
        .d_read_valid       (d_mem_valid256 & ~d_mem_rw256),
        .d_read_ready       (d_cache_rd_ready),
        .d_read_addr        (d_mem_addr256),
        .d_read_data        (d_mem_rdata256),
        .d_write_valid      (d_mem_valid256 & d_mem_rw256),
        .d_write_ready      (d_cache_wr_ready),
        .d_write_addr       (d_mem_addr256),
        .d_write_data       (d_mem_wdata256),

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

    //==========================================================
    // CPU monitor
    //==========================================================

    // CPU Monitor
    PSC_RV32_Monitor #(
        .CLK_FREQ_MHz       (80)
    ) u_cpu_monitor (
        .clock              (clock),
        .reset_n            (reset_n),

        // CSR
        .PSC_CPU_MON_CTRL           (csr_CPU_MON_CTRL),
        .PSC_CPU_MON_CYCLE          (csr_CPU_MON_CYCLE),
        // CACHE MONITOR
        .program_cache_hit_pulse    (program_cache_hit_pulse),
        .program_cache_miss_pulse   (program_cache_miss_pulse),
        .data_cache_hit_pulse       (data_cache_hit_pulse),
        .data_cache_miss_pulse      (data_cache_miss_pulse)
    );

endmodule