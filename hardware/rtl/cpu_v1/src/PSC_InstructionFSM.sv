// NISHIHARU

//`define PIPELINE_DEBUG_MODE

import PSC_Types::*;

module PSC_InstructionFSM (
    input  logic        clock,
    input  logic        reset_n,
    input  logic        cpu_stop,

    // Decoder struct
    input  dec_ctrl_t   decoder_ctrl,
    output dec_ctrl_t   decoder_ctrl_now,

    input  instruction_state_t inst_state,

    // FIFO / completion
    input  logic        fifo_req_ready,
    input  logic        fifo_read_ready,    // not used
    input  logic        decode_done,
    input  logic        alu_done,
    input  logic        branch_done,
    input  logic        store_done,

    // State decode
    output logic        IDLE_st,
    output logic        FIFO_READ_st,
    output logic        DECODE_st,
    output logic        REGISTER_READ_st,
    output logic        EXECUTE_st,
    output logic        BRANCH_st,
    output logic        STORE_st,

    // Pipeline 
    input  logic        ri_wb_done,

    // Completion pulse
    output logic        fsm_task_busy,
    output logic        fsm_task_done
);

    typedef enum logic [3:0] {
        ST_IDLE,
        ST_FIFO_READ,
        ST_DECODE,
        ST_REGISTER_READ,
        ST_EXECUTE,
        ST_BRANCH,
        ST_STORE,
        ST_PIPELINE_W
    } execute_state_t;

    execute_state_t execute_state;
    execute_state_t next_state;

    execute_state_t execute_state_d;

    // ============================================================
    // State register
    // ============================================================
    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            execute_state   <= ST_IDLE;
            execute_state_d <= ST_IDLE;
            decoder_ctrl_now <= '0;
        end else if (cpu_stop) begin
            execute_state   <= ST_IDLE;
            execute_state_d <= ST_IDLE;
            decoder_ctrl_now <= '0;
        end else begin
            execute_state   <= next_state;
            execute_state_d <= execute_state;
            if (decode_done)
                decoder_ctrl_now   <= decoder_ctrl;
        end
    end

    // ============================================================
    // Next-state logic
    // ============================================================
    always_comb begin
        next_state = execute_state;

        unique case (execute_state)

            ST_IDLE: begin
                if (fifo_req_ready)
                    next_state = ST_FIFO_READ;
            end

            ST_FIFO_READ: begin
                next_state = ST_DECODE;
            end

            ST_DECODE: begin
                if (decode_done)
                    next_state = ST_REGISTER_READ;
            end

            ST_REGISTER_READ: begin
                `ifndef PIPELINE_DEBUG_MODE
                if (decoder_ctrl_now.pipeline_type)
                    //next_state = ST_PIPELINE_W;     // TBD
                    next_state = ST_IDLE;
                else
                    next_state = ST_EXECUTE;
                `else
                next_state = ST_EXECUTE;
                `endif
            end

            ST_EXECUTE: begin
                if (alu_done)
                    next_state = ST_BRANCH;
            end

            ST_BRANCH: begin
                if (branch_done)
                    next_state = ST_STORE;
            end

            ST_STORE: begin
                if (store_done)
                    next_state = ST_IDLE;
            end

            // Debug(未使用)
            ST_PIPELINE_W: begin
                if (ri_wb_done)
                    next_state = ST_IDLE;
            end

            default: begin
                next_state = ST_IDLE;
            end

        endcase
    end

    // ============================================================
    // State decode
    // ============================================================
    assign IDLE_st          = (execute_state == ST_IDLE);
    assign FIFO_READ_st     = (execute_state == ST_FIFO_READ);
    assign DECODE_st        = (execute_state == ST_DECODE);
    assign REGISTER_READ_st = (execute_state == ST_REGISTER_READ);
    assign EXECUTE_st       = (execute_state == ST_EXECUTE);
    assign BRANCH_st        = (execute_state == ST_BRANCH);
    assign STORE_st         = (execute_state == ST_STORE);

    assign fsm_task_busy = 
                (execute_state != ST_IDLE);

    assign fsm_task_done =
                IDLE_st && ((execute_state_d == ST_STORE) || (execute_state_d == ST_PIPELINE_W));

endmodule