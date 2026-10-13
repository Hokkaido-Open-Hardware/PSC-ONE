`timescale 1ns/1ps
// NISHIHARU

import PSC_Types::*;

module Decorder #(
    parameter bit ENABLE_PULP = 1'b0
)(
    input  logic        clock,
    input  logic        reset_n,
    input  logic        decode_enb,
    input  logic [31:0] opcode,
    input  logic [63:0] in_pc,
    input  logic [1:0]  current_priv,
    output logic        decode_done,

    output dec_ctrl_t   decoder_ctrl
);

    // Privilege level encoding (RISC-V spec)
    localparam [1:0] PRIV_U = 2'b00;
    localparam [1:0] PRIV_S = 2'b01;
    localparam [1:0] PRIV_M = 2'b11;

    // 内部配線（組合せ）
    wire [4:0]  r_addr1_w, r_addr2_w, w_addr_w;
    wire [63:0] imm_w;
    wire [4:0]  alucon_w;
    wire [2:0]  funct3_w;
    wire        op1sel_w, op2sel_w, mem_rw_w, rf_wen_w;
    wire [1:0]  wb_sel_w, pc_sel_w;

    wire [6:0]  op = opcode[6:0];

    // オプコード定数
    localparam [6:0] RFORMAT       = 7'b0110011;
    localparam [6:0] IFORMAT_ALU   = 7'b0010011;
    localparam [6:0] IFORMAT_LOAD  = 7'b0000011;
    localparam [6:0] SFORMAT       = 7'b0100011;
    localparam [6:0] SBFORMAT      = 7'b1100011;
    localparam [6:0] UFORMAT_LUI   = 7'b0110111;
    localparam [6:0] UFORMAT_AUIPC = 7'b0010111;
    localparam [6:0] UJFORMAT      = 7'b1101111;
    localparam [6:0] IFORMAT_JALR  = 7'b1100111;
    localparam [6:0] ECALLEBREAK   = 7'b1110011; // SYSTEM
    localparam [6:0] FENCE         = 7'b0001111;
    localparam [6:0] MULDIV        = 7'b0110011; // (未使用なら無視)

    localparam [6:0] RFORMAT_W = 7'b0111011;
    localparam [6:0] IFORMAT_W = 7'b0011011;
    wire is_reg_op = (op == RFORMAT) || (op == RFORMAT_W);
    wire is_imm_op = (op == IFORMAT_ALU) || (op == IFORMAT_W);
    wire word_op = (op == RFORMAT_W) || (op == IFORMAT_W);

    // RV32 PULP custom encodings are intentionally unsupported in this RV64 ISA.
    // Exact register/register forms only; all other custom-3 encodings trap.
    wire is_cv_dotup_h = 1'b0 && ((opcode & 32'hfe00_707f) == 32'h8000_007b);
    wire is_cv_dotsp_b = 1'b0 && ((opcode & 32'hfe00_707f) == 32'h9000_107b);
    wire is_pulp = is_cv_dotup_h || is_cv_dotsp_b;
    wire illegal_pulp = (op == 7'h7b) && !is_pulp;

    // ---- SYSTEM / CSR detection ----
    wire        is_sfence_vma_w =
                            is_system &&
                            (sys_f3 == 3'b000) &&
                            (opcode[31:25] == 7'b0001001);
    wire        is_system  = (op == ECALLEBREAK);
    wire [2:0]  sys_f3     = opcode[14:12];
    //wire        is_priv    = is_system && (sys_f3 == 3'b000); // ECALL/EBREAK/MRET/WFI
    wire        is_trap_like = is_system && (sys_f3 == 3'b000) && !is_sfence_vma_w;

    // ecall 判定
    wire        is_ecall_w = is_system &&
                             (sys_f3 == 3'b000) &&
                             (opcode[31:20] == 12'h000);

    // sret/mret 判定
    // instruction detect
    wire        is_sret_w = is_system &&
                            (sys_f3 == 3'b000) &&
                            (opcode[31:20] == 12'h102);

    wire        is_mret_w = is_system &&
                            (sys_f3 == 3'b000) &&
                            (opcode[31:20] == 12'h302);

    // illegal checks
    wire raise_illegal_instruction_sw =
                            is_sret_w && (current_priv != PRIV_S);

    wire raise_illegal_instruction_mw =
                            is_mret_w && (current_priv != PRIV_M);

    // ---- sfence.vma 判定 ----
    wire        is_fence_family = (opcode[6:0] == FENCE);

    // fence (funct3 = 000)
    wire        is_fence_w =    is_fence_family &&
                                (opcode[14:12] == 3'b000);

    // fence.i (funct3 = 001, rs1=0, rd=0)
    wire        is_fence_i_w =   is_fence_family &&
                                (opcode[14:12] == 3'b001) &&
                                (opcode[19:15] == 5'b00000) &&
                                (opcode[11:7]  == 5'b00000);

    // ---- CSR 判定 ----
    wire        is_csrrw   = is_system && (sys_f3 == 3'b001);
    wire        is_csrrs   = is_system && (sys_f3 == 3'b010);
    wire        is_csrrc   = is_system && (sys_f3 == 3'b011);
    wire        is_csrrwi  = is_system && (sys_f3 == 3'b101);
    wire        is_csrrsi  = is_system && (sys_f3 == 3'b110);
    wire        is_csrrci  = is_system && (sys_f3 == 3'b111);
    wire        is_csri    = is_csrrwi | is_csrrsi | is_csrrci;

    // CSR命令か？
    wire        is_csr_any = is_csrrw | is_csrrs | is_csrrc | is_csri;

    // funct3 → Csr.v のコマンド(0:RW,1:RS,2:RC) に正規化
    //   001/101 → RW(00), 010/110 → RS(01), 011/111 → RC(10)
    wire [1:0]  csr_cmd_norm =
                    (is_csrrw | is_csrrwi) ? 2'b00 :
                    (is_csrrs | is_csrrsi) ? 2'b01 :
                    (is_csrrc | is_csrrci) ? 2'b10 : 2'b00;

    wire [11:0] csr_addr_w = opcode[31:20];

    // ---- rs1/rs2/rd 選出（*I時はrs1未使用のため0固定）----
    assign r_addr1_w = (op == UFORMAT_LUI) ? 5'b0 :
                       (is_csri           ) ? 5'b0 : opcode[19:15];
    assign r_addr2_w = opcode[24:20];
    assign w_addr_w  = opcode[11:7];

    // ---- 即値生成 ----
    wire [63:0] imm_i;
    wire [63:0] imm_s;
    wire [63:0] imm_b;
    wire [63:0] imm_u;
    wire [63:0] imm_j;

    // I-type
    assign imm_i = {{52{opcode[31]}}, opcode[31:20]};

    // S-type
    assign imm_s = {{52{opcode[31]}}, opcode[31:25], opcode[11:7]};

    // B-type
    assign imm_b = {{51{opcode[31]}},
                    opcode[31],
                    opcode[7],
                    opcode[30:25],
                    opcode[11:8],
                    1'b0};

    // U-type
    assign imm_u = {{32{opcode[31]}}, opcode[31:12], 12'b0};

    // J-type (JAL)
    assign imm_j = {{43{opcode[31]}},
                    opcode[31],
                    opcode[19:12],
                    opcode[20],
                    opcode[30:21],
                    1'b0};

    // 最終 immediate
    assign imm_w =  (op == UJFORMAT) ? imm_j :
                    (op == SBFORMAT) ? imm_b :
                    (op == SFORMAT)  ? imm_s :
                    (is_imm_op || (op == IFORMAT_LOAD) || (op == IFORMAT_JALR)) ? imm_i :
                    ((op == UFORMAT_LUI) || (op == UFORMAT_AUIPC)) ? imm_u :
                    64'b0;

    // ---- ALU制御 ----
    wire is_mul;
    wire is_mulh;
    wire is_mulhsu;
    wire is_mulhu;
    wire is_div;
    wire is_divu;
    wire is_rem;
    wire is_remu;

    assign is_mul  = is_reg_op &&
                    (opcode[31:25] == 7'b0000001) &&
                    (opcode[14:12] == 3'b000);

    assign is_mulh =
                    is_reg_op &&
                    (opcode[31:25] == 7'b0000001) &&
                    (opcode[14:12] == 3'b001);

    assign is_mulhsu =
                    is_reg_op &&
                    (opcode[31:25] == 7'b0000001) &&
                    (opcode[14:12] == 3'b010);

    assign is_mulhu =
                    is_reg_op &&
                    (opcode[31:25] == 7'b0000001) &&
                    (opcode[14:12] == 3'b011);

    assign is_div  = is_reg_op &&
                    (opcode[31:25] == 7'b0000001) &&
                    (opcode[14:12] == 3'b100);

    assign is_divu = is_reg_op &&
                    (opcode[31:25] == 7'b0000001) &&
                    (opcode[14:12] == 3'b101);

    assign is_rem  = is_reg_op &&
                    (opcode[31:25] == 7'b0000001) &&
                    (opcode[14:12] == 3'b110);

    assign is_remu = is_reg_op &&
                    (opcode[31:25] == 7'b0000001) &&
                    (opcode[14:12] == 3'b111);

    // illegal checks
    logic legal_encoding;
    always_comb begin
        legal_encoding = 1'b0;
        case (op)
            RFORMAT: legal_encoding = (opcode[31:25] == 7'h00) ||
                (opcode[31:25] == 7'h01) ||
                ((opcode[31:25] == 7'h20) &&
                 ((opcode[14:12] == 0) || (opcode[14:12] == 5)));
            RFORMAT_W: legal_encoding =
                ((opcode[31:25] == 0) && ((opcode[14:12] == 0) ||
                  (opcode[14:12] == 1) || (opcode[14:12] == 5))) ||
                ((opcode[31:25] == 7'h20) && ((opcode[14:12] == 0) ||
                  (opcode[14:12] == 5))) ||
                ((opcode[31:25] == 1) && ((opcode[14:12] == 0) || opcode[14]));
            IFORMAT_ALU: legal_encoding =
                (opcode[14:12] == 1) ? (opcode[31:26] == 0) :
                (opcode[14:12] == 5) ? ((opcode[31:26] == 0) ||
                                               (opcode[31:26] == 6'h10)) : 1'b1;
            IFORMAT_W: legal_encoding = (opcode[14:12] == 0) ||
                ((opcode[14:12] == 1) && (opcode[31:25] == 0)) ||
                ((opcode[14:12] == 5) && ((opcode[31:25] == 0) ||
                                               (opcode[31:25] == 7'h20)));
            IFORMAT_LOAD: legal_encoding = opcode[14:12] != 7;
            SFORMAT: legal_encoding = opcode[14:12] <= 3;
            SBFORMAT: legal_encoding = (opcode[14:12] < 2) || opcode[14];
            UFORMAT_LUI, UFORMAT_AUIPC, UJFORMAT: legal_encoding = 1'b1;
            IFORMAT_JALR: legal_encoding = opcode[14:12] == 0;
            FENCE: legal_encoding = is_fence_w || is_fence_i_w;
            ECALLEBREAK: legal_encoding = is_csr_any ||
                (opcode == 32'h00000073) || (opcode == 32'h00100073) ||
                (opcode == 32'h10200073) || (opcode == 32'h30200073) ||
                (opcode == 32'h10500073) ||
                (is_sfence_vma_w && opcode[11:7] == 0 && current_priv != PRIV_U);
            default: legal_encoding = 1'b0;
        endcase
    end
    wire raise_illegal_instruction_alu = !legal_encoding;

    assign alucon_w =
                    is_cv_dotup_h ? ALU_CV_DOTUP_H :
                    is_cv_dotsp_b ? ALU_CV_DOTSP_B :
                    is_mul    ? 5'b1_1000 :
                    is_mulh   ? 5'b1_1001 :
                    is_mulhsu ? 5'b1_1010 :
                    is_mulhu  ? 5'b1_1011 :
                    is_div    ? 5'b1_1100 :
                    is_divu   ? 5'b1_1101 :
                    is_rem    ? 5'b1_1110 :
                    is_remu   ? 5'b1_1111 :
                    is_reg_op
                        ? {opcode[30], 1'b0, opcode[14:12]}
                    :
                    (is_imm_op && (opcode[14:12] == 3'b101))
                        ? {opcode[30], 1'b0, opcode[14:12]}
                    :
                    is_imm_op
                        ? {2'b00, opcode[14:12]}
                    :
                    5'b00000;

    assign funct3_w = opcode[14:12];

    // ---- オペランドセレクタ / メモリアクセス ----
    assign op1sel_w = ((op == SBFORMAT) || (op == UFORMAT_AUIPC) || (op == UJFORMAT)) ? 1'b1 : 1'b0;
    assign op2sel_w = (is_reg_op || (op == MULDIV) || is_pulp) ? 1'b0 : 1'b1;

    // メモリアクセス（CSRはメモリに行かない）
    assign mem_rw_w = (op == SFORMAT) ? 1'b1 : 1'b0;

    // ---- WriteBack 選択 ----
    // 2'b11 を CSR旧値の書き戻し経路に割当て（コア側で csr_rdata を選択）
    assign wb_sel_w = (op == IFORMAT_LOAD)                         ? 2'b01 :
                      ((op == UJFORMAT) || (op == IFORMAT_JALR))   ? 2'b10 :
                      (is_csr_any)                                 ? 2'b11 :
                                                                      2'b00;

    // ---- レジスタ書き込み許可信号 ----
    // CSR時は rd!=x0 のときのみ書く（rd==x0 なら破棄）
    wire rf_wen_noncsr = is_reg_op || is_imm_op ||
        (op == IFORMAT_LOAD) || (op == UFORMAT_LUI) || (op == UFORMAT_AUIPC) ||
        (op == UJFORMAT) || (op == IFORMAT_JALR);

    assign rf_wen_w = is_csr_any ? (w_addr_w != 5'b00000) : rf_wen_noncsr;

    // ---- PC セレクト ----
    // ECALL/EBREAK/MRET/WFI は分岐扱い（コア側でトラップ/戻りへ）
    assign pc_sel_w = (op == SBFORMAT) ? 2'b01 :
                      ((op == UJFORMAT) || (op == IFORMAT_JALR) || (is_ecall_w || is_sret_w || is_mret_w)) ? 2'b10 :
                      2'b00;

    // ---- CSR新規出力（組合せ値）----
    wire        csr_wr_w       = is_csr_any;
    wire [1:0]  csr_cmd_w      = csr_cmd_norm; // 0:RW,1:RS,2:RC
    wire        csr_use_imm_w  = is_csri;
    wire [11:0] csr_addr_mux   = csr_addr_w;
    wire [4:0]  csr_zimm_w     = opcode[19:15];

    // ロード/ストア判定
    wire is_load_w  = (op == IFORMAT_LOAD); // LB/LH/LW/LD/LBU/LHU/LWU
    wire is_store_w = (op == SFORMAT);       // SB/SH/SW/SD

    // ============================================================
    // ソースレジスタ使用判定
    // ============================================================

    // rs1を実際に使用する命令
    wire use_rs1_w =
            is_pulp ||
            is_reg_op       || // R-type、M拡張
            is_imm_op   || // ADDIなど
            (op == IFORMAT_LOAD)  || // LOADアドレス
            (op == SFORMAT)       || // STOREアドレス
            (op == SBFORMAT)      || // BRANCH比較
            (op == IFORMAT_JALR)  || // JALRアドレス
            is_csrrw              || // CSRレジスタ形式
            is_csrrs              ||
            is_csrrc              ||
            is_sfence_vma_w;

    // rs2を実際に使用する命令
    wire use_rs2_w =
            is_pulp ||
            is_reg_op      || // R-type、M拡張
            (op == SFORMAT)      || // STOREデータ
            (op == SBFORMAT)     || // BRANCH比較
            is_sfence_vma_w;

    // パイプライン処理 R-type判定
    wire is_R_type_w = is_reg_op || is_pulp;

    // パイプライン処理 IMM判定
    wire is_op_imm_w = is_imm_op;

    // NOP
    logic is_nop;

    assign is_nop = (opcode == 32'h0000_0013);

    // （MULDIV除外テスト時に）パイプライン対象外となるM拡張命令
    wire is_mul_div_w =
        is_mul    |
        is_mulh   |
        is_mulhsu |
        is_mulhu  |
        is_div    |
        is_divu   |
        is_rem    |
        is_remu;
        //is_nop;

    // -------------------------------------------------------------------------
    // Pipeline execution instructions (single-cycle EX, blocking memory):
    // R-Type : ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
    // I-Type : ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
    // Load   : LB, LH, LW, LBU, LHU
    // Store  : SB, SH, SW
    // -------------------------------------------------------------------------
    wire is_pipeline_memory_w =
        (is_load_w && ((funct3_w == 3'b000) || (funct3_w == 3'b001) ||
                       (funct3_w == 3'b010) || (funct3_w == 3'b100) ||
                       (funct3_w == 3'b101) || (funct3_w == 3'b011) ||
                       (funct3_w == 3'b110))) ||
        (is_store_w && ((funct3_w == 3'b000) || (funct3_w == 3'b001) ||
                        (funct3_w == 3'b010) || (funct3_w == 3'b011)));
    wire pipeline_type_w      =
            //(is_R_type_w && !is_mul_div_w) || is_op_imm_w || is_pipeline_memory_w;
            is_R_type_w || is_op_imm_w || is_pipeline_memory_w;

    // =============================================================================
    // 構造体へまとめた次段デコード結果
    // =============================================================================
    dec_ctrl_t decoder_ctrl_next;

    always @(*) begin
        decoder_ctrl_next.r_addr1                  = r_addr1_w;
        decoder_ctrl_next.r_addr2                  = r_addr2_w;
        decoder_ctrl_next.w_addr                   = w_addr_w;
        decoder_ctrl_next.imm                      = imm_w;
        decoder_ctrl_next.alucon                   = alucon_w;
        decoder_ctrl_next.funct3                   = funct3_w;
        decoder_ctrl_next.op1sel                   = op1sel_w;
        decoder_ctrl_next.op2sel                   = op2sel_w;
        decoder_ctrl_next.mem_rw                   = mem_rw_w;
        decoder_ctrl_next.rf_wen                   = rf_wen_w;
        decoder_ctrl_next.wb_sel                   = wb_sel_w;
        decoder_ctrl_next.pc_sel                   = pc_sel_w;
        decoder_ctrl_next.is_fence                 = is_fence_w;
        decoder_ctrl_next.is_fence_i               = is_fence_i_w;
        decoder_ctrl_next.is_sfence_vma            = is_sfence_vma_w;
        decoder_ctrl_next.csr_wr                   = csr_wr_w;
        decoder_ctrl_next.csr_cmd                  = csr_cmd_w;
        decoder_ctrl_next.csr_use_imm              = csr_use_imm_w;
        decoder_ctrl_next.csr_addr                 = csr_addr_mux;
        decoder_ctrl_next.csr_zimm                 = csr_zimm_w;
        decoder_ctrl_next.is_sret                  = is_sret_w;
        decoder_ctrl_next.is_mret                  = is_mret_w;
        decoder_ctrl_next.is_ecall                 = is_ecall_w;
        decoder_ctrl_next.is_load                  = is_load_w;
        decoder_ctrl_next.is_store                 = is_store_w;
        decoder_ctrl_next.use_rs1                  = use_rs1_w;
        decoder_ctrl_next.use_rs2                  = use_rs2_w;
        decoder_ctrl_next.is_R_type                = is_R_type_w;
        decoder_ctrl_next.is_op_imm                = is_op_imm_w;
        decoder_ctrl_next.word_op                  = word_op;
        decoder_ctrl_next.is_ebreak                = opcode == 32'h00100073;
        decoder_ctrl_next.pipeline_type            = pipeline_type_w;
        decoder_ctrl_next.out_pc                   = in_pc;
        decoder_ctrl_next.raise_illegal_instruction =
                                    raise_illegal_instruction_sw |
                                    raise_illegal_instruction_mw |
                                    raise_illegal_instruction_alu | illegal_pulp;
        if (decoder_ctrl_next.raise_illegal_instruction) begin
            decoder_ctrl_next.rf_wen = 1'b0;
            decoder_ctrl_next.is_load = 1'b0;
            decoder_ctrl_next.is_store = 1'b0;
            decoder_ctrl_next.mem_rw = 1'b0;
            decoder_ctrl_next.csr_wr = 1'b0;
            decoder_ctrl_next.pc_sel = 2'b00;
        end
    end

    // The v2 issue stage consumes the FIFO head directly.  Keep decode
    // combinational so a new independent R/I instruction can be dispatched
    // on every clock; the issue/slow-path registers provide the state hold.
    always_comb begin
        decoder_ctrl = decoder_ctrl_next;
        decode_done  = decode_enb;
    end

endmodule
