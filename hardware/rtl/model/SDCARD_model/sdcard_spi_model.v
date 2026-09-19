`timescale 1ns/1ps

// Minimal SDHC card model for SPI-mode simulations.
//
// Supported commands:
//   CMD0, CMD8, CMD17, CMD24, CMD55, ACMD41 and CMD58
//
// Command frames and write-data frames are parsed independently so arbitrary
// values in a 512-byte payload can never be mistaken for SD commands.
module sdcard_spi_model #(
    parameter [7:0] INIT_R1_IDLE = 8'h01,
    parameter [7:0] R1_READY     = 8'h00,
    parameter       DATA_HEX     = "",
    parameter integer STORED_SECTORS = 4,
    parameter integer ACMD41_IDLE_RESPONSES = 1
)(
    input  wire clock,
    input  wire cs,     // active low
    input  wire sck,
    input  wire mosi,
    inout  tri  miso
);

    localparam [2:0]
        WRITE_IDLE       = 3'd0,
        WRITE_WAIT_TOKEN = 3'd1,
        WRITE_DATA       = 3'd2,
        WRITE_CRC1       = 3'd3,
        WRITE_CRC2       = 3'd4;

    // MISO is released while the card is not selected.  While selected, an
    // empty response queue reads as the normal SPI idle value (logic one).
    reg miso_bit;
    assign miso = cs ? 1'bz : miso_bit;

    // Synchronize the externally generated SPI pins to the model clock.
    reg sck_q0, sck_q1;
    reg cs_q0,  cs_q1;

    wire pos_sck  =  sck_q0 & ~sck_q1;
    wire neg_sck  = ~sck_q0 &  sck_q1;
    wire cs_rise  =  cs_q0  & ~cs_q1;
    wire cs_fall  = ~cs_q0  &  cs_q1;
    wire selected = ~cs_q0;

    always @(posedge clock) begin
        sck_q0 <= sck;
        sck_q1 <= sck_q0;
        cs_q0  <= cs;
        cs_q1  <= cs_q0;
    end

    // DATA_HEX, when supplied, describes one default 512-byte sector.
    reg [7:0] sector_data [0:511];

    // A small tagged backing store is enough for controller tests while still
    // checking that the full 32-bit SDHC LBA is decoded.
    reg [7:0]  stored_data  [0:STORED_SECTORS*512-1];
    reg [31:0] stored_lba   [0:STORED_SECTORS-1];
    reg        stored_valid [0:STORED_SECTORS-1];
    reg [7:0]  write_buffer [0:511];
    integer replace_slot;

    // Largest response: R1, delay, token, one block and CRC.
    reg [7:0] resp_mem [0:1023];
    integer resp_wp;
    integer resp_rp;

    task resp_clear;
        begin
            resp_wp = 0;
            resp_rp = 0;
        end
    endtask

    task resp_push;
        input [7:0] value;
        begin
            if (resp_wp < 1024) begin
                resp_mem[resp_wp] = value;
                resp_wp = resp_wp + 1;
            end
        end
    endtask

    function [15:0] crc16_byte;
        input [15:0] crc_in;
        input [7:0]  data_in;
        reg [15:0] crc;
        integer bit_index;
        begin
            crc = crc_in ^ {data_in, 8'h00};
            for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
                if (crc[15])
                    crc = (crc << 1) ^ 16'h1021;
                else
                    crc = crc << 1;
            end
            crc16_byte = crc;
        end
    endfunction

    // Card/protocol state.  Counters remain visible for waveform diagnostics.
    reg        ready;
    reg        app_cmd_seen;
    integer    acmd41_count;
    reg [2:0]  write_state;
    reg [31:0] pending_write_lba;
    integer    write_byte_count;
    reg [7:0]  received_crc1;
    reg [7:0]  received_crc2;

    reg [31:0] last_cmd_arg;
    reg [7:0]  last_cmd;
    integer    command_count;
    integer    read_count;
    integer    write_count;

    // RX byte and command-frame assembly.
    reg [7:0] rx_shift;
    reg [2:0] rx_bitcnt;
    reg       command_active;
    reg [2:0] command_byte_count;
    reg [7:0] cmd0, cmd1, cmd2, cmd3, cmd4, cmd5;
    reg [7:0] rx_byte;
    reg [31:0] command_arg;

    // TX serializer (SPI mode 0: update MISO on falling SCK).
    reg [7:0] tx_shift;
    reg [2:0] tx_bitcnt;
    reg       tx_active;

    integer i;
    integer slot;
    integer match_slot;
    integer free_slot;
    reg [15:0] read_crc;
    reg [7:0] read_data_byte;

    initial begin
        sck_q0 = 1'b0;
        sck_q1 = 1'b0;
        cs_q0  = 1'b1;
        cs_q1  = 1'b1;
        miso_bit = 1'b1;

        ready = 1'b0;
        app_cmd_seen = 1'b0;
        acmd41_count = 0;
        write_state = WRITE_IDLE;
        pending_write_lba = 32'h0;
        write_byte_count = 0;
        received_crc1 = 8'h0;
        received_crc2 = 8'h0;

        last_cmd_arg = 32'h0;
        last_cmd = 8'hFF;
        command_count = 0;
        read_count = 0;
        write_count = 0;

        rx_shift = 8'hFF;
        rx_bitcnt = 3'd7;
        command_active = 1'b0;
        command_byte_count = 3'd0;
        cmd0 = 8'hFF;
        cmd1 = 8'h00;
        cmd2 = 8'h00;
        cmd3 = 8'h00;
        cmd4 = 8'h00;
        cmd5 = 8'hFF;

        tx_shift = 8'hFF;
        tx_bitcnt = 3'd7;
        tx_active = 1'b0;
        resp_wp = 0;
        resp_rp = 0;
        replace_slot = 0;

        for (i = 0; i < 512; i = i + 1) begin
            sector_data[i] = i[7:0];
            write_buffer[i] = 8'h00;
        end
        if (DATA_HEX != "")
            $readmemh(DATA_HEX, sector_data);

        for (slot = 0; slot < STORED_SECTORS; slot = slot + 1) begin
            stored_lba[slot] = 32'h0;
            stored_valid[slot] = 1'b0;
            for (i = 0; i < 512; i = i + 1)
                stored_data[slot*512+i] = 8'h00;
        end
    end

    always @(posedge clock) begin
        if (cs_rise || cs_fall) begin
            resp_clear();
            rx_bitcnt = 3'd7;
            command_active = 1'b0;
            command_byte_count = 3'd0;
            tx_active = 1'b0;
            tx_bitcnt = 3'd7;
            miso_bit = 1'b1;

            // A partial data block is aborted when CS is deasserted.
            if (cs_rise && (write_state != WRITE_IDLE)) begin
                write_state = WRITE_IDLE;
                write_byte_count = 0;
            end
        end else begin
            // RX: sample MOSI on rising SCK.
            if (selected && pos_sck) begin
                rx_shift[rx_bitcnt] = mosi;

                if (rx_bitcnt == 3'd0) begin
                    rx_byte = {rx_shift[7:1], mosi};
                    rx_bitcnt = 3'd7;

                    // After CMD24, data is parsed separately from commands.
                    case (write_state)
                        WRITE_WAIT_TOKEN: begin
                            if (rx_byte == 8'hFE) begin
                                write_byte_count = 0;
                                write_state = WRITE_DATA;
                            end
                        end

                        WRITE_DATA: begin
                            write_buffer[write_byte_count] = rx_byte;
                            if (write_byte_count == 511)
                                write_state = WRITE_CRC1;
                            else
                                write_byte_count = write_byte_count + 1;
                        end

                        WRITE_CRC1: begin
                            received_crc1 = rx_byte;
                            write_state = WRITE_CRC2;
                        end

                        WRITE_CRC2: begin
                            received_crc2 = rx_byte;

                            match_slot = -1;
                            free_slot = -1;
                            for (slot = 0; slot < STORED_SECTORS; slot = slot + 1) begin
                                if (stored_valid[slot] &&
                                    (stored_lba[slot] == pending_write_lba))
                                    match_slot = slot;
                                if (!stored_valid[slot] && (free_slot < 0))
                                    free_slot = slot;
                            end

                            if (match_slot >= 0)
                                slot = match_slot;
                            else if (free_slot >= 0)
                                slot = free_slot;
                            else begin
                                slot = replace_slot;
                                if (replace_slot == (STORED_SECTORS - 1))
                                    replace_slot = 0;
                                else
                                    replace_slot = replace_slot + 1;
                            end

                            stored_lba[slot] = pending_write_lba;
                            stored_valid[slot] = 1'b1;
                            for (i = 0; i < 512; i = i + 1)
                                stored_data[slot*512+i] = write_buffer[i];

                            write_count = write_count + 1;
                            write_state = WRITE_IDLE;
                            write_byte_count = 0;

                            // Data accepted, followed by a finite busy period.
                            resp_clear();
                            resp_push(8'h05);
                            resp_push(8'h00);
                            resp_push(8'h00);
                            resp_push(8'h00);
                            resp_push(8'hFF);
                            tx_active = 1'b0;
                        end

                        default: begin
                            // SD command start bits are 01. Idle 0xFF bytes are
                            // ignored and cannot desynchronize command parsing.
                            if (!command_active) begin
                                if (rx_byte[7:6] == 2'b01) begin
                                    command_active = 1'b1;
                                    command_byte_count = 3'd1;
                                    cmd0 = rx_byte;
                                end
                            end else begin
                                case (command_byte_count)
                                    3'd1: cmd1 = rx_byte;
                                    3'd2: cmd2 = rx_byte;
                                    3'd3: cmd3 = rx_byte;
                                    3'd4: cmd4 = rx_byte;
                                    3'd5: cmd5 = rx_byte;
                                    default: cmd5 = rx_byte;
                                endcase

                                if (command_byte_count == 3'd5) begin
                                    command_active = 1'b0;
                                    command_byte_count = 3'd0;
                                    command_arg = {cmd1, cmd2, cmd3, cmd4};
                                    last_cmd = cmd0;
                                    last_cmd_arg = command_arg;
                                    command_count = command_count + 1;

                                    resp_clear();
                                    tx_active = 1'b0;

                                    case (cmd0)
                                        8'h40: begin // CMD0: GO_IDLE_STATE
                                            ready = 1'b0;
                                            app_cmd_seen = 1'b0;
                                            acmd41_count = 0;
                                            write_state = WRITE_IDLE;
                                            resp_push(INIT_R1_IDLE);
                                        end

                                        8'h48: begin // CMD8: SEND_IF_COND
                                            resp_push(INIT_R1_IDLE);
                                            resp_push(8'h00);
                                            resp_push(8'h00);
                                            resp_push(cmd3);
                                            resp_push(cmd4);
                                        end

                                        8'h77: begin // CMD55: APP_CMD
                                            app_cmd_seen = 1'b1;
                                            resp_push(ready ? R1_READY : INIT_R1_IDLE);
                                        end

                                        8'h69: begin // ACMD41: SD_SEND_OP_COND
                                            if (!app_cmd_seen) begin
                                                resp_push(ready ? 8'h04 : 8'h05);
                                            end else if (acmd41_count < ACMD41_IDLE_RESPONSES) begin
                                                acmd41_count = acmd41_count + 1;
                                                resp_push(INIT_R1_IDLE);
                                            end else begin
                                                ready = 1'b1;
                                                resp_push(R1_READY);
                                            end
                                            app_cmd_seen = 1'b0;
                                        end

                                        8'h7A: begin // CMD58: READ_OCR
                                            resp_push(ready ? R1_READY : INIT_R1_IDLE);
                                            resp_push(8'h40); // CCS=1: SDHC/SDXC
                                            resp_push(8'h00);
                                            resp_push(8'h00);
                                            resp_push(8'h00);
                                        end

                                        8'h51: begin // CMD17: READ_SINGLE_BLOCK
                                            if (!ready) begin
                                                resp_push(8'h05);
                                            end else begin
                                                read_count = read_count + 1;
                                                resp_push(R1_READY);
                                                // The controller's ST_WAIT_R1
                                                // state always clocks six bytes
                                                // before entering token wait.
                                                for (i = 0; i < 8; i = i + 1)
                                                    resp_push(8'hFF);
                                                resp_push(8'hFE);

                                                match_slot = -1;
                                                for (slot = 0; slot < STORED_SECTORS; slot = slot + 1)
                                                    if (stored_valid[slot] &&
                                                        (stored_lba[slot] == command_arg))
                                                        match_slot = slot;

                                                read_crc = 16'h0000;
                                                for (i = 0; i < 512; i = i + 1) begin
                                                    if (match_slot >= 0)
                                                        read_data_byte = stored_data[match_slot*512+i];
                                                    else
                                                        read_data_byte = sector_data[i];
                                                    resp_push(read_data_byte);
                                                    read_crc = crc16_byte(read_crc, read_data_byte);
                                                end
                                                resp_push(read_crc[15:8]);
                                                resp_push(read_crc[7:0]);
                                            end
                                        end

                                        8'h58: begin // CMD24: WRITE_BLOCK
                                            if (!ready) begin
                                                resp_push(8'h05);
                                            end else begin
                                                pending_write_lba = command_arg;
                                                write_state = WRITE_WAIT_TOKEN;
                                                resp_push(R1_READY);
                                            end
                                        end

                                        default: begin
                                            // R1 illegal-command bit.
                                            resp_push(ready ? 8'h04 : 8'h05);
                                            app_cmd_seen = 1'b0;
                                        end
                                    endcase
                                end else begin
                                    command_byte_count = command_byte_count + 1;
                                end
                            end
                        end
                    endcase
                end else begin
                    rx_bitcnt = rx_bitcnt - 1'b1;
                end
            end

            // TX: update MISO on falling SCK.
            if (selected && neg_sck) begin
                if (!tx_active) begin
                    if (resp_rp < resp_wp) begin
                        tx_shift = resp_mem[resp_rp];
                        tx_bitcnt = 3'd7;
                        tx_active = 1'b1;
                        miso_bit = resp_mem[resp_rp][7];
                    end else begin
                        miso_bit = 1'b1;
                    end
                end else if (tx_bitcnt == 3'd0) begin
                    resp_rp = resp_rp + 1;
                    if (resp_rp < resp_wp) begin
                        tx_shift = resp_mem[resp_rp];
                        tx_bitcnt = 3'd7;
                        miso_bit = resp_mem[resp_rp][7];
                    end else begin
                        tx_active = 1'b0;
                        miso_bit = 1'b1;
                    end
                end else begin
                    miso_bit = tx_shift[tx_bitcnt - 1'b1];
                    tx_bitcnt = tx_bitcnt - 1'b1;
                end
            end
        end
    end

endmodule
