// NISHIHARU

module PSC_RV32ISP_Execute #(
    parameter [31:0] UART_MMIO_ADDR    = 32'hF004_00F0,     // 未使用.
    parameter [31:0] UART_MMIO_FLAG    = 32'hF004_00F4,
    parameter [31:0] COUNTER_MMIO_ADDR = 32'hF004_FFF0
)(
    // clock, reset
    input wire              clock,
    input wire              reset_n,
    input wire              cpu_stop,
    input wire              cpu_trap,
    // in,out
    input wire              execute_valid,      // = !fifo_empty
    output reg              execute_ready,      // execute state 終了パルス
    // fifo sig.
    output wire             fifo_read_state_sig,
    output wire             execute_state_sig,
    input  wire             fifo_read_ready,
    output wire             fifo_flush_sig,
    // other sig.
    input  wire [31:0]      pc,
    input  wire [31:0]      opcode,
    input  wire [31:0]      csr_satp,
    input  wire [1:0]       priv_mode,
    output wire [31:0]      alu_data,
    output wire             is_load,
    output wire             is_store,
    output wire             is_sfence_vma,
    output wire             pc_sel2,
    output wire             do_sret,
    output wire             do_mret,
    output wire             is_ecall,
    output wire             is_fence_i,
    output wire             d_pf,
    output wire             illegal_instruction,
    // CSR sig
    output wire             csr_enb,
    output wire             csr_valid,
    // CSR
    output wire             csr_wr,          // CSRRW/CSRRS/CSRRC
    output wire [1:0]       csr_cmd,         // 0:RW, 1:RS, 2:RC
    output wire             csr_use_imm,     // *I 版（zimm使用）
    output wire [11:0]      csr_addr,        // CSR address
    output wire [4:0]       csr_zimm,
    input  wire [31:0]      csr_rdata,
    output wire [31:0]      csr_reg_data_1,
    // to memory
    output wire             data_mem_read_valid,
    input wire              data_mem_read_ready,
    output wire [31:0]      data_mem_read_address,
    input  wire [31:0]      data_mem_read_data,
    input  wire             data_mem_req_ready,

    output wire             data_mem_write_valid,    
    input wire              data_mem_write_ready,
    output wire [31:0]      data_mem_write_address,
    output wire [31:0]      data_mem_write_data,
    output wire  [2:0]      mem_write_sel,
    // vaddr for stval
    output wire [31:0]      vaddr,
    output wire  [8:0]      uart_out
);

    // ============================================================
    // FIFO 制御
    // ============================================================
    // fifo sig
    assign fifo_read_state_sig  = (execute_state==FIFO_READ);
    assign execute_state_sig    = (execute_state==EXECUTE);
    assign fifo_flush_sig       = (execute_state==STORE) & 
                                  (pc_sel2 | is_sfence_vma | is_fence_i | is_ecall | do_mret | do_sret | cpu_trap);

    // CSR
    assign csr_enb      = (execute_state==BRANCH) & branch_done;
    assign csr_valid    = execute_ready;

    // ============================================================
    // pipeline_mode 制御
    // ============================================================
    wire is_R_type;              // add x1 x2 x3 等
    wire is_op_imm;              // addi x1, #10 等

    // Pipeline Setting
    //wire pipeline_type =  1'b0;   // Pipeline = off    
    //wire pipeline_type =  is_R_type;   // R type.
    //wire pipeline_type =  is_op_imm;   // IMM type.
    wire pipeline_type = (is_R_type | is_op_imm);   // R type & I type.

    // mode reg.
    reg  pipeline_mode;          // pipeline_mode=1 のときは「パイプライン指定命令のみ」受け入れ

    always @(posedge clock or negedge reset_n) begin
        if(!reset_n) begin
            pipeline_mode <= 1'b0;
        end else if(cpu_stop) begin
            pipeline_mode <= 1'b0;
        end else begin
            if(execute_state==IDLE) begin
                pipeline_mode <= 1'b0;
            end else if(decode_done & pipeline_type) begin
                pipeline_mode <= 1'b1;
            end
        end
    end

    // =====================================
    // Internal State counter
    // =====================================
    localparam IDLE             = 0;
    localparam FIFO_READ        = 1;
    localparam DECODE           = 2;    // Decode
    localparam EXECUTE          = 3;    // Execute
    localparam BRANCH_MMU       = 4;
    localparam BRANCH_MMU_W     = 5;
    localparam BRANCH           = 6;    // Branch
    localparam STORE_MMU        = 7;
    localparam STORE_MMU_W      = 8;
    localparam STORE            = 9;    // Store

    wire       i_mmu_done, d_mmu_done;
    wire       d_mode_sv32;
    
    reg [31:0] data_mem_read_data_reg;
    reg [1:0]  ld_low2_q;

    // =====================================================
    // 状態レジスタ（同期）
    // =====================================================
    reg [3:0] execute_state, next_state;
    reg [3:0] execute_state_d;

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            execute_state <= IDLE;
            execute_state_d <= IDLE;
        end else if (cpu_stop) begin
            execute_state <= IDLE;
            execute_state_d <= IDLE;
        end else begin
            execute_state <= next_state;
            execute_state_d <= execute_state;
        end
    end

    // execute_ready
    wire idle_enter = (execute_state == IDLE) & (execute_state_d != IDLE);

    always @(posedge clock or negedge reset_n) begin
        if(!reset_n)
            execute_ready <= 0;
        else
            execute_ready <= idle_enter;
    end

    // =====================================================
    // 次状態・出力ロジック（組み合わせ）
    // =====================================================
    always @(*) begin
        next_state = execute_state;  // デフォルト = stay（stall）

        case (execute_state)

            // =====================
            IDLE:
                if (execute_valid)
                    next_state = FIFO_READ;

            // =====================
            FIFO_READ:
                next_state = DECODE;

            // =====================
            DECODE:
                //if (fifo_read_ready & decode_done)
                if (decode_done)
                    next_state = EXECUTE;

            // =====================
            EXECUTE:
                if (alu_done) begin
                    if (pipeline_type)
                        next_state = STORE;
                    else
                        next_state = BRANCH_MMU;
                end

            // =====================
            BRANCH_MMU:
                next_state = BRANCH_MMU_W;

            // =====================
            BRANCH_MMU_W:
                if (is_load | is_store) begin
                    if (d_mmu_done) 
                        next_state = BRANCH;
                end else begin
                    next_state = BRANCH;
                end

            // =====================
            BRANCH:
                if (branch_done)
                    next_state = STORE_MMU;

            // =====================
            STORE_MMU:
                next_state = STORE_MMU_W;

            // =====================
            STORE_MMU_W:
                if (is_load | is_store) begin
                    if (d_mmu_done)
                        next_state = STORE;
                end else begin
                    next_state = STORE;
                end

            // =====================
            STORE:
                if (mem_rw & store_done)
                    next_state = IDLE;
                else
                    next_state = IDLE;

            // =====================
            default:
                next_state = IDLE;

        endcase
    end

    // =====================================================
    // Output / Datapath Registers
    // =====================================================
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            data_mem_read_data_reg <= 0;
            ld_low2_q <= 0;
        end else begin
            // Output regs
            case (execute_state)
                BRANCH: begin
                    if (is_load)
                        ld_low2_q <= alu_data[1:0];
                    if (data_mem_read_ready)
                        data_mem_read_data_reg <= data_mem_read_data;
                end
                default: begin
                end
            endcase
        end
    end


    // to memory
    wire d_mmu_mem_valid;
    wire branch_data_mem_read_valid;
    wire [31:0] d_mmu_mem_addr;
    wire [31:0] d_paddr;
    wire [31:0] branch_data_mem_read_address;
    wire d_MMU_enb;

    assign d_MMU_enb = (execute_state==BRANCH_MMU || execute_state==STORE_MMU) & (is_load | is_store);

    assign data_mem_read_address = (execute_state==BRANCH_MMU_W & d_mmu_mem_valid) ? d_mmu_mem_addr : 
                                   (execute_state==STORE_MMU_W & d_mmu_mem_valid)  ? d_mmu_mem_addr : 
                                   branch_data_mem_read_address;

    assign data_mem_read_valid = branch_data_mem_read_valid |
                                 ((execute_state==BRANCH_MMU_W) & d_mmu_mem_valid) |
                                 ((execute_state==STORE_MMU_W)  & d_mmu_mem_valid);
                                 
    assign data_mem_write_address = store_mem_write_address;

    // =====================================
    // DECODE
    // =====================================
    // decode wire
    wire [4:0] r_addr1, r_addr2, w_addr;
    wire [31:0] imm;
    wire [4:0] alucon;
    wire [2:0] funct3;
    wire op1sel, op2sel, mem_rw, rf_wen;
    wire [1:0] wb_sel, pc_sel;
    wire is_fence;
    //wire is_fence_i;

    //wire        is_load;
    //wire        is_store;

    wire [31:0] reg_data_1;
    wire [31:0] reg_data_2;
    wire [31:0] decode_pc;

    wire        decode_done;

    assign csr_reg_data_1       = reg_data_1;

    Decorder u_decorder (
        .clock              (clock),       // クロック
        .reset_n            (reset_n),     // リセット（負論理）
        .decode_enb         (execute_state==DECODE & fifo_read_ready),   // デコード有効信号. 
        .opcode             (opcode),      // 32bit命令コード入力
        .in_pc              (pc),          // PC

        .r_addr1            (r_addr1),     // レジスタ読み出しアドレス1
        .r_addr2            (r_addr2),     // レジスタ読み出しアドレス2
        .w_addr             (w_addr),      // レジスタ書き込みアドレス
        .imm                (imm),         // 即値
        .alucon             (alucon),      // ALU制御
        .funct3             (funct3),      // funct3
        .op1sel             (op1sel),      // オペランド1選択
        .op2sel             (op2sel),      // オペランド2選択
        .mem_rw             (mem_rw),      // メモリR/W制御
        .rf_wen             (rf_wen),      // レジスタファイル書き込み有効
        .wb_sel             (wb_sel),      // Write Back 選択
        .pc_sel             (pc_sel),      // PC選択
        .is_fence           (is_fence),
        .is_fence_i         (is_fence_i),
        .is_sfence_vma      (is_sfence_vma),

        // Privilege level encoding (RISC-V spec)
        .current_priv       (priv_mode),
        // ==== CSR outputs ====
        .csr_wr             (csr_wr),
        .csr_cmd            (csr_cmd),
        .csr_use_imm        (csr_use_imm),
        .csr_addr           (csr_addr),
        .csr_zimm           (csr_zimm),
        .is_sret            (do_sret),
        .is_mret            (do_mret),
        .is_ecall           (is_ecall),
        // pipeline sig
        .is_R_type          (is_R_type),
        .is_op_imm          (is_op_imm),
        // Load Store
        .is_load            (is_load),
        .is_store           (is_store),
        .out_pc             (decode_pc),
        .raise_illegal_instruction (illegal_instruction),
        .decode_done        (decode_done)
    );

    // =====================================
    // EXECUTION
    // =====================================
    wire [31:0] execute_pc;
    wire        alu_done;

    // REGISTER READ
    wire [31:0] r_data1, r_data2;

    Execute u_execute (
        .clock              (clock),             // クロック
        .reset_n            (reset_n),           // リセット（負論理）
        .execute_enb        (execute_state==EXECUTE),    // 実行有効信号 1
        .r_addr1            (r_addr1),           // レジスタアドレス1（Decorder出力）
        .r_addr2            (r_addr2),           // レジスタアドレス2（Decorder出力）
        .reg_data_addr1     (reg_data_1),        // レジスタデータ1入力
        .reg_data_addr2     (reg_data_2),        // レジスタデータ2入力
        .op1sel             (op1sel),            // オペランド1選択（Decorder出力）
        .op2sel             (op2sel),            // オペランド2選択（Decorder出力）
        .alucon             (alucon),            // ALU制御コード（Decorder出力）
        .imm                (imm),               // 即値（Decorder出力）
        .in_pc              (pc),                // 現在のPC値

        .alu_data           (alu_data),          // ALU演算結果
        .r_data1            (r_data1),           // レジスタデータ1保持
        .r_data2            (r_data2),           // レジスタデータ2保持
        .out_pc             (execute_pc),
        .alu_done           (alu_done)
    );

    // =====================================
    // MMU_d
    // =====================================
    // D-side MMU: ALU出力を翻訳（ロード/ストア属性）
    wire [31:0] d_pte_mem_rdata;
    wire d_mmu_mem_ready = data_mem_read_ready;
    assign d_pte_mem_rdata = data_mem_read_data;
    assign vaddr = alu_data;

    MMU u_mmu_d (
        .clk                (clock),
        .reset_n            (reset_n),
        .MMU_enb            (d_MMU_enb & !pipeline_mode),
        .vaddr              (vaddr),
        .satp               (csr_satp),
        .priv_mode          (priv_mode),
        .access_r           (is_load),
        .access_w           (is_store),
        .access_x           (1'b0),
        .mem_req_ready      (data_mem_req_ready),     // 暫定.
        .mem_rdata          (d_pte_mem_rdata),
        .mem_addr           (d_mmu_mem_addr),
        .mem_valid          (d_mmu_mem_valid),
        .mem_ready          (d_mmu_mem_ready),
        .cpu_state_done     (execute_state==STORE),
        .sfence_vma         (fifo_flush_sig & is_sfence_vma),
        
        .paddr              (d_paddr),
        .page_fault         (d_pf),
        .mode_sv32          (d_mode_sv32),
        .mmu_done           (d_mmu_done)
    );

    // =====================================
    // BRANCH
    // =====================================
    wire [31:0] branch_pc;
    wire        branch_done;

    Branch u_branch (
        .clock                  (clock),            // クロック
        .reset_n                (reset_n),          // リセット（負論理）
        // ブランチ有効信号. pc_sel2更新のためpipeline_modeはEXECUTEで更新
        .branch_enb             (execute_state==BRANCH | (execute_state==EXECUTE & pipeline_mode)),
        .is_load_store          (is_load | is_store),
        .funct3                 (funct3),           // funct3（Decorder出力）
        .r_data1                (r_data1),          // レジスタデータ1（Execute出力）
        .r_data2                (r_data2),          // レジスタデータ2（Execute出力）
        .pc_sel                 (pc_sel),           // PC選択（Decorder出力）
        .in_pc                  (execute_pc),       // PC
        .d_paddr                (d_paddr),

        // memory
        .data_mem_read_address  (branch_data_mem_read_address),
        .data_mem_read_valid    (branch_data_mem_read_valid),  
        .data_mem_req_ready     (data_mem_req_ready),
        .data_mem_read_ready    (data_mem_read_ready),
        
        // output 
        .pc_sel2                (pc_sel2),          // 分岐結果によるPC選択（Branch出力）
        .out_pc                 (branch_pc),
        .branch_done            (branch_done)
    );

    // =====================================
    // MEMORY STORE
    // =====================================
    wire [2:0]  mem_val = funct3;
    wire [31:0] w_data;
    wire        store_done;
    wire [31:0] memory_store_pc;
    wire [31:0] store_mem_write_address;
    assign  mem_write_sel = funct3;

    MemoryStore #(
        .UART_MMIO_ADDR             (UART_MMIO_ADDR),        // 未使用.
        .UART_MMIO_FLAG             (UART_MMIO_FLAG),
        .COUNTER_MMIO_ADDR          (COUNTER_MMIO_ADDR)
    ) u_memory_store (
        .clock                      (clock),                  // クロック
        .reset_n                    (reset_n),                // リセット（負論理）
        .store_enb                  (execute_state==STORE & !pipeline_mode),   // ストア有効
        .mem_rw                     (mem_rw),                 // メモリR/W制御（Decorder出力）
        .wb_sel                     (wb_sel),                 // Write Back 選択（Decorder出力）
        .pc_sel2                    (pc_sel2),                // ブランチ判定結果（Branch出力）
        .alu_data                   (alu_data),               // ALU結果（Execute出力）
        .mem_val                    (mem_val),                // メモリ値の制御（必要に応じてDecorder等から）
        .mem_read_data              (data_mem_read_data_reg),     // メモリ読み出しデータ
        .r_data2                    (r_data2),                // レジスタデータ2（Execute出力）
        .in_pc                      (branch_pc),              // 現在PC値
        .counter                    (32'd0),                  // カウンタ値
        .ld_low2                    (ld_low2_q),
        .csr_rdata                  (csr_rdata), 
        .d_paddr                    (d_paddr),

        // memory
        .data_mem_write_address     (store_mem_write_address),
        .data_mem_write_valid       (data_mem_write_valid),
        .data_mem_write_data        (data_mem_write_data),         // メモリ書き込みデータ[31:0]
        .data_mem_write_ready       (data_mem_write_ready),
        .data_mem_req_ready         (data_mem_req_ready),
        
        // output
        .uart                       (uart_out),
        .w_data                     (w_data),                      // 書き込みデータ全体
        .store_done                 (store_done),
        .out_pc                     (memory_store_pc)
    );

    // =====================================
    // Register インスタンス
    // =====================================

    // レジスタファイルのインスタンス化
    Register u_regfile (
        .clock              (clock),
        .reset_n            (reset_n),
        .store_enb          (execute_state==STORE),
        .rf_wen             (rf_wen),
        .w_addr             (w_addr),
        .w_data             (w_data),
        .r_addr1            (r_addr1),
        .r_addr2            (r_addr2),
        .reg_data_1         (reg_data_1),
        .reg_data_2         (reg_data_2)
    );

endmodule