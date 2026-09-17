// NISHIHARU — Sv32 MMU (sync, PTE fetch waits for mem_ready)
// Assumption: PTE data (mem_rdata) becomes valid ONLY when mem_ready==1.
// mem_req is a 1‑cycle pulse; address must be set before asserting mem_req.
`timescale 1ns/1ps

module MMU (
    input  wire             clk,
    input  wire             reset_n,
    input  wire             MMU_enb,
    input  wire [31:0]      vaddr,       // 仮想アドレス
    input  wire [31:0]      satp,        // CSR satp
    input  wire [1:0]       priv_mode,   // M-mode -> MMU:off
    input  wire             access_r,    // 読みアクセス要求？
    input  wire             access_w,    // 書きアクセス要求？
    input  wire             access_x,    // 実行アクセス要求？
    input  wire [31:0]      mem_rdata,   // PTE値（mem_readyが1のサイクルで有効）
    input  wire             mem_ready,   // ★追加: PTE応答レディ（この拍にmem_rdata有効）
    input  wire             cpu_state_done,  // CPU state終了タイミング
    input  wire             sfence_vma,      // sfence.vma（TLBキャッシュクリア）

    input  wire             mem_req_ready,
    output wire [31:0]      mem_addr,     // PTE取得用 物理アドレス
    output reg              mem_valid,    // PTE読出し要求（1サイクルパルス）
    output wire [31:0]      paddr,        // 変換後の 物理アドレス
    output reg              page_fault,   // どれかのページフォールト（種別は外で解釈）
    output wire             mode_sv32,
    output wire             mmu_done      // MMU完了通知
);

    // Privilege level encoding (RISC-V spec)
    localparam [1:0] PRIV_U = 2'b00;
    localparam [1:0] PRIV_S = 2'b01;
    localparam [1:0] PRIV_M = 2'b11;

    // MMU完了通知.
    assign  mmu_done = (state==S_DONE);

    // sfence_vma_reg
    reg     sfence_vma_reg;

    // ---- SV32 のアドレス分解 ----
    wire [9:0]  vpn1     = vaddr[31:22];
    wire [9:0]  vpn0     = vaddr[21:12];
    wire [11:0] page_off = vaddr[11:0];

    // paddr_34bitの32bitのみ使用
    reg [33:0] paddr_34bit;
    assign     paddr = paddr_34bit[31:0];

    reg [33:0] mem_addr_34bit;
    assign     mem_addr = mem_addr_34bit[31:0];

    // satp フィールド（SV32）
    assign      mode_sv32 = satp[31];       // MODE: 0=bare, 1=Sv32
    wire [21:0] root_ppn  = satp[21:0];     // ルートページテーブルの PPN

    // ---- ステート ----
    localparam [3:0]
        S_IDLE      = 4'd0,
        S_START     = 4'd1,
        S_L1_REQ    = 4'd2,
        S_L1_WAIT   = 4'd3,
        S_L1_CHECK  = 4'd4,
        S_L0_REQ    = 4'd5,
        S_L0_WAIT   = 4'd6,
        S_L0_CHECK  = 4'd7,
        S_DONE      = 4'd8;


    reg [3:0] state;

    // ---- PTE ラッチ ----
    reg [31:0] pte_l1, pte_l0;

    // ---- PTE Cache ----
    reg pte_cached;
    reg [21:0] cache_root_ppn;
    reg [9:0]  cache_vpn1;
    reg [31:0] cache_pte_l1;

    // L1
    wire cache_hit = pte_cached &&
                    (cache_root_ppn == root_ppn) &&
                    (cache_vpn1 == vpn1);

    reg        l0_cached;
    reg [31:0] cache_pte_l0;
    reg [9:0]  cache_vpn0;

    // L0
    wire l0_cache_hit = l0_cached &&
                        cache_hit &&       // ← L1が一致していること
                        (cache_vpn0 == vpn0);

    // ---- ヘルパ（許可・違法組合せチェック）---- (Verilog-2001 style)

    // W=1 && R=0 は違法
    function [0:0] illegal_rw;
        input [31:0] pte;
    begin
        illegal_rw = (pte[2] && !pte[1]);
    end
    endfunction

    // R=1 または X=1 なら leaf
    function [0:0] is_leaf;
        input [31:0] pte;
    begin
        is_leaf = (pte[1] || pte[3]);
    end
    endfunction

    // V=1 && (W=1 -> R=1) が最低条件
    function [0:0] pte_valid;
        input [31:0] pte;
    begin
        pte_valid = (pte[0] && !illegal_rw(pte));
    end
    endfunction

    // 要求アクセスと PTE パーミッションの突き合わせ
    // r/w/x は 1bit入力（0=不要, 1=必要）
    function [0:0] perm_ok;
        input [31:0] pte;
        input        r;
        input        w;
        input        x;
    begin
        perm_ok = ((!r) || pte[1]) &&
                  ((!w) || pte[2]) &&
                  ((!x) || pte[3]);
        // ※ U/S, A/D ビットの扱いは最小実装として省略
    end
    endfunction

    // ===== 本体 =====
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state       <= S_IDLE;
            mem_valid   <= 1'b0;
            mem_addr_34bit <= 34'h0;
            paddr_34bit    <= 34'h0;
            page_fault  <= 1'b0;
            pte_l1      <= 32'h0;
            pte_l0      <= 32'h0;
            // cache 
            pte_cached      <= 1'b0;
            cache_root_ppn  <= 22'h0;
            cache_vpn1      <= 10'd0;
            cache_pte_l1    <= 32'h0;
            cache_pte_l0    <= 32'h0;
            l0_cached       <= 1'b0;
            cache_vpn0      <= 10'd0;
            // sfence_vma
            sfence_vma_reg <= 1'b0;
        end else begin
            
            // --------------------------------------------------
            //  cpu state done. sfence_vma. 
            // --------------------------------------------------
            // page_falut=Lに戻す.
            if(cpu_state_done) 
                page_fault <= 1'b0; 
            // PTEキャッシュクリア. cpu_state_done=Hと同じ
            if (sfence_vma) 
                sfence_vma_reg <= 1'b1;

            // sfence_vmaの処理. 無条件でcache_vpnをクリア
            if(sfence_vma_reg) begin
                pte_cached      <= 1'b0;
                l0_cached       <= 1'b0;
                if (state == S_IDLE || state == S_DONE)
                    sfence_vma_reg  <= 1'b0;    // sfence_vma_reg をクリア
            end

            // --------------------------------------------------
            //  MMU  state machine 
            // --------------------------------------------------
            // デフォルト：1サイクルパルス信号は下げておく
            mem_valid  <= 1'b0;

            // MMUステートマシン
            case (state)
                // --------------------------------------------------
                S_IDLE: begin
                    if (MMU_enb)
                        state    <= S_START;
                end

                // --------------------------------------------------
                S_START: begin
                    page_fault <= 1'b0; // 新規トランザクション開始
                    if (!mode_sv32 || (priv_mode == PRIV_M)) begin
                        // Bare モード：変換無し
                        paddr_34bit <= vaddr;
                        state       <= S_DONE;
                    end else begin
                        // PTE モード：変換あり
                        if(cache_hit) begin    // PTEキャッシュあり
                            pte_l1 <= cache_pte_l1;
                            state <= S_L1_CHECK;
                        end else begin          // PTEキャッシュなし
                            // L1 PTE を読む：root + vpn1*4
                            //mem_addr <= {root_ppn, 12'b0} + {vpn1, 2'b00}; // <<2
                            mem_addr_34bit <= {root_ppn, 12'b0} + {vpn1, 2'b00};
                            if(mem_req_ready)
                                state    <= S_L1_REQ;
                        end
                    end
                end

                // --------------------------------------------------
                S_L1_REQ: begin
                    mem_valid <= 1'b1;       // 1サイクル発行
                    state     <= S_L1_WAIT;  // 応答待ちへ
                end

                S_L1_WAIT: begin
                    if (mem_ready) begin
                        pte_l1          <= mem_rdata; // この拍に有効
                        cache_pte_l1    <= mem_rdata;
                        cache_vpn1      <= vpn1;        // vpn1 cache data
                        cache_root_ppn  <= root_ppn;    // cache vpn1 に対応する root_ppn
                        pte_cached      <= 1'b1;
                        state  <= S_L1_CHECK;
                    end
                end

                S_L1_CHECK: begin
                    // V=1? W=1 & R=0 でない? をまず確認
                    if (!pte_valid(pte_l1)) begin
                        page_fault <= 1'b1;
                        state      <= S_DONE;
                    end else if (is_leaf(pte_l1)) begin
                        // ---- 4MiB スーパー・ページ ----
                        // L1 leaf の場合、PPN[0] は 0 必須（アラインメント）
                        if (|pte_l1[19:10]) begin
                            page_fault <= 1'b1; // misaligned superpage
                            state      <= S_DONE;
                        end else if (!perm_ok(pte_l1, access_r, access_w, access_x)) begin
                            page_fault <= 1'b1;
                            state      <= S_DONE;
                        end else begin
                            // Sv32 L1 leaf (4MiB superpage)
                            // PA[31:22] = PTE.PPN[1] (= pte_l1[31:20])
                            // PA[21:12] = VA.VPN[0] (= vpn0)
                            // PA[11:0]  = VA.offset (= page_off)
                            paddr_34bit <= {pte_l1[31:20], vpn0, page_off};
                            state       <= S_DONE;
                        end
                    end else begin
                        // ポインタPTE → L0
                        if (l0_cache_hit) begin
                            pte_l0 <= cache_pte_l0;
                            state  <= S_L0_CHECK;
                        end else begin
                            // ---- ポインタPTE → L0 へ降りる ----
                            // next PT base = {PPN, 12'b0}
                            //mem_addr <= {pte_l1[31:10], 12'b0} + {vpn0, 2'b00};
                            mem_addr_34bit <= {pte_l1[31:10], 12'b0} + {vpn0, 2'b00};
                            if(mem_req_ready)
                                state    <= S_L0_REQ;
                        end
                    end
                end

                // --------------------------------------------------
                S_L0_REQ: begin
                    mem_valid <= 1'b1;
                    state     <= S_L0_WAIT;
                end

                S_L0_WAIT: begin
                    if (mem_ready) begin
                        pte_l0       <= mem_rdata;
                        cache_pte_l0 <= mem_rdata;      // vpn0 cache data
                        cache_vpn0   <= vpn0;           // cache vpn0 に対応するvpn0
                        l0_cached    <= 1'b1;
                        state  <= S_L0_CHECK;
                    end
                end

                S_L0_CHECK: begin
                    if (!pte_valid(pte_l0)) begin
                        page_fault <= 1'b1;
                        state      <= S_DONE;
                    end else if (!perm_ok(pte_l0, access_r, access_w, access_x)) begin
                        page_fault <= 1'b1;
                        state      <= S_DONE;
                    end else begin
                        // 4KiBページ
                        //paddr <= {pte_l0[31:10], page_off};
                        //paddr <= ({10'b0, pte_l0[31:10]} << 12) | {20'b0, page_off};
                        paddr_34bit <= {pte_l0[31:10], page_off};
                        state       <= S_DONE;
                    end
                end

                // --------------------------------------------------
                S_DONE: begin
                    // 次の要求をそのまま受けられるように戻す
                    state <= S_IDLE;
                end

                default: state <= S_IDLE;

            endcase
        end
    end

endmodule