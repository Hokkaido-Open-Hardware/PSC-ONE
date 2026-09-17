`timescale 1ns/1ps

module sdcard_spi_model #(
    parameter [7:0] INIT_R1_IDLE = 8'h01,
    parameter [7:0] R1_READY     = 8'h00,
    parameter       DATA_HEX     = ""
)(
    input  wire clock,
    input  wire cs,     // active low
    input  wire sck,
    input  wire mosi,
    inout  tri  miso
);

    //============================================================
    // MISO tri-state driver (TX only writer)
    //============================================================
    reg miso_en;
    reg miso_bit;
    assign miso = miso_en ? miso_bit : 1'bz;

    //============================================================
    // 2-FF Synchronizer
    //============================================================
    reg sck_q0, sck_q1;
    reg cs_q0,  cs_q1;

    always @(posedge clock) begin
        sck_q0 <= sck;
        sck_q1 <= sck_q0;
        cs_q0  <= cs;
        cs_q1  <= cs_q0;
    end

    wire pos_sck =  sck_q0 & ~sck_q1;
    wire neg_sck = ~sck_q0 &  sck_q1;
    wire cs_rise =  cs_q0  & ~cs_q1;
    wire cs_fall = ~cs_q0  &  cs_q1;
    wire selected = ~cs_q0;

    //============================================================
    // Sector data (dummy)
    //============================================================
    reg [7:0] sector_data [0:511];
    integer i;

    initial begin
        for (i = 0; i < 512; i = i + 1)
            sector_data[i] = i[7:0];

        if (DATA_HEX != "")
            $readmemh(DATA_HEX, sector_data);
    end

    //============================================================
    // Response FIFO
    //============================================================
    reg [7:0] resp_mem [0:2047];
    integer resp_wp;
    integer resp_rp;

    reg resp_wp_reset;

    task resp_reset;
        begin
            resp_wp_reset = 1;
            resp_wp = 0;
        end
    endtask

    task resp_push(input [7:0] b);
        begin
            resp_mem[resp_wp] = b;
            resp_wp = resp_wp + 1;
        end
    endtask

    //============================================================
    // Card state
    //============================================================
    reg ready;
    reg app_cmd_seen;
    reg tx_sector_data;

    //============================================================
    // RX (sample on pos_sck)
    //============================================================
    reg [7:0] rx_shift;
    reg [2:0] rx_bitcnt;
    reg [2:0] cmd_idx;

    reg [7:0] cmd0, cmd1, cmd2, cmd3, cmd4, cmd5;

    //============================================================
    // TX (change on neg_sck)
    //============================================================
    reg [7:0] tx_shift;
    reg [2:0] tx_bitcnt;
    reg       tx_active;

    reg [7:0] debug_num;

    //============================================================
    // sd card ready delay counter
    //============================================================
    localparam  ready_delay_param = 5;
    reg [11:0]  ready_delay_count;

    //============================================================
    // Main sequential logic
    //============================================================
    always @(posedge clock) begin

        resp_wp_reset = 1'b0;   // verilatエラー対策

        //--------------------------------------------------------
        // CS reset
        //--------------------------------------------------------
        if (cs_rise || cs_fall) begin
            miso_en   <= 1'b0;
            miso_bit  <= 1'b1;

            resp_wp   = 0;      // verilatエラー対策
            resp_rp   <= 0;

            rx_bitcnt <= 3'd7;
            cmd_idx   <= 3'd0;

            tx_active <= 1'b0;
            tx_bitcnt <= 3'd7;

            //ready     <= 1'b0;
            debug_num <= 8'd0;

            ready_delay_count <= 0;
        end

        //--------------------------------------------------------
        // RX (Mode0: sample on rising SCK)
        //--------------------------------------------------------
        if (selected && pos_sck) begin
            rx_shift[rx_bitcnt] <= mosi;

            if (rx_bitcnt == 3'd0) begin
                reg [7:0] rx_byte;
                rx_byte = {rx_shift[7:1], mosi};

                case (cmd_idx)
                    3'd0: cmd0 <= rx_byte;
                    3'd1: cmd1 <= rx_byte;
                    3'd2: cmd2 <= rx_byte;
                    3'd3: cmd3 <= rx_byte;
                    3'd4: cmd4 <= rx_byte;
                    3'd5: cmd5 <= rx_byte;
                    default: cmd0 <= 8'hFF;
                endcase

                if (cmd_idx == 3'd5) begin

                    ready_delay_count <= ready_delay_count + 1;

                    if (!tx_sector_data) begin
                        resp_reset();
                    end

                    case (cmd0)
                        
                        8'h40: begin // CMD0
                            debug_num <= 8'd0;
                            ready <= 1'b0;
                            app_cmd_seen <= 1'b0;
                            tx_sector_data <= 1'b0;
                            resp_push(INIT_R1_IDLE);
                        end
                        
                        8'h48: begin // CMD8
                            debug_num <= 8'd8;
                            resp_push(INIT_R1_IDLE);
                            resp_push(8'h00);
                            resp_push(8'h00);
                            resp_push(8'h01);
                            resp_push(8'hAA);
                        end
                        
                        // WRITE RESPONSE
                        8'h58: begin // CMD24
                            debug_num <= 8'd0;
                            for (i = 0; i < 5; i = i + 1) begin
                                resp_push(8'hFF);
                            end
                            resp_push(R1_READY);
                            resp_push(8'hFF);
                            resp_push(8'hFF);
                            resp_push(8'hFF);
                            resp_push(8'hFF);
                        end
                        
                        // WRITE END RESP (E1はオリジナルENDマークDATA)
                        8'hE1: begin
                            debug_num <= 8'd9;
                            for (i = 0; i < 5; i = i + 1)
                                resp_push(8'hFF);
                            resp_push(8'h05);
                            resp_push(8'h00);
                            resp_push(8'h00);
                            resp_push(8'h00);
                            resp_push(8'h00);
                        end
                        
                        8'h77: begin // CMD55
                            debug_num <= 8'd55;
                            app_cmd_seen <= 1'b1;
                            //resp_push(ready ? R1_READY : INIT_R1_IDLE);
                            resp_push(8'h01);
                        end

                        8'h69: begin // ACMD41
                            debug_num <= 8'd41;
                            if (app_cmd_seen) begin
                                ready_delay_count <= 0;
                                ready <= 1'b1;
                                // R1_READY     = 8'h00
                                // INIT_R1_IDLE = 8'h01,
                                //resp_push(R1_READY);     
                                resp_push(ready ? R1_READY : INIT_R1_IDLE);
                            end else begin
                                resp_push(8'h05);
                            end
                            app_cmd_seen <= 1'b0;
                        end

                        8'h7A: begin // CMD58
                            debug_num <= 8'd58;
                            resp_push(ready ? R1_READY : INIT_R1_IDLE);
                            resp_push(8'h40);
                            resp_push(8'h00);
                            resp_push(8'h00);
                            resp_push(8'h00);
                        end

                        8'h51: begin // CMD17
                            debug_num <= 8'd17;
                            //resp_reset();
                            if (ready) begin
                                tx_sector_data <= 1'b1;
                                resp_push(R1_READY);

                                // ★ WAIT期間（超重要）
                                for (i = 0; i < 20; i = i + 1)
                                    resp_push(8'hFF);

                                // 0xFE: marker
                                resp_push(8'hFE);
                                for (i = 0; i < 512; i = i + 1) begin
                                    resp_push(sector_data[i]);
                                end
                                // CRC1
                                resp_push(8'hC1);
                                // CRC2
                                resp_push(8'hC2);
                            end
                        end

                        // 8'hFF
                        default: begin
                            if(!tx_sector_data) begin
                                // R1_READY     = 8'h00
                                // INIT_R1_IDLE = 8'h01,
                                if(ready_delay_count > ready_delay_param) begin
                                    ready_delay_count <= 0;
                                    for (i = 0; i < 6; i = i + 1)
                                        resp_push(ready ? R1_READY : INIT_R1_IDLE);
                                end else begin
                                    for (i = 0; i < 6; i = i + 1)
                                        resp_push(8'hFF);
                                        //resp_push(8'h05);
                                end
                            end else begin
                                for (i = 0; i < 6; i = i + 1)
                                    resp_push(8'hFF);
                                    //resp_push(8'h05);
                            end
                        end
                        
                    endcase

                    if (!tx_sector_data) begin
                        resp_rp   <= 0;
                        tx_active <= 1'b0;
                    end
                    cmd_idx   <= 3'd0;

                end else begin
                    cmd_idx <= cmd_idx + 1;
                end

                rx_bitcnt <= 3'd7;
            end
            else begin
                rx_bitcnt <= rx_bitcnt - 1;
            end
        end
    end

    //--------------------------------------------------------
    // TX (Mode0: change on falling SCK)
    //--------------------------------------------------------

    always @(posedge clock) begin
        if (selected && neg_sck) begin

            if (!tx_active) begin
                if (resp_rp < resp_wp) begin
                    tx_shift  <= resp_mem[resp_rp];
                    tx_bitcnt <= 3'd7;
                    tx_active <= 1'b1;

                    miso_en   <= 1'b1;
                    miso_bit  <= resp_mem[resp_rp][7];
                end
                else begin
                    miso_en   <= 1'b0;
                    miso_bit  <= 1'b1;
                end
            end
            else begin
                // 1SCKズレ対策：次のビットを即出力
                if (tx_bitcnt == 3'd0) begin

                    resp_rp <= resp_rp + 1;

                    if ((resp_rp + 1) < resp_wp) begin
                        tx_shift  <= resp_mem[resp_rp + 1];
                        tx_bitcnt <= 3'd7;

                        // ★ ここが超重要
                        miso_bit  <= resp_mem[resp_rp + 1][7];
                        miso_en   <= 1'b1;
                    end
                    else begin
                        tx_active <= 1'b0;
                        miso_en   <= 1'b0;
                    end

                end
                else begin
                    tx_bitcnt <= tx_bitcnt - 1;
                    miso_bit  <= tx_shift[tx_bitcnt - 1];
                end
            end
        end
    end

    // debug 
    wire [7:0] debug_mem_0 = resp_mem[0];
    wire [7:0] debug_mem_1 = resp_mem[1];
    wire [7:0] debug_mem_2 = resp_mem[2];
    wire [7:0] debug_mem_3 = resp_mem[3];
    wire [7:0] debug_mem_4 = resp_mem[4];
    wire [7:0] debug_mem_5 = resp_mem[5];
    wire [7:0] debug_mem_6 = resp_mem[6];
    // debug 
    wire [7:0] debug_sec_0 = sector_data[0];
    wire [7:0] debug_sec_1 = sector_data[1];
    wire [7:0] debug_sec_2 = sector_data[2];
    wire [7:0] debug_sec_3 = sector_data[3];

endmodule