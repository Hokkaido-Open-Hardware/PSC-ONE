// RV32IS 10+ stage pipeline 
// pipeline動作ON
// NISHIHARU

`timescale 1ns / 1ps

module PSC_RV32ISP_core #(
    parameter [31:0] UART_MMIO_ADDR    = 32'hF004_00F0,     // 未使用.
    parameter [31:0] UART_MMIO_FLAG    = 32'hF004_00F4,
    parameter [31:0] COUNTER_MMIO_ADDR = 32'hF004_FFF0
)(
    input wire              clock,
    input wire              reset_n,
    input wire              cpu_stop,
    input wire              timer_irq_ext,
    // Program
    output wire             program_mem_burst_mode,
    output wire             program_mem_read_valid,
    input wire              program_mem_read_ready,
    output wire [31:0]      program_mem_read_address,
    input  wire [31:0]      program_mem_read_data,
    input wire              program_mem_req_ready,
    // Data
    output wire             data_mem_read_valid,
    input wire              data_mem_read_ready,
    output wire [31:0]      data_mem_read_address,
    input  wire [31:0]      data_mem_read_data,
    input  wire             data_mem_req_ready,
    
    output wire             data_mem_write_valid,    
    input wire              data_mem_write_ready,
    output wire  [2:0]      mem_write_sel,
    output wire [31:0]      mem_write_address,
    output wire [31:0]      mem_write_data,
    // MMU
    output wire             mmu_data_mem_read_valid,
    input wire              mmu_data_mem_read_ready,
    output wire [31:0]      mmu_data_mem_read_address,
    input  wire [31:0]      mmu_data_mem_read_data,
    input  wire             mmu_data_req_ready,
    // Cashe 
    output wire             is_fence_i,
    // DATA Cache
    output wire [31:0]      csr_DCACHE_CTRL,
    // DMA
    output wire [31:0]      csr_DMA_CTRL,
    output wire [31:0]      csr_DMA_WORDS,
    output wire [31:0]      csr_DMA_SRC,
    output wire [31:0]      csr_DMA_DST,
    input  wire [31:0]      csr_DMA_STATUS,
    // SynapEngine
    output wire [31:0]      csr_SA_CTRL,
    output wire [31:0]      csr_SA_MODE,
    input  wire [31:0]      csr_SA_STATUS,
    output wire [31:0]      csr_SA_ADDR_A,
    output wire [31:0]      csr_SA_ADDR_B,
    output wire [31:0]      csr_SA_ADDR_C,
    // CPU Monitor
    output wire [31:0]      csr_CPU_MON_CTRL,
    input  wire [31:0]      csr_CPU_MON_CYCLE,
    output wire  [8:0]      uart_out    // not used
);

    assign  program_mem_burst_mode = 1'b0;

    `ifdef COCOTB_SIM
    `ifdef CPU_CORE_SIM
    initial begin
        `ifdef DUMP_VCD
        $display("COCOTB_SIM CPU CORE DUMP_VCD ENABLE");
        $dumpfile("./wave/PSC_RV32ISP_core.vcd");
        $dumpvars(0);
        `else
        $display("COCOTB_SIM CPU CORE verilator FST ENABLE");
        $dumpfile("./wave/PSC_RV32ISP_core.fst");
        $dumpvars(0);
        `endif
    end
    `endif
    `endif

    // Program Counter
    reg [31:0] pc;
    reg [31:0] counter;

    // =====================================
    // CPU Main State counter
    // =====================================
    localparam IDLE         = 0;
    localparam CPU_RUN      = 1;
    localparam CPU_TRAP     = 2;
    localparam CPU_HALT     = 3;
    localparam EXECUTE      = 4;    // TBD

    reg [3:0]  cpu_state;   // max: 15 state.
    reg        fetch_valid;
    wire       fetch_ready;

    always @(posedge clock or negedge reset_n) begin
        if(!reset_n) begin
            cpu_state <= IDLE;
            fetch_valid <= 1'b0;
        end else if(cpu_stop) begin
            cpu_state <= IDLE;
            fetch_valid <= 1'b0;
        end else begin
            case(cpu_state)
                // IDLE
                IDLE: begin
                    cpu_state <= CPU_RUN;
                    fetch_valid <= 1'b0;
                end
                // CPU Run.
                CPU_RUN: begin
                    fetch_valid <= 1'b1;
                    if (illegal_instruction | i_pf | d_pf)
                        cpu_state <= CPU_TRAP;
                end
                // CPU Trap.
                CPU_TRAP: begin
                    if(execute_ready)
                        cpu_state <= CPU_RUN;
                end
                // CPU Halt.
                CPU_HALT: begin
                    fetch_valid <= 1'b0;
                end
            endcase
        end
    end

    // =====================================
    // Csr module
    // =====================================
    // CSR wire
    wire [31:0] csr_mstatus;  // 使わなければ未接続でもOK
    wire [31:0] csr_medeleg;
    wire [31:0] csr_mie;
    wire [31:0] csr_mip;
    wire [31:0] csr_mtvec;
    wire [31:0] csr_mepc;
    wire [31:0] csr_mcause;

    wire [31:0] csr_sstatus;  
    wire [31:0] csr_stvec;
    wire [31:0] csr_sepc;
    wire [31:0] csr_scause;
    wire [31:0] csr_stval;

    // Privilege level encoding (RISC-V spec)
    localparam [1:0] PRIV_U = 2'b00;
    localparam [1:0] PRIV_S = 2'b01;
    localparam [1:0] PRIV_M = 2'b11;

    // トラップ入口/出口 (Supervisor側) 
    wire        ecall_u     = is_ecall && (priv_mode == PRIV_U);
    wire        ecall_s     = is_ecall && (priv_mode == PRIV_S);
    wire        ecall_m     = is_ecall && (priv_mode == PRIV_M);

    wire        set_trap    = is_ecall || illegal_instruction || i_pf || d_pf;

    wire [31:0] trap_sepc   = pc;

    wire [31:0] execute_vaddr;
    wire [31:0] trap_stval = i_pf ? pc :
                             d_pf ? execute_vaddr :
                             32'h0;

    wire [31:0] trap_scause =
                            ecall_u             ? 32'd8  :
                            ecall_s             ? 32'd9  :
                            illegal_instruction ? 32'd2  :
                            i_pf                ? 32'd12 :
                            d_pf                ? (is_store ? 32'd15 : 32'd13) :
                                                32'd0;

    wire        timer_irq_request = timer_irq_ext && csr_mstatus[3] && csr_mie[7];
    wire        timer_irq_take;
    reg         timer_irq_active;
    wire        set_mtrap   = (ecall_m && csr_enb) || timer_irq_take;
    wire [31:0] trap_mepc   = pc;
    wire [31:0] trap_mcause = timer_irq_take ? 32'h8000_0007 :
                                ecall_m      ? 32'd11 : 32'd0;

    // ペンディング入力（mip制御）
    wire        set_msip   = 1'b0, clr_msip = 1'b0;
    wire        set_mtip   = timer_irq_ext, clr_mtip = !timer_irq_ext;
    wire        set_meip   = 1'b0, clr_meip = 1'b0;

    // Execute wire
    wire [31:0] alu_data;
    wire        do_sret;
    wire        do_mret;
    wire        is_ecall;
    wire        pc_sel2;

    // =====================================
    // CSRインスタンス（修正後）
    // =====================================
    // CSR
    wire        csr_enb;
    wire        csr_valid;
    wire [31:0] csr_rdata;

    // CSR wire
    wire        csr_wr;          // CSRRW/CSRRS/CSRRC
    wire [1:0]  csr_cmd;         // 0:RW, 1:RS, 2:RC
    wire        csr_use_imm;     // *I 版（zimm使用）
    wire [11:0] csr_addr;        // CSR address
    wire [4:0]  csr_zimm;
    wire [31:0] csr_satp; 
    wire [1:0]  priv_mode;

    wire [31:0] csr_reg_data_1;

    Csr u_csr (
        .clock              (clock),
        .reset_n            (reset_n),
        .csr_enb            (csr_enb),
        .csr_valid          (csr_valid),    // 次サイクルでcsrレジスタを反映.

        // ==== CSR命令実行側（パイプラインから）====
        .csr_wr             (csr_wr),
        .csr_cmd            (csr_cmd),
        .csr_use_imm        (csr_use_imm),
        .csr_addr           (csr_addr),
        .csr_rs1_val        (csr_reg_data_1),
        .csr_zimm           (csr_zimm),
        .csr_rdata          (csr_rdata),

        // ==== トラップ入口/出口 (Supervisor側) ====
        .set_trap           (set_trap),           
        .trap_sepc          (trap_sepc),
        .trap_scause        (trap_scause),
        .trap_stval         (trap_stval),
        .do_sret            (do_sret),

        // ==== トラップ入口/出口 (Machine側, 将来用/デバッグ用) ====
        .set_mtrap          (set_mtrap),
        .trap_mepc          (trap_mepc),
        .trap_mcause        (trap_mcause),
        .do_mret            (do_mret),

        .set_msip    (set_msip),    .clr_msip (clr_msip),
        .set_mtip    (set_mtip),    .clr_mtip (clr_mtip),
        .set_meip    (set_meip),    .clr_meip (clr_meip),

        // current privilege mode
        .priv_mode          (priv_mode),

        // Mレベル: デバッグ/将来用
        .out_mstatus        (csr_mstatus),
        .out_medeleg        (csr_medeleg),
        .out_mie            (csr_mie),
        .out_mip            (csr_mip),
        .out_mtvec          (csr_mtvec),
        .out_mepc           (csr_mepc),
        .out_mcause         (csr_mcause),

        // Sレベル: OSで実際に使う
        .out_sstatus        (csr_sstatus),
        .out_stvec          (csr_stvec),           // パイプラインが「例外発生！」と判断した瞬間、次にフェッチすべきPCは stvec のベースアドレス。今は不使用でいい
        .out_sepc           (csr_sepc),            // sret を検出した段階でPCを out_sepc に切り替える。今は不使用でいい
        .out_scause         (csr_scause),
        .out_stval          (csr_stval),
        .out_satp           (csr_satp),

        // DATA Cache
        .out_DCACHE_CTRL    (csr_DCACHE_CTRL),
        
        // DMA
        .out_DMA_CTRL       (csr_DMA_CTRL),
        .out_DMA_WORDS      (csr_DMA_WORDS),
        .out_DMA_SRC        (csr_DMA_SRC),
        .out_DMA_DST        (csr_DMA_DST),
        .in_DMA_STATUS      (csr_DMA_STATUS),

        // SynapEngine
        .out_SA_CTRL        (csr_SA_CTRL),
        .out_SA_MODE        (csr_SA_MODE),
        .in_SA_STATUS       (csr_SA_STATUS),
        .out_SA_ADDR_A      (csr_SA_ADDR_A),
        .out_SA_ADDR_B      (csr_SA_ADDR_B),
        .out_SA_ADDR_C      (csr_SA_ADDR_C),

        // CPU MONITOR
        .out_CPU_MON_CTRL   (csr_CPU_MON_CTRL),
        .in_CPU_MON_CYCLE   (csr_CPU_MON_CYCLE)
    );

    // =====================================
    // Fetch State
    // =====================================
    // wire
    wire [31:0] opcode;
    wire [31:0] fifo_opcode_data;
    wire        fifo_empty;
    wire        fifo_full;
    wire        fifo_flush_sig;
    wire        fifo_read_ready;
    wire        execute_ready;
    wire        execute_idle;
    wire        execute_fifo_flush_sig;
    wire        fifo_read_state_sig;
    wire        is_load, is_store;
    wire        is_sfence_vma;

    // MMU fault
    wire        i_pf;

    // Program Counter
    wire [31:0] fetch_pc = pc;

    PSC_RV32ISP_Fetch u_fetch_state(
        // clock, reset
        .clock                      (clock),
        .reset_n                    (reset_n),
        .cpu_stop                   (cpu_stop),
        // in,out
        .fetch_valid                (fetch_valid),
        .fetch_ready                (fetch_ready),
        // An interrupt can be accepted while Execute is already IDLE, so
        // use the accept pulse to complete the fetch FIFO flush as well.
        .execute_ready              (execute_ready | timer_irq_take | timer_irq_active),
        // fifo sig.
        .fifo_empty                 (fifo_empty),
        .fifo_full                  (fifo_full),
        .fifo_read_valid            (fifo_read_state_sig),
        .fifo_read_ready            (fifo_read_ready),
        .fifo_flush                 (fifo_flush_sig),
        // other sig.
        .pc                         (fetch_pc),
        .csr_satp                   (csr_satp),
        .priv_mode                  (priv_mode),
        .is_load                    (is_load),
        .is_store                   (is_store),
        .is_sfence_vma              (is_sfence_vma),
        .fifo_ready                 (),
        // MMU fault sig.
        .i_pf                       (i_pf),
        // to memory
        .program_mem_read_valid     (program_mem_read_valid),
        .program_mem_read_ready     (program_mem_read_ready),
        .program_mem_read_address   (program_mem_read_address),
        .program_mem_read_data      (program_mem_read_data),
        .program_mem_req_ready      (program_mem_req_ready),
        // MMU port
        .data_mem_read_valid        (mmu_data_mem_read_valid), 
        .data_mem_read_ready        (mmu_data_mem_read_ready),
        .data_mem_read_address      (mmu_data_mem_read_address),
        .data_mem_read_data         (mmu_data_mem_read_data),
        .data_mem_read_req_ready    (mmu_data_req_ready),
        // opcode
        .opcode                     (opcode),   // 未使用.
        .fifo_opcode_data           (fifo_opcode_data)
    );

    // =====================================
    // Execute State
    // =====================================
    // wire
    wire [31:0] imm;
    wire [4:0] alucon;
    wire [2:0] funct3;
    wire op1sel, op2sel, mem_rw, rf_wen;
    wire [1:0] pc_sel;

    // fifo
    wire        execute_state_sig;  // not used

    // MMU fault
    wire        d_pf;
    wire        illegal_instruction;

    PSC_RV32ISP_Execute u_execute_state(
        // clock, reset
        .clock                      (clock),
        .reset_n                    (reset_n),
        .cpu_stop                   (cpu_stop),
        .cpu_trap                   (cpu_state==CPU_TRAP),
        .timer_irq_request          (timer_irq_request && !timer_irq_active),
        // in,out
        .execute_valid              (!fifo_empty),
        .execute_ready              (execute_ready),
        .execute_idle               (execute_idle),
        // fifo sig.
        .fifo_read_state_sig        (fifo_read_state_sig),
        .execute_state_sig          (execute_state_sig),
        .fifo_read_ready            (fifo_read_ready),
        .fifo_flush_sig             (execute_fifo_flush_sig),
        // other sig.
        .pc                         (pc),
        .opcode                     (fifo_opcode_data),
        .csr_satp                   (csr_satp),
        .priv_mode                  (priv_mode),
        .alu_data                   (alu_data),
        .is_load                    (is_load),
        .is_store                   (is_store),
        .is_sfence_vma              (is_sfence_vma),
        .pc_sel2                    (pc_sel2),
        .is_ecall                   (is_ecall),
        .do_mret                    (do_mret),
        .do_sret                    (do_sret),
        // CSR sig.
        .csr_enb                    (csr_enb),
        .csr_valid                  (csr_valid),
        // CSR
        .csr_wr                     (csr_wr),
        .csr_cmd                    (csr_cmd),
        .csr_use_imm                (csr_use_imm),
        .csr_addr                   (csr_addr),
        .csr_zimm                   (csr_zimm),
        .csr_rdata                  (csr_rdata),
        .csr_reg_data_1             (csr_reg_data_1),
        // cache sig.
        .is_fence_i                 (is_fence_i),
        // MMU fault sig.
        .d_pf                       (d_pf),
        .illegal_instruction        (illegal_instruction),
        // to memory
        .data_mem_read_valid        (data_mem_read_valid),
        .data_mem_read_ready        (data_mem_read_ready),
        .data_mem_read_address      (data_mem_read_address),
        .data_mem_read_data         (data_mem_read_data),
        .data_mem_write_valid       (data_mem_write_valid),
        .data_mem_write_ready       (data_mem_write_ready),
        .data_mem_write_address     (mem_write_address),
        .data_mem_write_data        (mem_write_data),
        .mem_write_sel              (mem_write_sel),
        .data_mem_req_ready         (data_mem_req_ready),
        // vaddr for stval
        .vaddr                      (execute_vaddr),
        .uart_out                   (uart_out)
    );

    // =====================================
    // NEXT PC
    // =====================================
    assign timer_irq_take = timer_irq_request && !timer_irq_active && execute_idle;
    assign fifo_flush_sig = execute_fifo_flush_sig || timer_irq_take;

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n || cpu_stop)
            timer_irq_active <= 1'b0;
        else if (!timer_irq_ext)
            timer_irq_active <= 1'b0;
        else if (timer_irq_take)
            timer_irq_active <= 1'b1;
    end

    wire exception = is_ecall | illegal_instruction | d_pf | i_pf;
    wire interrupt = timer_irq_take;

    wire trap = exception | interrupt;
    wire trap_deleg_to_s = (priv_mode != PRIV_M) && csr_medeleg[trap_scause];

    wire [31:0] trap_pc = (!interrupt && trap_deleg_to_s) ? csr_stvec : csr_mtvec;
    wire [31:0] branch_target_pc = {alu_data[31:1], 1'b0};  // JALR/JAL/branch用
    wire [31:0] seq_pc           = pc + 32'd4;              // 順次実行用
    wire [31:0] sret_pc          = csr_sepc;                // Csr からの戻り先

    // trap save pc
    reg  [31:0] trap_pc_latch;
    always @(posedge clock) begin
        if (execute_ready) begin
            trap_pc_latch <= 32'd0;
        end else begin
            if (trap) begin
                if (trap_deleg_to_s)
                    trap_pc_latch <= csr_stvec;
                else
                    trap_pc_latch <= csr_mtvec;
            end
        end
    end

    wire [31:0] next_pc;
    assign next_pc = (do_mret)              ? csr_mepc :      // ★ M-mode return
                     (do_sret)              ? sret_pc :
                     (interrupt)            ? csr_mtvec :
                     (trap)                 ? trap_pc_latch :
                     (cpu_state==CPU_TRAP)  ? trap_pc_latch : 
                     (pc_sel2 == 1'b1)      ? branch_target_pc :
                                              seq_pc;

    // NEXT PC WRITE BACK and CYCLE COUNTER
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            pc      <= 32'b0;
            counter <= 32'b0;
        end else if(cpu_stop) begin
            pc      <= 32'b0;
            counter <= 32'b0;
        end else begin
            if(timer_irq_take) begin
                pc      <= csr_mtvec;
                counter <= counter + 1;
            end else if(execute_ready) begin
                pc      <= next_pc;
                counter <= counter + 1;
            end
        end
    end

endmodule
