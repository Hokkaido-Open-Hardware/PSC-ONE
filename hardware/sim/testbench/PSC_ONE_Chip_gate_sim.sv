// Board-level harness for the unmodified Gowin PSC_ONE.vg netlist.
// Keep this source before GW2AR_sdram.v, which inherits its timescale.
`timescale 1ns/1ps
module PSC_ONE_Chip_gate_sim #(
    parameter real CLOCK_PERIOD_NS = 37.038,
    parameter real SDRAM_TAC_NS = 5.4,
    parameter real SDRAM_TOH_NS = 3.0
)(
    input wire rst,
    input wire uart_rx,
    output wire uart_tx,
    output wire [5:0] led_out
);
    reg clock = 0;
    always #(CLOCK_PERIOD_NS / 2.0) clock = ~clock;

    wire sdram_clk, sdram_cke, sdram_cs_n, sdram_ras_n;
    wire sdram_cas_n, sdram_wen_n;
    wire [10:0] sdram_addr;
    wire [1:0] sdram_ba;
    wire [3:0] sdram_dqm;
    wire [31:0] sdram_dq;
    wire sd_cs, sd_sck, sd_mosi;
    tri1 sd_miso;
    tri1 i2c_scl, i2c_sda;

    // No CLK_FREQ parameter or RTL defines: the synthesis result is the DUT.
    PSC_ONE_Chip u_chip (
        .sys_clk(clock), .sys_reset(rst),
        .UART_RXD(uart_rx), .UART_TXD(uart_tx),
        .PSCONE_SW1(1'b1), .PSCONE_SW2(1'b1),
        .I2S_SCK(), .I2S_WS(), .I2S_LR(), .I2S_SD(1'b0),
        .SD_D3(sd_cs), .SD_CLK(sd_sck), .SD_CMD(sd_mosi), .SD_D0(sd_miso),
        .O_sdram_clk(sdram_clk), .O_sdram_cke(sdram_cke),
        .O_sdram_cs_n(sdram_cs_n), .O_sdram_ras_n(sdram_ras_n),
        .O_sdram_cas_n(sdram_cas_n), .O_sdram_wen_n(sdram_wen_n),
        .O_sdram_addr(sdram_addr), .O_sdram_ba(sdram_ba),
        .O_sdram_dqm(sdram_dqm), .IO_sdram_dq(sdram_dq),
        .PSCONE_LCD_CS(), .PSCONE_LCD_RST(), .PSCONE_LCD_BL(),
        .PSCONE_LCD_DC(), .PSCONE_LCD_SCK(), .PSCONE_LCD_SDI(),
        .PSCONE_LCD_SDO(1'b0), .PSCONE_TP_PEN(1'b1), .PSCONE_TP_TDO(1'b0),
        .PSCONE_TP_TDI(), .PSCONE_TP_TCS(), .PSCONE_TP_TCK(),
        .PSCONE_LV3(i2c_scl), .PSCONE_LV4(i2c_sda), .PSCONE_LED_OUT(led_out)
    );

    // Model-only timing override for diagnostics; default matches the model.
    GW2AR_sdram #(.tAC(SDRAM_TAC_NS), .tOH(SDRAM_TOH_NS)) u_sdram_model (
        .Dq(sdram_dq), .Addr(sdram_addr), .Ba(sdram_ba),
        .Clk(sdram_clk), .Cke(sdram_cke), .Cs_n(sdram_cs_n),
        .Ras_n(sdram_ras_n), .Cas_n(sdram_cas_n), .We_n(sdram_wen_n),
        .Dqm(sdram_dqm)
    );

    // The card model synchronizes SPI pins. Sample faster than the PLL-driven
    // SPI clock; the board's 27 MHz input is too slow for high-speed transfers.
    reg card_clock = 0;
    always #2 card_clock = ~card_clock;
    sdcard_spi_model #(.IMAGE_HEX("sdcard/sdcard.hex")) u_sd_model (
        .clock(card_clock), .cs(sd_cs), .sck(sd_sck),
        .mosi(sd_mosi), .miso(sd_miso)
    );

    // Observable board activity, independent of synthesized hierarchy names.
    integer sdram_clock_edges = 0;
    integer sdram_commands = 0;
    always @(posedge sdram_clk) begin
        sdram_clock_edges <= sdram_clock_edges + 1;
        if (sdram_cke && !sdram_cs_n &&
            {sdram_ras_n, sdram_cas_n, sdram_wen_n} != 3'b111)
            sdram_commands <= sdram_commands + 1;
    end

`ifdef DUMP_FST
    initial begin
        $dumpfile("wave/PSC_ONE_Chip_gate.fst");
        // Pin-level trace avoids dumping millions of memory locations.
        $dumpvars(1, PSC_ONE_Chip_gate_sim);
    end
`endif
endmodule
