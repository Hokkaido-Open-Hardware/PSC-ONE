`timescale 1ns/1ps
// Provisional Sv39 walker, based on cpu_v1/src/MMU.sv.
// Profile: Sv39 + Svade, SUM=0, MXR=0, no translation/PTE cache.
// priv_mode must be the effective privilege (resolve data MPRV externally).
// No PMP/PMA or bus-error input exists yet; these need access-fault plumbing.
// satp CSR is still Bare-only in the surrounding core: integration is TODO.
//
// MMU_enb is a one-cycle request, accepted only while idle. Context is latched.
// mem_addr is stable before mem_valid. mem_req_ready grants a one-cycle
// request pulse on the following cycle (the same contract as cpu_v1).
// Return one atomic 64-bit PTE with mem_ready, at/after the request pulse.
// No new request is issued until the response arrives; no timeout is assumed.
// SFENCE.VMA is a full fence: an active walk drains its outstanding read,
// then restarts. Caller orders page-table stores before asserting the fence.
// Consume translated paddr only with mmu_done && !page_fault.
module MMU (
    input logic clk, reset_n, MMU_enb,
    input logic [63:0] vaddr, satp,
    input logic [1:0] priv_mode,
    input logic access_r, access_w, access_x,
    input logic mem_req_ready,
    input logic [63:0] mem_rdata,
    output logic [63:0] mem_addr,
    output logic mem_valid,
    input logic mem_ready, cpu_state_done, sfence_vma,
    output logic [63:0] paddr,
    output logic page_fault, mode_translate, mmu_done
);
    localparam logic [1:0] PRIV_U = 2'b00;
    localparam logic [1:0] PRIV_S = 2'b01;
    localparam logic [1:0] PRIV_M = 2'b11;

    typedef enum logic [2:0] {
        S_IDLE, S_START, S_REQ, S_WAIT, S_CHECK, S_DONE
    } state_t;
    state_t state;

    logic [63:0] req_vaddr;
    logic [43:0] root_ppn;
    logic [3:0] req_mode;
    logic [1:0] req_priv, level;
    logic req_r, req_w, req_x;
    logic [63:0] pte, translated_paddr;
    logic fence_pending;
    logic pte_leaf, pte_invalid, permission_ok, misaligned_leaf;
    logic [63:0] leaf_paddr, next_pte_addr;

    // Unsupported non-Bare modes also enter the walker and fail closed.
    // CSR WARL logic must reject unsupported MODE writes at integration time.
    assign mode_translate = (satp[63:60] != 4'd0) && (priv_mode != PRIV_M);
    // Preserve the original combinational Bare path and one-cycle completion.
    assign paddr = ((state != S_IDLE) || mmu_done || mode_translate)
                 ? translated_paddr : vaddr;

    // Datapath: 44-bit PPN + 12-bit offset = 56-bit PA, zero-extended to 64.
    // No Svnapot/Svpbmt/other PTE extensions: bits 63:54 must be zero.
    assign pte_leaf = pte[1] || pte[3];
    assign pte_invalid = !pte[0] || (!pte[1] && pte[2]) || (|pte[63:54]);
    assign permission_ok =
        (!req_r || pte[1]) && (!req_w || pte[2]) && (!req_x || pte[3]) &&
        (((req_priv == PRIV_U) && pte[4]) ||
         ((req_priv == PRIV_S) && !pte[4])) &&
        pte[6] && (!req_w || pte[7]); // Svade: fault instead of updating A/D
    assign misaligned_leaf = ((level == 2'd2) && (|pte[27:10])) ||
                             ((level == 2'd1) && (|pte[18:10]));

    always_comb begin
        leaf_paddr = {8'b0, pte[53:10], req_vaddr[11:0]};
        case (level)
            2'd2: leaf_paddr = {8'b0, pte[53:28], req_vaddr[29:0]};
            2'd1: leaf_paddr = {8'b0, pte[53:19], req_vaddr[20:0]};
            default: ;
        endcase
        // Each table is 4 KiB aligned; VPN * 8 fills its low 12 bits.
        if (level == 2'd2)
            next_pte_addr = {8'b0, pte[53:10], req_vaddr[29:21], 3'b0};
        else
            next_pte_addr = {8'b0, pte[53:10], req_vaddr[20:12], 3'b0};
    end

    // Control: reuse the same request/wait/check states at all three levels.
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= S_IDLE;
            mmu_done <= 1'b0;
            mem_valid <= 1'b0;
            mem_addr <= '0;
            page_fault <= 1'b0;
            translated_paddr <= '0;
            req_vaddr <= '0;
            root_ppn <= '0;
            req_mode <= '0;
            req_priv <= PRIV_M;
            req_r <= 1'b0;
            req_w <= 1'b0;
            req_x <= 1'b0;
            level <= 2'd2;
            pte <= '0;
            fence_pending <= 1'b0;
        end else begin
            mem_valid <= 1'b0;
            mmu_done <= 1'b0;
            // Do not clear a newly completed fault until the consumer sees it.
            if (cpu_state_done && (state == S_IDLE))
                page_fault <= 1'b0;
            if (sfence_vma && (state != S_IDLE))
                fence_pending <= 1'b1;

            case (state)
                S_IDLE: begin
                    fence_pending <= 1'b0;
                    if (MMU_enb) begin
                        page_fault <= 1'b0;
                        translated_paddr <= vaddr;
                        if (!mode_translate) begin
                            mmu_done <= 1'b1;
                        end else begin
                            req_vaddr <= vaddr;
                            root_ppn <= satp[43:0];
                            req_mode <= satp[63:60];
                            req_priv <= priv_mode;
                            req_r <= access_r;
                            req_w <= access_w;
                            req_x <= access_x;
                            translated_paddr <= '0;
                            state <= S_START;
                        end
                    end
                end
                S_START: begin
                    fence_pending <= 1'b0;
                    page_fault <= 1'b0;
                    level <= 2'd2;
                    if ((req_mode != 4'd8) ||
                        (req_vaddr[63:39] != {25{req_vaddr[38]}}) ||
                        ((req_priv != PRIV_U) && (req_priv != PRIV_S))) begin
                        page_fault <= 1'b1;
                        state <= S_DONE;
                    end else begin
                        mem_addr <= {8'b0, root_ppn, req_vaddr[38:30], 3'b0};
                        state <= S_REQ;
                    end
                end
                S_REQ: begin
                    if (fence_pending || sfence_vma)
                        state <= S_START;
                    else if (mem_req_ready) begin
                        mem_valid <= 1'b1;
                        state <= S_WAIT;
                    end
                end
                S_WAIT: begin
                    if (mem_ready) begin
                        pte <= mem_rdata;
                        state <= S_CHECK;
                    end
                end
                S_CHECK: begin
                    if (fence_pending || sfence_vma) begin
                        state <= S_START;
                    end else if (pte_invalid) begin
                        page_fault <= 1'b1;
                        state <= S_DONE;
                    end else if (pte_leaf) begin
                        if (misaligned_leaf || !permission_ok)
                            page_fault <= 1'b1;
                        else
                            translated_paddr <= leaf_paddr;
                        state <= S_DONE;
                    end else if ((level == 2'd0) || pte[7] || pte[6] || pte[4]) begin
                        // Non-leaf D/A/U are reserved; G and RSW are legal.
                        page_fault <= 1'b1;
                        state <= S_DONE;
                    end else begin
                        level <= level - 2'd1;
                        mem_addr <= next_pte_addr;
                        state <= S_REQ;
                    end
                end
                S_DONE: begin
                    if (fence_pending || sfence_vma) begin
                        translated_paddr <= '0;
                        state <= S_START;
                    end else begin
                        mmu_done <= 1'b1;
                        state <= S_IDLE;
                    end
                end
                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
