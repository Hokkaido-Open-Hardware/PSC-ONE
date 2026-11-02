// NISHIHARU — Sv32 MMU
// Assumption: PTE data (mem_rdata) becomes valid ONLY when mem_ready==1.
// mem_valid is a 1-cycle pulse; address must be set before asserting mem_valid.

`timescale 1ns/1ps

module MMU (
    input  logic            clk,
    input  logic            reset_n,
    input  logic            MMU_enb,
    input  logic [31:0]     vaddr,           // Virtual address
    input  logic [31:0]     satp,            // CSR satp
    input  logic [1:0]      priv_mode,       // M-mode -> MMU off
    input  logic [31:0]     mstatus,         // SUM/MXR and data-only MPRV/MPP
    input  logic            access_r,        // Read access
    input  logic            access_w,        // Write access
    input  logic            access_x,        // Execute access

    input  logic            mem_req_ready,
    input  logic [31:0]     mem_rdata,       // Valid when mem_ready==1
    output logic [31:0]     mem_addr,        // Physical address for PTE fetch
    output logic            mem_valid,       // 1-cycle PTE read request
    input  logic            mem_access_fault, // Valid with mem_ready
    input  logic            mem_ready,       // PTE response ready

    input  logic            cpu_state_done,
    input  logic            sfence_vma,

    output logic [31:0]     paddr,
    output logic            page_fault,
    output logic            access_fault,    // Physical range / PTE access failure
    output logic            mode_sv32,
    output logic            mmu_done
);

`ifdef COCOTB_SIM
`ifdef CPU_MMU_SIM
    initial begin
`ifdef DUMP_VCD
        $display("COCOTB_SIM MMU DUMP_VCD ENABLE");
        $dumpfile("./wave/PSC_RV32ISP_MMU.vcd");
        $dumpvars(0);
`else
        $display("COCOTB_SIM MMU verilator FST ENABLE");
        $dumpfile("./wave/PSC_RV32ISP_MMU.fst");
        $dumpvars(0);
`endif
    end
`endif
`endif

    // Sv32 + Svade: software manages A/D. Physical bus supports PA[31:0].
    // Keep request context stable across privilege/CSR changes during a walk.
    logic [31:0] req_vaddr, req_satp, req_mstatus;
    logic [1:0] req_priv;
    logic req_r, req_w, req_x;
    wire [1:0] effective_priv = (!access_x && mstatus[17])
                               ? mstatus[12:11] : priv_mode;
    // Privilege level encoding
    localparam logic [1:0] PRIV_U = 2'b00;
    localparam logic [1:0] PRIV_S = 2'b01;
    localparam logic [1:0] PRIV_M = 2'b11;

    // sfence.vma request
    logic sfence_vma_req;

    // ---- Sv32 virtual address fields ----
    logic [9:0]  vpn1;
    logic [9:0]  vpn0;
    logic [11:0] page_offset;

    assign vpn1        = req_vaddr[31:22];
    assign vpn0        = req_vaddr[21:12];
    assign page_offset = req_vaddr[11:0];

    // Physical address: PSC currently uses lower 32 bits only
    logic [33:0] paddr_34bit;
    assign paddr = paddr_34bit[31:0];

    logic [33:0] mem_addr_34bit;
    assign mem_addr = mem_addr_34bit[31:0];

    // ---- satp fields ----
    assign mode_sv32 = satp[31];

    logic [21:0] root_ppn;
    assign root_ppn = req_satp[21:0];

    // ---- MMU state ----
    typedef enum logic [3:0] {
        S_IDLE     = 4'd0,
        S_START    = 4'd1,
        S_L1_REQ   = 4'd2,
        S_L1_WAIT  = 4'd3,
        S_L1_CHECK = 4'd4,
        S_L0_REQ   = 4'd5,
        S_L0_WAIT  = 4'd6,
        S_L0_CHECK = 4'd7,
        S_DONE     = 4'd8
    } state_t;

    state_t state;

    // ---- Page Table Walk registers ----
    // PTE fetched during current page-table walk
    logic [31:0] l1_pte;
    logic [31:0] l0_pte;

    // ---- L1 PTE Cache ----
    // One-entry cache. Key = root_ppn + VPN[1]
    logic        l1_cache_valid;
    logic [21:0] l1_cache_root_ppn;
    logic [9:0]  l1_cache_vpn;
    logic [31:0] l1_cache_pte;

    logic l1_cache_hit;

    assign l1_cache_hit = l1_cache_valid &&
                          (l1_cache_root_ppn == root_ppn) &&
                    (cache_asid == req_satp[30:22]) && !sfence_vma && !sfence_vma_req &&
                          (l1_cache_vpn == vpn1);

    logic [8:0] cache_asid;
    // ---- L0 PTE Cache ----
    // One-entry cache. Key = root_ppn + VPN[1] + VPN[0]
    logic        l0_cache_valid;
    logic [9:0]  l0_cache_vpn;
    logic [31:0] l0_cache_pte;

    logic l0_cache_hit;

    assign l0_cache_hit = l0_cache_valid &&
                          l1_cache_hit &&
                          (l0_cache_vpn == vpn0);

    // W=1 && R=0 is invalid
    function automatic logic illegal_rw(input logic [31:0] pte);
        return pte[2] && !pte[1];
    endfunction

    // R=1 or X=1 means leaf PTE
    function automatic logic is_leaf(input logic [31:0] pte);
        return pte[1] || pte[3];
    endfunction

    // Minimum PTE validity check
    function automatic logic pte_valid(input logic [31:0] pte);
        return pte[0] && !illegal_rw(pte) &&
               (is_leaf(pte) || !(pte[7] || pte[6] || pte[4]));
    endfunction

    // Check requested access permission
    function automatic logic perm_ok(
        input logic [31:0] pte,
        input logic        r,
        input logic        w,
        input logic        x
    );
        return ((!r) || pte[1] || (req_mstatus[19] && pte[3])) &&
               ((!w) || pte[2]) && ((!x) || pte[3]) &&
               ((req_priv == PRIV_U) ? pte[4] :
                (!pte[4] || (!x && req_mstatus[18]))) &&
               pte[6] && (!w || pte[7]);
    endfunction

    // ===== MMU main =====
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            req_vaddr <= 0; req_satp <= 0; req_mstatus <= 0;
            req_priv <= PRIV_M; req_r <= 0; req_w <= 0; req_x <= 0;
            cache_asid <= 0;
            access_fault <= 0;

            state             <= S_IDLE;
            mem_valid         <= 1'b0;
            mem_addr_34bit    <= 34'h0;
            paddr_34bit       <= 34'h0;
            page_fault        <= 1'b0;
            l1_pte            <= 32'h0;
            l0_pte            <= 32'h0;

            // L1 cache
            l1_cache_valid    <= 1'b0;
            l1_cache_root_ppn <= 22'h0;
            l1_cache_vpn      <= 10'h0;
            l1_cache_pte      <= 32'h0;

            // L0 cache
            l0_cache_valid    <= 1'b0;
            l0_cache_vpn      <= 10'h0;
            l0_cache_pte      <= 32'h0;

            // sfence.vma
            sfence_vma_req    <= 1'b0;
            mmu_done          <= 1'b0;
        end else begin
            // CPU state done -> clear previous page fault
            if (cpu_state_done) begin
                page_fault <= 1'b0;
                access_fault <= 1'b0;
            end

            // Latch sfence.vma request
            if (sfence_vma)
                sfence_vma_req <= 1'b1;

            // Default: pulse signals are low
            mem_valid <= 1'b0;
            mmu_done  <= 1'b0;

            unique case (state)

                // --------------------------------------------------
                S_IDLE: begin
                    if (MMU_enb) begin
                        req_vaddr <= vaddr;
                        req_satp <= satp;
                        req_mstatus <= mstatus;
                        req_priv <= effective_priv;
                        req_r <= access_r; req_w <= access_w; req_x <= access_x;
                        state <= S_START;
                    end
                    if (sfence_vma_req)
                        sfence_vma_req <= 1'b0;
                end

                // --------------------------------------------------
                S_START: begin
                    access_fault <= 1'b0;
                    sfence_vma_req <= 1'b0;
                    page_fault <= 1'b0;

                    if (!req_satp[31] || (req_priv == PRIV_M)) begin
                        // Bare mode
                        paddr_34bit <= {2'b00, req_vaddr};
                        state <= S_DONE;
                    end else begin
                        if (|root_ppn[21:20]) begin
                            access_fault <= 1'b1;
                            state <= S_DONE;
                        end else if (l1_cache_hit) begin
                            l1_pte <= l1_cache_pte;
                            state <= S_L1_CHECK;
                        end else begin
                            // L1 PTE address = root + VPN[1] * 4
                            mem_addr_34bit <= {root_ppn, 12'b0} + {22'b0, vpn1, 2'b00};
                            if (mem_req_ready)
                                state <= S_L1_REQ;
                        end
                    end
                end

                // --------------------------------------------------
                S_L1_REQ: begin
                    mem_valid <= 1'b1;
                    state <= S_L1_WAIT;
                end

                S_L1_WAIT: begin
                    if (mem_ready && mem_access_fault) begin
                        access_fault <= 1'b1;
                        state <= S_DONE;
                    end else if (mem_ready) begin
                        cache_asid <= req_satp[30:22];
                        l1_pte            <= mem_rdata;
                        l1_cache_pte      <= mem_rdata;
                        l1_cache_vpn      <= vpn1;
                        l1_cache_root_ppn <= root_ppn;
                        l1_cache_valid    <= 1'b1;
                        // L0 belongs to the previous L1 entry.
                        l0_cache_valid    <= 1'b0;
                        state <= S_L1_CHECK;
                    end
                end

                S_L1_CHECK: begin
                    if (sfence_vma_req || sfence_vma) begin
                        sfence_vma_req <= 1'b0;
                        state <= S_START;
                    end else if (!pte_valid(l1_pte)) begin
                        page_fault <= 1'b1;
                        state <= S_DONE;
                    end else if (is_leaf(l1_pte)) begin
                        // L1 leaf = 4 MiB superpage
                        // PPN[0] must be zero
                        if (|l1_pte[19:10]) begin
                            page_fault <= 1'b1;
                            state <= S_DONE;
                        end else if (!perm_ok(l1_pte, req_r, req_w, req_x)) begin
                            page_fault <= 1'b1;
                            state <= S_DONE;
                        end else if (|l1_pte[31:30]) begin
                            access_fault <= 1'b1;
                            state <= S_DONE;
                        end else begin
                            // PA[31:22] = PTE.PPN[1]
                            // PA[21:12] = VA.VPN[0]
                            // PA[11:0]  = VA.offset
                            paddr_34bit <= {l1_pte[31:20], vpn0, page_offset};
                            state <= S_DONE;
                        end
                    end else begin
                        // Non-leaf -> descend to L0
                        if (|l1_pte[31:30]) begin
                            access_fault <= 1'b1;
                            state <= S_DONE;
                        end else if (l0_cache_hit) begin
                            l0_pte <= l0_cache_pte;
                            state <= S_L0_CHECK;
                        end else begin
                            // L0 PTE address = next PT base + VPN[0] * 4
                            mem_addr_34bit <= {l1_pte[31:10], 12'b0} + {22'b0, vpn0, 2'b00};
                            if (mem_req_ready)
                                state <= S_L0_REQ;
                        end
                    end
                end

                // --------------------------------------------------
                S_L0_REQ: begin
                    mem_valid <= 1'b1;
                    state <= S_L0_WAIT;
                end

                S_L0_WAIT: begin
                    if (mem_ready && mem_access_fault) begin
                        access_fault <= 1'b1;
                        state <= S_DONE;
                    end else if (mem_ready) begin
                        l0_pte         <= mem_rdata;
                        l0_cache_pte   <= mem_rdata;
                        l0_cache_vpn   <= vpn0;
                        l0_cache_valid <= 1'b1;
                        state <= S_L0_CHECK;
                    end
                end

                S_L0_CHECK: begin
                    if (sfence_vma_req || sfence_vma) begin
                        sfence_vma_req <= 1'b0;
                        state <= S_START;
                    end else if (!pte_valid(l0_pte)) begin
                        page_fault <= 1'b1;
                        state <= S_DONE;
                    end else if (!is_leaf(l0_pte)) begin
                        // L0 is final level, so non-leaf is invalid
                        page_fault <= 1'b1;
                        state <= S_DONE;
                    end else if (!perm_ok(l0_pte, req_r, req_w, req_x)) begin
                        page_fault <= 1'b1;
                        state <= S_DONE;
                    end else if (|l0_pte[31:30]) begin
                        access_fault <= 1'b1;
                        state <= S_DONE;
                    end else begin
                        // 4 KiB page
                        paddr_34bit <= {l0_pte[31:10], page_offset};
                        state <= S_DONE;
                    end
                end

                // --------------------------------------------------
                S_DONE: begin
                    mmu_done <= 1'b1;
                    state <= S_IDLE;
                end

                default: state <= S_IDLE;

            endcase
            if (sfence_vma || sfence_vma_req) begin
                l1_cache_valid <= 1'b0;
                l0_cache_valid <= 1'b0;
            end

        end
    end

endmodule
