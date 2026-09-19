`timescale 1ns/1ps

// ============================================================================
// cache_dma_controller_io_TimingTop
//
// Standalone timing-analysis wrapper for cache_dma_controller_io.
//
// Wide DUT interfaces are kept internal. Registered pseudo stimulus prevents
// Yosys from constant-folding representative cache/MMIO/memory control paths.
// Only a small registered observation point is exposed externally.
//
// This wrapper is for synthesis/place-and-route timing analysis only.
// It is not a functional memory/MMIO model.
// ============================================================================

module cache_dma_controller_io_TimingTop (
    input  wire clock,
    input  wire reset_n,
    output reg  timing_keep
);

    // ------------------------------------------------------------------------
    // Pseudo stimulus generator
    // ------------------------------------------------------------------------
    (* keep = "true" *) reg [31:0] stimulus;
    (* keep = "true" *) reg [31:0] counter;

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            stimulus <= 32'h5A17_C0DE;
            counter  <= 32'h0000_0000;
        end else begin
            stimulus <= {
                stimulus[30:0],
                stimulus[31] ^ stimulus[21] ^ stimulus[1] ^ stimulus[0]
            };
            counter <= counter + 32'd1;
        end
    end

    // ------------------------------------------------------------------------
    // CPU request stimulus
    // ------------------------------------------------------------------------
    (* keep = "true" *) wire        cpu_rvalid;
    (* keep = "true" *) wire        cpu_wvalid;
    (* keep = "true" *) wire        cpu_rw;
    (* keep = "true" *) wire [2:0]  cpu_write_sel;
    (* keep = "true" *) wire [31:0] cpu_raddr;
    (* keep = "true" *) wire [31:0] cpu_waddr;
    (* keep = "true" *) wire [31:0] cpu_data;
    (* keep = "true" *) wire        cpu_cache_clear;
    (* keep = "true" *) wire        cpu_cache_wb;

    assign cpu_rvalid      = stimulus[2] & ~stimulus[3];
    assign cpu_wvalid      = stimulus[3] & ~stimulus[2];
    assign cpu_rw          = stimulus[4];
    assign cpu_write_sel   = stimulus[7:5];
    assign cpu_raddr       = 32'h0010_0000 ^ stimulus ^ {counter[15:0], counter[31:16]};
    assign cpu_waddr       = 32'h0020_0000 ^ {stimulus[15:0], stimulus[31:16]} ^ counter;
    assign cpu_data        = stimulus ^ counter ^ 32'hA5A5_5A5A;
    assign cpu_cache_clear = stimulus[8] & stimulus[9] & counter[7];
    assign cpu_cache_wb    = stimulus[10] & stimulus[11] & counter[8];

    // ------------------------------------------------------------------------
    // SynapEngine request stimulus
    // ------------------------------------------------------------------------
    (* keep = "true" *) wire        sa_valid;
    (* keep = "true" *) wire        sa_rw;
    (* keep = "true" *) wire [31:0] sa_addr;
    (* keep = "true" *) wire [31:0] sa_data;

    assign sa_valid = stimulus[12] & ~stimulus[13];
    assign sa_rw    = stimulus[14];
    assign sa_addr  = 32'h0030_0000 ^ {stimulus[7:0], stimulus[31:8]} ^ counter;
    assign sa_data  = {stimulus[15:0], counter[15:0]};

    // ------------------------------------------------------------------------
    // MMU request stimulus
    // ------------------------------------------------------------------------
    (* keep = "true" *) wire        mmu_valid;
    (* keep = "true" *) wire [31:0] mmu_addr;

    assign mmu_valid = stimulus[15] & ~stimulus[16];
    assign mmu_addr  = 32'h0040_0000 ^ stimulus ^ {counter[7:0], counter[31:8]};

    // ------------------------------------------------------------------------
    // MMIO response stimulus
    // ------------------------------------------------------------------------
    (* keep = "true" *) wire        mmio_ready;
    (* keep = "true" *) wire [31:0] mmio_rdata;

    assign mmio_ready = stimulus[17] | counter[1];
    assign mmio_rdata = stimulus ^ {counter[15:0], counter[31:16]} ^ 32'h3C3C_C3C3;

    // ------------------------------------------------------------------------
    // External memory response stimulus
    // ------------------------------------------------------------------------
    (* keep = "true" *) wire         mem_ready;
    (* keep = "true" *) wire [255:0] mem_data_in;
    (* keep = "true" *) wire         mem_req_ready;

    assign mem_ready     = stimulus[18] | counter[2];
    assign mem_req_ready = stimulus[19] | counter[3];
    assign mem_data_in   = {
        stimulus - counter,
        stimulus ^ {counter[7:0], counter[31:8]},
        {counter[23:0], stimulus[7:0]},
        {stimulus[7:0], counter[31:8]},
        stimulus ^ counter,
        stimulus + counter,
        {stimulus[15:0], counter[15:0]},
        {counter[15:0], stimulus[15:0]}
    };

    // ------------------------------------------------------------------------
    // DUT outputs
    // ------------------------------------------------------------------------
    (* keep = "true" *) wire         cpu_ready;
    (* keep = "true" *) wire [31:0]  cpu_data_out;
    (* keep = "true" *) wire         cpu_req_ready;

    (* keep = "true" *) wire         sa_ready;
    (* keep = "true" *) wire [31:0]  sa_data_out;
    (* keep = "true" *) wire         sa_req_ready;

    (* keep = "true" *) wire         mmu_ready;
    (* keep = "true" *) wire [31:0]  mmu_data_out;
    (* keep = "true" *) wire         mmu_req_ready;

    (* keep = "true" *) wire         mmio_valid;
    (* keep = "true" *) wire         mmio_rw;
    (* keep = "true" *) wire [31:0]  mmio_addr;
    (* keep = "true" *) wire [31:0]  mmio_wdata;

    (* keep = "true" *) wire         mem_valid;
    (* keep = "true" *) wire         mem_rw;
    (* keep = "true" *) wire [31:0]  mem_addr;
    (* keep = "true" *) wire [255:0] mem_data_out;

    (* keep = "true" *) wire         cache_hit_pulse;
    (* keep = "true" *) wire         cache_miss_pulse;

    // ------------------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------------------
    cache_dma_controller_io u_cache_dma_controller_io (
        .clock            (clock),
        .reset_n          (reset_n),

        .cpu_rvalid       (cpu_rvalid),
        .cpu_wvalid       (cpu_wvalid),
        .cpu_rw           (cpu_rw),
        .cpu_write_sel    (cpu_write_sel),
        .cpu_raddr        (cpu_raddr),
        .cpu_waddr        (cpu_waddr),
        .cpu_data         (cpu_data),
        .cpu_ready        (cpu_ready),
        .cpu_data_out     (cpu_data_out),
        .cpu_req_ready    (cpu_req_ready),

        .cpu_cache_clear  (cpu_cache_clear),
        .cpu_cache_wb     (cpu_cache_wb),

        .sa_valid         (sa_valid),
        .sa_rw            (sa_rw),
        .sa_addr          (sa_addr),
        .sa_data          (sa_data),
        .sa_ready         (sa_ready),
        .sa_data_out      (sa_data_out),
        .sa_req_ready     (sa_req_ready),

        .mmu_valid        (mmu_valid),
        .mmu_addr         (mmu_addr),
        .mmu_ready        (mmu_ready),
        .mmu_data_out     (mmu_data_out),
        .mmu_req_ready    (mmu_req_ready),

        .mmio_valid       (mmio_valid),
        .mmio_rw          (mmio_rw),
        .mmio_addr        (mmio_addr),
        .mmio_wdata       (mmio_wdata),
        .mmio_ready       (mmio_ready),
        .mmio_rdata       (mmio_rdata),

        .mem_ready        (mem_ready),
        .mem_data_in      (mem_data_in),
        .mem_req_ready    (mem_req_ready),

        .mem_valid        (mem_valid),
        .mem_rw           (mem_rw),
        .mem_addr         (mem_addr),
        .mem_data_out     (mem_data_out),

        .cache_hit_pulse  (cache_hit_pulse),
        .cache_miss_pulse (cache_miss_pulse)
    );

    // ------------------------------------------------------------------------
    // Registered observation point
    //
    // Sample representative bits only. A reduction over all output bits would
    // create a large artificial XOR tree and could become the wrapper's
    // critical path instead of the cache controller's real path.
    // ------------------------------------------------------------------------
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            timing_keep <= 1'b0;
        else
            timing_keep <= cpu_ready
                         ^ cpu_req_ready
                         ^ cpu_data_out[0]
                         ^ cpu_data_out[15]
                         ^ sa_ready
                         ^ sa_req_ready
                         ^ sa_data_out[0]
                         ^ mmu_ready
                         ^ mmu_req_ready
                         ^ mmu_data_out[15]
                         ^ mmio_valid
                         ^ mmio_rw
                         ^ mmio_addr[0]
                         ^ mmio_wdata[15]
                         ^ mem_valid
                         ^ mem_rw
                         ^ mem_addr[4]
                         ^ mem_data_out[0]
                         ^ mem_data_out[63]
                         ^ mem_data_out[127]
                         ^ mem_data_out[191]
                         ^ mem_data_out[255]
                         ^ cache_hit_pulse
                         ^ cache_miss_pulse;
    end

endmodule
