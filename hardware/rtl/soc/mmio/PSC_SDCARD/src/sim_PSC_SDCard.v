`timescale 1ns/1ps

module sim_PSC_SDCard #(
    parameter SD_IF_DATA    = 32'h1000_6000,  // READ: FIFO pop (byte)
    parameter SD_IF_SECTOR  = 32'h1000_6004,  // WRITE: LBA
    parameter SD_IF_CTRL    = 32'h1000_6008   // RW: start/status
)(
    input  wire        clock,
    input  wire        reset_n,

    // ---------------- CPU BUS ----------------
    input  wire        cpu_rvalid,
    input  wire [31:0] cpu_raddr,
    output reg  [31:0] cpu_rdata,
    output reg         cpu_rready,

    input  wire        cpu_wvalid,
    input  wire [31:0] cpu_waddr,
    input  wire [31:0] cpu_wdata,
    output reg         cpu_wready
);


    `ifdef COCOTB_SIM
    initial begin
        `ifdef DUMP_VCD
        $display("COCOTB_SIM DUMP_VCD ENABLE");
        $dumpfile("./wave/PSC_SD_test.vcd");  // 出力するVCDファイル名
        $dumpvars(0);     // 第1引数: 階層 (0 はこのモジュールを最上位として)
        `else
        $display("COCOTB_SIM verilator FST ENABLE");
        $dumpfile("./wave/PSC_SD_test.fst");  // 出力するVCDファイル名
        $dumpvars(0);     // 第1引数: 階層 (0 はこのモジュールを最上位として)
        `endif
    end
    `endif

    wire    SD_CS_N;
    wire    SD_SCK;
    wire    SD_MOSI;
    wire    SD_MISO;

    PSC_SDCard u_sd (
        .clock          (clock),
        .reset_n        (reset_n),

        // CPU BUS
        .cpu_rvalid     (cpu_rvalid),
        .cpu_raddr      (cpu_raddr),
        .cpu_rdata      (cpu_rdata),
        .cpu_rready     (cpu_rready),

        .cpu_wvalid     (cpu_wvalid),
        .cpu_waddr      (cpu_waddr),
        .cpu_wdata      (cpu_wdata),
        .cpu_wready     (cpu_wready),

        // SD SPI
        .sd_cs_n        (SD_CS_N),
        .sd_sck         (SD_SCK),
        .sd_mosi        (SD_MOSI),
        .sd_miso        (SD_MISO)       // input
    );

    // ------------------------------
    // SDカード モデル
    // ------------------------------
    sdcard_spi_model #(
        .INIT_R1_IDLE (8'h01),          // CMD0/CMD8応答(Idle)
        .R1_READY     (8'h00),          // ready時
        .DATA_HEX     ("")              // ""なら固定パターン
    ) u_sd_model (
        .clock      (clock),
        .cs         (SD_CS_N),
        .sck        (SD_SCK),
        .mosi       (SD_MOSI),
        .miso       (SD_MISO)           // inout
    );

endmodule