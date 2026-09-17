// ===================================================================
// cache_dma_controller_io  (for packed dm_cache_tag / write-first RAMs)
//   - 32B line, Direct-Mapped, Write-back / Write-allocate
//   - Sync-read 1clk (tag/data) に整合（ISSUE → COMPARE）
//   - mem_req_ready で外部要求をゲート
//   - 単一 PIO アドレスはキャッシュ迂回で即応答
//   - FPGA向け：BRAMはリセットせず、起動時に S_INIT で全ライン invalid 化
//   - byte書き込み対応
// ===================================================================
`timescale 1ns/1ps
module cache_dma_controller_io #(
    parameter PROTECT_MODE        = 1,
    parameter PROTECT_ADDR        = 32'h0001_0000,
    parameter ADDR_WIDTH          = 32,
    parameter CPU_DATA_WIDTH      = 32,
    parameter CACHE_DATA_WIDTH    = 256,
    parameter MAIN_MEM_DATA_WIDTH = 256,

    // アドレス切り出し
    parameter TAGMSB            = 31,
    parameter TAGLSB            = 14,   // 32B line → index=[13:5]
    parameter TAG_WIDTH         = TAGMSB - TAGLSB + 1,         // 例:18
    parameter TAG_ENTRY_WIDTH   = TAG_WIDTH + 2,               // {tag,valid,dirty}

    // MMIO MASK BITS
    parameter [ADDR_WIDTH-1:0]  MMMIO_BASK_BITS     = 32'h1000_F00F,
    // MMIO アドレス（0なら無効）
    parameter [ADDR_WIDTH-1:0]  PIO_ADDRESS         = {ADDR_WIDTH{1'b0}},
    parameter [ADDR_WIDTH-1:0]  UART_ADDRESS_TX     = {ADDR_WIDTH{1'b0}},
    parameter [ADDR_WIDTH-1:0]  UART_ADDRESS_RX     = {ADDR_WIDTH{1'b0}},
    parameter [ADDR_WIDTH-1:0]  UART_ADDRESS_ST     = {ADDR_WIDTH{1'b0}},
    parameter [ADDR_WIDTH-1:0]  UART_ADDRESS_CT     = {ADDR_WIDTH{1'b0}},
    parameter [ADDR_WIDTH-1:0]  TIMER_WRITE_ADDR    = {ADDR_WIDTH{1'b0}},
    parameter [ADDR_WIDTH-1:0]  TIMER_READ_ADDR     = {ADDR_WIDTH{1'b0}},
    parameter [ADDR_WIDTH-1:0]  TIMER_ST_ADDR       = {ADDR_WIDTH{1'b0}},
    parameter [ADDR_WIDTH-1:0]  LCD_PIXS_DATA       = {ADDR_WIDTH{1'b0}},
    parameter [ADDR_WIDTH-1:0]  LCD_PIXS_ST         = {ADDR_WIDTH{1'b0}},
    parameter [ADDR_WIDTH-1:0]  LED_ADDRESS         = {ADDR_WIDTH{1'b0}},
    parameter [ADDR_WIDTH-1:0]  PSC_SA_CTRL         = {ADDR_WIDTH{1'b0}},   // not used
    parameter [ADDR_WIDTH-1:0]  PSC_SA_STATUS       = {ADDR_WIDTH{1'b0}},   // not used
    parameter [ADDR_WIDTH-1:0]  PSC_SD_IF_READ_DATA = {ADDR_WIDTH{1'b0}},
    parameter [ADDR_WIDTH-1:0]  PSC_SD_IF_SECTOR    = {ADDR_WIDTH{1'b0}},
    parameter [ADDR_WIDTH-1:0]  PSC_SD_IF_CTRL      = {ADDR_WIDTH{1'b0}},
    parameter [ADDR_WIDTH-1:0]  PSC_I2S_ADDR_RX     = {ADDR_WIDTH{1'b0}},
    parameter [ADDR_WIDTH-1:0]  PSC_I2S_ADDR_ST     = {ADDR_WIDTH{1'b0}},
    parameter [ADDR_WIDTH-1:0]  PSC_PFE_IF_DATA     = {ADDR_WIDTH{1'b0}},
    parameter [ADDR_WIDTH-1:0]  PSC_PFE_IF_CTRL     = {ADDR_WIDTH{1'b0}}
)(
    input  wire                             clock,
    input  wire                             reset_n,

    // --------- CPU リクエスト/レスポンス ---------
    input  wire                             cpu_rvalid,
    input  wire                             cpu_wvalid,
    input  wire                             cpu_rw,          // 1:W, 0:R
    input  wire [2:0]                       cpu_write_sel,
    input  wire [ADDR_WIDTH-1:0]            cpu_raddr,       // byte address
    input  wire [ADDR_WIDTH-1:0]            cpu_waddr,       // byte address
    input  wire [CPU_DATA_WIDTH-1:0]        cpu_data,
    output logic                            cpu_ready,
    output logic  [CPU_DATA_WIDTH-1:0]      cpu_data_out,
    output wire                             cpu_req_ready,

    // --------- Cache 制御信号 ---------
    input  wire                             cpu_cache_clear, 
    input  wire                             cpu_cache_wb, 

    // --------- SynapEngine リクエスト/レスポンス ---------
    input  wire                             sa_valid,
    input  wire                             sa_rw,          // 1:W, 0:R
    //input  wire [2:0]                     sa_write_sel,
    input  wire [ADDR_WIDTH-1:0]            sa_addr,        // byte address
    input  wire [CPU_DATA_WIDTH-1:0]        sa_data,
    output logic                            sa_ready,
    output logic  [CPU_DATA_WIDTH-1:0]      sa_data_out,
    output wire                             sa_req_ready,

    // --------- MMU リクエスト/レスポンス ---------
    input  wire                             mmu_valid,
    input  wire [ADDR_WIDTH-1:0]            mmu_addr,        // byte address
    output logic                            mmu_ready,
    output logic  [CPU_DATA_WIDTH-1:0]      mmu_data_out,
    output wire                             mmu_req_ready,

    // --------- MMIO I/F（8bit） ---------
    output logic                            mmio_valid,
    output logic                            mmio_rw,          // 1:W, 0:R
    output logic [ADDR_WIDTH-1:0]           mmio_addr,        // byte address
    output logic [CPU_DATA_WIDTH-1:0]       mmio_wdata,
    input wire                              mmio_ready,
    input wire  [CPU_DATA_WIDTH-1:0]        mmio_rdata,

    // --------- 外部メモリ（ライン転送） ---------
    input  wire                             mem_ready,       // 1ライン応答
    input  wire [MAIN_MEM_DATA_WIDTH-1:0]   mem_data_in,
    input  wire                             mem_req_ready,   // 要求受付可

    // --------- メモリアクセス要求 ---------
    output logic                            mem_valid,       // 1clk パルス
    output logic                            mem_rw,          // 1:WB, 0:READ
    output logic  [ADDR_WIDTH-1:0]          mem_addr,        // byte addr (32B aligned推奨)
    output logic  [MAIN_MEM_DATA_WIDTH-1:0] mem_data_out,

    // --------- メモリアクセス要求 ---------
    output logic                            cache_hit_pulse,
    output logic                            cache_miss_pulse
);
    // ---------------- 定数/ローカル ----------------
    localparam integer LINE_BYTES = CACHE_DATA_WIDTH / 8;
    localparam integer LINE_WORDS = CACHE_DATA_WIDTH / CPU_DATA_WIDTH;
    localparam integer OFFSET_BITS = $clog2(LINE_BYTES);
    localparam integer WORD_BITS = $clog2(LINE_WORDS);

    localparam integer INDEX_WIDTH_BA = TAGLSB - OFFSET_BITS;   // 例:9（index=[13:5]）
    localparam integer USED_BITS_BA   = TAG_WIDTH + INDEX_WIDTH_BA + OFFSET_BITS;
    localparam integer DEPTH          = (1 << INDEX_WIDTH_BA);

    // Req Ready
    assign  mmu_req_ready      = (state == S_IDLE);                 // I-MMU port.
    assign  sa_req_ready       = (state == S_IDLE);                 // SA port.
    assign  cpu_req_ready      = (state == S_IDLE);                 // Data port(Main)

    // FSM ステート
    localparam [4:0]
        S_INIT                  = 5'd0, // ★起動時初期化（全エントリ invalid）
        S_IDLE                  = 5'd1,
        S_CASHE_START           = 5'd2,
        S_LOOKUP_ISSUE          = 5'd4,
        S_COMPARE               = 5'd6,
        S_WRITEBACK             = 5'd7,
        S_ALLOC_WAIT            = 5'd8,
        S_POST_WBALLOC          = 5'd10,
        S_MMIO_WAIT             = 5'd11,
        S_CACHE_WB_START        = 5'd12,
        S_CACHE_WB_START_WAIT   = 5'd13,
        S_CACHE_WB_CHECK        = 5'd15,
        S_CACHE_WB_WRITE_REQ    = 5'd16,
        S_CACHE_WB_WRITE_WAIT   = 5'd17,
        S_CACHE_WB_NEXT         = 5'd18;

    // ---------------- wire ----------------
    // 書き込む位置
    // アドレス下位bits
    //wire [1:0] byte_sel = req_addr_b[1:0]; // 0..3 (SB用途)  ★修正
    //wire       half_sel = req_addr_b[1];   // 0 or 1 (SH用途) ★修正
    logic [1:0]   byte_sel;
    logic         half_sel;

    // 書き込み後の新ライン
    logic [CACHE_DATA_WIDTH-1:0] new_line;

    // ---------------- 内部レジスタ ----------------
    logic [4:0]                 state;

    // 初期化スイープ
    logic  [INDEX_WIDTH_BA-1:0] init_idx;

    // 要求ラッチ
    logic                       req_from_mmu;
    logic                       req_from_sa;
    logic                       req_is_write;
    logic  [ADDR_WIDTH-1:0]     req_addr_w;        // word address
    logic  [ADDR_WIDTH-1:0]     req_addr_b;        // byte address
    logic  [CPU_DATA_WIDTH-1:0] req_wdata;
    logic  [WORD_BITS-1:0]                req_word_sel_r;    // ライン内 word 選択（0..7）
    logic  [2:0]                req_write_sel_r;

    // キャッシュ初期化
    logic                       cpu_cache_clear_d1;
    logic                       cpu_cache_clear_latch;

    // キャッシュWB
    logic                       cpu_cache_wb_d1;
    logic                       cpu_cache_wb_latch;

    // アドレス
    wire [ADDR_WIDTH-1:0]     cpu_byte_raddr =  cpu_raddr[31:0];  
    wire [ADDR_WIDTH-1:0]     cpu_word_raddr =  cpu_raddr[31:2];   // cpu_add[1:0]を削除
    wire [ADDR_WIDTH-1:0]     cpu_byte_waddr =  cpu_waddr[31:0];  
    wire [ADDR_WIDTH-1:0]     cpu_word_waddr =  cpu_waddr[31:2];   // cpu_add[1:0]を削除

    wire [ADDR_WIDTH-1:0]     sa_byte_addr  =  sa_addr[31:0];  
    wire [ADDR_WIDTH-1:0]     sa_word_addr  =  sa_addr[31:2];   // cpu_add[1:0]を削除

    // ルックアップ（次拍でBRAM出力）
    logic  [INDEX_WIDTH_BA-1:0] cur_index_r;      // RAM アドレス
    logic  [TAG_WIDTH-1:0]      cur_tag_r;        // 比較用タグ

    // Tag RAM I/F（パック形式）
    logic                           tag_we;
    logic  [TAG_ENTRY_WIDTH-1:0]    tag_write;
    wire [TAG_ENTRY_WIDTH-1:0]      tag_read;

    // アンパック
    wire [TAG_WIDTH-1:0]          tag_read_tag   = tag_read[TAG_ENTRY_WIDTH-1:2];
    wire                          tag_read_valid = tag_read[1];
    wire                          tag_read_dirty = tag_read[0];

    // Data RAM I/F
    logic                           data_we;
    logic  [CACHE_DATA_WIDTH-1:0]   data_write;
    wire [CACHE_DATA_WIDTH-1:0]     data_read;

    // RAM outputs remain stable while cur_index_r is held for a transaction.

    // ---------------- mmu_valid, sa_valid, cpu_valid の場合のlatch ----------------
    logic                           cpu_req_slot_valid;
    logic                           sa_req_slot_valid;
    logic                           mmu_req_slot_valid;
    logic [ADDR_WIDTH-1:0]          mmu_addr_slot;
    logic [ADDR_WIDTH-1:0]          cpu_word_addr_slot;
    logic [ADDR_WIDTH-1:0]          cpu_byte_addr_slot;
    logic                           cpu_rw_latch;
    logic [CPU_DATA_WIDTH-1:0]      cpu_data_latch;
    logic [2:0]                     cpu_write_sel_latch;

    logic [ADDR_WIDTH-1:0]          sa_word_addr_slot;
    logic [ADDR_WIDTH-1:0]          sa_byte_addr_slot;
    logic                           sa_rw_latch;
    logic [CPU_DATA_WIDTH-1:0]      sa_data_latch;
    logic [2:0]                     sa_write_sel_latch;

    // WB関連
    logic [INDEX_WIDTH_BA-1:0]      cache_wb_index;

    // ---------------- ヘルパ関数 ----------------
    function [31:0] pick_word(input [CACHE_DATA_WIDTH-1:0] line, input [WORD_BITS-1:0] sel);
        begin
            pick_word = line[sel*CPU_DATA_WIDTH +: CPU_DATA_WIDTH];
        end
    endfunction

    // One shared store datapath for hits and write allocation. Decode the
    // byte enables once; each byte lane only selects old data or store data.
    wire [CACHE_DATA_WIDTH-1:0] store_base = (state == S_ALLOC_WAIT) ? mem_data_in : data_read;
    logic [31:0] store_data;
    logic [3:0] store_byte_en;
    integer lane;
    always_comb begin
        case (req_write_sel_r)
            3'b000: begin
                store_data = {4{req_wdata[7:0]}};
                store_byte_en = 4'b0001 << byte_sel;
            end
            3'b001: begin
                store_data = {2{req_wdata[15:0]}};
                store_byte_en = half_sel ? 4'b1100 : 4'b0011;
            end
            default: begin
                store_data = req_wdata;
                store_byte_en = 4'b1111;
            end
        endcase
        for (lane = 0; lane < LINE_BYTES; lane = lane + 1) begin
            new_line[lane*8 +: 8] =
                ((req_word_sel_r == (lane / 4)) && store_byte_en[lane % 4])
                ? store_data[(lane % 4)*8 +: 8] : store_base[lane*8 +: 8];
        end
    end

    // 32B 先頭 byte アドレス（単純に 32B 境界に切り下げ）
    function [ADDR_WIDTH-1:0] alloc_addr_ba_f(input [ADDR_WIDTH-1:0] addr);
        alloc_addr_ba_f = { addr[ADDR_WIDTH-1:OFFSET_BITS], {OFFSET_BITS{1'b0}} };
    endfunction
    function [ADDR_WIDTH-1:0] wb_addr_ba_f(
        input [TAG_WIDTH-1:0] tag_i, input [INDEX_WIDTH_BA-1:0] index_i
    );
        wb_addr_ba_f = { {(ADDR_WIDTH-USED_BITS_BA){1'b0}}, tag_i, index_i, {OFFSET_BITS{1'b0}} };
    endfunction
    wire [ADDR_WIDTH-1:0] victim_addr_ba = wb_addr_ba_f(tag_read_tag, cur_index_r);

    // MMIO（一致かつ0以外で有効）
    function mmio_hit(input [ADDR_WIDTH-1:0] addr_mmio);
        reg [31:0]  addr_mmio_masked;
        begin
            addr_mmio_masked = addr_mmio & MMMIO_BASK_BITS;
            mmio_hit =
                (((PIO_ADDRESS          != {ADDR_WIDTH{1'b0}}) && (addr_mmio_masked == PIO_ADDRESS          )) |
                 ((UART_ADDRESS_TX      != {ADDR_WIDTH{1'b0}}) && (addr_mmio_masked == UART_ADDRESS_TX      )) |
                 ((UART_ADDRESS_RX      != {ADDR_WIDTH{1'b0}}) && (addr_mmio_masked == UART_ADDRESS_RX      )) |
                 ((UART_ADDRESS_ST      != {ADDR_WIDTH{1'b0}}) && (addr_mmio_masked == UART_ADDRESS_ST      )) |
                 ((UART_ADDRESS_CT      != {ADDR_WIDTH{1'b0}}) && (addr_mmio_masked == UART_ADDRESS_CT      )) |
                 ((TIMER_WRITE_ADDR     != {ADDR_WIDTH{1'b0}}) && (addr_mmio_masked == TIMER_WRITE_ADDR     )) |
                 ((TIMER_READ_ADDR      != {ADDR_WIDTH{1'b0}}) && (addr_mmio_masked == TIMER_READ_ADDR      )) |
                 ((TIMER_ST_ADDR        != {ADDR_WIDTH{1'b0}}) && (addr_mmio_masked == TIMER_ST_ADDR        )) |
                 ((LCD_PIXS_DATA        != {ADDR_WIDTH{1'b0}}) && (addr_mmio_masked == LCD_PIXS_DATA        )) |
                 ((LCD_PIXS_ST          != {ADDR_WIDTH{1'b0}}) && (addr_mmio_masked == LCD_PIXS_ST          )) |
                 ((LED_ADDRESS          != {ADDR_WIDTH{1'b0}}) && (addr_mmio_masked == LED_ADDRESS          )) |
                 ((PSC_SA_CTRL          != {ADDR_WIDTH{1'b0}}) && (addr_mmio_masked == PSC_SA_CTRL          )) |
                 ((PSC_SA_STATUS        != {ADDR_WIDTH{1'b0}}) && (addr_mmio_masked == PSC_SA_STATUS        )) |
                 ((PSC_SD_IF_READ_DATA  != {ADDR_WIDTH{1'b0}}) && (addr_mmio_masked == PSC_SD_IF_READ_DATA  )) |
                 ((PSC_SD_IF_SECTOR     != {ADDR_WIDTH{1'b0}}) && (addr_mmio_masked == PSC_SD_IF_SECTOR     )) |
                 ((PSC_SD_IF_CTRL       != {ADDR_WIDTH{1'b0}}) && (addr_mmio_masked == PSC_SD_IF_CTRL       )) |
                 ((PSC_I2S_ADDR_RX      != {ADDR_WIDTH{1'b0}}) && (addr_mmio_masked == PSC_I2S_ADDR_RX      )) |
                 ((PSC_I2S_ADDR_ST      != {ADDR_WIDTH{1'b0}}) && (addr_mmio_masked == PSC_I2S_ADDR_ST      )) |
                 ((PSC_PFE_IF_DATA      != {ADDR_WIDTH{1'b0}}) && (addr_mmio_masked == PSC_PFE_IF_DATA      )) |
                 ((PSC_PFE_IF_CTRL      != {ADDR_WIDTH{1'b0}}) && (addr_mmio_masked == PSC_PFE_IF_CTRL      )));
        end
    endfunction

    // Response enables are disjoint by state. Keep the tag comparison out
    // of the nested write/miss/arbitration mux tree feeding output FF enables.
    wire read_hit                               = (state == S_COMPARE) && !req_is_write &&
                                                lookup_valid && (lookup_tag == cur_tag_r);
    wire read_fill                              = (state == S_ALLOC_WAIT) && mem_ready && !req_is_write;
    wire read_response                          = read_hit || read_fill;
    wire cpu_read_response                      = read_response && !req_from_mmu && !req_from_sa;
    wire mmio_response                          = (state == S_MMIO_WAIT) && mmio_ready;
    wire protected_response                     = (state == S_CASHE_START) &&
                                                !mmu_req_slot_valid && !sa_req_slot_valid && cpu_req_slot_valid &&
                                                PROTECT_MODE && cpu_rw_latch && (cpu_byte_addr_slot < PROTECT_ADDR);
    wire [CPU_DATA_WIDTH-1:0] response_word     = (state == S_ALLOC_WAIT)
                                                ? pick_word(mem_data_in, req_word_sel_r)
                                                : pick_word(data_read, req_word_sel_r);
    wire [CPU_DATA_WIDTH-1:0] cpu_response_data =
                                                ({CPU_DATA_WIDTH{(state == S_COMPARE) || (state == S_ALLOC_WAIT)}} & response_word) |
                                                ({CPU_DATA_WIDTH{state == S_MMIO_WAIT}} & mmio_rdata);

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            cpu_data_out <= {CPU_DATA_WIDTH{1'b0}};
            sa_data_out  <= {CPU_DATA_WIDTH{1'b0}};
            mmu_data_out <= {CPU_DATA_WIDTH{1'b0}};
        end else begin
            if (cpu_read_response || mmio_response || protected_response)
                cpu_data_out <= cpu_response_data;
            if (read_response && !req_from_mmu && req_from_sa)
                sa_data_out  <= response_word;
            if (read_response && req_from_mmu)
                mmu_data_out <= response_word;
        end
    end

    // Memory request registers have a common, flat enable. In particular,
    // the eviction line does not need the priority mux for every FSM branch.
    wire cache_match                          = lookup_valid && (lookup_tag == cur_tag_r);
    wire dirty_victim                         = lookup_valid && lookup_dirty;
    wire miss_request                         = (state == S_COMPARE) && !cache_match &&
        !(req_is_write && PROTECT_MODE && (req_addr_b < PROTECT_ADDR)) && mem_req_ready;
    wire eviction_request                     = miss_request && dirty_victim;
    wire post_alloc_request                   = (state == S_POST_WBALLOC) && mem_req_ready;
    wire sweep_request                        = (state == S_CACHE_WB_WRITE_REQ) && mem_req_ready;
    wire writeback_request                    = eviction_request || sweep_request;
    wire memory_request                       = miss_request || post_alloc_request || sweep_request;
    wire [ADDR_WIDTH-1:0] memory_request_addr = writeback_request
        ? wb_addr_ba_f(tag_read_tag, cur_index_r) : alloc_addr_ba_f(req_addr_b);

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            mem_valid    <= 1'b0;
            mem_rw       <= 1'b0;
            mem_addr     <= {ADDR_WIDTH{1'b0}};
            mem_data_out <= {MAIN_MEM_DATA_WIDTH{1'b0}};
        end else begin
            mem_valid <= memory_request;
            if (memory_request) begin
                mem_rw   <= writeback_request;
                mem_addr <= memory_request_addr;
            end
            if (writeback_request)
                mem_data_out <= data_read;
        end
    end

    // data_write is consumed by the RAM only when data_we is asserted.
    // Capture its next value every cycle instead of routing hit/miss/FSM
    // conditions to line-wide FF enables. The merge datapath itself is unchanged.
    wire cache_write_hit = (state == S_COMPARE) && req_is_write && cache_match;
    wire cache_fill      = (state == S_ALLOC_WAIT) && mem_ready;
    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            data_write <= {CACHE_DATA_WIDTH{1'b0}};
            data_we    <= 1'b0;
        end else begin
            data_write <= req_is_write ? new_line : mem_data_in;
            data_we    <= cache_write_hit || cache_fill;
        end
    end

    // Present the arbitrated index to tag RAM in the request-selection
    // cycle. Its synchronous result can then be captured in LOOKUP_ISSUE,
    // without adding a cycle to the hit path. Data RAM keeps its old address
    // schedule; only the small tag result needs an extra timing boundary.
    wire [INDEX_WIDTH_BA-1:0] selected_tag_index = mmu_req_slot_valid
        ? mmu_addr_slot[TAGLSB-1:OFFSET_BITS] : sa_req_slot_valid
        ? sa_byte_addr_slot[TAGLSB-1:OFFSET_BITS] : cpu_byte_addr_slot[TAGLSB-1:OFFSET_BITS];
    wire [INDEX_WIDTH_BA-1:0] tag_index          = (state == S_CASHE_START)
        ? selected_tag_index : cur_index_r;
    logic [TAG_ENTRY_WIDTH-1:0] lookup_tag_r;
    wire [TAG_WIDTH-1:0] lookup_tag              = lookup_tag_r[TAG_ENTRY_WIDTH-1:2];
    wire                 lookup_valid            = lookup_tag_r[1];
    wire                 lookup_dirty            = lookup_tag_r[0];
    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            lookup_tag_r <= {TAG_ENTRY_WIDTH{1'b0}};
        else if (state == S_LOOKUP_ISSUE)
            lookup_tag_r <= tag_read;
    end

    // ------------------------ FSM 本体 ------------------------
    always_ff @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            // 出力/制御初期化
            state         <= S_INIT;        // ★まず初期化へ
            init_idx      <= {INDEX_WIDTH_BA{1'b0}};

            // Valid latch 
            cpu_req_slot_valid  <= 1'b0;    // CPU
            cpu_word_addr_slot  <= 32'h0;
            cpu_byte_addr_slot  <= 32'h0;
            byte_sel            <= 2'b00;
            half_sel            <= 1'b0;
            cpu_rw_latch        <= 1'b0;
            cpu_data_latch      <= 32'h0;
            cpu_write_sel_latch <= 3'b000;
            sa_req_slot_valid   <= 1'b0;    // SA
            sa_word_addr_slot   <= 32'h0;
            sa_byte_addr_slot   <= 32'h0;
            sa_data_latch       <= 32'h0;
            sa_rw_latch         <= 1'b0;
            sa_write_sel_latch  <= 3'b000;
            mmu_req_slot_valid  <= 1'b0;    // MMU
            mmu_addr_slot       <= 32'h0;

            // MMIO
            mmio_valid    <= 1'b0;
            mmio_rw       <= 1'b0;
            mmio_addr     <= 32'd0;
            mmio_wdata    <= 32'd0;

            cpu_ready     <= 1'b0;

            // clear, wb
            cpu_cache_clear_d1    <= 1'b0;
            cpu_cache_clear_latch <= 1'b0;

            cpu_cache_wb_d1       <= 1'b0;
            cpu_cache_wb_latch    <= 1'b0;
            cache_wb_index        <= {INDEX_WIDTH_BA{1'b0}};

            sa_ready      <= 1'b0;

            tag_we        <= 1'b0;

            req_from_mmu  <= 1'b0;
            req_from_sa   <= 1'b0;
            req_is_write  <= 1'b0;
            req_addr_w    <= {ADDR_WIDTH{1'b0}};
            req_addr_b    <= {ADDR_WIDTH{1'b0}};
            req_wdata     <= {CPU_DATA_WIDTH{1'b0}};
            req_write_sel_r <= 3'b000;
            req_word_sel_r<= '0;

            cur_index_r   <= {INDEX_WIDTH_BA{1'b0}};
            cur_tag_r     <= {TAG_WIDTH{1'b0}};

            mmu_ready     <= 1'b0;

            cache_hit_pulse  <= 1'b0;
            cache_miss_pulse <= 1'b0;

        end else begin
            // 1clk パルスは毎サイクル LOW
            cpu_ready <= 1'b0;
            tag_we    <= 1'b0;
            sa_ready  <= 1'b0;
            mmu_ready <= 1'b0;
            mmio_valid  <= 1'b0;
            mmio_rw     <= 1'b0;

            cpu_cache_clear_d1 <= cpu_cache_clear;
            cpu_cache_wb_d1    <= cpu_cache_wb;

            cache_hit_pulse  <= 1'b0;
            cache_miss_pulse <= 1'b0;

            // cpu_cache_clear posedge
            if (cpu_cache_clear & !cpu_cache_clear_d1) begin
                cpu_cache_clear_latch   <= 1'b1;
            end
            // cpu_cache_wb posedge
            if (cpu_cache_wb & !cpu_cache_wb_d1) begin
                cpu_cache_wb_latch      <= 1'b1;
            end

            // ---------------- Valid latch ----------------
            // CPU port
            if (cpu_rvalid) begin
                cpu_req_slot_valid  <= 1'b1;
                cpu_word_addr_slot  <= cpu_word_raddr;
                cpu_byte_addr_slot  <= cpu_byte_raddr;
                cpu_rw_latch        <= cpu_rw;
                cpu_data_latch      <= cpu_data;
                cpu_write_sel_latch <= cpu_write_sel;
            end
            if (cpu_wvalid) begin
                cpu_req_slot_valid  <= 1'b1;
                cpu_word_addr_slot  <= cpu_word_waddr;
                cpu_byte_addr_slot  <= cpu_byte_waddr;
                cpu_rw_latch        <= cpu_rw;
                cpu_data_latch      <= cpu_data;
                cpu_write_sel_latch <= cpu_write_sel;
            end
            // SA port
            if (sa_valid) begin
                sa_req_slot_valid   <= 1'b1;
                sa_word_addr_slot   <= sa_word_addr;
                sa_byte_addr_slot   <= sa_byte_addr;
                sa_rw_latch         <= sa_rw;
                sa_data_latch       <= sa_data;
                sa_write_sel_latch  <= 3'b010;
            end
            // MMU port
            if (mmu_valid) begin
                mmu_req_slot_valid  <= 1'b1;
                mmu_addr_slot       <= mmu_addr;
            end
            // ---------------------------------------------

            case (state)
                // ---------- 初期化：全インデックスを invalid=0 にする ----------
                // state = 0
                S_INIT: begin
                    cur_index_r <= init_idx;
                    tag_write   <= {TAG_ENTRY_WIDTH{1'b0}}; // {tag=0, valid=0, dirty=0}
                    tag_we      <= 1'b1;

                    if (init_idx == DEPTH-1) begin
                        init_idx <= {INDEX_WIDTH_BA{1'b0}};
                        state    <= S_IDLE;
                    end
                    init_idx <= init_idx + 1'b1;
                end

                // ---------------- IDLE ----------------
                // state = 1
                S_IDLE: begin
                    if (cpu_req_slot_valid | sa_req_slot_valid | mmu_req_slot_valid) begin
                        state <= S_CASHE_START;
                    end else begin
                        if (cpu_cache_clear_latch) begin
                            state       <= S_INIT;
                            cpu_cache_clear_latch <= 1'b0;
                        end
                        else if (cpu_cache_wb_latch) begin
                            state       <= S_CACHE_WB_START;
                            cpu_cache_wb_latch <= 1'b0;
                        end
                    end
                end

                // ---------------- S_CASHE_START (旧: S_IDLE) ----------------
                // state = 2
                S_CASHE_START: begin
                    // cpu_validよりmmu_valid優先.
                    if (mmu_req_slot_valid) begin
                        // ===== MMU READ ONLY =====
                        req_from_mmu    <= 1'b1;
                        req_from_sa     <= 1'b0;
                        req_is_write    <= 1'b0;
                        req_addr_b      <= mmu_addr_slot;
                        req_addr_w      <= mmu_addr_slot[31:2];
                        req_word_sel_r  <= mmu_addr_slot[OFFSET_BITS-1:2];
                        mmu_req_slot_valid <= 1'b0;    // _valid をクリア

                        // MMIO は MMU では使わない（即ミス扱い or 無視）
                        cur_index_r <= mmu_addr_slot[TAGLSB-1:OFFSET_BITS];
                        cur_tag_r   <= mmu_addr_slot[TAGMSB:TAGLSB];
                        state       <= S_LOOKUP_ISSUE;

                    // cpu_validよりsa_valid優先.
                    end else if (sa_req_slot_valid) begin
                        req_from_mmu    <= 1'b0;
                        req_from_sa     <= 1'b1;
                        req_is_write    <= sa_rw_latch;
                        req_addr_w      <= sa_word_addr_slot;
                        req_addr_b      <= sa_byte_addr_slot;
                        req_wdata       <= sa_data_latch;
                        req_write_sel_r <= sa_write_sel_latch;
                        byte_sel        <= sa_byte_addr_slot[1:0];
                        half_sel        <= sa_byte_addr_slot[1];
                        req_word_sel_r  <= sa_word_addr_slot[WORD_BITS-1:0];
                        // MMIO は SA では使わない（即ミス扱い or 無視）
                        cur_index_r     <= sa_byte_addr_slot[TAGLSB-1:OFFSET_BITS];
                        cur_tag_r       <= sa_byte_addr_slot[TAGMSB:TAGLSB];
                        state           <= S_LOOKUP_ISSUE;

                    end else if (cpu_req_slot_valid) begin
                        // 要求ラッチ
                        req_from_mmu    <= 1'b0;
                        req_from_sa     <= 1'b0;
                        req_is_write    <= cpu_rw_latch;
                        req_addr_w      <= cpu_word_addr_slot;
                        req_addr_b      <= cpu_byte_addr_slot;
                        req_wdata       <= cpu_data_latch;
                        req_write_sel_r <= cpu_write_sel_latch;
                        byte_sel        <= cpu_byte_addr_slot[1:0];
                        half_sel        <= cpu_byte_addr_slot[1];
                        req_word_sel_r  <= cpu_word_addr_slot[WORD_BITS-1:0];
                        cpu_req_slot_valid <= 1'b0;    // _valid をクリア

                        // ---------- PROTECT MODE: 書き込み禁止 ----------
                        if (PROTECT_MODE && cpu_rw_latch && (cpu_byte_addr_slot < PROTECT_ADDR)) begin
                            cpu_ready    <= 1'b1;
                            state        <= S_IDLE;
                        end

                        // ---------- PIO：MMIO ----------
                        else if (mmio_hit(cpu_byte_addr_slot)) begin
                            if(cpu_rw_latch) begin
                                mmio_valid  <= 1'b1;
                                mmio_rw     <= 1'b1;
                                mmio_addr   <= cpu_byte_addr_slot;
                                mmio_wdata  <= cpu_data_latch;
                                state       <= S_MMIO_WAIT;
                            end else begin
                                mmio_valid  <= 1'b1;
                                mmio_rw     <= 1'b0;
                                mmio_addr   <= cpu_byte_addr_slot;
                                state       <= S_MMIO_WAIT;
                            end
                        end

                        // ---------- キャッシュルックアップ ----------
                        else begin
                            cur_index_r <= cpu_byte_addr_slot[TAGLSB-1:OFFSET_BITS];
                            cur_tag_r   <= cpu_byte_addr_slot[TAGMSB:TAGLSB];
                            state       <= S_LOOKUP_ISSUE;
                        end
                    end
                end

                // ---------------- MMIO WAIT ----------------
                // state = 11
                S_MMIO_WAIT: begin
                    if(mmio_ready) begin
                        cpu_ready     <= 1'b1;
                        state <= S_IDLE;
                    end
                end

                // ---- index提示（1clk 後に tag/data が有効） ----
                // state = 4
                S_LOOKUP_ISSUE: begin
                    state <= S_COMPARE;
                end

                // ---------------- COMPARE ----------------
                // state = 6
                S_COMPARE: begin
                    if (lookup_valid && (lookup_tag == cur_tag_r)) begin
                        // ---- HIT ----
                        if (req_is_write) begin
                            // ライン更新 + dirty=1
                            tag_write  <= {tag_read_tag, 1'b1, 1'b1};  // valid=1, dirty=1
                            tag_we     <= 1'b1;
                            if (req_from_sa) sa_req_slot_valid  <= 1'b0;
                            if (req_from_sa) sa_ready   <= 1'b1;
                            else             cpu_ready  <= 1'b1;
                            cache_hit_pulse <= 1'b1;
                            state      <= S_IDLE;
                        end else begin
                            // ---- READ HIT ----
                            if (req_from_mmu) begin
                                mmu_req_slot_valid <= 1'b0;
                                mmu_ready    <= 1'b1;
                            end else if (req_from_sa) begin
                                sa_req_slot_valid <= 1'b0;
                                sa_ready    <= 1'b1;
                            end else begin
                                cpu_req_slot_valid <= 1'b0;
                                cpu_ready    <= 1'b1;
                            end
                            cache_hit_pulse <= 1'b1;
                            state <= S_IDLE;
                        end

                    end else begin
                        // ---- MISS ----
                        // PROTECT領域への書込み要求はキャッシュを変更せず完了する
                        if (req_is_write && PROTECT_MODE &&
                            (req_addr_b < PROTECT_ADDR)) begin
                            if (req_from_sa) begin
                                sa_req_slot_valid <= 1'b0;
                                sa_ready       <= 1'b1;
                            end else begin
                                cpu_req_slot_valid <= 1'b0;
                                cpu_ready       <= 1'b1;
                            end
                            state <= S_IDLE;
                        end else if (lookup_valid && lookup_dirty) begin
                            // dirty victimを先にWRITEBACK
                            if (mem_req_ready) begin
                                cache_miss_pulse <= 1'b1;
                                state            <= S_WRITEBACK;
                            end
                        end else begin
                            // READ/WRITEともにREAD ALLOCATE
                            if (mem_req_ready) begin
                                cache_miss_pulse <= 1'b1;
                                state            <= S_ALLOC_WAIT;
                            end
                        end
                    end
                end

                // ---------------- WRITEBACK ----------------
                // state = 7
                S_WRITEBACK: begin
                    if (mem_ready) begin
                        // READ/WRITEともにvictim退避後は新ラインを取得する
                        state <= S_POST_WBALLOC;
                    end
                end

                // ------ WB後、mem_req_ready待ってALLOC発行 ------
                // state = 10
                S_POST_WBALLOC: begin
                    if (mem_req_ready) begin
                        state     <= S_ALLOC_WAIT;
                    end
                end

                // -------------- 外部READ完了待ち（ALLOC） --------------
                // state = 8
                S_ALLOC_WAIT: begin
                    if (mem_ready) begin
                        if (req_is_write) begin

                            tag_write <= {cur_tag_r, 1'b1, 1'b1};
                            tag_we    <= 1'b1;

                            // 処理した要求だけをクリアする
                            if (req_from_sa) begin
                                sa_req_slot_valid <= 1'b0;
                                sa_ready       <= 1'b1;
                            end else begin
                                cpu_req_slot_valid <= 1'b0;
                                cpu_ready       <= 1'b1;
                            end

                            state <= S_IDLE;
                        end else begin
                            tag_write   <= {cur_tag_r, 1'b1, 1'b0};
                            tag_we      <= 1'b1;
                            if (req_from_mmu) begin
                                mmu_req_slot_valid  <= 1'b0;
                                mmu_ready    <= 1'b1;
                            end else if (req_from_sa) begin
                                sa_req_slot_valid  <= 1'b0;
                                sa_ready     <= 1'b1;
                            end else begin
                                cpu_req_slot_valid  <= 1'b0;
                                cpu_ready    <= 1'b1;
                            end
                            state <= S_IDLE;
                        end
                    end
                end

                // ------------------------------------------
                // Write back all
                // ------------------------------------------

                // -------- CACHE ALL DATA WRITEBACK --------
                S_CACHE_WB_START: begin
                    cur_index_r <= cache_wb_index;
                    state <= S_CACHE_WB_START_WAIT;
                end

                S_CACHE_WB_START_WAIT: begin
                    state <= S_CACHE_WB_CHECK;
                end

                // -------- TAG CHECK --------
                S_CACHE_WB_CHECK: begin

                    if (tag_read_valid && tag_read_dirty) begin
                        state <= S_CACHE_WB_WRITE_REQ;
                    end
                    else begin
                        state <= S_CACHE_WB_NEXT;
                    end

                end

                // -------- メモリにWB --------
                S_CACHE_WB_WRITE_REQ: begin
                    if (mem_req_ready) begin
                        state        <= S_CACHE_WB_WRITE_WAIT;
                    end
                end

                S_CACHE_WB_WRITE_WAIT: begin
                    if (mem_ready) begin
                        cur_index_r <= cache_wb_index;
                        tag_write   <= {tag_read_tag, 1'b1, 1'b0};
                        tag_we      <= 1'b1;
                        state       <= S_CACHE_WB_NEXT;
                    end
                end

                // -------- アドレスインクメント --------
                S_CACHE_WB_NEXT: begin

                    if (cache_wb_index == DEPTH-1) begin
                        cpu_ready <= 1'b1;
                        cache_wb_index <= {INDEX_WIDTH_BA{1'b0}};
                        state <= S_IDLE;
                    end
                    else begin
                        cache_wb_index <= cache_wb_index + 1'b1;
                        state <= S_CACHE_WB_START;
                    end

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
        .index     (tag_index),
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
