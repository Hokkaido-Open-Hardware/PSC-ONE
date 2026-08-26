// NISHIHARU

//`define fifo_pipeline_off

module PSC_RV32ISP_FetchUnit #(
    parameter logic BURST_MODE = 1'b1,
    parameter int   FIFO_DEPTH = 16
)(
    input  logic        clock,
    input  logic        reset_n,
    input  logic        cpu_stop,
    input  logic        fetch_valid,
    output logic        fetch_ready,
    input  logic        execute_task_busy,
    input  logic        execute_task_done,

    // FIFO
    output logic        fifo_req_ready,
    output logic        fifo_full,
    input  logic        fifo_read_valid,
    output logic        fifo_read_ready,
    input  logic        fifo_flush,

    input  logic [31:0] pc,
    input  logic [31:0] csr_satp,
    input  logic [1:0]  priv_mode,
    input  logic        is_load,
    input  logic        is_store,
    input  logic        is_sfence_vma,
    output logic        fifo_ready,
    output logic        i_pf,

    // Program memory
    output logic        program_mem_burst_mode,
    output logic        program_mem_read_valid,
    input  logic        program_mem_read_ready,
    output logic [31:0] program_mem_read_address,
    input  logic [31:0] program_mem_read_data,
    input  logic        program_mem_req_ready,

    // MMU memory
    output logic        data_mem_read_valid,
    input  logic        data_mem_read_ready,
    output logic [31:0] data_mem_read_address,
    input  logic [31:0] data_mem_read_data,
    input  logic        data_mem_read_req_ready,

    output logic [31:0] opcode,
    output logic [31:0] fifo_opcode_data,
    output logic [31:0] out_fetch_pc
);

    typedef enum logic [3:0] {
        IDLE, 
        FETCH_PC, 
        FETCH, 
        FETCH_W, 
        EXECUTE_W,
        FIFO_FLUSH_WAIT,
        FIFO_FLUSH_WAIT_PC
    } state_t;

    state_t fetch_state, next_state;
    logic [15:0] fetch_wakeup_timer;
    logic [31:0] fetch_pc, next_pc;
    logic fetch_state_fifo_flush;
    logic next_ready;
    logic initial_fetch;

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            fetch_state <= IDLE;
            fetch_wakeup_timer <= 16'd0;
            fetch_pc    <= 32'd0;
            fetch_ready <= 1'b0;
            initial_fetch <= 1'b1;
        end else if (cpu_stop) begin
            fetch_state <= IDLE;
            fetch_wakeup_timer <= 16'd0;
            fetch_ready <= 1'b0;
        end else begin
            if (fetch_wakeup_timer < 16'h400)
                fetch_wakeup_timer <= fetch_wakeup_timer + 16'd1;
            fetch_state <= next_state;
            fetch_pc    <= next_pc;
            fetch_ready <= next_ready;
            if (initial_fetch && (fetch_state == IDLE) &&
                fetch_valid && (fetch_wakeup_timer > 16'h300))
                initial_fetch <= 1'b0;
        end
    end

    always_comb begin
        next_state = fetch_state;
        next_pc    = fetch_pc;
        next_ready = 1'b0;
        fetch_state_fifo_flush = 1'b0;

        // fifo_flush
        if (fifo_flush) begin
            next_state = FIFO_FLUSH_WAIT;
        
        // 通常state
        end else begin

            case (fetch_state)
                // ----------------------------------------
                IDLE:
                    if (fetch_valid && (fetch_wakeup_timer > 16'h300)) begin
                        // Hide the one-time fill latency of the v2 ID/ISSUE
                        // register.  Redirect refills still use FETCH_PC.
                        if (initial_fetch &&
                            ((BURST_MODE && (count <= FIFO_DEPTH - 4)) ||
                             (!BURST_MODE && !full))) begin
                            `ifdef fifo_pipeline_off
                            next_pc = pc;
                            `endif
                            next_state = FETCH;
                        end else begin
                            next_state = FETCH_PC;
                        end
                    end

                FETCH_PC:
                    if (BURST_MODE) begin
                        if (count <= FIFO_DEPTH - 4)
                            next_state = FETCH;
                    end else begin
                        if (!full)
                            `ifdef fifo_pipeline_off
                            next_pc    = pc;
                            `endif
                            next_state = FETCH;
                    end

                FETCH:
                    next_state = FETCH_W;

                FETCH_W:
                    if (fetch_done) begin
                        next_ready = 1'b1;
                        next_state = EXECUTE_W;
                    end

                EXECUTE_W: begin
                    `ifdef fifo_pipeline_off
                    if (execute_task_done) begin        // fifo pileline off mode
                        next_state = FETCH_PC;
                    end
                    `else
                    if (BURST_MODE)
                        next_pc = {fetch_pc[31:4], 4'b0000} + 32'd16;
                        //next_pc    = fetch_pc + 32'd16;      // fetch_pc + 16
                    else
                        next_pc    = fetch_pc + 32'd4;      // fetch_pc + 4
                    next_state = FETCH_PC;
                    `endif
                end

                // ----------------------------------------
                FIFO_FLUSH_WAIT: begin
                    fetch_state_fifo_flush = 1'b1;
                    if (!fetch_busy && !execute_task_busy) begin
                        next_state = FIFO_FLUSH_WAIT_PC;
                    end
                end

                FIFO_FLUSH_WAIT_PC: begin
                    next_pc    = pc;
                    next_state = IDLE;
                end

                default: begin
                    next_pc    = pc;
                    next_state = IDLE;
                end
            endcase
        end
    end

    // =====================================
    // FETCH, FETCH-FIFO
    // =====================================
    // Fetch
    logic opcode_read_valid, fetch_done, fetch_busy;
    logic [31:0] opcode_read_data;
    logic mmu_valid, i_mmu_done;
    logic [31:0] vaddr, i_paddr;
    logic fetch_enb;
    logic [31:0] opcode_read_pc;
    assign fetch_enb = (fetch_state == FETCH);

    Fetch #(
        .BURST_MODE               (BURST_MODE)
    ) u_fetch(
        .clock                    (clock),
        .reset_n                  (reset_n),
        .fetch_enb                (fetch_enb),
        .mode_sv32                (i_mode_sv32),
        .fetch_address            (fetch_pc),
        .mmu_valid                (mmu_valid),
        .mmu_ready                (i_mmu_done),
        .vaddr                    (vaddr),
        .paddr                    (i_paddr),
        .program_mem_burst_mode   (program_mem_burst_mode),
        .program_mem_read_valid   (program_mem_read_valid),
        .program_mem_read_ready   (program_mem_read_ready),
        .program_mem_read_address (program_mem_read_address),
        .program_mem_read_data    (program_mem_read_data),
        .program_mem_req_ready    (program_mem_req_ready),
        .fifo_read_valid          (opcode_read_valid),
        .fifo_read_data           (opcode_read_data),
        .fifo_read_pc             (opcode_read_pc),
        .done                     (fetch_done),
        .busy                     (fetch_busy),
        .opcode                   (opcode)
    );

    // FIFO
    logic in_ready;
    localparam int ADDR_BITS = $clog2(FIFO_DEPTH);
    logic [ADDR_BITS:0] count;

    logic full, empty;
    assign fifo_req_ready = !empty;
    assign fifo_full  = full;

    Fetch_Fifo #(
        .WIDTH                    (32),
        .DEPTH                    (FIFO_DEPTH)
    ) u_fetch_fifo(
        .clock                    (clock),
        .reset_n                  (reset_n),
        .in_valid                 (opcode_read_valid),
        .in_data                  (opcode_read_data),
        .in_pc_data               (opcode_read_pc),
        .in_ready                 (in_ready),
        .out_req_ready            (fifo_ready),
        .out_valid                (fifo_read_valid),
        .out_ready                (fifo_read_ready),
        .out_data                 (fifo_opcode_data),
        .out_pc_data              (out_fetch_pc),
        .full                     (full),
        .empty                    (empty),
        .count                    (count),
        .flush                    (
            fifo_flush || 
            fetch_state_fifo_flush || 
            cpu_stop
        )
    );


    // =====================================
    // I-MMU
    // =====================================
    // Instruction-side MMU
    logic i_mode_sv32;
    logic cpu_state_done;
    assign cpu_state_done = (fetch_state == FETCH_W);

    MMU u_mmu_i(
        .clk                      (clock),
        .reset_n                  (reset_n),
        .MMU_enb                  (mmu_valid),
        .vaddr                    (vaddr),
        .satp                     (csr_satp),
        .priv_mode                (priv_mode),
        .access_r                 (1'b0),
        .access_w                 (1'b0),
        .access_x                 (1'b1),
        .mem_req_ready            (data_mem_read_req_ready),
        .mem_rdata                (data_mem_read_data),
        .mem_addr                 (data_mem_read_address),
        .mem_valid                (data_mem_read_valid),
        .mem_ready                (data_mem_read_ready),
        .cpu_state_done           (cpu_state_done),
        .sfence_vma               (fifo_flush && is_sfence_vma),
        .paddr                    (i_paddr),
        .page_fault               (i_pf),
        .mode_sv32                (i_mode_sv32),
        .mmu_done                 (i_mmu_done)
    );

endmodule
