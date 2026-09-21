`timescale 1ns/1ps
// Standalone transaction/latency regression, including the 2-line REG cache.
// Two backing-cache lines make exhaustive conflict/WB tests fast.
module cache_io_regression;
    reg clock = 0; always #5 clock = ~clock;
    reg reset_n = 0;
    reg cpu_rvalid = 0;
    reg cpu_wvalid = 0;
    reg cpu_rw = 0;
    reg [2:0] cpu_write_sel = 0;
    reg [31:0] cpu_raddr = 0;
    reg [31:0] cpu_waddr = 0;
    reg [31:0] cpu_data = 0;
    wire cpu_ready;
    wire [31:0] cpu_data_out;
    wire cpu_req_ready;
    reg cpu_cache_clear = 0;
    reg cpu_cache_wb = 0;
    reg sa_valid = 0;
    reg sa_rw = 0;
    reg [31:0] sa_addr = 0;
    reg [31:0] sa_data = 0;
    wire sa_ready;
    wire [31:0] sa_data_out;
    wire sa_req_ready;
    reg mmu_valid = 0;
    reg [31:0] mmu_addr = 0;
    wire mmu_ready;
    wire [31:0] mmu_data_out;
    wire mmu_req_ready;
    wire mmio_valid;
    wire mmio_rw;
    wire [31:0] mmio_addr;
    wire [31:0] mmio_wdata;
    reg mmio_ready = 0;
    reg [31:0] mmio_rdata = 0;
    reg mem_ready = 0;
    reg [255:0] mem_data_in = 0;
    reg mem_req_ready = 0;
    wire mem_valid;
    wire mem_rw;
    wire [31:0] mem_addr;
    wire [255:0] mem_data_out;
    wire cache_hit_pulse;
    wire cache_miss_pulse;
    cache_dma_controller_io #(.TAGLSB(6), .PROTECT_ADDR(32'h100),
        .PIO_ADDRESS(32'h10000001)) dut (.*);

    reg [255:0] memory [0:4095];
    reg [31:0] expected [0:16383];
    integer cycle = 0, pending = 0, mmio_pending = 0;
    integer reads = 0, writes = 0, mmios = 0;
    integer response_delay = 3;
    reg busy_rw;
    reg [31:0] busy_addr;
    reg [255:0] busy_data;
    reg req_ready_prev;
    reg [31:0] last_mmio_addr, last_mmio_data;
    reg last_mmio_rw;
    always @(posedge clock) begin
        cycle <= cycle + 1;
        req_ready_prev <= mem_req_ready;
        mem_ready <= 0;
        mmio_ready <= 0;
        if (!reset_n) begin
            pending <= 0;
            mmio_pending <= 0;
        end else begin
            if (mem_valid) begin
                if (pending != 0 || !req_ready_prev || mem_addr[4:0] != 0)
                    $fatal(1, "invalid external memory request");
                busy_rw <= mem_rw;
                busy_addr <= mem_addr;
                busy_data <= mem_data_out;
                pending <= response_delay;
                if (mem_rw) writes <= writes + 1;
                else reads <= reads + 1;
            end else if (pending > 0) begin
                pending <= pending - 1;
                if (pending == 1) begin
                    if (busy_rw) memory[busy_addr[15:5]] <= busy_data;
                    else mem_data_in <= memory[busy_addr[15:5]];
                    mem_ready <= 1;
                end
            end
            if (mmio_valid) begin
                if (mmio_pending != 0) $fatal(1, "duplicate MMIO request");
                mmio_pending <= 3;
                mmios <= mmios + 1;
                last_mmio_addr <= mmio_addr;
                last_mmio_data <= mmio_wdata;
                last_mmio_rw <= mmio_rw;
            end else if (mmio_pending > 0) begin
                mmio_pending <= mmio_pending - 1;
                if (mmio_pending == 1) begin
                    mmio_ready <= 1;
                    mmio_rdata <= 32'hcafe1234;
                end
            end
        end
    end

    task tick;
        begin @(posedge clock); #1; end
    endtask
    task idle;
        integer n;
        begin
            n=0;
            while (!cpu_req_ready) begin
                tick(); n=n+1;
                if (n > 2000) $fatal(1,"idle timeout");
            end
            @(negedge clock);
        end
    endtask
    integer latency;
    reg [31:0] returned;
    task transact(input integer port_id, input bit wr, input [31:0] addr,
                  input [2:0] size, input [31:0] data, input string label_text);
        integer start_cycle, n;
        begin
            idle();
            case(port_id)
                0: begin
                    cpu_rvalid=!wr; cpu_wvalid=wr; cpu_rw=wr;
                    cpu_raddr=addr; cpu_waddr=addr;
                    cpu_write_sel=size; cpu_data=data;
                end
                1: begin sa_valid=1; sa_rw=wr; sa_addr=addr; sa_data=data; end
                2: begin mmu_valid=1; mmu_addr=addr; end
            endcase
            tick(); start_cycle=cycle; // first rising edge sampling valid
            @(negedge clock);
            cpu_rvalid=0; cpu_wvalid=0; sa_valid=0; mmu_valid=0;
            // Poison live buses after acceptance: all lookup/response fields
            // must come from the request registers, including REG hits.
            cpu_raddr=~addr; cpu_waddr=~addr; sa_addr=~addr; mmu_addr=~addr;
            cpu_data=~data; sa_data=~data;
            n=0;
            while (!(port_id==0 ? cpu_ready : port_id==1 ? sa_ready : mmu_ready)) begin
                tick(); n=n+1;
                if(n>2000) $fatal(1,"response timeout %s",label_text);
            end
            latency=cycle-start_cycle;
            returned=port_id==0 ? cpu_data_out : port_id==1 ? sa_data_out : mmu_data_out;
            if (!wr && addr!=32'h10000001 && returned !== expected[addr[15:2]])
                $fatal(1,"read mismatch %s port=%0d addr=%h got=%h expected=%h",
                       label_text,port_id,addr,returned,expected[addr[15:2]]);
            if(wr && !(port_id==0 && addr<256) &&
               !(port_id==1 && addr<256 && !cache_hit_pulse) && addr!=32'h10000001) begin
                if(port_id==1 || size>1) expected[addr[15:2]]=data;
                else if(size==0) expected[addr[15:2]][addr[1:0]*8 +: 8]=data[7:0];
                else expected[addr[15:2]][addr[1]*16 +: 16]=data[15:0];
            end
            if(label_text!="") $display("LATENCY %s %0d",label_text,latency);
        end
    endtask
    task writeback(input string label_text);
        integer start_cycle, n;
        begin
            idle(); cpu_cache_wb=1; tick(); start_cycle=cycle;
            @(negedge clock); cpu_cache_wb=0;
            n=0;
            while(!cpu_ready) begin tick(); n=n+1; if(n>2000) $fatal(1,"WB timeout"); end
            $display("LATENCY %s %0d",label_text,cycle-start_cycle);
            for(integer i=0;i<16384;i=i+1)
                if(memory[i/8][(i%8)*32 +: 32] !== expected[i])
                    $fatal(1,"WB memory mismatch word=%0d",i);
        end
    endtask
    task clear_cache;
        begin
            idle(); cpu_cache_clear=1; tick();
            @(negedge clock); cpu_cache_clear=0;
            tick(); tick(); idle();
        end
    endtask
    // Every word and port must use the short path without a RAM lookup or
    // external request. Also check that exactly one response/hit is emitted.
    task reg_read(input integer port_id, input [31:0] addr);
        integer before_reads, before_writes, before_index;
        begin
            before_reads=reads; before_writes=writes; before_index=dut.cur_index_r;
            transact(port_id,0,addr,2,0,"");
            // latency is elapsed cycles after the accepting edge, hence 0
            // or 1 means a response within the allowed one or two request clocks.
            if(latency<0 || latency>1 || !cache_hit_pulse || cache_miss_pulse ||
               reads!=before_reads || writes!=before_writes || dut.cur_index_r!=before_index)
                $fatal(1,"REG hit protocol/latency addr=%h port=%0d latency=%0d",addr,port_id,latency);
            $display("REG_LATENCY port=%0d clocks=%0d",port_id,latency+1);
            tick();
            if(cpu_ready || sa_ready || mmu_ready || cache_hit_pulse)
                $fatal(1,"duplicate REG response");
        end
    endtask
    always @(posedge clock) begin
        if(reset_n && dut.line_cache_valid == 2'b11 &&
           dut.line_cache_addr[0] == dut.line_cache_addr[1])
            $fatal(1,"duplicate REG entries for the same line");
        if(reset_n && dut.line_cache_hit) begin
            if(dut.u_tag.index !== dut.cur_index_r || dut.u_data.index !== dut.cur_index_r || dut.tag_we || dut.data_we || mem_valid || mmio_valid)
                $fatal(1,"REG hit accessed backing cache/memory");
            if(dut.req_is_write || dut.line_cache_maintenance)
                $fatal(1,"REG hit bypassed store/maintenance");
        end
    end
    integer i,j,k,old_reads,old_writes,seen;
    reg [31:0] rng=32'h195ac742, a, d;
    initial begin
        for(i=0;i<16384;i=i+1) begin
            expected[i]=32'ha5000000 ^ (i*4);
            memory[i/8][(i%8)*32 +: 32]=expected[i];
        end
        repeat(3) tick();
        if(cpu_ready || sa_ready || mmu_ready || mem_valid || mmio_valid)
            $fatal(1,"reset output mismatch");
        @(negedge clock); reset_n=1; mem_req_ready=1;
        transact(0,0,'h1000,2,0,"CPU_read_clean_miss");
        for(j=0;j<3;j=j+1)
            for(k=0;k<8;k=k+1) reg_read(j,'h1000+4*k);
        // Both backing indices must coexist in REG and hit within two clocks of the sampling
        // edge for all words and ports, even when alternating lines.
        transact(0,0,'h1020,2,0,"");
        for(j=0;j<3;j=j+1)
            for(k=0;k<8;k=k+1) begin
                reg_read(j,'h1000+4*k);
                reg_read(j,'h1020+4*k);
            end
        // A conflicting backing-cache fill must invalidate A's REG copy,
        // but leave B available in REG. Reading A again must access memory.
        old_reads=reads;
        transact(0,0,'h1040,2,0,"REG_backing_index_conflict");
        if(reads!=old_reads+1) $fatal(1,"conflict did not fill from memory");
        reg_read(0,'h1020);
        old_reads=reads;
        transact(0,0,'h1000,2,0,"REG_after_backing_eviction");
        if(reads!=old_reads+1) $fatal(1,"evicted line survived in REG");
        reg_read(0,'h1020);
        reg_read(0,'h1000);
        // A store invalidates both copies. Read hits on both backing lines
        // must repopulate the REG entries without external memory traffic.
        transact(0,1,'h1004,2,expected['h1004/4],"");
        if(dut.line_cache_valid) $fatal(1,"store did not invalidate both REG lines");
        transact(0,0,'h1020,2,0,"");
        old_reads=reads;
        transact(0,0,'h1000,2,0,"CPU_backing_read_hit");
        if(latency!=4 || reads!=old_reads) $fatal(1,"backing hit did not use RAM");
        reg_read(0,'h101c);
        // Restore the original cold/hot sequence below after the added checks.
        clear_cache();
        transact(0,0,'h1000,2,0,"");
        transact(0,0,'h1000,2,0,"CPU_read_hit");
        transact(0,1,'h1004,2,32'h12345678,"CPU_write_hit");
        transact(0,0,'h1040,2,0,"CPU_read_dirty_miss");
        transact(0,1,'h1080,0,32'hab,"CPU_write_clean_miss");
        transact(0,1,'h10c0,1,32'hcdef,"CPU_write_dirty_miss");
        transact(1,0,'h1010,2,0,"SA_read_clean_miss");
        transact(1,0,'h1014,2,0,"SA_read_hit");
        transact(1,1,'h1018,2,32'habcdef01,"SA_write_hit");
        transact(2,0,'h1020,2,0,"MMU_read_clean_miss");
        transact(2,0,'h1024,2,0,"MMU_read_hit");
        transact(0,0,32'h10000001,2,0,"MMIO_read");
        if(returned!==32'hcafe1234 || last_mmio_rw || last_mmio_addr!==32'h10000001)
            $fatal(1,"MMIO read mismatch");
        transact(0,1,32'h10000001,0,32'h1234abcd,"MMIO_write");
        if(!last_mmio_rw || last_mmio_data!==32'h1234abcd || mmios!=2)
            $fatal(1,"MMIO write mismatch");
        old_reads=reads; old_writes=writes;
        transact(0,1,0,2,32'h11111111,"CPU_protected_write");
        if(reads!=old_reads || writes!=old_writes) $fatal(1,"protected write issued memory request");
        // Preserve the existing asymmetric SA protection rule: a protected
        // miss is ignored, but an SA write hit updates the cached line.
        transact(1,1,0,2,32'h11223344,"SA_protected_miss");
        transact(0,0,0,2,0,"");
        transact(1,1,0,2,32'h55667788,"SA_protected_hit");
        transact(2,0,0,2,0,"");
        writeback("WB_protected_SA_hit");
        // All size encodings and byte offsets, on both hits and misses.
        for(i=0;i<8;i=i+1) begin
            for(j=0;j<32;j=j+1) begin
                a='h2000+(j*64)+j;
                transact(0,1,a,i,32'h89abcdef ^ j,"");
                transact(0,0,a,2,0,"");
                transact(0,1,a,i,32'h76543210 ^ j,"");
                transact(0,0,a,2,0,"");
            end
        end
        writeback("WB_dirty_sweep");
        old_writes=writes;
        writeback("WB_clean_sweep");
        if(writes!=old_writes) $fatal(1,"clean WB issued write");
        clear_cache();
        old_reads=reads;
        transact(0,0,a,2,0,"CPU_after_clear");
        if(reads!=old_reads+1) $fatal(1,"clear did not invalidate");
        // Arbitration: one pending request per port, same assertion edge.
        idle();
        cpu_rvalid=1; cpu_rw=0; cpu_raddr='h3000;
        sa_valid=1; sa_rw=0; sa_addr='h3010;
        mmu_valid=1; mmu_addr='h3020;
        tick(); @(negedge clock); cpu_rvalid=0; sa_valid=0; mmu_valid=0;
        seen=0; k=0;
        while(seen<3) begin
            tick(); k=k+1;
            if(k>1000) $fatal(1,"arbitration timeout");
            if(mmu_ready) begin
                if(seen!=0 || mmu_data_out!==expected['h3020/4]) $fatal(1,"MMU arbitration");
                seen=seen+1;
            end
            if(sa_ready) begin
                if(seen!=1 || sa_data_out!==expected['h3010/4]) $fatal(1,"SA arbitration");
                seen=seen+1;
            end
            if(cpu_ready) begin
                if(seen!=2 || cpu_data_out!==expected['h3000/4]) $fatal(1,"CPU arbitration");
                seen=seen+1;
            end
        end
        // Hold off memory requests across lookup and dirty eviction.
        idle(); mem_req_ready=0;
        fork
            begin repeat(20) tick(); @(negedge clock); mem_req_ready=1; end
            transact(0,1,'h4000,2,32'h8899aabb,"CPU_stalled_clean_miss");
        join
        idle(); mem_req_ready=0;
        fork
            begin repeat(20) tick(); @(negedge clock); mem_req_ready=1; end
            transact(0,0,'h4040,2,0,"CPU_stalled_dirty_miss");
        join
        for(i=0;i<300;i=i+1) begin
            rng=rng ^ (rng<<13); rng=rng ^ (rng>>17); rng=rng ^ (rng<<5);
            a='h5000+{22'b0,rng[9:0]}; d=rng ^ 32'hc39ab6f1;
            response_delay=1+(rng[15:12]%7);
            transact(rng[18:16]%3,(rng[18:16]%3!=2)&&rng[20],a,rng[23:21],d,"");
        end
        writeback("WB_random_sweep");
        clear_cache();
        for(i=0;i<256;i=i+1) transact(2,0,'h5000+4*i,2,0,"");
        // WB request backpressure: dirty data and tag must remain stable
        // while the controller stays on the selected RAM index.
        transact(0,1,'h6000,2,32'hdecafbad,"");
        idle(); mem_req_ready=0;
        fork
            begin repeat(30) tick(); @(negedge clock); mem_req_ready=1; end
            writeback("WB_stalled_sweep");
        join
        // A warm CPU read competing with an SA write must see the store.
        transact(0,0,'h6000,2,0,"");
        reg_read(0,'h6000);
        idle();
        cpu_rvalid=1; cpu_rw=0; cpu_raddr='h6000;
        sa_valid=1; sa_rw=1; sa_addr='h6000; sa_data=32'h55aa1234;
        tick(); @(negedge clock); cpu_rvalid=0; sa_valid=0;
        seen=0; k=0;
        while(seen<2) begin
            tick(); k=k+1;
            if(k>1000) $fatal(1,"SA store arbitration timeout");
            if(sa_ready) begin
                if(seen!=0 || dut.line_cache_valid) $fatal(1,"SA store did not invalidate REG line");
                expected['h6000/4]=32'h55aa1234; seen=1;
            end
            if(cpu_ready) begin
                if(seen!=1 || cpu_data_out!==expected['h6000/4])
                    $fatal(1,"CPU returned stale data after competing SA store");
                seen=2;
            end
        end
        reg_read(2,'h6000);
        // WB drops even a valid REG copy. External DMA then changes RAM;
        // the existing WB-before-DMA / clear-after-DMA protocol must work.
        writeback("WB_REG_line");
        if(dut.line_cache_valid) $fatal(1,"WB did not invalidate REG line");
        transact(0,0,'h6000,2,0,"");
        reg_read(1,'h6000);
        memory['h6000/32][31:0]=32'hda7a1234;
        expected['h6000/4]=32'hda7a1234;
        clear_cache();
        old_reads=reads;
        transact(0,0,'h6000,2,0,"CPU_after_DMA_clear");
        if(reads!=old_reads+1) $fatal(1,"DMA clear returned stale REG line");
        reg_read(0,'h6000);

        // A clear requested during a fill must prevent revalidating the REG
        // copy, then invalidate the backing cache before the next access.
        response_delay=10;
        fork
            begin
                wait(pending>0);
                @(negedge clock); cpu_cache_clear=1;
                tick(); @(negedge clock); cpu_cache_clear=0;
            end
            transact(0,0,'h6080,2,0,"clear_during_fill");
        join
        if(dut.line_cache_valid) $fatal(1,"fill revalidated during pending clear");
        tick(); idle();
        old_reads=reads;
        transact(0,0,'h6080,2,0,"");
        if(reads!=old_reads+1) $fatal(1,"busy clear did not invalidate backing line");
        reg_read(0,'h6080);
        response_delay=3;

        // SA can cache this line, but a CPU MMIO address in the same line
        // must still go to the device rather than return the REG word.
        transact(1,0,32'h10000000,2,0,"");
        reg_read(1,32'h10000000);
        old_reads=mmios;
        transact(0,0,32'h10000001,2,0,"MMIO_with_REG_line_match");
        if(returned!==32'hcafe1234 || mmios!=old_reads+1 || cache_hit_pulse)
            $fatal(1,"REG cache bypassed MMIO");

        // All three live ports hit a warm line. Only the highest-priority
        // MMU read responds within two clocks; the other two requests must stay
        // queued and return once each in SA > CPU order.
        transact(0,0,'h6000,2,0,"");
        idle();
        cpu_rvalid=1; cpu_rw=0; cpu_raddr='h6004;
        sa_valid=1; sa_rw=0; sa_addr='h6008;
        mmu_valid=1; mmu_addr='h600c;
        tick();
        @(negedge clock); cpu_rvalid=0; sa_valid=0; mmu_valid=0;
        if(!mmu_ready) tick();
        if(!mmu_ready || cpu_ready || sa_ready || mmu_data_out!==expected['h600c/4] ||
           !cache_hit_pulse || !dut.cpu_req_slot_valid || !dut.sa_req_slot_valid ||
           dut.mmu_req_slot_valid)
            $fatal(1,"registered-hit MMU arbitration lost a request");
        @(negedge clock); cpu_rvalid=0; sa_valid=0; mmu_valid=0;
        seen=1; k=0;
        while(seen<3) begin
            tick(); k=k+1;
            if(k>1000) $fatal(1,"registered-hit arbitration timeout");
            if(mmu_ready) $fatal(1,"registered-hit MMU request was replayed");
            if(sa_ready) begin
                if(seen!=1 || sa_data_out!==expected['h6008/4])
                    $fatal(1,"registered-hit pending SA request mismatch");
                seen=2;
            end
            if(cpu_ready) begin
                if(seen!=2 || cpu_data_out!==expected['h6004/4])
                    $fatal(1,"registered-hit pending CPU request mismatch");
                seen=3;
            end
        end
        tick();
        if(cpu_ready || sa_ready || mmu_ready || cache_hit_pulse)
            $fatal(1,"registered-hit arbitration duplicated a response");

        // Reset after populated/dirty-cache activity invalidates all lines.
        @(negedge clock); reset_n=0; tick();
        if(cpu_ready || sa_ready || mmu_ready || mem_valid || mmio_valid ||
           cpu_data_out || sa_data_out || mmu_data_out)
            $fatal(1,"second reset output mismatch");
        @(negedge clock); reset_n=1;
        old_reads=reads;
        transact(0,0,'h6000,2,0,"CPU_after_reset");
        if(reads!=old_reads+1) $fatal(1,"reset did not invalidate");
        $display("PASS cache_io_regression reads=%0d writes=%0d mmios=%0d",reads,writes,mmios);
        $finish;
    end
    initial begin #1000000; $fatal(1,"global timeout"); end
endmodule
