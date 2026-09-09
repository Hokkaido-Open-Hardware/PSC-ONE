`timescale 1ns/1ps
module tb;
    reg clock = 0;
    always #5 clock = ~clock;
    reg reset_n = 0, wvalid = 0;
    reg [31:0] wdata = 0;
    PSC_RV32IS_TIMER #(.CLK_FREQ_MHz(1)) dut (
        .clock(clock), .reset_n(reset_n),
        .cpu_wvalid(wvalid), .cpu_waddr(32'h10002000),
        .cpu_wdata(wdata), .cpu_wready(),
        .cpu_rvalid(1'b0), .cpu_raddr(32'b0),
        .cpu_rdata(), .cpu_rready(), .irq_tx()
    );
    task write_control(input [31:0] value);
        begin
            @(negedge clock); wdata = value; wvalid = 1;
            @(negedge clock); wvalid = 0;
            @(negedge clock);
        end
    endtask
    initial begin
        #12; reset_n = 1;
        write_control(32'h1000a);
        write_control(32'h10064);
        if (dut.counter !== 100) $fatal(1, "restart load lost");
        // Start must also win when the old one-shot counter expires.
        @(negedge clock);
        while (dut.counter != 1) @(negedge clock);
        wdata = 32'h10032; wvalid = 1;
        @(negedge clock); wvalid = 0;
        @(negedge clock);
        if (dut.counter !== 50 || !dut.running || dut.irq_pending)
            $fatal(1, "restart at expiry lost");
        // Normal countdown and one-shot expiry still work.
        wait (!dut.running);
        if (!dut.irq_pending) $fatal(1, "one-shot did not expire");
        write_control(32'h30003);
        repeat (4) @(negedge clock);
        if (!dut.running || dut.counter !== 3 || !dut.irq_pending)
            $fatal(1, "autoreload failed");
        $display("timer regression PASS");
        $finish;
    end
    initial begin #10000; $fatal(1, "timeout"); end
endmodule
