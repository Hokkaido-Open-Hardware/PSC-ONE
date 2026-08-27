// NISHIHARU
//
// PSC_CPU_TimingTop.sv
//
// nextpnr / Himbaechel timing-analysis wrapper for PSC_RV32ISP_core.
//
// Purpose:
//   - Keep the CPU core as the timing target.
//   - Avoid exposing the CPU's hundreds of memory/CSR signals as FPGA I/O.
//   - Give the CPU inputs registered, changing values so Yosys does not
//     constant-fold large portions of the core.
//   - Preserve the CPU instance and its interface nets during synthesis.
//
// Notes:
//   - This wrapper is for static timing comparison only.
//   - It is NOT a functional memory model and is NOT intended for simulation.
//   - Use exactly the same wrapper for CPU_V1 and CPU_V2 comparisons.
//   - Only clock/reset_n/timing_keep are top-level I/O, so the CST can be tiny.
//
// The PSC_RV32ISP_core interface used here matches the project source:
// clock/reset/cpu_stop/irq_ext, program/data/MMU memory ports,
// cache/DMA/SynapEngine/monitor CSR ports, and uart_out.

`timescale 1ns / 1ps

module PSC_CPU_TimingTop (
    input  logic clock,
    input  logic reset_n,
    output logic timing_keep
);

    // ------------------------------------------------------------------------
    // Registered pseudo stimulus
    //
    // Do not tie the CPU input buses to constants.  Constant inputs can cause
    // Yosys to simplify paths that exist in the real SoC and make the timing
    // comparison misleading.
    // ------------------------------------------------------------------------
    (* keep = "true" *) logic [31:0] stimulus;

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            stimulus <= 32'h1ACE_B00C;
        else
            stimulus <= {
                stimulus[30:0],
                stimulus[31] ^ stimulus[21] ^ stimulus[1] ^ stimulus[0]
            };
    end

    // ------------------------------------------------------------------------
    // CPU input-side signals
    // ------------------------------------------------------------------------
    (* keep = "true" *) logic        cpu_stop;
    (* keep = "true" *) logic        irq_ext;

    (* keep = "true" *) logic        program_mem_read_ready;
    (* keep = "true" *) logic [31:0] program_mem_read_data;
    (* keep = "true" *) logic        program_mem_req_ready;

    (* keep = "true" *) logic        data_mem_read_ready;
    (* keep = "true" *) logic [31:0] data_mem_read_data;
    (* keep = "true" *) logic        data_mem_req_ready;
    (* keep = "true" *) logic        data_mem_write_ready;

    (* keep = "true" *) logic        mmu_data_mem_read_ready;
    (* keep = "true" *) logic [31:0] mmu_data_mem_read_data;
    (* keep = "true" *) logic        mmu_data_req_ready;

    (* keep = "true" *) logic [31:0] csr_DMA_STATUS;
    (* keep = "true" *) logic [31:0] csr_SA_STATUS;
    (* keep = "true" *) logic [31:0] csr_CPU_MON_CYCLE;

    // Registered/stable-enough pseudo environment.
    // cpu_stop remains deasserted so the main CPU datapath is not disabled.
    assign cpu_stop                  = 1'b0;
    assign irq_ext                   = stimulus[0];

    assign program_mem_read_ready    = stimulus[1];
    assign program_mem_read_data     = stimulus ^ 32'h1357_9BDF;
    assign program_mem_req_ready     = stimulus[2];

    assign data_mem_read_ready       = stimulus[3];
    assign data_mem_read_data        = {stimulus[15:0], stimulus[31:16]};
    assign data_mem_req_ready        = stimulus[4];
    assign data_mem_write_ready      = stimulus[5];

    assign mmu_data_mem_read_ready   = stimulus[6];
    assign mmu_data_mem_read_data    = ~stimulus;
    assign mmu_data_req_ready        = stimulus[7];

    assign csr_DMA_STATUS            = stimulus ^ 32'h2468_ACE0;
    assign csr_SA_STATUS             = {stimulus[7:0], stimulus[31:8]};
    assign csr_CPU_MON_CYCLE         = stimulus;

    // ------------------------------------------------------------------------
    // CPU output-side signals
    //
    // Keep these nets so synthesis does not delete the logic cones simply
    // because this timing wrapper has very few physical outputs.
    // ------------------------------------------------------------------------
    (* keep = "true" *) logic        program_mem_burst_mode;
    (* keep = "true" *) logic        program_mem_read_valid;
    (* keep = "true" *) logic [31:0] program_mem_read_address;

    (* keep = "true" *) logic        data_mem_read_valid;
    (* keep = "true" *) logic [31:0] data_mem_read_address;

    (* keep = "true" *) logic        data_mem_write_valid;
    (* keep = "true" *) logic [2:0]  mem_write_sel;
    (* keep = "true" *) logic [31:0] mem_write_address;
    (* keep = "true" *) logic [31:0] mem_write_data;

    (* keep = "true" *) logic        mmu_data_mem_read_valid;
    (* keep = "true" *) logic [31:0] mmu_data_mem_read_address;

    (* keep = "true" *) logic        is_fence_i;

    (* keep = "true" *) logic [31:0] csr_DCACHE_CTRL;

    (* keep = "true" *) logic [31:0] csr_DMA_CTRL;
    (* keep = "true" *) logic [31:0] csr_DMA_WORDS;
    (* keep = "true" *) logic [31:0] csr_DMA_SRC;
    (* keep = "true" *) logic [31:0] csr_DMA_DST;

    (* keep = "true" *) logic [31:0] csr_SA_CTRL;
    (* keep = "true" *) logic [31:0] csr_SA_MODE;
    (* keep = "true" *) logic [31:0] csr_SA_ADDR_A;
    (* keep = "true" *) logic [31:0] csr_SA_ADDR_B;
    (* keep = "true" *) logic [31:0] csr_SA_ADDR_C;

    (* keep = "true" *) logic [31:0] csr_CPU_MON_CTRL;
    (* keep = "true" *) logic [8:0]  uart_out;

    // ------------------------------------------------------------------------
    // CPU under timing analysis
    // ------------------------------------------------------------------------
    PSC_RV32ISP_core u_cpu (
        .clock                      (clock),
        .reset_n                    (reset_n),
        .cpu_stop                   (cpu_stop),
        .irq_ext                    (irq_ext),

        // Program memory
        .program_mem_burst_mode     (program_mem_burst_mode),
        .program_mem_read_valid     (program_mem_read_valid),
        .program_mem_read_ready     (program_mem_read_ready),
        .program_mem_read_address   (program_mem_read_address),
        .program_mem_read_data      (program_mem_read_data),
        .program_mem_req_ready      (program_mem_req_ready),

        // Data memory
        .data_mem_read_valid        (data_mem_read_valid),
        .data_mem_read_ready        (data_mem_read_ready),
        .data_mem_read_address      (data_mem_read_address),
        .data_mem_read_data         (data_mem_read_data),
        .data_mem_req_ready         (data_mem_req_ready),

        .data_mem_write_valid       (data_mem_write_valid),
        .data_mem_write_ready       (data_mem_write_ready),
        .mem_write_sel              (mem_write_sel),
        .mem_write_address          (mem_write_address),
        .mem_write_data             (mem_write_data),

        // MMU
        .mmu_data_mem_read_valid    (mmu_data_mem_read_valid),
        .mmu_data_mem_read_ready    (mmu_data_mem_read_ready),
        .mmu_data_mem_read_address  (mmu_data_mem_read_address),
        .mmu_data_mem_read_data     (mmu_data_mem_read_data),
        .mmu_data_req_ready         (mmu_data_req_ready),

        // Cache
        .is_fence_i                 (is_fence_i),
        .csr_DCACHE_CTRL            (csr_DCACHE_CTRL),

        // DMA
        .csr_DMA_CTRL               (csr_DMA_CTRL),
        .csr_DMA_WORDS              (csr_DMA_WORDS),
        .csr_DMA_SRC                (csr_DMA_SRC),
        .csr_DMA_DST                (csr_DMA_DST),
        .csr_DMA_STATUS             (csr_DMA_STATUS),

        // SynapEngine
        .csr_SA_CTRL                (csr_SA_CTRL),
        .csr_SA_MODE                (csr_SA_MODE),
        .csr_SA_STATUS              (csr_SA_STATUS),
        .csr_SA_ADDR_A              (csr_SA_ADDR_A),
        .csr_SA_ADDR_B              (csr_SA_ADDR_B),
        .csr_SA_ADDR_C              (csr_SA_ADDR_C),

        // CPU Monitor
        .csr_CPU_MON_CTRL           (csr_CPU_MON_CTRL),
        .csr_CPU_MON_CYCLE          (csr_CPU_MON_CYCLE),

        .uart_out                   (uart_out)
    );

    // ------------------------------------------------------------------------
    // Small registered observation point.
    //
    // The large CPU output buses are not reduced through one huge XOR tree;
    // doing that would create an artificial wrapper critical path.
    // A few representative bits are enough for a physical output while the
    // keep attributes preserve the complete CPU instance/interface.
    // ------------------------------------------------------------------------
    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            timing_keep <= 1'b0;
        else
            timing_keep <= program_mem_read_valid ^
                           data_mem_read_valid ^
                           data_mem_write_valid ^
                           mmu_data_mem_read_valid ^
                           uart_out[0] ^
                           csr_SA_CTRL[0];
    end

endmodule
