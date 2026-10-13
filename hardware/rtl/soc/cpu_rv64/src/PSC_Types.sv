`timescale 1ns/1ps
package PSC_Types;

    // Private ALU control; instruction encoding is checked in Decorder.
    localparam logic [4:0] ALU_CV_DOTUP_H = 5'b0_1000;
    localparam logic [4:0] ALU_CV_DOTSP_B = 5'b0_1001;

    // ============================================================
    // CSR wire
    // ============================================================

    typedef struct packed {
        logic [4:0]  r_addr1;
        logic [4:0]  r_addr2;
        logic [4:0]  w_addr;

        logic [63:0] imm;
        logic [4:0]  alucon;
        logic [2:0]  funct3;
        logic        op1sel;
        logic        op2sel;

        logic        mem_rw;
        logic        rf_wen;
        logic [1:0]  wb_sel;

        logic [1:0]  pc_sel;
        logic [63:0] out_pc;

        logic        is_fence;
        logic        is_fence_i;
        logic        is_sfence_vma;

        logic        csr_wr;
        logic [1:0]  csr_cmd;
        logic        csr_use_imm;
        logic [11:0] csr_addr;
        logic [4:0]  csr_zimm;

        logic        is_sret;
        logic        is_mret;
        logic        is_ecall;

        logic        is_load;
        logic        is_store;

        logic        use_rs1;
        logic        use_rs2;

        logic        is_R_type;
        logic        is_op_imm;
        logic        word_op;
        logic        is_ebreak;

        logic        pipeline_type;
        logic        raise_illegal_instruction;
    } dec_ctrl_t;

    // ============================================================
    // CSR wire
    // ============================================================

    typedef struct packed {
        // Mレベル
        logic [63:0] mstatus;
        logic [63:0] medeleg;
        logic [63:0] mie;
        logic [63:0] mip;
        logic [63:0] mtvec;
        logic [63:0] mepc;
        logic [63:0] mcause;

        // Sレベル
        logic [63:0] sstatus;
        logic [63:0] stvec;
        logic [63:0] sepc;
        logic [63:0] scause;
        logic [63:0] stval;
        logic [63:0] satp;
    } csr_state_t;

    // ============================================================
    // Instruction state
    // ============================================================

    typedef struct packed {
        // Instruction information
        logic        valid;
        logic [63:0] pc;
        logic [31:0] opcode;

        // Decoder result
        dec_ctrl_t   decoder_ctrl;

        // Register operands
        logic [63:0] reg_data_1;
        logic [63:0] reg_data_2;

        // Execute result
        logic [63:0] alu_data;
        logic [2:0]  alu_data_low3;

        // Branch / memory result
        logic        pc_sel2;
        logic [2:0]  ld_low3;
        logic [63:0] branch_rdata;

        // Write-back data
        logic [63:0] w_data;

        // Exception information
        logic        d_pf;
        logic        i_pf;
        logic [4:0]  trap_scause;
    } instruction_state_t;

endpackage
