module dvi_tx_top #(
    // Parameter
    parameter integer 		    COLOR_BAR_MODE = 1,
    parameter [ADDR_WIDTH-1:0]  VRAM_ADDRESS   = 32'h0090_0000,
	// AXI Prameter
    parameter integer ADDR_WIDTH   = 32,
    parameter integer ID_WIDTH     = 1,
    parameter integer DATA_WIDTH   = 256,
    parameter DOUBLE_BUFFER = 1'b0
)(
    // CLK, RESET
	input				axi_clock,
	input				pixel_clock,
	input				ddr_bit_clock,
	input				reset,

    // -------------------------------
    // AXI4 master, 32 bytes per beat
    // Write Address
    output wire  [ID_WIDTH-1:0]      pix_axi_awid,
    output wire  [ADDR_WIDTH-1:0]    pix_axi_awaddr,
    output wire  [7:0]               pix_axi_awlen,
    output wire  [2:0]               pix_axi_awsize,
    output wire  [1:0]               pix_axi_awburst,       // INCR=01
    output wire                      pix_axi_awvalid,
    input  wire                      pix_axi_awready,

    // Write Data
    output wire  [DATA_WIDTH-1:0]    pix_axi_wdata,
    output wire  [(DATA_WIDTH/8)-1:0]pix_axi_wstrb,
    output wire                      pix_axi_wlast,
    output wire                      pix_axi_wvalid,
    input  wire                      pix_axi_wready,

    // Write Response
    input  wire [ID_WIDTH-1:0]       pix_axi_bid,
    input  wire [1:0]                pix_axi_bresp,
    input  wire                      pix_axi_bvalid,
    output wire                      pix_axi_bready,

    // Read Address
    output wire  [ID_WIDTH-1:0]      pix_axi_arid,
    output wire  [ADDR_WIDTH-1:0]    pix_axi_araddr,
    output wire  [7:0]               pix_axi_arlen,
    output wire  [2:0]               pix_axi_arsize,
    output wire  [1:0]               pix_axi_arburst,       // INCR
    output wire                      pix_axi_arvalid,
    input  wire                      pix_axi_arready,

    // Read Data
    input  wire [ID_WIDTH-1:0]       pix_axi_rid,
    input  wire [DATA_WIDTH-1:0]     pix_axi_rdata,
    input  wire [1:0]                pix_axi_rresp,
    input  wire                      pix_axi_rlast,
    input  wire                      pix_axi_rvalid,
    output wire                      pix_axi_rready,
	
    // ===== HDMI =====
	output	[1 : 0]		tmds_clk,
	output	[1 : 0]		tmds_d0,
	output	[1 : 0]		tmds_d1,
	output	[1 : 0]		tmds_d2,
    input wire requested_page,
    output wire displayed_page, scanout_busy
);

    // Video scanout only uses the AXI read channels.
    assign pix_axi_awid    = '0;
    assign pix_axi_awaddr  = '0;
    assign pix_axi_awlen   = '0;
    assign pix_axi_awsize  = '0;
    assign pix_axi_awburst = '0;
    assign pix_axi_awvalid = '0;
    assign pix_axi_wdata   = '0;
    assign pix_axi_wstrb   = '0;
    assign pix_axi_wlast   = '0;
    assign pix_axi_wvalid  = '0;
    assign pix_axi_bready  = '0;
    assign pix_axi_arid    = '0;

	wire	[5 : 0]		ctrl;
	wire	[29 : 0]	tmds_enc;
	
	wire				dvi_vsync, dvi_hsync, dvi_den;
	wire	[23 : 0]	dvi_data;
	wire	[5 : 0]		data_out_to_pins;
	
	assign {tmds_d2, tmds_d1, tmds_d0} = data_out_to_pins;
	
    generate
        if (COLOR_BAR_MODE == 0) begin : gen_vram
            assign pix_axi_arsize  = 3'd5;
            assign pix_axi_arburst = 2'b01;

            dvi_vram_scanout #(
                .ADDR_WIDTH          (ADDR_WIDTH),
                .VRAM_ADDRESS        (VRAM_ADDRESS),
                .DOUBLE_BUFFER       (DOUBLE_BUFFER)
            ) scanout (
                .requested_page      (requested_page),
                .displayed_page      (displayed_page),
                .scanout_busy        (scanout_busy),
                .axi_clock           (axi_clock),
                .pixel_clock         (pixel_clock),
                .reset               (reset),
                .araddr              (pix_axi_araddr),
                .arlen               (pix_axi_arlen),
                .arvalid             (pix_axi_arvalid),
                .arready             (pix_axi_arready),
                .rdata               (pix_axi_rdata),
                .rresp               (pix_axi_rresp),
                .rlast               (pix_axi_rlast),
                .rvalid              (pix_axi_rvalid),
                .rready              (pix_axi_rready),
                .hsync               (dvi_hsync),
                .vsync               (dvi_vsync),
                .den                 (dvi_den),
                .rgb                 (dvi_data)
            );
        end else begin : gen_bars
            assign displayed_page = 0;
            assign scanout_busy = 0;
            assign pix_axi_araddr  = '0;
            assign pix_axi_arlen   = '0;
            assign pix_axi_arsize  = '0;
            assign pix_axi_arburst = '0;
            assign pix_axi_arvalid = 1'b0;
            assign pix_axi_rready  = 1'b0;

            test_pattern_gen u_test_pattern_gen (
                .pixel_clock         (pixel_clock),
                .reset               (reset),
                .video_vsync         (dvi_vsync),
                .video_hsync         (dvi_hsync),
                .video_den           (dvi_den),
                .video_line_start    (),
                .video_pixel_even    (dvi_data),
                .video_pixel_odd     ()
            );
        end
    endgenerate

	assign ctrl[0] = dvi_hsync;
	assign ctrl[1] = dvi_vsync;
	assign ctrl[5 : 2] = 4'b0000;
	
	// TMDS GEN
	generate
		
		genvar i;
		
		for(i = 0; i < 3; i = i + 1)begin : gen_enc
			
			dvi_tx_tmds_enc dvi_tx_tmds_enc_inst(
				// input
				.clock		(pixel_clock),
				.reset		(reset),
				.den		(dvi_den),
				.data		(dvi_data[(8*i) +: 8]),
				.ctrl		(ctrl[(2*i) +: 2]),
				// output 
				.tmds		(tmds_enc[(10*i) +: 10])
			);
			
			dvi_tx_tmds_phy dvi_tx_tmds_phy_inst(
				// input
				.pixel_clock		(pixel_clock),
				.ddr_bit_clock		(ddr_bit_clock),
				.reset				(reset),
				.data				(tmds_enc[(10*i) +: 10]),
				// output 
				.tmds_lane			(data_out_to_pins[2*i +: 2])
			);
		end
		
	endgenerate
	
	dvi_tx_clk_drv clock_phy(
		.pixel_clock	(pixel_clock),
		.tmds_clk		(tmds_clk)
	);
	
endmodule
