`timescale 1ns/1ps
module tb;
    reg clock = 0;
    always #5 clock = ~clock;
    reg reset_n = 0, start = 0;
    reg [31:0] words = 0;
    wire busy, done, arvalid, rready, awvalid, wvalid, bready;
    wire [31:0] araddr, awaddr, wdata;
    reg rvalid = 0, bvalid = 0;
    reg [31:0] rdata = 0;
    integer reads = 0, writes = 0;
    PSC_ONE_DMA_axi dut (
        .clock(clock), .reset_n(reset_n), .dma_start(start),
        .dma_busy(busy), .dma_done(done), .DMA_WORDS(words),
        .BASE_ADDR_READ(32'h1000), .BASE_ADDR_WRITE(32'h2000),
        .dma_axi_awid(), .dma_axi_awaddr(awaddr), .dma_axi_awlen(),
        .dma_axi_awsize(), .dma_axi_awburst(),
        .dma_axi_awvalid(awvalid), .dma_axi_awready(1'b1),
        .dma_axi_wdata(wdata), .dma_axi_wstrb(), .dma_axi_wlast(),
        .dma_axi_wvalid(wvalid), .dma_axi_wready(1'b1),
        .dma_axi_bid(1'b0), .dma_axi_bresp(2'b0),
        .dma_axi_bvalid(bvalid), .dma_axi_bready(bready),
        .dma_axi_arid(), .dma_axi_araddr(araddr), .dma_axi_arlen(),
        .dma_axi_arsize(), .dma_axi_arburst(),
        .dma_axi_arvalid(arvalid), .dma_axi_arready(1'b1),
        .dma_axi_rid(1'b0), .dma_axi_rdata(rdata),
        .dma_axi_rresp(2'b0), .dma_axi_rlast(1'b1),
        .dma_axi_rvalid(rvalid), .dma_axi_rready(rready)
    );
    always @(posedge clock) begin
        if (arvalid) begin
            if (araddr !== 32'h1000 + reads*4) $fatal(1, "read address");
            reads <= reads + 1;
            rvalid <= 1;
            rdata <= araddr ^ 32'ha5a5a5a5;
        end else if (rready) rvalid <= 0;
        if (awvalid && awaddr !== 32'h2000 + writes*4)
            $fatal(1, "write address");
        if (wvalid) begin
            if (wdata !== ((32'h1000 + writes*4) ^ 32'ha5a5a5a5))
                $fatal(1, "write data");
            writes <= writes + 1;
            bvalid <= 1;
        end else if (bready) bvalid <= 0;
    end
    task transfer(input [31:0] n);
        begin
            @(negedge clock); reads = 0; writes = 0; words = n; start = 1;
            // Includes the DONE -> IDLE restart handshake.
            repeat (3) @(negedge clock);
            start = 0;
            wait (done); #1;
            if (busy || reads != n || writes != n) $fatal(1, "length mismatch");
            repeat (4) @(negedge clock);
            if (reads != n || writes != n) $fatal(1, "extra AXI traffic");
        end
    endtask
    initial begin
        #12; reset_n = 1;
        transfer(0); transfer(1); transfer(5); transfer(0); transfer(2);
        $display("DMA RTL regression PASS"); $finish;
    end
    initial begin #10000; $fatal(1, "timeout"); end
endmodule
