module PSC_RV32ISP_Monitor #(
    parameter CLK_FREQ_MHz = 80
)(
    input  wire         clock,
    input  wire         reset_n,

    // ---------------- CPU BUS ----------------
    input  wire [31:0]  PSC_CPU_MON_CTRL,
    output reg  [31:0]  PSC_CPU_MON_CYCLE,

    // ---------------- MONITOR ----------------
    input  wire         program_cache_hit_pulse,
    input  wire         program_cache_miss_pulse,
    input  wire         data_cache_hit_pulse,
    input  wire         data_cache_miss_pulse
);

    reg [31:0] program_cache_hit_count;
    reg [31:0] program_cache_miss_count;
    reg [31:0] data_cache_hit_count;
    reg [31:0] data_cache_miss_count;

    // ----------------------------------------------------
    // Counter
    // ----------------------------------------------------
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            program_cache_hit_count  <= 32'd0;
            program_cache_miss_count <= 32'd0;
            data_cache_hit_count     <= 32'd0;
            data_cache_miss_count    <= 32'd0;
        end
        else begin
            if (program_cache_hit_pulse)
                program_cache_hit_count <= program_cache_hit_count + 1'b1;

            if (program_cache_miss_pulse)
                program_cache_miss_count <= program_cache_miss_count + 1'b1;

            if (data_cache_hit_pulse)
                data_cache_hit_count <= data_cache_hit_count + 1'b1;

            if (data_cache_miss_pulse)
                data_cache_miss_count <= data_cache_miss_count + 1'b1;
        end
    end

    // ----------------------------------------------------
    // Read Mux
    // ----------------------------------------------------
    always @(*) begin
        case (PSC_CPU_MON_CTRL)
            32'd0: PSC_CPU_MON_CYCLE = program_cache_hit_count;
            32'd1: PSC_CPU_MON_CYCLE = program_cache_miss_count;
            32'd2: PSC_CPU_MON_CYCLE = data_cache_hit_count;
            32'd3: PSC_CPU_MON_CYCLE = data_cache_miss_count;
            default: PSC_CPU_MON_CYCLE = 32'd0;
        endcase
    end

endmodule