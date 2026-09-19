// NISHIHARU
`timescale 1ns / 1ps

module sim_PSC_I2SRX #(
    // MMIO base (word addressed)
    parameter int CLK_FREQ               = 80,
    parameter int ADDR_WIDTH             = 32,

    // PIO アドレス（0なら無効）
    parameter logic [ADDR_WIDTH-1:0] PSC_I2S_ADDR_RX     = 32'h1000_7000,
    parameter logic [ADDR_WIDTH-1:0] PSC_I2S_ADDR_ST     = 32'h1000_7004
)(
    input  logic                     clock,
    input  logic                     reset_n,

    // ---------------- PSC-ONE LCD ----------------
    /*
    output logic                     PSCONE_LCD_CS,
    output logic                     PSCONE_LCD_RST,
    output logic                     PSCONE_LCD_BL,
    output logic                     PSCONE_LCD_DC,
    output logic                     PSCONE_LCD_SCK,
    output logic                     PSCONE_LCD_SDI,
    input  logic                     PSCONE_LCD_SDO,
    */

    // ---------------- CPU I/F ----------------
    input  logic                     cpu_rvalid,
    input  logic [ADDR_WIDTH-1:0]    cpu_raddr,
    output logic [31:0]              cpu_rdata,
    output logic                     cpu_rready   // 1clk パルス
);

    `ifdef COCOTB_SIM
    initial begin
        `ifdef DUMP_VCD
        $display("COCOTB_SIM DUMP_VCD ENABLE");
        $dumpfile("./wave/PSC_MIC_test.vcd");  // 出力するVCDファイル名
        $dumpvars(0);     // 第1引数: 階層 (0 はこのモジュールを最上位として)
        `else
        $display("COCOTB_SIM verilator FST ENABLE");
        $dumpfile("./wave/PSC_MIC_test.fst");  // 出力するVCDファイル名
        $dumpvars(0);     // 第1引数: 階層 (0 はこのモジュールを最上位として)
        `endif
    end
    `endif

    logic    I2S_SCK;
    logic    I2S_WS;
    logic    I2S_LR;
    logic    I2S_SD;

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
		.cpu_rvalid     (cpu_rvalid),
        .cpu_raddr      (cpu_raddr),
        .cpu_rdata      (cpu_rdata),
        .cpu_rready     (cpu_rready),

        // I2S IF
        .I2S_SCK        (I2S_SCK),
        .I2S_WS         (I2S_WS),
        .I2S_LR         (I2S_LR),
        .I2S_SD         (I2S_SD)
    );

    //==========================================================
    // I2S MEMSマイクモデル
    //==========================================================
    PSC_I2S_MIC_MODEL #(
        .DATA_WIDTH     (32)
    ) u_mic_model (
        .clock          (clock),
        .SCK_i          (I2S_SCK),
        .WS_i           (I2S_WS),
        .LR_i           (I2S_LR),
        .SD_o           (I2S_SD)
    );


    
endmodule