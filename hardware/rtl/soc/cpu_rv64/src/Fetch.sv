`timescale 1ns/1ps
// RV64 addresses, 32-bit instructions (no compressed extension).
// Single request: one aligned 32-bit beat. Burst: eight 32-bit beats at
// the aligned 32-byte line. read_ready marks each response, not request acceptance.
module Fetch #(
    parameter logic BURST_MODE = 1'b0
)(
    input  logic        clock, reset_n, fetch_enb, mode_translate,
    input  logic [63:0] fetch_address,
    output logic        mmu_valid,
    input  logic        mmu_ready,
    output logic [63:0] vaddr,
    input  logic [63:0] paddr,
    output logic        program_mem_burst_mode, program_mem_read_valid,
    input  logic        program_mem_read_ready,
    output logic [63:0] program_mem_read_address,
    input  logic [31:0] program_mem_read_data,
    input  logic        program_mem_req_ready,
    output logic        fifo_read_valid,
    output logic [31:0] fifo_read_data,
    output logic [63:0] fifo_read_pc,
    output logic        done, busy,
    output logic [31:0] opcode
);
    typedef enum logic [2:0] {IDLE, TRANSLATE, REQUEST, RECEIVE, EMIT, FINISH} state_t;
    state_t state;
    logic [255:0] line_data;
    logic [2:0] beat;
    logic [2:0] word_index;
    logic [63:0] physical_address;
    assign program_mem_burst_mode = BURST_MODE;
    assign busy = state != IDLE;
    assign fifo_read_valid = state == EMIT;
    assign fifo_read_data = line_data[word_index*32 +: 32];
    assign fifo_read_pc = BURST_MODE
        ? {vaddr[63:5], word_index, 2'b0} : vaddr;
    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            mmu_valid <= 1'b0; program_mem_read_valid <= 1'b0;
            program_mem_read_address <= '0; physical_address <= '0;
            vaddr <= '0; line_data <= '0; beat <= '0; word_index <= '0;
            done <= 1'b0; opcode <= '0;
        end else begin
            mmu_valid <= 1'b0; program_mem_read_valid <= 1'b0; done <= 1'b0;
            case (state)
                IDLE: if (fetch_enb) begin
                    vaddr <= fetch_address;
                    physical_address <= fetch_address;
                    beat <= '0;
                    if (mode_translate) begin
                        mmu_valid <= 1'b1;
                        state <= TRANSLATE;
                    end else state <= REQUEST;
                end
                TRANSLATE: if (mmu_ready) begin
                    physical_address <= paddr;
                    state <= REQUEST;
                end
                REQUEST: if (program_mem_req_ready) begin
                    program_mem_read_address <= BURST_MODE
                        ? {physical_address[63:5], 5'b0}
                        : {physical_address[63:2], 2'b0};
                    program_mem_read_valid <= 1'b1;
                    state <= RECEIVE;
                end
                RECEIVE: if (program_mem_read_ready) begin
                    line_data[beat*32 +: 32] <= program_mem_read_data;
                    if (!BURST_MODE || beat == 7) begin
                        word_index <= BURST_MODE ? vaddr[4:2] : 3'b0;
                        state <= EMIT;
                    end else beat <= beat + 1'b1;
                end
                EMIT: begin
                    if ((!BURST_MODE) || (word_index == vaddr[4:2]))
                        opcode <= fifo_read_data;
                    if (!BURST_MODE || word_index == 7) state <= FINISH;
                    else word_index <= word_index + 1'b1;
                end
                FINISH: begin
                    done <= 1'b1;
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
