// ===================================================================
// cache_dma_controller  (for packed dm_cache_tag / write-first RAMs)
//   - 32B line, write-back / zero-filled store-miss allocation
//   - Set PSC_CACHE_2WAY=1 for two ways at the same capacity (one extra lookup cycle).
//   - Sync-read 1clk; tag判定を保持（IDLE → [ISSUE] → READ → COMPARE）
//   - mem_req_ready で外部要求をゲート
//   - FPGA向け：BRAMはリセットせず、起動時に S_INIT で全ライン invalid 化
//
// burst_mode = 0:
//   通常32bit READ
//
// burst_mode = 1:
//   READ HIT / READ ALLOC後に256bit lineを32bit x 8連続返却
//   cpu_readyを8clk連続assert
//
// NISHIHARU
// ===================================================================
`timescale 1ns/1ps

module cache_dma_controller #(
    parameter int PSC_CACHE_2WAY      = 0,
    parameter int ADDR_WIDTH          = 32,
    parameter int CPU_DATA_WIDTH      = 32,
    parameter int CACHE_DATA_WIDTH    = 256,
    parameter int MAIN_MEM_DATA_WIDTH = 256,
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

    localparam integer LINE_BYTES = CACHE_DATA_WIDTH / 8;
    localparam integer LINE_WORDS = CACHE_DATA_WIDTH / CPU_DATA_WIDTH;
    localparam integer OFFSET_BITS = $clog2(LINE_BYTES);
    localparam integer WORD_BITS = $clog2(LINE_WORDS);

    // TAGLSB always describes the total data capacity.
    localparam int WAY_BITS       = (PSC_CACHE_2WAY != 0) ? 1 : 0;
    localparam int TAG_LOW        = TAGLSB - WAY_BITS;
    localparam int LINE_TAG_WIDTH = TAG_WIDTH + WAY_BITS;
    localparam int ENTRY_WIDTH    = TAG_ENTRY_WIDTH + WAY_BITS;
    localparam int SET_BITS       = TAG_LOW - OFFSET_BITS;
    localparam int SET_COUNT      = 1 << SET_BITS;
    // A two-line cache in two-way mode has one set, addressed by constant zero.
    localparam int SET_ADDR_WIDTH = SET_BITS > 0 ? SET_BITS : 1;
    localparam int DATA_ADDR_WIDTH = TAGLSB - OFFSET_BITS;

    typedef enum logic [3:0] {
        S_INIT         = 4'd0,
        S_IDLE         = 4'd1,
        S_LOOKUP_ISSUE = 4'd2,
        S_LOOKUP_READ  = 4'd3,
        S_COMPARE      = 4'd4,
        S_WRITEBACK    = 4'd5,
        S_ALLOC_WAIT   = 4'd6,
        S_WAY_READ     = 4'd7,
        S_POST_WBALLOC = 4'd8,
        S_BURST_RESP   = 4'd9
    } state_t;

    state_t state;

    assign cpu_req_ready  = (state == S_IDLE);

    logic [SET_ADDR_WIDTH-1:0] init_idx;

    logic                      req_is_write;
    logic [ADDR_WIDTH-1:0]     req_addr_w;
    logic [CPU_DATA_WIDTH-1:0] req_wdata;
    logic [WORD_BITS-1:0]                req_word_sel_r;
    logic                      req_burst_mode;

    // Word 0 is returned immediately; only the remaining seven words are held.
    logic [CACHE_DATA_WIDTH-33:0]                burst_tail_r;
    logic [WORD_BITS-1:0]                  burst_word_idx;

    logic cpu_cache_clear_d1;
    logic cpu_cache_clear_slot;

    // A burst read always returns word zero first. Decode this at capture
    // so the response path from the data RAM needs only the word selector.
    wire [WORD_BITS-1:0] first_word = (burst_mode && !cpu_rw)
        ? '0 : cpu_addr[OFFSET_BITS-1:2];
    wire [ADDR_WIDTH-1:0] cpu_byte_addr =
        {cpu_addr[ADDR_WIDTH-1:OFFSET_BITS], first_word, 2'b00};

    logic [SET_ADDR_WIDTH-1:0] cur_index_r;
    logic [LINE_TAG_WIDTH-1:0] cur_tag_r;

    logic                       tag_we;
    logic [ENTRY_WIDTH-1:0] tag_write;
    logic [ENTRY_WIDTH-1:0] tag_read;

    logic [LINE_TAG_WIDTH-1:0] tag_read_tag;
    logic                 tag_read_valid;
    logic                 tag_read_dirty;

    assign tag_read_tag   = tag_read[ENTRY_WIDTH-1:2];
    assign tag_read_valid = tag_read[1];
    assign tag_read_dirty = tag_read[0];

    logic                        data_we;
    logic [CACHE_DATA_WIDTH-1:0] data_write;
    logic [CACHE_DATA_WIDTH-1:0] data_read;

    logic                      cpu_req_slot_valid;
    logic [ADDR_WIDTH-1:0]     cpu_byte_addr_slot;
    logic                      cpu_rw_slot;
    logic [CPU_DATA_WIDTH-1:0] cpu_data_slot;
    logic                      cpu_burst_mode_slot;

    function automatic [31:0] pick_word(
        input [CACHE_DATA_WIDTH-1:0] line,
        input [WORD_BITS-1:0] sel
    );
        begin
            pick_word = line[sel*CPU_DATA_WIDTH +: CPU_DATA_WIDTH];
        end
    endfunction

    function automatic [ADDR_WIDTH-1:0] alloc_addr_ba_f(
        input [ADDR_WIDTH-1:0] addr
    );
        begin
            alloc_addr_ba_f = {addr[ADDR_WIDTH-1:OFFSET_BITS], {OFFSET_BITS{1'b0}}};
        end
    endfunction

    wire [ADDR_WIDTH-1:0] victim_addr_ba =
        (ADDR_WIDTH'(tag_read_tag) << TAG_LOW) | (ADDR_WIDTH'(cur_index_r) << OFFSET_BITS);

    wire [SET_ADDR_WIDTH-1:0] slot_index =
        SET_BITS == 0 ? '0 : SET_ADDR_WIDTH'(cpu_byte_addr_slot >> OFFSET_BITS);

    // Read the next tag during IDLE when the single RAM port is free.
    // A pending tag write (including the final INIT write) must keep the old
    // index and gets one extra ISSUE cycle. Data RAM retains its original
    // registered address schedule in both cases.
    wire early_tag_read                       = (state == S_IDLE) && cpu_req_slot_valid && !tag_we;
    wire [SET_ADDR_WIDTH-1:0] tag_index       = early_tag_read
        ? slot_index : cur_index_r;
    wire [ENTRY_WIDTH-1:0] tag0;
    logic lookup_hit_r;
    logic lookup_dirty_r;

    wire [DATA_ADDR_WIDTH-1:0] data_index;
    wire write_tag0;
    wire lookup_complete;
    wire lookup_hit;

    if (PSC_CACHE_2WAY != 0) begin : g_two_way
        wire [ENTRY_WIDTH-1:0] tag1;
        // Compare small tag slices in parallel at the tag RAM outputs. The
        // reduction and way selection then feed the registered data RAM address.
        localparam int GROUP_BITS = 4;
        localparam int TAG_GROUPS = (LINE_TAG_WIDTH + GROUP_BITS - 1) / GROUP_BITS;
        localparam int PADDED_WIDTH = TAG_GROUPS * GROUP_BITS;
        wire [PADDED_WIDTH-1:0] compare_tag0 = PADDED_WIDTH'(tag0[ENTRY_WIDTH-1:2]);
        wire [PADDED_WIDTH-1:0] compare_tag1 = PADDED_WIDTH'(tag1[ENTRY_WIDTH-1:2]);
        wire [PADDED_WIDTH-1:0] request_tag = PADDED_WIDTH'(cur_tag_r);
        logic [TAG_GROUPS-1:0] match0_r, match1_r;
        for (genvar g = 0; g < TAG_GROUPS; g = g + 1) begin : g_tag_match
            always_ff @(posedge clock) begin
                if (state == S_LOOKUP_READ) begin
                    match0_r[g] <= compare_tag0[g*GROUP_BITS +: GROUP_BITS] == request_tag[g*GROUP_BITS +: GROUP_BITS];
                    match1_r[g] <= compare_tag1[g*GROUP_BITS +: GROUP_BITS] == request_tag[g*GROUP_BITS +: GROUP_BITS];
                end
            end
        end
        logic valid0_r, valid1_r, replace_way1_r;
        wire hit0 = valid0_r && (&match0_r);
        wire hit1 = valid1_r && (&match1_r);
        // Read the replacement bit alongside the synchronous tag RAMs. This
        // port is only consumed on a lookup, after any preceding LRU write.
        logic lru_read;
        (* ram_style = "block" *) logic lru_way [0:SET_COUNT-1];
        // Prefer an invalid way; LRU is consulted only after both ways were used.
        wire replace_way1 = tag0[1] && (!tag1[1] || lru_read);
        wire selected_way = hit1 || (!hit0 && replace_way1_r);
        assign tag_read = selected_way ? tag1 : tag0;
        assign data_index =
            (DATA_ADDR_WIDTH'(selected_way) << SET_BITS) | DATA_ADDR_WIDTH'(cur_index_r);
        // tag_write and tag_we are registered together. A clear invalidates
        // both tags, including the last delayed write after S_INIT.
        assign write_tag0 = tag_we && (!tag_write[1] || !selected_way);
        wire write_tag1 = tag_we && (!tag_write[1] || selected_way);

        // Keep this lookup's decision stable through writeback and refill.
        always_ff @(posedge clock) begin
            if (state == S_LOOKUP_READ) begin
                valid0_r       <= tag0[1];
                valid1_r       <= tag1[1];
                replace_way1_r <= replace_way1;
            end
        end

        always_ff @(posedge clock) begin
            lru_read <= lru_way[tag_index];
            if (state == S_COMPARE)
                lru_way[cur_index_r] <= !selected_way;
        end

        dm_cache_tag #(
            .TAG_WIDTH   (ENTRY_WIDTH),
            .INDEX_WIDTH (SET_ADDR_WIDTH),
            .DEPTH       (SET_COUNT)
        ) u_tag_way1 (
            .clk         (clock),
            .we          (write_tag1),
            .index       (tag_index),
            .tag_write   (tag_write),
            .tag_read    (tag1)
        );

        assign lookup_complete = (state == S_WAY_READ);
        assign lookup_hit = hit0 || hit1;
    end else begin : g_direct_mapped
        assign tag_read = tag0;
        assign data_index = cur_index_r;
        assign write_tag0 = tag_we;
        assign lookup_complete = (state == S_LOOKUP_READ);
        assign lookup_hit = tag_read_valid && (tag_read_tag == cur_tag_r);
    end

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            lookup_hit_r   <= 1'b0;
            lookup_dirty_r <= 1'b0;
        end else if (lookup_complete) begin
            lookup_hit_r   <= lookup_hit;
            lookup_dirty_r <= tag_read_valid && tag_read_dirty;
        end
    end

    // Disjoint events keep FSM priorities out of the wide register enables.
    wire cache_match                          = lookup_hit_r;
    wire dirty_victim                         = lookup_dirty_r;
    wire compare_hit                          = (state == S_COMPARE) && cache_match;
    wire compare_miss                         = (state == S_COMPARE) && !cache_match;
    wire write_hit                            = compare_hit && req_is_write;
    wire write_new                            = req_is_write &&
        ((compare_miss && !dirty_victim) ||
         ((state == S_WRITEBACK) && mem_ready));
    wire cache_fill                           = (state == S_ALLOC_WAIT) && mem_ready;
    wire write_event                          = write_hit || write_new || cache_fill;

    // A store miss installs the selected word with zero in the other words.
    // A store hit preserves the other words. Decode each lane only once.
    wire preserve_line                        = (state == S_COMPARE) && cache_match;
    wire [CACHE_DATA_WIDTH-1:0] store_base    =
        data_read & {CACHE_DATA_WIDTH{preserve_line}};
    wire [CACHE_DATA_WIDTH-1:0] store_line;
    genvar word_lane;
    generate
        for (word_lane = 0; word_lane < LINE_WORDS; word_lane = word_lane + 1) begin: g_store
            assign store_line[word_lane*32 +: 32] = (req_word_sel_r == word_lane)
                ? req_wdata : store_base[word_lane*32 +: 32];
        end
    endgenerate
    wire [CACHE_DATA_WIDTH-1:0] write_data    = req_is_write ? store_line : mem_data_in;

    wire eviction_request                     = compare_miss && dirty_victim && mem_req_ready;
    wire allocation_request                   = mem_req_ready &&
        ((compare_miss && !dirty_victim && !req_is_write) || (state == S_POST_WBALLOC));
    wire memory_request                       = eviction_request || allocation_request;
    wire [ADDR_WIDTH-1:0] memory_request_addr = eviction_request
        ? victim_addr_ba : alloc_addr_ba_f(req_addr_w);

    wire read_hit                             = compare_hit && !req_is_write;
    wire read_response                        = read_hit || cache_fill || (state == S_BURST_RESP);
    wire response_valid                       = write_hit || write_new || read_response;
    if (PSC_CACHE_2WAY != 0) begin : g_two_way_response
        // Register the RAM word separately from refill/burst words: a hit's
        // BRAM-to-register path then contains only the word selector.
        logic [CPU_DATA_WIDTH-1:0] hit_word_r, other_word_r;
        logic last_read_hit;
        wire [CPU_DATA_WIDTH-1:0] other_word = (state == S_ALLOC_WAIT)
            ? pick_word(mem_data_in, req_word_sel_r)
            : pick_word({burst_tail_r, 32'b0}, burst_word_idx);
        always_ff @(posedge clock or negedge reset_n) begin
            if (!reset_n) begin
                last_read_hit <= 1'b0;
                hit_word_r    <= '0;
                other_word_r  <= '0;
            end else if (read_response) begin
                last_read_hit <= read_hit;
                if (read_hit)
                    hit_word_r <= pick_word(data_read, req_word_sel_r);
                else
                    other_word_r <= other_word;
            end
        end
        assign cpu_data_out = last_read_hit ? hit_word_r : other_word_r;
    end else begin : g_direct_response
        wire [CPU_DATA_WIDTH-1:0] response_data =
            ({CPU_DATA_WIDTH{state == S_COMPARE}} & pick_word(data_read, req_word_sel_r)) |
            ({CPU_DATA_WIDTH{state == S_ALLOC_WAIT}} & pick_word(mem_data_in, req_word_sel_r)) |
            ({CPU_DATA_WIDTH{state == S_BURST_RESP}} & pick_word({burst_tail_r, 32'b0}, burst_word_idx));
        always_ff @(posedge clock or negedge reset_n) begin
            if (!reset_n)
                cpu_data_out <= '0;
            else if (read_response)
                cpu_data_out <= response_data;
        end
    end

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            data_write           <= '0;
            data_we              <= 1'b0;
            tag_write            <= '0;
            tag_we               <= 1'b0;
            mem_valid            <= 1'b0;
            mem_rw               <= 1'b0;
            mem_addr             <= '0;
            mem_data_out         <= '0;
            cpu_ready            <= 1'b0;
            cache_hit_pulse      <= 1'b0;
            cache_miss_pulse     <= 1'b0;
        end else begin
            // RAM consumes this register only with data_we; no hold mux or CE.
            data_write           <= write_data;
            data_we              <= write_event;
            tag_we               <= (state == S_INIT) || write_event;
            if (state == S_INIT)
                tag_write            <= '0;
            else if (write_event)
                tag_write            <= {cur_tag_r, 1'b1, !cache_fill};

            mem_valid            <= memory_request;
            if (memory_request) begin
                mem_rw               <= eviction_request;
                mem_addr             <= memory_request_addr;
            end
            if (eviction_request)
                mem_data_out         <= data_read;

            cpu_ready            <= response_valid;
            cache_hit_pulse      <= compare_hit;
            cache_miss_pulse     <= compare_miss &&
                (dirty_victim ? mem_req_ready : (req_is_write || mem_req_ready));
        end
    end

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            state                <= S_INIT;
            init_idx             <= '0;
            cpu_req_slot_valid   <= 1'b0;

            cpu_byte_addr_slot   <= '0;
            cpu_rw_slot          <= 1'b0;
            cpu_data_slot        <= '0;
            cpu_burst_mode_slot  <= 1'b0;

            cpu_cache_clear_d1   <= 1'b0;
            cpu_cache_clear_slot <= 1'b0;

            req_is_write         <= 1'b0;
            req_addr_w           <= '0;
            req_wdata            <= '0;
            req_word_sel_r       <= '0;
            req_burst_mode       <= 1'b0;
            cur_index_r          <= '0;
            cur_tag_r            <= '0;

            burst_tail_r         <= '0;
            burst_word_idx       <= '0;

        end else begin
            if (cpu_valid) begin
                cpu_req_slot_valid   <= 1'b1;

                cpu_byte_addr_slot   <= cpu_byte_addr;
                cpu_rw_slot          <= cpu_rw;
                cpu_data_slot        <= cpu_data;
                cpu_burst_mode_slot  <= burst_mode;
            end

            cpu_cache_clear_d1   <= cpu_cache_clear;

            if (cpu_cache_clear && !cpu_cache_clear_d1) begin
                cpu_cache_clear_slot <= 1'b1;
            end

            case (state)
                S_INIT: begin
                    cur_index_r <= init_idx;

                    if (init_idx == SET_ADDR_WIDTH'(SET_COUNT-1)) begin
                        init_idx             <= '0;
                        state                <= S_IDLE;
                    end else begin
                        init_idx             <= init_idx + 1'b1;
                    end
                end

                S_IDLE: begin
                    if (cpu_req_slot_valid) begin
                        cpu_req_slot_valid   <= 1'b0;
                        req_is_write         <= cpu_rw_slot;
                        req_addr_w           <= cpu_byte_addr_slot;
                        req_wdata            <= cpu_data_slot;
                        req_word_sel_r       <= cpu_byte_addr_slot[OFFSET_BITS-1:2];
                        req_burst_mode       <= cpu_burst_mode_slot;
                        cur_index_r          <= slot_index;
                        cur_tag_r            <= cpu_byte_addr_slot[TAGMSB:TAG_LOW];
                        state                <= tag_we ? S_LOOKUP_ISSUE : S_LOOKUP_READ;
                    end else if (cpu_cache_clear_slot) begin
                        init_idx             <= '0;
                        cpu_cache_clear_slot <= 1'b0;
                        state                <= S_INIT;
                    end
                end

                S_LOOKUP_ISSUE: begin
                    state       <= S_LOOKUP_READ;
                end

                S_LOOKUP_READ: state <= (PSC_CACHE_2WAY != 0) ? S_WAY_READ : S_COMPARE;
                S_WAY_READ:    state <= S_COMPARE;

                S_COMPARE: begin
                    if (cache_match) begin
                        if (req_is_write) begin
                            state          <= S_IDLE;
                        end else begin
                            if (req_burst_mode) begin
                                burst_tail_r   <= data_read[CACHE_DATA_WIDTH-1:32];
                                burst_word_idx <= 1;
                                state          <= S_BURST_RESP;
                            end else begin
                                state          <= S_IDLE;
                            end
                        end
                    end else begin
                        if (dirty_victim) begin
                            if (mem_req_ready) begin
                                state          <= S_WRITEBACK;
                            end
                        end else if (!req_is_write) begin
                            if (mem_req_ready) begin
                                state          <= S_ALLOC_WAIT;
                            end
                        end else begin
                            state          <= S_IDLE;
                        end
                    end
                end

                S_WRITEBACK: begin
                    if (mem_ready) begin
                        if (!req_is_write) begin
                            state          <= S_POST_WBALLOC;
                        end else begin
                            state          <= S_IDLE;
                        end
                    end
                end

                S_POST_WBALLOC: begin
                    if (mem_req_ready) begin
                        state                <= S_ALLOC_WAIT;
                    end
                end

                S_ALLOC_WAIT: begin
                    if (mem_ready) begin
                        if (req_burst_mode) begin
                            burst_tail_r   <= mem_data_in[CACHE_DATA_WIDTH-1:32];
                            burst_word_idx <= 1;
                            state          <= S_BURST_RESP;
                        end else begin
                            state          <= S_IDLE;
                        end
                    end
                end

                S_BURST_RESP: begin
                    if (burst_word_idx == LINE_WORDS-1) begin
                        burst_word_idx       <= '0;
                        state                <= S_IDLE;
                    end else begin
                        burst_word_idx       <= burst_word_idx + 1'b1;
                    end
                end

                default: begin
                    state       <= S_IDLE;
                end
            endcase
        end
    end

    dm_cache_tag #(
        .TAG_WIDTH   (ENTRY_WIDTH),
        .INDEX_WIDTH (SET_ADDR_WIDTH),
        .DEPTH       (SET_COUNT)
    ) u_tag (
        .clk         (clock),
        .we          (write_tag0),
        .index       (tag_index),
        .tag_write   (tag_write),
        .tag_read    (tag0)
    );

    dm_cache_data #(
        .DATA_WIDTH  (CACHE_DATA_WIDTH),
        .INDEX_WIDTH (DATA_ADDR_WIDTH)
    ) u_data (
        .clk         (clock),
        .we          (data_we),
        .index       (data_index),
        .data_write  (data_write),
        .data_read   (data_read)
    );

endmodule
