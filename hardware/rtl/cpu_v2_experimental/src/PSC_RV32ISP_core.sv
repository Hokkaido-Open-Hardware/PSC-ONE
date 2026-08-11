// NISHIHARU
`timescale 1ns / 1ps

import PSC_Types::*;

module PSC_RV32ISP_core #(
    parameter logic [31:0] UART_MMIO_ADDR    = 32'hF004_00F0,     // 未使用.
    parameter logic [31:0] UART_MMIO_FLAG    = 32'hF004_00F4,
    parameter logic [31:0] COUNTER_MMIO_ADDR = 32'hF004_FFF0
)(
    input logic              clock,
    input logic              reset_n,
    input logic              cpu_stop,
    input logic              irq_ext,     // TBD
    // Program
    output logic             program_mem_read_valid,
    input  logic             program_mem_read_ready,
    output logic [31:0]      program_mem_read_address,
    input  logic [31:0]      program_mem_read_data,
    input  logic             program_mem_req_ready,
    // Data
    output logic             data_mem_read_valid,
    input  logic             data_mem_read_ready,
    output logic [31:0]      data_mem_read_address,
    input  logic [31:0]      data_mem_read_data,
    input  logic             data_mem_req_ready,
    
    output logic             data_mem_write_valid,    
    input  logic             data_mem_write_ready,
    output logic  [2:0]      mem_write_sel,
    output logic [31:0]      mem_write_address,
    output logic [31:0]      mem_write_data,
    // MMU
    output logic             mmu_data_mem_read_valid,
    input  logic             mmu_data_mem_read_ready,
    output logic [31:0]      mmu_data_mem_read_address,
    input  logic [31:0]      mmu_data_mem_read_data,
    input  logic             mmu_data_req_ready,
    // Cashe 
    output logic             is_fence_i,
    // DATA Cache
    output logic [31:0]      csr_DCACHE_CTRL,
    // DMA
    output logic [31:0]      csr_DMA_CTRL,
    output logic [31:0]      csr_DMA_WORDS,
    output logic [31:0]      csr_DMA_SRC,
    output logic [31:0]      csr_DMA_DST,
    input  logic [31:0]      csr_DMA_STATUS,
    // SynapEngine
    output logic [31:0]      csr_SA_CTRL,
    output logic [31:0]      csr_SA_MODE,
    input  logic [31:0]      csr_SA_STATUS,
    output logic [31:0]      csr_SA_ADDR_A,
    output logic [31:0]      csr_SA_ADDR_B,
    output logic [31:0]      csr_SA_ADDR_C,
    // CPU Monitor
    output logic [31:0]      csr_CPU_MON_CTRL,
    input  logic [31:0]      csr_CPU_MON_CYCLE,
    output logic  [8:0]      uart_out    // not used
);

    dec_ctrl_t decoder_ctrl;

    `ifdef COCOTB_SIM
    `ifdef CPU_CORE_SIM
    initial begin
        `ifdef DUMP_VCD
        $display("COCOTB_SIM CPU CORE DUMP_VCD ENABLE");
        $dumpfile("./wave/PSC_RV32ISP_V2_core.vcd");
        $dumpvars(0);
        `else
        $display("COCOTB_SIM CPU CORE verilator FST ENABLE");
        $dumpfile("./wave/PSC_RV32ISP_V2_core.fst");
        $dumpvars(0);
        `endif
    end
    `endif
    `endif

    // Program Counter
    logic [31:0] pc;
    logic [31:0] counter;

    // =====================================
    // CPU Main State counter
    // =====================================
    typedef enum logic [3:0] {
        IDLE     = 4'd0,
        CPU_RUN  = 4'd1,
        CPU_TRAP = 4'd2,
        CPU_HALT = 4'd3,
        EXECUTE  = 4'd4     // TBD
    } cpu_state_t;

    cpu_state_t cpu_state;
    logic       fetch_valid;
    logic       fetch_ready;

    always_ff @(posedge clock or negedge reset_n) begin
        if(!reset_n) begin
            cpu_state <= IDLE;
            fetch_valid <= 1'b0;
        end else if(cpu_stop) begin
            cpu_state <= IDLE;
            fetch_valid <= 1'b0;
        end else begin
            unique case (cpu_state)
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
                    if(execute_task_done)
                        cpu_state <= CPU_RUN;
                end
                // CPU Halt.
                CPU_HALT: begin
                    fetch_valid <= 1'b0;
                end

                default: begin
                    cpu_state   <= IDLE;
                    fetch_valid <= 1'b0;
                end
            endcase
        end
    end

    // =====================================
    // Csr module
    // =====================================
    // CSR logic
    csr_state_t csr_state;

    // Privilege level encoding (RISC-V spec)
    localparam logic [1:0] PRIV_U = 2'b00;
    localparam logic [1:0] PRIV_S = 2'b01;
    localparam logic [1:0] PRIV_M = 2'b11;

    // トラップ入口/出口 (Supervisor側) 
    logic        ecall_u;
    logic        ecall_s;
    logic        ecall_m;
    logic        set_trap;
    logic [31:0] trap_sepc;

    assign ecall_u   = decoder_ctrl.is_ecall && (priv_mode == PRIV_U);
    assign ecall_s   = decoder_ctrl.is_ecall && (priv_mode == PRIV_S);
    assign ecall_m   = decoder_ctrl.is_ecall && (priv_mode == PRIV_M);
    assign set_trap  = decoder_ctrl.is_ecall ||
                       decoder_ctrl.raise_illegal_instruction ||
                       i_pf || d_pf;
    assign trap_sepc = pc;

    logic [31:0] execute_vaddr;
    logic [31:0] trap_stval;
    logic [31:0] trap_scause;
    logic        set_mtrap;
    logic [31:0] trap_mepc;
    logic [31:0] trap_mcause;

    assign trap_stval = i_pf ? pc :
                        d_pf ? execute_vaddr :
                               32'h0;

    assign trap_scause =
        ecall_u                                ? 32'd8  :
        ecall_s                                ? 32'd9  :
        decoder_ctrl.raise_illegal_instruction ? 32'd2  :
        i_pf                                   ? 32'd12 :
        d_pf                                   ?
            (decoder_ctrl.is_store ? 32'd15 : 32'd13) :
                                                 32'd0;

    assign set_mtrap   = ecall_m;
    assign trap_mepc   = pc;
    assign trap_mcause = ecall_m ? 32'd11 : 32'd0;

    // ペンディング入力（mip制御）
    logic set_msip, clr_msip;
    logic set_mtip, clr_mtip;
    logic set_meip, clr_meip;

    assign set_msip = 1'b0;
    assign clr_msip = 1'b0;
    assign set_mtip = 1'b0;
    assign clr_mtip = 1'b0;
    assign set_meip = 1'b0;
    assign clr_meip = 1'b0;

    // Execute logic
    logic [31:0] alu_data;
    logic        pc_sel2;

    // =====================================
    // CSRインスタンス（修正後）
    // =====================================
    // CSR
    logic        csr_enb;
    logic        csr_valid;
    logic [31:0] csr_rdata;

    // CSR logic
    logic [1:0]  priv_mode;

    logic [31:0] csr_reg_data_1;

    Csr u_csr (
        .clock              (clock),
        .reset_n            (reset_n),
        .csr_enb            (csr_enb),
        .csr_valid          (csr_valid),    // 次サイクルでcsrレジスタを反映.

        // ==== CSR命令実行側（パイプラインから）====
        .csr_wr             (decoder_ctrl.csr_wr),
        .csr_cmd            (decoder_ctrl.csr_cmd),
        .csr_use_imm        (decoder_ctrl.csr_use_imm),
        .csr_addr           (decoder_ctrl.csr_addr),
        .csr_zimm           (decoder_ctrl.csr_zimm),
        .csr_rs1_val        (csr_reg_data_1),
        .csr_rdata          (csr_rdata),

        // ==== トラップ入口/出口 (Supervisor側) ====
        .set_trap           (set_trap),           
        .trap_sepc          (trap_sepc),
        .trap_scause        (trap_scause),
        .trap_stval         (trap_stval),
        .do_sret            (decoder_ctrl.is_sret),

        // ==== トラップ入口/出口 (Machine側, 将来用/デバッグ用) ====
        .set_mtrap          (set_mtrap),
        .trap_mepc          (trap_mepc),
        .trap_mcause        (trap_mcause),
        .do_mret            (decoder_ctrl.is_mret),

        .set_msip    (set_msip),    .clr_msip (clr_msip),
        .set_mtip    (set_mtip),    .clr_mtip (clr_mtip),
        .set_meip    (set_meip),    .clr_meip (clr_meip),

        // current privilege mode
        .priv_mode          (priv_mode),

        // M-level CSR
        .out_mstatus        (csr_state.mstatus),
        .out_medeleg        (csr_state.medeleg),
        .out_mie            (csr_state.mie),
        .out_mip            (csr_state.mip),
        .out_mtvec          (csr_state.mtvec),
        .out_mepc           (csr_state.mepc),
        .out_mcause         (csr_state.mcause),

        // S-level CSR
        .out_sstatus        (csr_state.sstatus),
        .out_stvec          (csr_state.stvec),
        .out_sepc           (csr_state.sepc),
        .out_scause         (csr_state.scause),
        .out_stval          (csr_state.stval),
        .out_satp           (csr_state.satp),

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
    // logic
    logic [31:0] opcode;
    logic [31:0] fifo_opcode_data;
    logic [31:0] fifo_fetch_pc;
    logic        fifo_req_ready;
    logic        fifo_full;
    logic        fifo_flush_sig;
    logic        fifo_read_ready;
    logic        execute_task_busy;
    logic        execute_task_done;
    logic        fifo_read_state_sig;
    logic        is_sfence_vma;

    assign is_sfence_vma = decoder_ctrl.is_sfence_vma;
    assign is_fence_i = decoder_ctrl.is_fence_i;

    // MMU fault
    logic        i_pf;
    logic        d_pf;

    // Program Counter
    logic [31:0] fetch_pc;

    assign fetch_pc = pc;

    PSC_RV32ISP_FetchUnit u_fetch_unit(
        // clock, reset
        .clock                      (clock),
        .reset_n                    (reset_n),
        .cpu_stop                   (cpu_stop),
        // in,out
        .fetch_valid                (fetch_valid),
        .fetch_ready                (fetch_ready),
        .execute_task_busy          (execute_task_busy),
        .execute_task_done          (execute_task_done),
        // fifo sig.
        .fifo_req_ready             (fifo_req_ready),
        .fifo_full                  (fifo_full),
        .fifo_read_valid            (fifo_read_state_sig),
        .fifo_read_ready            (fifo_read_ready),
        .fifo_flush                 (fifo_flush_sig),
        // other sig.
        .pc                         (fetch_pc),
        .csr_satp                   (csr_state.satp),
        .priv_mode                  (priv_mode),
        .is_load                    (decoder_ctrl.is_load),
        .is_store                   (decoder_ctrl.is_store),
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
        .fifo_opcode_data           (fifo_opcode_data),
        .out_fetch_pc               (fifo_fetch_pc)
    );

    // =====================================
    // Execute State
    // =====================================

    // fifo
    logic        execute_state_sig;  // not used

    // MMU fault
    logic        illegal_instruction;

    assign illegal_instruction = decoder_ctrl.raise_illegal_instruction;

    PSC_RV32ISP_InstructionEngine u_inst_engine(
        // clock, reset
        .clock                      (clock),
        .reset_n                    (reset_n),
        .cpu_stop                   (cpu_stop),
        .cpu_state                  (cpu_state),
        .cpu_trap                   (cpu_state==CPU_TRAP),
        // in,out
        .fifo_req_ready             (fifo_req_ready),
        .execute_task_busy          (execute_task_busy),
        .execute_task_done          (execute_task_done),
        // fifo sig.
        .fifo_read_state_sig        (fifo_read_state_sig),
        .execute_state_sig          (execute_state_sig),
        .fifo_read_ready            (fifo_read_ready),
        .fifo_flush_sig             (fifo_flush_sig),
        // other sig.
        .pc                         (pc),
        .counter                    (counter),

        .opcode                     (fifo_opcode_data),
        .pc_now                     (fifo_fetch_pc),
        .csr_satp                   (csr_state.satp),
        .priv_mode                  (priv_mode),
        .alu_data                   (alu_data),
        .pc_sel2                    (pc_sel2),
        // Decoder
        .decoder_ctrl               (decoder_ctrl),

        // CSR struct
        .csr_state                  (csr_state),
        // CSR sig.
        .csr_enb                    (csr_enb),
        .csr_valid                  (csr_valid),
        // CSR
        .csr_rdata                  (csr_rdata),
        .csr_reg_data_1             (csr_reg_data_1),
        // MMU fault sig.
        .i_pf                       (i_pf),
        .d_pf                       (d_pf),
        .trap_scause                (trap_scause[4:0]),
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

endmodule
