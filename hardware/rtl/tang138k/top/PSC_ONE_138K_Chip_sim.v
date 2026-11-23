// NISHIHARU
`timescale 1ns / 1ps

// cocotb
`define COCOTB_SIM

// icarusの場合はdefine PSCOS_SIM
//`define PSCOS_SIM

// SDRAM_Model Debug log=ON
//`define SDRAM_Debug_log

module PSC_ONE_138K_Chip_sim #(
    parameter integer ADDR_WIDTH   = 32,
    parameter integer ID_WIDTH     = 1,
    parameter integer DATA_WIDTH   = 16    // fixed 16
)(
    input  wire         clock,
    input  wire         rst,

    // ---- UART ----
    input  wire         uart_rx,
    output wire         uart_tx,

    // ---- I2C ----
    inout  wire         PSCONE_SCL,
    `ifdef PSC_ROBOT_SIM
    input  wire         i2c_master_sda_low,
    output wire         i2c_sda_bus,
    `else
    inout  wire         PSCONE_SDA,
    `endif

    // ---------------- PSC-ONE SW ----------------
    input wire          PSCONE_SW1,
    input wire          PSCONE_SW2,

    // ==== LED ====
    output wire [7:0]   led_out
);

    `ifdef PSC_ROBOT_SIM
    // External pull-up and master open-drain driver, resolved with the chip.
    tri1 PSCONE_SDA;
    assign PSCONE_SDA = i2c_master_sda_low ? 1'b0 : 1'bz;
    assign i2c_sda_bus = PSCONE_SDA;
    `endif

    // --------------------------------
    // wave file
    // --------------------------------
    `ifdef COCOTB_SIM
    initial begin
        $display("========================");
        $display("COCOTB_SIM TOP ENABLE");
    end
    `ifdef TOP_SIM
    initial begin
        `ifdef DUMP_VCD
        $display("COCOTB_SIM TOP DUMP_VCD ENABLE");
        $dumpfile("./wave/PSC_ONE_138K_Chip_test.vcd");
        $dumpvars(1, u_chip);
        $dumpvars(0, u_chip.u_soc);
        `endif
        `ifdef DUMP_FST
        $display("COCOTB_SIM TOP verilator FST ENABLE");
        $dumpfile("./wave/PSC_ONE_138K_Chip_test.fst");
        $dumpvars(1, u_chip);
        $dumpvars(0, u_chip.u_soc);
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
    PSC_ONE_138K_Chip #(
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

        .gpio_uart_rx        (),
        .gpio_uart_tx        (),

        // ---- HDMI ----
        .tmds_d_p_0          (),
        .tmds_d_n_0          (),
        .tmds_clk_p_0        (),
        .tmds_clk_n_0        (),

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

        // DDR3 app memory is inside the chip in simulation.
        .ddr_addr(), .ddr_bank(), .ddr_cs(), .ddr_ras(), .ddr_cas(), .ddr_we(),
        .ddr_ck(), .ddr_ck_n(), .ddr_cke(), .ddr_odt(), .ddr_reset_n(),
        .ddr_dm(), .ddr_dq(), .ddr_dqs(), .ddr_dqs_n(),

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

        // ---- Robot ----
        .PSCONE_LV1          (),  // inout
        .PSCONE_LV2          (),  // inout
        .PSCONE_LV3          (PSCONE_SCL),  // inout
        .PSCONE_LV4          (PSCONE_SDA),  // inout

        // ---- LED ----
        .led                 (led_out)
    );

    // LCD信号
    wire            tft_bl;
    wire            tft_sck;
    wire            tft_sdi;
    wire            tft_dc;
    wire            tft_cs;
    wire            tft_rst;
    wire            tft_sdo;

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
    // SDカード モデル
    // ------------------------------
`ifdef PSCOS_NO_SDCARD
    // Direct ROM boot must work without an SD image or a card attached.
    assign SDI_MISO = 1'b1;
`else
    sdcard_spi_model #(
        .INIT_R1_IDLE (8'h01),          // CMD0/CMD8応答(Idle)
        .R1_READY     (8'h00),          // ready時
        .IMAGE_HEX    ("sdcard/sdcard.hex") // Makefile.sdcardで生成するカード全体
    ) u_sd_model (
        .clock      (clock),
        .cs         (SDI_CS),
        .sck        (SDI_SCK),
        .mosi       (SDI_MOSI),
        .miso       (SDI_MISO)
    );
`endif

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
