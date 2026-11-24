`timescale 1ns/1ps

// Rectified fixed cameras: the projected row is the input row. A single
// 640-word depth/colour RAM resolves all occlusions before emitting that row.
module rgbz_to_vram #(parameter [31:0] VRAM_ADDRESS = 32'h0090_0000) (
    input wire clock, reset_n, start, displayed_page,
    output reg requested_page,
    output wire [3:0] status,
    output wire command, write_command,
    output wire [31:0] address,
    output reg [255:0] write_data,
    input wire completed, failed,
    input wire [255:0] read_data
);
    localparam RGB_BASE = 32'h00b0_0000, Z_BASE = 32'h00b8_0000;
    localparam PAGE_BYTES = 32'h0010_0000;
    localparam IDLE=0, CLEAR_ROW=1, FETCH_RGB=2, FETCH_Z=3, LOAD_POINT=4,
               DIVIDE_COLOUR=5, LOOKUP_Z=6, UPDATE_Z=7, NEXT_POINT=8,
               READ_PIXEL=9, PACK_PIXEL=10, WRITE_BEAT=11, WAIT_DISPLAY=12;
    reg [3:0] state;
    reg done, error;
    assign status = {displayed_page, error, done, state != IDLE};

    reg [9:0] x;
    reg [8:0] y;
    reg [1:0] repeat_x, repeat_y;
    reg [5:0] nibble;
    reg [31:0] input_offset, output_addr;
    reg [255:0] rgb_group, z_group;
    wire [15:0] z = z_group[15:0];
    wire [7:0] red   = {rgb_group[15:11], rgb_group[15:13]};
    wire [7:0] green = {rgb_group[10:5], rgb_group[10:9]};
    wire [7:0] blue  = {rgb_group[4:0], rgb_group[4:2]};

    // Evaluate one EGA entry per clock alongside one unsigned division bit.
    reg [3:0] candidate, best_colour;
    reg [17:0] best_distance;
    wire [7:0] pr = {4{candidate[2],candidate[3]}};
    wire [7:0] pg = candidate == 6 ? 8'h55 : {4{candidate[1],candidate[3]}};
    wire [7:0] pb = {4{candidate[0],candidate[3]}};
    function [15:0] squared_difference;
        input [7:0] a, b;
        reg [7:0] diff;
        begin
            diff = a >= b ? a-b : b-a;
            squared_difference = diff * diff;
        end
    endfunction
    wire [17:0] distance = {2'b0,squared_difference(red,pr)} +
                           {2'b0,squared_difference(green,pg)} +
                           {2'b0,squared_difference(blue,pb)};
    reg [15:0] quotient, remainder;
    wire [16:0] trial = {remainder,quotient[15]};
    wire subtract_z = trial >= {1'b0,z};
    wire [9:0] projected_x = x - quotient[9:0];

    reg [19:0] row [0:639];
    reg [19:0] row_value;
    wire [9:0] row_addr = state == LOOKUP_Z || state == UPDATE_Z ? projected_x : x;
    always @(posedge clock) begin
        if (state == CLEAR_ROW)
            row[x] <= {16'hffff,4'h0};
        else if (state == UPDATE_Z && z < row_value[19:4])
            row[row_addr] <= {z,best_colour};
        if (state == READ_PIXEL || (state == LOOKUP_Z && quotient <= {6'd0,x}))
            row_value <= row[row_addr];
    end

    assign command = state == FETCH_RGB || state == FETCH_Z || state == WRITE_BEAT;
    assign write_command = state == WRITE_BEAT;
    assign address = write_command ? output_addr :
                     (state == FETCH_Z ? Z_BASE : RGB_BASE) + input_offset;

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            requested_page <= 0;
            done <= 0;
            error <= 0;
        end else if (completed && failed) begin
            state <= IDLE;
            error <= 1;
        end else case (state)
            IDLE: if (start) begin
                state <= CLEAR_ROW;
                x <= 0;
                y <= 0;
                done <= 0;
                error <= 0;
                input_offset <= 0;
                output_addr <= displayed_page ? VRAM_ADDRESS : VRAM_ADDRESS + PAGE_BYTES;
            end
            CLEAR_ROW: if (x == 639) begin
                x <= 0;
                state <= FETCH_RGB;
            end else x <= x + 1'b1;
            FETCH_RGB: if (completed) begin
                rgb_group <= read_data;
                state <= FETCH_Z;
            end
            FETCH_Z: if (completed) begin
                z_group <= read_data;
                input_offset <= input_offset + 32;
                state <= LOAD_POINT;
            end
            LOAD_POINT: begin
                quotient <= 16'd16000 + (z >> 1);
                remainder <= 0;
                candidate <= 0;
                best_distance <= 18'h3ffff;
                state <= (z == 0 || z == 16'hffff) ? NEXT_POINT : DIVIDE_COLOUR;
            end
            DIVIDE_COLOUR: begin
                quotient <= {quotient[14:0],subtract_z};
                remainder <= subtract_z ? trial[15:0]-z : trial[15:0];
                if (distance < best_distance) begin
                    best_distance <= distance;
                    best_colour <= candidate;
                end
                candidate <= candidate + 1'b1;
                if (candidate == 15) state <= LOOKUP_Z;
            end
            LOOKUP_Z: state <= (quotient <= {6'd0,x}) ? UPDATE_Z : NEXT_POINT;
            UPDATE_Z: state <= NEXT_POINT;
            NEXT_POINT: begin
                rgb_group <= rgb_group >> 16;
                z_group <= z_group >> 16;
                if (x == 639) begin
                    x <= 0;
                    repeat_x <= 0;
                    repeat_y <= 0;
                    nibble <= 0;
                    state <= READ_PIXEL;
                end else begin
                    x <= x + 1'b1;
                    state <= x[3:0] == 15 ? FETCH_RGB : LOAD_POINT;
                end
            end
            READ_PIXEL: state <= PACK_PIXEL;
            PACK_PIXEL: begin
                write_data <= {row_value[3:0],write_data[255:4]};
                nibble <= nibble + 1'b1;
                if (repeat_x == 2) begin
                    repeat_x <= 0;
                    x <= x == 639 ? 0 : x + 1'b1;
                end else repeat_x <= repeat_x + 1'b1;
                state <= nibble == 63 ? WRITE_BEAT : READ_PIXEL;
            end
            WRITE_BEAT: if (completed) begin
                output_addr <= output_addr + 32;
                if (x == 0 && repeat_x == 0 && repeat_y == 2) begin
                    if (y == 359) begin
                        requested_page <= !displayed_page;
                        state <= WAIT_DISPLAY;
                    end else begin
                        y <= y + 1'b1;
                        state <= CLEAR_ROW;
                    end
                end else begin
                    if (x == 0 && repeat_x == 0) repeat_y <= repeat_y + 1'b1;
                    state <= READ_PIXEL;
                end
            end
            WAIT_DISPLAY: if (displayed_page == requested_page) begin
                done <= 1;
                state <= IDLE;
            end
            default: state <= IDLE;
        endcase
    end
endmodule
