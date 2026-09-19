// NISHIHARU
import PSC_Types::*;

// Pipeline MEM controller; branch/jump decisions remain in PSC_InstructionUnit.
module Branch #(
    parameter logic [31:0] UART_MMIO_ADDR = 32'hF004_00F0
)(
    input  logic        clock,
    input  logic        reset_n,
    input  logic        cpu_stop,
    input  logic        valid,
    input  dec_ctrl_t   decoder_ctrl,
    input  logic [31:0] in_vaddr,
    input  logic [31:0] r_data2,
    input  logic        mode_sv32,
    output logic        mmu_valid,
    input  logic        mmu_ready,
    input  logic        access_fault,
    input  logic [31:0] d_paddr,
    output logic [31:0] data_mem_address,
    output logic [31:0] data_mem_write_data,
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
    logic [31:0] translated_address;
    logic misaligned_address;

    // Check alignment before translation; register faults to let older instructions commit.
    assign misaligned_address =
        (((decoder_ctrl.funct3 == 3'b001) ||
          (decoder_ctrl.is_load && decoder_ctrl.funct3 == 3'b101)) && in_vaddr[0]) ||
        ((decoder_ctrl.funct3 == 3'b010) && (|in_vaddr[1:0]));
    assign done               = pending && (decoder_ctrl.is_store
                             ? data_mem_write_ready : data_mem_read_ready);

    // Pulse one cache request after req_ready, then hold pending until its response.
    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            pending              <= 1'b0;
            mmu_started          <= 1'b0;
            translated           <= 1'b0;
            translated_address   <= 32'd0;
            mmu_valid            <= 1'b0;
            data_mem_read_valid  <= 1'b0;
            data_mem_write_valid <= 1'b0;
            data_mem_address     <= 32'd0;
            data_mem_write_data  <= 32'd0;
            uart                 <= 9'd0;
            misaligned_fault     <= 1'b0;
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
            end else if (valid && !pending) begin
                if (misaligned_address) begin
                    misaligned_fault     <= 1'b1;
                end else if (mode_sv32 && !translated) begin
                    if (!mmu_started) begin
                        mmu_valid          <= 1'b1;
                        mmu_started        <= 1'b1;
                    end
                    if (mmu_ready) begin
                        translated_address <= d_paddr;
                        translated         <= 1'b1;
                    end
                end else if (data_mem_req_ready) begin
                    pending              <= 1'b1;
                    data_mem_read_valid  <= decoder_ctrl.is_load;
                    data_mem_write_valid <= decoder_ctrl.is_store;
                    data_mem_address     <= mode_sv32 ? translated_address : in_vaddr;
                    data_mem_write_data  <= r_data2;
                    if (decoder_ctrl.is_store && (in_vaddr == UART_MMIO_ADDR))
                        uart               <= {1'b1, r_data2[7:0]};
                end
            end
        end
    end

endmodule
