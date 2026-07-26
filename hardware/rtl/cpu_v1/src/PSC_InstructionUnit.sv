// NISHIHARU

import PSC_Types::*;

module PSC_InstructionUnit (
    input  logic        clock,
    input  logic        reset_n,
    input  logic        cpu_stop,
    input  logic        cpu_trap,
    input  logic [1:0]  priv_mode,

    // PC, OPCODE
    output logic [31:0] pc,
    output logic [31:0] counter,
    input  logic [31:0] opcode,
    input  logic [31:0] pc_now,

    // Cell state
    output logic        EXECUTE_st,
    output logic        BRANCH_st,
    output logic        BRANCH_W_st,
    output logic        STORE_st,
    output logic        STORE_W_st,

    // FIFO
    input  logic        fifo_req_ready,
    input  logic        fifo_read_ready,
    output logic        fifo_read_valid,
    output logic        fifo_flush,

    // Decoder struct
    input  dec_ctrl_t   decoder_ctrl,
    output dec_ctrl_t   decoder_ctrl_now,

    // Excute
    input  logic [31:0] alu_data,

    // Pipeline alu control
    output logic        ri_execute_valid,      
    output dec_ctrl_t   ri_execute_ctrl,       
    output logic [31:0] ri_execute_reg_data_1,
    output logic [31:0] ri_execute_reg_data_2,
    input  logic [31:0] ri_alu_data,
    input  logic        ri_alu_done,

    // Branch
    input  logic        pc_sel2,
    output logic [1:0]  ld_low2_q,
    output logic [31:0] branch_rdata,

    // Register
    output logic [31:0] reg_data_1,
    output logic [31:0] reg_data_2,
    input  logic [31:0] w_data,

    // CSR
    input csr_state_t   csr_state,
    output logic        csr_enb,
    output logic        csr_valid,

    // Module enable
    output logic        decode_enb,
    output logic        execute_enb,
    output logic        branch_enb,
    output logic        memory_store_enb,
    output logic        register_store_enb,

    // Datapath
    input  logic [1:0]  alu_data_low2,
    input  logic [31:0] branch_mem_read_data,

    // Completion
    input  logic        decode_done,
    input  logic        alu_done,
    input  logic        branch_done,
    input  logic        store_done,

    // Page Fault
    input  logic        d_pf,
    input  logic        i_pf,
    input  logic [4:0]  trap_scause,

    output logic        execute_task_busy,
    output logic        execute_task_done
);

    typedef struct packed {
        logic        valid;
        dec_ctrl_t   decoder_ctrl;
        logic [31:0] reg_data_1;
        logic [31:0] reg_data_2;
    } ri_id_ex_t;

    typedef struct packed {
        logic        valid;
        logic [4:0]  w_addr;
        logic        rf_wen;
        logic [31:0] alu_data;
    } ri_ex_wb_t;

    ri_id_ex_t ri_id_ex;
    ri_ex_wb_t ri_ex_wb;

    instruction_state_t inst_state;

    // ============================================================
    // Register file signals
    // ============================================================
    PSC_Register u_regfile (
        .clock             (clock),
        .reset_n           (reset_n),
        .register_wenb     (regfile_wen),
        .rf_wen            (regfile_wen),
        .w_addr            (regfile_waddr),
        .w_data            (regfile_wdata),
        .r_addr1           (decoder_ctrl.r_addr1),
        .r_addr2           (decoder_ctrl.r_addr2),
        .reg_data_1        (reg_data_1),
        .reg_data_2        (reg_data_2)
    );

    // ============================================================
    // PROGRAM COUNTER
    // ============================================================
    assign execute_task_busy = fsm_task_busy || ri_pipeline_busy;
    assign execute_task_done = fsm_task_done || ri_wb_commit;

    PSC_PC u_PSC_PC (
        .clock             (clock),
        .reset_n           (reset_n),
        .cpu_stop          (cpu_stop),

        .execute_task_done (execute_task_done),
        .alu_data          (alu_data),
        .pc_sel2           (pc_sel2),
        .decoder_ctrl      (decoder_ctrl_now),

        .cpu_trap          (cpu_trap),
        .priv_mode         (priv_mode),

        .d_pf              (d_pf),
        .i_pf              (i_pf),

        .trap_scause       (trap_scause[4:0]),
        .csr_state         (csr_state),

        .pc                (pc),
        .counter           (counter)
    );

    // ============================================================
    // Saved datapath values
    // ============================================================
    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            branch_rdata    <= 32'b0;
            ld_low2_q       <= 2'b0;
        end else begin
            if (alu_done && decoder_ctrl_now.is_load)
                ld_low2_q <= alu_data_low2;
            if (branch_done)
                branch_rdata <= branch_mem_read_data;
        end
    end

    // ============================================================
    // Cell state
    // ============================================================
    logic fsm_task_busy;
    logic fsm_task_done;

    PSC_InstructionFSM u_PSC_inst_fsm (
        .clock                (clock),
        .reset_n              (reset_n),
        .cpu_stop             (cpu_stop),

        .decoder_ctrl         (decoder_ctrl),
        .decoder_ctrl_now     (decoder_ctrl_now),
        .inst_state           (inst_state),

        .fifo_req_ready       (fifo_req_ready),
        .fifo_read_ready      (fifo_read_ready),
        .decode_done          (decode_done),
        .alu_done             (alu_done),
        .branch_done          (branch_done),
        .store_done           (store_done),

        .IDLE_st              (IDLE_st),
        .FIFO_READ_st         (FIFO_READ_st),
        .DECODE_st            (DECODE_st),
        .REGISTER_READ_st     (REGISTER_READ_st),
        .EXECUTE_st           (EXECUTE_st),
        .BRANCH_st            (BRANCH_st),
        .BRANCH_W_st          (BRANCH_W_st),
        .STORE_st             (STORE_st),
        .STORE_W_st           (STORE_W_st),

        .ri_wb_done           (ri_ex_complete),

        .fsm_task_busy        (fsm_task_busy),
        .fsm_task_done        (fsm_task_done)
    );

    logic IDLE_st;
    logic FIFO_READ_st;
    logic DECODE_st;
    logic REGISTER_READ_st;

    // ============================================================
    // R/I-Type ID/EX pipeline register
    // ============================================================
    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            ri_id_ex <= '0;
        end else if (ri_pipeline_flush) begin
            ri_id_ex <= '0;
        end else begin
            if (ri_id_ex_issue) begin
                ri_id_ex.valid        <= 1'b1;
                ri_id_ex.decoder_ctrl <= decoder_ctrl_now;
                ri_id_ex.reg_data_1   <= reg_data_1;
                ri_id_ex.reg_data_2   <= reg_data_2;
            end else if (ri_ex_complete && ri_ex_wb_ready) begin
                ri_id_ex.valid <= 1'b0;
            end
        end
    end

    assign ri_execute_valid =
                ri_id_ex.valid;
    assign ri_execute_ctrl =
                ri_id_ex.decoder_ctrl;
    assign ri_execute_reg_data_1 =
                ri_id_ex.reg_data_1;
    assign ri_execute_reg_data_2 =
                ri_id_ex.reg_data_2;

    // ============================================================
    // RAW Hazard
    // ============================================================
    logic raw_hazard_id_ex;
    logic raw_hazard_ex_wb;
    logic raw_hazard;

    assign raw_hazard_id_ex =
                ri_id_ex.valid                         &&
                ri_id_ex.decoder_ctrl.rf_wen           &&
                (ri_id_ex.decoder_ctrl.w_addr != 5'd0) &&
                (
                    (
                        decoder_ctrl_now.use_rs1 &&
                        decoder_ctrl_now.r_addr1 ==
                            ri_id_ex.decoder_ctrl.w_addr
                    ) ||
                    (
                        decoder_ctrl_now.use_rs2 &&
                        decoder_ctrl_now.r_addr2 ==
                            ri_id_ex.decoder_ctrl.w_addr
                    )
                );

    assign raw_hazard_ex_wb =
                ri_ex_wb.valid            &&
                ri_ex_wb.rf_wen           &&
                (ri_ex_wb.w_addr != 5'd0) &&
                (
                    (
                        decoder_ctrl_now.use_rs1 &&
                        decoder_ctrl_now.r_addr1 ==
                            ri_ex_wb.w_addr
                    ) ||
                    (
                        decoder_ctrl_now.use_rs2 &&
                        decoder_ctrl_now.r_addr2 ==
                            ri_ex_wb.w_addr
                    )
                );

    // DECORD -> FIFO READ -> DECORDまで4CLKなので
    // raw_hazardしない (TBD)
    assign raw_hazard =
                raw_hazard_id_ex ||
                raw_hazard_ex_wb;

    // ============================================================
    // Pipeline control
    // ============================================================
    logic ri_pipeline_flush;
    logic ri_id_ex_ready;
    logic ri_id_ex_issue;
    logic ri_ex_wb_ready;
    logic ri_ex_complete;
    logic ri_wb_commit;
    logic ri_pipeline_busy;

    assign ri_pipeline_flush =
                fifo_flush ||
                cpu_trap   ||
                d_pf       ||
                i_pf;

    assign ri_ex_wb_ready =
                !ri_ex_wb.valid ||
                ri_wb_commit;

    assign ri_id_ex_ready =
                !ri_id_ex.valid ||
                (ri_ex_complete && ri_ex_wb_ready);

    assign ri_id_ex_issue =
                REGISTER_READ_st                    &&
                decoder_ctrl_now.pipeline_type      &&
                ri_id_ex_ready                      &&
                !raw_hazard;

    assign ri_pipeline_busy =
                ri_id_ex.valid ||
                ri_ex_wb.valid;

    assign ri_ex_complete =
                ri_id_ex.valid &&
                ri_alu_done;

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            ri_ex_wb <= '0;
        end else if (ri_pipeline_flush) begin
            ri_ex_wb <= '0;
        end else begin
            if (ri_ex_complete && ri_ex_wb_ready) begin
                ri_ex_wb.valid    <= ri_id_ex.decoder_ctrl.rf_wen &&
                                    (ri_id_ex.decoder_ctrl.w_addr != 5'd0);
                ri_ex_wb.w_addr   <= ri_id_ex.decoder_ctrl.w_addr;
                ri_ex_wb.rf_wen   <= ri_id_ex.decoder_ctrl.rf_wen;
                ri_ex_wb.alu_data <= ri_alu_data;
            end else if (ri_wb_commit) begin
                ri_ex_wb.valid <= 1'b0;
            end
        end
    end

    // ============================================================
    // Instruction state registers
    // ============================================================
    logic        normal_wb_valid;
    logic        regfile_wen;
    logic [4:0]  regfile_waddr;
    logic [31:0] regfile_wdata;

    assign normal_wb_valid =
                STORE_W_st &&
                store_done &&
                decoder_ctrl_now.rf_wen &&
                (decoder_ctrl_now.w_addr != 5'd0);

    // 通常WBを優先
    assign ri_wb_commit =
                ri_ex_wb.valid &&
                !normal_wb_valid;

    assign regfile_wen =
                normal_wb_valid ||
                ri_wb_commit;

    assign regfile_waddr =
                normal_wb_valid
                    ? decoder_ctrl_now.w_addr
                    : ri_ex_wb.w_addr;

    assign regfile_wdata =
                normal_wb_valid
                    ? w_data
                    : ri_ex_wb.alu_data;

    // ============================================================
    // Instruction state registers
    // ============================================================
    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            inst_state <= '0;
        end else begin
            if (FIFO_READ_st && fifo_read_ready) begin
                inst_state.valid  <= 1'b1;
                inst_state.pc     <= pc_now;
                inst_state.opcode <= opcode;
            end

            if (DECODE_st && decode_done) begin
                inst_state.decoder_ctrl <= decoder_ctrl;
                inst_state.reg_data_1   <= reg_data_1;
                inst_state.reg_data_2   <= reg_data_2;
            end

            if (EXECUTE_st && alu_done) begin
                inst_state.alu_data      <= alu_data;
                inst_state.alu_data_low2 <= alu_data_low2;
            end

            if (BRANCH_W_st && branch_done) begin
                inst_state.pc_sel2      <= pc_sel2;
                inst_state.branch_rdata <= branch_mem_read_data;
            end

            if (STORE_W_st && store_done) begin
                inst_state.w_data <= w_data;
                inst_state.valid  <= 1'b0;
            end
        end
    end

    // FIFO
    assign fifo_read_valid = FIFO_READ_st;
    assign fifo_flush =
                STORE_st &&
                (
                    pc_sel2                        ||
                    decoder_ctrl_now.is_sfence_vma ||
                    decoder_ctrl_now.is_fence_i    ||
                    decoder_ctrl_now.is_ecall      ||
                    decoder_ctrl_now.is_mret       ||
                    decoder_ctrl_now.is_sret       ||
                    cpu_trap
                );

    // Module enable
    assign decode_enb =
                DECODE_st &&
                fifo_read_ready;
    assign execute_enb = 
                EXECUTE_st;
    assign branch_enb = 
                BRANCH_st;
    assign memory_store_enb = 
                STORE_st;
    assign register_store_enb =
                STORE_W_st                &&
                store_done                &&
                decoder_ctrl_now.rf_wen   &&
                (decoder_ctrl_now.w_addr != 5'd0);
    // CSR
    assign csr_enb =
                BRANCH_W_st &&
                branch_done;
    assign csr_valid = 
                execute_task_done;

endmodule