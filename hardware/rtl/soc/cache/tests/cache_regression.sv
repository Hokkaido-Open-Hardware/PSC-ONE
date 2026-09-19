`timescale 1ns/1ps

// Transaction scoreboard independent of controller state encoding/timing.
module cache_regression;
    parameter integer TAGLSB = 6;
    parameter integer STALL  = 1;
    localparam integer DEPTH = 1 << (TAGLSB - 5);
    reg clock                = 0;
    always #5 clock = !clock;
    reg reset_n              = 0;
    reg cpu_valid            = 0, cpu_rw = 0, burst_mode = 0, cpu_cache_clear = 0;
    reg [31:0] cpu_addr      = 0, cpu_data = 0;
    wire cpu_ready, cpu_req_ready, mem_valid, mem_rw, cache_hit_pulse, cache_miss_pulse;
    wire [31:0] cpu_data_out, mem_addr;
    wire [255:0] mem_data_out;
    reg mem_ready            = 0, mem_req_ready = 0;
    reg [255:0] mem_data_in  = 0;
    cache_dma_controller #(.TAGLSB(TAGLSB)) dut (.*);

    reg [255:0] memory [0:8191];
    reg [255:0] model_data [0:DEPTH-1];
    integer model_tag [0:DEPTH-1];
    reg model_valid [0:DEPTH-1], model_dirty [0:DEPTH-1];
    reg [31:0] expected_addr [0:1];
    reg expected_rw [0:1];
    reg [255:0] expected_data [0:1];
    integer expected_count = 0, seen_count = 0;
    integer ticks          = 0, delay_left = 0, hits = 0, misses = 0, transactions = 0;
    integer pending_line   = 0;
    reg pending              = 0, pending_rw = 0;
    reg [255:0] pending_data = 0;
    reg [31:0] rng           = 32'h13579bdf;
    integer i, wait_count;

    // Inputs change on falling edges; output requests are sampled after NBA.
    always @(negedge clock) begin
        ticks                           = ticks + 1;
        mem_ready                       = 0;
        mem_req_ready                   = !pending && (!STALL || (ticks % 7 >= 3));
        if (pending) begin
            if (delay_left == 0) begin
                if (pending_rw)
                    memory[pending_line] = pending_data;
                mem_data_in                   = memory[pending_line];
                mem_ready                     = 1;
                pending                       = 0;
            end else
                delay_left                    = delay_left - 1;
        end
    end
    always @(posedge clock) begin
        #1;
        if (reset_n) begin
            if (cache_hit_pulse) hits = hits + 1;
            if (cache_miss_pulse) misses = misses + 1;
            if (mem_valid) begin
                if (!mem_req_ready) $fatal(1, "request issued while memory was not ready");
                if (pending || seen_count >= expected_count)
                    $fatal(1, "unexpected/duplicate memory request");
                if (mem_addr !== expected_addr[seen_count] || mem_rw !== expected_rw[seen_count])
                    $fatal(1, "memory request mismatch: got %h/%b expected %h/%b",
                        mem_addr, mem_rw, expected_addr[seen_count], expected_rw[seen_count]);
                if (mem_rw && mem_data_out !== expected_data[seen_count])
                    $fatal(1, "dirty writeback data mismatch");
                seen_count                    = seen_count + 1;
                pending                       = 1;
                pending_line                  = mem_addr >> 5;
                pending_rw                    = mem_rw;
                pending_data                  = mem_data_out;
                delay_left                    = STALL ? ticks % 5 : 2;
            end
        end
    end

    task invalidate_model;
        integer k;
        begin
            for (k = 0; k < DEPTH; k = k + 1) begin
                model_valid[k]                = 0;
                model_dirty[k]                = 0;
            end
        end
    endtask

    task clear_cache;
        begin
            @(negedge clock); #2; cpu_cache_clear = 1;
            repeat (DEPTH + 6) @(negedge clock);
            #2; cpu_cache_clear = 0;
            invalidate_model();
            repeat (2) @(negedge clock);
            if (!cpu_req_ready) $fatal(1, "clear did not complete");
        end
    endtask

    task access_cache(input reg wr, input integer addr, input reg [31:0] data,
                      input reg burst, input reg clear_busy, input reg report_latency);
        integer index, tag, line, word_sel, count, cycle, start_tick, first_tick;
        integer old_hits, old_misses;
        reg hit, dirty;
        reg [255:0] expected_line;
        begin
            index                                 = (addr >> 5) % DEPTH;
            tag                                   = addr >> TAGLSB;
            line                                  = addr >> 5;
            word_sel                              = (addr >> 2) % 8;
            hit                                   = model_valid[index] && model_tag[index] == tag;
            dirty                                 = model_valid[index] && model_dirty[index];
            expected_count                        = 0;
            seen_count                            = 0;
            if (!hit && dirty) begin
                expected_addr[expected_count] = (model_tag[index] << TAGLSB) | (index << 5);
                expected_rw[expected_count]   = 1;
                expected_data[expected_count] = model_data[index];
                expected_count                = expected_count + 1;
            end
            if (!hit && !wr) begin
                expected_addr[expected_count] = addr & ~31;
                expected_rw[expected_count]   = 0;
                expected_count                = expected_count + 1;
            end
            expected_line                         = hit ? model_data[index] : (wr ? 256'b0 : memory[line]);
            if (wr) expected_line[word_sel*32 +: 32] = data;
            model_data[index]                     = expected_line;
            model_tag[index]                      = tag;
            model_valid[index]                    = 1;
            model_dirty[index]                    = wr || (hit && dirty);
            old_hits                              = hits;
            old_misses                            = misses;
            while (!cpu_req_ready) @(negedge clock);
            @(negedge clock); #2;
            cpu_addr                              = addr;
            cpu_rw                                = wr;
            cpu_data                              = data;
            burst_mode                            = burst;
            cpu_valid                             = 1;
            @(posedge clock); #2; start_tick      = ticks;
            @(negedge clock); #2;
            cpu_valid                             = 0;
            // Live bus changes must not alter the captured transaction.
            cpu_addr                              = ~addr;
            cpu_data                              = ~data;
            cpu_rw                                = !wr;
            burst_mode                            = !burst;
            cpu_cache_clear                       = clear_busy;
            count                                 = 0;
            first_tick                            = -1;
            cycle                                 = 0;
            while (count < ((!wr && burst) ? 8 : 1) && cycle < 200) begin
                @(posedge clock); #2;
                cycle                         = cycle + 1;
                if (cpu_ready) begin
                    if (first_tick < 0) first_tick = ticks;
                    if (!wr && cpu_data_out !== expected_line[(burst ? count : word_sel)*32 +: 32])
                        $fatal(1, "CPU data mismatch addr=%h beat=%0d got=%h expected=%h",
                            addr, count, cpu_data_out, expected_line[(burst ? count : word_sel)*32 +: 32]);
                    if (burst && !wr && ticks != first_tick + count)
                        $fatal(1, "burst response has a gap");
                    count                = count + 1;
                end
            end
            if (cycle >= 200 || seen_count != expected_count)
                $fatal(1, "transaction timeout/missing memory request");
            if (hits-old_hits != (hit ? 1 : 0) || misses-old_misses != (hit ? 0 : 1))
                $fatal(1, "hit/miss pulse count mismatch");
            if (report_latency)
                $display("LATENCY wr=%0d hit=%0d dirty=%0d burst=%0d first=%0d last=%0d",
                    wr, hit, dirty, burst, first_tick-start_tick, ticks-start_tick);
            if (clear_busy) begin
                repeat (DEPTH + 6) @(negedge clock);
                #2; cpu_cache_clear = 0;
                invalidate_model();
            end
            @(negedge clock); #2;
            transactions                          = transactions + 1;
        end
    endtask

    // The existing one-entry slot accepts a pulse while another request is
    // active. Check that shortening the FSM does not lose that queued pulse.
    task queued_requests(input reg first_write);
        integer n, k, old_hits;
        reg [31:0] expected_word [0:1];
        begin
            access_cache(0, 0, 0, 0, 0, 0);
            access_cache(0, 32, 0, 0, 0, 0);
            expected_word[0]                      = model_data[0][31:0];
            expected_word[1]                      = first_write ? 32'hface1234 : model_data[1][31:0];
            if (first_write) begin
                model_data[0][31:0]           = 32'hface1234;
                model_dirty[0]                = 1;
            end
            expected_count                        = 0;
            seen_count                            = 0;
            old_hits                              = hits;
            n                                     = 0;
            @(negedge clock); #2;
            cpu_addr                              = 0;
            cpu_rw                                = first_write;
            cpu_data                              = 32'hface1234;
            burst_mode                            = 0;
            cpu_valid                             = 1;
            for (k = 0; k < 30; k = k + 1) begin
                @(posedge clock); #2;
                if (cpu_ready) begin
                    if (n >= 2 || (!(first_write && n == 0) && cpu_data_out !== expected_word[n]))
                        $fatal(1, "queued response mismatch/duplicate");
                    n                    = n + 1;
                end
                @(negedge clock); #2;
                cpu_valid                     = (k == 1);
                cpu_addr                      = first_write ? 0 : 32;
                cpu_rw                        = 0;
            end
            if (n != 2 || hits-old_hits != 2) $fatal(1, "queued request lost");
            transactions                          = transactions + 2;
        end
    endtask

    initial begin
        for (i = 0; i < 8192; i = i + 1)
            memory[i]                             = {32'h76540000 ^ i, 32'h89ab0000 ^ i, 32'h43210000 ^ i, 32'hba980000 ^ i, 32'h12340000 ^ i, 32'habcd0000 ^ i, 32'h87650000 ^ i, 32'hfedc0000 ^ i};
        invalidate_model();
        repeat (3) @(negedge clock);
        #2; reset_n = 1;
        repeat (DEPTH + 4) @(negedge clock);
        access_cache(0, 0, 0, 0, 0, 1);                  // clean read miss
        access_cache(0, 4, 0, 0, 0, 1);                  // read hit
        access_cache(1, 8, 32'hcafebabe, 0, 0, 1);      // write hit
        access_cache(0, 12, 0, 1, 0, 1);                 // burst always starts at word 0
        access_cache(0, 1 << TAGLSB, 0, 0, 0, 1);       // dirty read miss
        access_cache(1, 0, 32'h11223344, 0, 0, 1);      // clean write miss
        access_cache(1, 1 << TAGLSB, 32'hdeadbeef, 0, 0, 1); // dirty write miss
        access_cache(0, 1 << TAGLSB, 0, 1, 0, 0);       // zero-filled untouched words
        access_cache(0, 32, 0, 1, 0, 1);                 // burst clean miss
        access_cache(1, 32, 32'h55555555, 0, 0, 0);
        access_cache(0, (1 << TAGLSB) | 32, 0, 1, 0, 1); // burst dirty miss
        // Exercise every word, including the old 16-byte boundary.
        for (i = 0; i < 8; i = i + 1) begin
            access_cache(1, 32 + 4*i, 32'h10203040 ^ i, 0, 0, 0);
            access_cache(0, 32 + 4*i, 0, 0, 0, 0);
        end
        access_cache(0, (1 << TAGLSB) | 32, 0, 1, 0, 0);
        queued_requests(0);
        queued_requests(1);
        clear_cache();
        for (i = 0; i < 600; i = i + 1) begin
            rng                                   = (rng >> 1) ^ (32'hd0000001 & {32{rng[0]}});
            access_cache(rng[0], ((rng >> 5) % (DEPTH*16))*4, rng,
                         rng[1], i % 97 == 96, 0);
            if (i % 113 == 112) clear_cache();
        end
        // Queue a request during reset's INIT sweep. In particular, its tag
        // read must not steal the final invalidation write from the last index.
        access_cache(1, (DEPTH-1)*32, 32'hcafecafe, 0, 0, 0);
        @(negedge clock); #2; reset_n   = 0;
        repeat (3) @(negedge clock);
        #2; reset_n = 1;
        invalidate_model();
        expected_count                  = 1;
        seen_count                      = 0;
        expected_addr[0]                = 0;
        expected_rw[0]                  = 0;
        @(negedge clock); #2;
        cpu_valid                       = 1;
        cpu_addr                        = 0;
        cpu_rw                          = 0;
        burst_mode                      = 0;
        @(negedge clock); #2; cpu_valid = 0;
        wait_count                      = 0;
        while (!cpu_ready && wait_count < DEPTH+100) begin
            @(posedge clock); #2;
            wait_count                            = wait_count + 1;
        end
        if (!cpu_ready || cpu_data_out !== memory[0][31:0] || seen_count != 1)
            $fatal(1, "INIT queued request lost/corrupted");
        model_valid[0]                  = 1;
        model_tag[0]                    = 0;
        model_dirty[0]                  = 0;
        model_data[0]                   = memory[0];
        transactions                    = transactions + 1;
        @(negedge clock); #2;
        access_cache(0, (DEPTH-1)*32, 0, 1, 0, 0);
        $display("PASS cache_regression transactions=%0d TAGLSB=%0d STALL=%0d", transactions, TAGLSB, STALL);
        $finish;
    end
    initial begin
        #10000000;
        $fatal(1, "global timeout");
    end
endmodule
