// NISHIHARU
// Verilog-2001版 ST7796 SPI ドライバ + framebuffer read request + reset_n対応
`timescale 1ns/1ps

/*
    // ------------------------------------------------------------
    // INIT_SEQ の内容を初期設定（これはFPGA合成可）
    // ------------------------------------------------------------
    
    // ili9341
    initial begin
        // --- (省略なしで以前と同じ内容) ---
        INIT_SEQ[0]  = {1'b0, 8'h28};
        INIT_SEQ[1]  = {1'b0, 8'hCF}; INIT_SEQ[2]  = {1'b1, 8'h00}; INIT_SEQ[3]  = {1'b1, 8'h83}; INIT_SEQ[4]  = {1'b1, 8'h30};
        INIT_SEQ[5]  = {1'b0, 8'hED}; INIT_SEQ[6]  = {1'b1, 8'h64}; INIT_SEQ[7]  = {1'b1, 8'h03}; INIT_SEQ[8]  = {1'b1, 8'h12}; INIT_SEQ[9]  = {1'b1, 8'h81};
        INIT_SEQ[10] = {1'b0, 8'hE8}; INIT_SEQ[11] = {1'b1, 8'h85}; INIT_SEQ[12] = {1'b1, 8'h01}; INIT_SEQ[13] = {1'b1, 8'h79};
        INIT_SEQ[14] = {1'b0, 8'hCB}; INIT_SEQ[15] = {1'b1, 8'h39}; INIT_SEQ[16] = {1'b1, 8'h2C}; INIT_SEQ[17] = {1'b1, 8'h00}; INIT_SEQ[18] = {1'b1, 8'h34}; INIT_SEQ[19] = {1'b1, 8'h02};
        INIT_SEQ[20] = {1'b0, 8'hF7}; INIT_SEQ[21] = {1'b1, 8'h20};
        INIT_SEQ[22] = {1'b0, 8'hEA}; INIT_SEQ[23] = {1'b1, 8'h00}; INIT_SEQ[24] = {1'b1, 8'h00};
        INIT_SEQ[25] = {1'b0, 8'hC0}; INIT_SEQ[26] = {1'b1, 8'h26};
        INIT_SEQ[27] = {1'b0, 8'hC1}; INIT_SEQ[28] = {1'b1, 8'h11};
        INIT_SEQ[29] = {1'b0, 8'hC5}; INIT_SEQ[30] = {1'b1, 8'h35}; INIT_SEQ[31] = {1'b1, 8'h3E};
        INIT_SEQ[32] = {1'b0, 8'hC7}; INIT_SEQ[33] = {1'b1, 8'hBE};
        INIT_SEQ[34] = {1'b0, 8'h3A}; INIT_SEQ[35] = {1'b1, 8'h55};
        INIT_SEQ[36] = {1'b0, 8'hB1}; INIT_SEQ[37] = {1'b1, 8'h00}; INIT_SEQ[38] = {1'b1, 8'h1B};
        INIT_SEQ[39] = {1'b0, 8'h26}; INIT_SEQ[40] = {1'b1, 8'h01};
        INIT_SEQ[41] = {1'b0, 8'h51}; INIT_SEQ[42] = {1'b1, 8'hFF};
        INIT_SEQ[43] = {1'b0, 8'hB7}; INIT_SEQ[44] = {1'b1, 8'h07};
        INIT_SEQ[45] = {1'b0, 8'hB6}; INIT_SEQ[46] = {1'b1, 8'h0A}; INIT_SEQ[47] = {1'b1, 8'h82}; INIT_SEQ[48] = {1'b1, 8'h27}; INIT_SEQ[49] = {1'b1, 8'h00};
        INIT_SEQ[50] = {1'b0, 8'h29};
        INIT_SEQ[51] = {1'b0, 8'h2C};
    end
*/

/*
    // Software Reset
    assign INIT_SEQ[0] = {1'b0,8'h01};

    // NOP
    assign INIT_SEQ[1] = {1'b0,8'h00};

    // Pixel Format = RGB666
    assign INIT_SEQ[2] = {1'b0,8'h3A};
`ifdef RGB111_mode
    assign INIT_SEQ[3] = {1'b1,8'h01};
`else
    assign INIT_SEQ[3] = {1'b1,8'h66};
`endif

    // Memory Access Control
    assign INIT_SEQ[4] = {1'b0,8'h36};
    //assign INIT_SEQ[5] = {1'b1,8'h48};
    assign INIT_SEQ[5] = {1'b1,8'hC8};

    // Sleep Out
    assign INIT_SEQ[6] = {1'b0,8'h11};

    // Display ON
    assign INIT_SEQ[7] = {1'b0,8'h29};

    // Column Address Set
    assign INIT_SEQ[8]  = {1'b0,8'h2A};
    assign INIT_SEQ[9]  = {1'b1, {7'd0, x_start_pos[8]}};
    assign INIT_SEQ[10] = {1'b1, x_start_pos[7:0]};
    assign INIT_SEQ[11] = {1'b1, {7'd0, x_end_pos[8]}};    // 0x001F = 31
    assign INIT_SEQ[12] = {1'b1, x_end_pos[7:0]};

    //assign INIT_SEQ[9]  = {1'b1,8'h01};    // 0x013F = 319
    //assign INIT_SEQ[10] = {1'b1,8'h3F};

    // Row Address Set
    assign INIT_SEQ[13] = {1'b0,8'h2B};
    assign INIT_SEQ[14] = {1'b1, {7'd0, y_start_pos[8]}};
    assign INIT_SEQ[15] = {1'b1, y_start_pos[7:0]};
    assign INIT_SEQ[16] = {1'b1, {7'd0, y_end_pos[8]}};
    assign INIT_SEQ[17] = {1'b1, y_end_pos[7:0]};    // 0x003F = 31

    //assign INIT_SEQ[14] = {1'b1,8'h01};
    //assign INIT_SEQ[15] = {1'b1,8'hDF};    // 0x01DF = 479

    // Memory Write
    assign INIT_SEQ[18] = {1'b0,8'h2C};
*/


`define RGB111_mode

module tft_ili9488 #(
    parameter integer  INPUT_CLK_MHZ     = 100
)(
    input  wire        clock,
    input  wire        reset_n,     // Input

    // SPI
    input  wire        tft_sdo,     // 現状未使用 (MISO)
    output wire        tft_sck,
    output wire        tft_sdi,
    output wire        tft_dc,
    output wire        tft_cs,
    output wire        spi_idle,

    // CPU-IF
    input  wire        cpu_if_valid,
    output reg         cpu_if_ready,
    input  wire [8:0]  cpu_if_data
);

    reg     dataAvailable;

    // ------------------------------------------------------------
    // SPIインターフェース制御側レジスタ
    // ------------------------------------------------------------
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            cpu_if_ready  <= 1'b0;
            dataAvailable <= 1'b0;
        end else begin
            // default
            cpu_if_ready  <= 1'b0;

            if (cpu_if_valid) begin
                cpu_if_ready  <= 1'b1;
                dataAvailable <= 1'b1;
            end else if (~spi_idle) begin
                dataAvailable <= 1'b0;
            end
        end
    end

    // SPIサブモジュール
    tft_ili9488_spi spi (
        .spiClk        (clock),
        .data          (cpu_if_data),
        .dataAvailable (cpu_if_valid),
        .tft_sck       (tft_sck),
        .tft_sdi       (tft_sdi),
        .tft_dc        (tft_dc),
        .tft_cs        (tft_cs),
        .idle          (spi_idle)
    );


endmodule
