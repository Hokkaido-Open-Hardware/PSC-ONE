// NISHIHARU

module Decorder(
    input wire              clock,
    input  wire             reset_n,
    input  wire             decode_enb,
    input  wire [31:0]      opcode,
    input  wire [31:0]      in_pc,
    // ==== 既存出力 ====
    output reg  [4:0]       r_addr1, 
    output reg  [4:0]       r_addr2, 
    output reg  [4:0]       w_addr,
    output reg  [31:0]      imm,
    output reg  [4:0]       alucon,
    output reg  [2:0]       funct3,
    output reg              op1sel, 
    output reg              op2sel, 
    output reg              mem_rw, 
    output reg              rf_wen,
    output reg  [1:0]       wb_sel,
    output reg  [1:0]       pc_sel,
    output reg              is_fence,
    output reg              is_fence_i,
    output reg              is_sfence_vma,
    // Privilege level encoding (RISC-V spec)
    input wire [1:0]        current_priv,
    // ==== CSR命令デコード結果 ====
    output reg              csr_wr,        // CSRRW/CSRRS/CSRRC/CSRR*I
    output reg  [1:0]       csr_cmd,       // 0:RW, 1:RS, 2:RC
    output reg              csr_use_imm,   // *I 版（zimm使用）
    output reg  [11:0]      csr_addr,      // CSRアドレス
    output reg  [4:0]       csr_zimm,
    output reg              is_sret,
    output reg              is_mret,
    output reg              is_ecall, 
    // ==== ロード/ストア判定 ====
    output reg              is_load,
    output reg              is_store,
    // pipeline sig.
    output reg              is_R_type,
    output reg              is_op_imm,
    // pc
    output reg [31:0]       out_pc,
    // illegal_instruction
    output reg              raise_illegal_instruction,
    // done
    output reg              decode_done
);

    // Privilege level encoding (RISC-V spec)
    localparam [1:0] PRIV_U = 2'b00;
    localparam [1:0] PRIV_S = 2'b01;
    localparam [1:0] PRIV_M = 2'b11;

    // 内部配線（組合せ）
    wire [4:0]  r_addr1_w, r_addr2_w, w_addr_w;
    wire [31:0] imm_w;
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
    wire [31:0] imm_i;
    wire [31:0] imm_s;
    wire [31:0] imm_b;
    wire [31:0] imm_u;
    wire [31:0] imm_j;

    // I-type
    assign imm_i = {{20{opcode[31]}}, opcode[31:20]};

    // S-type
    assign imm_s = {{20{opcode[31]}}, opcode[31:25], opcode[11:7]};

    // B-type
    assign imm_b = {{19{opcode[31]}},
                    opcode[31],
                    opcode[7],
                    opcode[30:25],
                    opcode[11:8],
                    1'b0};

    // U-type
    assign imm_u = {opcode[31:12], 12'b0};

    // J-type (JAL)
    assign imm_j = {{11{opcode[31]}},
                    opcode[31],
                    opcode[19:12],
                    opcode[20],
                    opcode[30:21],
                    1'b0};

    // 最終 immediate
    assign imm_w =  (op == UJFORMAT) ? imm_j :
                    (op == SBFORMAT) ? imm_b :
                    (op == SFORMAT)  ? imm_s :
                    ((op == IFORMAT_ALU) || (op == IFORMAT_LOAD) || (op == IFORMAT_JALR)) ? imm_i :
                    ((op == UFORMAT_LUI) || (op == UFORMAT_AUIPC)) ? imm_u :
                    32'b0;

    // ---- ALU制御 ----
    wire is_mul;
    wire is_mulh;
    wire is_mulhsu;
    wire is_mulhu;
    wire is_div;
    wire is_divu;
    wire is_rem;
    wire is_remu;

    assign is_mul  = (op == RFORMAT) &&
                    (opcode[31:25] == 7'b0000001) &&
                    (opcode[14:12] == 3'b000);

    assign is_mulh =
                    (op == RFORMAT) &&
                    (opcode[31:25] == 7'b0000001) &&
                    (opcode[14:12] == 3'b001);

    assign is_mulhsu =
                    (op == RFORMAT) &&
                    (opcode[31:25] == 7'b0000001) &&
                    (opcode[14:12] == 3'b010);

    assign is_mulhu =
                    (op == RFORMAT) &&
                    (opcode[31:25] == 7'b0000001) &&
                    (opcode[14:12] == 3'b011);

    assign is_div  = (op == RFORMAT) &&
                    (opcode[31:25] == 7'b0000001) &&
                    (opcode[14:12] == 3'b100);

    assign is_divu = (op == RFORMAT) &&
                    (opcode[31:25] == 7'b0000001) &&
                    (opcode[14:12] == 3'b101);

    assign is_rem  = (op == RFORMAT) &&
                    (opcode[31:25] == 7'b0000001) &&
                    (opcode[14:12] == 3'b110);

    assign is_remu = (op == RFORMAT) &&
                    (opcode[31:25] == 7'b0000001) &&
                    (opcode[14:12] == 3'b111);

    // illegal checks
    // DIV以下は未対応
    //wire raise_illegal_instruction_alu = is_div | is_divu | is_rem | is_remu;
    wire raise_illegal_instruction_alu = 0;

    assign alucon_w =
                    is_mul    ? 5'b1_1000 :
                    is_mulh   ? 5'b1_1001 :
                    is_mulhsu ? 5'b1_1010 :
                    is_mulhu  ? 5'b1_1011 :
                    is_div    ? 5'b1_1100 :
                    is_divu   ? 5'b1_1101 :
                    is_rem    ? 5'b1_1110 :
                    is_remu   ? 5'b1_1111 :
                    (op == RFORMAT)
                        ? {opcode[30], opcode[25], opcode[14:12]}
                    :
                    ((op == IFORMAT_ALU) && (opcode[14:12] == 3'b101))
                        ? {opcode[30], opcode[25], opcode[14:12]}
                    :
                    (op == IFORMAT_ALU)
                        ? {2'b00, opcode[14:12]}
                    :
                    5'b00000;

    assign funct3_w = opcode[14:12];

    // ---- オペランドセレクタ / メモリアクセス ----
    assign op1sel_w = ((op == SBFORMAT) || (op == UFORMAT_AUIPC) || (op == UJFORMAT)) ? 1'b1 : 1'b0;
    assign op2sel_w = ((op == RFORMAT) || (op == MULDIV)) ? 1'b0 : 1'b1;

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
    wire rf_wen_noncsr =
        ((op == RFORMAT) && ({opcode[31], opcode[29:25]} == 6'b000000)) ||
        ((op == MULDIV)  && (opcode[31:25] == 7'b000001)) ||
        ((op == IFORMAT_ALU) &&
           ( ({opcode[31:25], opcode[14:12]} == 10'b00000_00_001) ||
             ({opcode[31], opcode[29:25], opcode[14:12]} == 9'b0_000_00_101) || // SLLI/SRLI/SRAI
             (opcode[14:12] == 3'b000) || (opcode[14:12] == 3'b010) ||
             (opcode[14:12] == 3'b011) || (opcode[14:12] == 3'b100) ||
             (opcode[14:12] == 3'b110) || (opcode[14:12] == 3'b111) )) ||
        (op == IFORMAT_LOAD) || (op == UFORMAT_LUI) || (op == UFORMAT_AUIPC) ||
        (op == UJFORMAT) || (op == IFORMAT_JALR);

    assign rf_wen_w = is_csr_any ? (w_addr_w != 5'b00000) : rf_wen_noncsr;

    // ---- PC セレクト ----
    // ECALL/EBREAK/MRET/WFI は分岐扱い（コア側でトラップ/戻りへ）
    assign pc_sel_w = (op == SBFORMAT) ? 2'b01 :
                      ((op == UJFORMAT) || (op == IFORMAT_JALR) || (is_trap_like)) ? 2'b10 :
                      2'b00;

    // ---- CSR新規出力（組合せ値）----
    wire        csr_wr_w       = is_csr_any;
    wire [1:0]  csr_cmd_w      = csr_cmd_norm; // 0:RW,1:RS,2:RC
    wire        csr_use_imm_w  = is_csri;
    wire [11:0] csr_addr_mux   = csr_addr_w;
    wire [4:0]  csr_zimm_w     = opcode[19:15];

    // ロード/ストア判定
    wire        is_load_w  = (op == 7'b0000011); // IFORMAT_LOAD : LB/LH/LW/LBU/LHU
    wire        is_store_w = (op == 7'b0100011); // SFORMAT      : SB/SH/SW

    // パイプライン処理 R-type判定
    wire is_R_type_w = (op == RFORMAT);

    // パイプライン処理 IMM判定
    wire is_op_imm_w = (op == IFORMAT_ALU);

    // =============================================================================
    // パイプラインレジスタ
    // =============================================================================
    always @(posedge clock or negedge reset_n) begin
        if(!reset_n) begin
            r_addr1     <= 5'd0; 
            r_addr2     <= 5'd0;
            w_addr      <= 5'd0;
            imm         <= 32'd0;
            alucon      <= 5'd0;
            funct3      <= 3'd0;
            op1sel      <= 1'b0; 
            op2sel      <= 1'b0; 
            mem_rw      <= 1'b0; 
            rf_wen      <= 1'b0;
            wb_sel      <= 2'b00; 
            pc_sel      <= 2'b00;
            is_fence    <= 1'b0;
            is_fence_i  <= 1'b0;
            is_sfence_vma <= 1'b0;
            // CSR
            csr_wr      <= 1'b0;
            csr_cmd     <= 2'b00;
            csr_use_imm <= 1'b0;
            csr_addr    <= 12'h000;
            csr_zimm    <= 5'd0;
            is_sret     <= 1'b0;
            is_mret     <= 1'b0;
            is_ecall    <= 1'b0;  
            // Load Store
            is_load     <= 1'b0;
            is_store    <= 1'b0;
            // pipeline sig.
            is_R_type   <= 1'b0;
            is_op_imm   <= 1'b0;
            // pc
            out_pc      <= 32'h0;
            // illegal_instruction
            raise_illegal_instruction <= 1'b0;
            decode_done <= 1'b0;

        end else begin
            decode_done <= 1'b0;

            if (decode_enb) begin
                r_addr1     <= r_addr1_w; 
                r_addr2     <= r_addr2_w;
                w_addr      <= w_addr_w;
                imm         <= imm_w;
                alucon      <= alucon_w;
                funct3      <= funct3_w;
                op1sel      <= op1sel_w; 
                op2sel      <= op2sel_w; 
                mem_rw      <= mem_rw_w; 
                rf_wen      <= rf_wen_w;
                wb_sel      <= wb_sel_w; 
                pc_sel      <= pc_sel_w;
                is_fence    <= is_fence_w;
                is_fence_i  <= is_fence_i_w;
                is_sfence_vma <= is_sfence_vma_w;
                // CSR
                csr_wr      <= csr_wr_w;
                csr_cmd     <= csr_cmd_w;
                csr_use_imm <= csr_use_imm_w;
                csr_addr    <= csr_addr_mux;
                csr_zimm    <= csr_zimm_w;
                is_sret     <= is_sret_w;
                is_mret     <= is_mret_w;
                is_ecall    <= is_ecall_w; 
                // Load Store
                is_load     <= is_load_w;
                is_store    <= is_store_w;
                // pipeline sig.
                is_R_type   <= is_R_type_w;
                is_op_imm   <= is_op_imm_w;
                // pc
                out_pc      <= in_pc;
                // illegal_instruction
                raise_illegal_instruction <= raise_illegal_instruction_sw | raise_illegal_instruction_mw 
                                            | raise_illegal_instruction_alu;
                decode_done <= 1'b1;
            end
        end
    end

endmodule
