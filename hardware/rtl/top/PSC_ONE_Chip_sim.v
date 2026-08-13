// NISHIHARU
`timescale 1ns / 1ps

// cocotb
`define COCOTB_SIM

// icarusの場合はdefine OS_SIM
//`define OS_SIM

// SDRAM_Model Debug log=ON
//`define SDRAM_Debug_log

module PSC_ONE_Chip_sim #(
    parameter integer ADDR_WIDTH   = 32,
    parameter integer ID_WIDTH     = 1,
    parameter integer DATA_WIDTH   = 16    // fixed 16
)(
    input  wire         clock,
    input  wire         rst,

    // ---- UART ----
    input  wire         uart_rx,
    output wire         uart_tx,

    // ---------------- PSC-ONE SW ----------------
    input wire          PSCONE_SW1,
    input wire          PSCONE_SW2,

    // ==== LED ====
    output wire [5:0]   led_out
);

    // --------------------------------
    // wave file
    // --------------------------------
    `ifdef COCOTB_SIM
    initial begin
        $display("COCOTB_SIM TOP ENABLE");
    end
    `ifdef TOP_SIM
    initial begin
        `ifdef DUMP_VCD
        $display("COCOTB_SIM TOP DUMP_VCD ENABLE");
        $dumpfile("./wave/PSC_ONE_Chip_test.vcd");
        $dumpvars(1, u_chip);
        $dumpvars(1, u_chip.u_lcd);
        $dumpvars(1, u_chip.u_i2s_if);
        $dumpvars(1, u_chip.u_mmap_led);
        $dumpvars(1, u_chip.u_dma);
        `else
        $display("COCOTB_SIM TOP verilator FST ENABLE");
        $dumpfile("./wave/PSC_ONE_Chip_test.fst");
        $dumpvars(1, u_chip);
        $dumpvars(1, u_chip.u_lcd);
        $dumpvars(1, u_chip.u_i2s_if);
        `endif
    end
    `endif
    `else
    initial begin
        $display("COCOTB_SIM TOP DISABLE");
    end
    `endif

    // internal pull-up(down)
    //pullup(SDI_MISO);

    // ------------------------------
    // DUT 本体
    // ------------------------------
    PSC_ONE_Chip #(
        `ifdef COCOTB_SIM
        .CLK_FREQ           (100)
        `else
        .CLK_FREQ           (80)
        `endif
    ) u_chip (
        .sys_clk             (clock),
        .sys_reset           (rst),

        // ---- UART ----
        .UART_RXD            (uart_rx),
        .UART_TXD            (uart_tx),

        // ---------------- PSC-ONE SW ----------------
        .PSCONE_SW1          (PSCONE_SW1),
        .PSCONE_SW2          (PSCONE_SW2),

        // ------------------ I2S ------------------
        .I2S_SCK             (I2S_SCK),
        .I2S_WS              (I2S_WS),
        .I2S_LR              (I2S_LR),
        .I2S_SD              (I2S_SD),

        // ---- SD-CARD I/F ----
        .SD_D3               (SDI_CS),
        .SD_CLK              (SDI_SCK),
        .SD_CMD              (SDI_MOSI),
        .SD_D0               (SDI_MISO),

        // ---- SDRAM pins ----
        .O_sdram_clk         (O_sdram_clk),
        .O_sdram_cke         (O_sdram_cke),
        .O_sdram_cs_n        (O_sdram_cs_n),
        .O_sdram_cas_n       (O_sdram_cas_n),
        .O_sdram_ras_n       (O_sdram_ras_n),
        .O_sdram_wen_n       (O_sdram_wen_n),

        .IO_sdram_dq         (IO_sdram_dq),
        .O_sdram_addr        (O_sdram_addr),
        .O_sdram_ba          (O_sdram_ba),
        .O_sdram_dqm         (O_sdram_dqm),

        // ---- LCD IF ----
        .PSCONE_LCD_CS       (tft_cs),
        .PSCONE_LCD_RST      (tft_rst),
        .PSCONE_LCD_BL       (tft_bl),
        .PSCONE_LCD_DC       (tft_dc), 
        .PSCONE_LCD_SCK      (tft_sck), 
        .PSCONE_LCD_SDI      (tft_sdi), 
        .PSCONE_LCD_SDO      (tft_sdo), 

        // ---- TP IF ----
        .PSCONE_TP_PEN       (1'b0),
        .PSCONE_TP_TDO       (1'b0),
        .PSCONE_TP_TDI       (),
        .PSCONE_TP_TCS       (),
        .PSCONE_TP_TCK       (),

        // ---- LED ----
        .PSCONE_LED_OUT      (led_out)
    );

    // LCD信号
    wire            tft_bl;
    wire            tft_sck;
    wire            tft_sdi;
    wire            tft_dc;
    wire            tft_cs;
    wire            tft_rst;
    wire            tft_sdo;

    // SDRAM信号
    wire            O_sdram_clk;
    wire            O_sdram_cke;
    wire            O_sdram_cs_n;
    wire            O_sdram_ras_n;
    wire            O_sdram_cas_n;
    wire            O_sdram_wen_n;
    wire [10:0]     O_sdram_addr;
    wire [1:0]      O_sdram_ba;
    wire [3:0]      O_sdram_dqm;  
    wire [31:0]     IO_sdram_dq;       // 32bit bus

    // SDカード信号
    wire            SDI_CS;
    wire            SDI_SCK;
    wire            SDI_MOSI;  
    wire            SDI_MISO;

    // I2S信号
    wire            I2S_SCK;
    wire            I2S_WS;
    wire            I2S_LR;
    wire            I2S_SD;

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
        .Cke        (1'b1),
        .Cs_n       (O_sdram_cs_n),
        .Ras_n      (O_sdram_ras_n),
        .Cas_n      (O_sdram_cas_n),
        .We_n       (O_sdram_wen_n),
        .Dqm        (O_sdram_dqm)
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
        .cs         (SDI_CS),
        .sck        (SDI_SCK),
        .mosi       (SDI_MOSI),
        .miso       (SDI_MISO)
    );

    // ------------------------------
    // LCD ILI9488モデル
    // ------------------------------
    PSC_LCD_ILI9488_MODEL #(
        .DATA_WIDTH     (32)
    ) u_lcd_model (
        .clock      (clock),
        .LCD_CS     (tft_cs),
        .LCD_RST    (tft_rst),
        .LCD_BL     (tft_bl),
        .LCD_DC     (tft_dc),
        .LCD_SCK    (tft_sck),
        .LCD_SDI    (tft_sdi),
        .LCD_SDO    (tft_sdo)
    );

    // ------------------------------
    // I2S MEMSマイクモデル
    // ------------------------------
    PSC_I2S_MIC_MODEL #(
        .DATA_WIDTH     (32)
    ) u_mic_model (
        .clock      (clock),
        .SCK_i      (I2S_SCK),
        .WS_i       (I2S_WS),
        .LR_i       (I2S_LR),
        .SD_o       (I2S_SD)
    );

endmodule