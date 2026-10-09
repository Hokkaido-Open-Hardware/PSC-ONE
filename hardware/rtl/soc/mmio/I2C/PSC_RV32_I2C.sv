`timescale 1ns / 1ps
// PSC-ONE I2C slave, 7-bit, standard/fast mode, MMIO register interface.
// Arduino Nano is bus master; MPU6050 and PSC-ONE are separate slaves.
// All registers have a single sequential driver. No clock stretching.
// The SCL/SDA pull-ups and bidirectional SDA buffer belong at chip top level.
//
// I2C register protocol (8-bit pointer, auto increment):
//   Write: START, ADDR+W, register_index, data ..., STOP
//   Read:  START, ADDR+W, register_index, RESTART, ADDR+R, data ..., NACK, STOP
// Registers:
//   0x00..03  INPUT0..3 (W from master, 4 signed INT8 input values)
//   0x04      STATUS   [0]=input_ready [1]=output_ready [2]=overrun
//   0x08      OUTPUT   (R by master, signed INT8 inference output)
//   0x09      SEQ      (R, increments on complete 4-byte input write)
// MMIO (byte addressed; 32-bit word operations):
//   BASE+0x00 INPUT    [31:0]={in3,in2,in1,in0}
//   BASE+0x04 STATUS   [2:0]={overrun,output_ready,input_ready}; W1C [0..2]
//   BASE+0x08 OUTPUT   [7:0] CPU write sets output_ready
//   BASE+0x0C CONTROL  [0] interrupt enable
//   BASE+0x10 SEQ      [7:0] last input sequence number
// Warning: SPI or I2S electrical conventions are NOT compatible with this port.

module PSC_RV32_I2C #(
    parameter integer ADDR_WIDTH = 32,
    parameter [6:0] SLAVE_ADDRESS = 7'h42,
    parameter [ADDR_WIDTH-1:0] I2C_BASE = 32'h1000_2000,
    // CPU MMIO addresses; individually overridable from the parent module.
    parameter [ADDR_WIDTH-1:0] I2C_ADDR_INPUT   = I2C_BASE + 32'h00,
    parameter [ADDR_WIDTH-1:0] I2C_ADDR_STATUS  = I2C_BASE + 32'h04,
    parameter [ADDR_WIDTH-1:0] I2C_ADDR_OUTPUT  = I2C_BASE + 32'h08,
    parameter [ADDR_WIDTH-1:0] I2C_ADDR_CONTROL = I2C_BASE + 32'h0C,
    parameter [ADDR_WIDTH-1:0] I2C_ADDR_SEQ     = I2C_BASE + 32'h10
)(
    input  wire                  clock,
    input  wire                  reset_n,
    input  wire                  scl_i,
    input  wire                  sda_i,
    output reg                   sda_drive_low, // open drain: 1 pulls SDA low

    input  wire                  cpu_wvalid,
    input  wire [ADDR_WIDTH-1:0] cpu_waddr,
    input  wire [31:0]           cpu_wdata,
    output reg                   cpu_wready,
    input  wire                  cpu_rvalid,
    input  wire [ADDR_WIDTH-1:0] cpu_raddr,
    output reg  [31:0]           cpu_rdata,
    output reg                   cpu_rready,
    output wire                  irq_rx
);
    localparam [3:0] ST_IDLE=4'd0, ST_ADDR=4'd1, ST_ADDR_ACK=4'd2,
                     ST_RX=4'd3, ST_RX_ACK=4'd4, ST_TX=4'd5,
                     ST_TX_ACK=4'd6, ST_IGNORE=4'd7;

    // Double synchronization; bus must be slow enough for clock-domain sampling.
    reg scl_meta, scl_sync, scl_prev;
    reg sda_meta, sda_sync, sda_prev;
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            scl_meta <= 1'b1; scl_sync <= 1'b1; scl_prev <= 1'b1;
            sda_meta <= 1'b1; sda_sync <= 1'b1; sda_prev <= 1'b1;
        end else begin
            scl_meta <= scl_i; scl_sync <= scl_meta; scl_prev <= scl_sync;
            sda_meta <= sda_i; sda_sync <= sda_meta; sda_prev <= sda_sync;
        end
    end
    wire scl_rise = scl_sync && !scl_prev;
    wire scl_fall = !scl_sync && scl_prev;
    wire i2c_start = scl_sync && scl_prev && sda_prev && !sda_sync;
    wire i2c_stop  = scl_sync && scl_prev && !sda_prev && sda_sync;

    reg [3:0] state;
    reg [2:0] bit_count;
    reg [7:0] shift_rx, shift_tx;
    reg [7:0] reg_ptr;
    reg       ptr_valid;
    reg       addr_matches, addr_read;
    reg       ack_seen_high;
    reg       master_ack;

    reg [7:0] in0, in1, in2, in3;
    reg [7:0] out_value;
    reg [7:0] seq;
    reg       input_ready, output_ready, overrun;
    reg       irq_en;
    reg [3:0] received_mask;

    reg wvalid_d, rvalid_d;
    wire cpu_wr = cpu_wvalid && !wvalid_d;
    wire cpu_rd = cpu_rvalid && !rvalid_d;
    wire wr_input_status = cpu_wr && (cpu_waddr == I2C_ADDR_STATUS);
    wire wr_output = cpu_wr && (cpu_waddr == I2C_ADDR_OUTPUT);
    wire wr_control = cpu_wr && (cpu_waddr == I2C_ADDR_CONTROL);
    assign irq_rx = irq_en && input_ready;

    // Combinational source for I2C master reads. Low byte is the data lane.
    function automatic [7:0] selected_byte(input [7:0] idx);
        begin
            case (idx)
                8'h00: selected_byte = in0;
                8'h01: selected_byte = in1;
                8'h02: selected_byte = in2;
                8'h03: selected_byte = in3;
                8'h04: selected_byte = {5'b0,overrun,output_ready,input_ready};
                8'h08: selected_byte = out_value;
                8'h09: selected_byte = seq;
                default: selected_byte = 8'h00;
            endcase
        end
    endfunction

    // All I2C state/buffers and CPU-visible registers use a single driver.
    // If CPU and I2C update same status in one cycle, incoming I2C wins.
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            state <= ST_IDLE;
            bit_count <= 3'd0;
            shift_rx <= 8'd0;
            shift_tx <= 8'd0;
            reg_ptr <= 8'd0;
            ptr_valid <= 1'b0;
            addr_matches <= 1'b0;
            addr_read <= 1'b0;
            ack_seen_high <= 1'b0;
            master_ack <= 1'b0;
            sda_drive_low <= 1'b0;
            in0 <= 8'd0; in1 <= 8'd0; in2 <= 8'd0; in3 <= 8'd0;
            out_value <= 8'd0; seq <= 8'd0;
            input_ready <= 1'b0; output_ready <= 1'b0;
            overrun <= 1'b0; received_mask <= 4'd0;
            irq_en <= 1'b0;
            cpu_wready <= 1'b0; cpu_rready <= 1'b0;
            cpu_rdata <= 32'd0;
            wvalid_d <= 1'b0; rvalid_d <= 1'b0;
        end else begin
            wvalid_d <= cpu_wvalid;
            rvalid_d <= cpu_rvalid;
            cpu_wready <= 1'b0;
            cpu_rready <= 1'b0;

            if (cpu_wr) begin
                case (cpu_waddr)
                    I2C_ADDR_STATUS: begin
                        if (cpu_wdata[0]) input_ready <= 1'b0;
                        if (cpu_wdata[1]) output_ready <= 1'b0;
                        if (cpu_wdata[2]) overrun <= 1'b0;
                        cpu_wready <= 1'b1;
                    end
                    I2C_ADDR_OUTPUT: begin
                        out_value <= cpu_wdata[7:0];
                        output_ready <= 1'b1;
                        cpu_wready <= 1'b1;
                    end
                    I2C_ADDR_CONTROL: begin
                        irq_en <= cpu_wdata[0];
                        cpu_wready <= 1'b1;
                    end
                    default: begin end
                endcase
            end
            if (cpu_rd) begin
                case (cpu_raddr)
                    I2C_ADDR_INPUT: begin
                        cpu_rdata <= {in3,in2,in1,in0};
                        cpu_rready <= 1'b1;
                    end
                    I2C_ADDR_STATUS: begin
                        cpu_rdata <= {29'd0,overrun,output_ready,input_ready};
                        cpu_rready <= 1'b1;
                    end
                    I2C_ADDR_OUTPUT: begin
                        cpu_rdata <= {24'd0,out_value};
                        cpu_rready <= 1'b1;
                    end
                    I2C_ADDR_CONTROL: begin
                        cpu_rdata <= {31'd0,irq_en};
                        cpu_rready <= 1'b1;
                    end
                    I2C_ADDR_SEQ: begin
                        cpu_rdata <= {24'd0,seq};
                        cpu_rready <= 1'b1;
                    end
                    default: begin end
                endcase
            end

            if (i2c_start) begin
                state <= ST_ADDR;
                bit_count <= 3'd0;
                shift_rx <= 8'd0;
                sda_drive_low <= 1'b0;
                ack_seen_high <= 1'b0;
                // Keep register pointer across repeated start.
            end else if (i2c_stop) begin
                state <= ST_IDLE;
                sda_drive_low <= 1'b0;
                ptr_valid <= 1'b0;
                received_mask <= 4'd0;
            end else begin
                case (state)
                    ST_IDLE: sda_drive_low <= 1'b0;
                    ST_ADDR: begin
                        if (scl_rise) begin
                            shift_rx <= {shift_rx[6:0],sda_sync};
                            if (bit_count == 3'd7) begin
                                addr_matches <= (shift_rx[6:0] == SLAVE_ADDRESS);
                                addr_read <= sda_sync;
                                state <= ST_ADDR_ACK;
                                ack_seen_high <= 1'b0;
                            end else bit_count <= bit_count + 3'd1;
                        end
                    end
                    ST_ADDR_ACK: begin
                        if (scl_fall && !ack_seen_high)
                            sda_drive_low <= addr_matches;
                        if (scl_rise) ack_seen_high <= 1'b1;
                        if (scl_fall && ack_seen_high) begin
                            sda_drive_low <= 1'b0;
                            bit_count <= 3'd0;
                            if (!addr_matches) state <= ST_IGNORE;
                            else if (addr_read) begin
                                state <= ST_TX;
                                shift_tx <= selected_byte(reg_ptr);
                                sda_drive_low <= ~(selected_byte(reg_ptr) >> 7);
                            end else begin
                                state <= ST_RX;
                                shift_rx <= 8'd0;
                                ptr_valid <= 1'b0;
                                received_mask <= 4'd0;
                            end
                        end
                    end
                    ST_RX: begin
                        if (scl_rise) begin
                            shift_rx <= {shift_rx[6:0],sda_sync};
                            if (bit_count == 3'd7) begin
                                state <= ST_RX_ACK;
                                ack_seen_high <= 1'b0;
                                if (!ptr_valid) begin
                                    reg_ptr <= {shift_rx[6:0],sda_sync};
                                    ptr_valid <= 1'b1;
                                end else begin
                                    reg_ptr <= reg_ptr + 8'd1;
                                    case (reg_ptr)
                                        8'h00: begin in0 <= {shift_rx[6:0],sda_sync}; received_mask[0] <= 1'b1; end
                                        8'h01: begin in1 <= {shift_rx[6:0],sda_sync}; received_mask[1] <= 1'b1; end
                                        8'h02: begin in2 <= {shift_rx[6:0],sda_sync}; received_mask[2] <= 1'b1; end
                                        8'h03: begin
                                            in3 <= {shift_rx[6:0],sda_sync};
                                            received_mask[3] <= 1'b1;
                                            if (&received_mask[2:0]) begin
                                                if (input_ready) overrun <= 1'b1;
                                                input_ready <= 1'b1;
                                                output_ready <= 1'b0;
                                                seq <= seq + 8'd1;
                                            end
                                        end
                                        default: begin end
                                    endcase
                                end
                            end else bit_count <= bit_count + 3'd1;
                        end
                    end
                    ST_RX_ACK: begin
                        if (scl_fall && !ack_seen_high) sda_drive_low <= 1'b1;
                        if (scl_rise) ack_seen_high <= 1'b1;
                        if (scl_fall && ack_seen_high) begin
                            sda_drive_low <= 1'b0;
                            state <= ST_RX;
                            bit_count <= 3'd0;
                        end
                    end
                    ST_TX: begin
                        // First bit set on final address-ACK falling edge;
                        // subsequent bits change on falling SCL edges.
                        if (scl_rise) begin
                            if (bit_count == 3'd7) begin
                                state <= ST_TX_ACK;
                                ack_seen_high <= 1'b0;
                            end else bit_count <= bit_count + 3'd1;
                        end
                        if (scl_fall) begin
                            shift_tx <= {shift_tx[6:0],1'b0};
                            sda_drive_low <= ~shift_tx[6];
                        end
                    end
                    ST_TX_ACK: begin
                        if (scl_fall && !ack_seen_high) sda_drive_low <= 1'b0;
                        if (scl_rise) begin
                            master_ack <= !sda_sync;
                            ack_seen_high <= 1'b1;
                        end
                        if (scl_fall && ack_seen_high) begin
                            if (master_ack) begin
                                state <= ST_TX;
                                bit_count <= 3'd0;
                                reg_ptr <= reg_ptr + 8'd1;
                                shift_tx <= selected_byte(reg_ptr + 8'd1);
                                sda_drive_low <= ~(selected_byte(reg_ptr + 8'd1) >> 7);
                            end else begin
                                state <= ST_IGNORE;
                                sda_drive_low <= 1'b0;
                            end
                        end
                    end
                    ST_IGNORE: sda_drive_low <= 1'b0;
                    default: begin state <= ST_IDLE; sda_drive_low <= 1'b0; end
                endcase
            end
        end
    end
    
endmodule