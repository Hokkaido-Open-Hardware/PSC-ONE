`timescale 1ns/1ps
// NISHIHARU
import PSC_Types::*;

// Pipeline MEM controller; branch/jump decisions remain in PSC_InstructionUnit.
module Branch #(
    parameter logic [63:0] UART_MMIO_ADDR = 64'hF004_00F0
)(
    input  logic        clock,
    input  logic        reset_n,
    input  logic        cpu_stop,
    input  logic        valid,
    input  dec_ctrl_t   decoder_ctrl,
    input  logic [63:0] in_vaddr,
    input  logic [63:0] r_data2,
    input  logic        mode_translate,
    output logic        mmu_valid,
    input  logic        mmu_ready,
    input  logic        access_fault,
    input  logic [63:0] d_paddr,
    output logic [63:0] data_mem_address,
    output logic [63:0] data_mem_write_data,
    output logic [2:0]  data_mem_sel,
    input  logic [63:0] data_mem_read_data,
    output logic [63:0] load_data,
    output logic        load_unaligned,
    output logic        data_mem_read_valid,
    output logic        data_mem_write_valid,
    input  logic        data_mem_req_ready,
    input  logic        data_mem_read_ready,
    input  logic        data_mem_write_ready,
    output logic [8:0]  uart,
    output logic        pending,
    output logic        done,
    output logic        misaligned_fault
);
    // EX/MEM holds address, rs2, funct3, rd and PC until the transaction completes.
    logic mmu_started;
    logic translated;
    logic [63:0] translated_address;
    logic misaligned_address;
    logic [2:0] byte_index;
    logic [63:0] load_bytes;
    logic [63:0] read_lane;
    logic [63:0] access_address;
    logic response_ready;
    logic last_byte;
    logic response_misaligned;
    logic response_last_byte;

    // Bare-memory misaligned accesses are serialized into byte transactions.
    // EX/MEM remains held until the final byte has completed.
    assign misaligned_address =
        (((decoder_ctrl.funct3 == 3'b001) ||
          (decoder_ctrl.is_load && decoder_ctrl.funct3 == 3'b101)) && in_vaddr[0]) ||
        (((decoder_ctrl.funct3 == 3'b010) ||
          (decoder_ctrl.is_load && decoder_ctrl.funct3 == 3'b110)) && (|in_vaddr[1:0])) ||
        ((decoder_ctrl.funct3 == 3'b011) && (|in_vaddr[2:0]));
    assign access_address = mode_translate ? translated_address : in_vaddr;
    assign response_ready = decoder_ctrl.is_store
                          ? data_mem_write_ready : data_mem_read_ready;
    assign last_byte = {1'b0, byte_index} ==
                       ((4'd1 << decoder_ctrl.funct3[1:0]) - 4'd1);
    // Decode response controls at request launch, before pending can be set.
    // EX/MEM is held for the entire access; this preserves completion timing
    // while removing funct3/address decode from the pipeline ready feedback.
    assign done = pending && response_ready &&
                  (!response_misaligned || response_last_byte);
    assign data_mem_sel = misaligned_address ? 3'b000 : decoder_ctrl.funct3;
    assign load_unaligned = response_misaligned;
    assign read_lane = data_mem_read_data >> {data_mem_address[2:0], 3'b0};
    // Include the final response combinationally for MEM/WB's completion edge.
    assign load_data = response_misaligned
                    ? load_bytes | ({56'b0, read_lane[7:0]} << {byte_index, 3'b0})
                    : data_mem_read_data;

    // Pulse one cache request after req_ready, then hold pending until its response.
    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            pending              <= 1'b0;
            mmu_started          <= 1'b0;
            translated           <= 1'b0;
            translated_address   <= 64'd0;
            mmu_valid            <= 1'b0;
            data_mem_read_valid  <= 1'b0;
            data_mem_write_valid <= 1'b0;
            data_mem_address     <= 64'd0;
            data_mem_write_data  <= 64'd0;
            uart                 <= 9'd0;
            misaligned_fault     <= 1'b0;
            byte_index           <= 3'b0;
            load_bytes           <= 64'b0;
            response_misaligned   <= 1'b0;
            response_last_byte    <= 1'b0;
        end else begin
            mmu_valid            <= 1'b0;
            data_mem_read_valid  <= 1'b0;
            data_mem_write_valid <= 1'b0;
            uart                 <= 9'd0;
            misaligned_fault     <= 1'b0;
            if (cpu_stop || (access_fault || misaligned_fault) || done) begin
                pending     <= 1'b0;
                mmu_started <= 1'b0;
                translated  <= 1'b0;
                byte_index  <= 3'b0;
                load_bytes  <= 64'b0;
            end else if (pending && response_ready && response_misaligned) begin
                pending <= 1'b0;
                byte_index <= byte_index + 1'b1;
                if (decoder_ctrl.is_load)
                    load_bytes <= load_data;
            end else if (valid && !pending) begin
                if (mode_translate && !translated) begin
                    if (!mmu_started) begin
                        mmu_valid          <= 1'b1;
                        mmu_started        <= 1'b1;
                    end
                    if (mmu_ready) begin
                        translated_address <= d_paddr;
                        translated         <= 1'b1;
                    end
                end else if (data_mem_req_ready) begin
                    response_misaligned   <= misaligned_address;
                    response_last_byte    <= last_byte;
                    pending              <= 1'b1;
                    data_mem_read_valid  <= decoder_ctrl.is_load;
                    data_mem_write_valid <= decoder_ctrl.is_store;
                    data_mem_address     <= access_address +
                                            (misaligned_address ? {61'b0, byte_index} : 64'b0);
                    data_mem_write_data  <= misaligned_address
                                          ? r_data2 >> {byte_index, 3'b0} : r_data2;
                    if (decoder_ctrl.is_store && (in_vaddr == UART_MMIO_ADDR))
                        uart               <= {1'b1, r_data2[7:0]};
                end
            end
        end
    end

endmodule
