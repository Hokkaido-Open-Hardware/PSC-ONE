// ===================================================================
// cache_dma_controller  (for packed dm_cache_tag / write-first RAMs)
//   - 16B line, Direct-Mapped, Write-back / Write-no-allocate
//   - Sync-read 1clk (tag/data) に整合（ISSUE → READ → COMPARE）
//   - mem_req_ready で外部要求をゲート
//   - FPGA向け：BRAMはリセットせず、起動時に S_INIT で全ライン invalid 化
//
// burst_mode = 0:
//   通常32bit READ
//
// burst_mode = 1:
//   READ HIT / READ ALLOC後に128bit lineを32bit x 4連続返却
//   cpu_readyを4clk連続assert
//
// NISHIHARU
// ===================================================================
`timescale 1ns/1ps

module cache_dma_controller #(
    parameter int ADDR_WIDTH          = 32,
    parameter int CPU_DATA_WIDTH      = 32,
    parameter int CACHE_DATA_WIDTH    = 128,
    parameter int MAIN_MEM_DATA_WIDTH = 128,
    parameter int CPU_MON_COUNT_WIDTH = 32,
    parameter int TAGMSB              = 31,
    parameter int TAGLSB              = 14,
    parameter int TAG_WIDTH           = TAGMSB - TAGLSB + 1,
    parameter int TAG_ENTRY_WIDTH     = TAG_WIDTH + 2
)(
    input  logic                           clock,
    input  logic                           reset_n,
    input  logic                           cpu_valid,
    input  logic                           cpu_rw,
    input  logic [ADDR_WIDTH-1:0]          cpu_addr,
    input  logic [CPU_DATA_WIDTH-1:0]      cpu_data,
    input  logic                           burst_mode,
    output logic                           cpu_ready,
    output logic [CPU_DATA_WIDTH-1:0]      cpu_data_out,
    output logic                           cpu_req_ready,
    input  logic                           cpu_cache_clear,
    input  logic                           mem_ready,
    input  logic [MAIN_MEM_DATA_WIDTH-1:0] mem_data_in,
    input  logic                           mem_req_ready,
    output logic                           mem_valid,
    output logic                           mem_rw,
    output logic [ADDR_WIDTH-1:0]          mem_addr,
    output logic [MAIN_MEM_DATA_WIDTH-1:0] mem_data_out,
    output logic                           cache_hit_pulse,
    output logic                           cache_miss_pulse
);

    localparam int INDEX_WIDTH_BA = TAGLSB - 4;
    localparam int USED_BITS_BA   = TAG_WIDTH + INDEX_WIDTH_BA + 4;
    localparam int DEPTH          = (1 << INDEX_WIDTH_BA);

    typedef enum logic [3:0] {
        S_INIT         = 4'd0,
        S_IDLE         = 4'd1,
        S_LOOKUP_ISSUE = 4'd2,
        S_LOOKUP_READ  = 4'd3,
        S_COMPARE      = 4'd4,
        S_WRITEBACK    = 4'd5,
        S_ALLOC_WAIT   = 4'd6,
        S_ALLOC_RESP   = 4'd7,
        S_POST_WBALLOC = 4'd8,
        S_BURST_RESP   = 4'd9
    } state_t;

    state_t state;

    assign cpu_req_ready = (state == S_IDLE);

    logic [INDEX_WIDTH_BA-1:0] init_idx;

    logic                      req_is_write;
    logic [ADDR_WIDTH-1:0]     req_addr_w;
    logic [CPU_DATA_WIDTH-1:0] req_wdata;
    logic [1:0]                req_word_sel_r;
    logic                      req_burst_mode;

    logic [CACHE_DATA_WIDTH-1:0] burst_line_r;
    logic [1:0]                  burst_word_idx;

    logic cpu_cache_clear_d1;
    logic cpu_cache_clear_slot;

    logic [ADDR_WIDTH-1:0] cpu_byte_addr;
    logic [ADDR_WIDTH-1:0] cpu_word_addr;

    assign cpu_byte_addr = {cpu_addr[ADDR_WIDTH-1:2], 2'b00};
    assign cpu_word_addr = cpu_addr >> 2;

    logic [INDEX_WIDTH_BA-1:0] cur_index_r;
    logic [TAG_WIDTH-1:0]      cur_tag_r;

    logic                       tag_we;
    logic [TAG_ENTRY_WIDTH-1:0] tag_write;
    logic [TAG_ENTRY_WIDTH-1:0] tag_read;

    logic [TAG_WIDTH-1:0] tag_read_tag;
    logic                 tag_read_valid;
    logic                 tag_read_dirty;

    assign tag_read_tag   = tag_read[TAG_ENTRY_WIDTH-1:2];
    assign tag_read_valid = tag_read[1];
    assign tag_read_dirty = tag_read[0];

    logic                        data_we;
    logic [CACHE_DATA_WIDTH-1:0] data_write;
    logic [CACHE_DATA_WIDTH-1:0] data_read;

    logic [TAG_WIDTH-1:0]        victim_tag_r;
    logic                        victim_valid_r;
    logic                        victim_dirty_r;
    logic [CACHE_DATA_WIDTH-1:0] line_read_r;
    logic [CACHE_DATA_WIDTH-1:0] fill_line_r;

    logic                      cpu_req_slot_valid;
    logic [ADDR_WIDTH-1:0]     cpu_word_addr_slot;
    logic [ADDR_WIDTH-1:0]     cpu_byte_addr_slot;
    logic                      cpu_rw_slot;
    logic [CPU_DATA_WIDTH-1:0] cpu_data_slot;
    logic                      cpu_burst_mode_slot;

    function automatic [31:0] pick_word(
        input [127:0] line,
        input [1:0]   sel
    );
        begin
            case (sel)
                2'b00: pick_word = line[31:0];
                2'b01: pick_word = line[63:32];
                2'b10: pick_word = line[95:64];
                default: pick_word = line[127:96];
            endcase
        end
    endfunction

    function automatic [127:0] place_word(
        input [127:0] line,
        input [1:0]   sel,
        input [31:0]  w
    );
        logic [127:0] t;
        begin
            t = line;
            case (sel)
                2'b00: t[31:0]   = w;
                2'b01: t[63:32]  = w;
                2'b10: t[95:64]  = w;
                2'b11: t[127:96] = w;
            endcase
            place_word = t;
        end
    endfunction

    function automatic [ADDR_WIDTH-1:0] alloc_addr_ba_f(
        input [ADDR_WIDTH-1:0] addr
    );
        begin
            alloc_addr_ba_f = {addr[ADDR_WIDTH-1:4], 4'b0000};
        end
    endfunction

    function automatic [ADDR_WIDTH-1:0] wb_addr_ba_f(
        input [TAG_WIDTH-1:0]      tag_i,
        input [INDEX_WIDTH_BA-1:0] index_i
    );
        begin
            wb_addr_ba_f = {
                {(ADDR_WIDTH-USED_BITS_BA){1'b0}},
                tag_i,
                index_i,
                4'b0000
            };
        end
    endfunction

    logic [ADDR_WIDTH-1:0]      victim_addr_ba;
    logic [CACHE_DATA_WIDTH-1:0] ZERO_LINE;

    assign victim_addr_ba = wb_addr_ba_f(victim_tag_r, cur_index_r);
    assign ZERO_LINE      = '0;

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            state                 <= S_INIT;
            init_idx              <= '0;
            cpu_req_slot_valid    <= 1'b0;
            cpu_word_addr_slot    <= '0;
            cpu_byte_addr_slot    <= '0;
            cpu_rw_slot           <= 1'b0;
            cpu_data_slot         <= '0;
            cpu_burst_mode_slot   <= 1'b0;
            mem_valid             <= 1'b0;
            mem_rw                <= 1'b0;
            mem_addr              <= '0;
            mem_data_out          <= '0;
            cpu_ready             <= 1'b0;
            cpu_data_out          <= '0;
            cpu_cache_clear_d1    <= 1'b0;
            cpu_cache_clear_slot  <= 1'b0;
            tag_we                <= 1'b0;
            tag_write             <= '0;
            data_we               <= 1'b0;
            data_write            <= '0;
            req_is_write          <= 1'b0;
            req_addr_w            <= '0;
            req_wdata             <= '0;
            req_word_sel_r        <= 2'b00;
            req_burst_mode        <= 1'b0;
            cur_index_r           <= '0;
            cur_tag_r             <= '0;
            victim_tag_r          <= '0;
            victim_valid_r        <= 1'b0;
            victim_dirty_r        <= 1'b0;
            line_read_r           <= '0;
            fill_line_r           <= '0;
            burst_line_r          <= '0;
            burst_word_idx        <= 2'd0;
            cache_hit_pulse       <= 1'b0;
            cache_miss_pulse      <= 1'b0;
        end else begin
            mem_valid             <= 1'b0;
            cpu_ready             <= 1'b0;
            tag_we                <= 1'b0;
            data_we               <= 1'b0;
            cache_hit_pulse       <= 1'b0;
            cache_miss_pulse      <= 1'b0;

            if (cpu_valid) begin
                cpu_req_slot_valid   <= 1'b1;
                cpu_word_addr_slot   <= cpu_word_addr;
                cpu_byte_addr_slot   <= cpu_byte_addr;
                cpu_rw_slot          <= cpu_rw;
                cpu_data_slot        <= cpu_data;
                cpu_burst_mode_slot  <= burst_mode;
            end

            cpu_cache_clear_d1 <= cpu_cache_clear;

            if (cpu_cache_clear && !cpu_cache_clear_d1) begin
                cpu_cache_clear_slot <= 1'b1;
            end

            case (state)
                S_INIT: begin
                    cur_index_r <= init_idx;
                    tag_write   <= '0;
                    tag_we      <= 1'b1;
                    if (init_idx == DEPTH-1) begin
                        init_idx <= '0;
                        state    <= S_IDLE;
                    end else begin
                        init_idx <= init_idx + 1'b1;
                    end
                end

                S_IDLE: begin
                    if (cpu_req_slot_valid) begin
                        cpu_req_slot_valid <= 1'b0;
                        req_is_write       <= cpu_rw_slot;
                        req_addr_w         <= cpu_byte_addr_slot;
                        req_wdata          <= cpu_data_slot;
                        req_word_sel_r     <= cpu_word_addr_slot[1:0];
                        req_burst_mode     <= cpu_burst_mode_slot;
                        cur_index_r        <= cpu_byte_addr_slot[TAGLSB-1:4];
                        cur_tag_r          <= cpu_byte_addr_slot[TAGMSB:TAGLSB];
                        state              <= S_LOOKUP_ISSUE;
                    end else if (cpu_cache_clear_slot) begin
                        init_idx             <= '0;
                        cpu_cache_clear_slot <= 1'b0;
                        state                <= S_INIT;
                    end
                end

                S_LOOKUP_ISSUE: begin
                    state <= S_LOOKUP_READ;
                end

                S_LOOKUP_READ: begin
                    victim_tag_r    <= tag_read_tag;
                    victim_valid_r  <= tag_read_valid;
                    victim_dirty_r  <= tag_read_dirty;
                    line_read_r     <= data_read;
                    state           <= S_COMPARE;
                end

                S_COMPARE: begin
                    if (victim_valid_r && (victim_tag_r == cur_tag_r)) begin
                        if (req_is_write) begin
                            data_write        <= place_word(
                                line_read_r,
                                req_word_sel_r,
                                req_wdata
                            );
                            data_we           <= 1'b1;
                            tag_write         <= {
                                victim_tag_r,
                                1'b1,
                                1'b1
                            };
                            tag_we            <= 1'b1;
                            cpu_ready         <= 1'b1;
                            cache_hit_pulse   <= 1'b1;
                            state             <= S_IDLE;
                        end else begin
                            if (req_burst_mode) begin
                                burst_line_r       <= line_read_r;
                                burst_word_idx     <= 2'd0;
                                cache_hit_pulse    <= 1'b1;
                                state              <= S_BURST_RESP;
                            end else begin
                                cpu_data_out       <= pick_word(
                                    line_read_r,
                                    req_word_sel_r
                                );
                                cpu_ready          <= 1'b1;
                                cache_hit_pulse    <= 1'b1;
                                state              <= S_IDLE;
                            end
                        end
                    end else begin
                        if (victim_valid_r && victim_dirty_r) begin
                            if (mem_req_ready) begin
                                mem_valid           <= 1'b1;
                                mem_rw              <= 1'b1;
                                mem_addr            <= victim_addr_ba;
                                mem_data_out        <= line_read_r;
                                cache_miss_pulse    <= 1'b1;
                                state               <= S_WRITEBACK;
                            end
                        end else if (!req_is_write) begin
                            if (mem_req_ready) begin
                                mem_valid           <= 1'b1;
                                mem_rw              <= 1'b0;
                                mem_addr            <= alloc_addr_ba_f(req_addr_w);
                                cache_miss_pulse    <= 1'b1;
                                state               <= S_ALLOC_WAIT;
                            end
                        end else begin
                            data_write         <= place_word(
                                ZERO_LINE,
                                req_word_sel_r,
                                req_wdata
                            );
                            data_we            <= 1'b1;
                            tag_write          <= {
                                cur_tag_r,
                                1'b1,
                                1'b1
                            };
                            tag_we             <= 1'b1;
                            cpu_ready          <= 1'b1;
                            cache_miss_pulse   <= 1'b1;
                            state              <= S_IDLE;
                        end
                    end
                end

                S_WRITEBACK: begin
                    if (mem_ready) begin
                        if (!req_is_write) begin
                            state <= S_POST_WBALLOC;
                        end else begin
                            data_write       <= place_word(
                                ZERO_LINE,
                                req_word_sel_r,
                                req_wdata
                            );
                            data_we          <= 1'b1;
                            tag_write        <= {
                                cur_tag_r,
                                1'b1,
                                1'b1
                            };
                            tag_we           <= 1'b1;
                            cpu_ready        <= 1'b1;
                            state            <= S_IDLE;
                        end
                    end
                end

                S_POST_WBALLOC: begin
                    if (mem_req_ready) begin
                        mem_valid   <= 1'b1;
                        mem_rw      <= 1'b0;
                        mem_addr    <= alloc_addr_ba_f(req_addr_w);
                        state       <= S_ALLOC_WAIT;
                    end
                end

                S_ALLOC_WAIT: begin
                    if (mem_ready) begin
                        fill_line_r       <= mem_data_in;
                        data_write        <= mem_data_in;
                        data_we           <= 1'b1;
                        tag_write         <= {
                            cur_tag_r,
                            1'b1,
                            1'b0
                        };
                        tag_we            <= 1'b1;
                        if (req_burst_mode) begin
                            burst_line_r   <= mem_data_in;
                            burst_word_idx <= 2'd0;
                            state          <= S_BURST_RESP;
                        end else begin
                            state          <= S_ALLOC_RESP;
                        end
                    end
                end

                S_ALLOC_RESP: begin
                    cpu_data_out <= pick_word(
                        fill_line_r,
                        req_word_sel_r
                    );
                    cpu_ready    <= 1'b1;
                    state        <= S_IDLE;
                end

                S_BURST_RESP: begin
                    cpu_ready <= 1'b1;

                    case (burst_word_idx)
                        2'd0: cpu_data_out <= burst_line_r[31:0];
                        2'd1: cpu_data_out <= burst_line_r[63:32];
                        2'd2: cpu_data_out <= burst_line_r[95:64];
                        2'd3: cpu_data_out <= burst_line_r[127:96];
                    endcase

                    if (burst_word_idx == 2'd3) begin
                        burst_word_idx <= 2'd0;
                        state          <= S_IDLE;
                    end else begin
                        burst_word_idx <= burst_word_idx + 2'd1;
                    end
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

    dm_cache_tag #(
        .TAG_WIDTH   (TAG_ENTRY_WIDTH),
        .INDEX_WIDTH (INDEX_WIDTH_BA)
    ) u_tag (
        .clk         (clock),
        .we          (tag_we),
        .index       (cur_index_r),
        .tag_write   (tag_write),
        .tag_read    (tag_read)
    );

    dm_cache_data #(
        .DATA_WIDTH  (CACHE_DATA_WIDTH),
        .INDEX_WIDTH (INDEX_WIDTH_BA)
    ) u_data (
        .clk         (clock),
        .we          (data_we),
        .index       (cur_index_r),
        .data_write  (data_write),
        .data_read   (data_read)
    );

endmodule