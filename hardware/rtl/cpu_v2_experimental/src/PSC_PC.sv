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
    input  logic [31:0] alu_data,
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
    // CSR
    input  csr_state_t  csr_state,
    
    // Current PC / cycle counter
    output logic [31:0] pc,
    output logic [31:0] counter
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

    logic [31:0] trap_pc;
    logic [31:0] branch_target_pc;
    logic [31:0] seq_pc;
    logic [31:0] sret_pc;

    assign exception =
        decoder_ctrl.is_ecall |
        decoder_ctrl.raise_illegal_instruction |
        d_pf |
        i_pf;

    assign interrupt = 1'b0;

    assign trap = exception | interrupt;

    assign trap_deleg_to_s =
        (priv_mode != PRIV_M) &&
        (((csr_state.medeleg >> trap_scause) & 32'd1) != 32'd0);

    assign trap_pc =
        trap_deleg_to_s
            ? csr_state.stvec
            : csr_state.mtvec;

    assign branch_target_pc =
        {alu_data[31:1], 1'b0};

    assign seq_pc =
        pc + 32'd4;

    assign sret_pc =
        csr_state.sepc;

    // =====================================
    // TRAP PC LATCH
    // =====================================

    logic [31:0] trap_pc_latch;

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            trap_pc_latch <= 32'd0;
        end else if (cpu_stop) begin
            trap_pc_latch <= 32'd0;
        end else if (execute_task_done) begin
            trap_pc_latch <= 32'd0;
        end else if (trap) begin
            if (trap_deleg_to_s)
                trap_pc_latch <= csr_state.stvec;
            else
                trap_pc_latch <= csr_state.mtvec;
        end
    end

    // =====================================
    // NEXT PC SELECT
    // =====================================

    logic [31:0] next_pc;

    assign next_pc =
        decoder_ctrl.is_mret ? csr_state.mepc :
        decoder_ctrl.is_sret ? csr_state.sepc :
        trap                 ? trap_pc_latch :
        cpu_trap
                             ? trap_pc_latch :
        pc_sel2              ? branch_target_pc :
                               seq_pc;

    // =====================================
    // PC WRITE BACK / CYCLE COUNTER
    // =====================================

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            pc      <= 32'd0;
            counter <= 32'd0;
        end else if (cpu_stop) begin
            pc      <= 32'd0;
            counter <= 32'd0;
        end else if (execute_task_done) begin
            pc      <= next_pc;
            counter <= counter + 32'd1;
        end
    end

endmodule