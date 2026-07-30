// NISHIHARU

import PSC_Types::*;

module Branch (
    input  logic        clock,
    input  logic        reset_n,
    input  logic        branch_enb,
    input  logic [31:0] in_vaddr,
    input  logic [31:0] r_data1,
    input  logic [31:0] r_data2,

    // Decoder control
    input  dec_ctrl_t   decoder_ctrl,

    // MMU
    output logic        mmu_valid,
    output logic [31:0] vaddr,
    input  logic        mmu_ready,
    input  logic [31:0] d_paddr,

    // Memory
    output logic [31:0] data_mem_read_address,
    output logic        data_mem_read_valid,
    input  logic        data_mem_req_ready,
    input  logic        data_mem_read_ready,

    // Branch result
    output logic        pc_sel2,

    // Completion
    output logic        busy,
    output logic        branch_done
);

    typedef enum logic [3:0] {
        IDLE, BRANCH_MMU, BRANCH_MMU_W,
        BRANCH_ACCESS, BRANCH_WAIT,
        BRANCH_DONE
    } state_t;

    state_t state;

    function automatic logic branch_exec (
        input logic [2:0]  branch_op,
        input logic [31:0] data1,
        input logic [31:0] data2,
        input logic [1:0]  pc_sel
    );
        unique case (pc_sel)
            // PC + 4
            2'b00: begin
                branch_exec = 1'b0;
            end
            // Conditional branch
            2'b01: begin
                unique case (branch_op)
                    3'b000: begin
                        // BEQ
                        branch_exec = (data1 == data2);
                    end
                    3'b001: begin
                        // BNE
                        branch_exec = (data1 != data2);
                    end
                    3'b100: begin
                        // BLT: signed comparison
                        branch_exec = (
                            $signed(data1) < $signed(data2)
                        );
                    end
                    3'b101: begin
                        // BGE: signed comparison
                        branch_exec = (
                            $signed(data1) >= $signed(data2)
                        );
                    end
                    3'b110: begin
                        // BLTU: unsigned comparison
                        branch_exec = (data1 < data2);
                    end
                    3'b111: begin
                        // BGEU: unsigned comparison
                        branch_exec = (data1 >= data2);
                    end
                    default: begin
                        // Illegal branch operation
                        branch_exec = 1'b0;
                    end
                endcase
            end
            // JAL / JALR
            2'b10: begin
                branch_exec = 1'b1;
            end

            default: begin
                branch_exec = 1'b0;
            end
        endcase
    endfunction

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            state                 <= IDLE;
            pc_sel2               <= 1'b0;
            mmu_valid             <= 1'b0;
            vaddr                 <= 32'd0;
            data_mem_read_valid   <= 1'b0;
            data_mem_read_address <= 32'd0;
            busy                  <= 1'b0;
            branch_done           <= 1'b0;
        end else begin
            // Default pulse outputs
            mmu_valid           <= 1'b0;
            data_mem_read_valid <= 1'b0;
            branch_done         <= 1'b0;

            unique case (state)
                IDLE: begin
                    busy <= 1'b0;
                    pc_sel2 <= branch_exec(
                        decoder_ctrl.funct3,
                        r_data1,
                        r_data2,
                        decoder_ctrl.pc_sel
                    );
                    if (branch_enb && !busy) begin
                        busy <= 1'b1;
                        if (decoder_ctrl.is_load) begin
                            state <= BRANCH_MMU;
                        end else begin
                            state <= BRANCH_DONE;
                        end
                    end
                end

                BRANCH_MMU: begin
                    mmu_valid <= 1'b1;
                    vaddr     <= in_vaddr;
                    state     <= BRANCH_MMU_W;
                end

                BRANCH_MMU_W: begin
                    if (mmu_ready) begin
                        data_mem_read_address <= d_paddr;
                        state                 <= BRANCH_ACCESS;
                    end
                end

                BRANCH_ACCESS: begin
                    if (data_mem_req_ready) begin
                        data_mem_read_valid <= 1'b1;
                        state               <= BRANCH_WAIT;
                    end
                end

                BRANCH_WAIT: begin
                    if (data_mem_read_ready) begin
                        state <= BRANCH_DONE;
                    end

                end

                BRANCH_DONE: begin
                    branch_done <= 1'b1;
                    state       <= IDLE;
                end

                default: begin
                    state                 <= IDLE;
                    mmu_valid             <= 1'b0;
                    data_mem_read_valid   <= 1'b0;
                    data_mem_read_address <= 32'd0;
                    branch_done           <= 1'b0;
                end
            endcase
        end
    end

endmodule