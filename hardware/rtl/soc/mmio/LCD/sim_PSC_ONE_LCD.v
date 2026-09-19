// NISHIHARU
`timescale 1ns / 1ps
`define BSRAM_REDUCE

module sim_PSC_ONE_LCD #(
    // MMIO base (word addressed)
    parameter integer CLK_FREQ               = 80,
    parameter integer DIV_CLK                = 8,
    parameter integer ADDR_WIDTH             = 32,
    parameter [ADDR_WIDTH-1:0] LCD_PIXS_ADDR = 32'h1000_3000,
    parameter [ADDR_WIDTH-1:0] LCD_PIXS_DATA = 32'h1000_3004
)(
    input  wire                     clock,
    input  wire                     reset_n,

    // ---------------- PSC-ONE LCD ----------------
    /*
    output wire                     PSCONE_LCD_CS,
    output wire                     PSCONE_LCD_RST,
    output wire                     PSCONE_LCD_BL,
    output wire                     PSCONE_LCD_DC,
    output wire                     PSCONE_LCD_SCK,
    output wire                     PSCONE_LCD_SDI,
    input  wire                     PSCONE_LCD_SDO,
    */

    // ---------------- CPU I/F ----------------
    input  wire                     cpu_wvalid,
    input  wire [ADDR_WIDTH-1:0]    cpu_waddr,
    input  wire [31:0]              cpu_wdata,
    output reg                      cpu_wready,   // 1clk パルス

    input  wire                     cpu_rvalid,
    input  wire [ADDR_WIDTH-1:0]    cpu_raddr,
    output wire [31:0]              cpu_rdata,
    output reg                      cpu_rready  
);
    
    wire                     PSCONE_LCD_CS;
    wire                     PSCONE_LCD_RST;
    wire                     PSCONE_LCD_BL;
    wire                     PSCONE_LCD_DC;
    wire                     PSCONE_LCD_SCK;
    wire                     PSCONE_LCD_SDI;
    wire                     PSCONE_LCD_SDO;

    `ifdef COCOTB_SIM
    initial begin
        `ifdef DUMP_VCD
        $display("COCOTB_SIM DUMP_VCD ENABLE");
        $dumpfile("./wave/PSC_LCD_test.vcd");  // 出力するVCDファイル名
        $dumpvars(0);     // 第1引数: 階層 (0 はこのモジュールを最上位として)
        `else
        $display("COCOTB_SIM verilator FST ENABLE");
        $dumpfile("./wave/PSC_LCD_test.fst");  // 出力するVCDファイル名
        $dumpvars(0);     // 第1引数: 階層 (0 はこのモジュールを最上位として)
        `endif
    end
    `else
    `endif

    PSC_ONE_LCD #(
        .CLK_FREQ       (80),
        .DIV_CLK        (8),
        .ADDR_WIDTH     (32),
        .LCD_PIXS_DATA  (32'h1000_3000),
        .LCD_PIXS_ST    (32'h1000_3004)
    ) u_lcd (
        .clock          (clock),
        .reset_n        (reset_n),

        .tft_sdo        (PSCONE_LCD_SDO),
        .tft_sck        (PSCONE_LCD_SCK),
        .tft_sdi        (PSCONE_LCD_SDI),
        .tft_dc         (PSCONE_LCD_DC),
        .tft_reset      (PSCONE_LCD_RST),
        .tft_cs         (PSCONE_LCD_CS),

        .cpu_wvalid     (cpu_wvalid),
        .cpu_waddr      (cpu_waddr),
        .cpu_wdata      (cpu_wdata),
        .cpu_wready     (cpu_wready),

        .cpu_rvalid     (cpu_rvalid),
        .cpu_raddr      (cpu_raddr),
        .cpu_rdata      (cpu_rdata),
        .cpu_rready     (cpu_rready)
    );

    // ------------------------------
    // LCD ILI9488モデル
    // ------------------------------
    PSC_LCD_ILI9488_MODEL #(
        .DATA_WIDTH     (32)
    ) u_lcd_model (
        .clock          (clock),
        .LCD_CS         (PSCONE_LCD_CS),
        .LCD_RST        (PSCONE_LCD_RST),
        .LCD_BL         (1'b1),
        .LCD_DC         (PSCONE_LCD_DC),
        .LCD_SCK        (PSCONE_LCD_SCK),
        .LCD_SDI        (PSCONE_LCD_SDI),
        .LCD_SDO        (PSCONE_LCD_SDO)
    );

endmodule