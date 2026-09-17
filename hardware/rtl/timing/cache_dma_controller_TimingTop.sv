`timescale 1ns/1ps

// Standalone timing wrapper for cache_dma_controller.
// Wide DUT ports remain internal. Dynamic registered stimulus prevents
// excessive constant propagation; representative outputs are registered
// into one observable pin without creating a large artificial XOR tree.
module cache_dma_controller_TimingTop (
    input  wire clock,
    input  wire reset_n,
    output reg  timing_keep
);

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

    (* keep = "true" *) wire        cpu_valid;
    (* keep = "true" *) wire        cpu_rw;
    (* keep = "true" *) wire [31:0] cpu_addr;
    (* keep = "true" *) wire [31:0] cpu_data;
    (* keep = "true" *) wire        burst_mode;
    (* keep = "true" *) wire        cpu_cache_clear;

    assign cpu_valid       = stimulus[2] & ~stimulus[3];
    assign cpu_rw          = stimulus[4];
    assign cpu_addr        = 32'h0010_0000 ^ stimulus ^
                             {counter[15:0], counter[31:16]};
    assign cpu_data        = stimulus ^ counter ^ 32'hA5A5_5A5A;
    assign burst_mode      = stimulus[5];
    assign cpu_cache_clear = stimulus[6] & stimulus[7] & counter[8];

    (* keep = "true" *) wire         mem_ready;
    (* keep = "true" *) wire [255:0] mem_data_in;
    (* keep = "true" *) wire         mem_req_ready;

    assign mem_ready     = stimulus[8] | counter[1];
    assign mem_req_ready = stimulus[9] | counter[2];
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

    (* keep = "true" *) wire         cpu_ready;
    (* keep = "true" *) wire [31:0]  cpu_data_out;
    (* keep = "true" *) wire         cpu_req_ready;
    (* keep = "true" *) wire         mem_valid;
    (* keep = "true" *) wire         mem_rw;
    (* keep = "true" *) wire [31:0]  mem_addr;
    (* keep = "true" *) wire [255:0] mem_data_out;
    (* keep = "true" *) wire         cache_hit_pulse;
    (* keep = "true" *) wire         cache_miss_pulse;

    cache_dma_controller u_cache_dma_controller (
        .clock            (clock),
        .reset_n          (reset_n),

        .cpu_valid        (cpu_valid),
        .cpu_rw           (cpu_rw),
        .cpu_addr         (cpu_addr),
        .cpu_data         (cpu_data),
        .burst_mode       (burst_mode),
        .cpu_ready        (cpu_ready),
        .cpu_data_out     (cpu_data_out),
        .cpu_req_ready    (cpu_req_ready),
        .cpu_cache_clear  (cpu_cache_clear),

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

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            timing_keep <= 1'b0;
        else
            timing_keep <= cpu_ready
                         ^ cpu_req_ready
                         ^ cpu_data_out[0]
                         ^ cpu_data_out[15]
                         ^ cpu_data_out[31]
                         ^ mem_valid
                         ^ mem_rw
                         ^ mem_addr[0]
                         ^ mem_addr[15]
                         ^ mem_data_out[0]
                         ^ mem_data_out[63]
                         ^ mem_data_out[127]
                         ^ mem_data_out[191]
                         ^ mem_data_out[255]
                         ^ cache_hit_pulse
                         ^ cache_miss_pulse;
    end

endmodule
