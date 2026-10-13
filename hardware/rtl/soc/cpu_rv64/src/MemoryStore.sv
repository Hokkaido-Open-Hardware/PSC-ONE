`timescale 1ns/1ps
// NISHIHARU

import PSC_Types::*;

module MemoryStore #(
    parameter logic [63:0] UART_MMIO_ADDR    = 64'h0000_FFF0,
    parameter logic [63:0] UART_MMIO_FLAG    = 64'h0000_FFF4,
    parameter logic [63:0] COUNTER_MMIO_ADDR = 64'h0000_FFF8
)(
    input  logic        clock,
    input  logic        reset_n,
    input  logic        store_enb,
    input  logic        mode_translate,
    input  logic [63:0] alu_data,
    input  logic [2:0]  mem_val,
    input  logic [63:0] mem_read_data,
    input  logic [63:0] r_data2,
    input  logic [63:0] in_pc,
    input  logic [63:0] counter,
    input  logic [2:0]  ld_low3,
    input  logic [63:0] csr_rdata,
    input  dec_ctrl_t   decoder_ctrl,

    // MMU
    output logic        mmu_valid,
    output logic [63:0] vaddr,
    input  logic        mmu_ready,
    input  logic        access_fault,
    input  logic [63:0] d_paddr,

    // Memory
    output logic [63:0] data_mem_write_address,
    output logic        data_mem_write_valid,
    output logic [63:0] data_mem_write_data,
    input  logic        data_mem_write_ready,
    input  logic        data_mem_req_ready,

    output logic [8:0]  uart,
    output logic [63:0] w_data,
    output logic        busy,
    output logic        store_done
);

    typedef enum logic [2:0] {
        IDLE, STORE_MMU, STORE_MMU_W, STORE_ACCESS,
        STORE_WAIT, STORE_DONE
    } state_t;

    state_t state;

    logic [63:0] mem_addr, mem_data, ld_result;
    logic [63:0] shifted;
    logic is_lw;
    logic is_mmio_counter, is_mmio_uart_flag;
    assign vaddr = alu_data;
    assign mem_addr = alu_data;
    assign shifted = mem_read_data >> {ld_low3, 3'b0};
    assign is_lw = mem_val == 3'b010;
    always_comb begin
        case (mem_val)
            3'b000: ld_result = {{56{shifted[7]}}, shifted[7:0]};
            3'b001: ld_result = {{48{shifted[15]}}, shifted[15:0]};
            3'b010: ld_result = {{32{shifted[31]}}, shifted[31:0]};
            3'b011: ld_result = shifted;
            3'b100: ld_result = {56'b0, shifted[7:0]};
            3'b101: ld_result = {48'b0, shifted[15:0]};
            3'b110: ld_result = {32'b0, shifted[31:0]};
            default: ld_result = '0;
        endcase
    end

    assign is_mmio_counter   = is_lw && (mem_addr == COUNTER_MMIO_ADDR);
    assign is_mmio_uart_flag = (mem_val[1:0] == 2'b00) && (mem_addr == UART_MMIO_FLAG);

    assign mem_data = decoder_ctrl.mem_rw ? 64'd0 :
                      is_mmio_counter     ? counter :
                      is_mmio_uart_flag   ? 64'd1  : ld_result;

    logic [63:0] w_data_w;
    assign w_data_w = (decoder_ctrl.wb_sel == 2'b00) ? alu_data :
                      (decoder_ctrl.wb_sel == 2'b01) ? mem_data :
                      (decoder_ctrl.wb_sel == 2'b10) ? in_pc + 64'd4 :
                                                       csr_rdata;

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            state                  <= IDLE;
            mmu_valid              <= 1'b0;
            data_mem_write_valid   <= 1'b0;
            data_mem_write_data    <= 64'd0;
            data_mem_write_address <= 64'd0;
            uart                   <= 9'd0;
            w_data                 <= 64'h0;
            busy                   <= 1'b0;
            store_done             <= 1'b0;
        end else begin
            mmu_valid            <= 1'b0;
            data_mem_write_valid <= 1'b0;
            store_done           <= 1'b0;

            case (state)
                IDLE: begin
                    busy       <= 1'b0;
                    if (store_enb && !busy) begin
                        busy   <= 1'b1;
                        w_data <= w_data_w;
                        if (decoder_ctrl.mem_rw)
                            state <= STORE_MMU;
                        else
                            state <= STORE_DONE;
                    end
                end

                STORE_MMU: begin
                    if (mode_translate) begin
                        mmu_valid <= 1'b1;
                        state     <= STORE_MMU_W;
                    end else begin
                        data_mem_write_address <= vaddr;
                        state <= STORE_ACCESS;
                    end
                end

                STORE_MMU_W:
                    if (mmu_ready) begin
                        if (access_fault) begin
                            state <= STORE_DONE;
                        end else begin
                            data_mem_write_address <= d_paddr;
                            state                  <= STORE_ACCESS;
                        end
                    end

                STORE_ACCESS:
                    if (data_mem_req_ready) begin
                        data_mem_write_valid <= 1'b1;
                        data_mem_write_data  <= r_data2;
                        uart <= (mem_addr == UART_MMIO_ADDR)
                              ? {1'b1, r_data2[7:0]} : 9'd0;
                        state <= STORE_WAIT;
                    end

                STORE_WAIT:
                    if (data_mem_write_ready) begin
                        state <= STORE_DONE;
                    end

                STORE_DONE: begin
                    store_done <= 1'b1;
                    state      <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
