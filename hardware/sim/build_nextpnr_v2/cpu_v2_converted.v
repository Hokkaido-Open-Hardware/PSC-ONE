module PSC_ONE_RV32ISP_core (
	clock,
	reset_n,
	cpu_stop,
	uart_out,
	mmio_valid,
	mmio_rw,
	mmio_addr,
	mmio_rdata,
	mmio_ready,
	mmio_wdata,
	csr_DMA_CTRL,
	csr_DMA_WORDS,
	csr_DMA_SRC,
	csr_DMA_DST,
	csr_DMA_STATUS,
	p_axi_awid,
	p_axi_awaddr,
	p_axi_awlen,
	p_axi_awsize,
	p_axi_awburst,
	p_axi_awvalid,
	p_axi_awready,
	p_axi_wdata,
	p_axi_wstrb,
	p_axi_wlast,
	p_axi_wvalid,
	p_axi_wready,
	p_axi_bid,
	p_axi_bresp,
	p_axi_bvalid,
	p_axi_bready,
	p_axi_arid,
	p_axi_araddr,
	p_axi_arlen,
	p_axi_arsize,
	p_axi_arburst,
	p_axi_arvalid,
	p_axi_arready,
	p_axi_rid,
	p_axi_rdata,
	p_axi_rresp,
	p_axi_rlast,
	p_axi_rvalid,
	p_axi_rready,
	d_axi_awid,
	d_axi_awaddr,
	d_axi_awlen,
	d_axi_awsize,
	d_axi_awburst,
	d_axi_awvalid,
	d_axi_awready,
	d_axi_wdata,
	d_axi_wstrb,
	d_axi_wlast,
	d_axi_wvalid,
	d_axi_wready,
	d_axi_bid,
	d_axi_bresp,
	d_axi_bvalid,
	d_axi_bready,
	d_axi_arid,
	d_axi_araddr,
	d_axi_arlen,
	d_axi_arsize,
	d_axi_arburst,
	d_axi_arvalid,
	d_axi_arready,
	d_axi_rid,
	d_axi_rdata,
	d_axi_rresp,
	d_axi_rlast,
	d_axi_rvalid,
	d_axi_rready
);
	parameter PROTECT_MODE = 0;
	parameter PROTECT_ADDR = 32'h00010000;
	parameter integer ADDR_WIDTH = 32;
	parameter integer ID_WIDTH = 1;
	parameter integer DATA_WIDTH = 32;
	parameter integer CPU_DATA_WIDTH = 32;
	parameter [ADDR_WIDTH - 1:0] UART_ADDRESS_TX = 32'h10000000;
	parameter [ADDR_WIDTH - 1:0] UART_ADDRESS_RX = 32'h10000004;
	parameter [ADDR_WIDTH - 1:0] UART_ADDRESS_ST = 32'h10000008;
	parameter [ADDR_WIDTH - 1:0] UART_ADDRESS_CT = 32'h1000000c;
	parameter [ADDR_WIDTH - 1:0] PIO_ADDRESS = 32'h10001000;
	parameter [ADDR_WIDTH - 1:0] TIMER_WRITE_ADDR = 32'h10002000;
	parameter [ADDR_WIDTH - 1:0] TIMER_READ_ADDR = 32'h10002004;
	parameter [ADDR_WIDTH - 1:0] TIMER_ST_ADDR = 32'h10002008;
	parameter [ADDR_WIDTH - 1:0] LCD_PIXS_DATA = 32'h10003000;
	parameter [ADDR_WIDTH - 1:0] LCD_PIXS_ST = 32'h10003004;
	parameter [ADDR_WIDTH - 1:0] LED_ADDRESS = 32'h10004000;
	parameter [ADDR_WIDTH - 1:0] PSC_SA_CTRL = 32'h00000000;
	parameter [ADDR_WIDTH - 1:0] PSC_SA_STATUS = 32'h00000000;
	parameter [ADDR_WIDTH - 1:0] PSC_SD_IF_READ_DATA = 32'h10006000;
	parameter [ADDR_WIDTH - 1:0] PSC_SD_IF_SECTOR = 32'h10006004;
	parameter [ADDR_WIDTH - 1:0] PSC_SD_IF_CTRL = 32'h10006008;
	parameter [ADDR_WIDTH - 1:0] PSC_I2S_ADDR_RX = 32'h10007000;
	parameter [ADDR_WIDTH - 1:0] PSC_I2S_ADDR_ST = 32'h10007004;
	parameter [ADDR_WIDTH - 1:0] PSC_PFE_IF_DATA = 32'h10008000;
	parameter [ADDR_WIDTH - 1:0] PSC_PFE_IF_CTRL = 32'h10008004;
	input wire clock;
	input wire reset_n;
	input wire cpu_stop;
	output wire [8:0] uart_out;
	output wire mmio_valid;
	output wire mmio_rw;
	output wire [ADDR_WIDTH - 1:0] mmio_addr;
	input wire [CPU_DATA_WIDTH - 1:0] mmio_rdata;
	input wire mmio_ready;
	output wire [CPU_DATA_WIDTH - 1:0] mmio_wdata;
	output wire [CPU_DATA_WIDTH - 1:0] csr_DMA_CTRL;
	output wire [CPU_DATA_WIDTH - 1:0] csr_DMA_WORDS;
	output wire [CPU_DATA_WIDTH - 1:0] csr_DMA_SRC;
	output wire [CPU_DATA_WIDTH - 1:0] csr_DMA_DST;
	input wire [CPU_DATA_WIDTH - 1:0] csr_DMA_STATUS;
	output wire [ID_WIDTH - 1:0] p_axi_awid;
	output wire [ADDR_WIDTH - 1:0] p_axi_awaddr;
	output wire [7:0] p_axi_awlen;
	output wire [2:0] p_axi_awsize;
	output wire [1:0] p_axi_awburst;
	output wire p_axi_awvalid;
	input wire p_axi_awready;
	output wire [DATA_WIDTH - 1:0] p_axi_wdata;
	output wire [(DATA_WIDTH / 8) - 1:0] p_axi_wstrb;
	output wire p_axi_wlast;
	output wire p_axi_wvalid;
	input wire p_axi_wready;
	input wire [ID_WIDTH - 1:0] p_axi_bid;
	input wire [1:0] p_axi_bresp;
	input wire p_axi_bvalid;
	output wire p_axi_bready;
	output wire [ID_WIDTH - 1:0] p_axi_arid;
	output wire [ADDR_WIDTH - 1:0] p_axi_araddr;
	output wire [7:0] p_axi_arlen;
	output wire [2:0] p_axi_arsize;
	output wire [1:0] p_axi_arburst;
	output wire p_axi_arvalid;
	input wire p_axi_arready;
	input wire [ID_WIDTH - 1:0] p_axi_rid;
	input wire [DATA_WIDTH - 1:0] p_axi_rdata;
	input wire [1:0] p_axi_rresp;
	input wire p_axi_rlast;
	input wire p_axi_rvalid;
	output wire p_axi_rready;
	output wire [ID_WIDTH - 1:0] d_axi_awid;
	output wire [ADDR_WIDTH - 1:0] d_axi_awaddr;
	output wire [7:0] d_axi_awlen;
	output wire [2:0] d_axi_awsize;
	output wire [1:0] d_axi_awburst;
	output wire d_axi_awvalid;
	input wire d_axi_awready;
	output wire [DATA_WIDTH - 1:0] d_axi_wdata;
	output wire [(DATA_WIDTH / 8) - 1:0] d_axi_wstrb;
	output wire d_axi_wlast;
	output wire d_axi_wvalid;
	input wire d_axi_wready;
	input wire [ID_WIDTH - 1:0] d_axi_bid;
	input wire [1:0] d_axi_bresp;
	input wire d_axi_bvalid;
	output wire d_axi_bready;
	output wire [ID_WIDTH - 1:0] d_axi_arid;
	output wire [ADDR_WIDTH - 1:0] d_axi_araddr;
	output wire [7:0] d_axi_arlen;
	output wire [2:0] d_axi_arsize;
	output wire [1:0] d_axi_arburst;
	output wire d_axi_arvalid;
	input wire d_axi_arready;
	input wire [ID_WIDTH - 1:0] d_axi_rid;
	input wire [DATA_WIDTH - 1:0] d_axi_rdata;
	input wire [1:0] d_axi_rresp;
	input wire d_axi_rlast;
	input wire d_axi_rvalid;
	output wire d_axi_rready;
	wire [31:0] csr_DCACHE_CTRL;
	wire [31:0] csr_SA_CTRL;
	wire [31:0] csr_SA_MODE;
	wire [31:0] csr_SA_STATUS;
	wire [31:0] csr_SA_ADDR_A;
	wire [31:0] csr_SA_ADDR_B;
	wire [31:0] csr_SA_ADDR_C;
	wire [31:0] csr_CPU_MON_CTRL;
	wire [31:0] csr_CPU_MON_CYCLE;
	wire program_mem_burst_mode;
	wire program_mem_read_valid;
	wire program_mem_read_ready;
	wire [31:0] program_mem_read_address;
	wire [31:0] program_mem_read_data;
	wire program_mem_req_ready;
	wire is_fence_i;
	wire data_mem_read_valid;
	wire data_mem_read_ready;
	wire [31:0] data_mem_read_address;
	wire [31:0] data_mem_read_data;
	wire data_mem_write_valid;
	wire data_mem_write_ready;
	wire [31:0] data_mem_write_address;
	wire mmu_mem_read_valid;
	wire mmu_mem_read_ready;
	wire [31:0] mmu_mem_read_address;
	wire [31:0] mmu_mem_read_data;
	wire [2:0] mem_write_sel;
	wire [31:0] mem_write_data;
	wire data_mem_req_ready;
	wire mmu_data_req_ready;
	PSC_RV32ISP_core #(.COUNTER_MMIO_ADDR(32'hf004fff0)) u_core(
		.clock(clock),
		.reset_n(reset_n),
		.cpu_stop(cpu_stop),
		.irq_ext(1'b0),
		.program_mem_burst_mode(program_mem_burst_mode),
		.program_mem_read_valid(program_mem_read_valid),
		.program_mem_read_ready(program_mem_read_ready),
		.program_mem_read_address(program_mem_read_address),
		.program_mem_read_data(program_mem_read_data),
		.program_mem_req_ready(program_mem_req_ready),
		.data_mem_read_valid(data_mem_read_valid),
		.data_mem_read_ready(data_mem_read_ready),
		.data_mem_read_address(data_mem_read_address),
		.data_mem_read_data(data_mem_read_data),
		.data_mem_req_ready(data_mem_req_ready),
		.data_mem_write_ready(data_mem_write_ready),
		.data_mem_write_valid(data_mem_write_valid),
		.mem_write_sel(mem_write_sel),
		.mem_write_address(data_mem_write_address),
		.mem_write_data(mem_write_data),
		.mmu_data_mem_read_valid(mmu_mem_read_valid),
		.mmu_data_mem_read_ready(mmu_mem_read_ready),
		.mmu_data_mem_read_address(mmu_mem_read_address),
		.mmu_data_mem_read_data(mmu_mem_read_data),
		.mmu_data_req_ready(mmu_data_req_ready),
		.is_fence_i(is_fence_i),
		.csr_DCACHE_CTRL(csr_DCACHE_CTRL),
		.csr_DMA_CTRL(csr_DMA_CTRL),
		.csr_DMA_WORDS(csr_DMA_WORDS),
		.csr_DMA_SRC(csr_DMA_SRC),
		.csr_DMA_DST(csr_DMA_DST),
		.csr_DMA_STATUS(csr_DMA_STATUS),
		.csr_SA_CTRL(csr_SA_CTRL),
		.csr_SA_MODE(csr_SA_MODE),
		.csr_SA_STATUS(csr_SA_STATUS),
		.csr_SA_ADDR_A(csr_SA_ADDR_A),
		.csr_SA_ADDR_B(csr_SA_ADDR_B),
		.csr_SA_ADDR_C(csr_SA_ADDR_C),
		.csr_CPU_MON_CTRL(csr_CPU_MON_CTRL),
		.csr_CPU_MON_CYCLE(csr_CPU_MON_CYCLE),
		.uart_out(uart_out)
	);
	wire sa_read_valid;
	wire sa_read_ready;
	wire sa_write_valid;
	wire sa_write_ready;
	wire [31:0] sa_read_addr;
	wire [31:0] sa_read_data;
	wire [31:0] sa_write_addr;
	wire [31:0] sa_write_data;
	wire sa_busy;
	wire sa_done;
	assign csr_SA_STATUS = {30'b000000000000000000000000000000, sa_busy, sa_done};
	wire sa_start = csr_SA_CTRL[0];
	wire sa_state_reset = csr_SA_CTRL[1];
	wire sa_clear = csr_SA_CTRL[2];
	wire [3:0] sa_os_instruction = csr_SA_CTRL[11:8];
	wire [7:0] sa_matrix_size_x = csr_SA_CTRL[23:16];
	wire [7:0] sa_matrix_size_y = csr_SA_CTRL[31:24];
	wire sa_valid = sa_read_valid | sa_write_valid;
	wire [31:0] sa_addr = (sa_read_valid ? sa_read_addr : (sa_write_valid ? sa_write_addr : 32'h00000000));
	wire [31:0] sa_data = sa_write_data;
	wire sa_ready;
	assign sa_read_ready = sa_ready;
	assign sa_write_ready = sa_ready;
	wire [31:0] sa_data_out;
	assign sa_read_data = sa_data_out;
	wire sa_rw = sa_write_valid;
	wire sa_req_ready;
	PSC_NPU_Controller u_systolic(
		.clock(clock),
		.reset_n(reset_n),
		.start(sa_start),
		.sa_state_reset(sa_state_reset),
		.sa_os_instruction(sa_os_instruction),
		.sa_clear(sa_clear),
		.matrix_size_x(sa_matrix_size_x),
		.matrix_size_y(sa_matrix_size_y),
		.BASE_ADDR_A(csr_SA_ADDR_A),
		.BASE_ADDR_B(csr_SA_ADDR_B),
		.BASE_ADDR_C(csr_SA_ADDR_C),
		.sa_req_ready(sa_req_ready),
		.rd_read_addr(sa_read_addr),
		.rd_read_valid(sa_read_valid),
		.rd_read_ready(sa_read_ready),
		.rd_read_data(sa_read_data),
		.c_write_valid(sa_write_valid),
		.c_write_addr(sa_write_addr),
		.c_write_wdata(sa_write_data),
		.c_write_ready(sa_write_ready),
		.busy(sa_busy),
		.done(sa_done)
	);
	wire p_mem_valid128;
	wire p_mem_rw128;
	wire p_mem_ready128;
	wire [127:0] p_mem_rdata128;
	wire [31:0] p_mem_addr128;
	wire [127:0] p_mem_wdata128;
	wire program_cache_hit_pulse;
	wire program_cache_miss_pulse;
	cache_dma_controller #(
		.ADDR_WIDTH(32),
		.CPU_DATA_WIDTH(32),
		.CACHE_DATA_WIDTH(128),
		.MAIN_MEM_DATA_WIDTH(128),
		.TAGMSB(31),
		.TAGLSB(12)
	) u_program_dma_ctrl(
		.clock(clock),
		.reset_n(reset_n),
		.cpu_valid(program_mem_read_valid),
		.cpu_rw(1'b0),
		.cpu_addr(program_mem_read_address),
		.cpu_data(32'd0),
		.burst_mode(program_mem_burst_mode),
		.cpu_ready(program_mem_read_ready),
		.cpu_data_out(program_mem_read_data),
		.cpu_req_ready(program_mem_req_ready),
		.cpu_cache_clear(is_fence_i),
		.mem_req_ready(1'b1),
		.mem_valid(p_mem_valid128),
		.mem_rw(p_mem_rw128),
		.mem_ready(p_mem_ready128),
		.mem_data_in(p_mem_rdata128),
		.mem_addr(p_mem_addr128),
		.mem_data_out(p_mem_wdata128),
		.cache_hit_pulse(program_cache_hit_pulse),
		.cache_miss_pulse(program_cache_miss_pulse)
	);
	localparam integer SYS_ADDR_WIDTH = 32;
	localparam integer AXI_ID_WIDTH = 1;
	localparam integer AXI_DATA_WIDTH = 32;
	wire p_cache_rd_valid = p_mem_valid128 & ~p_mem_rw128;
	wire p_cache_wr_valid = p_mem_valid128 & p_mem_rw128;
	wire [31:0] p_cache_rd_addr = p_mem_addr128;
	wire [31:0] p_cache_wr_addr = p_mem_addr128;
	wire [127:0] p_cache_wr_data = p_mem_wdata128;
	wire [127:0] p_cache_rd_data;
	wire p_cache_rd_ready;
	wire p_cache_wr_ready;
	assign p_mem_ready128 = p_cache_rd_ready | p_cache_wr_ready;
	assign p_mem_rdata128 = p_cache_rd_data;
	wire data_cache_hit_pulse;
	wire data_cache_miss_pulse;
	sdram_32bit_to_128bit_axi_bridge #(
		.ADDR_WIDTH(SYS_ADDR_WIDTH),
		.ID_WIDTH(AXI_ID_WIDTH),
		.DATA_WIDTH(AXI_DATA_WIDTH)
	) p_axi_bridge(
		.clock(clock),
		.reset_n(reset_n),
		.read_valid(p_cache_rd_valid),
		.read_ready(p_cache_rd_ready),
		.read_addr(p_cache_rd_addr),
		.read_data(p_cache_rd_data),
		.write_valid(p_cache_wr_valid),
		.write_ready(p_cache_wr_ready),
		.write_addr(p_cache_wr_addr),
		.write_data(p_cache_wr_data),
		.m_axi_awid(p_axi_awid),
		.m_axi_awaddr(p_axi_awaddr),
		.m_axi_awlen(p_axi_awlen),
		.m_axi_awsize(p_axi_awsize),
		.m_axi_awburst(p_axi_awburst),
		.m_axi_awvalid(p_axi_awvalid),
		.m_axi_awready(p_axi_awready),
		.m_axi_wdata(p_axi_wdata),
		.m_axi_wstrb(p_axi_wstrb),
		.m_axi_wlast(p_axi_wlast),
		.m_axi_wvalid(p_axi_wvalid),
		.m_axi_wready(p_axi_wready),
		.m_axi_bid(p_axi_bid),
		.m_axi_bresp(p_axi_bresp),
		.m_axi_bvalid(p_axi_bvalid),
		.m_axi_bready(p_axi_bready),
		.m_axi_arid(p_axi_arid),
		.m_axi_araddr(p_axi_araddr),
		.m_axi_arlen(p_axi_arlen),
		.m_axi_arsize(p_axi_arsize),
		.m_axi_arburst(p_axi_arburst),
		.m_axi_arvalid(p_axi_arvalid),
		.m_axi_arready(p_axi_arready),
		.m_axi_rid(p_axi_rid),
		.m_axi_rdata(p_axi_rdata),
		.m_axi_rresp(p_axi_rresp),
		.m_axi_rlast(p_axi_rlast),
		.m_axi_rvalid(p_axi_rvalid),
		.m_axi_rready(p_axi_rready)
	);
	wire [31:0] cpu_data_addr = (data_mem_write_valid ? data_mem_write_address[31:0] : data_mem_read_address[31:0]);
	wire d_mem_valid128;
	wire d_mem_rw128;
	wire d_mem_ready128;
	wire [127:0] d_mem_rdata128;
	wire [31:0] d_mem_addr128;
	wire [127:0] d_mem_wdata128;
	wire dcache_ready;
	assign data_mem_read_ready = dcache_ready;
	assign data_mem_write_ready = dcache_ready;
	wire cpu_cache_clear = csr_DCACHE_CTRL[0];
	wire cpu_cache_wb = csr_DCACHE_CTRL[1];
	cache_dma_controller_io #(
		.PROTECT_MODE(PROTECT_MODE),
		.PROTECT_ADDR(PROTECT_ADDR),
		.ADDR_WIDTH(32),
		.CPU_DATA_WIDTH(32),
		.CACHE_DATA_WIDTH(128),
		.MAIN_MEM_DATA_WIDTH(128),
		.TAGMSB(31),
		.TAGLSB(10),
		.UART_ADDRESS_TX(UART_ADDRESS_TX),
		.UART_ADDRESS_RX(UART_ADDRESS_RX),
		.UART_ADDRESS_ST(UART_ADDRESS_ST),
		.UART_ADDRESS_CT(UART_ADDRESS_CT),
		.PIO_ADDRESS(PIO_ADDRESS),
		.TIMER_WRITE_ADDR(TIMER_WRITE_ADDR),
		.TIMER_READ_ADDR(TIMER_READ_ADDR),
		.TIMER_ST_ADDR(TIMER_ST_ADDR),
		.LCD_PIXS_DATA(LCD_PIXS_DATA),
		.LCD_PIXS_ST(LCD_PIXS_ST),
		.LED_ADDRESS(LED_ADDRESS),
		.PSC_SA_CTRL(PSC_SA_CTRL),
		.PSC_SA_STATUS(PSC_SA_STATUS),
		.PSC_SD_IF_READ_DATA(PSC_SD_IF_READ_DATA),
		.PSC_SD_IF_SECTOR(PSC_SD_IF_SECTOR),
		.PSC_SD_IF_CTRL(PSC_SD_IF_CTRL),
		.PSC_I2S_ADDR_RX(PSC_I2S_ADDR_RX),
		.PSC_I2S_ADDR_ST(PSC_I2S_ADDR_ST),
		.PSC_PFE_IF_DATA(PSC_PFE_IF_DATA),
		.PSC_PFE_IF_CTRL(PSC_PFE_IF_CTRL)
	) u_data_dma_ctrl(
		.clock(clock),
		.reset_n(reset_n),
		.cpu_valid(data_mem_read_valid | data_mem_write_valid),
		.cpu_rw(data_mem_write_valid),
		.cpu_write_sel(mem_write_sel),
		.cpu_addr(cpu_data_addr),
		.cpu_data(mem_write_data),
		.cpu_ready(dcache_ready),
		.cpu_data_out(data_mem_read_data),
		.cpu_req_ready(data_mem_req_ready),
		.cpu_cache_clear(cpu_cache_clear),
		.cpu_cache_wb(cpu_cache_wb),
		.sa_valid(sa_valid),
		.sa_rw(sa_rw),
		.sa_addr(sa_addr),
		.sa_data(sa_data),
		.sa_ready(sa_ready),
		.sa_data_out(sa_data_out),
		.sa_req_ready(sa_req_ready),
		.mmu_valid(mmu_mem_read_valid),
		.mmu_addr(mmu_mem_read_address),
		.mmu_ready(mmu_mem_read_ready),
		.mmu_data_out(mmu_mem_read_data),
		.mmu_req_ready(mmu_data_req_ready),
		.mmio_valid(mmio_valid),
		.mmio_rw(mmio_rw),
		.mmio_addr(mmio_addr),
		.mmio_rdata(mmio_rdata),
		.mmio_ready(mmio_ready),
		.mmio_wdata(mmio_wdata),
		.mem_req_ready(1'b1),
		.mem_valid(d_mem_valid128),
		.mem_rw(d_mem_rw128),
		.mem_ready(d_mem_ready128),
		.mem_data_in(d_mem_rdata128),
		.mem_addr(d_mem_addr128),
		.mem_data_out(d_mem_wdata128),
		.cache_hit_pulse(data_cache_hit_pulse),
		.cache_miss_pulse(data_cache_miss_pulse)
	);
	wire d_cache_rd_valid = d_mem_valid128 & ~d_mem_rw128;
	wire d_cache_wr_valid = d_mem_valid128 & d_mem_rw128;
	wire [31:0] d_cache_rd_addr = d_mem_addr128;
	wire [31:0] d_cache_wr_addr = d_mem_addr128;
	wire [127:0] d_cache_wr_data = d_mem_wdata128;
	wire [127:0] d_cache_rd_data;
	wire d_cache_rd_ready;
	wire d_cache_wr_ready;
	assign d_mem_ready128 = d_cache_rd_ready | d_cache_wr_ready;
	assign d_mem_rdata128 = d_cache_rd_data;
	sdram_32bit_to_128bit_axi_bridge #(
		.ADDR_WIDTH(SYS_ADDR_WIDTH),
		.ID_WIDTH(AXI_ID_WIDTH),
		.DATA_WIDTH(32)
	) d_axi_bridge(
		.clock(clock),
		.reset_n(reset_n),
		.read_valid(d_cache_rd_valid),
		.read_ready(d_cache_rd_ready),
		.read_addr(d_cache_rd_addr),
		.read_data(d_cache_rd_data),
		.write_valid(d_cache_wr_valid),
		.write_ready(d_cache_wr_ready),
		.write_addr(d_cache_wr_addr),
		.write_data(d_cache_wr_data),
		.m_axi_awid(d_axi_awid),
		.m_axi_awaddr(d_axi_awaddr),
		.m_axi_awlen(d_axi_awlen),
		.m_axi_awsize(d_axi_awsize),
		.m_axi_awburst(d_axi_awburst),
		.m_axi_awvalid(d_axi_awvalid),
		.m_axi_awready(d_axi_awready),
		.m_axi_wdata(d_axi_wdata),
		.m_axi_wstrb(d_axi_wstrb),
		.m_axi_wlast(d_axi_wlast),
		.m_axi_wvalid(d_axi_wvalid),
		.m_axi_wready(d_axi_wready),
		.m_axi_bid(d_axi_bid),
		.m_axi_bresp(d_axi_bresp),
		.m_axi_bvalid(d_axi_bvalid),
		.m_axi_bready(d_axi_bready),
		.m_axi_arid(d_axi_arid),
		.m_axi_araddr(d_axi_araddr),
		.m_axi_arlen(d_axi_arlen),
		.m_axi_arsize(d_axi_arsize),
		.m_axi_arburst(d_axi_arburst),
		.m_axi_arvalid(d_axi_arvalid),
		.m_axi_arready(d_axi_arready),
		.m_axi_rid(d_axi_rid),
		.m_axi_rdata(d_axi_rdata),
		.m_axi_rresp(d_axi_rresp),
		.m_axi_rlast(d_axi_rlast),
		.m_axi_rvalid(d_axi_rvalid),
		.m_axi_rready(d_axi_rready)
	);
	PSC_RV32ISP_Monitor #(.CLK_FREQ_MHz(80)) u_cpu_monitor(
		.clock(clock),
		.reset_n(reset_n),
		.PSC_CPU_MON_CTRL(csr_CPU_MON_CTRL),
		.PSC_CPU_MON_CYCLE(csr_CPU_MON_CYCLE),
		.program_cache_hit_pulse(program_cache_hit_pulse),
		.program_cache_miss_pulse(program_cache_miss_pulse),
		.data_cache_hit_pulse(data_cache_hit_pulse),
		.data_cache_miss_pulse(data_cache_miss_pulse)
	);
endmodule
module PSC_RV32ISP_core (
	clock,
	reset_n,
	cpu_stop,
	irq_ext,
	program_mem_burst_mode,
	program_mem_read_valid,
	program_mem_read_ready,
	program_mem_read_address,
	program_mem_read_data,
	program_mem_req_ready,
	data_mem_read_valid,
	data_mem_read_ready,
	data_mem_read_address,
	data_mem_read_data,
	data_mem_req_ready,
	data_mem_write_valid,
	data_mem_write_ready,
	mem_write_sel,
	mem_write_address,
	mem_write_data,
	mmu_data_mem_read_valid,
	mmu_data_mem_read_ready,
	mmu_data_mem_read_address,
	mmu_data_mem_read_data,
	mmu_data_req_ready,
	is_fence_i,
	csr_DCACHE_CTRL,
	csr_DMA_CTRL,
	csr_DMA_WORDS,
	csr_DMA_SRC,
	csr_DMA_DST,
	csr_DMA_STATUS,
	csr_SA_CTRL,
	csr_SA_MODE,
	csr_SA_STATUS,
	csr_SA_ADDR_A,
	csr_SA_ADDR_B,
	csr_SA_ADDR_C,
	csr_CPU_MON_CTRL,
	csr_CPU_MON_CYCLE,
	uart_out
);
	parameter [31:0] UART_MMIO_ADDR = 32'hf00400f0;
	parameter [31:0] UART_MMIO_FLAG = 32'hf00400f4;
	parameter [31:0] COUNTER_MMIO_ADDR = 32'hf004fff0;
	input wire clock;
	input wire reset_n;
	input wire cpu_stop;
	input wire irq_ext;
	output wire program_mem_burst_mode;
	output wire program_mem_read_valid;
	input wire program_mem_read_ready;
	output wire [31:0] program_mem_read_address;
	input wire [31:0] program_mem_read_data;
	input wire program_mem_req_ready;
	output wire data_mem_read_valid;
	input wire data_mem_read_ready;
	output wire [31:0] data_mem_read_address;
	input wire [31:0] data_mem_read_data;
	input wire data_mem_req_ready;
	output wire data_mem_write_valid;
	input wire data_mem_write_ready;
	output wire [2:0] mem_write_sel;
	output wire [31:0] mem_write_address;
	output wire [31:0] mem_write_data;
	output wire mmu_data_mem_read_valid;
	input wire mmu_data_mem_read_ready;
	output wire [31:0] mmu_data_mem_read_address;
	input wire [31:0] mmu_data_mem_read_data;
	input wire mmu_data_req_ready;
	output wire is_fence_i;
	output wire [31:0] csr_DCACHE_CTRL;
	output wire [31:0] csr_DMA_CTRL;
	output wire [31:0] csr_DMA_WORDS;
	output wire [31:0] csr_DMA_SRC;
	output wire [31:0] csr_DMA_DST;
	input wire [31:0] csr_DMA_STATUS;
	output wire [31:0] csr_SA_CTRL;
	output wire [31:0] csr_SA_MODE;
	input wire [31:0] csr_SA_STATUS;
	output wire [31:0] csr_SA_ADDR_A;
	output wire [31:0] csr_SA_ADDR_B;
	output wire [31:0] csr_SA_ADDR_C;
	output wire [31:0] csr_CPU_MON_CTRL;
	input wire [31:0] csr_CPU_MON_CYCLE;
	output wire [8:0] uart_out;
	wire [129:0] decoder_ctrl;
	wire [31:0] pc;
	wire [31:0] counter;
	reg [3:0] cpu_state;
	reg fetch_valid;
	wire fetch_ready;
	wire d_pf;
	wire i_pf;
	wire illegal_instruction;
	always @(posedge clock or negedge reset_n)
		if (!reset_n) begin
			cpu_state <= 4'd0;
			fetch_valid <= 1'b0;
		end
		else if (cpu_stop) begin
			cpu_state <= 4'd0;
			fetch_valid <= 1'b0;
		end
		else
			(* full_case, parallel_case *)
			case (cpu_state)
				4'd0: begin
					cpu_state <= 4'd1;
					fetch_valid <= 1'b0;
				end
				4'd1: begin
					fetch_valid <= 1'b1;
					if ((illegal_instruction | i_pf) | d_pf)
						cpu_state <= 4'd2;
				end
				4'd2: cpu_state <= 4'd1;
				4'd3: fetch_valid <= 1'b0;
				default: begin
					cpu_state <= 4'd0;
					fetch_valid <= 1'b0;
				end
			endcase
	wire [415:0] csr_state;
	localparam [1:0] PRIV_U = 2'b00;
	localparam [1:0] PRIV_S = 2'b01;
	localparam [1:0] PRIV_M = 2'b11;
	wire ecall_u;
	wire ecall_s;
	wire ecall_m;
	wire set_trap;
	wire [31:0] trap_sepc;
	reg fault_seen;
	wire d_pf_event;
	wire i_pf_event;
	wire [1:0] priv_mode;
	assign ecall_u = decoder_ctrl[8] && (priv_mode == PRIV_U);
	assign ecall_s = decoder_ctrl[8] && (priv_mode == PRIV_S);
	assign ecall_m = decoder_ctrl[8] && (priv_mode == PRIV_M);
	assign d_pf_event = d_pf && !fault_seen;
	assign i_pf_event = i_pf && !fault_seen;
	always @(posedge clock or negedge reset_n)
		if (!reset_n)
			fault_seen <= 1'b0;
		else if (!d_pf && !i_pf)
			fault_seen <= 1'b0;
		else
			fault_seen <= 1'b1;
	assign set_trap = ((decoder_ctrl[8] || decoder_ctrl[0]) || i_pf_event) || d_pf_event;
	wire [31:0] data_fault_pc;
	wire [31:0] data_fault_vaddr;
	wire data_fault_is_store;
	assign trap_sepc = (d_pf_event ? data_fault_pc : pc);
	wire [31:0] execute_vaddr;
	wire [31:0] trap_stval;
	wire [31:0] trap_scause;
	wire set_mtrap;
	wire [31:0] trap_mepc;
	wire [31:0] trap_mcause;
	assign trap_stval = (i_pf_event ? pc : (d_pf_event ? data_fault_vaddr : 32'h00000000));
	assign trap_scause = (ecall_u ? 32'd8 : (ecall_s ? 32'd9 : (decoder_ctrl[0] ? 32'd2 : (i_pf_event ? 32'd12 : (d_pf_event ? (data_fault_is_store ? 32'd15 : 32'd13) : 32'd0)))));
	assign set_mtrap = ecall_m;
	assign trap_mepc = pc;
	assign trap_mcause = (ecall_m ? 32'd11 : 32'd0);
	wire set_msip;
	wire clr_msip;
	wire set_mtip;
	wire clr_mtip;
	wire set_meip;
	wire clr_meip;
	assign set_msip = 1'b0;
	assign clr_msip = 1'b0;
	assign set_mtip = 1'b0;
	assign clr_mtip = 1'b0;
	assign set_meip = 1'b0;
	assign clr_meip = 1'b0;
	wire [31:0] alu_data;
	wire pc_sel2;
	wire csr_enb;
	wire csr_valid;
	wire [31:0] csr_rdata;
	wire [31:0] csr_reg_data_1;
	Csr u_csr(
		.clock(clock),
		.reset_n(reset_n),
		.csr_enb(csr_enb),
		.csr_valid(csr_valid),
		.csr_wr(decoder_ctrl[31]),
		.csr_cmd(decoder_ctrl[30-:2]),
		.csr_use_imm(decoder_ctrl[28]),
		.csr_addr(decoder_ctrl[27-:12]),
		.csr_zimm(decoder_ctrl[15-:5]),
		.csr_rs1_val(csr_reg_data_1),
		.csr_rdata(csr_rdata),
		.set_trap(set_trap),
		.trap_sepc(trap_sepc),
		.trap_scause(trap_scause),
		.trap_stval(trap_stval),
		.do_sret(decoder_ctrl[10]),
		.set_mtrap(set_mtrap),
		.trap_mepc(trap_mepc),
		.trap_mcause(trap_mcause),
		.do_mret(decoder_ctrl[9]),
		.set_msip(set_msip),
		.clr_msip(clr_msip),
		.set_mtip(set_mtip),
		.clr_mtip(clr_mtip),
		.set_meip(set_meip),
		.clr_meip(clr_meip),
		.priv_mode(priv_mode),
		.out_mstatus(csr_state[415-:32]),
		.out_medeleg(csr_state[383-:32]),
		.out_mie(csr_state[351-:32]),
		.out_mip(csr_state[319-:32]),
		.out_mtvec(csr_state[287-:32]),
		.out_mepc(csr_state[255-:32]),
		.out_mcause(csr_state[223-:32]),
		.out_sstatus(csr_state[191-:32]),
		.out_stvec(csr_state[159-:32]),
		.out_sepc(csr_state[127-:32]),
		.out_scause(csr_state[95-:32]),
		.out_stval(csr_state[63-:32]),
		.out_satp(csr_state[31-:32]),
		.out_DCACHE_CTRL(csr_DCACHE_CTRL),
		.out_DMA_CTRL(csr_DMA_CTRL),
		.out_DMA_WORDS(csr_DMA_WORDS),
		.out_DMA_SRC(csr_DMA_SRC),
		.out_DMA_DST(csr_DMA_DST),
		.in_DMA_STATUS(csr_DMA_STATUS),
		.out_SA_CTRL(csr_SA_CTRL),
		.out_SA_MODE(csr_SA_MODE),
		.in_SA_STATUS(csr_SA_STATUS),
		.out_SA_ADDR_A(csr_SA_ADDR_A),
		.out_SA_ADDR_B(csr_SA_ADDR_B),
		.out_SA_ADDR_C(csr_SA_ADDR_C),
		.out_CPU_MON_CTRL(csr_CPU_MON_CTRL),
		.in_CPU_MON_CYCLE(csr_CPU_MON_CYCLE)
	);
	wire [31:0] opcode;
	wire [31:0] fifo_opcode_data;
	wire [31:0] fifo_fetch_pc;
	wire fifo_req_ready;
	wire fifo_full;
	wire fifo_flush_sig;
	wire fifo_read_ready;
	wire execute_task_busy;
	wire execute_task_done;
	wire fifo_read_state_sig;
	wire is_sfence_vma;
	assign is_sfence_vma = decoder_ctrl[32];
	assign is_fence_i = decoder_ctrl[33];
	wire [31:0] fetch_pc;
	assign fetch_pc = pc;
	PSC_RV32ISP_FetchUnit u_fetch_unit(
		.clock(clock),
		.reset_n(reset_n),
		.cpu_stop(cpu_stop),
		.fetch_valid(fetch_valid),
		.fetch_ready(fetch_ready),
		.execute_task_busy(execute_task_busy),
		.execute_task_done(execute_task_done),
		.fifo_req_ready(fifo_req_ready),
		.fifo_full(fifo_full),
		.fifo_read_valid(fifo_read_state_sig),
		.fifo_read_ready(fifo_read_ready),
		.fifo_flush(fifo_flush_sig),
		.pc(fetch_pc),
		.csr_satp(csr_state[31-:32]),
		.priv_mode(priv_mode),
		.is_load(decoder_ctrl[7]),
		.is_store(decoder_ctrl[6]),
		.is_sfence_vma(is_sfence_vma),
		.fifo_ready(),
		.i_pf(i_pf),
		.program_mem_burst_mode(program_mem_burst_mode),
		.program_mem_read_valid(program_mem_read_valid),
		.program_mem_read_ready(program_mem_read_ready),
		.program_mem_read_address(program_mem_read_address),
		.program_mem_read_data(program_mem_read_data),
		.program_mem_req_ready(program_mem_req_ready),
		.data_mem_read_valid(mmu_data_mem_read_valid),
		.data_mem_read_ready(mmu_data_mem_read_ready),
		.data_mem_read_address(mmu_data_mem_read_address),
		.data_mem_read_data(mmu_data_mem_read_data),
		.data_mem_read_req_ready(mmu_data_req_ready),
		.opcode(opcode),
		.fifo_opcode_data(fifo_opcode_data),
		.out_fetch_pc(fifo_fetch_pc)
	);
	wire execute_state_sig;
	assign illegal_instruction = decoder_ctrl[0];
	PSC_RV32ISP_InstructionEngine u_inst_engine(
		.clock(clock),
		.reset_n(reset_n),
		.cpu_stop(cpu_stop),
		.cpu_state(cpu_state),
		.cpu_trap(cpu_state == 4'd2),
		.fifo_req_ready(fifo_req_ready),
		.execute_task_busy(execute_task_busy),
		.execute_task_done(execute_task_done),
		.fifo_read_state_sig(fifo_read_state_sig),
		.execute_state_sig(execute_state_sig),
		.fifo_read_ready(fifo_read_ready),
		.fifo_flush_sig(fifo_flush_sig),
		.pc(pc),
		.counter(counter),
		.opcode(fifo_opcode_data),
		.pc_now(fifo_fetch_pc),
		.csr_satp(csr_state[31-:32]),
		.priv_mode(priv_mode),
		.alu_data(alu_data),
		.pc_sel2(pc_sel2),
		.decoder_ctrl(decoder_ctrl),
		.csr_state(csr_state),
		.csr_enb(csr_enb),
		.csr_valid(csr_valid),
		.csr_rdata(csr_rdata),
		.csr_reg_data_1(csr_reg_data_1),
		.i_pf(i_pf),
		.d_pf(d_pf),
		.i_pf_event(i_pf_event),
		.d_pf_event(d_pf_event),
		.data_fault_pc(data_fault_pc),
		.data_fault_vaddr(data_fault_vaddr),
		.data_fault_is_store(data_fault_is_store),
		.trap_scause(trap_scause[4:0]),
		.data_mem_read_valid(data_mem_read_valid),
		.data_mem_read_ready(data_mem_read_ready),
		.data_mem_read_address(data_mem_read_address),
		.data_mem_read_data(data_mem_read_data),
		.data_mem_write_valid(data_mem_write_valid),
		.data_mem_write_ready(data_mem_write_ready),
		.data_mem_write_address(mem_write_address),
		.data_mem_write_data(mem_write_data),
		.mem_write_sel(mem_write_sel),
		.data_mem_req_ready(data_mem_req_ready),
		.vaddr(execute_vaddr),
		.uart_out(uart_out)
	);
endmodule
module PSC_RV32ISP_FetchUnit (
	clock,
	reset_n,
	cpu_stop,
	fetch_valid,
	fetch_ready,
	execute_task_busy,
	execute_task_done,
	fifo_req_ready,
	fifo_full,
	fifo_read_valid,
	fifo_read_ready,
	fifo_flush,
	pc,
	csr_satp,
	priv_mode,
	is_load,
	is_store,
	is_sfence_vma,
	fifo_ready,
	i_pf,
	program_mem_burst_mode,
	program_mem_read_valid,
	program_mem_read_ready,
	program_mem_read_address,
	program_mem_read_data,
	program_mem_req_ready,
	data_mem_read_valid,
	data_mem_read_ready,
	data_mem_read_address,
	data_mem_read_data,
	data_mem_read_req_ready,
	opcode,
	fifo_opcode_data,
	out_fetch_pc
);
	reg _sv2v_0;
	parameter [0:0] BURST_MODE = 1'b1;
	parameter signed [31:0] FIFO_DEPTH = 16;
	input wire clock;
	input wire reset_n;
	input wire cpu_stop;
	input wire fetch_valid;
	output reg fetch_ready;
	input wire execute_task_busy;
	input wire execute_task_done;
	output wire fifo_req_ready;
	output wire fifo_full;
	input wire fifo_read_valid;
	output wire fifo_read_ready;
	input wire fifo_flush;
	input wire [31:0] pc;
	input wire [31:0] csr_satp;
	input wire [1:0] priv_mode;
	input wire is_load;
	input wire is_store;
	input wire is_sfence_vma;
	output wire fifo_ready;
	output wire i_pf;
	output wire program_mem_burst_mode;
	output wire program_mem_read_valid;
	input wire program_mem_read_ready;
	output wire [31:0] program_mem_read_address;
	input wire [31:0] program_mem_read_data;
	input wire program_mem_req_ready;
	output wire data_mem_read_valid;
	input wire data_mem_read_ready;
	output wire [31:0] data_mem_read_address;
	input wire [31:0] data_mem_read_data;
	input wire data_mem_read_req_ready;
	output wire [31:0] opcode;
	output wire [31:0] fifo_opcode_data;
	output wire [31:0] out_fetch_pc;
	reg [3:0] fetch_state;
	reg [3:0] next_state;
	reg [15:0] fetch_wakeup_timer;
	reg [31:0] fetch_pc;
	reg [31:0] next_pc;
	reg fetch_state_fifo_flush;
	reg next_ready;
	reg initial_fetch;
	always @(posedge clock or negedge reset_n)
		if (!reset_n) begin
			fetch_state <= 4'd0;
			fetch_wakeup_timer <= 16'd0;
			fetch_pc <= 32'd0;
			fetch_ready <= 1'b0;
			initial_fetch <= 1'b1;
		end
		else if (cpu_stop) begin
			fetch_state <= 4'd0;
			fetch_wakeup_timer <= 16'd0;
			fetch_ready <= 1'b0;
		end
		else begin
			if (fetch_wakeup_timer < 16'h0400)
				fetch_wakeup_timer <= fetch_wakeup_timer + 16'd1;
			fetch_state <= next_state;
			fetch_pc <= next_pc;
			fetch_ready <= next_ready;
			if (((initial_fetch && (fetch_state == 4'd0)) && fetch_valid) && (fetch_wakeup_timer > 16'h0300))
				initial_fetch <= 1'b0;
		end
	localparam signed [31:0] ADDR_BITS = $clog2(FIFO_DEPTH);
	wire [ADDR_BITS:0] count;
	wire fetch_busy;
	wire fetch_done;
	wire full;
	always @(*) begin
		if (_sv2v_0)
			;
		next_state = fetch_state;
		next_pc = fetch_pc;
		next_ready = 1'b0;
		fetch_state_fifo_flush = 1'b0;
		if (fifo_flush)
			next_state = 4'd5;
		else
			case (fetch_state)
				4'd0:
					if (fetch_valid && (fetch_wakeup_timer > 16'h0300)) begin
						if (initial_fetch && ((BURST_MODE && (count <= (FIFO_DEPTH - 4))) || (!BURST_MODE && !full)))
							next_state = 4'd2;
						else
							next_state = 4'd1;
					end
				4'd1:
					if (BURST_MODE) begin
						if (count <= (FIFO_DEPTH - 4))
							next_state = 4'd2;
					end
					else if (!full)
						next_state = 4'd2;
				4'd2: next_state = 4'd3;
				4'd3:
					if (fetch_done) begin
						next_ready = 1'b1;
						next_state = 4'd4;
					end
				4'd4: begin
					if (BURST_MODE)
						next_pc = {fetch_pc[31:4], 4'b0000} + 32'd16;
					else
						next_pc = fetch_pc + 32'd4;
					next_state = 4'd1;
				end
				4'd5: begin
					fetch_state_fifo_flush = 1'b1;
					if (!fetch_busy && !execute_task_busy)
						next_state = 4'd6;
				end
				4'd6: begin
					next_pc = pc;
					next_state = 4'd0;
				end
				default: begin
					next_pc = pc;
					next_state = 4'd0;
				end
			endcase
	end
	wire opcode_read_valid;
	wire [31:0] opcode_read_data;
	wire mmu_valid;
	wire i_mmu_done;
	wire [31:0] vaddr;
	wire [31:0] i_paddr;
	wire fetch_enb;
	wire [31:0] opcode_read_pc;
	assign fetch_enb = fetch_state == 4'd2;
	wire i_mode_sv32;
	Fetch #(.BURST_MODE(BURST_MODE)) u_fetch(
		.clock(clock),
		.reset_n(reset_n),
		.fetch_enb(fetch_enb),
		.mode_sv32(i_mode_sv32),
		.fetch_address(fetch_pc),
		.mmu_valid(mmu_valid),
		.mmu_ready(i_mmu_done),
		.vaddr(vaddr),
		.paddr(i_paddr),
		.program_mem_burst_mode(program_mem_burst_mode),
		.program_mem_read_valid(program_mem_read_valid),
		.program_mem_read_ready(program_mem_read_ready),
		.program_mem_read_address(program_mem_read_address),
		.program_mem_read_data(program_mem_read_data),
		.program_mem_req_ready(program_mem_req_ready),
		.fifo_read_valid(opcode_read_valid),
		.fifo_read_data(opcode_read_data),
		.fifo_read_pc(opcode_read_pc),
		.done(fetch_done),
		.busy(fetch_busy),
		.opcode(opcode)
	);
	wire in_ready;
	wire empty;
	assign fifo_req_ready = !empty;
	assign fifo_full = full;
	Fetch_Fifo #(
		.WIDTH(32),
		.DEPTH(FIFO_DEPTH)
	) u_fetch_fifo(
		.clock(clock),
		.reset_n(reset_n),
		.in_valid(opcode_read_valid),
		.in_data(opcode_read_data),
		.in_pc_data(opcode_read_pc),
		.in_ready(in_ready),
		.out_req_ready(fifo_ready),
		.out_valid(fifo_read_valid),
		.out_ready(fifo_read_ready),
		.out_data(fifo_opcode_data),
		.out_pc_data(out_fetch_pc),
		.full(full),
		.empty(empty),
		.count(count),
		.flush((fifo_flush || fetch_state_fifo_flush) || cpu_stop)
	);
	wire cpu_state_done;
	assign cpu_state_done = fetch_state == 4'd3;
	MMU u_mmu_i(
		.clk(clock),
		.reset_n(reset_n),
		.MMU_enb(mmu_valid),
		.vaddr(vaddr),
		.satp(csr_satp),
		.priv_mode(priv_mode),
		.access_r(1'b0),
		.access_w(1'b0),
		.access_x(1'b1),
		.mem_req_ready(data_mem_read_req_ready),
		.mem_rdata(data_mem_read_data),
		.mem_addr(data_mem_read_address),
		.mem_valid(data_mem_read_valid),
		.mem_ready(data_mem_read_ready),
		.cpu_state_done(cpu_state_done),
		.sfence_vma(fifo_flush && is_sfence_vma),
		.paddr(i_paddr),
		.page_fault(i_pf),
		.mode_sv32(i_mode_sv32),
		.mmu_done(i_mmu_done)
	);
	initial _sv2v_0 = 0;
endmodule
module Fetch_Fifo (
	clock,
	reset_n,
	in_valid,
	in_data,
	in_pc_data,
	in_ready,
	out_req_ready,
	out_valid,
	out_ready,
	out_data,
	out_pc_data,
	full,
	empty,
	count,
	flush
);
	reg _sv2v_0;
	parameter signed [31:0] WIDTH = 32;
	parameter signed [31:0] DEPTH = 8;
	parameter signed [31:0] ADDR_BITS = $clog2(DEPTH);
	input wire clock;
	input wire reset_n;
	input wire in_valid;
	input wire [WIDTH - 1:0] in_data;
	input wire [WIDTH - 1:0] in_pc_data;
	output wire in_ready;
	output wire out_req_ready;
	input wire out_valid;
	output reg out_ready;
	output reg [WIDTH - 1:0] out_data;
	output reg [WIDTH - 1:0] out_pc_data;
	output wire full;
	output wire empty;
	output reg [ADDR_BITS:0] count;
	input wire flush;
	(* syn_keep = 1 *) reg [WIDTH - 1:0] mem [0:DEPTH - 1];
	(* syn_keep = 1 *) reg [WIDTH - 1:0] pc_mem [0:DEPTH - 1];
	reg [ADDR_BITS - 1:0] wptr;
	reg [ADDR_BITS - 1:0] rptr;
	wire push;
	wire pop;
	integer i;
	assign full = count == DEPTH;
	assign empty = count == 0;
	assign in_ready = !full;
	assign out_req_ready = !empty;
	assign push = in_valid && in_ready;
	assign pop = out_valid && out_req_ready;
	always @(*) begin
		if (_sv2v_0)
			;
		out_data = mem[rptr];
		out_pc_data = pc_mem[rptr];
		out_ready = pop;
	end
	function automatic signed [ADDR_BITS - 1:0] sv2v_cast_5DD1B_signed;
		input reg signed [ADDR_BITS - 1:0] inp;
		sv2v_cast_5DD1B_signed = inp;
	endfunction
	always @(posedge clock or negedge reset_n)
		if (!reset_n) begin
			wptr <= 1'sb0;
			rptr <= 1'sb0;
			count <= 1'sb0;
			for (i = 0; i < DEPTH; i = i + 1)
				begin
					mem[i] <= 1'sb0;
					pc_mem[i] <= 1'sb0;
				end
		end
		else if (flush) begin
			wptr <= 1'sb0;
			rptr <= 1'sb0;
			count <= 1'sb0;
			for (i = 0; i < DEPTH; i = i + 1)
				begin
					mem[i] <= 1'sb0;
					pc_mem[i] <= 1'sb0;
				end
		end
		else
			case ({push, pop})
				2'b10: begin
					mem[wptr] <= in_data;
					pc_mem[wptr] <= in_pc_data;
					wptr <= (wptr == sv2v_cast_5DD1B_signed(DEPTH - 1) ? {ADDR_BITS {1'sb0}} : wptr + 1'b1);
					count <= count + 1'b1;
				end
				2'b01: begin
					rptr <= (rptr == sv2v_cast_5DD1B_signed(DEPTH - 1) ? {ADDR_BITS {1'sb0}} : rptr + 1'b1);
					count <= count - 1'b1;
				end
				2'b11: begin
					mem[wptr] <= in_data;
					pc_mem[wptr] <= in_pc_data;
					wptr <= (wptr == sv2v_cast_5DD1B_signed(DEPTH - 1) ? {ADDR_BITS {1'sb0}} : wptr + 1'b1);
					rptr <= (rptr == sv2v_cast_5DD1B_signed(DEPTH - 1) ? {ADDR_BITS {1'sb0}} : rptr + 1'b1);
				end
				default:
					;
			endcase
	initial _sv2v_0 = 0;
endmodule
module PSC_RV32ISP_InstructionEngine (
	clock,
	reset_n,
	cpu_stop,
	cpu_state,
	cpu_trap,
	fifo_req_ready,
	execute_task_busy,
	execute_task_done,
	fifo_read_state_sig,
	execute_state_sig,
	fifo_read_ready,
	fifo_flush_sig,
	pc,
	counter,
	opcode,
	pc_now,
	csr_satp,
	priv_mode,
	alu_data,
	pc_sel2,
	decoder_ctrl,
	i_pf,
	d_pf,
	i_pf_event,
	d_pf_event,
	data_fault_pc,
	data_fault_vaddr,
	data_fault_is_store,
	trap_scause,
	csr_state,
	csr_enb,
	csr_valid,
	csr_rdata,
	csr_reg_data_1,
	data_mem_read_valid,
	data_mem_read_ready,
	data_mem_read_address,
	data_mem_read_data,
	data_mem_req_ready,
	data_mem_write_valid,
	data_mem_write_ready,
	data_mem_write_address,
	data_mem_write_data,
	mem_write_sel,
	vaddr,
	uart_out
);
	parameter [31:0] UART_MMIO_ADDR = 32'hf00400f0;
	parameter [31:0] UART_MMIO_FLAG = 32'hf00400f4;
	parameter [31:0] COUNTER_MMIO_ADDR = 32'hf004fff0;
	input wire clock;
	input wire reset_n;
	input wire cpu_stop;
	input wire [3:0] cpu_state;
	input wire cpu_trap;
	input wire fifo_req_ready;
	output wire execute_task_busy;
	output wire execute_task_done;
	output wire fifo_read_state_sig;
	output wire execute_state_sig;
	input wire fifo_read_ready;
	output wire fifo_flush_sig;
	output wire [31:0] pc;
	output wire [31:0] counter;
	input wire [31:0] opcode;
	input wire [31:0] pc_now;
	input wire [31:0] csr_satp;
	input wire [1:0] priv_mode;
	output wire [31:0] alu_data;
	output wire pc_sel2;
	output wire [129:0] decoder_ctrl;
	input wire i_pf;
	output wire d_pf;
	input wire i_pf_event;
	input wire d_pf_event;
	output wire [31:0] data_fault_pc;
	output wire [31:0] data_fault_vaddr;
	output wire data_fault_is_store;
	input wire [4:0] trap_scause;
	input wire [415:0] csr_state;
	output wire csr_enb;
	output wire csr_valid;
	input wire [31:0] csr_rdata;
	output wire [31:0] csr_reg_data_1;
	output wire data_mem_read_valid;
	input wire data_mem_read_ready;
	output wire [31:0] data_mem_read_address;
	input wire [31:0] data_mem_read_data;
	input wire data_mem_req_ready;
	output wire data_mem_write_valid;
	input wire data_mem_write_ready;
	output wire [31:0] data_mem_write_address;
	output wire [31:0] data_mem_write_data;
	output wire [2:0] mem_write_sel;
	output wire [31:0] vaddr;
	output wire [8:0] uart_out;
	wire decode_enb;
	wire decode_done;
	wire [129:0] decoded_ctrl;
	wire alu_execute_valid;
	wire [129:0] alu_execute_ctrl;
	wire [31:0] alu_execute_reg_data_1;
	wire [31:0] alu_execute_reg_data_2;
	wire [31:0] alu_execute_data;
	wire alu_execute_done;
	wire md_execute_valid;
	wire [129:0] md_execute_ctrl;
	wire [31:0] md_execute_reg_data_1;
	wire [31:0] md_execute_reg_data_2;
	wire [31:0] md_execute_data;
	wire md_execute_done;
	wire [129:0] memory_ctrl;
	wire [31:0] memory_alu_data;
	wire [31:0] memory_reg_data_1;
	wire [31:0] memory_reg_data_2;
	wire [31:0] memory_pc;
	wire load_valid;
	wire store_valid;
	wire load_done;
	wire store_done;
	wire [31:0] load_read_data;
	wire [129:0] commit_ctrl;
	wire [31:0] commit_alu_data;
	wire commit_branch_taken;
	wire load_data_mem_read_valid;
	wire load_mmu_valid;
	wire [31:0] load_data_mem_read_address;
	wire [31:0] load_vaddr;
	wire load_branch_unused;
	wire store_mmu_valid;
	wire [31:0] store_vaddr;
	wire [31:0] store_mem_write_address;
	wire [31:0] store_wdata_unused;
	wire d_mmu_mem_valid;
	wire d_mmu_done;
	wire d_mode_sv32;
	wire [31:0] d_mmu_mem_addr;
	wire [31:0] d_paddr;
	wire d_mmu_enb;
	wire cpu_state_done;
	wire [31:0] raw_load_data;
	wire is_counter_load;
	wire is_uart_flag_load;
	assign execute_state_sig = alu_execute_valid || md_execute_valid;
	assign decoder_ctrl = commit_ctrl;
	assign alu_data = commit_alu_data;
	assign pc_sel2 = commit_branch_taken;
	assign mem_write_sel = memory_ctrl[77-:3];
	assign is_counter_load = (memory_ctrl[77-:3] == 3'b010) && (memory_alu_data == COUNTER_MMIO_ADDR);
	assign is_uart_flag_load = !memory_ctrl[76:75] && (memory_alu_data == UART_MMIO_FLAG);
	assign raw_load_data = (is_counter_load ? counter : (is_uart_flag_load ? 32'd1 : data_mem_read_data));
	assign load_read_data = raw_load_data;
	assign vaddr = (load_valid ? load_vaddr : (store_valid ? store_vaddr : 32'd0));
	assign data_fault_pc = memory_pc;
	assign data_fault_vaddr = memory_alu_data;
	assign data_fault_is_store = memory_ctrl[6];
	assign d_mmu_enb = (load_mmu_valid || store_mmu_valid) && (memory_ctrl[7] || memory_ctrl[6]);
	assign cpu_state_done = load_done || store_done;
	assign data_mem_read_valid = d_mmu_mem_valid | load_data_mem_read_valid;
	assign data_mem_read_address = (d_mmu_mem_valid ? d_mmu_mem_addr : load_data_mem_read_address);
	assign data_mem_write_address = store_mem_write_address;
	PSC_InstructionUnit u_inst_unit(
		.clock(clock),
		.reset_n(reset_n),
		.cpu_stop(cpu_stop),
		.cpu_trap(cpu_trap),
		.priv_mode(priv_mode),
		.pc(pc),
		.counter(counter),
		.opcode(opcode),
		.pc_now(pc_now),
		.fifo_req_ready(fifo_req_ready),
		.fifo_read_ready(fifo_read_ready),
		.fifo_read_valid(fifo_read_state_sig),
		.fifo_flush(fifo_flush_sig),
		.decoded_ctrl(decoded_ctrl),
		.decode_enb(decode_enb),
		.decode_done(decode_done),
		.alu_execute_valid(alu_execute_valid),
		.alu_execute_ctrl(alu_execute_ctrl),
		.alu_execute_reg_data_1(alu_execute_reg_data_1),
		.alu_execute_reg_data_2(alu_execute_reg_data_2),
		.alu_execute_data(alu_execute_data),
		.alu_execute_done(alu_execute_done),
		.md_execute_valid(md_execute_valid),
		.md_execute_ctrl(md_execute_ctrl),
		.md_execute_reg_data_1(md_execute_reg_data_1),
		.md_execute_reg_data_2(md_execute_reg_data_2),
		.md_execute_data(md_execute_data),
		.md_execute_done(md_execute_done),
		.memory_ctrl(memory_ctrl),
		.memory_alu_data(memory_alu_data),
		.memory_reg_data_1(memory_reg_data_1),
		.memory_reg_data_2(memory_reg_data_2),
		.memory_pc(memory_pc),
		.load_valid(load_valid),
		.store_valid(store_valid),
		.load_done(load_done),
		.store_done(store_done),
		.load_read_data(load_read_data),
		.csr_state(csr_state),
		.csr_rdata(csr_rdata),
		.csr_reg_data_1(csr_reg_data_1),
		.csr_enb(csr_enb),
		.csr_valid(csr_valid),
		.commit_ctrl(commit_ctrl),
		.commit_alu_data(commit_alu_data),
		.commit_branch_taken(commit_branch_taken),
		.d_pf(d_pf),
		.i_pf(i_pf),
		.d_pf_event(d_pf_event),
		.i_pf_event(i_pf_event),
		.trap_scause(trap_scause),
		.execute_task_busy(execute_task_busy),
		.execute_task_done(execute_task_done)
	);
	Decorder u_Decorder(
		.clock(clock),
		.reset_n(reset_n),
		.decode_enb(decode_enb),
		.opcode(opcode),
		.in_pc(pc_now),
		.current_priv(priv_mode),
		.decode_done(decode_done),
		.decoder_ctrl(decoded_ctrl)
	);
	Execute #(
		.ENABLE_MUL(1'b0),
		.ENABLE_DIV(1'b0)
	) u_execute_alu(
		.clock(clock),
		.reset_n(reset_n),
		.execute_enb(alu_execute_valid),
		.decoder_ctrl(alu_execute_ctrl),
		.reg_data_addr1(alu_execute_reg_data_1),
		.reg_data_addr2(alu_execute_reg_data_2),
		.alu_data(alu_execute_data),
		.r_data1(),
		.r_data2(),
		.out_pc(),
		.busy(),
		.done(alu_execute_done)
	);
	Execute #(
		.ENABLE_MUL(1'b1),
		.ENABLE_DIV(1'b1)
	) u_execute_mul_div(
		.clock(clock),
		.reset_n(reset_n),
		.execute_enb(md_execute_valid),
		.decoder_ctrl(md_execute_ctrl),
		.reg_data_addr1(md_execute_reg_data_1),
		.reg_data_addr2(md_execute_reg_data_2),
		.alu_data(md_execute_data),
		.r_data1(),
		.r_data2(),
		.out_pc(),
		.busy(),
		.done(md_execute_done)
	);
	Branch u_load(
		.clock(clock),
		.reset_n(reset_n),
		.branch_enb(load_valid),
		.decoder_ctrl(memory_ctrl),
		.in_vaddr(memory_alu_data),
		.r_data1(memory_reg_data_1),
		.r_data2(memory_reg_data_2),
		.mmu_valid(load_mmu_valid),
		.vaddr(load_vaddr),
		.mmu_ready(d_mmu_done),
		.access_fault(d_pf),
		.d_paddr(d_paddr),
		.data_mem_read_address(load_data_mem_read_address),
		.data_mem_read_valid(load_data_mem_read_valid),
		.data_mem_req_ready(data_mem_req_ready),
		.data_mem_read_ready(data_mem_read_ready),
		.pc_sel2(load_branch_unused),
		.busy(),
		.branch_done(load_done)
	);
	MemoryStore #(
		.UART_MMIO_ADDR(UART_MMIO_ADDR),
		.UART_MMIO_FLAG(UART_MMIO_FLAG),
		.COUNTER_MMIO_ADDR(COUNTER_MMIO_ADDR)
	) u_store(
		.clock(clock),
		.reset_n(reset_n),
		.store_enb(store_valid),
		.mode_sv32(d_mode_sv32),
		.decoder_ctrl(memory_ctrl),
		.alu_data(memory_alu_data),
		.mem_val(memory_ctrl[77-:3]),
		.mem_read_data(32'd0),
		.r_data2(memory_reg_data_2),
		.in_pc(memory_pc),
		.counter(counter),
		.ld_low2(memory_alu_data[1:0]),
		.csr_rdata(csr_rdata),
		.mmu_valid(store_mmu_valid),
		.vaddr(store_vaddr),
		.mmu_ready(d_mmu_done),
		.access_fault(d_pf),
		.d_paddr(d_paddr),
		.data_mem_write_address(store_mem_write_address),
		.data_mem_write_valid(data_mem_write_valid),
		.data_mem_write_data(data_mem_write_data),
		.data_mem_write_ready(data_mem_write_ready),
		.data_mem_req_ready(data_mem_req_ready),
		.uart(uart_out),
		.w_data(store_wdata_unused),
		.busy(),
		.store_done(store_done)
	);
	MMU u_mmu_d(
		.clk(clock),
		.reset_n(reset_n),
		.MMU_enb(d_mmu_enb),
		.vaddr(vaddr),
		.satp(csr_satp),
		.priv_mode(priv_mode),
		.access_r(memory_ctrl[7]),
		.access_w(memory_ctrl[6]),
		.access_x(1'b0),
		.mem_req_ready(data_mem_req_ready),
		.mem_rdata(data_mem_read_data),
		.mem_addr(d_mmu_mem_addr),
		.mem_valid(d_mmu_mem_valid),
		.mem_ready(data_mem_read_ready),
		.cpu_state_done(cpu_state_done),
		.sfence_vma(fifo_flush_sig && commit_ctrl[32]),
		.paddr(d_paddr),
		.page_fault(d_pf),
		.mode_sv32(d_mode_sv32),
		.mmu_done(d_mmu_done)
	);
endmodule
module PSC_InstructionUnit (
	clock,
	reset_n,
	cpu_stop,
	cpu_trap,
	priv_mode,
	pc,
	counter,
	opcode,
	pc_now,
	fifo_req_ready,
	fifo_read_ready,
	fifo_read_valid,
	fifo_flush,
	decoded_ctrl,
	decode_enb,
	decode_done,
	alu_execute_valid,
	alu_execute_ctrl,
	alu_execute_reg_data_1,
	alu_execute_reg_data_2,
	alu_execute_data,
	alu_execute_done,
	md_execute_valid,
	md_execute_ctrl,
	md_execute_reg_data_1,
	md_execute_reg_data_2,
	md_execute_data,
	md_execute_done,
	memory_ctrl,
	memory_alu_data,
	memory_reg_data_1,
	memory_reg_data_2,
	memory_pc,
	load_valid,
	store_valid,
	load_done,
	store_done,
	load_read_data,
	csr_state,
	csr_rdata,
	csr_reg_data_1,
	csr_enb,
	csr_valid,
	commit_ctrl,
	commit_alu_data,
	commit_branch_taken,
	d_pf,
	i_pf,
	d_pf_event,
	i_pf_event,
	trap_scause,
	execute_task_busy,
	execute_task_done
);
	reg _sv2v_0;
	parameter signed [31:0] ROB_DEPTH = 2;
	parameter signed [31:0] IQ_DEPTH = 2;
	parameter signed [31:0] PRF_DEPTH = 32 + ROB_DEPTH;
	parameter signed [31:0] ROB_TAG_W = $clog2(ROB_DEPTH);
	parameter signed [31:0] IQ_IDX_W = $clog2(IQ_DEPTH);
	parameter signed [31:0] PHY_TAG_W = $clog2(PRF_DEPTH);
	input wire clock;
	input wire reset_n;
	input wire cpu_stop;
	input wire cpu_trap;
	input wire [1:0] priv_mode;
	output wire [31:0] pc;
	output wire [31:0] counter;
	input wire [31:0] opcode;
	input wire [31:0] pc_now;
	input wire fifo_req_ready;
	input wire fifo_read_ready;
	output wire fifo_read_valid;
	output wire fifo_flush;
	input wire [129:0] decoded_ctrl;
	output wire decode_enb;
	input wire decode_done;
	output wire alu_execute_valid;
	output wire [129:0] alu_execute_ctrl;
	output wire [31:0] alu_execute_reg_data_1;
	output wire [31:0] alu_execute_reg_data_2;
	input wire [31:0] alu_execute_data;
	input wire alu_execute_done;
	output wire md_execute_valid;
	output wire [129:0] md_execute_ctrl;
	output wire [31:0] md_execute_reg_data_1;
	output wire [31:0] md_execute_reg_data_2;
	input wire [31:0] md_execute_data;
	input wire md_execute_done;
	output wire [129:0] memory_ctrl;
	output wire [31:0] memory_alu_data;
	output wire [31:0] memory_reg_data_1;
	output wire [31:0] memory_reg_data_2;
	output wire [31:0] memory_pc;
	output wire load_valid;
	output wire store_valid;
	input wire load_done;
	input wire store_done;
	input wire [31:0] load_read_data;
	input wire [415:0] csr_state;
	input wire [31:0] csr_rdata;
	output wire [31:0] csr_reg_data_1;
	output wire csr_enb;
	output reg csr_valid;
	output wire [129:0] commit_ctrl;
	output wire [31:0] commit_alu_data;
	output wire commit_branch_taken;
	input wire d_pf;
	input wire i_pf;
	input wire d_pf_event;
	input wire i_pf_event;
	input wire [4:0] trap_scause;
	output wire execute_task_busy;
	output wire execute_task_done;
	reg [(198 + PHY_TAG_W) + 102:0] rob [0:ROB_DEPTH - 1];
	reg [(((((1 + ROB_TAG_W) + 33) + PHY_TAG_W) + 33) + PHY_TAG_W) - 1:0] iq [0:IQ_DEPTH - 1];
	reg decode_stage_valid;
	reg [129:0] decode_stage_ctrl;
	reg [31:0] decode_stage_opcode;
	wire decode_stage_ready;
	wire decode_capture_fire;
	reg [PHY_TAG_W - 1:0] decode_stage_src1_tag;
	reg [PHY_TAG_W - 1:0] decode_stage_src2_tag;
	reg [PHY_TAG_W - 1:0] capture_src1_tag;
	reg [PHY_TAG_W - 1:0] capture_src2_tag;
	reg [ROB_TAG_W - 1:0] rob_head;
	reg [ROB_TAG_W - 1:0] rob_tail;
	reg [ROB_TAG_W:0] rob_count;
	reg [31:0] rat_spec_valid;
	reg [ROB_TAG_W - 1:0] rat_spec_slot [0:31];
	reg [PRF_DEPTH - 1:0] free_list;
	wire [31:0] prf_read_data1;
	wire [31:0] prf_read_data2;
	wire prf_read_ready1;
	wire prf_read_ready2;
	reg has_free_phys;
	reg [PHY_TAG_W - 1:0] alloc_phys;
	wire dispatch_needs_dest;
	wire dispatch_fire;
	wire rob_full;
	wire iq_has_free;
	wire [IQ_IDX_W - 1:0] iq_free_idx;
	wire dispatch_blocked;
	reg dispatch_src1_ready;
	reg [31:0] dispatch_src1_value;
	wire [PHY_TAG_W - 1:0] dispatch_src1_tag;
	reg dispatch_src2_ready;
	reg [31:0] dispatch_src2_value;
	wire [PHY_TAG_W - 1:0] dispatch_src2_tag;
	reg alu_select_valid;
	reg [IQ_IDX_W - 1:0] alu_select_idx;
	reg md_select_valid;
	reg [IQ_IDX_W - 1:0] md_select_idx;
	reg iq0_ready;
	reg iq1_ready;
	reg iq0_md_candidate;
	reg iq1_md_candidate;
	reg iq0_alu_candidate;
	reg iq1_alu_candidate;
	reg alu_active;
	reg [ROB_TAG_W - 1:0] alu_active_rob_tag;
	reg [PHY_TAG_W - 1:0] alu_active_dest_phys;
	reg alu_active_dest_valid;
	reg [129:0] alu_active_ctrl;
	reg [31:0] alu_active_src1;
	reg [31:0] alu_active_src2;
	reg md_active;
	reg [ROB_TAG_W - 1:0] md_active_rob_tag;
	reg [PHY_TAG_W - 1:0] md_active_dest_phys;
	reg md_active_dest_valid;
	reg [129:0] md_active_ctrl;
	reg [31:0] md_active_src1;
	reg [31:0] md_active_src2;
	wire alu_wb_valid;
	wire [ROB_TAG_W - 1:0] alu_wb_rob_tag;
	wire [PHY_TAG_W - 1:0] alu_wb_phys_tag;
	wire alu_wb_has_dest;
	wire [31:0] alu_wb_value;
	wire md_wb_valid;
	wire load_wb_valid;
	wire [31:0] load_wb_value;
	wire commit_fire;
	wire [31:0] commit_result;
	wire branch_redirect;
	reg [63:0] ooo_cycle;
	integer i;
	integer scan_free;
	PSC_Register #(
		.ENTRIES(PRF_DEPTH),
		.TAG_W(PHY_TAG_W)
	) u_physical_register_file(
		.clock(clock),
		.reset_n(reset_n),
		.cpu_stop(cpu_stop),
		.read_addr1(dispatch_src1_tag),
		.read_addr2(dispatch_src2_tag),
		.read_data1(prf_read_data1),
		.read_data2(prf_read_data2),
		.read_ready1(prf_read_ready1),
		.read_ready2(prf_read_ready2),
		.allocate_valid(dispatch_fire && dispatch_needs_dest),
		.allocate_addr(alloc_phys),
		.release_valid((commit_fire && rob[rob_head][1 + (PHY_TAG_W + 102)]) && !rob[rob_head][37]),
		.release_addr(rob[rob_head][PHY_TAG_W + 102-:((PHY_TAG_W + 102) >= 103 ? PHY_TAG_W + 0 : 104 - (PHY_TAG_W + 102))]),
		.wb0_valid((alu_wb_valid && alu_wb_has_dest) && (rob[iq[alu_select_idx][ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))-:((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) >= (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) ? ((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) - (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0))))) + 1 : ((33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) - (ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32))))) + 1)]][(163 + (PHY_TAG_W + 102)) - 59-:2] != 2'b11)),
		.wb0_addr(alu_wb_phys_tag),
		.wb0_data(alu_wb_value),
		.wb1_valid(md_wb_valid && md_active_dest_valid),
		.wb1_addr(md_active_dest_phys),
		.wb1_data(md_execute_data),
		.wb2_valid(load_wb_valid && rob[rob_head][1 + (PHY_TAG_W + 102)]),
		.wb2_addr(rob[rob_head][PHY_TAG_W + 102-:((PHY_TAG_W + 102) >= 103 ? PHY_TAG_W + 0 : 104 - (PHY_TAG_W + 102))]),
		.wb2_data(load_wb_value),
		.wb3_valid((commit_fire && rob[rob_head][1 + (PHY_TAG_W + 102)]) && !rob[rob_head][37]),
		.wb3_addr(rob[rob_head][(163 + (PHY_TAG_W + 102)) - 10-:5]),
		.wb3_data(commit_result)
	);
	function automatic is_mul_div;
		input reg [129:0] ctrl;
		is_mul_div = (ctrl[82:80] == 3'b110) || (ctrl[82:80] == 3'b111);
	endfunction
	function automatic serializing_instruction;
		input reg [129:0] ctrl;
		serializing_instruction = (((((((((ctrl[7] || ctrl[6]) || (ctrl[68-:2] != 2'b00)) || ctrl[31]) || ctrl[34]) || ctrl[33]) || ctrl[32]) || ctrl[8]) || ctrl[9]) || ctrl[10]) || ctrl[0];
	endfunction
	function automatic branch_exec;
		input reg [1:0] pc_sel;
		input reg [2:0] funct3;
		input reg [31:0] data1;
		input reg [31:0] data2;
		case (pc_sel)
			2'b01:
				case (funct3)
					3'b000: branch_exec = data1 == data2;
					3'b001: branch_exec = data1 != data2;
					3'b100: branch_exec = $signed(data1) < $signed(data2);
					3'b101: branch_exec = $signed(data1) >= $signed(data2);
					3'b110: branch_exec = data1 < data2;
					3'b111: branch_exec = data1 >= data2;
					default: branch_exec = 1'b0;
				endcase
			2'b10: branch_exec = 1'b1;
			default: branch_exec = 1'b0;
		endcase
	endfunction
	function automatic [31:0] load_result;
		input reg [31:0] raw_data;
		input reg [1:0] low2;
		input reg [2:0] funct3;
		reg [7:0] byte_data;
		reg [15:0] half_data;
		begin
			case (low2)
				2'd0: byte_data = raw_data[7:0];
				2'd1: byte_data = raw_data[15:8];
				2'd2: byte_data = raw_data[23:16];
				default: byte_data = raw_data[31:24];
			endcase
			half_data = (low2[1] ? raw_data[31:16] : raw_data[15:0]);
			case (funct3)
				3'b000: load_result = {{24 {byte_data[7]}}, byte_data};
				3'b001: load_result = {{16 {half_data[15]}}, half_data};
				3'b100: load_result = {24'd0, byte_data};
				3'b101: load_result = {16'd0, half_data};
				default: load_result = raw_data;
			endcase
		end
	endfunction
	always @(*) begin
		if (_sv2v_0)
			;
		has_free_phys = 1'b0;
		alloc_phys = 1'sb0;
		for (scan_free = 32; scan_free < PRF_DEPTH; scan_free = scan_free + 1)
			if (free_list[scan_free] && !has_free_phys) begin
				has_free_phys = 1'b1;
				alloc_phys = scan_free[PHY_TAG_W - 1:0];
			end
	end
	assign dispatch_needs_dest = decode_stage_ctrl[71] && (decode_stage_ctrl[119-:5] != 5'd0);
	always @(*) begin
		if (_sv2v_0)
			;
		capture_src1_tag = decoded_ctrl[129-:5];
		if (!decoded_ctrl[5])
			capture_src1_tag = 1'sb0;
		else if ((dispatch_fire && dispatch_needs_dest) && (decode_stage_ctrl[119-:5] == decoded_ctrl[129-:5]))
			capture_src1_tag = alloc_phys;
		else if (rat_spec_valid[decoded_ctrl[129-:5]]) begin
			if (((commit_fire && rob[rob_head][1 + (PHY_TAG_W + 102)]) && (rob[rob_head][(163 + (PHY_TAG_W + 102)) - 10-:5] == decoded_ctrl[129-:5])) && (rat_spec_slot[decoded_ctrl[129-:5]] == rob[rob_head][(PHY_TAG_W + 102) - ((PHY_TAG_W - 1) - (ROB_TAG_W - 1)):(PHY_TAG_W + 102) - (PHY_TAG_W - 1)]))
				capture_src1_tag = decoded_ctrl[129-:5];
			else
				capture_src1_tag = 6'd32 + rat_spec_slot[decoded_ctrl[129-:5]];
		end
		capture_src2_tag = decoded_ctrl[124-:5];
		if (!decoded_ctrl[4])
			capture_src2_tag = 1'sb0;
		else if ((dispatch_fire && dispatch_needs_dest) && (decode_stage_ctrl[119-:5] == decoded_ctrl[124-:5]))
			capture_src2_tag = alloc_phys;
		else if (rat_spec_valid[decoded_ctrl[124-:5]]) begin
			if (((commit_fire && rob[rob_head][1 + (PHY_TAG_W + 102)]) && (rob[rob_head][(163 + (PHY_TAG_W + 102)) - 10-:5] == decoded_ctrl[124-:5])) && (rat_spec_slot[decoded_ctrl[124-:5]] == rob[rob_head][(PHY_TAG_W + 102) - ((PHY_TAG_W - 1) - (ROB_TAG_W - 1)):(PHY_TAG_W + 102) - (PHY_TAG_W - 1)]))
				capture_src2_tag = decoded_ctrl[124-:5];
			else
				capture_src2_tag = 6'd32 + rat_spec_slot[decoded_ctrl[124-:5]];
		end
	end
	assign dispatch_src1_tag = decode_stage_src1_tag;
	assign dispatch_src2_tag = decode_stage_src2_tag;
	always @(*) begin
		if (_sv2v_0)
			;
		dispatch_src1_ready = (!decode_stage_ctrl[5] || (decode_stage_ctrl[129-:5] == 5'd0)) || prf_read_ready1;
		dispatch_src1_value = (!decode_stage_ctrl[5] || (decode_stage_ctrl[129-:5] == 5'd0) ? 32'd0 : prf_read_data1);
		if ((alu_wb_valid && alu_wb_has_dest) && (dispatch_src1_tag == alu_wb_phys_tag)) begin
			dispatch_src1_ready = 1'b1;
			dispatch_src1_value = alu_wb_value;
		end
		else if ((md_wb_valid && md_active_dest_valid) && (dispatch_src1_tag == md_active_dest_phys)) begin
			dispatch_src1_ready = 1'b1;
			dispatch_src1_value = md_execute_data;
		end
		else if ((load_wb_valid && rob[rob_head][1 + (PHY_TAG_W + 102)]) && (dispatch_src1_tag == rob[rob_head][PHY_TAG_W + 102-:((PHY_TAG_W + 102) >= 103 ? PHY_TAG_W + 0 : 104 - (PHY_TAG_W + 102))])) begin
			dispatch_src1_ready = 1'b1;
			dispatch_src1_value = load_wb_value;
		end
		dispatch_src2_ready = (!decode_stage_ctrl[4] || (decode_stage_ctrl[124-:5] == 5'd0)) || prf_read_ready2;
		dispatch_src2_value = (!decode_stage_ctrl[4] || (decode_stage_ctrl[124-:5] == 5'd0) ? 32'd0 : prf_read_data2);
		if ((alu_wb_valid && alu_wb_has_dest) && (dispatch_src2_tag == alu_wb_phys_tag)) begin
			dispatch_src2_ready = 1'b1;
			dispatch_src2_value = alu_wb_value;
		end
		else if ((md_wb_valid && md_active_dest_valid) && (dispatch_src2_tag == md_active_dest_phys)) begin
			dispatch_src2_ready = 1'b1;
			dispatch_src2_value = md_execute_data;
		end
		else if ((load_wb_valid && rob[rob_head][1 + (PHY_TAG_W + 102)]) && (dispatch_src2_tag == rob[rob_head][PHY_TAG_W + 102-:((PHY_TAG_W + 102) >= 103 ? PHY_TAG_W + 0 : 104 - (PHY_TAG_W + 102))])) begin
			dispatch_src2_ready = 1'b1;
			dispatch_src2_value = load_wb_value;
		end
	end
	assign iq_has_free = !iq[0][1 + (ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32))))] || !iq[1][1 + (ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32))))];
	assign iq_free_idx = iq[0][1 + (ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32))))];
	assign dispatch_blocked = (rob[0][198 + (PHY_TAG_W + 102)] && serializing_instruction(rob[0][163 + (PHY_TAG_W + 102)-:((163 + (PHY_TAG_W + 102)) >= (33 + (PHY_TAG_W + 103)) ? ((163 + (PHY_TAG_W + 102)) - (33 + (PHY_TAG_W + 103))) + 1 : ((33 + (PHY_TAG_W + 103)) - (163 + (PHY_TAG_W + 102))) + 1)])) || (rob[1][198 + (PHY_TAG_W + 102)] && serializing_instruction(rob[1][163 + (PHY_TAG_W + 102)-:((163 + (PHY_TAG_W + 102)) >= (33 + (PHY_TAG_W + 103)) ? ((163 + (PHY_TAG_W + 102)) - (33 + (PHY_TAG_W + 103))) + 1 : ((33 + (PHY_TAG_W + 103)) - (163 + (PHY_TAG_W + 102))) + 1)]));
	assign rob_full = rob_count == ROB_DEPTH;
	assign dispatch_fire = ((((((((decode_stage_valid && !rob_full) && iq_has_free) && (!dispatch_needs_dest || has_free_phys)) && !dispatch_blocked) && !cpu_stop) && !cpu_trap) && !d_pf) && !i_pf) && !fifo_flush;
	assign decode_stage_ready = !decode_stage_valid || dispatch_fire;
	assign decode_enb = (((((fifo_req_ready && decode_stage_ready) && !cpu_stop) && !cpu_trap) && !d_pf) && !i_pf) && !fifo_flush;
	assign decode_capture_fire = decode_done && decode_enb;
	assign fifo_read_valid = decode_capture_fire;
	always @(*) begin
		if (_sv2v_0)
			;
		iq0_ready = (iq[0][1 + (ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32))))] && iq[0][33 + (PHY_TAG_W + (PHY_TAG_W + 32))]) && iq[0][PHY_TAG_W + 32];
		iq1_ready = (iq[1][1 + (ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32))))] && iq[1][33 + (PHY_TAG_W + (PHY_TAG_W + 32))]) && iq[1][PHY_TAG_W + 32];
		iq0_md_candidate = (iq0_ready && is_mul_div(rob[iq[0][ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))-:((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) >= (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) ? ((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) - (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0))))) + 1 : ((33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) - (ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32))))) + 1)]][163 + (PHY_TAG_W + 102)-:((163 + (PHY_TAG_W + 102)) >= (33 + (PHY_TAG_W + 103)) ? ((163 + (PHY_TAG_W + 102)) - (33 + (PHY_TAG_W + 103))) + 1 : ((33 + (PHY_TAG_W + 103)) - (163 + (PHY_TAG_W + 102))) + 1)])) && !md_active;
		iq1_md_candidate = (iq1_ready && is_mul_div(rob[iq[1][ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))-:((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) >= (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) ? ((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) - (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0))))) + 1 : ((33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) - (ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32))))) + 1)]][163 + (PHY_TAG_W + 102)-:((163 + (PHY_TAG_W + 102)) >= (33 + (PHY_TAG_W + 103)) ? ((163 + (PHY_TAG_W + 102)) - (33 + (PHY_TAG_W + 103))) + 1 : ((33 + (PHY_TAG_W + 103)) - (163 + (PHY_TAG_W + 102))) + 1)])) && !md_active;
		iq0_alu_candidate = ((iq0_ready && !alu_active) && !is_mul_div(rob[iq[0][ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))-:((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) >= (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) ? ((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) - (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0))))) + 1 : ((33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) - (ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32))))) + 1)]][163 + (PHY_TAG_W + 102)-:((163 + (PHY_TAG_W + 102)) >= (33 + (PHY_TAG_W + 103)) ? ((163 + (PHY_TAG_W + 102)) - (33 + (PHY_TAG_W + 103))) + 1 : ((33 + (PHY_TAG_W + 103)) - (163 + (PHY_TAG_W + 102))) + 1)])) && (!serializing_instruction(rob[iq[0][ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))-:((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) >= (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) ? ((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) - (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0))))) + 1 : ((33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) - (ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32))))) + 1)]][163 + (PHY_TAG_W + 102)-:((163 + (PHY_TAG_W + 102)) >= (33 + (PHY_TAG_W + 103)) ? ((163 + (PHY_TAG_W + 102)) - (33 + (PHY_TAG_W + 103))) + 1 : ((33 + (PHY_TAG_W + 103)) - (163 + (PHY_TAG_W + 102))) + 1)]) || (iq[0][ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))-:((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) >= (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) ? ((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) - (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0))))) + 1 : ((33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) - (ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32))))) + 1)] == rob_head));
		iq1_alu_candidate = ((iq1_ready && !alu_active) && !is_mul_div(rob[iq[1][ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))-:((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) >= (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) ? ((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) - (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0))))) + 1 : ((33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) - (ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32))))) + 1)]][163 + (PHY_TAG_W + 102)-:((163 + (PHY_TAG_W + 102)) >= (33 + (PHY_TAG_W + 103)) ? ((163 + (PHY_TAG_W + 102)) - (33 + (PHY_TAG_W + 103))) + 1 : ((33 + (PHY_TAG_W + 103)) - (163 + (PHY_TAG_W + 102))) + 1)])) && (!serializing_instruction(rob[iq[1][ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))-:((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) >= (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) ? ((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) - (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0))))) + 1 : ((33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) - (ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32))))) + 1)]][163 + (PHY_TAG_W + 102)-:((163 + (PHY_TAG_W + 102)) >= (33 + (PHY_TAG_W + 103)) ? ((163 + (PHY_TAG_W + 102)) - (33 + (PHY_TAG_W + 103))) + 1 : ((33 + (PHY_TAG_W + 103)) - (163 + (PHY_TAG_W + 102))) + 1)]) || (iq[1][ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))-:((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) >= (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) ? ((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) - (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0))))) + 1 : ((33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) - (ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32))))) + 1)] == rob_head));
		alu_select_valid = 1'b0;
		alu_select_idx = 1'sb0;
		md_select_valid = 1'b0;
		md_select_idx = 1'sb0;
		if (iq0_alu_candidate || iq1_alu_candidate) begin
			alu_select_valid = 1'b1;
			if (!iq0_alu_candidate)
				alu_select_idx = 1'b1;
			else if ((iq1_alu_candidate && (iq[1][ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))-:((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) >= (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) ? ((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) - (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0))))) + 1 : ((33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) - (ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32))))) + 1)] == rob_head)) && (iq[0][ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))-:((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) >= (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) ? ((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) - (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0))))) + 1 : ((33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) - (ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32))))) + 1)] != rob_head))
				alu_select_idx = 1'b1;
		end
		if (iq0_md_candidate || iq1_md_candidate) begin
			md_select_valid = 1'b1;
			if (!iq0_md_candidate)
				md_select_idx = 1'b1;
			else if ((iq1_md_candidate && (iq[1][ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))-:((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) >= (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) ? ((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) - (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0))))) + 1 : ((33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) - (ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32))))) + 1)] == rob_head)) && (iq[0][ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))-:((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) >= (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) ? ((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) - (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0))))) + 1 : ((33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) - (ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32))))) + 1)] != rob_head))
				md_select_idx = 1'b1;
		end
	end
	assign alu_execute_valid = alu_active;
	assign alu_execute_ctrl = (alu_active ? alu_active_ctrl : {130 {1'sb0}});
	assign alu_execute_reg_data_1 = (alu_active ? alu_active_src1 : 32'd0);
	assign alu_execute_reg_data_2 = (alu_active ? alu_active_src2 : 32'd0);
	assign md_execute_valid = md_active;
	assign md_execute_ctrl = (md_active ? md_active_ctrl : {130 {1'sb0}});
	assign md_execute_reg_data_1 = md_active_src1;
	assign md_execute_reg_data_2 = md_active_src2;
	assign alu_wb_valid = alu_active && alu_execute_done;
	assign alu_wb_rob_tag = alu_active_rob_tag;
	assign alu_wb_has_dest = alu_active_dest_valid;
	assign alu_wb_phys_tag = alu_active_dest_phys;
	assign alu_wb_value = (alu_active_ctrl[70-:2] == 2'b10 ? alu_active_ctrl[66-:32] + 32'd4 : alu_execute_data);
	assign md_wb_valid = md_active && md_execute_done;
	assign load_wb_valid = (load_done && load_valid) && !d_pf;
	assign load_wb_value = load_result(load_read_data, rob[rob_head][72:71], rob[rob_head][(163 + (PHY_TAG_W + 102)) - 52-:3]);
	assign memory_ctrl = (rob_count != 0 ? rob[rob_head][163 + (PHY_TAG_W + 102)-:((163 + (PHY_TAG_W + 102)) >= (33 + (PHY_TAG_W + 103)) ? ((163 + (PHY_TAG_W + 102)) - (33 + (PHY_TAG_W + 103))) + 1 : ((33 + (PHY_TAG_W + 103)) - (163 + (PHY_TAG_W + 102))) + 1)] : {130 {1'sb0}});
	assign memory_alu_data = rob[rob_head][102-:32];
	assign memory_reg_data_1 = 32'd0;
	assign memory_reg_data_2 = rob[rob_head][33 + (PHY_TAG_W + 102)-:((33 + (PHY_TAG_W + 102)) >= (1 + (PHY_TAG_W + 103)) ? ((33 + (PHY_TAG_W + 102)) - (1 + (PHY_TAG_W + 103))) + 1 : ((1 + (PHY_TAG_W + 103)) - (33 + (PHY_TAG_W + 102))) + 1)];
	assign memory_pc = rob[rob_head][(163 + (PHY_TAG_W + 102)) - 63-:32];
	assign load_valid = ((((rob_count != 0) && rob[rob_head][198 + (PHY_TAG_W + 102)]) && rob[rob_head][196 + (PHY_TAG_W + 102)]) && !rob[rob_head][197 + (PHY_TAG_W + 102)]) && rob[rob_head][(163 + (PHY_TAG_W + 102)) - 122];
	assign store_valid = ((((rob_count != 0) && rob[rob_head][198 + (PHY_TAG_W + 102)]) && rob[rob_head][196 + (PHY_TAG_W + 102)]) && !rob[rob_head][197 + (PHY_TAG_W + 102)]) && rob[rob_head][(163 + (PHY_TAG_W + 102)) - 123];
	assign commit_fire = ((rob_count != 0) && rob[rob_head][198 + (PHY_TAG_W + 102)]) && rob[rob_head][197 + (PHY_TAG_W + 102)];
	assign commit_result = (rob[rob_head][(163 + (PHY_TAG_W + 102)) - 59-:2] == 2'b11 ? csr_rdata : rob[rob_head][102-:32]);
	assign commit_ctrl = (commit_fire ? rob[rob_head][163 + (PHY_TAG_W + 102)-:((163 + (PHY_TAG_W + 102)) >= (33 + (PHY_TAG_W + 103)) ? ((163 + (PHY_TAG_W + 102)) - (33 + (PHY_TAG_W + 103))) + 1 : ((33 + (PHY_TAG_W + 103)) - (163 + (PHY_TAG_W + 102))) + 1)] : {130 {1'sb0}});
	assign commit_alu_data = rob[rob_head][69-:32];
	assign commit_branch_taken = commit_fire && rob[rob_head][70];
	assign csr_reg_data_1 = rob[rob_head][33 + (PHY_TAG_W + 102)-:((33 + (PHY_TAG_W + 102)) >= (1 + (PHY_TAG_W + 103)) ? ((33 + (PHY_TAG_W + 102)) - (1 + (PHY_TAG_W + 103))) + 1 : ((1 + (PHY_TAG_W + 103)) - (33 + (PHY_TAG_W + 102))) + 1)];
	assign csr_enb = commit_fire && !rob[rob_head][37];
	assign branch_redirect = (alu_wb_valid && (alu_active_ctrl[68-:2] != 2'b00)) && branch_exec(alu_active_ctrl[68-:2], alu_active_ctrl[77-:3], alu_active_src1, alu_active_src2);
	assign fifo_flush = ((d_pf || i_pf) || branch_redirect) || (commit_fire && (((((((rob[rob_head][(163 + (PHY_TAG_W + 102)) - 96] || rob[rob_head][(163 + (PHY_TAG_W + 102)) - 97]) || rob[rob_head][(163 + (PHY_TAG_W + 102)) - 121]) || rob[rob_head][(163 + (PHY_TAG_W + 102)) - 120]) || rob[rob_head][(163 + (PHY_TAG_W + 102)) - 119]) || rob[rob_head][(163 + (PHY_TAG_W + 102)) - 129]) || rob[rob_head][37]) || cpu_trap));
	assign execute_task_busy = (rob_count != 0) || md_active;
	assign execute_task_done = commit_fire;
	always @(posedge clock or negedge reset_n)
		if (!reset_n)
			csr_valid <= 1'b0;
		else
			csr_valid <= csr_enb;
	always @(posedge clock or negedge reset_n)
		if (!reset_n)
			ooo_cycle <= 64'd0;
		else if (cpu_stop)
			ooo_cycle <= 64'd0;
		else
			ooo_cycle <= ooo_cycle + 64'd1;
	always @(posedge clock or negedge reset_n)
		if (!reset_n) begin
			decode_stage_valid <= 1'b0;
			decode_stage_ctrl <= 1'sb0;
			decode_stage_opcode <= 32'd0;
			decode_stage_src1_tag <= 1'sb0;
			decode_stage_src2_tag <= 1'sb0;
		end
		else if ((((cpu_stop || cpu_trap) || d_pf) || i_pf) || fifo_flush)
			decode_stage_valid <= 1'b0;
		else if (decode_capture_fire) begin
			decode_stage_valid <= 1'b1;
			decode_stage_ctrl <= decoded_ctrl;
			decode_stage_opcode <= opcode;
			decode_stage_src1_tag <= capture_src1_tag;
			decode_stage_src2_tag <= capture_src2_tag;
		end
		else if (dispatch_fire)
			decode_stage_valid <= 1'b0;
		else if ((commit_fire && rob[rob_head][1 + (PHY_TAG_W + 102)]) && !rob[rob_head][37]) begin
			if (decode_stage_ctrl[5] && (decode_stage_src1_tag == rob[rob_head][PHY_TAG_W + 102-:((PHY_TAG_W + 102) >= 103 ? PHY_TAG_W + 0 : 104 - (PHY_TAG_W + 102))]))
				decode_stage_src1_tag <= rob[rob_head][(163 + (PHY_TAG_W + 102)) - 10-:5];
			if (decode_stage_ctrl[4] && (decode_stage_src2_tag == rob[rob_head][PHY_TAG_W + 102-:((PHY_TAG_W + 102) >= 103 ? PHY_TAG_W + 0 : 104 - (PHY_TAG_W + 102))]))
				decode_stage_src2_tag <= rob[rob_head][(163 + (PHY_TAG_W + 102)) - 10-:5];
		end
	always @(posedge clock or negedge reset_n)
		if (!reset_n) begin
			rob_head <= 1'sb0;
			rob_tail <= 1'sb0;
			rob_count <= 1'sb0;
			alu_active <= 1'b0;
			alu_active_rob_tag <= 1'sb0;
			alu_active_dest_phys <= 1'sb0;
			alu_active_dest_valid <= 1'b0;
			alu_active_ctrl <= 1'sb0;
			alu_active_src1 <= 32'd0;
			alu_active_src2 <= 32'd0;
			md_active <= 1'b0;
			md_active_rob_tag <= 1'sb0;
			md_active_dest_phys <= 1'sb0;
			md_active_dest_valid <= 1'b0;
			md_active_ctrl <= 1'sb0;
			md_active_src1 <= 32'd0;
			md_active_src2 <= 32'd0;
			free_list <= 1'sb0;
			rat_spec_valid <= 1'sb0;
			for (i = 32; i < PRF_DEPTH; i = i + 1)
				free_list[i] <= 1'b1;
			for (i = 0; i < ROB_DEPTH; i = i + 1)
				rob[i] <= 1'sb0;
			for (i = 0; i < IQ_DEPTH; i = i + 1)
				iq[i] <= 1'sb0;
		end
		else if (cpu_stop) begin
			rob_head <= 1'sb0;
			rob_tail <= 1'sb0;
			rob_count <= 1'sb0;
			alu_active <= 1'b0;
			md_active <= 1'b0;
			free_list <= 1'sb0;
			rat_spec_valid <= 1'sb0;
			for (i = 32; i < PRF_DEPTH; i = i + 1)
				free_list[i] <= 1'b1;
			for (i = 0; i < ROB_DEPTH; i = i + 1)
				rob[i] <= 1'sb0;
			for (i = 0; i < IQ_DEPTH; i = i + 1)
				iq[i] <= 1'sb0;
		end
		else if ((cpu_trap || d_pf) || i_pf) begin
			rob_head <= 1'sb0;
			rob_tail <= 1'sb0;
			rob_count <= 1'sb0;
			alu_active <= 1'b0;
			md_active <= 1'b0;
			free_list <= 1'sb0;
			rat_spec_valid <= 1'sb0;
			for (i = 32; i < PRF_DEPTH; i = i + 1)
				free_list[i] <= 1'b1;
			for (i = 0; i < ROB_DEPTH; i = i + 1)
				rob[i] <= 1'sb0;
			for (i = 0; i < IQ_DEPTH; i = i + 1)
				iq[i] <= 1'sb0;
		end
		else begin
			rat_spec_valid[0] <= 1'b0;
			if (commit_fire) begin
				rob[rob_head][198 + (PHY_TAG_W + 102)] <= 1'b0;
				if (rob[rob_head][1 + (PHY_TAG_W + 102)] && !rob[rob_head][37]) begin
					if (rat_spec_valid[rob[rob_head][(163 + (PHY_TAG_W + 102)) - 10-:5]] && (rat_spec_slot[rob[rob_head][(163 + (PHY_TAG_W + 102)) - 10-:5]] == rob[rob_head][(PHY_TAG_W + 102) - ((PHY_TAG_W - 1) - (ROB_TAG_W - 1)):(PHY_TAG_W + 102) - (PHY_TAG_W - 1)]))
						rat_spec_valid[rob[rob_head][(163 + (PHY_TAG_W + 102)) - 10-:5]] <= 1'b0;
					free_list[rob[rob_head][PHY_TAG_W + 102-:((PHY_TAG_W + 102) >= 103 ? PHY_TAG_W + 0 : 104 - (PHY_TAG_W + 102))]] <= 1'b1;
				end
				rob_head <= rob_head + 1'b1;
			end
			if (dispatch_fire) begin
				rob[rob_tail][198 + (PHY_TAG_W + 102)] <= 1'b1;
				rob[rob_tail][197 + (PHY_TAG_W + 102)] <= 1'b0;
				rob[rob_tail][196 + (PHY_TAG_W + 102)] <= 1'b0;
				rob[rob_tail][195 + (PHY_TAG_W + 102)-:((195 + (PHY_TAG_W + 102)) >= (163 + (PHY_TAG_W + 103)) ? ((195 + (PHY_TAG_W + 102)) - (163 + (PHY_TAG_W + 103))) + 1 : ((163 + (PHY_TAG_W + 103)) - (195 + (PHY_TAG_W + 102))) + 1)] <= decode_stage_opcode;
				rob[rob_tail][163 + (PHY_TAG_W + 102)-:((163 + (PHY_TAG_W + 102)) >= (33 + (PHY_TAG_W + 103)) ? ((163 + (PHY_TAG_W + 102)) - (33 + (PHY_TAG_W + 103))) + 1 : ((33 + (PHY_TAG_W + 103)) - (163 + (PHY_TAG_W + 102))) + 1)] <= decode_stage_ctrl;
				rob[rob_tail][33 + (PHY_TAG_W + 102)-:((33 + (PHY_TAG_W + 102)) >= (1 + (PHY_TAG_W + 103)) ? ((33 + (PHY_TAG_W + 102)) - (1 + (PHY_TAG_W + 103))) + 1 : ((1 + (PHY_TAG_W + 103)) - (33 + (PHY_TAG_W + 102))) + 1)] <= 32'd0;
				rob[rob_tail][1 + (PHY_TAG_W + 102)] <= dispatch_needs_dest;
				rob[rob_tail][PHY_TAG_W + 102-:((PHY_TAG_W + 102) >= 103 ? PHY_TAG_W + 0 : 104 - (PHY_TAG_W + 102))] <= (dispatch_needs_dest ? alloc_phys : {((PHY_TAG_W + 102) >= 103 ? PHY_TAG_W + 0 : 104 - (PHY_TAG_W + 102)) * 1 {1'sb0}});
				rob[rob_tail][102-:32] <= 32'd0;
				rob[rob_tail][70] <= 1'b0;
				rob[rob_tail][69-:32] <= 32'd0;
				rob[rob_tail][37] <= decode_stage_ctrl[0];
				rob[rob_tail][36-:5] <= (decode_stage_ctrl[0] ? 5'd2 : 5'd0);
				rob[rob_tail][31-:32] <= (decode_stage_ctrl[0] ? decode_stage_opcode : 32'd0);
				iq[iq_free_idx][1 + (ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32))))] <= 1'b1;
				iq[iq_free_idx][ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))-:((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) >= (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) ? ((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) - (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0))))) + 1 : ((33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) - (ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32))))) + 1)] <= rob_tail;
				iq[iq_free_idx][33 + (PHY_TAG_W + (PHY_TAG_W + 32))] <= dispatch_src1_ready;
				iq[iq_free_idx][32 + (PHY_TAG_W + (PHY_TAG_W + 32))-:((32 + (PHY_TAG_W + (PHY_TAG_W + 32))) >= (PHY_TAG_W + (33 + (PHY_TAG_W + 0))) ? ((32 + (PHY_TAG_W + (PHY_TAG_W + 32))) - (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) + 1 : ((PHY_TAG_W + (33 + (PHY_TAG_W + 0))) - (32 + (PHY_TAG_W + (PHY_TAG_W + 32)))) + 1)] <= dispatch_src1_value;
				iq[iq_free_idx][PHY_TAG_W + (PHY_TAG_W + 32)-:((PHY_TAG_W + (PHY_TAG_W + 32)) >= (33 + (PHY_TAG_W + 0)) ? ((PHY_TAG_W + (PHY_TAG_W + 32)) - (33 + (PHY_TAG_W + 0))) + 1 : ((33 + (PHY_TAG_W + 0)) - (PHY_TAG_W + (PHY_TAG_W + 32))) + 1)] <= dispatch_src1_tag;
				iq[iq_free_idx][PHY_TAG_W + 32] <= dispatch_src2_ready;
				iq[iq_free_idx][PHY_TAG_W + 31-:((PHY_TAG_W + 31) >= (PHY_TAG_W + 0) ? ((PHY_TAG_W + 31) - (PHY_TAG_W + 0)) + 1 : ((PHY_TAG_W + 0) - (PHY_TAG_W + 31)) + 1)] <= dispatch_src2_value;
				iq[iq_free_idx][PHY_TAG_W - 1-:PHY_TAG_W] <= dispatch_src2_tag;
				if (dispatch_needs_dest) begin
					rat_spec_valid[decode_stage_ctrl[119-:5]] <= 1'b1;
					rat_spec_slot[decode_stage_ctrl[119-:5]] <= alloc_phys[ROB_TAG_W - 1:0];
					free_list[alloc_phys] <= 1'b0;
				end
				rob_tail <= rob_tail + 1'b1;
			end
			case ({dispatch_fire, commit_fire})
				2'b10: rob_count <= rob_count + 1'b1;
				2'b01: rob_count <= rob_count - 1'b1;
				default: rob_count <= rob_count;
			endcase
			if (alu_select_valid && !alu_active) begin
				iq[alu_select_idx][1 + (ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32))))] <= 1'b0;
				alu_active <= 1'b1;
				alu_active_rob_tag <= iq[alu_select_idx][ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))-:((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) >= (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) ? ((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) - (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0))))) + 1 : ((33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) - (ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32))))) + 1)];
				alu_active_dest_valid <= rob[iq[alu_select_idx][ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))-:((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) >= (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) ? ((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) - (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0))))) + 1 : ((33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) - (ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32))))) + 1)]][1 + (PHY_TAG_W + 102)];
				alu_active_dest_phys <= rob[iq[alu_select_idx][ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))-:((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) >= (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) ? ((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) - (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0))))) + 1 : ((33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) - (ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32))))) + 1)]][PHY_TAG_W + 102-:((PHY_TAG_W + 102) >= 103 ? PHY_TAG_W + 0 : 104 - (PHY_TAG_W + 102))];
				alu_active_ctrl <= rob[iq[alu_select_idx][ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))-:((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) >= (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) ? ((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) - (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0))))) + 1 : ((33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) - (ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32))))) + 1)]][163 + (PHY_TAG_W + 102)-:((163 + (PHY_TAG_W + 102)) >= (33 + (PHY_TAG_W + 103)) ? ((163 + (PHY_TAG_W + 102)) - (33 + (PHY_TAG_W + 103))) + 1 : ((33 + (PHY_TAG_W + 103)) - (163 + (PHY_TAG_W + 102))) + 1)];
				alu_active_src1 <= iq[alu_select_idx][32 + (PHY_TAG_W + (PHY_TAG_W + 32))-:((32 + (PHY_TAG_W + (PHY_TAG_W + 32))) >= (PHY_TAG_W + (33 + (PHY_TAG_W + 0))) ? ((32 + (PHY_TAG_W + (PHY_TAG_W + 32))) - (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) + 1 : ((PHY_TAG_W + (33 + (PHY_TAG_W + 0))) - (32 + (PHY_TAG_W + (PHY_TAG_W + 32)))) + 1)];
				alu_active_src2 <= iq[alu_select_idx][PHY_TAG_W + 31-:((PHY_TAG_W + 31) >= (PHY_TAG_W + 0) ? ((PHY_TAG_W + 31) - (PHY_TAG_W + 0)) + 1 : ((PHY_TAG_W + 0) - (PHY_TAG_W + 31)) + 1)];
			end
			if (alu_wb_valid) begin
				alu_active <= 1'b0;
				if (alu_active_ctrl[6])
					rob[alu_wb_rob_tag][33 + (PHY_TAG_W + 102)-:((33 + (PHY_TAG_W + 102)) >= (1 + (PHY_TAG_W + 103)) ? ((33 + (PHY_TAG_W + 102)) - (1 + (PHY_TAG_W + 103))) + 1 : ((1 + (PHY_TAG_W + 103)) - (33 + (PHY_TAG_W + 102))) + 1)] <= alu_active_src2;
				else if (alu_active_ctrl[31])
					rob[alu_wb_rob_tag][33 + (PHY_TAG_W + 102)-:((33 + (PHY_TAG_W + 102)) >= (1 + (PHY_TAG_W + 103)) ? ((33 + (PHY_TAG_W + 102)) - (1 + (PHY_TAG_W + 103))) + 1 : ((1 + (PHY_TAG_W + 103)) - (33 + (PHY_TAG_W + 102))) + 1)] <= alu_active_src1;
				rob[alu_wb_rob_tag][102-:32] <= alu_wb_value;
				rob[alu_wb_rob_tag][70] <= branch_exec(alu_active_ctrl[68-:2], alu_active_ctrl[77-:3], alu_active_src1, alu_active_src2);
				rob[alu_wb_rob_tag][69-:32] <= alu_execute_data;
				rob[alu_wb_rob_tag][196 + (PHY_TAG_W + 102)] <= alu_active_ctrl[7] || alu_active_ctrl[6];
				if (!alu_active_ctrl[7] && !alu_active_ctrl[6])
					rob[alu_wb_rob_tag][197 + (PHY_TAG_W + 102)] <= 1'b1;
			end
			if (md_select_valid && !md_active) begin
				iq[md_select_idx][1 + (ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32))))] <= 1'b0;
				md_active <= 1'b1;
				md_active_rob_tag <= iq[md_select_idx][ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))-:((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) >= (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) ? ((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) - (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0))))) + 1 : ((33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) - (ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32))))) + 1)];
				md_active_dest_valid <= rob[iq[md_select_idx][ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))-:((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) >= (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) ? ((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) - (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0))))) + 1 : ((33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) - (ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32))))) + 1)]][1 + (PHY_TAG_W + 102)];
				md_active_dest_phys <= rob[iq[md_select_idx][ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))-:((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) >= (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) ? ((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) - (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0))))) + 1 : ((33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) - (ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32))))) + 1)]][PHY_TAG_W + 102-:((PHY_TAG_W + 102) >= 103 ? PHY_TAG_W + 0 : 104 - (PHY_TAG_W + 102))];
				md_active_ctrl <= rob[iq[md_select_idx][ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))-:((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) >= (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) ? ((ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32)))) - (33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0))))) + 1 : ((33 + (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) - (ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32))))) + 1)]][163 + (PHY_TAG_W + 102)-:((163 + (PHY_TAG_W + 102)) >= (33 + (PHY_TAG_W + 103)) ? ((163 + (PHY_TAG_W + 102)) - (33 + (PHY_TAG_W + 103))) + 1 : ((33 + (PHY_TAG_W + 103)) - (163 + (PHY_TAG_W + 102))) + 1)];
				md_active_src1 <= iq[md_select_idx][32 + (PHY_TAG_W + (PHY_TAG_W + 32))-:((32 + (PHY_TAG_W + (PHY_TAG_W + 32))) >= (PHY_TAG_W + (33 + (PHY_TAG_W + 0))) ? ((32 + (PHY_TAG_W + (PHY_TAG_W + 32))) - (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) + 1 : ((PHY_TAG_W + (33 + (PHY_TAG_W + 0))) - (32 + (PHY_TAG_W + (PHY_TAG_W + 32)))) + 1)];
				md_active_src2 <= iq[md_select_idx][PHY_TAG_W + 31-:((PHY_TAG_W + 31) >= (PHY_TAG_W + 0) ? ((PHY_TAG_W + 31) - (PHY_TAG_W + 0)) + 1 : ((PHY_TAG_W + 0) - (PHY_TAG_W + 31)) + 1)];
			end
			if (md_wb_valid) begin
				rob[md_active_rob_tag][102-:32] <= md_execute_data;
				rob[md_active_rob_tag][197 + (PHY_TAG_W + 102)] <= 1'b1;
				md_active <= 1'b0;
			end
			if (load_wb_valid) begin
				rob[rob_head][102-:32] <= load_wb_value;
				rob[rob_head][197 + (PHY_TAG_W + 102)] <= 1'b1;
			end
			if ((store_done && store_valid) && !d_pf)
				rob[rob_head][197 + (PHY_TAG_W + 102)] <= 1'b1;
			for (i = 0; i < IQ_DEPTH; i = i + 1)
				begin
					if (iq[i][1 + (ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32))))] && !iq[i][33 + (PHY_TAG_W + (PHY_TAG_W + 32))]) begin
						if ((alu_wb_valid && alu_wb_has_dest) && (iq[i][PHY_TAG_W + (PHY_TAG_W + 32)-:((PHY_TAG_W + (PHY_TAG_W + 32)) >= (33 + (PHY_TAG_W + 0)) ? ((PHY_TAG_W + (PHY_TAG_W + 32)) - (33 + (PHY_TAG_W + 0))) + 1 : ((33 + (PHY_TAG_W + 0)) - (PHY_TAG_W + (PHY_TAG_W + 32))) + 1)] == alu_wb_phys_tag)) begin
							iq[i][33 + (PHY_TAG_W + (PHY_TAG_W + 32))] <= 1'b1;
							iq[i][32 + (PHY_TAG_W + (PHY_TAG_W + 32))-:((32 + (PHY_TAG_W + (PHY_TAG_W + 32))) >= (PHY_TAG_W + (33 + (PHY_TAG_W + 0))) ? ((32 + (PHY_TAG_W + (PHY_TAG_W + 32))) - (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) + 1 : ((PHY_TAG_W + (33 + (PHY_TAG_W + 0))) - (32 + (PHY_TAG_W + (PHY_TAG_W + 32)))) + 1)] <= alu_wb_value;
						end
						else if ((md_wb_valid && md_active_dest_valid) && (iq[i][PHY_TAG_W + (PHY_TAG_W + 32)-:((PHY_TAG_W + (PHY_TAG_W + 32)) >= (33 + (PHY_TAG_W + 0)) ? ((PHY_TAG_W + (PHY_TAG_W + 32)) - (33 + (PHY_TAG_W + 0))) + 1 : ((33 + (PHY_TAG_W + 0)) - (PHY_TAG_W + (PHY_TAG_W + 32))) + 1)] == md_active_dest_phys)) begin
							iq[i][33 + (PHY_TAG_W + (PHY_TAG_W + 32))] <= 1'b1;
							iq[i][32 + (PHY_TAG_W + (PHY_TAG_W + 32))-:((32 + (PHY_TAG_W + (PHY_TAG_W + 32))) >= (PHY_TAG_W + (33 + (PHY_TAG_W + 0))) ? ((32 + (PHY_TAG_W + (PHY_TAG_W + 32))) - (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) + 1 : ((PHY_TAG_W + (33 + (PHY_TAG_W + 0))) - (32 + (PHY_TAG_W + (PHY_TAG_W + 32)))) + 1)] <= md_execute_data;
						end
						else if ((load_wb_valid && rob[rob_head][1 + (PHY_TAG_W + 102)]) && (iq[i][PHY_TAG_W + (PHY_TAG_W + 32)-:((PHY_TAG_W + (PHY_TAG_W + 32)) >= (33 + (PHY_TAG_W + 0)) ? ((PHY_TAG_W + (PHY_TAG_W + 32)) - (33 + (PHY_TAG_W + 0))) + 1 : ((33 + (PHY_TAG_W + 0)) - (PHY_TAG_W + (PHY_TAG_W + 32))) + 1)] == rob[rob_head][PHY_TAG_W + 102-:((PHY_TAG_W + 102) >= 103 ? PHY_TAG_W + 0 : 104 - (PHY_TAG_W + 102))])) begin
							iq[i][33 + (PHY_TAG_W + (PHY_TAG_W + 32))] <= 1'b1;
							iq[i][32 + (PHY_TAG_W + (PHY_TAG_W + 32))-:((32 + (PHY_TAG_W + (PHY_TAG_W + 32))) >= (PHY_TAG_W + (33 + (PHY_TAG_W + 0))) ? ((32 + (PHY_TAG_W + (PHY_TAG_W + 32))) - (PHY_TAG_W + (33 + (PHY_TAG_W + 0)))) + 1 : ((PHY_TAG_W + (33 + (PHY_TAG_W + 0))) - (32 + (PHY_TAG_W + (PHY_TAG_W + 32)))) + 1)] <= load_wb_value;
						end
					end
					if (iq[i][1 + (ROB_TAG_W + (33 + (PHY_TAG_W + (PHY_TAG_W + 32))))] && !iq[i][PHY_TAG_W + 32]) begin
						if ((alu_wb_valid && alu_wb_has_dest) && (iq[i][PHY_TAG_W - 1-:PHY_TAG_W] == alu_wb_phys_tag)) begin
							iq[i][PHY_TAG_W + 32] <= 1'b1;
							iq[i][PHY_TAG_W + 31-:((PHY_TAG_W + 31) >= (PHY_TAG_W + 0) ? ((PHY_TAG_W + 31) - (PHY_TAG_W + 0)) + 1 : ((PHY_TAG_W + 0) - (PHY_TAG_W + 31)) + 1)] <= alu_wb_value;
						end
						else if ((md_wb_valid && md_active_dest_valid) && (iq[i][PHY_TAG_W - 1-:PHY_TAG_W] == md_active_dest_phys)) begin
							iq[i][PHY_TAG_W + 32] <= 1'b1;
							iq[i][PHY_TAG_W + 31-:((PHY_TAG_W + 31) >= (PHY_TAG_W + 0) ? ((PHY_TAG_W + 31) - (PHY_TAG_W + 0)) + 1 : ((PHY_TAG_W + 0) - (PHY_TAG_W + 31)) + 1)] <= md_execute_data;
						end
						else if ((load_wb_valid && rob[rob_head][1 + (PHY_TAG_W + 102)]) && (iq[i][PHY_TAG_W - 1-:PHY_TAG_W] == rob[rob_head][PHY_TAG_W + 102-:((PHY_TAG_W + 102) >= 103 ? PHY_TAG_W + 0 : 104 - (PHY_TAG_W + 102))])) begin
							iq[i][PHY_TAG_W + 32] <= 1'b1;
							iq[i][PHY_TAG_W + 31-:((PHY_TAG_W + 31) >= (PHY_TAG_W + 0) ? ((PHY_TAG_W + 31) - (PHY_TAG_W + 0)) + 1 : ((PHY_TAG_W + 0) - (PHY_TAG_W + 31)) + 1)] <= load_wb_value;
						end
					end
				end
		end
	PSC_PC u_PSC_PC(
		.clock(clock),
		.reset_n(reset_n),
		.cpu_stop(cpu_stop),
		.execute_task_done(commit_fire),
		.alu_data(rob[rob_head][69-:32]),
		.pc_sel2(commit_fire && rob[rob_head][70]),
		.decoder_ctrl(commit_ctrl),
		.cpu_trap(cpu_trap),
		.priv_mode(priv_mode),
		.d_pf(d_pf_event),
		.i_pf(i_pf_event),
		.trap_scause(trap_scause),
		.csr_state(csr_state),
		.pc(pc),
		.counter(counter)
	);
	initial _sv2v_0 = 0;
endmodule
module Fetch (
	clock,
	reset_n,
	fetch_enb,
	mode_sv32,
	fetch_address,
	mmu_valid,
	mmu_ready,
	vaddr,
	paddr,
	program_mem_burst_mode,
	program_mem_read_valid,
	program_mem_read_ready,
	program_mem_read_address,
	program_mem_read_data,
	program_mem_req_ready,
	fifo_read_valid,
	fifo_read_data,
	fifo_read_pc,
	done,
	busy,
	opcode
);
	parameter [0:0] BURST_MODE = 1'b0;
	input wire clock;
	input wire reset_n;
	input wire fetch_enb;
	input wire mode_sv32;
	input wire [31:0] fetch_address;
	output reg mmu_valid;
	input wire mmu_ready;
	output reg [31:0] vaddr;
	input wire [31:0] paddr;
	output wire program_mem_burst_mode;
	output reg program_mem_read_valid;
	input wire program_mem_read_ready;
	output reg [31:0] program_mem_read_address;
	input wire [31:0] program_mem_read_data;
	input wire program_mem_req_ready;
	output wire fifo_read_valid;
	output wire [31:0] fifo_read_data;
	output wire [31:0] fifo_read_pc;
	output reg done;
	output reg busy;
	output reg [31:0] opcode;
	reg [2:0] burst_count;
	assign fifo_read_pc = (BURST_MODE ? {vaddr[31:4], 4'b0000} + {28'd0, burst_count[1:0], 2'b00} : vaddr);
	reg [3:0] state;
	reg [1:0] burst_start_word;
	assign program_mem_burst_mode = BURST_MODE;
	assign fifo_read_valid = program_mem_read_ready && (!BURST_MODE || (burst_count[1:0] >= burst_start_word));
	assign fifo_read_data = program_mem_read_data;
	always @(posedge clock or negedge reset_n)
		if (!reset_n) begin
			state <= 4'd0;
			vaddr <= 32'h00000000;
			mmu_valid <= 1'b0;
			program_mem_read_valid <= 1'b0;
			program_mem_read_address <= 32'h00000000;
			done <= 1'b0;
			busy <= 1'b0;
			opcode <= 32'd0;
			burst_count <= 3'd0;
			burst_start_word <= 2'd0;
		end
		else begin
			mmu_valid <= 1'b0;
			program_mem_read_valid <= 1'b0;
			done <= 1'b0;
			(* full_case, parallel_case *)
			case (state)
				4'd0:
					if (fetch_enb) begin
						vaddr <= fetch_address;
						busy <= 1'b1;
						burst_count <= 3'd0;
						burst_start_word <= fetch_address[3:2];
						if (mode_sv32)
							state <= 4'd1;
						else
							state <= 4'd4;
					end
				4'd1:
					if (program_mem_req_ready) begin
						mmu_valid <= 1'b1;
						program_mem_read_address <= paddr;
						state <= 4'd2;
					end
				4'd2:
					if (mmu_ready) begin
						burst_count <= 3'd0;
						burst_start_word <= paddr[3:2];
						state <= 4'd4;
					end
				4'd4:
					if (program_mem_req_ready) begin
						burst_count <= 3'd0;
						if (BURST_MODE) begin
							program_mem_read_valid <= 1'b1;
							program_mem_read_address <= {vaddr[31:4], 4'b0000};
							state <= 4'd3;
						end
						else begin
							program_mem_read_valid <= 1'b1;
							program_mem_read_address <= vaddr;
							state <= 4'd3;
						end
					end
				4'd3:
					if (program_mem_read_ready) begin
						if (!BURST_MODE)
							opcode <= program_mem_read_data;
						else if (burst_count[1:0] == burst_start_word)
							opcode <= program_mem_read_data;
						if (BURST_MODE) begin
							if (burst_count == 3'd3) begin
								burst_count <= 3'd0;
								state <= 4'd5;
							end
							else
								burst_count <= burst_count + 3'd1;
						end
						else
							state <= 4'd5;
					end
				4'd5: begin
					busy <= 1'b0;
					done <= 1'b1;
					state <= 4'd0;
				end
				default: begin
					state <= 4'd0;
					mmu_valid <= 1'b0;
					program_mem_read_valid <= 1'b0;
					done <= 1'b0;
					busy <= 1'b0;
					burst_count <= 3'd0;
				end
			endcase
		end
endmodule
module Decorder (
	clock,
	reset_n,
	decode_enb,
	opcode,
	in_pc,
	current_priv,
	decode_done,
	decoder_ctrl
);
	reg _sv2v_0;
	input wire clock;
	input wire reset_n;
	input wire decode_enb;
	input wire [31:0] opcode;
	input wire [31:0] in_pc;
	input wire [1:0] current_priv;
	output reg decode_done;
	output reg [129:0] decoder_ctrl;
	localparam [1:0] PRIV_U = 2'b00;
	localparam [1:0] PRIV_S = 2'b01;
	localparam [1:0] PRIV_M = 2'b11;
	wire [4:0] r_addr1_w;
	wire [4:0] r_addr2_w;
	wire [4:0] w_addr_w;
	wire [31:0] imm_w;
	wire [4:0] alucon_w;
	wire [2:0] funct3_w;
	wire op1sel_w;
	wire op2sel_w;
	wire mem_rw_w;
	wire rf_wen_w;
	wire [1:0] wb_sel_w;
	wire [1:0] pc_sel_w;
	wire [6:0] op = opcode[6:0];
	localparam [6:0] RFORMAT = 7'b0110011;
	localparam [6:0] IFORMAT_ALU = 7'b0010011;
	localparam [6:0] IFORMAT_LOAD = 7'b0000011;
	localparam [6:0] SFORMAT = 7'b0100011;
	localparam [6:0] SBFORMAT = 7'b1100011;
	localparam [6:0] UFORMAT_LUI = 7'b0110111;
	localparam [6:0] UFORMAT_AUIPC = 7'b0010111;
	localparam [6:0] UJFORMAT = 7'b1101111;
	localparam [6:0] IFORMAT_JALR = 7'b1100111;
	localparam [6:0] ECALLEBREAK = 7'b1110011;
	localparam [6:0] FENCE = 7'b0001111;
	localparam [6:0] MULDIV = 7'b0110011;
	wire is_system = op == ECALLEBREAK;
	wire [2:0] sys_f3 = opcode[14:12];
	wire is_sfence_vma_w = (is_system && (sys_f3 == 3'b000)) && (opcode[31:25] == 7'b0001001);
	wire is_trap_like = (is_system && (sys_f3 == 3'b000)) && !is_sfence_vma_w;
	wire is_ecall_w = (is_system && (sys_f3 == 3'b000)) && (opcode[31:20] == 12'h000);
	wire is_sret_w = (is_system && (sys_f3 == 3'b000)) && (opcode[31:20] == 12'h102);
	wire is_mret_w = (is_system && (sys_f3 == 3'b000)) && (opcode[31:20] == 12'h302);
	wire raise_illegal_instruction_sw = is_sret_w && (current_priv != PRIV_S);
	wire raise_illegal_instruction_mw = is_mret_w && (current_priv != PRIV_M);
	wire is_fence_family = opcode[6:0] == FENCE;
	wire is_fence_w = is_fence_family && (opcode[14:12] == 3'b000);
	wire is_fence_i_w = ((is_fence_family && (opcode[14:12] == 3'b001)) && (opcode[19:15] == 5'b00000)) && (opcode[11:7] == 5'b00000);
	wire is_csrrw = is_system && (sys_f3 == 3'b001);
	wire is_csrrs = is_system && (sys_f3 == 3'b010);
	wire is_csrrc = is_system && (sys_f3 == 3'b011);
	wire is_csrrwi = is_system && (sys_f3 == 3'b101);
	wire is_csrrsi = is_system && (sys_f3 == 3'b110);
	wire is_csrrci = is_system && (sys_f3 == 3'b111);
	wire is_csri = (is_csrrwi | is_csrrsi) | is_csrrci;
	wire is_csr_any = ((is_csrrw | is_csrrs) | is_csrrc) | is_csri;
	wire [1:0] csr_cmd_norm = (is_csrrw | is_csrrwi ? 2'b00 : (is_csrrs | is_csrrsi ? 2'b01 : (is_csrrc | is_csrrci ? 2'b10 : 2'b00)));
	wire [11:0] csr_addr_w = opcode[31:20];
	assign r_addr1_w = (op == UFORMAT_LUI ? 5'b00000 : (is_csri ? 5'b00000 : opcode[19:15]));
	assign r_addr2_w = opcode[24:20];
	assign w_addr_w = opcode[11:7];
	wire [31:0] imm_i;
	wire [31:0] imm_s;
	wire [31:0] imm_b;
	wire [31:0] imm_u;
	wire [31:0] imm_j;
	assign imm_i = {{20 {opcode[31]}}, opcode[31:20]};
	assign imm_s = {{20 {opcode[31]}}, opcode[31:25], opcode[11:7]};
	assign imm_b = {{19 {opcode[31]}}, opcode[31], opcode[7], opcode[30:25], opcode[11:8], 1'b0};
	assign imm_u = {opcode[31:12], 12'b000000000000};
	assign imm_j = {{11 {opcode[31]}}, opcode[31], opcode[19:12], opcode[20], opcode[30:21], 1'b0};
	assign imm_w = (op == UJFORMAT ? imm_j : (op == SBFORMAT ? imm_b : (op == SFORMAT ? imm_s : (((op == IFORMAT_ALU) || (op == IFORMAT_LOAD)) || (op == IFORMAT_JALR) ? imm_i : ((op == UFORMAT_LUI) || (op == UFORMAT_AUIPC) ? imm_u : 32'b00000000000000000000000000000000)))));
	wire is_mul;
	wire is_mulh;
	wire is_mulhsu;
	wire is_mulhu;
	wire is_div;
	wire is_divu;
	wire is_rem;
	wire is_remu;
	assign is_mul = ((op == RFORMAT) && (opcode[31:25] == 7'b0000001)) && (opcode[14:12] == 3'b000);
	assign is_mulh = ((op == RFORMAT) && (opcode[31:25] == 7'b0000001)) && (opcode[14:12] == 3'b001);
	assign is_mulhsu = ((op == RFORMAT) && (opcode[31:25] == 7'b0000001)) && (opcode[14:12] == 3'b010);
	assign is_mulhu = ((op == RFORMAT) && (opcode[31:25] == 7'b0000001)) && (opcode[14:12] == 3'b011);
	assign is_div = ((op == RFORMAT) && (opcode[31:25] == 7'b0000001)) && (opcode[14:12] == 3'b100);
	assign is_divu = ((op == RFORMAT) && (opcode[31:25] == 7'b0000001)) && (opcode[14:12] == 3'b101);
	assign is_rem = ((op == RFORMAT) && (opcode[31:25] == 7'b0000001)) && (opcode[14:12] == 3'b110);
	assign is_remu = ((op == RFORMAT) && (opcode[31:25] == 7'b0000001)) && (opcode[14:12] == 3'b111);
	wire raise_illegal_instruction_alu = 0;
	assign alucon_w = (is_mul ? 5'b11000 : (is_mulh ? 5'b11001 : (is_mulhsu ? 5'b11010 : (is_mulhu ? 5'b11011 : (is_div ? 5'b11100 : (is_divu ? 5'b11101 : (is_rem ? 5'b11110 : (is_remu ? 5'b11111 : (op == RFORMAT ? {opcode[30], opcode[25], opcode[14:12]} : ((op == IFORMAT_ALU) && (opcode[14:12] == 3'b101) ? {opcode[30], opcode[25], opcode[14:12]} : (op == IFORMAT_ALU ? {2'b00, opcode[14:12]} : 5'b00000)))))))))));
	assign funct3_w = opcode[14:12];
	assign op1sel_w = (((op == SBFORMAT) || (op == UFORMAT_AUIPC)) || (op == UJFORMAT) ? 1'b1 : 1'b0);
	assign op2sel_w = ((op == RFORMAT) || (op == MULDIV) ? 1'b0 : 1'b1);
	assign mem_rw_w = (op == SFORMAT ? 1'b1 : 1'b0);
	assign wb_sel_w = (op == IFORMAT_LOAD ? 2'b01 : ((op == UJFORMAT) || (op == IFORMAT_JALR) ? 2'b10 : (is_csr_any ? 2'b11 : 2'b00)));
	wire rf_wen_noncsr = ((((((((op == RFORMAT) && ({opcode[31], opcode[29:25]} == 6'b000000)) || ((op == MULDIV) && (opcode[31:25] == 7'b0000001))) || ((op == IFORMAT_ALU) && (((((((({opcode[31:25], opcode[14:12]} == 10'b0000000001) || ({opcode[31], opcode[29:25], opcode[14:12]} == 9'b000000101)) || (opcode[14:12] == 3'b000)) || (opcode[14:12] == 3'b010)) || (opcode[14:12] == 3'b011)) || (opcode[14:12] == 3'b100)) || (opcode[14:12] == 3'b110)) || (opcode[14:12] == 3'b111)))) || (op == IFORMAT_LOAD)) || (op == UFORMAT_LUI)) || (op == UFORMAT_AUIPC)) || (op == UJFORMAT)) || (op == IFORMAT_JALR);
	assign rf_wen_w = (is_csr_any ? w_addr_w != 5'b00000 : rf_wen_noncsr);
	assign pc_sel_w = (op == SBFORMAT ? 2'b01 : (((op == UJFORMAT) || (op == IFORMAT_JALR)) || is_trap_like ? 2'b10 : 2'b00));
	wire csr_wr_w = is_csr_any;
	wire [1:0] csr_cmd_w = csr_cmd_norm;
	wire csr_use_imm_w = is_csri;
	wire [11:0] csr_addr_mux = csr_addr_w;
	wire [4:0] csr_zimm_w = opcode[19:15];
	wire is_load_w = op == IFORMAT_LOAD;
	wire is_store_w = op == SFORMAT;
	wire use_rs1_w = (((((((((op == RFORMAT) || (op == IFORMAT_ALU)) || (op == IFORMAT_LOAD)) || (op == SFORMAT)) || (op == SBFORMAT)) || (op == IFORMAT_JALR)) || is_csrrw) || is_csrrs) || is_csrrc) || is_sfence_vma_w;
	wire use_rs2_w = (((op == RFORMAT) || (op == SFORMAT)) || (op == SBFORMAT)) || is_sfence_vma_w;
	wire is_R_type_w = op == RFORMAT;
	wire is_op_imm_w = op == IFORMAT_ALU;
	wire is_nop;
	assign is_nop = opcode == 32'h00000013;
	wire is_mul_div_w = ((((((is_mul | is_mulh) | is_mulhsu) | is_mulhu) | is_div) | is_divu) | is_rem) | is_remu;
	wire pipeline_type_w = is_R_type_w || is_op_imm_w;
	reg [129:0] decoder_ctrl_next;
	always @(*) begin
		decoder_ctrl_next[129-:5] = r_addr1_w;
		decoder_ctrl_next[124-:5] = r_addr2_w;
		decoder_ctrl_next[119-:5] = w_addr_w;
		decoder_ctrl_next[114-:32] = imm_w;
		decoder_ctrl_next[82-:5] = alucon_w;
		decoder_ctrl_next[77-:3] = funct3_w;
		decoder_ctrl_next[74] = op1sel_w;
		decoder_ctrl_next[73] = op2sel_w;
		decoder_ctrl_next[72] = mem_rw_w;
		decoder_ctrl_next[71] = rf_wen_w;
		decoder_ctrl_next[70-:2] = wb_sel_w;
		decoder_ctrl_next[68-:2] = pc_sel_w;
		decoder_ctrl_next[34] = is_fence_w;
		decoder_ctrl_next[33] = is_fence_i_w;
		decoder_ctrl_next[32] = is_sfence_vma_w;
		decoder_ctrl_next[31] = csr_wr_w;
		decoder_ctrl_next[30-:2] = csr_cmd_w;
		decoder_ctrl_next[28] = csr_use_imm_w;
		decoder_ctrl_next[27-:12] = csr_addr_mux;
		decoder_ctrl_next[15-:5] = csr_zimm_w;
		decoder_ctrl_next[10] = is_sret_w;
		decoder_ctrl_next[9] = is_mret_w;
		decoder_ctrl_next[8] = is_ecall_w;
		decoder_ctrl_next[7] = is_load_w;
		decoder_ctrl_next[6] = is_store_w;
		decoder_ctrl_next[5] = use_rs1_w;
		decoder_ctrl_next[4] = use_rs2_w;
		decoder_ctrl_next[3] = is_R_type_w;
		decoder_ctrl_next[2] = is_op_imm_w;
		decoder_ctrl_next[1] = pipeline_type_w;
		decoder_ctrl_next[66-:32] = in_pc;
		decoder_ctrl_next[0] = (raise_illegal_instruction_sw | raise_illegal_instruction_mw) | raise_illegal_instruction_alu;
	end
	always @(*) begin
		if (_sv2v_0)
			;
		decoder_ctrl = decoder_ctrl_next;
		decode_done = decode_enb;
	end
	initial _sv2v_0 = 0;
endmodule
module Execute (
	clock,
	reset_n,
	execute_enb,
	reg_data_addr1,
	reg_data_addr2,
	decoder_ctrl,
	alu_data,
	r_data1,
	r_data2,
	out_pc,
	busy,
	done
);
	reg _sv2v_0;
	parameter [0:0] ENABLE_MUL = 1'b1;
	parameter [0:0] ENABLE_DIV = 1'b1;
	input wire clock;
	input wire reset_n;
	input wire execute_enb;
	input wire [31:0] reg_data_addr1;
	input wire [31:0] reg_data_addr2;
	input wire [129:0] decoder_ctrl;
	output reg [31:0] alu_data;
	output reg [31:0] r_data1;
	output reg [31:0] r_data2;
	output reg [31:0] out_pc;
	output reg busy;
	output reg done;
	reg [1:0] state;
	wire [31:0] operand_1;
	wire [31:0] operand_2;
	reg [31:0] multi_result;
	wire is_div_op;
	wire is_mul_op;
	wire div_start;
	wire div_busy;
	wire div_done;
	wire div_signed;
	wire mul_start;
	wire mul_busy;
	wire mul_done;
	wire [31:0] div_quotient;
	wire [31:0] div_remainder;
	wire [31:0] mul_out;
	assign operand_1 = (decoder_ctrl[74] ? decoder_ctrl[66-:32] : reg_data_addr1);
	assign operand_2 = (decoder_ctrl[73] ? decoder_ctrl[114-:32] : reg_data_addr2);
	assign is_div_op = ENABLE_DIV && (decoder_ctrl[82:80] == 3'b111);
	assign is_mul_op = ENABLE_MUL && (decoder_ctrl[82:80] == 3'b110);
	assign div_signed = (decoder_ctrl[82-:5] == 5'b11100) || (decoder_ctrl[82-:5] == 5'b11110);
	assign div_start = (execute_enb && (state == 2'd0)) && is_div_op;
	assign mul_start = (execute_enb && (state == 2'd0)) && is_mul_op;
	Execute_Divider u_divider(
		.clk(clock),
		.reset_n(reset_n),
		.start(div_start),
		.signed_mode(div_signed),
		.dividend(operand_1),
		.divisor(operand_2),
		.busy(div_busy),
		.done(div_done),
		.quotient(div_quotient),
		.remainder(div_remainder)
	);
	Execute_Mul u_multiplier(
		.clk(clock),
		.reset_n(reset_n),
		.start(mul_start),
		.alucon(decoder_ctrl[79:78]),
		.data_1(operand_1),
		.data_2(operand_2),
		.busy(mul_busy),
		.done(mul_done),
		.mul_out(mul_out)
	);
	function automatic [31:0] alu_exec;
		input reg [4:0] control;
		input reg [31:0] data1;
		input reg [31:0] data2;
		case (control)
			5'b00000: alu_exec = data1 + data2;
			5'b10000: alu_exec = data1 - data2;
			5'b00001: alu_exec = data1 << data2[4:0];
			5'b00010: alu_exec = {31'd0, $signed(data1) < $signed(data2)};
			5'b00011: alu_exec = {31'd0, data1 < data2};
			5'b00100: alu_exec = data1 ^ data2;
			5'b00101: alu_exec = data1 >> data2[4:0];
			5'b10101: alu_exec = $signed(data1) >>> data2[4:0];
			5'b00110: alu_exec = data1 | data2;
			5'b00111: alu_exec = data1 & data2;
			default: alu_exec = 32'd0;
		endcase
	endfunction
	always @(*) begin
		if (_sv2v_0)
			;
		r_data1 = reg_data_addr1;
		r_data2 = reg_data_addr2;
		out_pc = decoder_ctrl[66-:32];
		busy = state != 2'd0;
		done = 1'b0;
		alu_data = alu_exec(decoder_ctrl[82-:5], operand_1, operand_2);
		if (state == 2'd3) begin
			alu_data = multi_result;
			done = execute_enb;
		end
		else if ((((state == 2'd0) && execute_enb) && !is_mul_op) && !is_div_op)
			done = 1'b1;
	end
	always @(posedge clock or negedge reset_n)
		if (!reset_n) begin
			state <= 2'd0;
			multi_result <= 32'd0;
		end
		else
			case (state)
				2'd0:
					if (div_start)
						state <= 2'd1;
					else if (mul_start)
						state <= 2'd2;
				2'd1:
					if (div_done) begin
						multi_result <= (decoder_ctrl[79] ? div_remainder : div_quotient);
						state <= 2'd3;
					end
				2'd2:
					if (mul_done) begin
						multi_result <= mul_out;
						state <= 2'd3;
					end
				2'd3:
					if (execute_enb)
						state <= 2'd0;
				default: state <= 2'd0;
			endcase
	initial _sv2v_0 = 0;
endmodule
module Execute_Divider (
	clk,
	reset_n,
	start,
	signed_mode,
	dividend,
	divisor,
	busy,
	done,
	quotient,
	remainder
);
	input wire clk;
	input wire reset_n;
	input wire start;
	input wire signed_mode;
	input wire [31:0] dividend;
	input wire [31:0] divisor;
	output wire busy;
	output wire done;
	output reg [31:0] quotient;
	output reg [31:0] remainder;
	reg [2:0] state;
	reg [31:0] dividend_abs;
	reg [31:0] divisor_abs;
	reg [31:0] quotient_reg;
	reg [32:0] remainder_reg;
	reg [5:0] count;
	reg quotient_neg;
	reg remainder_neg;
	wire dividend_is_neg;
	wire divisor_is_neg;
	wire [31:0] dividend_abs_w;
	wire [31:0] divisor_abs_w;
	wire quotient_neg_w;
	wire remainder_neg_w;
	wire [32:0] rem_shift_w;
	wire [32:0] rem_sub_w;
	wire rem_ge_div_w;
	assign busy = (state != 3'd0) && (state != 3'd4);
	assign done = state == 3'd4;
	assign dividend_is_neg = signed_mode && dividend[31];
	assign divisor_is_neg = signed_mode && divisor[31];
	assign dividend_abs_w = (dividend_is_neg ? ~dividend + 1'b1 : dividend);
	assign divisor_abs_w = (divisor_is_neg ? ~divisor + 1'b1 : divisor);
	assign quotient_neg_w = signed_mode && (dividend[31] ^ divisor[31]);
	assign remainder_neg_w = signed_mode && dividend[31];
	assign rem_shift_w = {remainder_reg[31:0], dividend_abs[31]};
	assign rem_ge_div_w = rem_shift_w >= {1'b0, divisor_abs};
	assign rem_sub_w = rem_shift_w - {1'b0, divisor_abs};
	always @(posedge clk or negedge reset_n)
		if (!reset_n) begin
			state <= 3'd0;
			dividend_abs <= 1'sb0;
			divisor_abs <= 1'sb0;
			quotient_reg <= 1'sb0;
			remainder_reg <= 1'sb0;
			count <= 1'sb0;
			quotient_neg <= 1'b0;
			remainder_neg <= 1'b0;
			quotient <= 1'sb0;
			remainder <= 1'sb0;
		end
		else
			case (state)
				3'd0:
					if (start)
						state <= 3'd1;
				3'd1: begin
					dividend_abs <= dividend_abs_w;
					divisor_abs <= divisor_abs_w;
					quotient_reg <= 1'sb0;
					remainder_reg <= 1'sb0;
					count <= 6'd32;
					quotient_neg <= quotient_neg_w;
					remainder_neg <= remainder_neg_w;
					quotient <= 1'sb0;
					remainder <= 1'sb0;
					state <= 3'd2;
				end
				3'd2:
					if (divisor_abs == 0) begin
						quotient_reg <= 32'hffffffff;
						remainder_reg <= {1'b0, dividend_abs};
						state <= 3'd3;
					end
					else begin
						dividend_abs <= {dividend_abs[30:0], 1'b0};
						remainder_reg <= (rem_ge_div_w ? rem_sub_w : rem_shift_w);
						quotient_reg <= {quotient_reg[30:0], rem_ge_div_w};
						count <= count - 1'b1;
						if (count == 1)
							state <= 3'd3;
					end
				3'd3: begin
					if (divisor_abs == 0) begin
						quotient <= 32'hffffffff;
						remainder <= dividend;
					end
					else begin
						quotient <= (quotient_neg ? ~quotient_reg + 1'b1 : quotient_reg);
						remainder <= (remainder_neg ? ~remainder_reg[31:0] + 1'b1 : remainder_reg[31:0]);
					end
					state <= 3'd4;
				end
				3'd4:
					if (!start)
						state <= 3'd0;
				default: state <= 3'd0;
			endcase
endmodule
module Execute_Mul (
	clk,
	reset_n,
	start,
	alucon,
	data_1,
	data_2,
	busy,
	done,
	mul_out
);
	reg _sv2v_0;
	input wire clk;
	input wire reset_n;
	input wire start;
	input wire [1:0] alucon;
	input wire [31:0] data_1;
	input wire [31:0] data_2;
	output wire busy;
	output reg done;
	output reg [31:0] mul_out;
	reg [1:0] state;
	reg signed [63:0] mul_ss;
	reg signed [64:0] mul_su;
	reg [63:0] mul_uu;
	assign busy = state != 2'd0;
	always @(*) begin
		if (_sv2v_0)
			;
		mul_ss = $signed(data_1) * $signed(data_2);
		mul_su = $signed({data_1[31], data_1}) * $signed({1'b0, data_2});
		mul_uu = data_1 * data_2;
	end
	always @(posedge clk or negedge reset_n)
		if (!reset_n) begin
			state <= 2'd0;
			done <= 1'b0;
			mul_out <= 32'd0;
		end
		else begin
			done <= 1'b0;
			(* full_case, parallel_case *)
			case (state)
				2'd0:
					if (start)
						state <= 2'd1;
				2'd1: begin
					(* full_case, parallel_case *)
					case (alucon)
						2'b00: mul_out <= mul_uu[31:0];
						2'b01: mul_out <= mul_ss[63:32];
						2'b10: mul_out <= mul_su[63:32];
						2'b11: mul_out <= mul_uu[63:32];
						default: mul_out <= 32'd0;
					endcase
					done <= 1'b1;
					state <= 2'd0;
				end
				default: state <= 2'd0;
			endcase
		end
	initial _sv2v_0 = 0;
endmodule
module Branch (
	clock,
	reset_n,
	branch_enb,
	in_vaddr,
	r_data1,
	r_data2,
	decoder_ctrl,
	mmu_valid,
	vaddr,
	mmu_ready,
	access_fault,
	d_paddr,
	data_mem_read_address,
	data_mem_read_valid,
	data_mem_req_ready,
	data_mem_read_ready,
	pc_sel2,
	busy,
	branch_done
);
	input wire clock;
	input wire reset_n;
	input wire branch_enb;
	input wire [31:0] in_vaddr;
	input wire [31:0] r_data1;
	input wire [31:0] r_data2;
	input wire [129:0] decoder_ctrl;
	output reg mmu_valid;
	output reg [31:0] vaddr;
	input wire mmu_ready;
	input wire access_fault;
	input wire [31:0] d_paddr;
	output reg [31:0] data_mem_read_address;
	output reg data_mem_read_valid;
	input wire data_mem_req_ready;
	input wire data_mem_read_ready;
	output reg pc_sel2;
	output reg busy;
	output reg branch_done;
	reg [3:0] state;
	function automatic branch_exec;
		input reg [2:0] branch_op;
		input reg [31:0] data1;
		input reg [31:0] data2;
		input reg [1:0] pc_sel;
		(* full_case, parallel_case *)
		case (pc_sel)
			2'b00: branch_exec = 1'b0;
			2'b01:
				(* full_case, parallel_case *)
				case (branch_op)
					3'b000: branch_exec = data1 == data2;
					3'b001: branch_exec = data1 != data2;
					3'b100: branch_exec = $signed(data1) < $signed(data2);
					3'b101: branch_exec = $signed(data1) >= $signed(data2);
					3'b110: branch_exec = data1 < data2;
					3'b111: branch_exec = data1 >= data2;
					default: branch_exec = 1'b0;
				endcase
			2'b10: branch_exec = 1'b1;
			default: branch_exec = 1'b0;
		endcase
	endfunction
	always @(posedge clock or negedge reset_n)
		if (!reset_n) begin
			state <= 4'd0;
			pc_sel2 <= 1'b0;
			mmu_valid <= 1'b0;
			vaddr <= 32'd0;
			data_mem_read_valid <= 1'b0;
			data_mem_read_address <= 32'd0;
			busy <= 1'b0;
			branch_done <= 1'b0;
		end
		else begin
			mmu_valid <= 1'b0;
			data_mem_read_valid <= 1'b0;
			branch_done <= 1'b0;
			(* full_case, parallel_case *)
			case (state)
				4'd0: begin
					busy <= 1'b0;
					pc_sel2 <= branch_exec(decoder_ctrl[77-:3], r_data1, r_data2, decoder_ctrl[68-:2]);
					if (branch_enb && !busy) begin
						busy <= 1'b1;
						if (decoder_ctrl[7])
							state <= 4'd1;
						else
							state <= 4'd5;
					end
				end
				4'd1: begin
					mmu_valid <= 1'b1;
					vaddr <= in_vaddr;
					state <= 4'd2;
				end
				4'd2:
					if (mmu_ready) begin
						if (access_fault)
							state <= 4'd5;
						else begin
							data_mem_read_address <= d_paddr;
							state <= 4'd3;
						end
					end
				4'd3:
					if (data_mem_req_ready) begin
						data_mem_read_valid <= 1'b1;
						state <= 4'd4;
					end
				4'd4:
					if (data_mem_read_ready)
						state <= 4'd5;
				4'd5: begin
					branch_done <= 1'b1;
					state <= 4'd0;
				end
				default: begin
					state <= 4'd0;
					mmu_valid <= 1'b0;
					data_mem_read_valid <= 1'b0;
					data_mem_read_address <= 32'd0;
					branch_done <= 1'b0;
				end
			endcase
		end
endmodule
module MemoryStore (
	clock,
	reset_n,
	store_enb,
	mode_sv32,
	alu_data,
	mem_val,
	mem_read_data,
	r_data2,
	in_pc,
	counter,
	ld_low2,
	csr_rdata,
	decoder_ctrl,
	mmu_valid,
	vaddr,
	mmu_ready,
	access_fault,
	d_paddr,
	data_mem_write_address,
	data_mem_write_valid,
	data_mem_write_data,
	data_mem_write_ready,
	data_mem_req_ready,
	uart,
	w_data,
	busy,
	store_done
);
	parameter [31:0] UART_MMIO_ADDR = 32'h0000fff0;
	parameter [31:0] UART_MMIO_FLAG = 32'h0000fff4;
	parameter [31:0] COUNTER_MMIO_ADDR = 32'h0000fff8;
	input wire clock;
	input wire reset_n;
	input wire store_enb;
	input wire mode_sv32;
	input wire [31:0] alu_data;
	input wire [2:0] mem_val;
	input wire [31:0] mem_read_data;
	input wire [31:0] r_data2;
	input wire [31:0] in_pc;
	input wire [31:0] counter;
	input wire [1:0] ld_low2;
	input wire [31:0] csr_rdata;
	input wire [129:0] decoder_ctrl;
	output reg mmu_valid;
	output wire [31:0] vaddr;
	input wire mmu_ready;
	input wire access_fault;
	input wire [31:0] d_paddr;
	output reg [31:0] data_mem_write_address;
	output reg data_mem_write_valid;
	output reg [31:0] data_mem_write_data;
	input wire data_mem_write_ready;
	input wire data_mem_req_ready;
	output reg [8:0] uart;
	output reg [31:0] w_data;
	output reg busy;
	output reg store_done;
	reg [2:0] state;
	wire [31:0] mem_addr;
	wire [31:0] mem_data;
	wire [31:0] ld_result;
	wire [7:0] rbyte;
	wire [15:0] rhword;
	wire is_lb;
	wire is_lh;
	wire is_lw;
	wire is_lbu;
	wire is_lhu;
	wire is_mmio_counter;
	wire is_mmio_uart_flag;
	assign vaddr = alu_data;
	assign mem_addr = alu_data;
	assign rbyte = (ld_low2 == 0 ? mem_read_data[7:0] : (ld_low2 == 1 ? mem_read_data[15:8] : (ld_low2 == 2 ? mem_read_data[23:16] : mem_read_data[31:24])));
	assign rhword = (ld_low2[1] ? mem_read_data[31:16] : mem_read_data[15:0]);
	assign is_lb = mem_val == 3'b000;
	assign is_lh = mem_val == 3'b001;
	assign is_lw = mem_val == 3'b010;
	assign is_lbu = mem_val == 3'b100;
	assign is_lhu = mem_val == 3'b101;
	assign ld_result = (is_lb ? {{24 {rbyte[7]}}, rbyte} : (is_lbu ? {24'd0, rbyte} : (is_lh ? {{16 {rhword[15]}}, rhword} : (is_lhu ? {16'd0, rhword} : mem_read_data))));
	assign is_mmio_counter = is_lw && (mem_addr == COUNTER_MMIO_ADDR);
	assign is_mmio_uart_flag = !mem_val[1:0] && (mem_addr == UART_MMIO_FLAG);
	assign mem_data = (decoder_ctrl[72] ? 32'd0 : (is_mmio_counter ? counter : (is_mmio_uart_flag ? 32'd1 : ld_result)));
	wire [31:0] w_data_w;
	assign w_data_w = (decoder_ctrl[70-:2] == 2'b00 ? alu_data : (decoder_ctrl[70-:2] == 2'b01 ? mem_data : (decoder_ctrl[70-:2] == 2'b10 ? in_pc + 32'd4 : csr_rdata)));
	always @(posedge clock or negedge reset_n)
		if (!reset_n) begin
			state <= 3'd0;
			mmu_valid <= 1'b0;
			data_mem_write_valid <= 1'b0;
			data_mem_write_data <= 32'd0;
			data_mem_write_address <= 32'd0;
			uart <= 9'd0;
			w_data <= 32'h00000000;
			busy <= 1'b0;
			store_done <= 1'b0;
		end
		else begin
			mmu_valid <= 1'b0;
			data_mem_write_valid <= 1'b0;
			store_done <= 1'b0;
			case (state)
				3'd0: begin
					busy <= 1'b0;
					if (store_enb && !busy) begin
						busy <= 1'b1;
						w_data <= w_data_w;
						if (decoder_ctrl[72])
							state <= 3'd1;
						else
							state <= 3'd5;
					end
				end
				3'd1:
					if (mode_sv32) begin
						mmu_valid <= 1'b1;
						state <= 3'd2;
					end
					else begin
						data_mem_write_address <= vaddr;
						state <= 3'd3;
					end
				3'd2:
					if (mmu_ready) begin
						if (access_fault)
							state <= 3'd5;
						else begin
							data_mem_write_address <= d_paddr;
							state <= 3'd3;
						end
					end
				3'd3:
					if (data_mem_req_ready) begin
						data_mem_write_valid <= 1'b1;
						data_mem_write_data <= r_data2;
						uart <= (mem_addr == UART_MMIO_ADDR ? {1'b1, r_data2[7:0]} : 9'd0);
						state <= 3'd4;
					end
				3'd4:
					if (data_mem_write_ready)
						state <= 3'd5;
				3'd5: begin
					store_done <= 1'b1;
					state <= 3'd0;
				end
				default: state <= 3'd0;
			endcase
		end
endmodule
module PSC_Register (
	clock,
	reset_n,
	cpu_stop,
	read_addr1,
	read_addr2,
	read_data1,
	read_data2,
	read_ready1,
	read_ready2,
	allocate_valid,
	allocate_addr,
	release_valid,
	release_addr,
	wb0_valid,
	wb0_addr,
	wb0_data,
	wb1_valid,
	wb1_addr,
	wb1_data,
	wb2_valid,
	wb2_addr,
	wb2_data,
	wb3_valid,
	wb3_addr,
	wb3_data
);
	reg _sv2v_0;
	parameter signed [31:0] ENTRIES = 64;
	parameter signed [31:0] TAG_W = $clog2(ENTRIES);
	input wire clock;
	input wire reset_n;
	input wire cpu_stop;
	input wire [TAG_W - 1:0] read_addr1;
	input wire [TAG_W - 1:0] read_addr2;
	output reg [31:0] read_data1;
	output reg [31:0] read_data2;
	output reg read_ready1;
	output reg read_ready2;
	input wire allocate_valid;
	input wire [TAG_W - 1:0] allocate_addr;
	input wire release_valid;
	input wire [TAG_W - 1:0] release_addr;
	input wire wb0_valid;
	input wire [TAG_W - 1:0] wb0_addr;
	input wire [31:0] wb0_data;
	input wire wb1_valid;
	input wire [TAG_W - 1:0] wb1_addr;
	input wire [31:0] wb1_data;
	input wire wb2_valid;
	input wire [TAG_W - 1:0] wb2_addr;
	input wire [31:0] wb2_data;
	input wire wb3_valid;
	input wire [TAG_W - 1:0] wb3_addr;
	input wire [31:0] wb3_data;
	reg [31:0] registers [0:ENTRIES - 1];
	reg ready [0:ENTRIES - 1];
	always @(*) begin
		if (_sv2v_0)
			;
		read_data1 = (read_addr1 == {TAG_W {1'sb0}} ? 32'd0 : registers[read_addr1]);
		read_data2 = (read_addr2 == {TAG_W {1'sb0}} ? 32'd0 : registers[read_addr2]);
		read_ready1 = (read_addr1 < 32 ? 1'b1 : ready[read_addr1]);
		read_ready2 = (read_addr2 < 32 ? 1'b1 : ready[read_addr2]);
	end
	genvar _gv_entry_1;
	generate
		for (_gv_entry_1 = 1; _gv_entry_1 < 32; _gv_entry_1 = _gv_entry_1 + 1) begin : g_arch_entry
			localparam entry = _gv_entry_1;
			localparam [TAG_W - 1:0] ENTRY_TAG = entry[TAG_W - 1:0];
			wire wb3_hit = wb3_valid && (wb3_addr == ENTRY_TAG);
			always @(posedge clock or negedge reset_n)
				if (!reset_n)
					registers[entry] <= 32'd0;
				else if (cpu_stop)
					registers[entry] <= 32'd0;
				else if (wb3_hit)
					registers[entry] <= wb3_data;
		end
	endgenerate
	genvar _gv_entry_2;
	generate
		for (_gv_entry_2 = 32; _gv_entry_2 < ENTRIES; _gv_entry_2 = _gv_entry_2 + 1) begin : g_spec_entry
			localparam entry = _gv_entry_2;
			localparam [TAG_W - 1:0] ENTRY_TAG = entry[TAG_W - 1:0];
			wire wb0_hit = wb0_valid && (wb0_addr == ENTRY_TAG);
			wire wb1_hit = wb1_valid && (wb1_addr == ENTRY_TAG);
			wire wb2_hit = wb2_valid && (wb2_addr == ENTRY_TAG);
			wire allocate_hit = allocate_valid && (allocate_addr == ENTRY_TAG);
			wire release_hit = release_valid && (release_addr == ENTRY_TAG);
			always @(posedge clock or negedge reset_n)
				if (!reset_n) begin
					registers[entry] <= 32'd0;
					ready[entry] <= 1'b0;
				end
				else if (cpu_stop) begin
					registers[entry] <= 32'd0;
					ready[entry] <= 1'b0;
				end
				else begin
					if (wb2_hit)
						registers[entry] <= wb2_data;
					else if (wb1_hit)
						registers[entry] <= wb1_data;
					else if (wb0_hit)
						registers[entry] <= wb0_data;
					if ((wb2_hit || wb1_hit) || wb0_hit)
						ready[entry] <= 1'b1;
					else if (allocate_hit || release_hit)
						ready[entry] <= 1'b0;
				end
		end
	endgenerate
	initial _sv2v_0 = 0;
endmodule
module PSC_PC (
	clock,
	reset_n,
	cpu_stop,
	execute_task_done,
	alu_data,
	pc_sel2,
	decoder_ctrl,
	cpu_trap,
	priv_mode,
	d_pf,
	i_pf,
	trap_scause,
	csr_state,
	pc,
	counter
);
	parameter signed [31:0] THREADS_NUM = 1;
	input wire clock;
	input wire reset_n;
	input wire cpu_stop;
	input wire execute_task_done;
	input wire [31:0] alu_data;
	input wire pc_sel2;
	input wire [129:0] decoder_ctrl;
	input wire cpu_trap;
	input wire [1:0] priv_mode;
	input wire d_pf;
	input wire i_pf;
	input wire [4:0] trap_scause;
	input wire [415:0] csr_state;
	output reg [31:0] pc;
	output reg [31:0] counter;
	localparam [1:0] PRIV_M = 2'b11;
	localparam [3:0] CPU_TRAP = 4'd2;
	wire exception;
	wire interrupt;
	wire trap;
	wire trap_deleg_to_s;
	wire [31:0] trap_pc;
	wire [31:0] branch_target_pc;
	wire [31:0] seq_pc;
	wire [31:0] sret_pc;
	assign exception = ((decoder_ctrl[8] | decoder_ctrl[0]) | d_pf) | i_pf;
	assign interrupt = 1'b0;
	assign trap = exception | interrupt;
	assign trap_deleg_to_s = (priv_mode != PRIV_M) && (((csr_state[383-:32] >> trap_scause) & 32'd1) != 32'd0);
	assign trap_pc = (trap_deleg_to_s ? csr_state[159-:32] : csr_state[287-:32]);
	assign branch_target_pc = {alu_data[31:1], 1'b0};
	assign seq_pc = pc + 32'd4;
	assign sret_pc = csr_state[127-:32];
	wire [31:0] next_pc;
	assign next_pc = (decoder_ctrl[9] ? csr_state[255-:32] : (decoder_ctrl[10] ? csr_state[127-:32] : (trap ? trap_pc : (pc_sel2 ? branch_target_pc : seq_pc))));
	always @(posedge clock or negedge reset_n)
		if (!reset_n) begin
			pc <= 32'd0;
			counter <= 32'd0;
		end
		else if (cpu_stop) begin
			pc <= 32'd0;
			counter <= 32'd0;
		end
		else if (trap) begin
			pc <= trap_pc;
			counter <= counter + 32'd1;
		end
		else if (execute_task_done) begin
			pc <= next_pc;
			counter <= counter + 32'd1;
		end
endmodule
module MMU (
	clk,
	reset_n,
	MMU_enb,
	vaddr,
	satp,
	priv_mode,
	access_r,
	access_w,
	access_x,
	mem_req_ready,
	mem_rdata,
	mem_addr,
	mem_valid,
	mem_ready,
	cpu_state_done,
	sfence_vma,
	paddr,
	page_fault,
	mode_sv32,
	mmu_done
);
	input wire clk;
	input wire reset_n;
	input wire MMU_enb;
	input wire [31:0] vaddr;
	input wire [31:0] satp;
	input wire [1:0] priv_mode;
	input wire access_r;
	input wire access_w;
	input wire access_x;
	input wire mem_req_ready;
	input wire [31:0] mem_rdata;
	output wire [31:0] mem_addr;
	output reg mem_valid;
	input wire mem_ready;
	input wire cpu_state_done;
	input wire sfence_vma;
	output wire [31:0] paddr;
	output reg page_fault;
	output wire mode_sv32;
	output reg mmu_done;
	localparam [1:0] PRIV_U = 2'b00;
	localparam [1:0] PRIV_S = 2'b01;
	localparam [1:0] PRIV_M = 2'b11;
	reg sfence_vma_req;
	wire [9:0] vpn1;
	wire [9:0] vpn0;
	wire [11:0] page_offset;
	assign vpn1 = vaddr[31:22];
	assign vpn0 = vaddr[21:12];
	assign page_offset = vaddr[11:0];
	reg [33:0] paddr_34bit;
	assign paddr = paddr_34bit[31:0];
	reg [33:0] mem_addr_34bit;
	assign mem_addr = mem_addr_34bit[31:0];
	assign mode_sv32 = satp[31];
	wire [21:0] root_ppn;
	assign root_ppn = satp[21:0];
	reg [3:0] state;
	reg [31:0] l1_pte;
	reg [31:0] l0_pte;
	reg l1_cache_valid;
	reg [21:0] l1_cache_root_ppn;
	reg [9:0] l1_cache_vpn;
	reg [31:0] l1_cache_pte;
	wire l1_cache_hit;
	assign l1_cache_hit = (l1_cache_valid && (l1_cache_root_ppn == root_ppn)) && (l1_cache_vpn == vpn1);
	reg l0_cache_valid;
	reg [9:0] l0_cache_vpn;
	reg [31:0] l0_cache_pte;
	wire l0_cache_hit;
	assign l0_cache_hit = (l0_cache_valid && l1_cache_hit) && (l0_cache_vpn == vpn0);
	function automatic illegal_rw;
		input reg [31:0] pte;
		illegal_rw = pte[2] && !pte[1];
	endfunction
	function automatic is_leaf;
		input reg [31:0] pte;
		is_leaf = pte[1] || pte[3];
	endfunction
	function automatic pte_valid;
		input reg [31:0] pte;
		pte_valid = pte[0] && !illegal_rw(pte);
	endfunction
	function automatic perm_ok;
		input reg [31:0] pte;
		input reg r;
		input reg w;
		input reg x;
		perm_ok = ((!r || pte[1]) && (!w || pte[2])) && (!x || pte[3]);
	endfunction
	always @(posedge clk or negedge reset_n)
		if (!reset_n) begin
			state <= 4'd0;
			mem_valid <= 1'b0;
			mem_addr_34bit <= 34'h000000000;
			paddr_34bit <= 34'h000000000;
			page_fault <= 1'b0;
			l1_pte <= 32'h00000000;
			l0_pte <= 32'h00000000;
			l1_cache_valid <= 1'b0;
			l1_cache_root_ppn <= 22'h000000;
			l1_cache_vpn <= 10'h000;
			l1_cache_pte <= 32'h00000000;
			l0_cache_valid <= 1'b0;
			l0_cache_vpn <= 10'h000;
			l0_cache_pte <= 32'h00000000;
			sfence_vma_req <= 1'b0;
			mmu_done <= 1'b0;
		end
		else begin
			if (cpu_state_done)
				page_fault <= 1'b0;
			if (sfence_vma)
				sfence_vma_req <= 1'b1;
			mem_valid <= 1'b0;
			mmu_done <= 1'b0;
			(* full_case, parallel_case *)
			case (state)
				4'd0: begin
					if (MMU_enb)
						state <= 4'd1;
					if (sfence_vma_req) begin
						l1_cache_valid <= 1'b0;
						l0_cache_valid <= 1'b0;
						sfence_vma_req <= 1'b0;
					end
				end
				4'd1: begin
					page_fault <= 1'b0;
					if (!mode_sv32 || (priv_mode == PRIV_M)) begin
						paddr_34bit <= {2'b00, vaddr};
						state <= 4'd8;
					end
					else if (l1_cache_hit) begin
						l1_pte <= l1_cache_pte;
						state <= 4'd4;
					end
					else begin
						mem_addr_34bit <= {root_ppn, 12'b000000000000} + {22'b0000000000000000000000, vpn1, 2'b00};
						if (mem_req_ready)
							state <= 4'd2;
					end
				end
				4'd2: begin
					mem_valid <= 1'b1;
					state <= 4'd3;
				end
				4'd3:
					if (mem_ready) begin
						l1_pte <= mem_rdata;
						l1_cache_pte <= mem_rdata;
						l1_cache_vpn <= vpn1;
						l1_cache_root_ppn <= root_ppn;
						l1_cache_valid <= 1'b1;
						state <= 4'd4;
					end
				4'd4:
					if (!pte_valid(l1_pte)) begin
						page_fault <= 1'b1;
						state <= 4'd8;
					end
					else if (is_leaf(l1_pte)) begin
						if (|l1_pte[19:10]) begin
							page_fault <= 1'b1;
							state <= 4'd8;
						end
						else if (!perm_ok(l1_pte, access_r, access_w, access_x)) begin
							page_fault <= 1'b1;
							state <= 4'd8;
						end
						else begin
							paddr_34bit <= {2'b00, l1_pte[31:20], vpn0, page_offset};
							state <= 4'd8;
						end
					end
					else if (l0_cache_hit) begin
						l0_pte <= l0_cache_pte;
						state <= 4'd7;
					end
					else begin
						mem_addr_34bit <= {l1_pte[31:10], 12'b000000000000} + {22'b0000000000000000000000, vpn0, 2'b00};
						if (mem_req_ready)
							state <= 4'd5;
					end
				4'd5: begin
					mem_valid <= 1'b1;
					state <= 4'd6;
				end
				4'd6:
					if (mem_ready) begin
						l0_pte <= mem_rdata;
						l0_cache_pte <= mem_rdata;
						l0_cache_vpn <= vpn0;
						l0_cache_valid <= 1'b1;
						state <= 4'd7;
					end
				4'd7:
					if (!pte_valid(l0_pte)) begin
						page_fault <= 1'b1;
						state <= 4'd8;
					end
					else if (!is_leaf(l0_pte)) begin
						page_fault <= 1'b1;
						state <= 4'd8;
					end
					else if (!perm_ok(l0_pte, access_r, access_w, access_x)) begin
						page_fault <= 1'b1;
						state <= 4'd8;
					end
					else begin
						paddr_34bit <= {l0_pte[31:10], page_offset};
						state <= 4'd8;
					end
				4'd8: begin
					mmu_done <= 1'b1;
					state <= 4'd0;
				end
				default: state <= 4'd0;
			endcase
		end
endmodule
module Csr (
	clock,
	reset_n,
	csr_enb,
	csr_valid,
	csr_wr,
	csr_cmd,
	csr_use_imm,
	csr_addr,
	csr_rs1_val,
	csr_zimm,
	csr_rdata,
	set_trap,
	trap_sepc,
	trap_scause,
	trap_stval,
	do_sret,
	set_mtrap,
	trap_mepc,
	trap_mcause,
	do_mret,
	set_msip,
	clr_msip,
	set_mtip,
	clr_mtip,
	set_meip,
	clr_meip,
	priv_mode,
	out_mstatus,
	out_medeleg,
	out_mie,
	out_mip,
	out_mtvec,
	out_mepc,
	out_mcause,
	out_sstatus,
	out_stvec,
	out_sepc,
	out_scause,
	out_stval,
	out_satp,
	out_DCACHE_CTRL,
	out_DMA_CTRL,
	out_DMA_WORDS,
	out_DMA_SRC,
	out_DMA_DST,
	in_DMA_STATUS,
	out_SA_CTRL,
	out_SA_MODE,
	in_SA_STATUS,
	out_SA_ADDR_A,
	out_SA_ADDR_B,
	out_SA_ADDR_C,
	out_CPU_MON_CTRL,
	in_CPU_MON_CYCLE
);
	reg _sv2v_0;
	input wire clock;
	input wire reset_n;
	input wire csr_enb;
	input wire csr_valid;
	input wire csr_wr;
	input wire [1:0] csr_cmd;
	input wire csr_use_imm;
	input wire [11:0] csr_addr;
	input wire [31:0] csr_rs1_val;
	input wire [4:0] csr_zimm;
	output reg [31:0] csr_rdata;
	input wire set_trap;
	input wire [31:0] trap_sepc;
	input wire [31:0] trap_scause;
	input wire [31:0] trap_stval;
	input wire do_sret;
	input wire set_mtrap;
	input wire [31:0] trap_mepc;
	input wire [31:0] trap_mcause;
	input wire do_mret;
	input wire set_msip;
	input wire clr_msip;
	input wire set_mtip;
	input wire clr_mtip;
	input wire set_meip;
	input wire clr_meip;
	output reg [1:0] priv_mode;
	output reg [31:0] out_mstatus;
	output reg [31:0] out_medeleg;
	output reg [31:0] out_mie;
	output reg [31:0] out_mip;
	output reg [31:0] out_mtvec;
	output reg [31:0] out_mepc;
	output reg [31:0] out_mcause;
	output reg [31:0] out_sstatus;
	output reg [31:0] out_stvec;
	output reg [31:0] out_sepc;
	output reg [31:0] out_scause;
	output reg [31:0] out_stval;
	output reg [31:0] out_satp;
	output reg [31:0] out_DCACHE_CTRL;
	output reg [31:0] out_DMA_CTRL;
	output reg [31:0] out_DMA_WORDS;
	output reg [31:0] out_DMA_SRC;
	output reg [31:0] out_DMA_DST;
	input wire [31:0] in_DMA_STATUS;
	output reg [31:0] out_SA_CTRL;
	output reg [31:0] out_SA_MODE;
	input wire [31:0] in_SA_STATUS;
	output reg [31:0] out_SA_ADDR_A;
	output reg [31:0] out_SA_ADDR_B;
	output reg [31:0] out_SA_ADDR_C;
	output reg [31:0] out_CPU_MON_CTRL;
	input wire [31:0] in_CPU_MON_CYCLE;
	localparam [31:0] SA_ADDR_A = 32'h00020000;
	localparam [31:0] SA_ADDR_B = 32'h00020010;
	localparam [31:0] SA_ADDR_C = 32'h00020020;
	localparam [1:0] PRIV_U = 2'b00;
	localparam [1:0] PRIV_S = 2'b01;
	localparam [1:0] PRIV_M = 2'b11;
	reg [31:0] csr_mstatus;
	reg [31:0] csr_medeleg;
	localparam [31:0] CSR_MISA = 32'h40140100;
	reg [31:0] csr_mie;
	reg [31:0] csr_mip;
	reg [31:0] csr_mtvec;
	reg [31:0] csr_mscratch;
	reg [31:0] csr_mepc;
	reg [31:0] csr_mcause;
	reg [31:0] csr_mtval;
	reg [31:0] csr_sstatus;
	reg [31:0] csr_sie;
	reg [31:0] csr_stvec;
	reg [31:0] csr_sscratch;
	reg [31:0] csr_sepc;
	reg [31:0] csr_scause;
	reg [31:0] csr_stval;
	reg [31:0] csr_satp;
	reg [1:0] csr_priv_mode;
	reg [31:0] csr_DCACHE_CTRL;
	reg [31:0] csr_DMA_CTRL;
	reg [31:0] csr_DMA_WORDS;
	reg [31:0] csr_DMA_SRC;
	reg [31:0] csr_DMA_DST;
	reg [31:0] csr_DMA_STATUS;
	reg [31:0] csr_SA_CTRL;
	reg [31:0] csr_SA_MODE;
	reg [31:0] csr_SA_STATUS;
	reg [31:0] csr_SA_ADDR_A;
	reg [31:0] csr_SA_ADDR_B;
	reg [31:0] csr_SA_ADDR_C;
	reg [31:0] csr_CPU_MON_CTRL;
	localparam signed [31:0] S_SIE_BIT = 1;
	localparam signed [31:0] S_SPIE_BIT = 5;
	localparam signed [31:0] S_SPP_BIT = 8;
	localparam signed [31:0] S_SUM_BIT = 18;
	localparam signed [31:0] S_MXR_BIT = 19;
	localparam [31:0] SSTATUS_MASK = ((((32'h00000001 << S_SIE_BIT) | (32'h00000001 << S_SPIE_BIT)) | (32'h00000001 << S_SPP_BIT)) | (32'h00000001 << S_SUM_BIT)) | (32'h00000001 << S_MXR_BIT);
	localparam [31:0] MSIP_MASK = 32'h00000001 << 3;
	localparam [31:0] MTIP_MASK = 32'h00000001 << 7;
	localparam [31:0] MEIP_MASK = 32'h00000001 << 11;
	localparam [31:0] MIRQ_MASK = (MSIP_MASK | MTIP_MASK) | MEIP_MASK;
	localparam [31:0] SSIP_MASK = 32'h00000001 << 1;
	localparam [31:0] STIP_MASK = 32'h00000001 << 5;
	localparam [31:0] SEIP_MASK = 32'h00000001 << 9;
	localparam [31:0] SIRQ_MASK = (SSIP_MASK | STIP_MASK) | SEIP_MASK;
	function automatic [31:0] pack_tvec_direct;
		input reg [31:0] v;
		pack_tvec_direct = {v[31:2], 2'b00};
	endfunction
	function automatic [31:0] pack_epc;
		input reg [31:0] v;
		pack_epc = {v[31:2], 2'b00};
	endfunction
	function automatic [31:0] pack_satp_sv32;
		input reg [31:0] v;
		begin
			pack_satp_sv32 = 32'b00000000000000000000000000000000;
			pack_satp_sv32[31] = v[31];
			pack_satp_sv32[30:22] = v[30:22];
			pack_satp_sv32[21:0] = v[21:0];
		end
	endfunction
	function automatic [31:0] sip_view;
		input reg [31:0] mip;
		reg [31:0] v;
		begin
			v = 32'b00000000000000000000000000000000;
			v[1] = mip[3];
			v[5] = mip[7];
			v[9] = mip[11];
			sip_view = v;
		end
	endfunction
	wire [31:0] csr_wr_val;
	wire side_effect_none_rs;
	assign csr_wr_val = (csr_use_imm ? {27'b000000000000000000000000000, csr_zimm} : csr_rs1_val);
	assign side_effect_none_rs = (csr_use_imm ? csr_zimm == 5'd0 : csr_rs1_val == 32'd0);
	function automatic [31:0] csr_apply;
		input reg [1:0] cmd;
		input reg no_side_effect_rs;
		input reg [31:0] oldv;
		input reg [31:0] wv;
		case (cmd)
			2'b00: csr_apply = wv;
			2'b01: csr_apply = (no_side_effect_rs ? oldv : oldv | wv);
			2'b10: csr_apply = (no_side_effect_rs ? oldv : oldv & ~wv);
			default: csr_apply = oldv;
		endcase
	endfunction
	wire trap_to_s;
	assign trap_to_s = (priv_mode != PRIV_M) && csr_medeleg[trap_scause];
	always @(posedge clock or negedge reset_n)
		if (!reset_n) begin
			out_mstatus <= 32'd0;
			out_medeleg <= 32'd0;
			out_mie <= 32'd0;
			out_mip <= 32'd0;
			out_mtvec <= 32'd0;
			out_mepc <= 32'd0;
			out_mcause <= 32'd0;
			out_sstatus <= 32'd0;
			out_stvec <= 32'd0;
			out_sepc <= 32'd0;
			out_scause <= 32'd0;
			out_stval <= 32'd0;
			out_satp <= 32'd0;
			priv_mode <= 2'b00;
			out_DCACHE_CTRL <= 32'd0;
			out_DMA_CTRL <= 32'd0;
			out_DMA_WORDS <= 32'd0;
			out_DMA_SRC <= 32'd0;
			out_DMA_DST <= 32'd0;
			out_SA_CTRL <= 32'd0;
			out_SA_ADDR_A <= 32'd0;
			out_SA_ADDR_B <= 32'd0;
			out_SA_ADDR_C <= 32'd0;
			out_CPU_MON_CTRL <= 32'd0;
			csr_DMA_STATUS <= 32'd0;
			csr_SA_STATUS <= 32'd0;
		end
		else if (csr_valid) begin
			out_mstatus <= csr_mstatus;
			out_medeleg <= csr_medeleg;
			out_mie <= csr_mie;
			out_mip <= csr_mip;
			out_mtvec <= csr_mtvec;
			out_mepc <= csr_mepc;
			out_mcause <= csr_mcause;
			out_sstatus <= csr_sstatus;
			out_stvec <= csr_stvec;
			out_sepc <= csr_sepc;
			out_scause <= csr_scause;
			out_stval <= csr_stval;
			out_satp <= csr_satp;
			out_DCACHE_CTRL <= csr_DCACHE_CTRL;
			out_DMA_CTRL <= csr_DMA_CTRL;
			out_DMA_WORDS <= csr_DMA_WORDS;
			out_DMA_SRC <= csr_DMA_SRC;
			out_DMA_DST <= csr_DMA_DST;
			out_SA_CTRL <= csr_SA_CTRL;
			out_SA_MODE <= csr_SA_MODE;
			out_SA_ADDR_A <= csr_SA_ADDR_A;
			out_SA_ADDR_B <= csr_SA_ADDR_B;
			out_SA_ADDR_C <= csr_SA_ADDR_C;
			out_CPU_MON_CTRL <= csr_CPU_MON_CTRL;
			priv_mode <= csr_priv_mode;
			csr_DMA_STATUS <= in_DMA_STATUS;
			csr_SA_STATUS <= in_SA_STATUS;
		end
	function automatic [31:0] csr_read_mux;
		input reg [11:0] a;
		case (a)
			12'h100: csr_read_mux = csr_sstatus & SSTATUS_MASK;
			12'h104: csr_read_mux = csr_sie & SIRQ_MASK;
			12'h105: csr_read_mux = csr_stvec;
			12'h140: csr_read_mux = csr_sscratch;
			12'h141: csr_read_mux = csr_sepc;
			12'h142: csr_read_mux = csr_scause;
			12'h143: csr_read_mux = csr_stval;
			12'h144: csr_read_mux = sip_view(csr_mip);
			12'h180: csr_read_mux = csr_satp;
			12'h300: csr_read_mux = csr_mstatus;
			12'h301: csr_read_mux = CSR_MISA;
			12'h302: csr_read_mux = csr_medeleg;
			12'h304: csr_read_mux = csr_mie & MIRQ_MASK;
			12'h305: csr_read_mux = csr_mtvec;
			12'h340: csr_read_mux = csr_mscratch;
			12'h341: csr_read_mux = csr_mepc;
			12'h342: csr_read_mux = csr_mcause;
			12'h344: csr_read_mux = csr_mip & MIRQ_MASK;
			12'h7f0: csr_read_mux = csr_DMA_STATUS;
			12'h7c8: csr_read_mux = csr_SA_STATUS;
			12'hbc4: csr_read_mux = in_CPU_MON_CYCLE;
			default: csr_read_mux = 32'b00000000000000000000000000000000;
		endcase
	endfunction
	wire [31:0] oldv;
	wire [31:0] newv;
	always @(csr_addr or in_CPU_MON_CYCLE or csr_SA_STATUS or csr_DMA_STATUS or csr_mip or csr_mcause or csr_mepc or csr_mscratch or csr_mtvec or csr_mie or csr_medeleg or csr_mstatus or csr_satp or csr_stval or csr_scause or csr_sepc or csr_sscratch or csr_stvec or csr_sie or csr_sstatus or _sv2v_0) begin
		if (_sv2v_0)
			;
		csr_rdata = csr_read_mux(csr_addr);
	end
	assign oldv = csr_read_mux(csr_addr);
	assign newv = csr_apply(csr_cmd, side_effect_none_rs, oldv, csr_wr_val);
	always @(posedge clock or negedge reset_n)
		if (!reset_n) begin
			csr_priv_mode <= PRIV_M;
			csr_mstatus <= 32'h00001800;
			csr_medeleg <= 32'b00000000000000000000000000000000;
			csr_mie <= 32'b00000000000000000000000000000000;
			csr_mtvec <= 32'b00000000000000000000000000000000;
			csr_mscratch <= 32'b00000000000000000000000000000000;
			csr_mepc <= 32'b00000000000000000000000000000000;
			csr_mcause <= 32'b00000000000000000000000000000000;
			csr_mip <= 32'b00000000000000000000000000000000;
			csr_sstatus <= 32'b00000000000000000000000000000000;
			csr_sie <= 32'b00000000000000000000000000000000;
			csr_stvec <= 32'b00000000000000000000000000000000;
			csr_sscratch <= 32'b00000000000000000000000000000000;
			csr_sepc <= 32'b00000000000000000000000000000000;
			csr_scause <= 32'b00000000000000000000000000000000;
			csr_stval <= 32'b00000000000000000000000000000000;
			csr_satp <= 32'b00000000000000000000000000000000;
			csr_DCACHE_CTRL <= 32'b00000000000000000000000000000000;
			csr_DMA_CTRL <= 32'b00000000000000000000000000000000;
			csr_DMA_WORDS <= 32'b00000000000000000000000000000000;
			csr_DMA_SRC <= 32'b00000000000000000000000000000000;
			csr_DMA_DST <= 32'b00000000000000000000000000000000;
			csr_SA_CTRL <= 32'b00000000000000000000000000000000;
			csr_SA_MODE <= 32'b00000000000000000000000000000000;
			csr_SA_ADDR_A <= SA_ADDR_A;
			csr_SA_ADDR_B <= SA_ADDR_B;
			csr_SA_ADDR_C <= SA_ADDR_C;
			csr_CPU_MON_CTRL <= 32'b00000000000000000000000000000000;
		end
		else begin
			if (csr_wr & csr_enb)
				case (csr_addr)
					12'h100: csr_sstatus <= newv & SSTATUS_MASK;
					12'h104: csr_sie <= newv & SIRQ_MASK;
					12'h105: csr_stvec <= pack_tvec_direct(newv);
					12'h140: csr_sscratch <= newv;
					12'h141: csr_sepc <= pack_epc(newv);
					12'h142: csr_scause <= newv;
					12'h143: csr_stval <= newv;
					12'h144:
						if (!side_effect_none_rs)
							csr_mip[3] <= newv[1];
					12'h180: csr_satp <= pack_satp_sv32(newv);
					12'h300: csr_mstatus <= newv;
					12'h302: csr_medeleg <= newv;
					12'h301:
						;
					12'h304: csr_mie <= newv & MIRQ_MASK;
					12'h305: csr_mtvec <= pack_tvec_direct(newv);
					12'h340: csr_mscratch <= newv;
					12'h341: csr_mepc <= pack_epc(newv);
					12'h342: csr_mcause <= newv;
					12'h344: csr_mip <= newv & MIRQ_MASK;
					12'h7f0: csr_DCACHE_CTRL <= newv;
					12'h7e0: csr_DMA_CTRL <= newv;
					12'h7e4: csr_DMA_WORDS <= newv;
					12'h7e8: csr_DMA_SRC <= newv;
					12'h7ec: csr_DMA_DST <= newv;
					12'h7c0: csr_SA_CTRL <= newv;
					12'h7c4: csr_SA_MODE <= newv;
					12'h7d0: csr_SA_ADDR_A <= newv;
					12'h7d4: csr_SA_ADDR_B <= newv;
					12'h7d8: csr_SA_ADDR_C <= newv;
					12'hbc0: csr_CPU_MON_CTRL <= newv;
					default:
						;
				endcase
			if (set_trap) begin
				if (trap_to_s) begin
					csr_priv_mode <= PRIV_S;
					csr_sepc <= pack_epc(trap_sepc);
					csr_scause <= trap_scause;
					csr_stval <= trap_stval;
					csr_sstatus[S_SPIE_BIT] <= csr_sstatus[S_SIE_BIT];
					csr_sstatus[S_SIE_BIT] <= 1'b0;
					csr_sstatus[S_SPP_BIT] <= priv_mode[0];
				end
				else begin
					csr_priv_mode <= PRIV_M;
					csr_mepc <= pack_epc(trap_sepc);
					csr_mcause <= trap_scause;
					csr_mtval <= trap_stval;
					csr_mstatus[7] <= csr_mstatus[3];
					csr_mstatus[3] <= 1'b0;
					csr_mstatus[12:11] <= priv_mode;
				end
			end
			if (csr_enb) begin
				if (do_sret) begin
					csr_priv_mode <= {1'b0, csr_sstatus[S_SPP_BIT]};
					csr_sepc <= pack_epc(csr_sepc);
					csr_sstatus[S_SIE_BIT] <= csr_sstatus[S_SPIE_BIT];
					csr_sstatus[S_SPIE_BIT] <= 1'b1;
					csr_sstatus[S_SPP_BIT] <= 1'b0;
				end
				if (do_mret) begin
					csr_priv_mode <= csr_mstatus[12:11];
					csr_mstatus[3] <= csr_mstatus[7];
					csr_mstatus[7] <= 1'b1;
					csr_mstatus[12:11] <= 2'b00;
				end
				if (set_mtrap) begin
					csr_mepc <= pack_epc(trap_mepc);
					csr_mcause <= trap_mcause;
					csr_mstatus[7] <= csr_mstatus[3];
					csr_mstatus[3] <= 1'b0;
				end
			end
			if (set_msip)
				csr_mip[3] <= 1'b1;
			if (clr_msip)
				csr_mip[3] <= 1'b0;
			if (set_mtip)
				csr_mip[7] <= 1'b1;
			if (clr_mtip)
				csr_mip[7] <= 1'b0;
			if (set_meip)
				csr_mip[11] <= 1'b1;
			if (clr_meip)
				csr_mip[11] <= 1'b0;
		end
	initial _sv2v_0 = 0;
endmodule
module PSC_RV32ISP_Monitor (
	clock,
	reset_n,
	PSC_CPU_MON_CTRL,
	PSC_CPU_MON_CYCLE,
	program_cache_hit_pulse,
	program_cache_miss_pulse,
	data_cache_hit_pulse,
	data_cache_miss_pulse
);
	parameter CLK_FREQ_MHz = 80;
	input wire clock;
	input wire reset_n;
	input wire [31:0] PSC_CPU_MON_CTRL;
	output reg [31:0] PSC_CPU_MON_CYCLE;
	input wire program_cache_hit_pulse;
	input wire program_cache_miss_pulse;
	input wire data_cache_hit_pulse;
	input wire data_cache_miss_pulse;
	reg [31:0] program_cache_hit_count;
	reg [31:0] program_cache_miss_count;
	reg [31:0] data_cache_hit_count;
	reg [31:0] data_cache_miss_count;
	always @(posedge clock or negedge reset_n)
		if (!reset_n) begin
			program_cache_hit_count <= 1'sb0;
			program_cache_miss_count <= 1'sb0;
			data_cache_hit_count <= 1'sb0;
			data_cache_miss_count <= 1'sb0;
		end
		else begin
			if (program_cache_hit_pulse)
				program_cache_hit_count <= program_cache_hit_count + 1'b1;
			if (program_cache_miss_pulse)
				program_cache_miss_count <= program_cache_miss_count + 1'b1;
			if (data_cache_hit_pulse)
				data_cache_hit_count <= data_cache_hit_count + 1'b1;
			if (data_cache_miss_pulse)
				data_cache_miss_count <= data_cache_miss_count + 1'b1;
		end
	always @(posedge clock or negedge reset_n)
		if (!reset_n)
			PSC_CPU_MON_CYCLE <= 1'sb0;
		else
			case (PSC_CPU_MON_CTRL)
				32'd0: PSC_CPU_MON_CYCLE <= program_cache_hit_count;
				32'd1: PSC_CPU_MON_CYCLE <= program_cache_miss_count;
				32'd2: PSC_CPU_MON_CYCLE <= data_cache_hit_count;
				32'd3: PSC_CPU_MON_CYCLE <= data_cache_miss_count;
				default: PSC_CPU_MON_CYCLE <= 1'sb0;
			endcase
endmodule
module PSC_CPU_TimingTop (
	clock,
	reset_n,
	timing_keep
);
	input wire clock;
	input wire reset_n;
	output reg timing_keep;
	(* keep = "true" *) reg [31:0] stimulus;
	always @(posedge clock or negedge reset_n)
		if (!reset_n)
			stimulus <= 32'h1aceb00c;
		else
			stimulus <= {stimulus[30:0], ((stimulus[31] ^ stimulus[21]) ^ stimulus[1]) ^ stimulus[0]};
	(* keep = "true" *) wire cpu_stop;
	(* keep = "true" *) wire irq_ext;
	(* keep = "true" *) wire program_mem_read_ready;
	(* keep = "true" *) wire [31:0] program_mem_read_data;
	(* keep = "true" *) wire program_mem_req_ready;
	(* keep = "true" *) wire data_mem_read_ready;
	(* keep = "true" *) wire [31:0] data_mem_read_data;
	(* keep = "true" *) wire data_mem_req_ready;
	(* keep = "true" *) wire data_mem_write_ready;
	(* keep = "true" *) wire mmu_data_mem_read_ready;
	(* keep = "true" *) wire [31:0] mmu_data_mem_read_data;
	(* keep = "true" *) wire mmu_data_req_ready;
	(* keep = "true" *) wire [31:0] csr_DMA_STATUS;
	(* keep = "true" *) wire [31:0] csr_SA_STATUS;
	(* keep = "true" *) wire [31:0] csr_CPU_MON_CYCLE;
	assign cpu_stop = 1'b0;
	assign irq_ext = stimulus[0];
	assign program_mem_read_ready = stimulus[1];
	assign program_mem_read_data = stimulus ^ 32'h13579bdf;
	assign program_mem_req_ready = stimulus[2];
	assign data_mem_read_ready = stimulus[3];
	assign data_mem_read_data = {stimulus[15:0], stimulus[31:16]};
	assign data_mem_req_ready = stimulus[4];
	assign data_mem_write_ready = stimulus[5];
	assign mmu_data_mem_read_ready = stimulus[6];
	assign mmu_data_mem_read_data = ~stimulus;
	assign mmu_data_req_ready = stimulus[7];
	assign csr_DMA_STATUS = stimulus ^ 32'h2468ace0;
	assign csr_SA_STATUS = {stimulus[7:0], stimulus[31:8]};
	assign csr_CPU_MON_CYCLE = stimulus;
	(* keep = "true" *) wire program_mem_burst_mode;
	(* keep = "true" *) wire program_mem_read_valid;
	(* keep = "true" *) wire [31:0] program_mem_read_address;
	(* keep = "true" *) wire data_mem_read_valid;
	(* keep = "true" *) wire [31:0] data_mem_read_address;
	(* keep = "true" *) wire data_mem_write_valid;
	(* keep = "true" *) wire [2:0] mem_write_sel;
	(* keep = "true" *) wire [31:0] mem_write_address;
	(* keep = "true" *) wire [31:0] mem_write_data;
	(* keep = "true" *) wire mmu_data_mem_read_valid;
	(* keep = "true" *) wire [31:0] mmu_data_mem_read_address;
	(* keep = "true" *) wire is_fence_i;
	(* keep = "true" *) wire [31:0] csr_DCACHE_CTRL;
	(* keep = "true" *) wire [31:0] csr_DMA_CTRL;
	(* keep = "true" *) wire [31:0] csr_DMA_WORDS;
	(* keep = "true" *) wire [31:0] csr_DMA_SRC;
	(* keep = "true" *) wire [31:0] csr_DMA_DST;
	(* keep = "true" *) wire [31:0] csr_SA_CTRL;
	(* keep = "true" *) wire [31:0] csr_SA_MODE;
	(* keep = "true" *) wire [31:0] csr_SA_ADDR_A;
	(* keep = "true" *) wire [31:0] csr_SA_ADDR_B;
	(* keep = "true" *) wire [31:0] csr_SA_ADDR_C;
	(* keep = "true" *) wire [31:0] csr_CPU_MON_CTRL;
	(* keep = "true" *) wire [8:0] uart_out;
	PSC_RV32ISP_core u_cpu(
		.clock(clock),
		.reset_n(reset_n),
		.cpu_stop(cpu_stop),
		.irq_ext(irq_ext),
		.program_mem_burst_mode(program_mem_burst_mode),
		.program_mem_read_valid(program_mem_read_valid),
		.program_mem_read_ready(program_mem_read_ready),
		.program_mem_read_address(program_mem_read_address),
		.program_mem_read_data(program_mem_read_data),
		.program_mem_req_ready(program_mem_req_ready),
		.data_mem_read_valid(data_mem_read_valid),
		.data_mem_read_ready(data_mem_read_ready),
		.data_mem_read_address(data_mem_read_address),
		.data_mem_read_data(data_mem_read_data),
		.data_mem_req_ready(data_mem_req_ready),
		.data_mem_write_valid(data_mem_write_valid),
		.data_mem_write_ready(data_mem_write_ready),
		.mem_write_sel(mem_write_sel),
		.mem_write_address(mem_write_address),
		.mem_write_data(mem_write_data),
		.mmu_data_mem_read_valid(mmu_data_mem_read_valid),
		.mmu_data_mem_read_ready(mmu_data_mem_read_ready),
		.mmu_data_mem_read_address(mmu_data_mem_read_address),
		.mmu_data_mem_read_data(mmu_data_mem_read_data),
		.mmu_data_req_ready(mmu_data_req_ready),
		.is_fence_i(is_fence_i),
		.csr_DCACHE_CTRL(csr_DCACHE_CTRL),
		.csr_DMA_CTRL(csr_DMA_CTRL),
		.csr_DMA_WORDS(csr_DMA_WORDS),
		.csr_DMA_SRC(csr_DMA_SRC),
		.csr_DMA_DST(csr_DMA_DST),
		.csr_DMA_STATUS(csr_DMA_STATUS),
		.csr_SA_CTRL(csr_SA_CTRL),
		.csr_SA_MODE(csr_SA_MODE),
		.csr_SA_STATUS(csr_SA_STATUS),
		.csr_SA_ADDR_A(csr_SA_ADDR_A),
		.csr_SA_ADDR_B(csr_SA_ADDR_B),
		.csr_SA_ADDR_C(csr_SA_ADDR_C),
		.csr_CPU_MON_CTRL(csr_CPU_MON_CTRL),
		.csr_CPU_MON_CYCLE(csr_CPU_MON_CYCLE),
		.uart_out(uart_out)
	);
	always @(posedge clock or negedge reset_n)
		if (!reset_n)
			timing_keep <= 1'b0;
		else
			timing_keep <= ((((program_mem_read_valid ^ data_mem_read_valid) ^ data_mem_write_valid) ^ mmu_data_mem_read_valid) ^ uart_out[0]) ^ csr_SA_CTRL[0];
endmodule
