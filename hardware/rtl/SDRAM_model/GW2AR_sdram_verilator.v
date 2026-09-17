// ============================================================================
//  GW2AR_sdram_verilator.v
//    - GW2AR 内蔵 SDRAM用 Verilator SDRAM モデル（バースト対応 / READ キュー8）
//    - コントローラのパイプラインに合わせて CAS 前倒し調整可能
//    - $display ログを DEBUG_SDRAM=1 で有効化
// ============================================================================

`timescale 1ns/1ps

module GW2AR_sdram #(
    parameter addr_bits     = 11,
    parameter COL_BITS      = 8,
    parameter ROW_BITS      = 11,
    parameter BA_BITS       = 2,

    parameter integer timing_RCD = 2,
    parameter integer timing_CAS = 3,
    parameter integer timing_RP  = 3,

    // コントローラ遅延吸収用（CAS 前倒し量）
    parameter integer CAS_ADJUST = 2,

    // WRITE 遅延
    parameter integer WRITE_LATENCY = 0,

    // ★ ログ出力 ON/OFF（1=表示、0=非表示）
    parameter DEBUG_SDRAM = 0
)(
    input  wire                 Clk,
    input  wire                 Cke,
    input  wire                 Cs_n,
    input  wire                 Ras_n,
    input  wire                 Cas_n,
    input  wire                 We_n,
    input  wire [addr_bits-1:0] Addr,
    input  wire [BA_BITS-1:0]   Ba,
    input  wire [3:0]           Dqm,
    inout  wire [31:0]          Dq
);

    // =========================================================================
    // メモリ配列
    // =========================================================================
    localparam integer BANKS     = (1 << BA_BITS);
    localparam integer ROWS      = (1 << ROW_BITS);
    localparam integer COLS      = (1 << COL_BITS);
    localparam integer MEM_DEPTH = BANKS * ROWS * COLS;

    function integer INDEX;
        input [BA_BITS-1:0]  ba;
        input [ROW_BITS-1:0] row;
        input [COL_BITS-1:0] col;
        INDEX = (ba * ROWS * COLS) + (row * COLS) + col;
    endfunction

    reg [31:0] mem [0:MEM_DEPTH-1];
    integer i;
    initial for (i = 0; i < MEM_DEPTH; i = i + 1) mem[i] = 32'h0000;

    // =========================================================================
    // DQ トライステート
    // =========================================================================
    reg [31:0] dq_out = 32'h0000;
    reg        dq_oe  = 1'b0;

    assign Dq = dq_oe ? dq_out : 32'hzzzz;

    // =========================================================================
    // コマンド判定
    // =========================================================================
    wire cmd_act   = (Cs_n==0 && Ras_n==0 && Cas_n==1 && We_n==1);
    wire cmd_read  = (Cs_n==0 && Ras_n==1 && Cas_n==0 && We_n==1);
    wire cmd_write = (Cs_n==0 && Ras_n==1 && Cas_n==0 && We_n==0);
    wire cmd_pre   = (Cs_n==0 && Ras_n==0 && Cas_n==1 && We_n==0);
    wire cmd_nop   = (Cs_n==0 && Ras_n==1 && Cas_n==1 && We_n==1);

    // =========================================================================
    // バンク管理
    // =========================================================================
    reg [ROW_BITS-1:0] open_row [0:BANKS-1];
    reg                row_open [0:BANKS-1];

    initial begin
        for (i = 0; i < BANKS; i = i + 1) begin
            row_open[i] = 1'b0;
            open_row[i] = 0;
        end
    end

    // =========================================================================
    // READ キュー（最大8）
    // =========================================================================
    localparam integer MAX_RD = 8;

    reg                 rd_valid [0:MAX_RD-1];
    reg [3:0]           rd_timer [0:MAX_RD-1];
    reg [BA_BITS-1:0]   rd_ba    [0:MAX_RD-1];
    reg [ROW_BITS-1:0]  rd_row   [0:MAX_RD-1];
    reg [COL_BITS-1:0]  rd_col   [0:MAX_RD-1];

    integer r;
    initial begin
        for (r = 0; r < MAX_RD; r = r + 1) begin
            rd_valid[r] = 1'b0;
            rd_timer[r] = 4'd0;
        end
    end

    // =========================================================================
    // WRITE パイプライン
    // =========================================================================
    reg wr_pending = 0;
    integer wr_timer = 0;
    reg [BA_BITS-1:0]  wr_ba;
    reg [ROW_BITS-1:0] wr_row;
    reg [COL_BITS-1:0] wr_col;

    // =========================================================================
    // メイン処理
    // =========================================================================
    integer idx, sel;
    integer eff_cas;
    integer f;

    always @(posedge Clk) begin
        if (!Cke) begin
            dq_oe  <= 1'b0;
            dq_out <= 16'h0000;

            for (i = 0; i < BANKS; i = i + 1) begin
                row_open[i] <= 1'b0;
                open_row[i] <= 0;
            end

            for (i = 0; i < MAX_RD; i = i + 1) begin
                rd_valid[i] <= 1'b0;
                rd_timer[i] <= 4'd0;
            end

            wr_pending <= 0;
            wr_timer   <= 0;

        end else begin
            // ------------------------------------------------------------
            // デフォルトは Hi-Z
            // ------------------------------------------------------------
            dq_oe  <= 1'b0;
            dq_out <= 32'h0000;

            // ------------------------------------------------------------
            // READ キュー timer 更新
            // ------------------------------------------------------------
            for (idx = 0; idx < MAX_RD; idx = idx + 1)
                if (rd_valid[idx] && rd_timer[idx] != 0)
                    rd_timer[idx] <= rd_timer[idx] - 1;

            // ------------------------------------------------------------
            // READ-OUT：timer==0 の最初のスロットだけ出力
            // ------------------------------------------------------------
            sel = -1;
            for (idx = 0; idx < MAX_RD; idx = idx + 1)
                if (rd_valid[idx] && rd_timer[idx] == 0 && sel == -1)
                    sel = idx;

            if (sel != -1) begin
                dq_oe  <= 1'b1;
                dq_out <= mem[ INDEX(rd_ba[sel], rd_row[sel], rd_col[sel]) ];
                rd_valid[sel] <= 1'b0;

                if (DEBUG_SDRAM)
                $display("[%0t] SDRAM READ-OUT   slot=%0d ba=%0d row=%0d col=%0d data=%h",
                         $time, sel, rd_ba[sel], rd_row[sel], rd_col[sel],
                         mem[INDEX(rd_ba[sel], rd_row[sel], rd_col[sel])]);
            end

            // ------------------------------------------------------------
            // WRITE パイプライン
            // ------------------------------------------------------------
            if (wr_pending) begin
                if (wr_timer > 0) wr_timer <= wr_timer - 1;
                else begin
                    mem[ INDEX(wr_ba, wr_row, wr_col) ] <= Dq;
                    wr_pending <= 0;

                    if (DEBUG_SDRAM)
                    $display("[%0t] SDRAM WRITE COMMIT ba=%0d row=%0d col=%0d data=%h",
                             $time, wr_ba, wr_row, wr_col, Dq);
                end
            end

            // ------------------------------------------------------------
            // CMD: ACTIVATE
            // ------------------------------------------------------------
            if (cmd_act) begin
                open_row[Ba] <= Addr;
                row_open[Ba] <= 1'b1;

                if (DEBUG_SDRAM)
                $display("[%0t] SDRAM ACT        ba=%0d row=%0d", $time, Ba, Addr);
            end

            // ------------------------------------------------------------
            // CMD: PRECHARGE
            // ------------------------------------------------------------
            if (cmd_pre) begin
                row_open[Ba] <= 1'b0;

                if (DEBUG_SDRAM)
                $display("[%0t] SDRAM PRE        ba=%0d", $time, Ba);
            end

            // ------------------------------------------------------------
            // CMD: READ
            // ------------------------------------------------------------
            if (cmd_read) begin
                f = -1;
                for (idx = 0; idx < MAX_RD; idx = idx + 1)
                    if (!rd_valid[idx] && f == -1) f = idx;

                if (f != -1) begin
                    eff_cas = timing_CAS - CAS_ADJUST;
                    if (eff_cas < 0) eff_cas = 0;

                    rd_valid[f] <= 1'b1;
                    rd_timer[f] <= eff_cas[3:0];
                    rd_ba[f]    <= Ba;
                    rd_row[f]   <= open_row[Ba];
                    rd_col[f]   <= Addr[COL_BITS-1:0];

                    if (DEBUG_SDRAM)
                    $display("[%0t] SDRAM READ CMD   slot=%0d ba=%0d row=%0d col=%0d (CAS=%0d eff=%0d)",
                             $time, f, Ba, open_row[Ba], Addr[COL_BITS-1:0],
                             timing_CAS, eff_cas);

                end else if (DEBUG_SDRAM) begin
                    $display("[%0t] *** SDRAM READ CMD DROPPED: queue full", $time);
                end
            end

            // ------------------------------------------------------------
            // CMD: WRITE
            // ------------------------------------------------------------
            if (cmd_write) begin
                if (WRITE_LATENCY == 0) begin
                    mem[ INDEX(Ba, open_row[Ba], Addr[COL_BITS-1:0]) ] <= Dq;

                    if (DEBUG_SDRAM)
                    $display("[%0t] SDRAM WRITE IMMED ba=%0d row=%0d col=%0d data=%h",
                             $time, Ba, open_row[Ba], Addr[COL_BITS-1:0], Dq);

                end else begin
                    wr_pending <= 1'b1;
                    wr_timer   <= WRITE_LATENCY;
                    wr_ba      <= Ba;
                    wr_row     <= open_row[Ba];
                    wr_col     <= Addr[COL_BITS-1:0];

                    if (DEBUG_SDRAM)
                    $display("[%0t] SDRAM WRITE CMD   ba=%0d row=%0d col=%0d WLAT=%0d data_now=%h",
                             $time, Ba, wr_row, wr_col, WRITE_LATENCY, Dq);
                end
            end

        end // else Cke
    end // always
endmodule