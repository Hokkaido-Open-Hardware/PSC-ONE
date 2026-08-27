// CPU_V2 physical register file.
// Parameterized entries x 32 bits, two asynchronous read ports and four WB ports.
// p0 is hard-wired to zero and is never allocated.
module PSC_Register #(
    parameter int ENTRIES = 64,
    parameter int TAG_W   = $clog2(ENTRIES)
)(
    input  logic             clock,
    input  logic             reset_n,
    input  logic             cpu_stop,

    input  logic [TAG_W-1:0] read_addr1,
    input  logic [TAG_W-1:0] read_addr2,
    output logic [31:0]      read_data1,
    output logic [31:0]      read_data2,
    output logic             read_ready1,
    output logic             read_ready2,

    input  logic             allocate_valid,
    input  logic [TAG_W-1:0] allocate_addr,
    input  logic             release_valid,
    input  logic [TAG_W-1:0] release_addr,

    input  logic             wb0_valid,
    input  logic [TAG_W-1:0] wb0_addr,
    input  logic [31:0]      wb0_data,
    input  logic             wb1_valid,
    input  logic [TAG_W-1:0] wb1_addr,
    input  logic [31:0]      wb1_data,
    input  logic             wb2_valid,
    input  logic [TAG_W-1:0] wb2_addr,
    input  logic [31:0]      wb2_data,
    input  logic             wb3_valid,
    input  logic [TAG_W-1:0] wb3_addr,
    input  logic [31:0]      wb3_data
);

    logic [31:0] registers [0:ENTRIES-1];
    logic        ready     [0:ENTRIES-1];

    always_comb begin
        read_data1  = (read_addr1 == '0) ? 32'd0 : registers[read_addr1];
        read_data2  = (read_addr2 == '0) ? 32'd0 : registers[read_addr2];
        read_ready1 = (read_addr1 < 32) ? 1'b1 : ready[read_addr1];
        read_ready2 = (read_addr2 < 32) ? 1'b1 : ready[read_addr2];
    end

    generate
        for (genvar entry = 1; entry < 32; entry = entry + 1) begin : g_arch_entry
            localparam logic [TAG_W-1:0] ENTRY_TAG = entry[TAG_W-1:0];
            wire wb3_hit = wb3_valid && (wb3_addr == ENTRY_TAG);

            always_ff @(posedge clock or negedge reset_n) begin
                if (!reset_n)
                    registers[entry] <= 32'd0;
                else if (cpu_stop)
                    registers[entry] <= 32'd0;
                else if (wb3_hit)
                    registers[entry] <= wb3_data;
            end
        end

        for (genvar entry = 32; entry < ENTRIES; entry = entry + 1) begin : g_spec_entry
            localparam logic [TAG_W-1:0] ENTRY_TAG = entry[TAG_W-1:0];
            wire wb0_hit = wb0_valid && (wb0_addr == ENTRY_TAG);
            wire wb1_hit = wb1_valid && (wb1_addr == ENTRY_TAG);
            wire wb2_hit = wb2_valid && (wb2_addr == ENTRY_TAG);
            wire allocate_hit = allocate_valid && (allocate_addr == ENTRY_TAG);
            wire release_hit = release_valid && (release_addr == ENTRY_TAG);

            always_ff @(posedge clock or negedge reset_n) begin
                if (!reset_n) begin
                    registers[entry] <= 32'd0;
                    ready[entry]     <= 1'b0;
                end else if (cpu_stop) begin
                    registers[entry] <= 32'd0;
                    ready[entry]     <= 1'b0;
                end else begin
                    if (wb2_hit)
                        registers[entry] <= wb2_data;
                    else if (wb1_hit)
                        registers[entry] <= wb1_data;
                    else if (wb0_hit)
                        registers[entry] <= wb0_data;

                    if (wb2_hit || wb1_hit || wb0_hit)
                        ready[entry] <= 1'b1;
                    else if (allocate_hit || release_hit)
                        ready[entry] <= 1'b0;
                end
            end
        end
    endgenerate

endmodule
