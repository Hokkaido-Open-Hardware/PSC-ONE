`timescale 1ns/1ps
`ifdef COCOTB_SIM
    `define fast_sck
`endif

// シミュレーション用: 初期化はSPI、READはhexイメージを参照
//`define SPI_BYPASS

module PSC_SDCard #(
    parameter ADDR_WIDTH        = 32,
    parameter CLK_FREQ_MHz      = 80,
    parameter INIT_80CLK        = 80,
    parameter PROTECT_ADDRESS   = 32'h0000_1000,  // > 4098
    parameter SD_IF_DATA        = 32'h1000_6000,  // READ: 4 bytes LE; WRITE: byte
    parameter SD_IF_SECTOR      = 32'h1000_6004,  // WRITE: LBA
    parameter SD_IF_CTRL        = 32'h1000_6008,  // RW: start/status
    parameter FIFO_DEPTH        = 512,            // 512推奨（将来64/128でも可）
    parameter BYPASS_IMAGE_HEX  = "sdcard/sdcard.hex",
    parameter integer BYPASS_IMAGE_SECTORS = 131072 // 64 MiB
)(
    input  logic        clock,
    input  logic        reset_n,

    // ---------------- CPU BUS ----------------
    input  logic        cpu_rvalid,
    input  logic [31:0] cpu_raddr,
    output logic [31:0] cpu_rdata,
    output logic        cpu_rready,

    input  logic        cpu_wvalid,
    input  logic [31:0] cpu_waddr,
    input  logic [31:0] cpu_wdata,
    output logic        cpu_wready,

    // ---------------- SD SPI ----------------
    output logic        sd_cs_n,
    output logic        sd_sck,
    output logic        sd_mosi,
    input  logic        sd_miso
);

    // Expose the compiled mode to the simulation wrapper; do not infer it
    // from the source file or an independently configured test environment.
`ifdef SPI_BYPASS
    localparam SPI_BYPASS_ENABLED = 1'b1;
`else
    localparam SPI_BYPASS_ENABLED = 1'b0;
`endif

    // ============================================================
    // SPI SCK CLK 
    // ============================================================
    localparam INIT_SCK_DIV =
            (CLK_FREQ_MHz * 1_000_000) / (2 * 400_000);         // 400kHz

    localparam FAST_SCK_DIV_TMP =
            `ifdef fast_sck
            (CLK_FREQ_MHz * 1_000_000) / (2 * 12_500_000);      // 12.5MHz
            `else
            (CLK_FREQ_MHz * 1_000_000) / (2 *  5_000_000);      //  5.0MHz
            `endif

    localparam FAST_SCK_DIV =
            (FAST_SCK_DIV_TMP < 12) ? 12 : FAST_SCK_DIV_TMP;

    // ============================================================
    // SPI ENGINE
    // ============================================================
    // SPI signals
    wire [7:0] spi_rx_data;
    wire       spi_busy;

    logic        spi_tx_data_valid;
    logic        spi_cs_high;
    logic  [7:0] spi_tx_data;
    logic        spi_tx_start;
    logic        spi_tx_start_d;

    logic        sck_fast_mode;
    logic        sd_card_ready;

    // input latch
    logic        sd_miso_latch;
    always @(posedge clock) begin
        sd_miso_latch <= sd_miso;
    end

    // SPI module instance
    PSC_SDCard_SPI #(
        .INIT_SCK_DIV   (INIT_SCK_DIV),
        .FAST_SCK_DIV   (FAST_SCK_DIV)
    ) u_spi (
        .clock              (clock),
        .reset_n            (reset_n),

        .sck_fast_mode      (sck_fast_mode),
        .sck_cs_high        (spi_cs_high),

        .spi_tx_data_valid  (spi_tx_data_valid),
        .spi_tx_data        (spi_tx_data),
        .spi_tx_start       (spi_tx_start_d),
        .spi_rx_data        (spi_rx_data),
        .spi_busy           (spi_busy),

        .CS_N               (sd_cs_n),
        .SCK                (sd_sck),
        .MOSI               (sd_mosi),
        .MISO               (sd_miso_latch)
    );

    // ============================================================
    // MMIO registers / flags
    // ============================================================
    logic [31:0] sector_reg;      // LBA
    logic        init_pulse;     // CPUが書いた「開始」ワンショット（内部）
    logic        read_start;
    logic        fifo_flush;
    logic        fifo_wdata_push;
    logic        fifo_wdata_pop;
    logic        soft_reset;
    logic        write_start;
    logic        error;

    // ============================================================
    // FIFO (byte)
    // ============================================================
    localparam integer FIFO_AW = 9;     // max 512
    localparam integer FIFO_CW = FIFO_AW + 1;

    // Read FIFO: byte producer, aligned 32-bit consumer. FIFO_DEPTH must be
    // a multiple of four (4..512). Store complete words for a single RAM
    // read port; fifo_count and both pointers still use byte units.
    logic [31:0] fifo_R_mem [0:FIFO_DEPTH/4-1];
    logic [23:0] fifo_R_pack;
    logic [31:0] fifo_read_word;
    logic [FIFO_AW-1:0] fifo_wr_ptr, fifo_rd_ptr;
    logic [FIFO_CW-1:0] fifo_count; // 0..FIFO_DEPTH

    wire fifo_empty = (fifo_count == 0);
`ifdef SPI_BYPASS
    wire fifo_full  = (fifo_count >= FIFO_DEPTH);
`else
    wire fifo_full  = (fifo_count == FIFO_DEPTH + 1);
`endif

    // fifo push/pop strobes
    logic         fifo_push;
    logic [7:0]   fifo_push_data;

    // write fifo
    logic [7:0] fifo_W_mem [0:FIFO_DEPTH-1];
    logic [FIFO_AW-1:0] fifo_W_wr_ptr, fifo_W_rd_ptr;

    logic [7:0]   fifo_W_push_data;
    logic [7:0]   fifo_write_data;

    // crc data
    logic         crc_write1;
    logic         crc_write2;
    logic [7:0]   crc_rdata;
    logic [7:0]   crc_data1;
    logic [7:0]   crc_data2;

    // ============================================================
    // CPU BUS (MMIO)
    // ============================================================
    logic     cpu_rvalid_latch;
    logic     cpu_rvalid_previous;
    logic     cpu_wvalid_latch;
    logic     fifo_read_pending;

    // A DATA response consumes a complete word on this same edge. Short
    // reads acknowledge with 0x000000E0 and leave all queued bytes intact.
    // STATUS.empty continues to mean zero bytes (not fewer than four).
    wire fifo_read_clear = fifo_flush
`ifdef SPI_BYPASS
                         || soft_reset
`endif
                         ;
    wire fifo_read_request = cpu_rvalid_latch && (cpu_raddr == SD_IF_DATA) &&
                             (fifo_count >= 4) && !fifo_read_clear;
    wire fifo_pop = fifo_read_pending && !fifo_read_clear;
    wire fifo_push_accept = fifo_push &&
                            ((fifo_count < FIFO_DEPTH) || fifo_pop);

    // Explicit wrap also supports read FIFOs smaller than the pointer width.
    function automatic [FIFO_AW-1:0] fifo_read_offset;
        input [FIFO_AW-1:0] ptr;
        input integer offset;
        integer next_ptr;
        begin
            next_ptr = int'(ptr) + offset;
            if (next_ptr >= FIFO_DEPTH) next_ptr = next_ptr - FIFO_DEPTH;
            fifo_read_offset = FIFO_AW'(next_ptr);
        end
    endfunction

    // No asynchronous reset on RAM data or its output register, allowing
    // block RAM inference. Partial incoming words cannot be read by the CPU.
    always @(posedge clock) begin
        if (reset_n && !fifo_read_clear && fifo_push_accept) begin
            fifo_R_pack <= {fifo_push_data, fifo_R_pack[23:8]};
            if (fifo_wr_ptr[1:0] == 2'b11)
                fifo_R_mem[fifo_wr_ptr[FIFO_AW-1:2]] <= {fifo_push_data, fifo_R_pack};
        end
        if (fifo_read_request)
            fifo_read_word <= fifo_R_mem[fifo_rd_ptr[FIFO_AW-1:2]];
    end
    
    // ---------------- cpu_valid latch ----------------
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            cpu_rvalid_latch    <= 1'b0;
            cpu_rvalid_previous <= 1'b0;
            cpu_wvalid_latch    <= 1'b0;
        end else begin
            // One response per assertion, even if valid remains high after
            // ready. A sampled low cycle arms the next transaction.
            cpu_rvalid_previous <= cpu_rvalid;
            cpu_rvalid_latch    <= cpu_rvalid && !cpu_rvalid_previous;
            cpu_wvalid_latch    <= cpu_wvalid;
        end
    end

    // ---------------- CPU Bus ----------------
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            cpu_wready       <= 1'b0;
            cpu_rready       <= 1'b0;
            cpu_rdata        <= 32'h0;
            fifo_read_pending <= 1'b0;

            sector_reg   <= 32'h0;
            init_pulse   <= 1'b0;  // one-shot
            read_start   <= 1'b0; 
            fifo_flush   <= 1'b0;
            soft_reset   <= 1'b0;

            fifo_wdata_push  <= 1'b0;

            write_start   <= 1'b0; 
            error        <= 1'b0;
            
            fifo_wr_ptr <= {FIFO_AW{1'b0}};
            fifo_rd_ptr <= {FIFO_AW{1'b0}};
            fifo_count  <= {(FIFO_AW+1){1'b0}};

            fifo_W_wr_ptr <= {FIFO_AW{1'b0}};
            fifo_W_rd_ptr <= {FIFO_AW{1'b0}};
            fifo_W_push_data <= 8'h0;
            fifo_write_data  <= 8'h0;

            crc_data1   <= 8'h0;
            crc_data2   <= 8'h0;

        end else begin
            cpu_wready       <= 1'b0;
            cpu_rready       <= 1'b0;
            cpu_rdata        <= 1'b0;
            fifo_read_pending <= fifo_read_request;
            init_pulse       <= 1'b0;   // one-shot
            fifo_flush       <= 1'b0;
            soft_reset       <= 1'b0;

            fifo_wdata_push  <= 1'b0;

            // read_startをリセット
            // write_startをリセット
            if (state == ST_DONE) begin
                read_start  <= 1'b0;
            end
            if (state == ST_WRITE_DONE) begin
                write_start <= 1'b0;
            end
`ifdef SPI_BYPASS
            if (soft_reset) begin
                read_start  <= 1'b0;
                write_start <= 1'b0;
            end
`endif

            // ------------ CPU Bus ----------------
            // READ: DATA FIFO
            if (cpu_rvalid_latch) begin
                case (cpu_raddr)
                    SD_IF_DATA: begin
                        if (!fifo_read_request) begin
                            cpu_rready <= 1'b1;
                            cpu_rdata <= 32'h0000_00E0; // fewer than 4 bytes: no pop
                        end
                    end
                    SD_IF_SECTOR: begin
                        cpu_rready <= 1'b1;
                        cpu_rdata <= sector_reg;
                    end
                    SD_IF_CTRL: begin
                        cpu_rready <= 1'b1;
                        cpu_rdata  <= {
                            crc_data1,
                            crc_data2,
                            8'b0,
                            2'b0,
                            {error | state_error},      // bit5
                            fifo_full,                  // bit4
                            fifo_empty,                 // bit3
                            sd_rw_ready,                // bit2
                            busy,                       // bit1
                            1'b0                        // bit0 (start is write-only; 0固定)
                        };
                    end
                    default: ;
                endcase
            end

            // The synchronous RAM output is available one cycle after the
            // request. Consume four bytes only when returning this response.
            if (fifo_read_pending) begin
                cpu_rready <= 1'b1;
                cpu_rdata <= fifo_pop ? fifo_read_word : 32'h0000_00E0;
            end

            // WRITE
            if (cpu_wvalid_latch) begin
                case (cpu_waddr)
                    SD_IF_DATA: begin
                        cpu_wready <= 1'b1;
                        fifo_W_push_data <= cpu_wdata[7:0];
                        fifo_wdata_push <= 1'b1;
                    end
                    SD_IF_SECTOR: begin
                        cpu_wready <= 1'b1;
                        sector_reg <= cpu_wdata;
                    end
                    SD_IF_CTRL: begin
                        cpu_wready <= 1'b1;
                        // bit0=1 SDカードイニシャライズで開始
                        if (cpu_wdata[0]) begin
                            init_pulse <= 1'b1;
                        end
                        // bit1=1 SDカードREAD開始
                        else if (cpu_wdata[1]) begin
                            read_start <= 1'b1;
                        end
                        // bit2=1 SDカードREAD開始
                        else if (cpu_wdata[2]) begin
                            fifo_flush <= 1'b1;
                            read_start <= 1'b0;
                        end
                        // bit3=1 でソフトリセット
                        else if (cpu_wdata[3]) begin
                            soft_reset <= 1'b1;
                        end
                        // bit4= writeスタート
                        else if (cpu_wdata[4]) begin
                            write_start <= 1'b1;
                        end
                        // bit7= TBD
                        // bit7=1 でエラークリア(任意)
                        else if (cpu_wdata[7]) begin
                            error <= 1'b0;
                        end
                    end
                    default: ;
                endcase
            end

            // ------------ READ FIFO ----------------
            // flush
            if (fifo_read_clear) begin
                fifo_wr_ptr <= {FIFO_AW{1'b0}};
                fifo_rd_ptr <= {FIFO_AW{1'b0}};
                fifo_count  <= {FIFO_CW{1'b0}};
                crc_data1   <= 8'h0;
                crc_data2   <= 8'h0;
            end

            else begin
                // Push and word pop are independent; neither may be lost
                // when the SPI producer and CPU complete on the same edge.
                if (fifo_push_accept) begin
                    fifo_wr_ptr <= fifo_read_offset(fifo_wr_ptr, 1);
                end
                if (fifo_pop)
                    fifo_rd_ptr <= fifo_read_offset(fifo_rd_ptr, 4);
                case ({fifo_push_accept, fifo_pop})
                    2'b10: fifo_count <= fifo_count + FIFO_CW'(1);
                    2'b01: fifo_count <= fifo_count - FIFO_CW'(4);
                    2'b11: fifo_count <= fifo_count - FIFO_CW'(3);
                    default: ;
                endcase
            end

            // crc
            if (crc_write1) begin
                crc_data1   <= crc_rdata;
            end
            if (crc_write2) begin
                crc_data2   <= crc_rdata;
            end

            // ------------ WRITE FIFO ----------------
            // flush
            if (fifo_flush) begin
                // flush信号はread と共通
                fifo_W_wr_ptr <= {FIFO_AW{1'b0}};
                fifo_W_rd_ptr <= {FIFO_AW{1'b0}};
            end

            // push
            else if (fifo_wdata_push) begin
                fifo_W_mem[fifo_W_wr_ptr] <= fifo_W_push_data;
                fifo_W_wr_ptr <= fifo_W_wr_ptr + FIFO_AW'(1);
            end

            // pop
            else if (fifo_wdata_pop) begin
                fifo_write_data <= fifo_W_mem[fifo_W_rd_ptr];
                fifo_W_rd_ptr <= fifo_W_rd_ptr + FIFO_AW'(1);
            end

        end
    end

    // ============================================================
    // SD INIT + READ FSM
    // ============================================================
    localparam [4:0]
        ST_RESET            = 5'd0,
        ST_INIT_CLK         = 5'd1,

        ST_CMD0_SEND        = 5'd2,
        ST_CMD8_SEND        = 5'd3,
        ST_CMD55_SEND       = 5'd4,
        ST_ACMD41_SEND      = 5'd5,
        ST_CMD58_SEND       = 5'd6,

        ST_WAIT_R1          = 5'd7,
        ST_READY            = 5'd8,

        ST_CMD17_SEND       = 5'd9,
        ST_WAIT_TOKEN       = 5'd10,
        ST_READ_DATA        = 5'd11,
        ST_READ_CRC1        = 5'd12,
        ST_READ_CRC2        = 5'd13,
        ST_DONE             = 5'd14,

        ST_CMD24_SEND       = 5'd15,
        ST_WRITE_TOKEN      = 5'd16,
        ST_WRITE_DATA       = 5'd17,
        ST_WRITE_CRC1       = 5'd18,
        ST_WRITE_CRC2       = 5'd19,
        ST_WAIT_DATA_RESP   = 5'd20,
        ST_WAIT_BUSY        = 5'd21,
        ST_WRITE_DONE       = 5'd22,

        ST_FULL        = 5'd30,
        ST_ERROR       = 5'd31;

    logic [4:0] state;
    logic [4:0] next_state;

    logic [6:0]   cmd_i;
    logic [9:0]   byte_cnt;
    logic [7:0]   cmd_rx;
    logic [7:0]   rx_cmd_sd_card;

    // BUSY definition:
    //   - not READY (init/read ongoing) OR fifo has remaining data
    wire busy = (state != ST_READY) || (fifo_count != 0);
    wire sd_rw_ready = (state == ST_READY);

    // state error
    logic       state_error;

`ifdef SPI_BYPASS
    // Sparse hex addresses are byte offsets. Unspecified bytes read as zero,
    // matching the SPI card model. This memory is for simulation only.
    localparam integer BYPASS_IMAGE_BYTES = BYPASS_IMAGE_SECTORS * 512;
    logic [7:0] bypass_image [0:BYPASS_IMAGE_BYTES-1];
    integer bypass_image_fd;
    integer bypass_index;
    logic [31:0] bypass_base;
    logic [15:0] bypass_crc;

    initial begin
        for (bypass_index = 0; bypass_index < BYPASS_IMAGE_BYTES;
             bypass_index = bypass_index + 1)
            bypass_image[bypass_index] = 8'h00;
        bypass_image_fd = $fopen(BYPASS_IMAGE_HEX, "r");
        if (bypass_image_fd == 0)
            $fatal(1, "Cannot open SD bypass image: %s", BYPASS_IMAGE_HEX);
        else begin
            $fclose(bypass_image_fd);
            $readmemh(BYPASS_IMAGE_HEX, bypass_image);
        end
    end

    function automatic [15:0] bypass_crc16_byte;
        input logic [15:0] crc_in;
        input logic [7:0] data_in;
        reg [15:0] crc;
        integer bit_index;
        begin
            crc = crc_in ^ {data_in, 8'h00};
            for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1)
                crc = crc[15] ? (crc << 1) ^ 16'h1021 : (crc << 1);
            bypass_crc16_byte = crc;
        end
    endfunction

`endif
    // ============================================================
    // Task
    // ============================================================
    task spi_send;
        input logic [7:0] byte_in;
        begin
            spi_tx_data_valid <= 1'b1;  // 1-cycle pulse from FSM
            spi_tx_data  <= byte_in;
        end
    endtask

    // ============================================================
    // MAIN FSM
    // ============================================================
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            state      <= ST_RESET;
            next_state <= ST_RESET;

            cmd_i            <= 6'd0;
            byte_cnt         <= 10'd0;
            cmd_rx           <= 8'h0;
            rx_cmd_sd_card   <= 8'h0;

            spi_tx_data_valid   <= 1'b0;
            spi_tx_start        <= 1'b0;
            spi_tx_start_d      <= 1'b0;
            spi_tx_data         <= 8'h0;
            sck_fast_mode       <= 1'b0;
            spi_cs_high         <= 1'b0;

            sd_card_ready       <= 1'b0;

            fifo_push           <= 1'b0;
            fifo_push_data      <= 8'h00;
            crc_rdata           <= 8'h0;
            crc_write1          <= 1'b0;
            crc_write2          <= 1'b0;

            fifo_wdata_pop      <= 1'b0;

            state_error         <= 1'b0;
`ifdef SPI_BYPASS
            bypass_base <= 32'd0;
            bypass_crc  <= 16'd0;
`endif
        end else begin
            // defaults
`ifdef SPI_BYPASS
            // Initialization still uses SPI; image reads keep CS inactive.
            spi_cs_high         <= (state >= ST_READY);
`else
            spi_cs_high         <= 1'b0;
`endif
            spi_tx_data_valid   <= 1'b0;
            spi_tx_start        <= 1'b0;
            fifo_push           <= 1'b0;
            fifo_push_data      <= 8'h00;
            crc_write1          <= 1'b0;
            crc_write2          <= 1'b0;

            fifo_wdata_pop      <= 1'b0;

            spi_tx_start_d      <= spi_tx_start;
            
            // 全てのステートで共通
            if (state != ST_RESET
`ifdef SPI_BYPASS
                && state < ST_READY
`endif
            ) begin
                if (spi_tx_start | spi_tx_start_d) begin
                    spi_tx_start    <= 1'b0;        // spi_tx_start: 1clkでLにする
                end else if (!spi_busy) begin
                    spi_tx_start    <= 1'b1;
                end
                if (spi_tx_start) begin
                    cmd_i           <= cmd_i + 6'd1;
                end
                // soft_resetで強制リセット. 連続READはTBD
                if (soft_reset) begin
                    state  <= ST_RESET;             
                end
            end

            // state マシン
            case (state)

                // -------------------------------------------------
                // state = 0
                ST_RESET: begin
                    spi_cs_high   <= 1'b1;
                    sd_card_ready <= 1'b0;
                    if (init_pulse && !state_error) begin
                        // start init sequence
                        spi_tx_start    <= 1'b1;
                        state <= ST_INIT_CLK;
                    end 
                end

                // -------------------------------------------------
                // 80 clocks with CS high (0xFF bytes)
                // state = 1
                ST_INIT_CLK: begin
                    spi_cs_high   <= 1'b1;
                    if (spi_tx_start) begin
                        spi_send(8'hFF);
                        if (cmd_i == INIT_80CLK) begin
                            cmd_i <= 6'd0;
                            spi_cs_high   <= 1'b0;
                            state <= ST_CMD0_SEND;
                        end
                    end
                end

                // -------------------------------------------------
                // CMD0
                // state = 2
                ST_CMD0_SEND: begin
                    if (spi_tx_start_d) begin
                        case (cmd_i)
                            3'd0: spi_send(8'h40);
                            3'd1: spi_send(8'h00);
                            3'd2: spi_send(8'h00);
                            3'd3: spi_send(8'h00);
                            3'd4: spi_send(8'h00);
                            3'd5: spi_send(8'h95);
                            default: spi_send(8'hFF);
                        endcase
                    end
                    if (spi_tx_start) begin
                        if (cmd_i == 6'd5) begin
                            cmd_i <= 6'd0;
                            next_state  <= ST_CMD8_SEND;
                            state       <= ST_WAIT_R1;
                        end
                    end
                end

                // -------------------------------------------------
                // CMD8
                // state = 3
                ST_CMD8_SEND: begin
                    if (spi_tx_start_d) begin
                        case (cmd_i)
                            3'd0: spi_send(8'h48);
                            3'd1: spi_send(8'h00);
                            3'd2: spi_send(8'h00);
                            3'd3: spi_send(8'h01);
                            3'd4: spi_send(8'hAA);
                            3'd5: spi_send(8'h87);
                            default: spi_send(8'hFF);
                        endcase
                    end
                    if (spi_tx_start) begin
                        if (cmd_i == 6'd5) begin
                            cmd_i <= 6'd0;
                            next_state    <= ST_CMD55_SEND;
                            state         <= ST_WAIT_R1;
                        end
                    end
                end

                // -------------------------------------------------
                // CMD55
                // state = 4
                ST_CMD55_SEND: begin
                    if (spi_tx_start_d) begin
                        case (cmd_i)
                            3'd0: spi_send(8'h77);
                            3'd1: spi_send(8'h00);
                            3'd2: spi_send(8'h00);
                            3'd3: spi_send(8'h00);
                            3'd4: spi_send(8'h00);
                            3'd5: spi_send(8'hFF);
                            default: spi_send(8'hFF);
                        endcase
                    end
                    if (spi_tx_start) begin
                        if (cmd_i == 6'd5) begin
                            cmd_i <= 6'd0;
                            next_state  <= ST_ACMD41_SEND;
                            state       <= ST_WAIT_R1;
                        end
                    end
                end

                // -------------------------------------------------
                // ACMD41
                // state = 5
                ST_ACMD41_SEND: begin
                    if (spi_tx_start_d) begin
                        case (cmd_i)
                            3'd0: spi_send(8'h69);
                            3'd1: spi_send(8'h40); // HCS
                            3'd2: spi_send(8'h00);
                            3'd3: spi_send(8'h00);
                            3'd4: spi_send(8'h00);
                            3'd5: spi_send(8'hFF);
                            default: spi_send(8'hFF);
                        endcase
                    end
                    if (spi_tx_start) begin
                        if (cmd_i == 3'd5) begin
                            next_state    <= ST_CMD58_SEND; // readyなら次
                            state         <= ST_WAIT_R1;
                            cmd_i         <= 3'd0;
                        end
                    end
                end

                // -------------------------------------------------
                // CMD58
                // state = 6
                ST_CMD58_SEND: begin
                    if (spi_tx_start_d) begin
                        case (cmd_i)
                            3'd0: spi_send(8'h7A);
                            3'd1: spi_send(8'h00);
                            3'd2: spi_send(8'h00);
                            3'd3: spi_send(8'h00);
                            3'd4: spi_send(8'h00);
                            3'd5: spi_send(8'hFF);
                            default: spi_send(8'hFF);
                        endcase
                    end
                    if (spi_tx_start) begin
                        if (cmd_i == 3'd5) begin
                            next_state <= ST_READY;
                            state      <= ST_WAIT_R1;
                            cmd_i    <= 3'd0;
                        end
                    end
                end

                // -------------------------------------------------
                // WAIT R1 (0xFF以外が来るまで0xFFを送り続ける)
                // state = 7
                ST_WAIT_R1: begin
                    if (spi_tx_start_d) begin
                        spi_send(8'hFF);
                        cmd_rx <= spi_rx_data;  // 初回はここに書く
                    end
                    if (spi_tx_start) begin
                        cmd_rx <= spi_rx_data;
                        if ((cmd_rx == 8'hFF) && (spi_rx_data != 8'hFF) && !sd_card_ready) begin      // rx_data = 0xFFからの変化を検出（初回の）
                            sd_card_ready <= 1'b1;
                            rx_cmd_sd_card <= spi_rx_data;
                        end
                        if (cmd_i == 6'd5) begin
                            cmd_i <= 6'd0;
                            if (sd_card_ready) begin
                                sd_card_ready  <= 1'b0;
                                case (next_state)
                                    // READ
                                    ST_CMD8_SEND    : if (rx_cmd_sd_card == 8'h01) state <= next_state;
                                    ST_CMD55_SEND   : if (rx_cmd_sd_card == 8'h01) state <= next_state;
                                    ST_ACMD41_SEND  : if (rx_cmd_sd_card == 8'h01) state <= next_state;
                                    ST_CMD58_SEND: begin
                                        if (rx_cmd_sd_card == 8'h00)
                                            state <= next_state;      // ACMD41完了. 0x00以外のコードも確認すべき（TBD）
                                        else if (rx_cmd_sd_card == 8'h01)
                                            state <= ST_CMD55_SEND;   // まだ初期化中なので再ループ
                                    end
                                    ST_READY        : if (rx_cmd_sd_card == 8'h00) state <= next_state;
                                    ST_WAIT_TOKEN   : if (rx_cmd_sd_card == 8'h00) state <= next_state;
                                    // WRITE
                                    ST_WRITE_TOKEN  : if (rx_cmd_sd_card == 8'h00) state <= next_state;     // rx = 8'h00
                                    default:          state <= next_state;
                                endcase
                            end
                        end
                    end
                end

                // -------------------------------------------------
                // SD READ Sequence
                // -------------------------------------------------

                // -------------------------------------------------
                // READY (待機: read開始待ち)
                // state = 8
                ST_READY: begin
`ifdef SPI_BYPASS
                    // Update the SPI engine's CS latch without starting SCK.
                    spi_send(8'hFF);
                    if (write_start || (read_start &&
                        (!fifo_empty || sector_reg >= BYPASS_IMAGE_SECTORS))) begin
                        state_error <= 1'b1;
                        state <= ST_ERROR;
                    end else if (read_start) begin
                        bypass_base <= sector_reg << 9;
                        byte_cnt    <= 10'd0;
                        bypass_crc  <= 16'd0;
                        state       <= ST_READ_DATA;
                    end
`else
                    spi_cs_high <= 1'b1;
                    if (spi_tx_start_d) begin
                        `ifdef fast_sck
                        sck_fast_mode <= 1'b1;
                        `endif
                        spi_send(8'hFF);
                    end
                    if (spi_tx_start) begin
                        if (cmd_i == 3'd5) begin
                            cmd_i   <= 3'd0;
                            if (read_start && !error) begin
                                if (!fifo_empty) begin
                                    state_error <= 1'b1;
                                    state <= ST_ERROR;
                                end else begin
                                    state <= ST_CMD17_SEND;
                                end
                            end
                            if (write_start && !error) begin
                                state <= ST_CMD24_SEND;
                            end
                        end
                    end
`endif
                end

                // -------------------------------------------------
                // CMD17 (SDHC前提でLBA)
                // セクタアドレス設定
                // state = 9
                ST_CMD17_SEND: begin
                    if (spi_tx_start_d) begin
                        case (cmd_i)
                            3'd0: spi_send(8'h51);
                            3'd1: spi_send(sector_reg[31:24]);
                            3'd2: spi_send(sector_reg[23:16]);
                            3'd3: spi_send(sector_reg[15:8]);
                            3'd4: spi_send(sector_reg[7:0]);
                            3'd5: spi_send(8'hFF);
                            default: spi_send(8'hFF);
                        endcase
                    end
                    if (spi_tx_start) begin
                        if (cmd_i == 3'd5) begin
                            next_state <= ST_WAIT_TOKEN;
                            state      <= ST_WAIT_R1;
                            cmd_i    <= 3'd0;
                        end
                    end
                end

                // -------------------------------------------------
                // wait token 0xFE
                // state = 10
                ST_WAIT_TOKEN: begin
                    if (spi_tx_start_d) begin
                        spi_send(8'hFF);
                    end
                    if (spi_tx_start) begin
                        if (spi_rx_data == 8'hFE) begin
                            byte_cnt <= 10'd0;
                            state    <= ST_READ_DATA;
                        end
                    end
                end

                // -------------------------------------------------
                // read 512 bytes -> FIFO push
                // state = 11
                ST_READ_DATA: begin
`ifdef SPI_BYPASS
                    // Allow CPU word reads during the transfer. Keep a gap
                    // for the registered push to update the full flag.
                    if (!fifo_full && !fifo_push && !fifo_flush) begin
                        fifo_push_data <= bypass_image[bypass_base + {22'd0, byte_cnt}];
                        fifo_push <= 1'b1;
                        bypass_crc <= bypass_crc16_byte(bypass_crc,
                            bypass_image[bypass_base + {22'd0, byte_cnt}]);
                        byte_cnt <= byte_cnt + 10'd1;
                        if (byte_cnt == 10'd511) state <= ST_READ_CRC1;
                    end
`else
                    if (spi_tx_start_d) begin
                        spi_send(8'hFF);
                    end

                    if (spi_tx_start) begin
                        if (fifo_full) begin
                            state_error <= 1'b1;
                            state <= ST_FULL;
                        end else begin
                            byte_cnt <= byte_cnt + 10'd1;
                            if (byte_cnt == 10'd513) begin
                                // CRC2
                                crc_write2      <= 1'b1;
                                crc_rdata       <= spi_rx_data;
                                cmd_i           <= 3'd0;
                                state           <= ST_DONE;
                            end else if (byte_cnt == 10'd512) begin
                                // CRC1
                                crc_write1      <= 1'b1;
                                crc_rdata       <= spi_rx_data;
                            end else begin
                                fifo_push       <= 1'b1;
                                fifo_push_data  <= spi_rx_data;
                            end
                        end
                    end
`endif
                end

                // -------------------------------------------------
                // state = 12
                // SPI_BYPASS: publish CRC high byte
                ST_READ_CRC1: begin
`ifdef SPI_BYPASS
                    crc_rdata  <= bypass_crc[15:8];
                    crc_write1 <= 1'b1;
                    state      <= ST_READ_CRC2;
`else
                    if (spi_tx_start_d) begin
                        spi_send(8'hFF);
                    end
                    if (spi_tx_start) begin
                        crc_rdata   <= spi_rx_data;
                        crc_write1  <= 1'b1;
                        state       <= ST_READ_CRC2;                            
                    end
`endif
                end

                // -------------------------------------------------
                // state = 13
                // SPI_BYPASS: publish CRC low byte
                ST_READ_CRC2: begin
`ifdef SPI_BYPASS
                    crc_rdata  <= bypass_crc[7:0];
                    crc_write2 <= 1'b1;
                    state      <= ST_DONE;
`else
                    if (spi_tx_start_d) begin
                        spi_send(8'hFF);
                    end
                    if (spi_tx_start) begin
                        crc_rdata   <= spi_rx_data;
                        crc_write2  <= 1'b1;
                        state       <= ST_DONE;                            
                    end
`endif
                end

                // -------------------------------------------------
                // state = 14
                ST_DONE: begin
`ifdef SPI_BYPASS
                    state <= ST_READY;
`else
                    if (spi_tx_start_d) begin
                        spi_send(8'hFF);
                    end
                    if (spi_tx_start) begin
                        if (cmd_i == 3'd5) begin
                            state    <= ST_READY;
                            cmd_i    <= 3'd0;
                        end
                    end
`endif
                end

                // -------------------------------------------------
                // SD WRITE Sequence
                // -------------------------------------------------
                // state = 15
                ST_CMD24_SEND: begin
                    if (spi_tx_start_d) begin
                        if (sector_reg > PROTECT_ADDRESS) begin     // SDカード破損防止
                            case (cmd_i)
                                3'd0: spi_send(8'h58);              // CMD24
                                3'd1: spi_send(sector_reg[31:24]);
                                3'd2: spi_send(sector_reg[23:16]);
                                3'd3: spi_send(sector_reg[15:8]);
                                3'd4: spi_send(sector_reg[7:0]);
                                3'd5: spi_send(8'hFF);              // Dummy CRC
                                default: spi_send(8'hFF);
                            endcase
                        end else begin
                            if (cmd_i == 3'd5) begin
                                state      <= ST_ERROR;
                            end
                        end
                    end

                    if (spi_tx_start) begin
                        if (cmd_i == 3'd5) begin
                            cmd_i      <= 3'd0;
                            next_state <= ST_WRITE_TOKEN;
                            state      <= ST_WAIT_R1;
                        end
                    end
                end

                // -------------------------------------------------
                // state = 16
                ST_WRITE_TOKEN: begin
                    if (spi_tx_start_d) begin
                        spi_send(8'hFF);
                    end

                    if (spi_tx_start) begin
                        if (cmd_i == 3'd5) begin
                            cmd_i      <= 3'd0;
                            byte_cnt   <= 10'd0;
                            state      <= ST_WRITE_DATA;
                            fifo_wdata_pop <= 1'b1; // 追加
                        end
                    end
                end

                // -------------------------------------------------
                // state = 17
                ST_WRITE_DATA: begin
                    if ((byte_cnt == 0) & spi_tx_start_d) begin
                        spi_send(8'hFE);          // Data Token
                    end 
                    else if (spi_tx_start) begin
                        if (byte_cnt == 10'd512) begin
                            state <= ST_WRITE_CRC1;
                        end else begin
                            byte_cnt <= byte_cnt + 10'd1;
                            fifo_wdata_pop <= 1'b1;
                            spi_send(fifo_write_data);
                        end
                    end
                end

                // -------------------------------------------------
                // state = 18
                ST_WRITE_CRC1: begin
                    if (spi_tx_start_d) begin
                        spi_send(8'hFF);
                    end
                    if (spi_tx_start) begin
                        state    <= ST_WRITE_CRC2;
                    end
                end

                // -------------------------------------------------
                // state = 19
                ST_WRITE_CRC2: begin
                    if (spi_tx_start_d) begin
                        spi_send(8'hFF);
                    end
                    if (spi_tx_start) begin
                        state    <= ST_WAIT_DATA_RESP;
                    end
                end

                // -------------------------------------------------
                // state = 20
                ST_WAIT_DATA_RESP: begin
                    if (spi_tx_start_d) begin
                        spi_send(8'hFF);
                    end

                    if (spi_tx_start) begin

                        // lower 5bits == 00101
                        if (spi_rx_data[4:0] == 5'h05) begin
                            state <= ST_WAIT_BUSY;
                        end
                        else if (spi_rx_data[4:0] == 5'h0B) begin
                            state <= ST_ERROR;  // CRC Error
                        end
                        else if (spi_rx_data[4:0] == 5'h0D) begin
                            state <= ST_ERROR;  // Write Error
                        end
                    end
                end

                // -------------------------------------------------
                // state = 21
                ST_WAIT_BUSY: begin
                    if (spi_tx_start_d)
                        spi_send(8'hFF);

                    if (spi_tx_start) begin
                        if (spi_rx_data == 8'hFF) begin
                            state <= ST_WRITE_DONE;
                            cmd_i <= 0;
                        end
                    end
                end

                // -------------------------------------------------
                // state = 22
                ST_WRITE_DONE: begin
                    if (spi_tx_start) begin
                        if (spi_rx_data == 8'hFF) begin
                            state <= ST_READY;
                            cmd_i <= 3'd0;
                        end
                    end
                end

                // -------------------------------------------------
                // SD other Sequence
                // -------------------------------------------------

                // -------------------------------------------------
                // state = 30
                ST_FULL: begin
                    spi_cs_high   <= 1'b1;
                    state   <= ST_FULL; // reset or ctrl bit4 clear then restart
                end

                // -------------------------------------------------
                // state = 31
                ST_ERROR: begin
                    spi_cs_high   <= 1'b1;
                    state   <= ST_ERROR; // reset or ctrl bit4 clear then restart
                end

                // -------------------------------------------------
                default: begin
                    spi_cs_high <= 1'b1;
                    state_error <= 1'b1;
                    state <= ST_ERROR;
                end
            endcase
`ifdef SPI_BYPASS
            // Give reset priority over the case statement, including errors.
            if (soft_reset) begin
                state          <= ST_RESET;
                state_error    <= 1'b0;
                cmd_i          <= 7'd0;
                spi_tx_start   <= 1'b0;
                spi_tx_start_d <= 1'b0;
                fifo_push      <= 1'b0;
                crc_write1     <= 1'b0;
                crc_write2     <= 1'b0;
            end
`endif
        end
    end

    // debug
    wire [7:0] fifo_rd0 = fifo_R_mem[0][7:0];
    wire [7:0] fifo_rd1 = fifo_R_mem[0][15:8];
    wire [7:0] fifo_rd2 = fifo_R_mem[0][23:16];
    wire [7:0] fifo_rd3 = fifo_R_mem[0][31:24];

    // debug
    wire [7:0] fifo_wd0 = fifo_W_mem[0];
    wire [7:0] fifo_wd1 = fifo_W_mem[1];
    wire [7:0] fifo_wd2 = fifo_W_mem[2];
    wire [7:0] fifo_wd3 = fifo_W_mem[3];

endmodule
