// NISHIHARU
// PSC_ONE_LCD module. cpu write data ready.
// ILI9488
`timescale 1ns / 1ps

module PSC_ONE_LCD #(
    // MMIO base (word addressed)
    parameter integer CLK_FREQ               = 80,
    parameter integer DIV_CLK                = 2,
    parameter integer ADDR_WIDTH             = 32,
    parameter [ADDR_WIDTH-1:0] LCD_PIXS_DATA = 32'h1000_3000,
    parameter [ADDR_WIDTH-1:0] LCD_PIXS_ST   = 32'h1000_3004
)(
    input  wire                     clock,
    input  wire                     reset_n,

    // TFT panel pins
    input  wire                     tft_sdo,    // input
    output wire                     tft_sck,
    output wire                     tft_sdi,
    output wire                     tft_dc,
    output reg                      tft_reset,
    output wire                     tft_cs,

    // CPU write IF (1clk パルス)
    input  wire                     cpu_rvalid,
    input  wire [ADDR_WIDTH-1:0]    cpu_raddr,
    output reg  [31:0]              cpu_rdata,
    output reg                      cpu_rready,

    input  wire                     cpu_wvalid,
    input  wire [ADDR_WIDTH-1:0]    cpu_waddr,
    input  wire [31:0]              cpu_wdata,
    output reg                      cpu_wready   // 1clk パルス
);

    // アドレス
    wire [ADDR_WIDTH-1:0]     cpu_byte_waddr = cpu_waddr;   // byte address
    wire [ADDR_WIDTH-1:0]     cpu_byte_raddr = cpu_raddr;   // byte address

    // ---------------- cpu_valid latch ----------------
    reg     cpu_rvalid_latch;
    reg     cpu_wvalid_latch;
    
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            cpu_rvalid_latch    <= 1'b0;
            cpu_wvalid_latch    <= 1'b0;
        end else begin
            cpu_rvalid_latch    <= cpu_rvalid;
            cpu_wvalid_latch    <= cpu_wvalid;
        end
    end

    // ------------------------------------------------------------
    // CPU-IF
    // ------------------------------------------------------------
    reg         cpu_if_valid;
    reg [8:0]   cpu_if_data;
    wire        cpu_if_ready;

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            cpu_wready  <= 1'b0;
            cpu_rready  <= 1'b0;
            cpu_if_valid <= 1'b0;
            cpu_if_data  <= 9'h0;
            cpu_rdata    <= 32'h0;
            tft_reset    <= 1'b1;
        end else begin
            cpu_wready <= 1'b0;
            cpu_rready <= 1'b0;
            // CPU I/F
            // W
            if(cpu_wvalid_latch) begin
                case(cpu_byte_waddr)
                    LCD_PIXS_DATA: begin
                        cpu_if_data <= cpu_wdata[8:0];
                        cpu_wready  <= 1'b1;
                    end
                    LCD_PIXS_ST: begin
                        cpu_if_valid <= cpu_wdata[0];
                        tft_reset    <= cpu_wdata[1];
                        cpu_wready   <= 1'b1;
                    end
                    default: ;
                endcase
            end else if (cpu_if_ready) begin
                cpu_if_valid <= 1'b0;           // div_clkから
            end
            // R
            if(cpu_rvalid_latch) begin
                case(cpu_byte_raddr)
                    LCD_PIXS_DATA: begin
                        cpu_rready <= 1'b1;
                    end
                    LCD_PIXS_ST: begin
                        cpu_rdata  <= {30'h0,
                                       cpu_if_ready,
                                       spi_idle
                                       };
                        cpu_rready <= 1'b1;
                    end
                    default: ;
                endcase
            end
        end
    end

    // ============================================================
    // ここから下はdiv_clk駆動
    // ============================================================

    // ------------------------------------------------------------
    // clock_divider 
    // ------------------------------------------------------------
    wire    div_clk;

`ifdef COCOTB_SIM
    tft_clock_divider #(
        .DIV            (DIV_CLK)
    ) m_clock_divider (
        .clock          (clock),
        .reset_n        (reset_n),
        .clk_div        (div_clk)
    );
`else
    Gowin_CLKDIV m_gowin_clk_div(
        .clkout         (div_clk),      //output clkout. max 20MHz
        .hclkin         (clock),        //input hclkin
        .resetn         (reset_n)       //input resetn
    );
`endif

    // ------------------------------------------------------------
    // TFT Module
    //  - tft_ILI9488 は SPI 叩いて ILI9488 にピクセルを投げる
    //  - currentPixel を逐次受け取る
    // ------------------------------------------------------------
    wire    spi_idle;

    tft_ili9488 #(
        .INPUT_CLK_MHZ          (CLK_FREQ)
    ) u_tft (
        .clock                  (div_clk),
        .reset_n                (reset_n),

        .tft_sdo                (tft_sdo),                   // Input not used.
        .tft_sck                (tft_sck),
        .tft_sdi                (tft_sdi),
        .tft_dc                 (tft_dc),
        .tft_cs                 (tft_cs),
        .spi_idle               (spi_idle),

        .cpu_if_valid           (cpu_if_valid),
        .cpu_if_ready           (cpu_if_ready),
        .cpu_if_data            (cpu_if_data)                // 9bit
    );

endmodule
