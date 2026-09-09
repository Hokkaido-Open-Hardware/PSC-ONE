`timescale 1ns/1ps

// ============================================================================
// PSC_NPU_Timing
//
// Timing-analysis wrapper for PSC_NPU_Controller.
//
// The wrapper supplies registered pseudo stimulus to the NPU so that Yosys
// cannot trivially constant-fold the controller, address-generation logic,
// read controller, systolic array, and writeback paths.
//
// This module is intended only for synthesis / place-and-route timing analysis.
// It is not a functional SDRAM/cache model.
// ============================================================================

module PSC_NPU_Timing (
    input  wire clock,
    input  wire reset_n,
    output reg  timing_keep
);

    // ------------------------------------------------------------------------
    // Pseudo stimulus generator
    //
    // A continuously changing register is used instead of constant inputs.
    // This keeps representative NPU control and datapath cones active during
    // synthesis while avoiding a large number of physical top-level I/O pins.
    // ------------------------------------------------------------------------
    (* keep = "true" *) reg [31:0] stimulus;

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            stimulus <= 32'h5A17_C0DE;
        else
            stimulus <= {
                stimulus[30:0],
                stimulus[31] ^ stimulus[21] ^ stimulus[1] ^ stimulus[0]
            };
    end

    // ------------------------------------------------------------------------
    // PSC_NPU_Controller input stimulus
    //
    // matrix_size_x/y are always non-zero multiples of four, matching the
    // runtime matrix-size contract of PSC_NPU_Controller.  The upper stimulus
    // bits vary the matrix size so address-generation logic is not reduced to
    // a single compile-time constant case.
    // ------------------------------------------------------------------------
    (* keep = "true" *) wire        signed_mode;
    (* keep = "true" *) wire        start;
    (* keep = "true" *) wire        sa_state_reset;
    (* keep = "true" *) wire [3:0]  sa_os_instruction;
    (* keep = "true" *) wire        sa_clear;

    (* keep = "true" *) wire [7:0]  matrix_size_x;
    (* keep = "true" *) wire [7:0]  matrix_size_y;

    (* keep = "true" *) wire [31:0] BASE_ADDR_A;
    (* keep = "true" *) wire [31:0] BASE_ADDR_B;
    (* keep = "true" *) wire [31:0] BASE_ADDR_C;

    (* keep = "true" *) wire        sa_req_ready;

    (* keep = "true" *) wire        rd_read_ready;
    (* keep = "true" *) wire [31:0] rd_read_data;
    (* keep = "true" *) wire        c_write_ready;

    assign signed_mode       = stimulus[2];
    assign start             = stimulus[3] & ~stimulus[4];
    assign sa_state_reset    = stimulus[5] & stimulus[6];
    assign sa_os_instruction = stimulus[10:7];
    assign sa_clear          = stimulus[11] & stimulus[12];

    // Generate 4, 8, 12, ... , 64.
    assign matrix_size_x = {2'b00, stimulus[16:13], 2'b00} + 8'd4;
    assign matrix_size_y = {2'b00, stimulus[20:17], 2'b00} + 8'd4;

    assign BASE_ADDR_A = 32'h0010_0000 ^ stimulus;
    assign BASE_ADDR_B = 32'h0020_0000 ^ {stimulus[15:0], stimulus[31:16]};
    assign BASE_ADDR_C = 32'h0030_0000 ^ {stimulus[7:0],
                                          stimulus[31:8]};

    assign sa_req_ready = stimulus[21];

    assign rd_read_ready = stimulus[22];
    assign rd_read_data  = stimulus ^ 32'hA5A5_5A5A;
    assign c_write_ready = stimulus[23];

    // ------------------------------------------------------------------------
    // PSC_NPU_Controller outputs
    //
    // keep attributes prevent the externally unconnected NPU result/control
    // cones from being discarded during standalone timing synthesis.
    // ------------------------------------------------------------------------
    (* keep = "true" *) wire [31:0] rd_read_addr;
    (* keep = "true" *) wire        rd_read_valid;

    (* keep = "true" *) wire        c_write_valid;
    (* keep = "true" *) wire [31:0] c_write_addr;
    (* keep = "true" *) wire [31:0] c_write_wdata;

    (* keep = "true" *) wire        busy;
    (* keep = "true" *) wire        done;

    // ------------------------------------------------------------------------
    // NPU under timing analysis
    //
    // The port map exactly follows PSC_NPU_Controller.v.
    // ------------------------------------------------------------------------
    PSC_NPU_Controller #(
        .PE_N     (4),
        .MATRIX_N (4),
        .MUL_NUM  (4)
    ) u_npu (
        .clock              (clock),
        .reset_n            (reset_n),
        .signed_mode        (signed_mode),

        .start              (start),
        .sa_state_reset     (sa_state_reset),
        .sa_os_instruction  (sa_os_instruction),
        .sa_clear           (sa_clear),

        .matrix_size_x      (matrix_size_x),
        .matrix_size_y      (matrix_size_y),

        .BASE_ADDR_A        (BASE_ADDR_A),
        .BASE_ADDR_B        (BASE_ADDR_B),
        .BASE_ADDR_C        (BASE_ADDR_C),

        .sa_req_ready       (sa_req_ready),

        .rd_read_addr       (rd_read_addr),
        .rd_read_valid      (rd_read_valid),
        .rd_read_ready      (rd_read_ready),
        .rd_read_data       (rd_read_data),

        .c_write_valid      (c_write_valid),
        .c_write_addr       (c_write_addr),
        .c_write_wdata      (c_write_wdata),
        .c_write_ready      (c_write_ready),

        .busy               (busy),
        .done               (done)
    );

    // ------------------------------------------------------------------------
    // Registered observation point
    //
    // Only representative output bits are folded into timing_keep.  Using a
    // full reduction XOR over every output bus would create an artificial
    // wrapper critical path unrelated to the NPU itself.
    // ------------------------------------------------------------------------
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            timing_keep <= 1'b0;
        else
            timing_keep <= busy
                         ^ done
                         ^ rd_read_valid
                         ^ rd_read_addr[0]
                         ^ rd_read_addr[15]
                         ^ c_write_valid
                         ^ c_write_addr[0]
                         ^ c_write_addr[15]
                         ^ c_write_wdata[0]
                         ^ c_write_wdata[15];
    end

endmodule