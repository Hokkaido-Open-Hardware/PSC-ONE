/*
NISHIHARU
*/
`timescale 1ns / 1ps

module sdram_controller #(
    parameter int CLK_FREQ_MHz           = 80,
    // SDRAM ADDR
    parameter int COL_ADDR_BUS_WIDTH     = 8,
    parameter int ROW_ADDR_BUS_WIDTH     = 11,
    parameter int BNK_ADDR_BUS_WIDTH     = 2,
    // DQ, DQM
    parameter int DQ_BUS_WIDTH           = 16,
    parameter int DQM_BUS_WIDTH          = 2,
    parameter int SD_ADDR_BUS_WIDTH      = 11,
    parameter int SDRAM_INIT_CNT         = (64 * CLK_FREQ_MHz) / 10, // 64us
    parameter int clk_dly_ps             = 1, // not use
    parameter int timing_CAS             = 3,
    parameter int timing_RCD             = 2,
    parameter int timing_RP              = 3,
    parameter int timing_MD              = 3,
    parameter int timing_RFC             = 8,
    // INNER Param
    parameter int CW                     = COL_ADDR_BUS_WIDTH,
    parameter int RW                     = ROW_ADDR_BUS_WIDTH,
    parameter int BW                     = BNK_ADDR_BUS_WIDTH,
    parameter int SDAW                   = SD_ADDR_BUS_WIDTH
)(
    input  logic                     clock,
    input  logic                     reset_n,
    input  logic [3:0]               rw_length, // 1,4,8
    output logic                     req_ready,
    output logic                     sdram_init_fin,
    // ==== READ要求（Bank/Row/Col 分離）====
    input  logic                     read_valid,
    output logic                     read_ready,
    input  logic [BW-1:0]            read_addr_ba,
    input  logic [RW-1:0]            read_addr_row,
    input  logic [CW-1:0]            read_addr_col,
    output logic [DQ_BUS_WIDTH-1:0]  read_data,
    // ==== WRITE要求（Bank/Row/Col 分離）====
    input  logic                     write_valid,
    output logic                     write_ready,
    input  logic [BW-1:0]            write_addr_ba,
    input  logic [RW-1:0]            write_addr_row,
    input  logic [CW-1:0]            write_addr_col,
    input  logic [DQ_BUS_WIDTH-1:0]  write_data,
    // ============ SDRAM IF ============
    output logic                     sdram_clk,
    output logic                     sdram_cs,
    output logic                     sdram_ras,
    output logic                     sdram_cas,
    output logic                     sdram_we,
    output logic [SDAW-1:0]          sdram_adr,
    output logic [BW-1:0]            sdram_ba,
    output logic [DQM_BUS_WIDTH-1:0] sdram_dqm,
    inout  wire  [DQ_BUS_WIDTH-1:0]  sdram_dq
);

    localparam int ROW_BITS = RW;
    localparam int COL_BITS = CW;
    localparam int BA_BITS  = BW;

    logic cs_r, ras_r, cas_r, we_r;
    logic init_cs_r, init_ras_r, init_cas_r, init_we_r;
    logic [SDAW-1:0] init_adr_r, adr_r;
    logic [BW-1:0] init_ba_r, ba_r;
    logic [DQM_BUS_WIDTH-1:0] init_dqm_r, dqm_r;
    logic [DQ_BUS_WIDTH-1:0] dq_out;
    logic dq_oe;

    assign sdram_clk = clock;
    assign sdram_cs  = !sdram_init_fin ? init_cs_r  : cs_r;
    assign sdram_ras = !sdram_init_fin ? init_ras_r : ras_r;
    assign sdram_cas = !sdram_init_fin ? init_cas_r : cas_r;
    assign sdram_we  = !sdram_init_fin ? init_we_r  : we_r;
    assign sdram_adr = !sdram_init_fin ? init_adr_r : adr_r;
    assign sdram_ba  = !sdram_init_fin ? init_ba_r  : ba_r;
    assign sdram_dqm = !sdram_init_fin ? init_dqm_r : dqm_r;
    assign sdram_dq  = dq_oe ? dq_out : {DQ_BUS_WIDTH{1'bz}};

    // 2 clock latch.
    logic [DQ_BUS_WIDTH-1:0] dq_in;
    logic [DQ_BUS_WIDTH-1:0] dq_d1;
    always_ff @(posedge clock) begin
        dq_in <= sdram_dq;
        dq_d1 <= dq_in;
    end

    // ----------------------------------------------------------
    // SDRAM 初期化処理
    // ----------------------------------------------------------
    typedef enum logic [3:0] {
        INIT_WAIT      = 4'd0,
        INIT_PRECHARGE = 4'd1,
        INIT_REFRESH1  = 4'd2,
        INIT_REFRESH2  = 4'd3,
        INIT_MODE      = 4'd4,
        INIT_FIN_WAIT  = 4'd5,
        INIT_DONE      = 4'd6
    } init_state_t;
    init_state_t init_state;
    logic [31:0] init_cnt_r;

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            sdram_init_fin <= 1'b0;
            init_state     <= INIT_WAIT;
            init_cnt_r     <= 32'd0;
            init_cs_r      <= 1'b0;
            init_ras_r     <= 1'b1;
            init_cas_r     <= 1'b1;
            init_we_r      <= 1'b1;
            init_adr_r     <= '0;
            init_ba_r      <= '0;
            init_dqm_r     <= '1;
        end else begin
            init_cs_r  <= 1'b0;
            init_ras_r <= 1'b1;
            init_cas_r <= 1'b1;
            init_we_r  <= 1'b1;
            init_cnt_r <= init_cnt_r + 32'd1;
            case (init_state)
                INIT_WAIT: begin
                    if (init_cnt_r == SDRAM_INIT_CNT) begin
                        init_state <= INIT_PRECHARGE;
                        init_cnt_r <= 32'd0;
                    end
                end
                INIT_PRECHARGE: begin
                    if (init_cnt_r == 32'd0) begin
                        init_ras_r <= 1'b0;
                        init_cas_r <= 1'b1;
                        init_we_r  <= 1'b0;
                        init_adr_r <= 11'h400; // PRECHARGE ALL
                    end else if (init_cnt_r == 32'd6) begin
                        init_state <= INIT_REFRESH1;
                        init_cnt_r <= 32'd0;
                    end
                end
                INIT_REFRESH1: begin
                    if (init_cnt_r == 32'd0) begin
                        init_ras_r <= 1'b0;
                        init_cas_r <= 1'b0;
                        init_we_r  <= 1'b1;
                    end else if (init_cnt_r == 32'd24) begin
                        init_state <= INIT_REFRESH2;
                        init_cnt_r <= 32'd0;
                    end
                end
                INIT_REFRESH2: begin
                    if (init_cnt_r == 32'd0) begin
                        init_ras_r <= 1'b0;
                        init_cas_r <= 1'b0;
                        init_we_r  <= 1'b1;
                    end else if (init_cnt_r == 32'd24) begin
                        init_state <= INIT_MODE;
                        init_cnt_r <= 32'd0;
                    end
                end
                INIT_MODE: begin
                    if (init_cnt_r == 32'd0) begin
                        init_ras_r <= 1'b0;
                        init_cas_r <= 1'b0;
                        init_we_r  <= 1'b0;
                        init_adr_r <= 11'h130;
                    end else if (init_cnt_r == 32'd14) begin
                        init_state <= INIT_FIN_WAIT;
                        init_cnt_r <= 32'd0;
                    end
                end
                INIT_FIN_WAIT: begin
                    if (init_cnt_r == 32'd60) begin
                        sdram_init_fin <= 1'b1;
                        init_state <= INIT_DONE;
                        init_cnt_r <= 32'd0;
                    end
                end
                INIT_DONE: begin
                    init_cnt_r <= 32'd0;
                end
                default: begin
                    init_state <= INIT_WAIT;
                end
            endcase
        end
    end

    // ----------------------------------------------------------
    // バッファと制御ロジック
    // ----------------------------------------------------------
    logic [BA_BITS-1:0] read_ba_buf [0:7];
    logic [ROW_BITS-1:0] read_row_buf [0:7];
    logic [COL_BITS-1:0] read_col_buf [0:7];
    logic [BA_BITS-1:0] write_ba_buf [0:7];
    logic [ROW_BITS-1:0] write_row_buf [0:7];
    logic [COL_BITS-1:0] write_col_buf [0:7];
    logic [DQ_BUS_WIDTH-1:0] write_data_buf [0:7];
    logic [3:0] read_count, write_count;
    logic [3:0] rw_index;
    logic buffered_read_start, buffered_write_start;

    typedef enum logic [4:0] {
        IDLE            = 5'd0,
        READ_ACTIVATE   = 5'd1,
        WAIT_TRCD_READ  = 5'd2,
        READ_CMD        = 5'd3,
        WAIT_CL         = 5'd4,
        READ_CMD_WAIT   = 5'd5,
        READ_PRECHARGE  = 5'd6,
        READ_TRP_WAIT   = 5'd7,
        READ_DONE       = 5'd8,
        WRITE_ACTIVATE  = 5'd9,
        WAIT_TRCD_WRITE = 5'd10,
        WRITE_CMD       = 5'd11,
        WRITE_CMD_WAIT  = 5'd12,
        WRITE_PRECHARGE = 5'd13,
        WAIT_TRP_WRITE  = 5'd14,
        WRITE_DONE      = 5'd15,
        REFRESH_START   = 5'd16,
        REFRESH_CMD     = 5'd17,
        REFRESH_WAIT    = 5'd18
    } state_t;
    state_t state;
    logic [4:0] wait_cnt;
    logic [4:0] read_cnt;

    // ----------------------------------------------------------
    // refresh
    // ----------------------------------------------------------
    localparam int REF_COUNT = (71 * CLK_FREQ_MHz) / 10;
    logic [11:0] ref_timer;
    logic refresh_req;
    logic refresh_req_pre10clk;
    assign refresh_req_pre10clk = (ref_timer > REF_COUNT - 10);
    assign req_ready = sdram_init_fin &&
                       (state == READ_DONE || state == WRITE_DONE || state == IDLE) &&
                       !refresh_req_pre10clk;

    // ----------------------------------------------------------
    // SDRAM main state machine
    // ----------------------------------------------------------
    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            state       <= IDLE;
            write_ready <= 1'b0;
            adr_r       <= '0;
            ba_r        <= '0;
            cs_r        <= 1'b0;
            ras_r       <= 1'b1;
            cas_r       <= 1'b1;
            we_r        <= 1'b1;
            dq_oe       <= 1'b0;
            dq_out      <= '0;
            dqm_r       <= '0;
            wait_cnt    <= 5'd0;
            rw_index    <= 4'd0;
            read_count  <= 4'd0;
            write_count <= 4'd0;
            buffered_read_start  <= 1'b0;
            buffered_write_start <= 1'b0;
        end else if (sdram_init_fin) begin
            cs_r  <= 1'b0;
            ras_r <= 1'b1;
            cas_r <= 1'b1;
            we_r  <= 1'b1;
            case (state)
                IDLE: begin
                    wait_cnt <= 5'd0;
                    if (refresh_req) begin
                        state <= REFRESH_START;
                    end else if (read_valid && read_count < rw_length) begin
                        read_ba_buf[read_count]  <= read_addr_ba;
                        read_row_buf[read_count] <= read_addr_row;
                        read_col_buf[read_count] <= read_addr_col;
                        read_count <= read_count + 4'd1;
                        if (read_count == rw_length - 4'd1) begin
                            buffered_read_start <= 1'b1;
                            rw_index <= 4'd0;
                            state <= READ_ACTIVATE;
                        end
                    end else if (write_valid && write_count < rw_length) begin
                        write_ba_buf[write_count]   <= write_addr_ba;
                        write_row_buf[write_count]  <= write_addr_row;
                        write_col_buf[write_count]  <= write_addr_col;
                        write_data_buf[write_count] <= write_data;
                        write_ready <= 1'b0;
                        write_count <= write_count + 4'd1;
                        if (write_count == rw_length - 4'd1) begin
                            buffered_write_start <= 1'b1;
                            rw_index <= 4'd0;
                            state <= WRITE_ACTIVATE;
                        end
                    end
                end
                // --- READ FLOW ---
                READ_ACTIVATE: begin
                    adr_r <= read_row_buf[0];
                    ba_r  <= read_ba_buf[0];
                    cs_r  <= 1'b0;
                    ras_r <= 1'b0;
                    cas_r <= 1'b1;
                    we_r  <= 1'b1;
                    wait_cnt <= 5'd0;
                    state <= WAIT_TRCD_READ;
                end
                WAIT_TRCD_READ: begin
                    cs_r  <= 1'b0;
                    ras_r <= 1'b1;
                    cas_r <= 1'b1;
                    we_r  <= 1'b1;
                    wait_cnt <= wait_cnt + 5'd1;
                    if (wait_cnt == timing_RCD) begin
                        wait_cnt <= 5'd0;
                        state <= READ_CMD;
                    end
                end
                READ_CMD: begin
                    if (rw_index == rw_length) begin
                        cs_r  <= 1'b0;
                        ras_r <= 1'b1;
                        cas_r <= 1'b1;
                        we_r  <= 1'b1;
                        state <= WAIT_CL;
                    end else begin
                        dq_oe <= 1'b0;
                        rw_index <= rw_index + 4'd1;
                        adr_r <= {3'b000, read_col_buf[rw_index]};
                        ba_r  <= read_ba_buf[rw_index];
                        cs_r  <= 1'b0;
                        ras_r <= 1'b1;
                        cas_r <= 1'b0;
                        we_r  <= 1'b1;
                        dqm_r <= '0;
                        wait_cnt <= 5'd0;
                    end
                end
                WAIT_CL: begin
                    cs_r  <= 1'b0;
                    ras_r <= 1'b1;
                    cas_r <= 1'b1;
                    we_r  <= 1'b1;
                    wait_cnt <= wait_cnt + 5'd1;
                    if (wait_cnt == timing_CAS) begin
                        wait_cnt <= 5'd0;
                        state <= READ_CMD_WAIT;
                    end
                end
                READ_CMD_WAIT: begin
                    cs_r  <= 1'b0;
                    ras_r <= 1'b1;
                    cas_r <= 1'b1;
                    we_r  <= 1'b1;
                    wait_cnt <= wait_cnt + 5'd1;
                    if (wait_cnt == timing_RP) begin
                        wait_cnt <= 5'd0;
                        state <= READ_PRECHARGE;
                    end
                end
                READ_PRECHARGE: begin
                    adr_r <= '0;
                    ba_r  <= read_ba_buf[0];
                    cs_r  <= 1'b0;
                    ras_r <= 1'b0;
                    cas_r <= 1'b1;
                    we_r  <= 1'b0;
                    wait_cnt <= 5'd0;
                    state <= READ_TRP_WAIT;
                end
                READ_TRP_WAIT: begin
                    cs_r  <= 1'b0;
                    ras_r <= 1'b1;
                    cas_r <= 1'b1;
                    we_r  <= 1'b1;
                    wait_cnt <= wait_cnt + 5'd1;
                    if (wait_cnt == timing_RP) begin
                        wait_cnt <= 5'd0;
                        state <= READ_DONE;
                    end
                end
                READ_DONE: begin
                    wait_cnt <= 5'd0;
                    read_count <= 4'd0;
                    buffered_read_start <= 1'b0;
                    state <= IDLE;
                end
                // --- WRITE FLOW ---
                WRITE_ACTIVATE: begin
                    adr_r <= write_row_buf[0];
                    ba_r  <= write_ba_buf[0];
                    cs_r  <= 1'b0;
                    ras_r <= 1'b0;
                    cas_r <= 1'b1;
                    we_r  <= 1'b1;
                    wait_cnt <= 5'd0;
                    state <= WAIT_TRCD_WRITE;
                end
                WAIT_TRCD_WRITE: begin
                    cs_r  <= 1'b0;
                    ras_r <= 1'b1;
                    cas_r <= 1'b1;
                    we_r  <= 1'b1;
                    wait_cnt <= wait_cnt + 5'd1;
                    if (wait_cnt == timing_RCD) begin
                        wait_cnt <= 5'd0;
                        state <= WRITE_CMD;
                    end
                end
                WRITE_CMD: begin
                    dqm_r <= '0;
                    if (rw_index == rw_length) begin
                        cs_r  <= 1'b0;
                        ras_r <= 1'b1;
                        cas_r <= 1'b1;
                        we_r  <= 1'b1;
                        state <= WRITE_CMD_WAIT;
                        wait_cnt <= 5'd0;
                        dq_oe <= 1'b0;
                        write_ready <= 1'b0;
                    end else begin
                        dq_oe <= 1'b1;
                        write_ready <= 1'b1;
                        rw_index <= rw_index + 4'd1;
                        dq_out <= write_data_buf[rw_index];
                        adr_r <= {3'b000, write_col_buf[rw_index]};
                        ba_r  <= write_ba_buf[rw_index];
                        cs_r  <= 1'b0;
                        ras_r <= 1'b1;
                        cas_r <= 1'b0;
                        we_r  <= 1'b0;
                    end
                end
                WRITE_CMD_WAIT: begin
                    cs_r  <= 1'b0;
                    ras_r <= 1'b1;
                    cas_r <= 1'b1;
                    we_r  <= 1'b1;
                    wait_cnt <= wait_cnt + 5'd1;
                    if (wait_cnt == timing_RP) begin
                        wait_cnt <= 5'd0;
                        state <= WRITE_PRECHARGE;
                    end
                end
                WRITE_PRECHARGE: begin
                    adr_r <= '0;
                    ba_r  <= write_ba_buf[0];
                    cs_r  <= 1'b0;
                    ras_r <= 1'b0;
                    cas_r <= 1'b1;
                    we_r  <= 1'b0;
                    wait_cnt <= 5'd0;
                    state <= WAIT_TRP_WRITE;
                end
                WAIT_TRP_WRITE: begin
                    cs_r  <= 1'b0;
                    ras_r <= 1'b1;
                    cas_r <= 1'b1;
                    we_r  <= 1'b1;
                    wait_cnt <= wait_cnt + 5'd1;
                    if (wait_cnt == timing_RP) begin
                        wait_cnt <= 5'd0;
                        state <= WRITE_DONE;
                    end
                end
                WRITE_DONE: begin
                    cs_r  <= 1'b0;
                    ras_r <= 1'b1;
                    cas_r <= 1'b1;
                    we_r  <= 1'b1;
                    write_ready <= 1'b0;
                    dq_oe <= 1'b0;
                    write_count <= 4'd0;
                    buffered_write_start <= 1'b0;
                    state <= IDLE;
                end
                // --- REFRESH ---
                REFRESH_START: begin
                    cs_r  <= 1'b0;
                    ras_r <= 1'b1;
                    cas_r <= 1'b1;
                    we_r  <= 1'b1;
                    wait_cnt <= wait_cnt + 5'd1;
                    if (wait_cnt == timing_MD) begin
                        wait_cnt <= 5'd0;
                        state <= REFRESH_CMD;
                    end
                end
                REFRESH_CMD: begin
                    cs_r  <= 1'b0;
                    ras_r <= 1'b0;
                    cas_r <= 1'b0;
                    we_r  <= 1'b1;
                    wait_cnt <= 5'd0;
                    state <= REFRESH_WAIT;
                end
                REFRESH_WAIT: begin
                    cs_r  <= 1'b0;
                    ras_r <= 1'b1;
                    cas_r <= 1'b1;
                    we_r  <= 1'b1;
                    wait_cnt <= wait_cnt + 5'd1;
                    if (wait_cnt == timing_RFC) begin
                        wait_cnt <= 5'd0;
                        state <= IDLE;
                    end
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

    // ----------------------------------------------------------
    // READ DQ 取り込み
    // ----------------------------------------------------------
    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            read_cnt   <= 5'd0;
            read_ready <= 1'b0;
            read_data  <= '0;
        end else begin
            if (state == IDLE) begin
                read_cnt   <= 5'd0;
                read_ready <= 1'b0;
            end
            if (state == READ_CMD ||
                state == WAIT_CL ||
                state == READ_CMD_WAIT ||
                state == READ_PRECHARGE) begin
                read_cnt <= read_cnt + 5'd1;
                if (read_cnt > timing_CAS + 5'd2 &&
                    read_cnt < rw_length + 5'd6) begin
                    read_ready <= 1'b1;
                    read_data <= dq_d1;
                end else begin
                    read_ready <= 1'b0;
                end
            end
        end
    end

    // ----------------------------------------------------------
    // refresh timer
    // ----------------------------------------------------------
    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            ref_timer   <= 12'd0;
            refresh_req <= 1'b0;
        end else if (sdram_init_fin) begin
            ref_timer <= ref_timer + 12'd1;
            if (ref_timer >= REF_COUNT) begin
                refresh_req <= 1'b1;
                if (state == REFRESH_START) begin
                    ref_timer   <= 12'd0;
                    refresh_req <= 1'b0;
                end
            end
        end
    end

endmodule