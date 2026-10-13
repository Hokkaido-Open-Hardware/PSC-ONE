`timescale 1ns/1ps
// RV64 Bare address path. No Sv32/Sv39 translation or page-table requests.
// satp is WARL read-only zero in Csr. Keep the request/completion interface
// so a future Sv39 implementation can replace this module explicitly.
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
    assign mode_translate = 1'b0;
    assign mem_valid = 1'b0;
    assign mem_addr = '0;
    assign page_fault = 1'b0;
    assign paddr = vaddr;
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) mmu_done <= 1'b0;
        else mmu_done <= MMU_enb;
    end
    // TODO: Sv39, permission checks and page faults are deliberately out of scope.
endmodule
