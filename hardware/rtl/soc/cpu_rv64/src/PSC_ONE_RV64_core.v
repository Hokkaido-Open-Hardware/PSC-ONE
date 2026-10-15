`timescale 1ns/1ps
// RV64 uncached integration wrapper. The legacy external signal names are kept.
// Core simulation instantiates PSC_RV64_core directly, not this wrapper.
// No RV32 cache/NPU modules are included. Cache control CSRs have no effect.
// TODO: SoC/MMIO integration verification, cache/NPU integration and bus-fault traps.
module PSC_ONE_RV64_core #(
    // Mode
`ifdef PSCOS_SIM
    parameter PROTECT_MODE         = 1,
    parameter PROTECT_ADDR         = 64'h0001_0000,
`else
    parameter PROTECT_MODE         = 0,
    parameter PROTECT_ADDR         = 64'h0001_0000,
`endif
    // Parameter
    parameter integer ADDR_WIDTH   = 64,
    parameter integer ID_WIDTH     = 1,
    parameter integer DATA_WIDTH   = 64,    // AXI bus. fixed 64
    parameter integer CPU_DATA_WIDTH  = 64,

    // MMIO MASK BITS
    parameter [ADDR_WIDTH-1:0]  MMMIO_BASK_BITS         = 64'h1000_FFFF,
    // MMIO アドレス（0なら無効）
    parameter [ADDR_WIDTH-1:0]  UART_ADDRESS_TX         = 64'h1000_0000,
    parameter [ADDR_WIDTH-1:0]  UART_ADDRESS_RX         = 64'h1000_0004,
    parameter [ADDR_WIDTH-1:0]  UART_ADDRESS_ST         = 64'h1000_0008,
    parameter [ADDR_WIDTH-1:0]  UART_ADDRESS_CT         = 64'h1000_000C,
    parameter [ADDR_WIDTH-1:0]  PIO_ADDRESS             = 64'h1000_1000,
    parameter [ADDR_WIDTH-1:0]  TIMER_WRITE_ADDR        = 64'h1000_2000,
    parameter [ADDR_WIDTH-1:0]  TIMER_READ_ADDR         = 64'h1000_2004,
    parameter [ADDR_WIDTH-1:0]  TIMER_ST_ADDR           = 64'h1000_2008,
    parameter [ADDR_WIDTH-1:0]  LCD_PIXS_DATA           = 64'h1000_3000,
    parameter [ADDR_WIDTH-1:0]  LCD_PIXS_ST             = 64'h1000_3004,
    parameter [ADDR_WIDTH-1:0]  LED_ADDRESS             = 64'h1000_4000,
    parameter [ADDR_WIDTH-1:0]  PSC_SA_CTRL             = 64'h0,
    parameter [ADDR_WIDTH-1:0]  PSC_SA_STATUS           = 64'h0,
    parameter [ADDR_WIDTH-1:0]  PSC_SD_IF_READ_DATA     = 64'h1000_6000,
    parameter [ADDR_WIDTH-1:0]  PSC_SD_IF_SECTOR        = 64'h1000_6004,
    parameter [ADDR_WIDTH-1:0]  PSC_SD_IF_CTRL          = 64'h1000_6008,
    parameter [ADDR_WIDTH-1:0]  PSC_I2S_ADDR_RX         = 64'h1000_7000,
    parameter [ADDR_WIDTH-1:0]  PSC_I2S_ADDR_ST         = 64'h1000_7004,
    parameter [ADDR_WIDTH-1:0]  PSC_PFE_IF_DATA         = 64'h1000_8000,
    parameter [ADDR_WIDTH-1:0]  PSC_PFE_IF_CTRL         = 64'h1000_8004,
    parameter [ADDR_WIDTH-1:0]  I2C_ADDR_INPUT          = 64'h1000_9000,
    parameter [ADDR_WIDTH-1:0]  I2C_ADDR_STATUS         = 64'h1000_9004,
    parameter [ADDR_WIDTH-1:0]  I2C_ADDR_OUTPUT         = 64'h1000_9008,
    parameter [ADDR_WIDTH-1:0]  I2C_ADDR_CONTROL        = 64'h1000_900C,
    parameter [ADDR_WIDTH-1:0]  I2C_ADDR_SEQ            = 64'h1000_9010,
    parameter ENABLE_PULP = 1'b0
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
    // 外部：Shared I/D 64bit AXI IF (p_axi_*)
    // -------------------------------
    // ===== AXI4 Master (64-bit) =====
    // Write Address
    output wire  [ID_WIDTH-1:0]      p_axi_awid,
    output wire  [ADDR_WIDTH-1:0]    p_axi_awaddr,
    output wire  [7:0]               p_axi_awlen,         // burst length minus one
    output wire  [2:0]               p_axi_awsize,        // log2(bytes)
    output wire  [1:0]               p_axi_awburst,       // INCR=01
    output wire                      p_axi_awvalid,
    input  wire                      p_axi_awready,

    // Write Data
    output wire  [DATA_WIDTH-1:0]    p_axi_wdata,
    output wire  [(DATA_WIDTH/8)-1:0]p_axi_wstrb,         // byte lanes
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
    output wire  [7:0]               p_axi_arlen,         // burst length minus one
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
    // ===== AXI4 Master (64-bit) =====
    // Write Address
    output wire  [ID_WIDTH-1:0]      d_axi_awid,
    output wire  [ADDR_WIDTH-1:0]    d_axi_awaddr,
    output wire  [7:0]               d_axi_awlen,         // burst length minus one
    output wire  [2:0]               d_axi_awsize,        // log2(bytes)
    output wire  [1:0]               d_axi_awburst,       // INCR=01
    output wire                      d_axi_awvalid,
    input  wire                      d_axi_awready,

    // Write Data
    output wire  [DATA_WIDTH-1:0]    d_axi_wdata,
    output wire  [(DATA_WIDTH/8)-1:0]d_axi_wstrb,         // byte lanes
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
    output wire  [7:0]               d_axi_arlen,         // burst length minus one
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

    initial begin
        if (ADDR_WIDTH != 64 || DATA_WIDTH != 64 || CPU_DATA_WIDTH != 64)
            $fatal(1, "RV64 wrapper requires 64-bit address/data buses");
        if (PROTECT_MODE != 0 || ENABLE_PULP != 0)
            $fatal(1, "RV64 uncached wrapper does not implement protection or PULP");
    end
    wire bus_fault;
    // --------------------------------
    // Csr to Data Cache
    // --------------------------------
    wire [63:0]  csr_DCACHE_CTRL;

    // --------------------------------
    // Csr to SynapEngine
    // --------------------------------
    wire [63:0]  csr_SA_CTRL;
    wire [63:0]  csr_SA_SIZE;
    wire [63:0]  csr_SA_STATUS;
    wire [63:0]  csr_SA_ADDR_A;
    wire [63:0]  csr_SA_ADDR_B;
    wire [63:0]  csr_SA_ADDR_C;

    // --------------------------------
    // Csr to CPU MONITOR
    // --------------------------------
    wire [63:0]  csr_CPU_MON_CTRL;
    wire [63:0]  csr_CPU_MON_CYCLE;

    // --------------------------------
    // CORE <-> I/D メモリIF
    // --------------------------------
    wire         program_mem_burst_mode;
    wire         program_mem_read_valid;
    wire         program_mem_read_ready;
    wire [63:0]  program_mem_read_address;
    wire [31:0]  program_mem_read_data;
    wire         program_mem_req_ready;

    wire         is_fence_i;

    wire         data_rw_double;
    wire         data_mem_read_valid;
    wire         data_mem_read_ready;
    wire [63:0]  data_mem_read_address;
    wire [63:0]  data_mem_read_data;

    wire         data_mem_write_valid;
    wire         data_mem_write_ready;
    wire [63:0]  data_mem_write_address;

    wire         mmu_mem_read_valid;    // MMU
    wire         mmu_mem_read_ready;
    wire [63:0]  mmu_mem_read_address;
    wire [63:0]  mmu_mem_read_data;

    wire [2:0]   mem_write_sel;
    wire [63:0]  mem_write_data;

    wire         data_mem_req_ready;
    wire         mmu_data_req_ready;

    // --------------------------------
    // CORE
    // --------------------------------
    PSC_RV64_core #(
        .COUNTER_MMIO_ADDR          (64'hF004_FFF0),
        .ENABLE_PULP                (ENABLE_PULP)
    ) u_core (
        .clock                      (clock),
        .reset_n                    (reset_n),
        .cpu_stop                   (cpu_stop || bus_fault),
        .timer_irq_ext              (timer_irq_ext),

        .program_mem_burst_mode     (program_mem_burst_mode),
        .program_mem_read_valid     (program_mem_read_valid),
        .program_mem_read_ready     (program_mem_read_ready),
        .program_mem_read_address   (program_mem_read_address),
        .program_mem_read_data      (program_mem_read_data),
        .program_mem_req_ready      (program_mem_req_ready),

        .data_mem_read_valid        (data_mem_read_valid),
        .data_rw_double             (data_rw_double),
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
        .csr_SA_SIZE                (csr_SA_SIZE),
        .csr_SA_STATUS              (csr_SA_STATUS),
        .csr_SA_ADDR_A              (csr_SA_ADDR_A),
        .csr_SA_ADDR_B              (csr_SA_ADDR_B),
        .csr_SA_ADDR_C              (csr_SA_ADDR_C),

        .csr_CPU_MON_CTRL           (csr_CPU_MON_CTRL),
        .csr_CPU_MON_CYCLE          (csr_CPU_MON_CYCLE),

        .uart_out                   (uart_out)
    );


    // No cache/NPU/MMU side effects in this Bare-only wrapper.
    assign csr_SA_STATUS = 64'b0;
    assign mmu_mem_read_ready = 1'b0;
    assign mmu_mem_read_data = 64'b0;
    assign mmu_data_req_ready = 1'b0;
    wire [63:0] access_address = data_mem_write_valid
                              ? data_mem_write_address : data_mem_read_address;
    wire access_is_mmio =
        ((UART_ADDRESS_TX != 0) && (access_address == UART_ADDRESS_TX)) ||
        ((UART_ADDRESS_RX != 0) && (access_address == UART_ADDRESS_RX)) ||
        ((UART_ADDRESS_ST != 0) && (access_address == UART_ADDRESS_ST)) ||
        ((UART_ADDRESS_CT != 0) && (access_address == UART_ADDRESS_CT)) ||
        ((PIO_ADDRESS != 0) && (access_address == PIO_ADDRESS)) ||
        ((TIMER_WRITE_ADDR != 0) && (access_address == TIMER_WRITE_ADDR)) ||
        ((TIMER_READ_ADDR != 0) && (access_address == TIMER_READ_ADDR)) ||
        ((TIMER_ST_ADDR != 0) && (access_address == TIMER_ST_ADDR)) ||
        ((LCD_PIXS_DATA != 0) && (access_address == LCD_PIXS_DATA)) ||
        ((LCD_PIXS_ST != 0) && (access_address == LCD_PIXS_ST)) ||
        ((LED_ADDRESS != 0) && (access_address == LED_ADDRESS)) ||
        ((PSC_SA_CTRL != 0) && (access_address == PSC_SA_CTRL)) ||
        ((PSC_SA_STATUS != 0) && (access_address == PSC_SA_STATUS)) ||
        ((PSC_SD_IF_READ_DATA != 0) && (access_address == PSC_SD_IF_READ_DATA)) ||
        ((PSC_SD_IF_SECTOR != 0) && (access_address == PSC_SD_IF_SECTOR)) ||
        ((PSC_SD_IF_CTRL != 0) && (access_address == PSC_SD_IF_CTRL)) ||
        ((PSC_I2S_ADDR_RX != 0) && (access_address == PSC_I2S_ADDR_RX)) ||
        ((PSC_I2S_ADDR_ST != 0) && (access_address == PSC_I2S_ADDR_ST)) ||
        ((PSC_PFE_IF_DATA != 0) && (access_address == PSC_PFE_IF_DATA)) ||
        ((PSC_PFE_IF_CTRL != 0) && (access_address == PSC_PFE_IF_CTRL)) ||
        ((I2C_ADDR_INPUT != 0) && (access_address == I2C_ADDR_INPUT)) ||
        ((I2C_ADDR_STATUS != 0) && (access_address == I2C_ADDR_STATUS)) ||
        ((I2C_ADDR_OUTPUT != 0) && (access_address == I2C_ADDR_OUTPUT)) ||
        ((I2C_ADDR_CONTROL != 0) && (access_address == I2C_ADDR_CONTROL)) ||
        ((I2C_ADDR_SEQ != 0) && (access_address == I2C_ADDR_SEQ));

    PSC_RV64_AXI #(.ID_WIDTH(ID_WIDTH)) u_axi (
        .clock(clock), .reset_n(reset_n),
        .i_valid(program_mem_read_valid), .i_burst(program_mem_burst_mode),
        .i_addr(program_mem_read_address), .i_req_ready(program_mem_req_ready),
        .i_ready(program_mem_read_ready), .i_data(program_mem_read_data),
        .d_rvalid(data_mem_read_valid), .d_wvalid(data_mem_write_valid),
        .d_double(data_rw_double),
        .d_raddr(data_mem_read_address), .d_waddr(data_mem_write_address),
        .d_wdata(mem_write_data), .d_sel(mem_write_sel), .d_is_mmio(access_is_mmio),
        .d_req_ready(data_mem_req_ready), .d_rready(data_mem_read_ready),
        .d_wready(data_mem_write_ready), .d_rdata(data_mem_read_data),
        .mmio_valid(mmio_valid), .mmio_rw(mmio_rw), .mmio_addr(mmio_addr),
        .mmio_wdata(mmio_wdata), .mmio_rdata(mmio_rdata), .mmio_ready(mmio_ready),
        .fault(bus_fault),
        .axi_awid(p_axi_awid),
        .axi_awaddr(p_axi_awaddr),
        .axi_awlen(p_axi_awlen),
        .axi_awsize(p_axi_awsize),
        .axi_awburst(p_axi_awburst),
        .axi_awvalid(p_axi_awvalid),
        .axi_awready(p_axi_awready),
        .axi_wdata(p_axi_wdata),
        .axi_wstrb(p_axi_wstrb),
        .axi_wlast(p_axi_wlast),
        .axi_wvalid(p_axi_wvalid),
        .axi_wready(p_axi_wready),
        .axi_bid(p_axi_bid),
        .axi_bresp(p_axi_bresp),
        .axi_bvalid(p_axi_bvalid),
        .axi_bready(p_axi_bready),
        .axi_arid(p_axi_arid),
        .axi_araddr(p_axi_araddr),
        .axi_arlen(p_axi_arlen),
        .axi_arsize(p_axi_arsize),
        .axi_arburst(p_axi_arburst),
        .axi_arvalid(p_axi_arvalid),
        .axi_arready(p_axi_arready),
        .axi_rid(p_axi_rid),
        .axi_rdata(p_axi_rdata),
        .axi_rresp(p_axi_rresp),
        .axi_rlast(p_axi_rlast),
        .axi_rvalid(p_axi_rvalid),
        .axi_rready(p_axi_rready)
    );
    assign d_axi_awid = '0;
    assign d_axi_awaddr = '0;
    assign d_axi_awlen = '0;
    assign d_axi_awsize = '0;
    assign d_axi_awburst = '0;
    assign d_axi_awvalid = '0;
    assign d_axi_wdata = '0;
    assign d_axi_wstrb = '0;
    assign d_axi_wlast = '0;
    assign d_axi_wvalid = '0;
    assign d_axi_bready = '0;
    assign d_axi_arid = '0;
    assign d_axi_araddr = '0;
    assign d_axi_arlen = '0;
    assign d_axi_arsize = '0;
    assign d_axi_arburst = '0;
    assign d_axi_arvalid = '0;
    assign d_axi_rready = '0;

    PSC_RV64_Monitor u_cpu_monitor (
        .clock(clock), .reset_n(reset_n),
        .PSC_CPU_MON_CTRL(csr_CPU_MON_CTRL), .PSC_CPU_MON_CYCLE(csr_CPU_MON_CYCLE),
        .program_cache_hit_pulse(1'b0), .program_cache_miss_pulse(program_mem_read_valid),
        .data_cache_hit_pulse(1'b0),
        .data_cache_miss_pulse(data_mem_read_valid || data_mem_write_valid)
    );
endmodule
