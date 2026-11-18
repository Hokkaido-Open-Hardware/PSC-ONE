// Tang 138K, x32 DDR3, fixed BL8. All ports are synchronous to the IP clk_out.
// If the IP is reset during a transaction, reset the AXI wrapper and bridge together.
// req_ready reserves space for a complete INCR transfer (1/2/4/8 words).
// Addresses on this side of the AXI wrapper are already in 32-bit words.
`timescale 1ns/1ps
module ddr3_controller_if #(
    parameter integer ADDR_WIDTH = 29,
    parameter integer WORD_ADDR_WIDTH = ADDR_WIDTH,
    parameter integer APP_DATA_WIDTH = 256,
    parameter integer APP_MASK_WIDTH = 32,
    parameter USER_REFRESH = "OFF"
)(
    input  logic                         clock,
    input  logic                         reset_n,
    output logic                         req_ready,
    input  logic [3:0]                   rw_length,
    input  logic                         write_valid,
    input  logic                         read_valid,
    input  logic [WORD_ADDR_WIDTH-1:0]   write_addr,
    input  logic [WORD_ADDR_WIDTH-1:0]   read_addr,
    input  logic [31:0]                  write_data,
    output logic                         write_ready,
    output logic                         read_ready,
    output logic [31:0]                  read_data,

    input  logic                         init_calib_complete,
    input  logic                         app_rdy,
    input  logic                         wr_data_rdy,
    input  logic                         app_rd_data_valid,
    input  logic [APP_DATA_WIDTH-1:0]    app_rd_data,
    output logic                         app_en,
    output logic [2:0]                   app_cmd,
    output logic [ADDR_WIDTH-1:0]        app_addr,
    output logic [APP_DATA_WIDTH-1:0]    app_wdf_data,
    output logic                         app_wdf_wren,
    output logic                         app_wdf_end,
    output logic [APP_MASK_WIDTH-1:0]    app_wdf_mask,
    output logic                         app_burst,
    output logic                         sr_req,
    output logic                         ref_req,
    output logic                         error
);
    localparam [2:0] IDLE=0, COLLECT=1, WRITE_CMD=2, WRITE_DONE=3,
                     READ_CMD=4, READ_WAIT=5, READ_WORDS=6;
    reg [2:0] state;
    reg [3:0] remaining;
    reg [2:0] read_lane;
    reg [APP_DATA_WIDTH-1:0] read_line;
    // An INCR transfer of at most eight words visits each lane at most once.
    // Both writes can share one data register with different lane enables.
    reg [7:0] first_lanes, next_lanes;
    wire [7:0] store_lane = 8'b1 << write_addr[2:0];
    wire active = reset_n && init_calib_complete;
    assign req_ready = active && state == IDLE;
    assign write_ready = state == WRITE_DONE;
    assign read_ready = state == READ_WORDS;
    assign read_data = read_line[read_lane*32 +: 32];

    // Offer command and data together on the very edge both FIFOs accept.
    assign app_wdf_wren = active && state == WRITE_CMD && app_rdy && wr_data_rdy;
    assign app_wdf_end = app_wdf_wren;
    assign app_en = app_wdf_wren || (active && state == READ_CMD && app_rdy);
    assign app_cmd = state == READ_CMD ? 3'b001 : 3'b000;
    for (genvar i=0; i<8; i=i+1) begin : gen_byte_mask
        assign app_wdf_mask[i*4 +: 4] = {4{!first_lanes[i]}};
    end
    assign app_burst = 1'b0;
    assign sr_req = 1'b0;
    assign ref_req = 1'b0;

    wire [ADDR_WIDTH-1:0] write_line_addr = ADDR_WIDTH'({write_addr[WORD_ADDR_WIDTH-1:3],3'b0});
    wire [ADDR_WIDTH-1:0] read_line_addr = ADDR_WIDTH'({read_addr[WORD_ADDR_WIDTH-1:3],3'b0});
    wire accepting_read = state == READ_CMD && app_en;
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            app_addr <= 0;
            first_lanes <= 0;
            next_lanes <= 0;
            remaining <= 0;
            read_lane <= 0;
            error <= 0;
        end else begin
            if (app_rd_data_valid && !(state == READ_WAIT || accepting_read))
                error <= 1'b1;
            case (state)
                // The wrapper checked req_ready one cycle before this valid.
                IDLE: if (write_valid || read_valid) begin
                    if (!(rw_length == 1 || rw_length == 2 ||
                          rw_length == 4 || rw_length == 8)) begin
                        error <= 1'b1;
                    end else if (write_valid) begin
                        app_addr <= write_line_addr;
                        app_wdf_data[write_addr[2:0]*32 +: 32] <= write_data;
                        first_lanes <= store_lane;
                        next_lanes <= 0;
                        remaining <= rw_length - 1'b1;
                        state <= rw_length == 1 ? WRITE_CMD : COLLECT;
                    end else begin
                        app_addr <= read_line_addr;
                        read_lane <= read_addr[2:0];
                        remaining <= rw_length;
                        state <= READ_CMD;
                    end
                end
                COLLECT: if (write_valid) begin
                    app_wdf_data[write_addr[2:0]*32 +: 32] <= write_data;
                    if (write_line_addr == app_addr)
                        first_lanes <= first_lanes | store_lane;
                    else
                        next_lanes <= next_lanes | store_lane;
                    remaining <= remaining - 1'b1;
                    if (remaining == 1) state <= WRITE_CMD;
                end
                WRITE_CMD: if (app_wdf_wren) begin
                    if (next_lanes != 0) begin
                        app_addr <= app_addr + 8;
                        first_lanes <= next_lanes;
                        next_lanes <= 0;
                    end else state <= WRITE_DONE;
                end
                WRITE_DONE: state <= IDLE;
                READ_CMD: if (accepting_read) begin
                    if (app_rd_data_valid) begin
                        read_line <= app_rd_data;
                        state <= READ_WORDS;
                    end else state <= READ_WAIT;
                end
                READ_WAIT: if (!init_calib_complete) begin
                    // The outstanding response requires a coordinated reset.
                    error <= 1'b1;
                end else if (app_rd_data_valid) begin
                    read_line <= app_rd_data;
                    state <= READ_WORDS;
                end
                READ_WORDS: begin
                    read_lane <= read_lane + 1'b1;
                    remaining <= remaining - 1'b1;
                    if (remaining == 1) state <= IDLE;
                    else if (read_lane == 7) begin
                        app_addr <= app_addr + 8;
                        state <= READ_CMD;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
