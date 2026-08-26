// NISHIHARU

import PSC_Types::*;

module PSC_InstructionUnit (
    input  logic        clock,
    input  logic        reset_n,
    input  logic        cpu_stop,
    input  logic        cpu_trap,
    input  logic [1:0]  priv_mode,

    // PC / current FIFO head
    output logic [31:0] pc,
    output logic [31:0] counter,
    input  logic [31:0] opcode,
    input  logic [31:0] pc_now,

    // FIFO / decode handshake
    input  logic        fifo_req_ready,
    input  logic        fifo_read_ready,
    output logic        fifo_read_valid,
    output logic        fifo_flush,
    input  dec_ctrl_t   decoded_ctrl,
    output logic        decode_enb,
    input  logic        decode_done,

    // Execute handshake
    output logic        execute_valid,
    output dec_ctrl_t   execute_ctrl,
    output logic [31:0] execute_reg_data_1,
    output logic [31:0] execute_reg_data_2,
    input  logic [31:0] execute_alu_data,
    input  logic        execute_done,

    // Memory-stage request and response
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

    // Commit / CSR interface
    input  csr_state_t  csr_state,
    input  logic [31:0] csr_rdata,
    output logic [31:0] csr_reg_data_1,
    output logic        csr_enb,
    output logic        csr_valid,
    output dec_ctrl_t   commit_ctrl,
    output logic [31:0] commit_alu_data,
    output logic        commit_branch_taken,

    // Fault information
    input  logic        d_pf,
    input  logic        i_pf,
    input  logic        d_pf_event,
    input  logic        i_pf_event,
    input  logic [4:0]  trap_scause,

    output logic        execute_task_busy,
    output logic        execute_task_done
);

    typedef struct packed {
        logic        valid;
        dec_ctrl_t   ctrl;
        logic [31:0] pc;
    } id_issue_t;

    typedef struct packed {
        logic        valid;
        dec_ctrl_t   ctrl;
        logic [31:0] pc;
        logic [31:0] reg_data_1;
        logic [31:0] reg_data_2;
    } issue_ex_t;

    typedef struct packed {
        logic        valid;
        dec_ctrl_t   ctrl;
        logic [31:0] pc;
        logic [31:0] reg_data_1;
        logic [31:0] reg_data_2;
        logic [31:0] alu_data;
    } ex_mem_t;

    typedef struct packed {
        logic        valid;
        dec_ctrl_t   ctrl;
        logic [31:0] pc;
        logic [31:0] reg_data_1;
        logic [31:0] alu_data;
        logic        branch_taken;
        logic [31:0] w_data;
    } wb_t;

    id_issue_t id_issue;
    issue_ex_t issue_ex;
    ex_mem_t   ex_mem;
    wb_t       mem_wb;
    wb_t       commit;

    logic [31:0] regfile_rdata_1;
    logic [31:0] regfile_rdata_2;
    logic        regfile_wen;
    logic [31:0] regfile_wdata;

    logic decode_fire;
    logic issue_fire;
    logic ex_fire;
    logic mem_fire;
    logic id_issue_ready;
    logic issue_ex_ready;
    logic ex_mem_ready;
    logic mem_wb_ready;
    logic memory_complete;
    logic branch_taken_now;
    logic raw_hazard;
    logic raw_hazard_rs1;
    logic raw_hazard_rs2;
    logic [31:0] issue_reg_data_1;
    logic [31:0] issue_reg_data_2;
    logic [2:0] forward_sel_rs1;
    logic [2:0] forward_sel_rs2;
    logic issue_ex_forwardable;
    logic ex_mem_forwardable;
    logic mem_wb_forwardable;
    logic [31:0] issue_ex_forward_data;
    logic [31:0] ex_mem_forward_data;
    logic backend_serial;
    logic backend_empty;
    logic pipeline_empty;
    logic issue_serial;
    logic issue_forwarding_consumer;
    logic early_branch_valid;
    logic commit_branch_redirected;
    logic pc_update_valid;
    dec_ctrl_t pc_update_ctrl;
    logic [31:0] pc_update_alu_data;
    logic pc_update_branch_taken;

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

    function automatic logic early_redirect_instruction(input dec_ctrl_t ctrl);
        early_redirect_instruction =
            (ctrl.pc_sel != 2'b00)             &&
            !ctrl.is_ecall                     &&
            !ctrl.is_mret                      &&
            !ctrl.is_sret                      &&
            !ctrl.raise_illegal_instruction;
    endfunction

    function automatic logic branch_exec(
        input logic [1:0]  pc_sel,
        input logic [2:0]  funct3,
        input logic [31:0] data1,
        input logic [31:0] data2
    );
        begin
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
        end
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

    // ============================================================
    // Register file and hazard interlock
    // ============================================================
    assign regfile_wen = commit.valid && commit.ctrl.rf_wen &&
                         (commit.ctrl.w_addr != 5'd0);
    assign regfile_wdata = (commit.ctrl.wb_sel == 2'b11)
                         ? csr_rdata : commit.w_data;

    PSC_Register u_regfile (
        .clock         (clock),
        .reset_n       (reset_n),
        .register_wenb (regfile_wen),
        .rf_wen        (regfile_wen),
        .w_addr        (commit.ctrl.w_addr),
        .w_data        (regfile_wdata),
        .r_addr1       (id_issue.ctrl.r_addr1),
        .r_addr2       (id_issue.ctrl.r_addr2),
        .reg_data_1    (regfile_rdata_1),
        .reg_data_2    (regfile_rdata_2)
    );

    // Results are selected at issue and stored with the consumer.  The
    // youngest matching producer wins; an unavailable young value must stall
    // instead of falling through to an older value for the same register.
    always_comb begin
        issue_ex_forwardable = execute_done &&
                               ((issue_ex.ctrl.wb_sel == 2'b00) ||
                                (issue_ex.ctrl.wb_sel == 2'b10));
        issue_ex_forward_data = (issue_ex.ctrl.wb_sel == 2'b10)
                              ? issue_ex.pc + 32'd4
                              : execute_alu_data;

        ex_mem_forwardable = (ex_mem.ctrl.wb_sel == 2'b00) ||
                             (ex_mem.ctrl.wb_sel == 2'b10) ||
                             ((ex_mem.ctrl.wb_sel == 2'b01) &&
                              ex_mem.ctrl.is_load && load_done);
        case (ex_mem.ctrl.wb_sel)
            2'b01: ex_mem_forward_data = load_result(
                                               load_read_data,
                                               ex_mem.alu_data[1:0],
                                               ex_mem.ctrl.funct3);
            2'b10: ex_mem_forward_data = ex_mem.pc + 32'd4;
            default: ex_mem_forward_data = ex_mem.alu_data;
        endcase

        mem_wb_forwardable = (mem_wb.ctrl.wb_sel != 2'b11);

        issue_reg_data_1 = regfile_rdata_1;
        raw_hazard_rs1   = 1'b0;
        forward_sel_rs1  = 3'd0;
        if (id_issue.ctrl.use_rs1 && (id_issue.ctrl.r_addr1 != 5'd0)) begin
            if (issue_ex.valid && issue_ex.ctrl.rf_wen &&
                (issue_ex.ctrl.w_addr != 5'd0) &&
                (id_issue.ctrl.r_addr1 == issue_ex.ctrl.w_addr)) begin
                issue_reg_data_1 = issue_ex_forward_data;
                raw_hazard_rs1   = !issue_ex_forwardable;
                forward_sel_rs1  = 3'd1;
            end else if (ex_mem.valid && ex_mem.ctrl.rf_wen &&
                         (ex_mem.ctrl.w_addr != 5'd0) &&
                         (id_issue.ctrl.r_addr1 == ex_mem.ctrl.w_addr)) begin
                issue_reg_data_1 = ex_mem_forward_data;
                raw_hazard_rs1   = !ex_mem_forwardable;
                forward_sel_rs1  = 3'd2;
            end else if (mem_wb.valid && mem_wb.ctrl.rf_wen &&
                         (mem_wb.ctrl.w_addr != 5'd0) &&
                         (id_issue.ctrl.r_addr1 == mem_wb.ctrl.w_addr)) begin
                issue_reg_data_1 = mem_wb.w_data;
                raw_hazard_rs1   = !mem_wb_forwardable;
                forward_sel_rs1  = 3'd3;
            end else if (commit.valid && commit.ctrl.rf_wen &&
                         (commit.ctrl.w_addr != 5'd0) &&
                         (id_issue.ctrl.r_addr1 == commit.ctrl.w_addr)) begin
                // The register file is written on this edge.  Interlock for
                // one cycle so the next read uses the registered value; do
                // not put commit/CSR write data on the issue operand path.
                raw_hazard_rs1   = 1'b1;
                forward_sel_rs1  = 3'd4;
            end
        end

        issue_reg_data_2 = regfile_rdata_2;
        raw_hazard_rs2   = 1'b0;
        forward_sel_rs2  = 3'd0;
        if (id_issue.ctrl.use_rs2 && (id_issue.ctrl.r_addr2 != 5'd0)) begin
            if (issue_ex.valid && issue_ex.ctrl.rf_wen &&
                (issue_ex.ctrl.w_addr != 5'd0) &&
                (id_issue.ctrl.r_addr2 == issue_ex.ctrl.w_addr)) begin
                issue_reg_data_2 = issue_ex_forward_data;
                raw_hazard_rs2   = !issue_ex_forwardable;
                forward_sel_rs2  = 3'd1;
            end else if (ex_mem.valid && ex_mem.ctrl.rf_wen &&
                         (ex_mem.ctrl.w_addr != 5'd0) &&
                         (id_issue.ctrl.r_addr2 == ex_mem.ctrl.w_addr)) begin
                issue_reg_data_2 = ex_mem_forward_data;
                raw_hazard_rs2   = !ex_mem_forwardable;
                forward_sel_rs2  = 3'd2;
            end else if (mem_wb.valid && mem_wb.ctrl.rf_wen &&
                         (mem_wb.ctrl.w_addr != 5'd0) &&
                         (id_issue.ctrl.r_addr2 == mem_wb.ctrl.w_addr)) begin
                issue_reg_data_2 = mem_wb.w_data;
                raw_hazard_rs2   = !mem_wb_forwardable;
                forward_sel_rs2  = 3'd3;
            end else if (commit.valid && commit.ctrl.rf_wen &&
                         (commit.ctrl.w_addr != 5'd0) &&
                         (id_issue.ctrl.r_addr2 == commit.ctrl.w_addr)) begin
                raw_hazard_rs2   = 1'b1;
                forward_sel_rs2  = 3'd4;
            end
        end

        raw_hazard = raw_hazard_rs1 || raw_hazard_rs2;
    end

    // ============================================================
    // Per-stage valid/ready flow control
    // ============================================================
    assign memory_complete = ex_mem.ctrl.is_load  ? load_done  :
                             ex_mem.ctrl.is_store ? store_done : 1'b1;

    assign mem_wb_ready  = 1'b1;
    assign mem_fire      = ex_mem.valid && memory_complete && mem_wb_ready;
    assign ex_mem_ready  = !ex_mem.valid || mem_fire;
    assign execute_valid = issue_ex.valid && ex_mem_ready;
    assign ex_fire       = issue_ex.valid && execute_done && ex_mem_ready;
    assign issue_ex_ready = !issue_ex.valid || ex_fire;

    assign backend_empty = !issue_ex.valid && !ex_mem.valid &&
                           !mem_wb.valid && !commit.valid;
    assign pipeline_empty = !id_issue.valid && backend_empty;
    assign backend_serial =
        (issue_ex.valid && serializing_instruction(issue_ex.ctrl)) ||
        (ex_mem.valid   && serializing_instruction(ex_mem.ctrl))   ||
        (mem_wb.valid   && serializing_instruction(mem_wb.ctrl))   ||
        (commit.valid   && serializing_instruction(commit.ctrl));
    assign issue_serial = serializing_instruction(id_issue.ctrl);
    // A store or control-transfer may consume forwarded ALU operands behind
    // older non-serial instructions.  Once issued, backend_serial still
    // prevents any younger instruction from passing it.
    assign issue_forwarding_consumer = id_issue.ctrl.is_store ||
                                       (id_issue.ctrl.pc_sel != 2'b00);

    assign id_issue_ready = !id_issue.valid || issue_fire;
    assign decode_enb = fifo_req_ready && id_issue_ready &&
                        !cpu_stop && !cpu_trap;
    assign decode_fire = decode_done && fifo_req_ready && id_issue_ready;
    assign issue_fire = id_issue.valid && issue_ex_ready &&
                        !raw_hazard && !backend_serial &&
                        (!issue_serial || backend_empty ||
                         issue_forwarding_consumer);
    assign fifo_read_valid = decode_fire;

    assign execute_ctrl       = issue_ex.valid ? issue_ex.ctrl : '0;
    assign execute_reg_data_1 = issue_ex.reg_data_1;
    assign execute_reg_data_2 = issue_ex.reg_data_2;

    assign memory_ctrl       = ex_mem.valid ? ex_mem.ctrl : '0;
    assign memory_alu_data   = ex_mem.alu_data;
    assign memory_reg_data_1 = ex_mem.reg_data_1;
    assign memory_reg_data_2 = ex_mem.reg_data_2;
    assign memory_pc         = ex_mem.pc;
    assign load_valid        = ex_mem.valid && ex_mem.ctrl.is_load;
    assign store_valid       = ex_mem.valid && ex_mem.ctrl.is_store;

    assign branch_taken_now = branch_exec(
        ex_mem.ctrl.pc_sel,
        ex_mem.ctrl.funct3,
        ex_mem.reg_data_1,
        ex_mem.reg_data_2
    );

    assign commit_ctrl         = commit.valid ? commit.ctrl : '0;
    assign commit_alu_data     = commit.alu_data;
    assign commit_branch_taken = commit.valid && commit.branch_taken;
    assign csr_reg_data_1      = commit.reg_data_1;
    assign csr_enb             = commit.valid;

    // A normal taken branch has already redirected and flushed from MEM/WB.
    // Exception and return instructions still wait for their commit effects.
    assign commit_branch_redirected =
        commit.valid && commit.branch_taken &&
        early_redirect_instruction(commit.ctrl);
    assign execute_task_busy = id_issue.valid || issue_ex.valid ||
                               ex_mem.valid || mem_wb.valid ||
                               (commit.valid && !commit_branch_redirected);
    assign execute_task_done = commit.valid;

    // The added ID/ISSUE register must not add a taken-branch refill cycle.
    // Resolve the redirect from MEM/WB, while architectural write-back and CSR
    // side effects remain in the existing commit stage.
    assign early_branch_valid =
        mem_wb.valid && mem_wb.branch_taken &&
        early_redirect_instruction(mem_wb.ctrl);
    assign pc_update_valid = early_branch_valid ||
                             (commit.valid && !commit_branch_redirected);
    assign pc_update_ctrl = early_branch_valid ? mem_wb.ctrl : commit_ctrl;
    assign pc_update_alu_data = early_branch_valid
                              ? mem_wb.alu_data : commit_alu_data;
    assign pc_update_branch_taken = early_branch_valid ||
                                    (commit.valid && commit.branch_taken &&
                                     !commit_branch_redirected);

    assign fifo_flush = d_pf || i_pf ||
                        early_branch_valid ||
                        (commit.valid &&
                        (commit.ctrl.is_fence_i              ||
                         commit.ctrl.is_sfence_vma           ||
                         commit.ctrl.is_ecall                ||
                         commit.ctrl.is_mret                 ||
                         commit.ctrl.is_sret                 ||
                         commit.ctrl.raise_illegal_instruction ||
                         cpu_trap));

    // CSR writes happen on commit.  The public CSR snapshot is updated on
    // the following edge, after the internal CSR bank has accepted the write.
    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            csr_valid <= 1'b0;
        else
            csr_valid <= commit.valid;
    end

    // ============================================================
    // Unified stage registers
    // ============================================================
    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            id_issue <= '0;
        end else if (cpu_stop || fifo_flush) begin
            id_issue <= '0;
        end else begin
            if (decode_fire) begin
                id_issue.valid <= 1'b1;
                id_issue.ctrl  <= decoded_ctrl;
                id_issue.pc    <= pc_now;
            end else if (issue_fire) begin
                id_issue.valid <= 1'b0;
            end
        end
    end

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            issue_ex <= '0;
        end else if (cpu_stop || d_pf) begin
            issue_ex <= '0;
        end else begin
            if (issue_fire) begin
                issue_ex.valid      <= 1'b1;
                issue_ex.ctrl       <= id_issue.ctrl;
                issue_ex.pc         <= id_issue.pc;
                issue_ex.reg_data_1 <= issue_reg_data_1;
                issue_ex.reg_data_2 <= issue_reg_data_2;
            end else if (ex_fire) begin
                issue_ex.valid <= 1'b0;
            end
        end
    end

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            ex_mem <= '0;
        end else if (cpu_stop || d_pf) begin
            ex_mem <= '0;
        end else begin
            if (ex_fire) begin
                ex_mem.valid      <= 1'b1;
                ex_mem.ctrl       <= issue_ex.ctrl;
                ex_mem.pc         <= issue_ex.pc;
                ex_mem.reg_data_1 <= issue_ex.reg_data_1;
                ex_mem.reg_data_2 <= issue_ex.reg_data_2;
                ex_mem.alu_data   <= execute_alu_data;
            end else if (mem_fire) begin
                ex_mem.valid <= 1'b0;
            end
        end
    end

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            mem_wb <= '0;
        end else if (cpu_stop || d_pf) begin
            mem_wb <= '0;
        end else begin
            if (mem_fire) begin
                mem_wb.valid        <= 1'b1;
                mem_wb.ctrl         <= ex_mem.ctrl;
                mem_wb.pc           <= ex_mem.pc;
                mem_wb.reg_data_1   <= ex_mem.reg_data_1;
                mem_wb.alu_data     <= ex_mem.alu_data;
                mem_wb.branch_taken <= branch_taken_now;
                case (ex_mem.ctrl.wb_sel)
                    2'b00: mem_wb.w_data <= ex_mem.alu_data;
                    2'b01: mem_wb.w_data <= load_result(
                                                load_read_data,
                                                ex_mem.alu_data[1:0],
                                                ex_mem.ctrl.funct3);
                    2'b10: mem_wb.w_data <= ex_mem.pc + 32'd4;
                    default: mem_wb.w_data <= 32'd0;
                endcase
            end else begin
                mem_wb.valid <= 1'b0;
            end
        end
    end

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            commit <= '0;
        end else if (cpu_stop || d_pf) begin
            commit <= '0;
        end else begin
            if (mem_wb.valid) begin
                commit.valid        <= 1'b1;
                commit.ctrl         <= mem_wb.ctrl;
                commit.pc           <= mem_wb.pc;
                commit.reg_data_1   <= mem_wb.reg_data_1;
                commit.alu_data     <= mem_wb.alu_data;
                commit.branch_taken <= mem_wb.branch_taken;
                commit.w_data       <= mem_wb.w_data;
            end else begin
                commit.valid <= 1'b0;
            end
        end
    end

    // ============================================================
    // Architectural PC advances only at in-order commit
    // ============================================================
    PSC_PC u_PSC_PC (
        .clock             (clock),
        .reset_n           (reset_n),
        .cpu_stop          (cpu_stop),
        .execute_task_done (pc_update_valid),
        .alu_data          (pc_update_alu_data),
        .pc_sel2           (pc_update_branch_taken),
        .decoder_ctrl      (pc_update_ctrl),
        .cpu_trap          (cpu_trap),
        .priv_mode         (priv_mode),
        .d_pf              (d_pf_event),
        .i_pf              (i_pf_event),
        .trap_scause       (trap_scause),
        .csr_state         (csr_state),
        .pc                (pc),
        .counter           (counter)
    );

`ifdef PIPELINE_TRACE
    always_ff @(posedge clock) begin
        if (reset_n && issue_fire &&
            ((forward_sel_rs1 != 3'd0) || (forward_sel_rs2 != 3'd0))) begin
            $display("FWD clock=%0t pc=%08x rs1=x%0d src=%0d data=%08x rs2=x%0d src=%0d data=%08x",
                     $time, id_issue.pc,
                     id_issue.ctrl.r_addr1, forward_sel_rs1, issue_reg_data_1,
                     id_issue.ctrl.r_addr2, forward_sel_rs2, issue_reg_data_2);
        end
        if (reset_n && id_issue.valid && raw_hazard) begin
            $display("RAW-STALL clock=%0t pc=%08x rs1=x%0d stall=%0b rs2=x%0d stall=%0b",
                     $time, id_issue.pc,
                     id_issue.ctrl.r_addr1, raw_hazard_rs1,
                     id_issue.ctrl.r_addr2, raw_hazard_rs2);
        end
        if (reset_n && (id_issue.valid || issue_ex.valid || ex_mem.valid ||
                        mem_wb.valid || commit.valid)) begin
            $display("PIPE clock=%0t ID=%0b:%08x ISSUE=%0b:%08x EX=%0b:%08x MEM=%0b:%08x WB=%0b:%08x COMMIT=%0b:%08x",
                     $time,
                     id_issue.valid, id_issue.pc,
                     issue_fire, id_issue.pc,
                     issue_ex.valid, issue_ex.pc,
                     ex_mem.valid, ex_mem.pc,
                     mem_wb.valid, mem_wb.pc,
                     commit.valid, commit.pc);
        end
    end
`endif

endmodule
