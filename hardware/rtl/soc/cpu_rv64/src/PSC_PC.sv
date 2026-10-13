`timescale 1ns/1ps
// NISHIHARU

import PSC_Types::*;

module PSC_PC #(
    parameter int THREADS_NUM = 1
)(
    input  logic        clock,
    input  logic        reset_n,
    input  logic        cpu_stop,
    // Execute
    input  logic        execute_task_done,
    input  logic [63:0] alu_data,
    input  logic        pc_sel2,
    input  dec_ctrl_t   decoder_ctrl,
    // CPU state
    input  logic        cpu_trap,
    input  logic [1:0]  priv_mode,
    // Page fault
    input  logic        d_pf,
    input  logic        i_pf,
    // Trap cause
    input  logic [4:0]  trap_scause,
    // Precise machine timer interrupt acceptance pulse
    input  logic        timer_irq_take,
    // CSR
    input  csr_state_t  csr_state,

    // Current PC / cycle counter
    output logic [63:0] pc,
    output logic [63:0] counter
);

    // =====================================
    // Local constants
    // =====================================

    localparam logic [1:0] PRIV_M   = 2'b11;
    localparam logic [3:0] CPU_TRAP = 4'd2;

    // =====================================
    // NEXT PC
    // =====================================

    logic        exception;
    logic        interrupt;
    logic        trap;
    logic        trap_deleg_to_s;

    logic [63:0] trap_pc;
    logic [63:0] branch_target_pc;
    logic [63:0] seq_pc;
    logic [63:0] sret_pc;

    assign exception =
        decoder_ctrl.is_ecall |
        decoder_ctrl.is_ebreak |
        decoder_ctrl.raise_illegal_instruction |
        d_pf |
        i_pf;

    assign interrupt = timer_irq_take;

    assign trap = exception | interrupt;

    assign trap_deleg_to_s =
        (priv_mode != PRIV_M) &&
        (((csr_state.medeleg >> trap_scause) & 64'd1) != 64'd0);

    assign trap_pc =
        !interrupt && trap_deleg_to_s
            ? csr_state.stvec
            : csr_state.mtvec;

    assign branch_target_pc =
        {alu_data[63:1], 1'b0};

    assign seq_pc =
        pc + 64'd4;

    assign sret_pc =
        csr_state.sepc;

    // =====================================
    // NEXT PC SELECT
    // =====================================

    logic [63:0] next_pc;

    assign next_pc =
        decoder_ctrl.is_mret ? csr_state.mepc :
        decoder_ctrl.is_sret ? csr_state.sepc :
        trap                 ? trap_pc :
        pc_sel2              ? branch_target_pc :
                               seq_pc;

    // =====================================
    // PC WRITE BACK / CYCLE COUNTER
    // =====================================

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            pc      <= 64'd0;
            counter <= 64'd0;
        end else if (cpu_stop) begin
            pc      <= 64'd0;
            counter <= 64'd0;
        end else if (trap) begin
            pc      <= trap_pc;
            counter <= counter + 64'd1;
        end else if (execute_task_done) begin
            pc      <= next_pc;
            counter <= counter + 64'd1;
        end
    end

endmodule
