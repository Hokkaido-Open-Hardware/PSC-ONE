`timescale 1ns/1ps
module tb;
    reg clk = 0;
    always #5 clk = ~clk;
    reg reset_n = 0, en = 0, sfence = 0;
    reg [31:0] va = 0, satp = 32'h80000001;
    wire [31:0] pa, ma;
    wire mv, done, pf;
    reg mr = 0;
    reg [31:0] md = 0;
    integer reads = 0;

    MMU dut (
        .clk(clk), .reset_n(reset_n), .MMU_enb(en), .vaddr(va),
        .satp(satp), .priv_mode(2'b01),
        .access_r(1'b1), .access_w(1'b0), .access_x(1'b0),
        .mem_req_ready(1'b1), .mem_rdata(md), .mem_addr(ma),
        .mem_valid(mv), .mem_ready(mr), .cpu_state_done(1'b0),
        .sfence_vma(sfence), .paddr(pa), .page_fault(pf),
        .mode_sv32(), .mmu_done(done)
    );

    always @(negedge clk) begin
        mr = mv;
        if (mv) begin
            reads = reads + 1;
            case (ma)
                32'h1000: md = 32'h801;
                32'h1004: md = 32'hc01;
                32'h2000: md = 32'h004000c3;
                32'h3000: md = 32'h008000c3;
                32'h4000: md = 32'h1401;
                32'h5000: md = 32'h00c000c3;
                default: md = 0;
            endcase
        end
    end

    task translate(input [31:0] addr, input [31:0] expected);
        begin
            @(negedge clk); va = addr; en = 1;
            @(negedge clk); en = 0;
            wait (done); #1;
            if (pa !== expected || pf)
                $fatal(1, "VA=%08x expected=%08x actual=%08x fault=%b",
                       addr, expected, pa, pf);
            // Legacy done is combinational; v1/v2 done is registered.
            repeat (2) @(negedge clk);
        end
    endtask

    initial begin
        #12; reset_n = 1;
        translate(0, 32'h01000000);
        translate(32'h00400000, 32'h02000000);
        if (reads != 4) $fatal(1, "new L1 must fetch new L0");
        translate(32'h00400000, 32'h02000000);
        if (reads != 4) $fatal(1, "same-page cache hit lost");
        translate(0, 32'h01000000);
        satp = 32'h80000004;
        translate(0, 32'h03000000);
        sfence = 1;
        @(negedge clk); sfence = 0;
        repeat (3) @(negedge clk);
        translate(0, 32'h03000000);
        if (reads != 10) $fatal(1, "sfence did not invalidate both levels");
        $display("MMU regression PASS");
        $finish;
    end
    initial begin #5000; $fatal(1, "timeout"); end
endmodule
