// NISHIHARU

import PSC_Types::*;

module PSC_RV32_InstructionEngine #(
    parameter logic [31:0] UART_MMIO_ADDR    = 32'hF004_00F0,
    parameter logic [31:0] UART_MMIO_FLAG    = 32'hF004_00F4,
    parameter logic [31:0] COUNTER_MMIO_ADDR = 32'hF004_FFF0
)(
    input  logic        clock,
    input  logic        reset_n,
    input  logic        cpu_stop,
    input  logic [3:0]  cpu_state,
    input  logic        cpu_trap,

    input  logic        timer_irq_ext,
    output logic        branch_resolve_valid,
    output logic        branch_resolve_taken,
    output logic [31:0] branch_resolve_pc,
    output logic [31:0] branch_resolve_target,

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
    output logic        data_fault_misaligned,
    input  logic [4:0]  trap_scause,

    input  csr_state_t  csr_state,
    output logic        csr_enb,
    output logic        csr_valid,
    output logic        timer_irq_take,
    input  logic [31:0] csr_rdata,
    output logic [11:0] csr_read_addr,
    output logic [31:0] csr_old_value,
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

    logic decode_enb;
    logic decode_done;
    dec_ctrl_t   decoded_ctrl;

    logic execute_valid;
    dec_ctrl_t   execute_ctrl;
    logic [31:0] execute_reg_data_1;
    logic [31:0] execute_reg_data_2;
    logic [31:0] execute_alu_data;
    logic execute_done;

    dec_ctrl_t   memory_ctrl;
    logic [31:0] memory_alu_data;
    logic [31:0] memory_reg_data_1;
    logic [31:0] memory_reg_data_2;
    logic [31:0] memory_pc;
    logic load_valid;
    logic store_valid;
    logic load_done;
    logic store_done;
    logic [31:0] load_read_data;

    dec_ctrl_t   commit_ctrl;
    logic [31:0] commit_alu_data;
    logic commit_branch_taken;

    logic d_mmu_mem_valid;
    logic d_mmu_done;
    logic d_mmu_fault;
    logic d_mode_sv32;
    logic [31:0] d_mmu_mem_addr;
    logic [31:0] d_paddr;
    logic d_mmu_enb;
    logic cpu_state_done;

    logic [31:0] raw_load_data;
    logic is_counter_load;
    logic is_uart_flag_load;

    logic mem_access;
    logic mem_pending;
    logic mem_mmu_valid;
    logic mem_read_valid, mem_write_valid;
    logic [31:0] mem_address, mem_write_data;
    logic mem_done;
    logic [8:0] mem_uart;

    assign mem_access             = load_valid || store_valid;
    assign load_done              = load_valid && mem_done;
    assign store_done             = store_valid && mem_done;
    assign d_pf                   = d_mmu_fault || data_fault_misaligned;

    Branch #(
        .UART_MMIO_ADDR       (UART_MMIO_ADDR)
    ) u_memory (
        .clock                (clock),
        .reset_n              (reset_n),
        .cpu_stop             (cpu_stop),
        .valid                (mem_access),
        .decoder_ctrl         (memory_ctrl),
        .in_vaddr             (memory_alu_data),
        .r_data2              (memory_reg_data_2),
        .mode_sv32            (d_mode_sv32),
        .mmu_valid            (mem_mmu_valid),
        .mmu_ready            (d_mmu_done),
        .access_fault         (d_mmu_fault),
        .d_paddr              (d_paddr),
        .data_mem_address     (mem_address),
        .data_mem_write_data  (mem_write_data),
        .data_mem_read_valid  (mem_read_valid),
        .data_mem_write_valid (mem_write_valid),
        .data_mem_req_ready   (data_mem_req_ready),
        .data_mem_read_ready  (data_mem_read_ready),
        .data_mem_write_ready (data_mem_write_ready),
        .uart                 (mem_uart),
        .pending              (mem_pending),
        .done                 (mem_done),
        .misaligned_fault     (data_fault_misaligned)
    );

    assign execute_state_sig      = execute_valid;
    assign decoder_ctrl           = commit_ctrl;
    assign alu_data               = commit_alu_data;
    assign pc_sel2                = commit_branch_taken;
    assign mem_write_sel          = memory_ctrl.funct3;

    assign is_counter_load        = (memory_ctrl.funct3 == 3'b010) &&
                                (memory_alu_data == COUNTER_MMIO_ADDR);
    assign is_uart_flag_load      = !memory_ctrl.funct3[1:0] &&
                                (memory_alu_data == UART_MMIO_FLAG);
    assign raw_load_data          = is_counter_load   ? counter :
                           is_uart_flag_load ? 32'd1 : data_mem_read_data;
    assign load_read_data         = raw_load_data;

    assign vaddr                  = memory_alu_data;
    assign data_fault_pc          = memory_pc;
    assign data_fault_vaddr       = memory_alu_data;
    assign data_fault_is_store    = memory_ctrl.is_store;

    assign d_mmu_enb              = mem_mmu_valid && mem_access;
    assign cpu_state_done         = load_done || store_done || (d_pf && d_mmu_done);

    assign data_mem_read_valid    = d_mmu_mem_valid |
                                 mem_read_valid;
    assign data_mem_read_address  = d_mmu_mem_valid
                                  ? d_mmu_mem_addr
                                  : mem_address;
    assign data_mem_write_address = mem_address;
    assign data_mem_write_valid   = mem_write_valid;
    assign data_mem_write_data    = mem_write_data;
    assign uart_out               = mem_uart;

    PSC_InstructionUnit u_inst_unit (
        .clock                (clock),
        .reset_n              (reset_n),
        .cpu_stop             (cpu_stop),
        .cpu_trap             (cpu_trap),
        .timer_irq_ext        (timer_irq_ext),
        .branch_resolve_valid (branch_resolve_valid),
        .branch_resolve_taken (branch_resolve_taken),
        .branch_resolve_pc    (branch_resolve_pc),
        .branch_resolve_target (branch_resolve_target),
        .priv_mode            (priv_mode),
        .pc                   (pc),
        .counter              (counter),
        .opcode               (opcode),
        .pc_now               (pc_now),
        .fifo_req_ready       (fifo_req_ready),
        .fifo_read_ready      (fifo_read_ready),
        .fifo_read_valid      (fifo_read_state_sig),
        .fifo_flush           (fifo_flush_sig),
        .decoded_ctrl         (decoded_ctrl),
        .decode_enb           (decode_enb),
        .decode_done          (decode_done),
        .execute_valid        (execute_valid),
        .execute_ctrl         (execute_ctrl),
        .execute_reg_data_1   (execute_reg_data_1),
        .execute_reg_data_2   (execute_reg_data_2),
        .execute_alu_data     (execute_alu_data),
        .execute_done         (execute_done),
        .memory_ctrl          (memory_ctrl),
        .memory_alu_data      (memory_alu_data),
        .memory_reg_data_1    (memory_reg_data_1),
        .memory_reg_data_2    (memory_reg_data_2),
        .memory_pc            (memory_pc),
        .load_valid           (load_valid),
        .store_valid          (store_valid),
        .load_done            (load_done),
        .store_done           (store_done),
        .load_read_data       (load_read_data),
        .csr_state            (csr_state),
        .csr_rdata            (csr_rdata),
        .csr_read_addr        (csr_read_addr),
        .csr_old_value        (csr_old_value),
        .csr_reg_data_1       (csr_reg_data_1),
        .csr_enb              (csr_enb),
        .csr_valid            (csr_valid),
        .timer_irq_take       (timer_irq_take),
        .commit_ctrl          (commit_ctrl),
        .commit_alu_data      (commit_alu_data),
        .commit_branch_taken  (commit_branch_taken),
        .d_pf                 (d_pf),
        .i_pf                 (i_pf),
        .d_pf_event           (d_pf_event),
        .i_pf_event           (i_pf_event),
        .trap_scause          (trap_scause),
        .execute_task_busy    (execute_task_busy),
        .execute_task_done    (execute_task_done)
    );

    Decorder u_Decorder (
        .clock                (clock),
        .reset_n              (reset_n),
        .decode_enb           (decode_enb),
        .opcode               (opcode),
        .in_pc                (pc_now),
        .current_priv         (priv_mode),
        .decode_done          (decode_done),
        .decoder_ctrl         (decoded_ctrl)
    );

    Execute #(
        .ENABLE_MUL           (1'b1),
        .ENABLE_DIV           (1'b1)
    ) u_execute (
        .clock                (clock),
        .reset_n              (reset_n),
        .execute_enb          (execute_valid),
        .decoder_ctrl         (execute_ctrl),
        .reg_data_addr1       (execute_reg_data_1),
        .reg_data_addr2       (execute_reg_data_2),
        .alu_data             (execute_alu_data),
        .r_data1              (),
        .r_data2              (),
        .out_pc               (),
        .busy                 (),
        .done                 (execute_done)
    );

    MMU u_mmu_d (
        .clk                  (clock),
        .reset_n              (reset_n),
        .MMU_enb              (d_mmu_enb),
        .vaddr                (vaddr),
        .satp                 (csr_satp),
        .priv_mode            (priv_mode),
        .access_r             (memory_ctrl.is_load),
        .access_w             (memory_ctrl.is_store),
        .access_x             (1'b0),
        .mem_req_ready        (data_mem_req_ready),
        .mem_rdata            (data_mem_read_data),
        .mem_addr             (d_mmu_mem_addr),
        .mem_valid            (d_mmu_mem_valid),
        .mem_ready            (data_mem_read_ready),
        .cpu_state_done       (cpu_state_done),
        .sfence_vma           (fifo_flush_sig && commit_ctrl.is_sfence_vma),
        .paddr                (d_paddr),
        .page_fault           (d_mmu_fault),
        .mode_sv32            (d_mode_sv32),
        .mmu_done             (d_mmu_done)
    );

endmodule
