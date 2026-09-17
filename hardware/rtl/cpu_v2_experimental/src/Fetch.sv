// NISHIHARU

module Fetch #(
    parameter logic BURST_MODE = 1'b0
)(
    input  logic        clock,
    input  logic        reset_n,
    input  logic        fetch_enb,
    input  logic        mode_sv32,
    input  logic [31:0] fetch_address,

    // MMU
    output logic        mmu_valid,
    input  logic        mmu_ready,
    output logic [31:0] vaddr,
    input  logic [31:0] paddr,

    // SDRAM
    output logic        program_mem_burst_mode,
    output logic        program_mem_read_valid,
    input  logic        program_mem_read_ready,
    output logic [31:0] program_mem_read_address,
    input  logic [31:0] program_mem_read_data,
    input  logic        program_mem_req_ready,

    // FIFO
    output logic        fifo_read_valid,
    output logic [31:0] fifo_read_data,
    output logic [31:0] fifo_read_pc,

    // PSC_RV32IS
    output logic        done,
    output logic        busy,
    output logic [31:0] opcode
);

    assign fifo_read_pc =
        BURST_MODE
        ? {vaddr[31:4], 4'b0000} + {28'd0, burst_count[1:0], 2'b00}
        : vaddr;

    typedef enum logic [3:0] {
        IDLE       = 4'd0,
        MMU        = 4'd1,
        MMU_WAIT   = 4'd2,
        FETCH_WAIT = 4'd3,
        FETCH      = 4'd4,
        FETCH_DONE = 4'd5
    } state_t;

    state_t state;

    logic [2:0] burst_count;
    logic [1:0] burst_start_word;

    assign program_mem_burst_mode = BURST_MODE;

    // burst時は要求PCより前のwordをFIFOへ入れない
    assign fifo_read_valid =
        program_mem_read_ready &&
        (!BURST_MODE || (burst_count[1:0] >= burst_start_word));

    assign fifo_read_data = program_mem_read_data;

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            state                    <= IDLE;
            vaddr                    <= 32'h0;
            mmu_valid                <= 1'b0;
            program_mem_read_valid   <= 1'b0;
            program_mem_read_address <= 32'h0;
            done                     <= 1'b0;
            busy                     <= 1'b0;
            opcode                   <= 32'd0;
            burst_count              <= 3'd0;
            burst_start_word         <= 2'd0;
        end else begin
            mmu_valid                <= 1'b0;
            program_mem_read_valid   <= 1'b0;
            done                     <= 1'b0;

            unique case (state)
                IDLE: begin
                    if (fetch_enb) begin
                        vaddr            <= fetch_address;
                        busy             <= 1'b1;
                        burst_count      <= 3'd0;
                        burst_start_word <= fetch_address[3:2];
                        if (mode_sv32)
                            state        <= MMU;
                        else
                            state        <= FETCH;
                    end
                end

                MMU: begin
                    if (program_mem_req_ready) begin
                        mmu_valid                <= 1'b1;
                        program_mem_read_address <= paddr;
                        state                    <= MMU_WAIT;
                    end
                end

                MMU_WAIT: begin
                    if (mmu_ready) begin
                        burst_count      <= 3'd0;
                        burst_start_word <= paddr[3:2];
                        state            <= FETCH;
                    end
                end

                FETCH: begin
                    if (program_mem_req_ready) begin
                        burst_count <= 3'd0;
                        if (BURST_MODE) begin
                            program_mem_read_valid   <= 1'b1;
                            program_mem_read_address <= {vaddr[31:4], 4'b0000};
                            state                    <= FETCH_WAIT;
                        end else begin
                            program_mem_read_valid   <= 1'b1;
                            program_mem_read_address <= vaddr;
                            state                    <= FETCH_WAIT;
                        end

                    end
                end

                FETCH_WAIT: begin
                    if (program_mem_read_ready) begin
                        // opcodeには要求アドレスの命令を保存
                        if (!BURST_MODE) begin
                            opcode <= program_mem_read_data;
                        end else if (burst_count[1:0] == burst_start_word) begin
                            opcode <= program_mem_read_data;
                        end

                        if (BURST_MODE) begin
                            if (burst_count == 3'd3) begin
                                burst_count <= 3'd0;
                                state       <= FETCH_DONE;
                            end else begin
                                burst_count <= burst_count + 3'd1;
                            end
                        end else begin
                            state <= FETCH_DONE;
                        end
                    end
                end

                FETCH_DONE: begin
                    busy  <= 1'b0;
                    done  <= 1'b1;
                    state <= IDLE;
                end

                default: begin
                    state                  <= IDLE;
                    mmu_valid              <= 1'b0;
                    program_mem_read_valid <= 1'b0;
                    done                   <= 1'b0;
                    busy                   <= 1'b0;
                    burst_count            <= 3'd0;
                end
            endcase
        end
    end

endmodule