`timescale 1ns/1ps

module PSC_SDCard_SPI #(
    parameter INIT_SCK_DIV = 125,
    parameter FAST_SCK_DIV = 12
)(
    input  wire        clock,
    input  wire        reset_n,

    input  wire        sck_fast_mode,
    input  wire        sck_cs_high,

    // SPI DATA
    input  wire        spi_tx_data_valid,
    input  wire [7:0]  spi_tx_data,
    input  wire        spi_tx_start,
    output reg  [7:0]  spi_rx_data,
    output wire        spi_busy,

    // SD SPI
    output reg         CS_N,
    output reg         SCK,
    output reg         MOSI,
    input  wire        MISO
);

    // clock divider
    reg [15:0] sck_div;

    always @(*) begin
        if (sck_fast_mode)
            sck_div = FAST_SCK_DIV;
        else
            sck_div = INIT_SCK_DIV;
    end

    // SPI engine
    reg [15:0] divcnt;
    reg [2:0]  bitcnt;
    reg        spi_active;

    reg [7:0] sh_tx;
    reg [7:0] sh_rx;

    reg sck_d1;

    wire pos_sck = ~sck_d1 & SCK;
    wire neg_sck =  sck_d1 & ~SCK;

    assign spi_busy = spi_active;

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin

            CS_N <= 1'b1;
            SCK  <= 1'b0;
            MOSI <= 1'b1;

            divcnt <= 16'd0;
            bitcnt <= 3'd0;

            spi_active <= 1'b0;
            sh_tx <= 8'hFF;
            sh_rx <= 8'h00;
            spi_rx_data <= 8'h00;

            sck_d1 <= 1'b0;

        end else begin

            sck_d1 <= SCK;

            // ----------------------------
            // start transfer
            if (spi_tx_start && !spi_active) begin
                // SPI start
                spi_active <= 1'b1;
                bitcnt     <= 3'd7;
                sh_tx      <= spi_tx_data;
                sh_rx      <= 8'h00;
            end

            if (spi_tx_data_valid) begin
                sh_tx      <= spi_tx_data;
                // INIT SCK 
                if (sck_cs_high) 
                    CS_N       <= 1'b1;
                else
                    CS_N       <= 1'b0;
            end

            // ----------------------------
            // clock generator
            if (spi_active) begin
                if (divcnt == (sck_div - 16'd1)) begin
                    divcnt <= 16'd0;
                    SCK    <= ~SCK;
                end else begin
                    divcnt <= divcnt + 16'd1;
                end
            end else begin
                divcnt <= 16'd0;
                SCK    <= 1'b0;
            end

            // ----------------------------
            // shift logic
            if (spi_active) begin

                // rising edge sample
                if (pos_sck)
                    sh_rx[bitcnt] <= MISO;

                // falling edge shift
                if (neg_sck) begin
                    if (bitcnt == 3'd0) begin
                        spi_active  <= 1'b0;
                        spi_rx_data <= sh_rx;
                    end else begin
                        bitcnt <= bitcnt - 3'd1;
                    end
                end

                // drive MOSI
                if (SCK == 1'b0)
                    MOSI <= sh_tx[bitcnt];

            end
        end
    end

endmodule
