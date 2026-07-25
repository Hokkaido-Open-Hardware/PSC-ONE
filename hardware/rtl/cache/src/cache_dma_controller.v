// ===================================================================
// cache_dma_controller  (for packed dm_cache_tag / write-first RAMs)
//   - 16B line, Direct-Mapped, Write-back / Write-no-allocate
//   - Sync-read 1clk (tag/data) に整合（ISSUE → READ → COMPARE）
//   - mem_req_ready で外部要求をゲート
//   - 単一 PIO アドレスはキャッシュ迂回で即応答
//   - FPGA向け：BRAMはリセットせず、起動時に S_INIT で全ライン invalid 化
// ===================================================================
`timescale 1ns/1ps
module cache_dma_controller #(
    parameter ADDR_WIDTH          = 32,
    parameter CPU_DATA_WIDTH      = 32,
    parameter CACHE_DATA_WIDTH    = 128,
    parameter MAIN_MEM_DATA_WIDTH = 128,
    parameter CPU_MON_COUNT_WIDTH = 32,

    // アドレス切り出し
    parameter TAGMSB            = 31,
    parameter TAGLSB            = 14,   // 16B line → index=[13:4]
    parameter TAG_WIDTH         = TAGMSB - TAGLSB + 1,         // 例:18
    parameter TAG_ENTRY_WIDTH   = TAG_WIDTH + 2                // {tag,valid,dirty}
)(
    input  wire                           clock,
    input  wire                           reset_n,

    // --------- CPU リクエスト/レスポンス ---------
    input  wire                           cpu_valid,
    input  wire                           cpu_rw,          // 1:W, 0:R
    input  wire [ADDR_WIDTH-1:0]          cpu_addr,        // byte address
    input  wire [CPU_DATA_WIDTH-1:0]      cpu_data,
    output reg                            cpu_ready,
    output reg  [CPU_DATA_WIDTH-1:0]      cpu_data_out,
    output wire                           cpu_req_ready,

    // --------- Cache 制御信号 ---------
    input  wire                           cpu_cache_clear, 

    // --------- 外部メモリ（ライン転送） ---------
    input  wire                           mem_ready,       // 1ライン応答
    input  wire [MAIN_MEM_DATA_WIDTH-1:0] mem_data_in,
    input  wire                           mem_req_ready,   // 要求受付可

    // --------- メモリアクセス要求 ---------
    output reg                            mem_valid,       // 1clk パルス
    output reg                            mem_rw,          // 1:WB, 0:READ
    output reg  [ADDR_WIDTH-1:0]          mem_addr,        // byte addr (16B aligned推奨)
    output reg  [MAIN_MEM_DATA_WIDTH-1:0] mem_data_out,

    // --------- メモリアクセス要求 ---------
    output reg                            cache_hit_pulse,
    output reg                            cache_miss_pulse
);
    // ---------------- 定数/ローカル ----------------
    localparam integer INDEX_WIDTH_BA = TAGLSB - 4;   // 例:10（index=[13:4]）
    localparam integer USED_BITS_BA   = TAG_WIDTH + INDEX_WIDTH_BA + 4;
    localparam integer DEPTH          = (1 << INDEX_WIDTH_BA);

    // Req Ready
    assign  cpu_req_ready      = (state == S_IDLE);                 // Data port(Main)

    // FSM ステート
    localparam [3:0]
        S_INIT         = 4'd0, // ★起動時初期化（全エントリ invalid）
        S_IDLE         = 4'd1,
        S_LOOKUP_ISSUE = 4'd2,
        S_LOOKUP_READ  = 4'd3,
        S_COMPARE      = 4'd4,
        S_WRITEBACK    = 4'd5,
        S_ALLOC_WAIT   = 4'd6,
        S_ALLOC_RESP   = 4'd7,
        S_POST_WBALLOC = 4'd8;

    // ---------------- 内部レジスタ ----------------
    reg [3:0]                 state;

    // 初期化スイープ
    reg  [INDEX_WIDTH_BA-1:0] init_idx;

    // 要求ラッチ
    reg                       req_is_write;
    reg  [ADDR_WIDTH-1:0]     req_addr_w;        // word address
    reg  [CPU_DATA_WIDTH-1:0] req_wdata;
    reg  [1:0]                req_word_sel_r;    // ライン内 word 選択（[1:0]）

    reg                       cpu_cache_clear_d1;
    reg                       cpu_cache_clear_slot;

    // アドレス
    wire [ADDR_WIDTH-1:0]     cpu_byte_addr = {cpu_addr[31:2], 2'b00};   // byte address [1:0]==2'b00
    wire [ADDR_WIDTH-1:0]     cpu_word_addr =  cpu_addr[31:2];   

    // ルックアップ（次拍でBRAM出力）
    reg  [INDEX_WIDTH_BA-1:0] cur_index_r;      // RAM アドレス
    reg  [TAG_WIDTH-1:0]      cur_tag_r;        // 比較用タグ

    // Tag RAM I/F（パック形式）
    reg                           tag_we;
    reg  [TAG_ENTRY_WIDTH-1:0]    tag_write;
    wire [TAG_ENTRY_WIDTH-1:0]    tag_read;

    // アンパック
    wire [TAG_WIDTH-1:0]          tag_read_tag   = tag_read[TAG_ENTRY_WIDTH-1:2];
    wire                          tag_read_valid = tag_read[1];
    wire                          tag_read_dirty = tag_read[0];

    // Data RAM I/F
    reg                           data_we;
    reg  [CACHE_DATA_WIDTH-1:0]   data_write;
    wire [CACHE_DATA_WIDTH-1:0]   data_read;

    // victim/line バッファ
    reg  [TAG_WIDTH-1:0]          victim_tag_r;
    reg                           victim_valid_r;
    reg                           victim_dirty_r;
    reg  [CACHE_DATA_WIDTH-1:0]   line_read_r;
    reg  [CACHE_DATA_WIDTH-1:0]   fill_line_r;

    // ---------------- mmu_valid, sa_valid, cpu_valid の場合のlatch ----------------
    reg                           cpu_req_slot_valid;
    reg [ADDR_WIDTH-1:0]          cpu_word_addr_slot;
    reg [ADDR_WIDTH-1:0]          cpu_byte_addr_slot;
    reg                           cpu_rw_slot;
    reg [CPU_DATA_WIDTH-1:0]      cpu_data_slot;

    // ---------------- ヘルパ関数 ----------------
    function [31:0] pick_word(input [127:0] line, input [1:0] sel);
        begin
            case (sel)
                2'b00: pick_word = line[ 31:  0];
                2'b01: pick_word = line[ 63: 32];
                2'b10: pick_word = line[ 95: 64];
                default: pick_word = line[127: 96];
            endcase
        end
    endfunction

    function [127:0] place_word(
        input [127:0] line, input [1:0] sel, input [31:0] w
    );
        reg [127:0] t;
        begin
            t = line;
            case (sel)
                2'b00: t[ 31:  0] = w;
                2'b01: t[ 63: 32] = w;
                2'b10: t[ 95: 64] = w;
                2'b11: t[127: 96] = w;
            endcase
            place_word = t;
        end
    endfunction

    // 16B 先頭 byte アドレス（単純に 16B 境界に切り下げ）
    function [ADDR_WIDTH-1:0] alloc_addr_ba_f(input [ADDR_WIDTH-1:0] addr);
        alloc_addr_ba_f = { addr[ADDR_WIDTH-1:4], 4'b0000 };
    endfunction
    function [ADDR_WIDTH-1:0] wb_addr_ba_f(
        input [TAG_WIDTH-1:0] tag_i, input [INDEX_WIDTH_BA-1:0] index_i
    );
        wb_addr_ba_f = { {(ADDR_WIDTH-USED_BITS_BA){1'b0}}, tag_i, index_i, 4'b0000 };
    endfunction
    wire [ADDR_WIDTH-1:0] victim_addr_ba = wb_addr_ba_f(victim_tag_r, cur_index_r);

    // ゼロライン（ライトミス導入用）
    wire [CACHE_DATA_WIDTH-1:0] ZERO_LINE = {CACHE_DATA_WIDTH{1'b0}};

    // ------------------------ FSM 本体 ------------------------
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            // 出力/制御初期化
            state         <= S_INIT;        // ★まず初期化へ
            init_idx      <= {INDEX_WIDTH_BA{1'b0}};

            // Valid latch 
            cpu_req_slot_valid  <= 1'b0;    // CPU
            cpu_word_addr_slot  <= 32'h0;
            cpu_byte_addr_slot  <= 32'h0;
            cpu_rw_slot         <= 1'b0;
            cpu_data_slot       <= 32'h0;

            mem_valid     <= 1'b0;  mem_rw <= 1'b0;
            mem_addr      <= {ADDR_WIDTH{1'b0}};
            mem_data_out  <= {MAIN_MEM_DATA_WIDTH{1'b0}};

            cpu_ready     <= 1'b0;
            cpu_data_out  <= {CPU_DATA_WIDTH{1'b0}};

            cpu_cache_clear_d1    <= 1'b0;
            cpu_cache_clear_slot  <= 1'b0;

            tag_we        <= 1'b0;
            data_write    <= {CPU_DATA_WIDTH{1'b0}};
            data_we       <= 1'b0;

            req_is_write  <= 1'b0;
            req_addr_w    <= {ADDR_WIDTH{1'b0}};
            req_wdata     <= {CPU_DATA_WIDTH{1'b0}};
            req_word_sel_r<= 2'b00;

            cur_index_r   <= {INDEX_WIDTH_BA{1'b0}};
            cur_tag_r     <= {TAG_WIDTH{1'b0}};

            victim_tag_r  <= {TAG_WIDTH{1'b0}};
            victim_valid_r<= 1'b0;
            victim_dirty_r<= 1'b0;

            line_read_r   <= {CACHE_DATA_WIDTH{1'b0}};
            fill_line_r   <= {CACHE_DATA_WIDTH{1'b0}};

            cache_hit_pulse  <= 1'b0;
            cache_miss_pulse <= 1'b0;

        end else begin
            // 1clk パルスは毎サイクル LOW
            mem_valid <= 1'b0;
            cpu_ready <= 1'b0;
            tag_we    <= 1'b0;
            data_we   <= 1'b0;
            cache_hit_pulse  <= 1'b0;
            cache_miss_pulse <= 1'b0;

            // ---------------- Valid latch ----------------
            // CPU port
            if (cpu_valid) begin
                cpu_req_slot_valid  <= 1'b1;
                cpu_word_addr_slot <= cpu_word_addr;
                cpu_byte_addr_slot <= cpu_byte_addr;
                cpu_rw_slot        <= cpu_rw;
                cpu_data_slot      <= cpu_data;
            end

            cpu_cache_clear_d1 <= cpu_cache_clear;

            // cpu_cache_clear posedge
            if (cpu_cache_clear & !cpu_cache_clear_d1) begin
                cpu_cache_clear_slot <= 1'b1;
            end

            case (state)
                // ---------- 初期化：全インデックスを invalid=0 にする ----------
                S_INIT: begin
                    cur_index_r <= init_idx;
                    tag_write   <= {TAG_ENTRY_WIDTH{1'b0}}; // {tag=0, valid=0, dirty=0}
                    tag_we      <= 1'b1;

                    if (init_idx == DEPTH-1) begin
                        state    <= S_IDLE;
                    end
                    init_idx <= init_idx + 1'b1;
                end

                // ---------------- IDLE ----------------
                S_IDLE: begin
                    if (cpu_req_slot_valid) begin
                        // 要求ラッチ
                        cpu_req_slot_valid <= 1'b0;
                        req_is_write    <= cpu_rw_slot;
                        req_addr_w      <= cpu_byte_addr_slot;
                        req_wdata       <= cpu_data_slot;
                        req_word_sel_r  <= cpu_word_addr_slot[1:0];
                        // キャッシュ参照（次拍でBRAM出力）
                        cur_index_r <= cpu_byte_addr_slot[TAGLSB-1:4];
                        cur_tag_r   <= cpu_byte_addr_slot[TAGMSB:TAGLSB];
                        state       <= S_LOOKUP_ISSUE;
                    end 
                    else if (cpu_cache_clear_slot) begin
                        state       <= S_INIT;
                        cpu_cache_clear_slot <= 1'b0;
                    end 
                end

                // ---- index提示（1clk 後に tag/data が有効） ----
                S_LOOKUP_ISSUE: begin
                    state <= S_LOOKUP_READ;
                end

                // ---- tag/data 受け取り ----
                S_LOOKUP_READ: begin
                    victim_tag_r   <= tag_read_tag;
                    victim_valid_r <= tag_read_valid;
                    victim_dirty_r <= tag_read_dirty;
                    line_read_r    <= data_read;
                    state          <= S_COMPARE;
                end

                // ---------------- COMPARE ----------------
                S_COMPARE: begin
                    if (victim_valid_r && (victim_tag_r == cur_tag_r)) begin
                        // ---- HIT ----
                        if (req_is_write) begin
                            // 行更新 + dirty=1
                            data_write <= place_word(line_read_r, req_word_sel_r, req_wdata);
                            data_we    <= 1'b1;
                            tag_write  <= {victim_tag_r, 1'b1, 1'b1};  // {tag,valid=1,dirty=1}
                            tag_we     <= 1'b1;
                            cpu_ready  <= 1'b1;
                        end else begin
                            // 読み出しヒット
                            cpu_data_out <= pick_word(line_read_r, req_word_sel_r);
                            cpu_ready    <= 1'b1;
                        end
                        cache_hit_pulse <= 1'b1;
                        state <= S_IDLE;

                    end else begin
                        // ---- MISS ----
                        if (victim_valid_r && victim_dirty_r) begin
                            // 先にWRITEBACK（mem_req_ready待ち）
                            if (mem_req_ready) begin
                                mem_valid    <= 1'b1;
                                mem_rw       <= 1'b1;               // WRITEBACK
                                mem_addr     <= victim_addr_ba;
                                mem_data_out <= line_read_r;        // victim 全体
                                cache_miss_pulse <= 1'b1;
                                state        <= S_WRITEBACK;
                            end
                        end else if (!req_is_write) begin
                            // READミス：READ ALLOCATE
                            if (mem_req_ready) begin
                                mem_valid <= 1'b1;
                                mem_rw    <= 1'b0;
                                mem_addr  <= alloc_addr_ba_f(req_addr_w);
                                cache_miss_pulse <= 1'b1;
                                state     <= S_ALLOC_WAIT;
                            end
                        end else begin
                            // WRITEミス：ゼロライン導入（外部アクセスなし）
                            data_write <= place_word(ZERO_LINE, req_word_sel_r, req_wdata);
                            data_we    <= 1'b1;
                            tag_write  <= {cur_tag_r, 1'b1, 1'b1};  // valid=1, dirty=1
                            tag_we     <= 1'b1;
                            cpu_ready  <= 1'b1;
                            cache_miss_pulse <= 1'b1;
                            state      <= S_IDLE;
                        end
                    end
                end

                // ---------------- WRITEBACK ----------------
                S_WRITEBACK: begin
                    if (mem_ready) begin
                        if (!req_is_write) begin
                            state <= S_POST_WBALLOC; // READミス継続
                        end else begin
                            // WRITEミス：WB後にゼロライン導入で終了
                            data_write <= place_word(ZERO_LINE, req_word_sel_r, req_wdata);
                            data_we    <= 1'b1;
                            tag_write  <= {cur_tag_r, 1'b1, 1'b1};
                            tag_we     <= 1'b1;
                            cpu_ready  <= 1'b1;
                            state      <= S_IDLE;
                        end
                    end
                end

                // ------ WB後、mem_req_ready待ってALLOC発行 ------
                S_POST_WBALLOC: begin
                    if (mem_req_ready) begin
                        mem_valid <= 1'b1;
                        mem_rw    <= 1'b0;
                        mem_addr  <= alloc_addr_ba_f(req_addr_w);
                        state     <= S_ALLOC_WAIT;
                    end
                end

                // -------------- 外部READ完了待ち（ALLOC） --------------
                S_ALLOC_WAIT: begin
                    if (mem_ready) begin
                        // 受信ラインをインストール（次拍で返却）
                        fill_line_r <= mem_data_in;
                        data_write  <= mem_data_in;
                        data_we     <= 1'b1;
                        tag_write   <= {cur_tag_r, 1'b1, 1'b0}; // valid=1, dirty=0
                        tag_we      <= 1'b1;
                        state       <= S_ALLOC_RESP;
                    end
                end

                // -------- READミス返却（フィル直後の1clk後） --------
                S_ALLOC_RESP: begin
                    cpu_data_out <= pick_word(fill_line_r, req_word_sel_r);
                    cpu_ready    <= 1'b1;
                    state        <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

    // -------------------- RAM インスタンス --------------------
    // TAG（パック：{tag, valid, dirty}）
    dm_cache_tag #(
        .TAG_WIDTH  (TAG_ENTRY_WIDTH),      // ★パック幅を指定
        .INDEX_WIDTH(INDEX_WIDTH_BA)
    ) u_tag (
        .clk       (clock),
        .we        (tag_we),
        .index     (cur_index_r),
        .tag_write (tag_write),
        .tag_read  (tag_read)
    );

    // DATA（write-first 同期読み）
    dm_cache_data #(
        .DATA_WIDTH (CACHE_DATA_WIDTH),
        .INDEX_WIDTH(INDEX_WIDTH_BA)
    ) u_data (
        .clk        (clock),
        .we         (data_we),
        .index      (cur_index_r),
        .data_write (data_write),
        .data_read  (data_read)
    );

endmodule
