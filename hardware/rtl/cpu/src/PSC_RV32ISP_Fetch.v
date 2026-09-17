// NISHIHARU
module PSC_RV32ISP_Fetch #(
    // Parameter
    parameter integer   FIFO_DEPTH   = 4
)(
    // clock, reset
    input wire              clock,
    input wire              reset_n,
    input wire              cpu_stop,
    // in,out
    input wire              fetch_valid,
    output reg              fetch_ready,        /// Not used.
    input wire              execute_ready,
    // fifo sig.
    output wire             fifo_empty,
    output wire             fifo_full,
    input wire              fifo_read_valid,
    output wire             fifo_read_ready,
    input wire              fifo_flush,
    // other sig.
    input wire [31:0]       pc,
    input wire [31:0]       csr_satp,
    input  wire [1:0]       priv_mode,
    input wire              is_load,
    input wire              is_store,
    input wire              is_sfence_vma,
    output wire             fifo_ready,
    // fault sig.
    output wire             i_pf,
    // to memory
    output wire             program_mem_read_valid,
    input wire              program_mem_read_ready,
    output wire [31:0]      program_mem_read_address,
    input wire [31:0]       program_mem_read_data,
    input wire              program_mem_req_ready,
    // MMU
    output wire             data_mem_read_valid,
    input wire              data_mem_read_ready,
    output wire [31:0]      data_mem_read_address,
    input  wire [31:0]      data_mem_read_data,
    input  wire             data_mem_read_req_ready,
    // opcode
    output wire [31:0]      opcode,
    output wire [31:0]      fifo_opcode_data
);

    // FIFO state sig.
    assign  fifo_empty = empty;
    assign  fifo_full  = full;

    // =====================================
    // Internal State counter
    // =====================================
    localparam IDLE             = 4'd0;
    localparam FETCH_PC         = 4'd1;
    localparam FETCH_MMU        = 4'd2;
    localparam FETCH_MMU_W      = 4'd3;
    localparam FETCH            = 4'd4;
    localparam FETCH_W          = 4'd5;
    localparam EXECUTE_W        = 4'd6;
    localparam FIFO_FLUSH       = 4'd7;
    localparam FIFO_FLUSH_MMU_W = 4'd8;
    localparam FIFO_FLUSH_W     = 4'd9;

    reg [3:0]  fetch_state, next_state;

    reg [31:0] fetch_pc, next_pc;
    reg        fetch_fifo_flush, next_flush;
    reg        next_ready;

    wire       i_mmu_done;
    wire       i_mode_sv32;

    // =====================================================
    // 状態レジスタ（同期）
    // =====================================================
    always @(posedge clock or negedge reset_n) begin
        if(!reset_n) begin
            fetch_state       <= IDLE;
            fetch_pc          <= 0;
            fetch_ready       <= 0;
            fetch_fifo_flush  <= 0;
        end else if(cpu_stop) begin
            fetch_state       <= IDLE;
        end else begin
            fetch_state       <= next_state;
            fetch_pc          <= next_pc;
            fetch_ready       <= next_ready;
            fetch_fifo_flush  <= next_flush;
        end
    end


    // =====================================================
    // 次状態・出力ロジック（組み合わせ）
    // =====================================================
    always @(*) begin

        // =====================================================
        // デフォルト値（超重要）
        next_state = fetch_state;
        next_pc    = fetch_pc;
        next_ready = 1'b0;
        next_flush = 1'b0;

        // fifo_flushの処理
        if (fifo_flush) begin

            case (fetch_state)
                // =====================
                FETCH_PC: begin
                    next_state = FIFO_FLUSH;
                end
                FETCH_MMU: begin
                    next_state = FIFO_FLUSH_MMU_W;
                end
                FETCH_MMU_W: begin
                    next_state = i_mmu_done ? FIFO_FLUSH : FIFO_FLUSH_MMU_W;
                end
                FETCH: begin
                    next_state = FIFO_FLUSH;
                end
                FETCH_W: begin
                    if (program_mem_read_ready)
                        next_state = EXECUTE_W;
                    else
                        next_state = FIFO_FLUSH_W;
                end
                EXECUTE_W: begin
                    next_state = FIFO_FLUSH;
                end
                // =====================
                default: begin
                    // NOP
                end
            endcase
        
        // =====================================================
        // default処理
        end else begin

            case (fetch_state)

                // ================================
                // 通常時のステート
                // ================================
                // =====================
                // state = 0
                IDLE: begin
                    if (fetch_valid)
                        next_state = FETCH_PC;
                end

                // =====================
                // state = 1
                FETCH_PC: begin
                    if (empty) begin
                        next_pc = pc;
                        next_state = FETCH_MMU;
                    end

                    else if (!full) begin
                        next_pc = fetch_pc + 4;
                        next_state = FETCH_MMU;
                    end
                end

                // =====================
                // state = 2
                FETCH_MMU: begin
                   next_state = FETCH_MMU_W;
                end

                // =====================
                // state = 3
                FETCH_MMU_W: begin
                    if (i_mmu_done)
                        next_state = FETCH;
                end

                // =====================
                // state = 4
                FETCH: begin
                    if (program_mem_read_valid)
                        next_state = FETCH_W;
                end

                // =====================
                // state = 5
                FETCH_W: begin
                    if (program_mem_read_ready) begin
                        next_ready = 1'b1;
                        next_state = FETCH_PC;
                    end
                end
                
                // =====================
                // state = 6
                EXECUTE_W: begin
                    next_pc = pc;
                    if (execute_ready)
                        next_state = IDLE;
                end

                // ================================
                // fifo flush時のステート
                // ================================
                // =====================
                // state = 7
                FIFO_FLUSH: begin
                    next_pc    = pc;
                    next_state = IDLE;
                end

                // =====================
                // state = 8
                FIFO_FLUSH_MMU_W: begin
                    next_pc = pc;
                    if (i_mmu_done)
                        next_state = IDLE;
                end

                // =====================
                // state = 9
                FIFO_FLUSH_W: begin
                    next_pc = pc;
                    if (program_mem_read_ready | execute_ready) begin       // TBD
                        next_state = IDLE;
                        next_flush = 1'b1;
                    end
                end

                // =====================
                // 不正状態から復帰（止まらないFSM）
                default: begin
                    next_state = IDLE;
                    next_pc    = pc;
                end
                
            endcase

        end
    end


    // MMU wire
    wire [31:0] i_paddr;
    wire        i_MMU_enb;

    // to memory
    wire [31:0] mem_read_address_pvsel = i_paddr;   // MMU output addr.

    assign program_mem_read_address = (program_mem_read_valid) ? mem_read_address_pvsel : 32'd0;
    assign i_MMU_enb = (fetch_state==FETCH_MMU);
                            
    // =====================================
    // MMU_i
    // =====================================
    // fetch_state = FETCH_MMU
    // I-side MMU: pc を翻訳（実行属性）

    MMU u_mmu_i (
        .clk                (clock),
        .reset_n            (reset_n),
        .MMU_enb            (i_MMU_enb),
        .vaddr              (fetch_pc),        // vaddr
        .satp               (csr_satp),        // Csr から出した satp
        .priv_mode          (priv_mode),
        .access_r           (1'b0),
        .access_w           (1'b0),
        .access_x           (1'b1),
        .mem_req_ready      (data_mem_read_req_ready),  // cache_io read可能.
        .mem_rdata          (data_mem_read_data),
        .mem_addr           (data_mem_read_address),
        .mem_valid          (data_mem_read_valid),
        .mem_ready          (data_mem_read_ready),
        .cpu_state_done     (fetch_state==FETCH_W),
        .sfence_vma         (fifo_flush & is_sfence_vma),
        
        .paddr              (i_paddr),
        .page_fault         (i_pf),
        .mode_sv32          (i_mode_sv32),      // 0: 仮想メモリモードOFF.
        .mmu_done           (i_mmu_done)
    );

    // =====================================
    // FETCH
    // =====================================
    // fetch_state = FETCH & FETCH_W
    wire [31:0] f_program_mem_read_data;
    wire f_program_mem_read_valid;
    wire f_program_mem_read_ready;
    wire f_program_mem_req_ready;

    assign  program_mem_read_valid = ((fetch_state==FETCH) ? f_program_mem_read_valid : 1'b0);
    assign  f_program_mem_read_ready = program_mem_read_ready;
    assign  f_program_mem_read_data  = program_mem_read_data;
    assign  f_program_mem_req_ready  = program_mem_req_ready;

    wire opcode_read_valid;
    wire [31:0] opcode_read_data;

    Fetch u_fetch (
        .clock                  (clock),                        // クロック
        .reset_n                (reset_n),                      // リセット（負論理）
        .fetch_enb              (fetch_state==FETCH),           // フェッチ有効信号
        .mem_read_data          (f_program_mem_read_data),
        .program_mem_read_valid (f_program_mem_read_valid),     // プログラムメモリ読出し有効
        .program_mem_read_ready (f_program_mem_read_ready), 
        .program_mem_req_ready  (f_program_mem_req_ready),

        .opcode_read_valid      (opcode_read_valid),            // Threw sig.
        .opcode_read_data       (opcode_read_data),             // Threw sig.
        .opcode                 (opcode)                        // フェッチした命令コード
    );

    // =====================================
    // FIFO
    // =====================================
    wire in_ready;
    wire full, empty;
    wire [31:0] out_fetch_pc;

    Fetch_Fifo #(
        .WIDTH              (32),
        .DEPTH              (FIFO_DEPTH)
    ) u_fetch_fifo (
        .clock              (clock),
        .reset_n            (reset_n),

        .in_valid           ((fetch_state==FETCH_W) & opcode_read_valid),
        .in_data            (opcode_read_data),
        .in_pc_data         (fetch_pc),     // Debug
        .in_ready           (in_ready),

        .out_req_ready      (fifo_ready),
        .out_valid          (fifo_read_valid),
        .out_ready          (fifo_read_ready),
        .out_data           (fifo_opcode_data),
        .out_pc_data        (out_fetch_pc), // Debug

        .full               (full),
        .empty              (empty),

        .flush              (fifo_flush | fetch_fifo_flush)
    );

endmodule