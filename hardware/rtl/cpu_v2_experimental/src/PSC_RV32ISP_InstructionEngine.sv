// NISHIHARU

import PSC_Types::*;

module PSC_RV32ISP_InstructionEngine #(
    parameter logic [31:0] UART_MMIO_ADDR    = 32'hF004_00F0,
    parameter logic [31:0] UART_MMIO_FLAG    = 32'hF004_00F4,
    parameter logic [31:0] COUNTER_MMIO_ADDR = 32'hF004_FFF0
)(
    input  logic        clock,
    input  logic        reset_n,
    input  logic        cpu_stop,
    input  logic [3:0]  cpu_state,
    input  logic        cpu_trap,

    input  logic        fifo_req_ready,
    output logic        execute_task_busy,
    output logic        execute_task_done,

    output logic        fifo_read_state_sig,
    output logic        execute_state_sig,
    input  logic        fifo_read_ready,
    output logic        fifo_flush_sig,

    output logic [31:0] pc,
    output logic [31:0] counter,

    input  logic [31:0] opcode,
    input  logic [31:0] pc_now,
    input  logic [31:0] csr_satp,
    input  logic [1:0]  priv_mode,
    output logic [31:0] alu_data,
    output logic        pc_sel2,
    output dec_ctrl_t   decoder_ctrl,
    input  logic        i_pf,
    output logic        d_pf,
    input  logic        i_pf_event,
    input  logic        d_pf_event,
    output logic [31:0] data_fault_pc,
    output logic [31:0] data_fault_vaddr,
    output logic        data_fault_is_store,
    input  logic [4:0]  trap_scause,

    input  csr_state_t  csr_state,
    output logic        csr_enb,
    output logic        csr_valid,
    input  logic [31:0] csr_rdata,
    output logic [31:0] csr_reg_data_1,

    output logic        data_mem_read_valid,
    input  logic        data_mem_read_ready,
    output logic [31:0] data_mem_read_address,
    input  logic [31:0] data_mem_read_data,
    input  logic        data_mem_req_ready,

    output logic        data_mem_write_valid,
    input  logic        data_mem_write_ready,
    output logic [31:0] data_mem_write_address,
    output logic [31:0] data_mem_write_data,
    output logic [2:0]  mem_write_sel,

    output logic [31:0] vaddr,
    output logic [8:0]  uart_out
);

    logic       decode_enb;
    logic       decode_done;
    dec_ctrl_t  decoded_ctrl;

    logic       execute_valid;
    dec_ctrl_t  execute_ctrl;
    logic [31:0] execute_reg_data_1;
    logic [31:0] execute_reg_data_2;
    logic [31:0] execute_alu_data;
    logic       execute_done;

    dec_ctrl_t  memory_ctrl;
    logic [31:0] memory_alu_data;
    logic [31:0] memory_reg_data_1;
    logic [31:0] memory_reg_data_2;
    logic [31:0] memory_pc;
    logic       load_valid;
    logic       store_valid;
    logic       load_done;
    logic       store_done;
    logic [31:0] load_read_data;

    dec_ctrl_t  commit_ctrl;
    logic [31:0] commit_alu_data;
    logic       commit_branch_taken;

    logic       load_data_mem_read_valid;
    logic       load_mmu_valid;
    logic [31:0] load_data_mem_read_address;
    logic [31:0] load_vaddr;
    logic       load_branch_unused;

    logic       store_mmu_valid;
    logic [31:0] store_vaddr;
    logic [31:0] store_mem_write_address;
    logic [31:0] store_wdata_unused;

    logic       d_mmu_mem_valid;
    logic       d_mmu_done;
    logic       d_mode_sv32;
    logic [31:0] d_mmu_mem_addr;
    logic [31:0] d_paddr;
    logic       d_mmu_enb;
    logic       cpu_state_done;

    logic [31:0] raw_load_data;
    logic        is_counter_load;
    logic        is_uart_flag_load;

    assign execute_state_sig = execute_valid;
    assign decoder_ctrl      = commit_ctrl;
    assign alu_data          = commit_alu_data;
    assign pc_sel2           = commit_branch_taken;
    assign mem_write_sel     = memory_ctrl.funct3;

    assign is_counter_load = (memory_ctrl.funct3 == 3'b010) &&
                             (memory_alu_data == COUNTER_MMIO_ADDR);
    assign is_uart_flag_load = !memory_ctrl.funct3[1:0] &&
                               (memory_alu_data == UART_MMIO_FLAG);
    assign raw_load_data = is_counter_load   ? counter :
                           is_uart_flag_load ? 32'd1 : data_mem_read_data;
    assign load_read_data = raw_load_data;

    assign vaddr = load_valid  ? load_vaddr  :
                   store_valid ? store_vaddr : 32'd0;
    assign data_fault_pc       = memory_pc;
    assign data_fault_vaddr    = memory_alu_data;
    assign data_fault_is_store = memory_ctrl.is_store;

    assign d_mmu_enb = (load_mmu_valid || store_mmu_valid) &&
                       (memory_ctrl.is_load || memory_ctrl.is_store);
    assign cpu_state_done = load_done || store_done;

    assign data_mem_read_valid = d_mmu_mem_valid |
                                 load_data_mem_read_valid;
    assign data_mem_read_address = d_mmu_mem_valid
                                  ? d_mmu_mem_addr
                                  : load_data_mem_read_address;
    assign data_mem_write_address = store_mem_write_address;

    PSC_InstructionUnit u_inst_unit (
        .clock                  (clock),
        .reset_n                (reset_n),
        .cpu_stop               (cpu_stop),
        .cpu_trap               (cpu_trap),
        .priv_mode              (priv_mode),
        .pc                     (pc),
        .counter                (counter),
        .opcode                 (opcode),
        .pc_now                 (pc_now),
        .fifo_req_ready         (fifo_req_ready),
        .fifo_read_ready        (fifo_read_ready),
        .fifo_read_valid        (fifo_read_state_sig),
        .fifo_flush             (fifo_flush_sig),
        .decoded_ctrl           (decoded_ctrl),
        .decode_enb             (decode_enb),
        .decode_done            (decode_done),
        .execute_valid          (execute_valid),
        .execute_ctrl           (execute_ctrl),
        .execute_reg_data_1     (execute_reg_data_1),
        .execute_reg_data_2     (execute_reg_data_2),
        .execute_alu_data       (execute_alu_data),
        .execute_done           (execute_done),
        .memory_ctrl            (memory_ctrl),
        .memory_alu_data        (memory_alu_data),
        .memory_reg_data_1      (memory_reg_data_1),
        .memory_reg_data_2      (memory_reg_data_2),
        .memory_pc              (memory_pc),
        .load_valid             (load_valid),
        .store_valid            (store_valid),
        .load_done              (load_done),
        .store_done             (store_done),
        .load_read_data         (load_read_data),
        .csr_state              (csr_state),
        .csr_rdata              (csr_rdata),
        .csr_reg_data_1         (csr_reg_data_1),
        .csr_enb                (csr_enb),
        .csr_valid              (csr_valid),
        .commit_ctrl            (commit_ctrl),
        .commit_alu_data        (commit_alu_data),
        .commit_branch_taken    (commit_branch_taken),
        .d_pf                   (d_pf),
        .i_pf                   (i_pf),
        .d_pf_event             (d_pf_event),
        .i_pf_event             (i_pf_event),
        .trap_scause            (trap_scause),
        .execute_task_busy      (execute_task_busy),
        .execute_task_done      (execute_task_done)
    );

    Decorder u_Decorder (
        .clock        (clock),
        .reset_n      (reset_n),
        .decode_enb   (decode_enb),
        .opcode       (opcode),
        .in_pc        (pc_now),
        .current_priv (priv_mode),
        .decode_done  (decode_done),
        .decoder_ctrl (decoded_ctrl)
    );

    Execute #(
        .ENABLE_MUL (1'b1),
        .ENABLE_DIV (1'b1)
    ) u_execute (
        .clock          (clock),
        .reset_n        (reset_n),
        .execute_enb    (execute_valid),
        .decoder_ctrl   (execute_ctrl),
        .reg_data_addr1 (execute_reg_data_1),
        .reg_data_addr2 (execute_reg_data_2),
        .alu_data       (execute_alu_data),
        .r_data1        (),
        .r_data2        (),
        .out_pc         (),
        .busy           (),
        .done           (execute_done)
    );

    // The load engine owns only the variable-latency read transaction.
    // Branch decisions are made combinationally from the same memory-stage
    // record in PSC_InstructionUnit.
    Branch u_load (
        .clock                 (clock),
        .reset_n               (reset_n),
        .branch_enb            (load_valid),
        .decoder_ctrl          (memory_ctrl),
        .in_vaddr              (memory_alu_data),
        .r_data1               (memory_reg_data_1),
        .r_data2               (memory_reg_data_2),
        .mmu_valid             (load_mmu_valid),
        .vaddr                 (load_vaddr),
        .mmu_ready             (d_mmu_done),
        .access_fault          (d_pf),
        .d_paddr               (d_paddr),
        .data_mem_read_address (load_data_mem_read_address),
        .data_mem_read_valid   (load_data_mem_read_valid),
        .data_mem_req_ready    (data_mem_req_ready),
        .data_mem_read_ready   (data_mem_read_ready),
        .pc_sel2               (load_branch_unused),
        .busy                  (),
        .branch_done           (load_done)
    );

    MemoryStore #(
        .UART_MMIO_ADDR    (UART_MMIO_ADDR),
        .UART_MMIO_FLAG    (UART_MMIO_FLAG),
        .COUNTER_MMIO_ADDR (COUNTER_MMIO_ADDR)
    ) u_store (
        .clock                  (clock),
        .reset_n                (reset_n),
        .store_enb              (store_valid),
        .mode_sv32              (d_mode_sv32),
        .decoder_ctrl           (memory_ctrl),
        .alu_data               (memory_alu_data),
        .mem_val                (memory_ctrl.funct3),
        .mem_read_data          (32'd0),
        .r_data2                (memory_reg_data_2),
        .in_pc                  (memory_pc),
        .counter                (counter),
        .ld_low2                (memory_alu_data[1:0]),
        .csr_rdata              (csr_rdata),
        .mmu_valid              (store_mmu_valid),
        .vaddr                  (store_vaddr),
        .mmu_ready              (d_mmu_done),
        .access_fault           (d_pf),
        .d_paddr                (d_paddr),
        .data_mem_write_address (store_mem_write_address),
        .data_mem_write_valid   (data_mem_write_valid),
        .data_mem_write_data    (data_mem_write_data),
        .data_mem_write_ready   (data_mem_write_ready),
        .data_mem_req_ready     (data_mem_req_ready),
        .uart                   (uart_out),
        .w_data                 (store_wdata_unused),
        .busy                   (),
        .store_done             (store_done)
    );

    MMU u_mmu_d (
        .clk            (clock),
        .reset_n        (reset_n),
        .MMU_enb        (d_mmu_enb),
        .vaddr          (vaddr),
        .satp           (csr_satp),
        .priv_mode      (priv_mode),
        .access_r       (memory_ctrl.is_load),
        .access_w       (memory_ctrl.is_store),
        .access_x       (1'b0),
        .mem_req_ready  (data_mem_req_ready),
        .mem_rdata      (data_mem_read_data),
        .mem_addr       (d_mmu_mem_addr),
        .mem_valid      (d_mmu_mem_valid),
        .mem_ready      (data_mem_read_ready),
        .cpu_state_done (cpu_state_done),
        .sfence_vma     (fifo_flush_sig && commit_ctrl.is_sfence_vma),
        .paddr          (d_paddr),
        .page_fault     (d_pf),
        .mode_sv32      (d_mode_sv32),
        .mmu_done       (d_mmu_done)
    );

endmodule
