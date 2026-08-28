// NISHIHARU

import PSC_Types::*;

// Small FPGA-oriented out-of-order backend.
//
// Rename uses p0-p31 as the committed architectural bank and p32-p33 as
// speculative slots.  The RAT stores only a valid bit and a ROB-sized slot index;
// precise recovery therefore resets the mapping checkpoint without copying a
// second register file.  Architectural effects occur only at the ROB head.
module PSC_InstructionUnit #(
    parameter int ROB_DEPTH = 2,
    parameter int IQ_DEPTH  = 2,
    parameter int PRF_DEPTH = 32 + ROB_DEPTH,
    parameter int ROB_TAG_W = $clog2(ROB_DEPTH),
    parameter int IQ_IDX_W  = $clog2(IQ_DEPTH),
    parameter int PHY_TAG_W = $clog2(PRF_DEPTH)
)(
    input  logic        clock,
    input  logic        reset_n,
    input  logic        cpu_stop,
    input  logic        cpu_trap,
    input  logic [1:0]  priv_mode,

    output logic [31:0] pc,
    output logic [31:0] counter,
    input  logic [31:0] opcode,
    input  logic [31:0] pc_now,

    input  logic        fifo_req_ready,
    input  logic        fifo_read_ready,
    output logic        fifo_read_valid,
    output logic        fifo_flush,
    input  dec_ctrl_t   decoded_ctrl,
    output logic        decode_enb,
    input  logic        decode_done,

    output logic        alu_execute_valid,
    output dec_ctrl_t   alu_execute_ctrl,
    output logic [31:0] alu_execute_reg_data_1,
    output logic [31:0] alu_execute_reg_data_2,
    input  logic [31:0] alu_execute_data,
    input  logic        alu_execute_done,

    output logic        md_execute_valid,
    output dec_ctrl_t   md_execute_ctrl,
    output logic [31:0] md_execute_reg_data_1,
    output logic [31:0] md_execute_reg_data_2,
    input  logic [31:0] md_execute_data,
    input  logic        md_execute_done,

    output dec_ctrl_t   memory_ctrl,
    output logic [31:0] memory_alu_data,
    output logic [31:0] memory_reg_data_1,
    output logic [31:0] memory_reg_data_2,
    output logic [31:0] memory_pc,
    output logic        load_valid,
    output logic        store_valid,
    input  logic        load_done,
    input  logic        store_done,
    input  logic [31:0] load_read_data,

    input  csr_state_t  csr_state,
    input  logic [31:0] csr_rdata,
    output logic [31:0] csr_reg_data_1,
    output logic        csr_enb,
    output logic        csr_valid,
    output dec_ctrl_t   commit_ctrl,
    output logic [31:0] commit_alu_data,
    output logic        commit_branch_taken,

    input  logic        d_pf,
    input  logic        i_pf,
    input  logic        d_pf_event,
    input  logic        i_pf_event,
    input  logic [4:0]  trap_scause,

    output logic        execute_task_busy,
    output logic        execute_task_done
);

    typedef struct packed {
        logic                 valid;
        logic                 completed;
        logic                 address_ready;
        logic [31:0]          instruction;
        dec_ctrl_t            ctrl;
        // Store data or CSR rs1 value.  These instruction classes are
        // mutually exclusive, so commit never needs two source operands.
        logic [31:0]          side_effect_value;
        logic                 dest_valid;
        logic [PHY_TAG_W-1:0] dest_phys;
        logic [31:0]          result;
        logic                 branch_taken;
        logic [31:0]          branch_target;
        logic                 exception_valid;
        logic [4:0]           exception_cause;
        logic [31:0]          exception_tval;
    } rob_entry_t;

    typedef struct packed {
        logic                 valid;
        logic [ROB_TAG_W-1:0] rob_tag;
        logic                 src1_ready;
        logic [31:0]          src1_value;
        logic [PHY_TAG_W-1:0] src1_tag;
        logic                 src2_ready;
        logic [31:0]          src2_value;
        logic [PHY_TAG_W-1:0] src2_tag;
    } iq_entry_t;

    rob_entry_t rob [0:ROB_DEPTH-1];
    iq_entry_t  iq  [0:IQ_DEPTH-1];

    // FIFO/Decode -> Rename/Dispatch timing boundary.  The FIFO is popped
    // when this one-entry elastic stage accepts an instruction, not when the
    // backend eventually dispatches it.
    logic                 decode_stage_valid;
    dec_ctrl_t            decode_stage_ctrl;
    logic [31:0]          decode_stage_opcode;
    logic                 decode_stage_ready;
    logic                 decode_capture_fire;
    logic [PHY_TAG_W-1:0] decode_stage_src1_tag;
    logic [PHY_TAG_W-1:0] decode_stage_src2_tag;
    logic [PHY_TAG_W-1:0] capture_src1_tag;
    logic [PHY_TAG_W-1:0] capture_src2_tag;

    logic [ROB_TAG_W-1:0] rob_head;
    logic [ROB_TAG_W-1:0] rob_tail;
    logic [ROB_TAG_W:0]   rob_count;

    // p0-p31 hold committed architectural state.  RAT entries point either
    // to that identity mapping or to an in-flight destination above p31.
    // The number of speculative mappings cannot exceed the ROB depth.
    logic [31:0]          rat_spec_valid;
    logic [ROB_TAG_W-1:0] rat_spec_slot       [0:31];
    logic [PRF_DEPTH-1:0] free_list;
    logic [31:0]          prf_read_data1;
    logic [31:0]          prf_read_data2;
    logic                 prf_read_ready1;
    logic                 prf_read_ready2;

    logic                 has_free_phys;
    logic [PHY_TAG_W-1:0] alloc_phys;
    logic                 dispatch_needs_dest;
    logic                 dispatch_fire;
    logic                 rob_full;
    logic                 iq_has_free;
    logic [IQ_IDX_W-1:0]  iq_free_idx;
    logic                 dispatch_blocked;

    logic                 dispatch_src1_ready;
    logic [31:0]          dispatch_src1_value;
    logic [PHY_TAG_W-1:0] dispatch_src1_tag;
    logic                 dispatch_src2_ready;
    logic [31:0]          dispatch_src2_value;
    logic [PHY_TAG_W-1:0] dispatch_src2_tag;

    logic                 alu_select_valid;
    logic [IQ_IDX_W-1:0]  alu_select_idx;
    logic                 md_select_valid;
    logic [IQ_IDX_W-1:0]  md_select_idx;
    logic                 iq0_ready;
    logic                 iq1_ready;
    logic                 iq0_md_candidate;
    logic                 iq1_md_candidate;
    logic                 iq0_alu_candidate;
    logic                 iq1_alu_candidate;

    // Registered integer issue boundary.  IQ/ROB selection and operand muxing
    // finish here; the ALU and ROB write-back run in the following cycle.
    // This intentionally trades issue throughput for FPGA Fmax.
    logic                 alu_active;
    logic [ROB_TAG_W-1:0] alu_active_rob_tag;
    logic [PHY_TAG_W-1:0] alu_active_dest_phys;
    logic                 alu_active_dest_valid;
    dec_ctrl_t            alu_active_ctrl;
    logic [31:0]          alu_active_src1;
    logic [31:0]          alu_active_src2;

    logic                 md_active;
    logic [ROB_TAG_W-1:0] md_active_rob_tag;
    logic [PHY_TAG_W-1:0] md_active_dest_phys;
    logic                 md_active_dest_valid;
    dec_ctrl_t            md_active_ctrl;
    logic [31:0]          md_active_src1;
    logic [31:0]          md_active_src2;

    logic                 alu_wb_valid;
    logic [ROB_TAG_W-1:0] alu_wb_rob_tag;
    logic [PHY_TAG_W-1:0] alu_wb_phys_tag;
    logic                 alu_wb_has_dest;
    logic [31:0]          alu_wb_value;
    logic                 md_wb_valid;
    logic                 load_wb_valid;
    logic [31:0]          load_wb_value;
    logic                 commit_fire;
    logic [31:0]          commit_result;
    logic                 commit_prf_valid;
    logic [4:0]           commit_prf_addr;
    logic [31:0]          commit_prf_data;
    logic                 commit_prf_csr;
    logic                 branch_redirect;
    logic [63:0]          ooo_cycle;
    integer i;
    integer scan_free;

    PSC_Register #(
        .ENTRIES (PRF_DEPTH),
        .TAG_W   (PHY_TAG_W)
    ) u_physical_register_file (
        .clock              (clock),
        .reset_n            (reset_n),
        .cpu_stop           (cpu_stop),
        .read_addr1         (dispatch_src1_tag),
        .read_addr2         (dispatch_src2_tag),
        .read_data1         (prf_read_data1),
        .read_data2         (prf_read_data2),
        .read_ready1        (prf_read_ready1),
        .read_ready2        (prf_read_ready2),
        .allocate_valid     (dispatch_fire && dispatch_needs_dest),
        .allocate_addr      (alloc_phys),
        .release_valid      (commit_fire && rob[rob_head].dest_valid &&
                             !rob[rob_head].exception_valid),
        .release_addr       (rob[rob_head].dest_phys),
        .wb0_valid          (alu_wb_valid && alu_wb_has_dest &&
                             (rob[iq[alu_select_idx].rob_tag].ctrl.wb_sel != 2'b11)),
        .wb0_addr           (alu_wb_phys_tag),
        .wb0_data           (alu_wb_value),
        .wb1_valid          (md_wb_valid && md_active_dest_valid),
        .wb1_addr           (md_active_dest_phys),
        .wb1_data           (md_execute_data),
        .wb2_valid          (load_wb_valid && rob[rob_head].dest_valid),
        .wb2_addr           (rob[rob_head].dest_phys),
        .wb2_data           (load_wb_value),
        .wb3_valid          (commit_prf_valid),
        .wb3_addr           (commit_prf_addr),
        .wb3_data           (commit_prf_csr ? csr_rdata : commit_prf_data)
    );

    function automatic logic is_mul_div(input dec_ctrl_t ctrl);
        is_mul_div = (ctrl.alucon[4:2] == 3'b110) ||
                     (ctrl.alucon[4:2] == 3'b111);
    endfunction

    function automatic logic serializing_instruction(input dec_ctrl_t ctrl);
        serializing_instruction =
            ctrl.is_load                    ||
            ctrl.is_store                   ||
            (ctrl.pc_sel != 2'b00)           ||
            ctrl.csr_wr                     ||
            ctrl.is_fence                   ||
            ctrl.is_fence_i                 ||
            ctrl.is_sfence_vma              ||
            ctrl.is_ecall                   ||
            ctrl.is_mret                    ||
            ctrl.is_sret                    ||
            ctrl.raise_illegal_instruction;
    endfunction

    function automatic logic branch_exec(
        input logic [1:0]  pc_sel,
        input logic [2:0]  funct3,
        input logic [31:0] data1,
        input logic [31:0] data2
    );
        case (pc_sel)
            2'b01: begin
                case (funct3)
                    3'b000: branch_exec = (data1 == data2);
                    3'b001: branch_exec = (data1 != data2);
                    3'b100: branch_exec = ($signed(data1) < $signed(data2));
                    3'b101: branch_exec = ($signed(data1) >= $signed(data2));
                    3'b110: branch_exec = (data1 < data2);
                    3'b111: branch_exec = (data1 >= data2);
                    default: branch_exec = 1'b0;
                endcase
            end
            2'b10: branch_exec = 1'b1;
            default: branch_exec = 1'b0;
        endcase
    endfunction

    function automatic logic [31:0] load_result(
        input logic [31:0] raw_data,
        input logic [1:0]  low2,
        input logic [2:0]  funct3
    );
        logic [7:0]  byte_data;
        logic [15:0] half_data;
        begin
            case (low2)
                2'd0: byte_data = raw_data[7:0];
                2'd1: byte_data = raw_data[15:8];
                2'd2: byte_data = raw_data[23:16];
                default: byte_data = raw_data[31:24];
            endcase
            half_data = low2[1] ? raw_data[31:16] : raw_data[15:0];
            case (funct3)
                3'b000: load_result = {{24{byte_data[7]}}, byte_data};
                3'b001: load_result = {{16{half_data[15]}}, half_data};
                3'b100: load_result = {24'd0, byte_data};
                3'b101: load_result = {16'd0, half_data};
                default: load_result = raw_data;
            endcase
        end
    endfunction

    // Only ROB_DEPTH speculative rename slots are required: every live
    // destination belongs to exactly one live ROB entry.
    always_comb begin
        has_free_phys = 1'b0;
        alloc_phys    = '0;
        for (scan_free = 32; scan_free < PRF_DEPTH; scan_free = scan_free + 1) begin
            if (free_list[scan_free] && !has_free_phys) begin
                has_free_phys = 1'b1;
                alloc_phys    = scan_free[PHY_TAG_W-1:0];
            end
        end
    end

    assign dispatch_needs_dest = decode_stage_ctrl.rf_wen &&
                                 (decode_stage_ctrl.w_addr != 5'd0);
    // Resolve RAT lookups before the PRF-read cycle.  This register boundary
    // keeps the 32-way RAT mux out of the PRF-read/bypass/IQ-write path.
    // Same-cycle dispatch and commit are folded into the lookup so adjacent
    // producer/consumer instructions retain correct rename semantics.
    always_comb begin
        capture_src1_tag = decoded_ctrl.r_addr1;
        if (!decoded_ctrl.use_rs1)
            capture_src1_tag = '0;
        else if (dispatch_fire && dispatch_needs_dest &&
                 (decode_stage_ctrl.w_addr == decoded_ctrl.r_addr1))
            capture_src1_tag = alloc_phys;
        else if (rat_spec_valid[decoded_ctrl.r_addr1]) begin
            if (commit_fire && rob[rob_head].dest_valid &&
                (rob[rob_head].ctrl.w_addr == decoded_ctrl.r_addr1) &&
                (rat_spec_slot[decoded_ctrl.r_addr1] ==
                 rob[rob_head].dest_phys[ROB_TAG_W-1:0]))
                capture_src1_tag = decoded_ctrl.r_addr1;
            else
                capture_src1_tag = 6'd32 +
                    rat_spec_slot[decoded_ctrl.r_addr1];
        end

        capture_src2_tag = decoded_ctrl.r_addr2;
        if (!decoded_ctrl.use_rs2)
            capture_src2_tag = '0;
        else if (dispatch_fire && dispatch_needs_dest &&
                 (decode_stage_ctrl.w_addr == decoded_ctrl.r_addr2))
            capture_src2_tag = alloc_phys;
        else if (rat_spec_valid[decoded_ctrl.r_addr2]) begin
            if (commit_fire && rob[rob_head].dest_valid &&
                (rob[rob_head].ctrl.w_addr == decoded_ctrl.r_addr2) &&
                (rat_spec_slot[decoded_ctrl.r_addr2] ==
                 rob[rob_head].dest_phys[ROB_TAG_W-1:0]))
                capture_src2_tag = decoded_ctrl.r_addr2;
            else
                capture_src2_tag = 6'd32 +
                    rat_spec_slot[decoded_ctrl.r_addr2];
        end
    end

    assign dispatch_src1_tag = decode_stage_src1_tag;
    assign dispatch_src2_tag = decode_stage_src2_tag;

    // Current-cycle WB bypasses exist only into rename.  IQ wake-up remains
    // registered, avoiding WB->wake-up->select->execute in one cycle.
    always_comb begin
        dispatch_src1_ready = !decode_stage_ctrl.use_rs1 ||
                              (decode_stage_ctrl.r_addr1 == 5'd0) ||
                              prf_read_ready1;
        dispatch_src1_value = (!decode_stage_ctrl.use_rs1 ||
                               (decode_stage_ctrl.r_addr1 == 5'd0))
                            ? 32'd0 : prf_read_data1;
        if (alu_wb_valid && alu_wb_has_dest &&
            (dispatch_src1_tag == alu_wb_phys_tag)) begin
            dispatch_src1_ready = 1'b1;
            dispatch_src1_value = alu_wb_value;
        end else if (md_wb_valid && md_active_dest_valid &&
                     (dispatch_src1_tag == md_active_dest_phys)) begin
            dispatch_src1_ready = 1'b1;
            dispatch_src1_value = md_execute_data;
        end else if (load_wb_valid && rob[rob_head].dest_valid &&
                     (dispatch_src1_tag == rob[rob_head].dest_phys)) begin
            dispatch_src1_ready = 1'b1;
            dispatch_src1_value = load_wb_value;
        end

        dispatch_src2_ready = !decode_stage_ctrl.use_rs2 ||
                              (decode_stage_ctrl.r_addr2 == 5'd0) ||
                              prf_read_ready2;
        dispatch_src2_value = (!decode_stage_ctrl.use_rs2 ||
                               (decode_stage_ctrl.r_addr2 == 5'd0))
                            ? 32'd0 : prf_read_data2;
        if (alu_wb_valid && alu_wb_has_dest &&
            (dispatch_src2_tag == alu_wb_phys_tag)) begin
            dispatch_src2_ready = 1'b1;
            dispatch_src2_value = alu_wb_value;
        end else if (md_wb_valid && md_active_dest_valid &&
                     (dispatch_src2_tag == md_active_dest_phys)) begin
            dispatch_src2_ready = 1'b1;
            dispatch_src2_value = md_execute_data;
        end else if (load_wb_valid && rob[rob_head].dest_valid &&
                     (dispatch_src2_tag == rob[rob_head].dest_phys)) begin
            dispatch_src2_ready = 1'b1;
            dispatch_src2_value = load_wb_value;
        end
    end

    assign iq_has_free = !iq[0].valid || !iq[1].valid;
    assign iq_free_idx = iq[0].valid;
    assign dispatch_blocked =
        (rob[0].valid && serializing_instruction(rob[0].ctrl)) ||
        (rob[1].valid && serializing_instruction(rob[1].ctrl));

    assign rob_full = (rob_count == ROB_DEPTH);
    assign dispatch_fire = decode_stage_valid && !rob_full && iq_has_free &&
                           (!dispatch_needs_dest || has_free_phys) &&
                           !dispatch_blocked && !cpu_stop && !cpu_trap &&
                           !d_pf && !i_pf && !fifo_flush &&
                           !commit_prf_valid;
    assign decode_stage_ready = !decode_stage_valid || dispatch_fire;
    assign decode_enb = fifo_req_ready && decode_stage_ready && !decode_done &&
                        !cpu_stop && !cpu_trap && !d_pf && !i_pf &&
                        !fifo_flush;
    assign decode_capture_fire = decode_done && fifo_req_ready &&
                                 decode_stage_ready && !cpu_stop &&
                                 !cpu_trap && !d_pf && !i_pf && !fifo_flush;
    assign fifo_read_valid = decode_capture_fire;

    // Two-entry oldest-ready selection, independently for the integer and M
    // lanes.  A tag equal to rob_head is older than the other possible tag.
    always_comb begin
        iq0_ready = iq[0].valid && iq[0].src1_ready && iq[0].src2_ready;
        iq1_ready = iq[1].valid && iq[1].src1_ready && iq[1].src2_ready;
        iq0_md_candidate = iq0_ready && is_mul_div(rob[iq[0].rob_tag].ctrl) &&
                           !md_active;
        iq1_md_candidate = iq1_ready && is_mul_div(rob[iq[1].rob_tag].ctrl) &&
                           !md_active;
        iq0_alu_candidate = iq0_ready && !alu_active &&
                            !is_mul_div(rob[iq[0].rob_tag].ctrl) &&
            (!serializing_instruction(rob[iq[0].rob_tag].ctrl) ||
             (iq[0].rob_tag == rob_head));
        iq1_alu_candidate = iq1_ready && !alu_active &&
                            !is_mul_div(rob[iq[1].rob_tag].ctrl) &&
            (!serializing_instruction(rob[iq[1].rob_tag].ctrl) ||
             (iq[1].rob_tag == rob_head));

        alu_select_valid = 1'b0;
        alu_select_idx   = '0;
        md_select_valid  = 1'b0;
        md_select_idx    = '0;

        if (iq0_alu_candidate || iq1_alu_candidate) begin
            alu_select_valid = 1'b1;
            if (!iq0_alu_candidate)
                alu_select_idx = 1'b1;
            else if (iq1_alu_candidate && (iq[1].rob_tag == rob_head) &&
                     (iq[0].rob_tag != rob_head))
                alu_select_idx = 1'b1;
        end

        if (iq0_md_candidate || iq1_md_candidate) begin
            md_select_valid = 1'b1;
            if (!iq0_md_candidate)
                md_select_idx = 1'b1;
            else if (iq1_md_candidate && (iq[1].rob_tag == rob_head) &&
                     (iq[0].rob_tag != rob_head))
                md_select_idx = 1'b1;
        end
    end

    assign alu_execute_valid      = alu_active;
    assign alu_execute_ctrl       = alu_active ? alu_active_ctrl : '0;
    assign alu_execute_reg_data_1 = alu_active ? alu_active_src1 : 32'd0;
    assign alu_execute_reg_data_2 = alu_active ? alu_active_src2 : 32'd0;

    assign md_execute_valid      = md_active;
    assign md_execute_ctrl       = md_active ? md_active_ctrl : '0;
    assign md_execute_reg_data_1 = md_active_src1;
    assign md_execute_reg_data_2 = md_active_src2;

    assign alu_wb_valid = alu_active && alu_execute_done;
    assign alu_wb_rob_tag = alu_active_rob_tag;
    assign alu_wb_has_dest = alu_active_dest_valid;
    assign alu_wb_phys_tag = alu_active_dest_phys;
    assign alu_wb_value = (alu_active_ctrl.wb_sel == 2'b10)
                        ? alu_active_ctrl.out_pc + 32'd4
                        : alu_execute_data;
    assign md_wb_valid = md_active && md_execute_done;
    assign load_wb_valid = load_done && load_valid && !d_pf;
    assign load_wb_value = load_result(load_read_data,
                                       rob[rob_head].result[1:0],
                                       rob[rob_head].ctrl.funct3);

    // Loads and stores issue only at the ROB head.  A store cannot modify
    // memory until all older instructions have committed.
    assign memory_ctrl       = (rob_count != 0) ? rob[rob_head].ctrl : '0;
    assign memory_alu_data   = rob[rob_head].result;
    assign memory_reg_data_1 = 32'd0;
    assign memory_reg_data_2 = rob[rob_head].side_effect_value;
    assign memory_pc         = rob[rob_head].ctrl.out_pc;
    assign load_valid  = (rob_count != 0) && rob[rob_head].valid &&
                         rob[rob_head].address_ready &&
                         !rob[rob_head].completed && rob[rob_head].ctrl.is_load;
    assign store_valid = (rob_count != 0) && rob[rob_head].valid &&
                         rob[rob_head].address_ready &&
                         !rob[rob_head].completed && rob[rob_head].ctrl.is_store;

    assign commit_fire = (rob_count != 0) && rob[rob_head].valid &&
                         rob[rob_head].completed;
    assign commit_result = (rob[rob_head].ctrl.wb_sel == 2'b11)
                         ? csr_rdata : rob[rob_head].result;
    // Only expose side-effecting control when an instruction really commits.
    // The CSR read address is safe to present early and lets Csr register the
    // old value without putting commit_fire in its read-mux data path.
    always_comb begin
        commit_ctrl = '0;
        commit_ctrl.csr_addr = rob[rob_head].ctrl.csr_addr;
        if (commit_fire)
            commit_ctrl = rob[rob_head].ctrl;
    end
    assign commit_alu_data = rob[rob_head].branch_target;
    assign commit_branch_taken = commit_fire && rob[rob_head].branch_taken;
    assign csr_reg_data_1 = rob[rob_head].side_effect_value;
    assign csr_enb = commit_fire && !rob[rob_head].exception_valid;

    assign fifo_flush = d_pf || i_pf || branch_redirect ||
                        (commit_fire &&
                         (rob[rob_head].ctrl.is_fence_i ||
                          rob[rob_head].ctrl.is_sfence_vma ||
                          rob[rob_head].ctrl.is_ecall ||
                          rob[rob_head].ctrl.is_mret ||
                          rob[rob_head].ctrl.is_sret ||
                          rob[rob_head].ctrl.raise_illegal_instruction ||
                          rob[rob_head].exception_valid || cpu_trap));

    assign execute_task_busy = (rob_count != 0) || md_active;
    assign execute_task_done = commit_fire;

    // The architectural PRF has 31 independently decoded write destinations.
    // Register the retiring value before that high-fanout write network so
    // ROB completion/count, CSR read selection and PRF destination decoding
    // are not part of one clock-to-clock path.  Dispatch pauses while this
    // packet is written, ensuring a held consumer cannot observe the old
    // architectural value after its speculative mapping is released.
    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            commit_prf_valid <= 1'b0;
            commit_prf_addr  <= 5'd0;
            commit_prf_data  <= 32'd0;
            commit_prf_csr   <= 1'b0;
        end else if (cpu_stop) begin
            commit_prf_valid <= 1'b0;
            commit_prf_addr  <= 5'd0;
            commit_prf_data  <= 32'd0;
            commit_prf_csr   <= 1'b0;
        end else begin
            commit_prf_valid <= commit_fire && rob[rob_head].dest_valid &&
                                !rob[rob_head].exception_valid;
            commit_prf_addr  <= rob[rob_head].ctrl.w_addr;
            commit_prf_data  <= rob[rob_head].result;
            commit_prf_csr   <= (rob[rob_head].ctrl.wb_sel == 2'b11);
        end
    end

    // Branches are serializing in the ROB, so no younger instruction can
    // dispatch while the comparison is pending.  Register the redirect pulse
    // and apply the FIFO flush in the following commit cycle; this removes the
    // comparator -> global flush/enable fanout from one timing path.
    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            branch_redirect <= 1'b0;
        else if (cpu_stop || cpu_trap || d_pf || i_pf)
            branch_redirect <= 1'b0;
        else
            branch_redirect <= alu_wb_valid &&
                               (alu_active_ctrl.pc_sel != 2'b00) &&
                               branch_exec(alu_active_ctrl.pc_sel,
                                           alu_active_ctrl.funct3,
                                           alu_active_src1,
                                           alu_active_src2);
    end

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            csr_valid <= 1'b0;
        else
            csr_valid <= csr_enb;
    end

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            ooo_cycle <= 64'd0;
        else if (cpu_stop)
            ooo_cycle <= 64'd0;
        else
            ooo_cycle <= ooo_cycle + 64'd1;
    end

    // Elastic decode/dispatch stage.  dispatch_fire may consume the current
    // entry on the same edge that decode_capture_fire refills it.
    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            decode_stage_valid  <= 1'b0;
            decode_stage_ctrl   <= '0;
            decode_stage_opcode <= 32'd0;
            decode_stage_src1_tag <= '0;
            decode_stage_src2_tag <= '0;
        end else if (cpu_stop || cpu_trap || d_pf || i_pf || fifo_flush) begin
            decode_stage_valid <= 1'b0;
        end else if (decode_capture_fire) begin
            decode_stage_valid  <= 1'b1;
            decode_stage_ctrl   <= decoded_ctrl;
            decode_stage_opcode <= opcode;
            decode_stage_src1_tag <= capture_src1_tag;
            decode_stage_src2_tag <= capture_src2_tag;
        end else if (dispatch_fire) begin
            decode_stage_valid <= 1'b0;
        end else if (commit_fire && rob[rob_head].dest_valid &&
                     !rob[rob_head].exception_valid) begin
            // A decoded instruction may wait here while its producer commits.
            // The speculative slot is released on that edge, so retarget any
            // held operand to the newly updated architectural register bank.
            if (decode_stage_ctrl.use_rs1 &&
                (decode_stage_src1_tag == rob[rob_head].dest_phys))
                decode_stage_src1_tag <= rob[rob_head].ctrl.w_addr;
            if (decode_stage_ctrl.use_rs2 &&
                (decode_stage_src2_tag == rob[rob_head].dest_phys))
                decode_stage_src2_tag <= rob[rob_head].ctrl.w_addr;
        end
    end

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            rob_head          <= '0;
            rob_tail          <= '0;
            rob_count         <= '0;
            alu_active        <= 1'b0;
            alu_active_rob_tag <= '0;
            alu_active_dest_phys <= '0;
            alu_active_dest_valid <= 1'b0;
            alu_active_ctrl   <= '0;
            alu_active_src1   <= 32'd0;
            alu_active_src2   <= 32'd0;
            md_active         <= 1'b0;
            md_active_rob_tag <= '0;
            md_active_dest_phys <= '0;
            md_active_dest_valid <= 1'b0;
            md_active_ctrl    <= '0;
            md_active_src1    <= 32'd0;
            md_active_src2    <= 32'd0;
            free_list         <= '0;
            rat_spec_valid    <= '0;
            for (i = 32; i < PRF_DEPTH; i = i + 1)
                free_list[i] <= 1'b1;
            for (i = 0; i < ROB_DEPTH; i = i + 1)
                rob[i] <= '0;
            for (i = 0; i < IQ_DEPTH; i = i + 1)
                iq[i] <= '0;
        end else if (cpu_stop) begin
            rob_head  <= '0;
            rob_tail  <= '0;
            rob_count <= '0;
            alu_active <= 1'b0;
            md_active <= 1'b0;
            free_list <= '0;
            rat_spec_valid <= '0;
            for (i = 32; i < PRF_DEPTH; i = i + 1)
                free_list[i] <= 1'b1;
            for (i = 0; i < ROB_DEPTH; i = i + 1)
                rob[i] <= '0;
            for (i = 0; i < IQ_DEPTH; i = i + 1)
                iq[i] <= '0;
        end else if (cpu_trap || d_pf || i_pf) begin
            // Precise recovery discards speculative mappings while retaining
            // the committed p0-p31 architectural bank.
            rob_head  <= '0;
            rob_tail  <= '0;
            rob_count <= '0;
            alu_active <= 1'b0;
            md_active <= 1'b0;
            free_list <= '0;
            rat_spec_valid <= '0;
            for (i = 32; i < PRF_DEPTH; i = i + 1)
                free_list[i] <= 1'b1;
            for (i = 0; i < ROB_DEPTH; i = i + 1)
                rob[i] <= '0;
            for (i = 0; i < IQ_DEPTH; i = i + 1)
                iq[i] <= '0;
        end else begin
            rat_spec_valid[0] <= 1'b0;

            // In-order retirement updates the architectural bank and releases
            // the speculative destination slot.
            if (commit_fire) begin
                rob[rob_head].valid <= 1'b0;
                if (rob[rob_head].dest_valid &&
                    !rob[rob_head].exception_valid) begin
                    if (rat_spec_valid[rob[rob_head].ctrl.w_addr] &&
                        (rat_spec_slot[rob[rob_head].ctrl.w_addr] ==
                         rob[rob_head].dest_phys[ROB_TAG_W-1:0]))
                        rat_spec_valid[rob[rob_head].ctrl.w_addr] <= 1'b0;
                    free_list[rob[rob_head].dest_phys] <= 1'b1;
                end
                rob_head <= rob_head + 1'b1;
            end

            // Rename and dispatch one instruction per cycle.
            if (dispatch_fire) begin
                rob[rob_tail].valid           <= 1'b1;
                rob[rob_tail].completed       <= 1'b0;
                rob[rob_tail].address_ready   <= 1'b0;
                rob[rob_tail].instruction     <= decode_stage_opcode;
                rob[rob_tail].ctrl            <= decode_stage_ctrl;
                rob[rob_tail].side_effect_value <= 32'd0;
                rob[rob_tail].dest_valid      <= dispatch_needs_dest;
                rob[rob_tail].dest_phys       <= dispatch_needs_dest ? alloc_phys : '0;
                rob[rob_tail].result          <= 32'd0;
                rob[rob_tail].branch_taken    <= 1'b0;
                rob[rob_tail].branch_target   <= 32'd0;
                rob[rob_tail].exception_valid <= decode_stage_ctrl.raise_illegal_instruction;
                rob[rob_tail].exception_cause <= decode_stage_ctrl.raise_illegal_instruction
                                               ? 5'd2 : 5'd0;
                rob[rob_tail].exception_tval  <= decode_stage_ctrl.raise_illegal_instruction
                                               ? decode_stage_opcode : 32'd0;

                iq[iq_free_idx].valid      <= 1'b1;
                iq[iq_free_idx].rob_tag    <= rob_tail;
                iq[iq_free_idx].src1_ready <= dispatch_src1_ready;
                iq[iq_free_idx].src1_value <= dispatch_src1_value;
                iq[iq_free_idx].src1_tag   <= dispatch_src1_tag;
                iq[iq_free_idx].src2_ready <= dispatch_src2_ready;
                iq[iq_free_idx].src2_value <= dispatch_src2_value;
                iq[iq_free_idx].src2_tag   <= dispatch_src2_tag;

                if (dispatch_needs_dest) begin
                    rat_spec_valid[decode_stage_ctrl.w_addr] <= 1'b1;
                    rat_spec_slot[decode_stage_ctrl.w_addr] <=
                        alloc_phys[ROB_TAG_W-1:0];
                    free_list[alloc_phys] <= 1'b0;
                end
                rob_tail <= rob_tail + 1'b1;
            end

            case ({dispatch_fire, commit_fire})
                2'b10: rob_count <= rob_count + 1'b1;
                2'b01: rob_count <= rob_count - 1'b1;
                default: rob_count <= rob_count;
            endcase

            // Register IQ selection before the integer ALU.  Selection cannot
            // launch again until the current result has written back.
            if (alu_select_valid && !alu_active) begin
                iq[alu_select_idx].valid <= 1'b0;
                alu_active              <= 1'b1;
                alu_active_rob_tag      <= iq[alu_select_idx].rob_tag;
                alu_active_dest_valid   <=
                    rob[iq[alu_select_idx].rob_tag].dest_valid;
                alu_active_dest_phys    <=
                    rob[iq[alu_select_idx].rob_tag].dest_phys;
                alu_active_ctrl         <=
                    rob[iq[alu_select_idx].rob_tag].ctrl;
                alu_active_src1         <= iq[alu_select_idx].src1_value;
                alu_active_src2         <= iq[alu_select_idx].src2_value;
            end

            // Integer execution and physical-register write-back.
            if (alu_wb_valid) begin
                alu_active <= 1'b0;
                // Only stores and CSR operations need a source value after
                // execution.  Branch comparison consumes both values here.
                if (alu_active_ctrl.is_store)
                    rob[alu_wb_rob_tag].side_effect_value <=
                        alu_active_src2;
                else if (alu_active_ctrl.csr_wr)
                    rob[alu_wb_rob_tag].side_effect_value <=
                        alu_active_src1;
                rob[alu_wb_rob_tag].result <= alu_wb_value;
                rob[alu_wb_rob_tag].branch_taken <=
                    branch_exec(alu_active_ctrl.pc_sel,
                                alu_active_ctrl.funct3,
                                alu_active_src1,
                                alu_active_src2);
                rob[alu_wb_rob_tag].branch_target <= alu_execute_data;
                rob[alu_wb_rob_tag].address_ready <=
                    alu_active_ctrl.is_load || alu_active_ctrl.is_store;
                if (!alu_active_ctrl.is_load && !alu_active_ctrl.is_store)
                    rob[alu_wb_rob_tag].completed <= 1'b1;
            end

            // Launch and complete the independent MUL/DIV lane.
            if (md_select_valid && !md_active) begin
                iq[md_select_idx].valid <= 1'b0;
                md_active            <= 1'b1;
                md_active_rob_tag    <= iq[md_select_idx].rob_tag;
                md_active_dest_valid <= rob[iq[md_select_idx].rob_tag].dest_valid;
                md_active_dest_phys  <= rob[iq[md_select_idx].rob_tag].dest_phys;
                md_active_ctrl       <= rob[iq[md_select_idx].rob_tag].ctrl;
                md_active_src1       <= iq[md_select_idx].src1_value;
                md_active_src2       <= iq[md_select_idx].src2_value;
            end
            if (md_wb_valid) begin
                rob[md_active_rob_tag].result <= md_execute_data;
                rob[md_active_rob_tag].completed <= 1'b1;
                md_active <= 1'b0;
            end

            // Head-only memory completion.
            if (load_wb_valid) begin
                rob[rob_head].result <= load_wb_value;
                rob[rob_head].completed <= 1'b1;
            end
            if (store_done && store_valid && !d_pf)
                rob[rob_head].completed <= 1'b1;

            // Registered wake-up; selection observes these changes next cycle.
            for (i = 0; i < IQ_DEPTH; i = i + 1) begin
                if (iq[i].valid && !iq[i].src1_ready) begin
                    if (alu_wb_valid && alu_wb_has_dest &&
                        (iq[i].src1_tag == alu_wb_phys_tag)) begin
                        iq[i].src1_ready <= 1'b1;
                        iq[i].src1_value <= alu_wb_value;
                    end else if (md_wb_valid && md_active_dest_valid &&
                                 (iq[i].src1_tag == md_active_dest_phys)) begin
                        iq[i].src1_ready <= 1'b1;
                        iq[i].src1_value <= md_execute_data;
                    end else if (load_wb_valid && rob[rob_head].dest_valid &&
                                 (iq[i].src1_tag == rob[rob_head].dest_phys)) begin
                        iq[i].src1_ready <= 1'b1;
                        iq[i].src1_value <= load_wb_value;
                    end
                end
                if (iq[i].valid && !iq[i].src2_ready) begin
                    if (alu_wb_valid && alu_wb_has_dest &&
                        (iq[i].src2_tag == alu_wb_phys_tag)) begin
                        iq[i].src2_ready <= 1'b1;
                        iq[i].src2_value <= alu_wb_value;
                    end else if (md_wb_valid && md_active_dest_valid &&
                                 (iq[i].src2_tag == md_active_dest_phys)) begin
                        iq[i].src2_ready <= 1'b1;
                        iq[i].src2_value <= md_execute_data;
                    end else if (load_wb_valid && rob[rob_head].dest_valid &&
                                 (iq[i].src2_tag == rob[rob_head].dest_phys)) begin
                        iq[i].src2_ready <= 1'b1;
                        iq[i].src2_value <= load_wb_value;
                    end
                end
            end
        end
    end

    PSC_PC u_PSC_PC (
        .clock             (clock),
        .reset_n           (reset_n),
        .cpu_stop          (cpu_stop),
        .execute_task_done (commit_fire),
        .alu_data          (rob[rob_head].branch_target),
        .pc_sel2           (commit_fire && rob[rob_head].branch_taken),
        .decoder_ctrl      (commit_ctrl),
        .cpu_trap          (cpu_trap),
        .priv_mode         (priv_mode),
        .d_pf              (d_pf_event),
        .i_pf              (i_pf_event),
        .trap_scause       (trap_scause),
        .csr_state         (csr_state),
        .pc                (pc),
        .counter           (counter)
    );

`ifdef OOO_TRACE
    always_ff @(posedge clock) begin
        if (reset_n && dispatch_fire) begin
            $display("C%0d ROB_ALLOC #%0d PC=%08x INST=%08x RD=x%0d PD=p%0d", ooo_cycle,
                     rob_tail, decode_stage_ctrl.out_pc, decode_stage_opcode,
                     decode_stage_ctrl.w_addr,
                     dispatch_needs_dest ? alloc_phys : 0);
            $display("C%0d IQ_ENQ    #%0d ROB#%0d S1=%0b/p%0d S2=%0b/p%0d", ooo_cycle,
                     iq_free_idx, rob_tail, dispatch_src1_ready,
                     dispatch_src1_tag, dispatch_src2_ready, dispatch_src2_tag);
        end
        if (reset_n && alu_select_valid)
            $display("C%0d ISSUE_ALU ROB#%0d PC=%08x", ooo_cycle,
                     iq[alu_select_idx].rob_tag,
                     rob[iq[alu_select_idx].rob_tag].ctrl.out_pc);
        if (reset_n && alu_wb_valid)
            $display("C%0d WB_ALU    ROB#%0d PC=%08x RESULT=%08x", ooo_cycle,
                     alu_wb_rob_tag, rob[alu_wb_rob_tag].ctrl.out_pc, alu_wb_value);
        if (reset_n && md_select_valid && !md_active)
            $display("C%0d ISSUE_MD  ROB#%0d PC=%08x", ooo_cycle,
                     iq[md_select_idx].rob_tag,
                     rob[iq[md_select_idx].rob_tag].ctrl.out_pc);
        if (reset_n && md_wb_valid)
            $display("C%0d WB_MD     ROB#%0d PC=%08x RESULT=%08x", ooo_cycle,
                     md_active_rob_tag, md_active_ctrl.out_pc, md_execute_data);
        if (reset_n && branch_redirect)
            $display("C%0d FLUSH     ROB#%0d PC=%08x TARGET=%08x", ooo_cycle,
                     alu_wb_rob_tag, rob[alu_wb_rob_tag].ctrl.out_pc, alu_execute_data);
        if (reset_n && commit_fire)
            $display("C%0d COMMIT    ROB#%0d PC=%08x INST=%08x RESULT=%08x", ooo_cycle,
                     rob_head, rob[rob_head].ctrl.out_pc,
                     rob[rob_head].instruction,
                     commit_result);
        if (reset_n && (d_pf || i_pf))
            $display("C%0d EXCEPTION PC=%08x CAUSE=%0d", ooo_cycle,
                     rob[rob_head].ctrl.out_pc, trap_scause);
    end
`endif

endmodule
