`define LCD_display_off

module PSC_LCD_ILI9488_MODEL #(
    parameter DATA_WIDTH = 32,
    parameter ID_BYTE0   = 8'h00,
    parameter ID_BYTE1   = 8'h94,
    parameter ID_BYTE2   = 8'h88
)(
    input  wire         clock,

    // ---------------- LCD ----------------
    input  wire         LCD_CS,
    input  wire         LCD_RST,
    input  wire         LCD_BL,
    input  wire         LCD_DC,
    input  wire         LCD_SCK,
    input  wire         LCD_SDI,
    output wire         LCD_SDO
);

    // ============================================================
    // Reset pulse width monitor
    // ============================================================
    integer rst_low_count;

    initial begin
        rst_low_count = 0;
    end

    always @(posedge clock) begin
        if (LCD_RST == 1'b0) begin
            rst_low_count <= rst_low_count + 1;
        end else begin
            if (rst_low_count != 0) begin
                `ifndef LCD_display_off
                $display("[ILI9488_MODEL] RST low pulse width = %0d clock cycles", rst_low_count);
                `endif
                rst_low_count <= 0;
            end
        end
    end

    // ============================================================
    // SPI receive monitor
    // Mode assumption:
    //   - sample MOSI at posedge LCD_SCK
    //   - MSB first
    //   - LCD_CS active low
    // ============================================================
    reg [7:0] rx_shift;
    reg [2:0] rx_bit_count;
    reg [7:0] rx_byte;

    reg [7:0] last_cmd;

    initial begin
        rx_shift     = 8'h00;
        rx_bit_count = 3'd0;
        rx_byte      = 8'h00;
        last_cmd     = 8'h00;
    end

    always @(posedge LCD_SCK or posedge LCD_CS) begin
        if (LCD_CS) begin
            rx_shift     <= 8'h00;
            rx_bit_count <= 3'd0;
        end else begin
            rx_shift <= {rx_shift[6:0], LCD_SDI};

            if (rx_bit_count == 3'd7) begin
                rx_byte <= {rx_shift[6:0], LCD_SDI};

                if (LCD_DC == 1'b0) begin
                    last_cmd <= {rx_shift[6:0], LCD_SDI};
                    `ifndef LCD_display_off
                    $display("[ILI9488_MODEL] SPI CMD  = 0x%02h", {rx_shift[6:0], LCD_SDI});
                    `endif
                end else begin
                    `ifndef LCD_display_off
                    $display("[ILI9488_MODEL] SPI DATA = 0x%02h  after CMD=0x%02h",
                             {rx_shift[6:0], LCD_SDI}, last_cmd);
                    `endif
                end

                rx_bit_count <= 3'd0;
            end else begin
                rx_bit_count <= rx_bit_count + 3'd1;
            end
        end
    end

    // ============================================================
    // Read Display ID response
    //
    // ILI9488 command:
    //   0x04 : Read Display ID
    //
    // This simple model returns:
    //   dummy 0x00, ID_BYTE0, ID_BYTE1, ID_BYTE2
    //
    // For many test purposes:
    //   00 00 94 88
    // or
    //   00 94 88
    // is enough.
    // ============================================================
    reg [31:0] id_shift;
    reg [5:0]  id_bit_count;
    reg        id_read_active;
    reg        sdo_reg;

    assign LCD_SDO = sdo_reg;

    initial begin
        id_shift       = {8'h00, ID_BYTE0, ID_BYTE1, ID_BYTE2};
        id_bit_count   = 6'd0;
        id_read_active = 1'b0;
        sdo_reg        = 1'b0;
    end

    // 0x04 command received -> prepare SDO response
    always @(negedge LCD_SCK or posedge LCD_CS) begin
        if (LCD_CS) begin
            id_read_active <= 1'b0;
            id_bit_count   <= 6'd0;
            id_shift       <= {8'h00, ID_BYTE0, ID_BYTE1, ID_BYTE2};
            sdo_reg        <= 1'b0;
        end else begin
            if (last_cmd == 8'h04) begin
                id_read_active <= 1'b1;
            end

            if (id_read_active) begin
                sdo_reg      <= id_shift[31];
                id_shift     <= {id_shift[30:0], 1'b0};
                id_bit_count <= id_bit_count + 6'd1;

                if (id_bit_count == 6'd31) begin
                    id_read_active <= 1'b0;
                    id_bit_count   <= 6'd0;
                    id_shift       <= {8'h00, ID_BYTE0, ID_BYTE1, ID_BYTE2};
                end
            end
        end
    end

endmodule