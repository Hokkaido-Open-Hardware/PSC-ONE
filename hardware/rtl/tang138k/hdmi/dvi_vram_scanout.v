// 1080p60, packed 4-bpp VRAM. The leftmost pixel is bits [3:0] of a word.
// One AXI line request is in flight at a time. Each bank holds one scan line.
module dvi_vram_scanout #(
    parameter integer ADDR_WIDTH = 32,
    parameter [ADDR_WIDTH-1:0] VRAM_ADDRESS = 32'h0090_0000, // word aligned
    parameter DOUBLE_BUFFER = 1'b0
)(
    input  wire                 axi_clock,
    input  wire                 pixel_clock,
    input  wire                 reset,
    output reg [ADDR_WIDTH-1:0] araddr,
    output wire [7:0]           arlen,
    output wire                 arvalid,
    input  wire                 arready,
    input  wire [255:0]         rdata,
    input  wire [1:0]           rresp,
    input  wire                 rlast,
    input  wire                 rvalid,
    output wire                 rready,
    output reg                  hsync,
    output reg                  vsync,
    output reg                  den,
    output reg [23:0]           rgb,
    input  wire                 requested_page,
    output wire                 displayed_page,
    output wire                 scanout_busy
);
    localparam WIDTH = 1920, HEIGHT = 1080;
    localparam STRIDE = WIDTH / 2;

    // STRIDE is a multiple of 32, so the alignment offset is constant for all rows.
    localparam [ADDR_WIDTH-1:0] FIRST_BEAT = {VRAM_ADDRESS[ADDR_WIDTH-1:5], 5'b0};
    localparam LINE_BEATS = STRIDE / 32;
    localparam [4:0] LAST_BEAT = VRAM_ADDRESS[4:0] == 0 ? LINE_BEATS[4:0] - 1'b1 : LINE_BEATS[4:0];

    // Both sides of the toggle handshake restart together, even if a PLL
    // has not yet started. Release each domain after two local clock edges.
    (* ASYNC_REG = "TRUE" *) reg [1:0] pix_reset_pipe, axi_reset_pipe;
    always @(posedge pixel_clock or posedge reset)
        if (reset) pix_reset_pipe <= 2'b11;
        else pix_reset_pipe <= {pix_reset_pipe[0], 1'b0};
    always @(posedge axi_clock or posedge reset)
        if (reset) axi_reset_pipe <= 2'b11;
        else axi_reset_pipe <= {axi_reset_pipe[0], 1'b0};
    wire pix_reset = pix_reset_pipe[1], axi_reset = axi_reset_pipe[1];

    wire [13:0] hpos, vpos, x, y;
    wire timing_hsync, timing_vsync, timing_den, line_start;
    video_timing_ctrl #(
        .video_h_visible     (WIDTH),
        .video_v_visible     (HEIGHT)
    ) timing (
        .pixel_clock         (pixel_clock),
        .reset               (pix_reset),
        .ext_sync            (1'b0),
        .timing_h_pos        (hpos),
        .timing_v_pos        (vpos),
        .pixel_x             (x),
        .pixel_y             (y),
        .video_hsync         (timing_hsync),
        .video_vsync         (timing_vsync),
        .video_den           (timing_den),
        .video_line_start    (line_start)
    );

    reg request, completed;
    (* ASYNC_REG = "TRUE" *) reg [1:0] request_sync, completed_sync;
    always @(posedge axi_clock or posedge axi_reset)
        if (axi_reset) request_sync <= 0;
        else request_sync <= {request_sync[0], request};
    always @(posedge pixel_clock or posedge pix_reset)
        if (pix_reset) completed_sync <= 0;
        else completed_sync <= {completed_sync[0], completed};

    wire frame_start = hpos == 0 && vpos == 0;
    wire idle = request == completed_sync[1];
    // The requested page stays stable until the acknowledged page returns.
    (* ASYNC_REG = "TRUE" *) reg [1:0] page_request_sync, page_ack_sync;
    reg front_page;
    always @(posedge pixel_clock or posedge pix_reset)
        if (pix_reset) begin
            page_request_sync <= 0;
            front_page <= 0;
        end else begin
            page_request_sync <= {page_request_sync[0], requested_page};
            if (frame_start && idle && DOUBLE_BUFFER) front_page <= page_request_sync[1];
        end
    always @(posedge axi_clock or posedge axi_reset)
        if (axi_reset) page_ack_sync <= 0;
        else page_ack_sync <= {page_ack_sync[0], front_page};
    assign displayed_page = page_ack_sync[1];
    assign scanout_busy = request_sync[1] != completed;
    wire first_page = DOUBLE_BUFFER && (idle ? page_request_sync[1] : front_page);
    wire [ADDR_WIDTH-1:0] frame_base = first_page ? FIRST_BEAT + 32'h0010_0000 : FIRST_BEAT;
    reg requested, show_line;
    // Bundled request payload stays stable until completion returns.
    reg [ADDR_WIDTH-1:0] request_addr, next_addr;
    reg request_bank;
    always @(posedge pixel_clock or posedge pix_reset) begin
        if (pix_reset) begin
            request <= 0;
            request_addr <= FIRST_BEAT;
            request_bank <= 0;
            next_addr <= FIRST_BEAT;
            requested <= 0;
            show_line <= 0;
        end else if (frame_start || line_start) begin
            // Sample readiness once. A late completion cannot expose a
            // partially written line or move pixels into a later scan line.
            show_line <= line_start && requested && idle;
            requested <= 0;
            if (frame_start || y != HEIGHT-1) begin
                next_addr <= frame_start ? frame_base + STRIDE : next_addr + STRIDE;
                if (idle) begin
                    request_addr <= frame_start ? frame_base : next_addr;
                    request_bank <= frame_start ? 1'b0 : ~y[0];
                    request <= ~request;
                    requested <= 1;
                end
            end
        end
    end

    localparam WAIT_LINE = 2'd0, ADDRESS = 2'd1, DATA = 2'd2;
    reg [1:0] state;
    reg bank;
    reg [4:0] beat_index;
    assign arvalid = state == ADDRESS;
    assign rready = state == DATA;
    // Naturally aligned 1/2/4-beat bursts never cross a 4 KiB boundary.
    assign arlen = araddr[6:5] == 0 && beat_index <= LAST_BEAT - 5'd3 ? 8'd3 :
                   araddr[5] == 0 && beat_index < LAST_BEAT ? 8'd1 : 8'd0;

    always @(posedge axi_clock or posedge axi_reset) begin
        if (axi_reset) begin
            state <= WAIT_LINE;
            completed <= 0;
            araddr <= FIRST_BEAT;
            bank <= 0;
            beat_index <= 0;
        end else begin
            case (state)
                WAIT_LINE: if (request_sync[1] != completed) begin
                    araddr <= request_addr;
                    bank <= request_bank;
                    beat_index <= 0;
                    state <= ADDRESS;
                end
                ADDRESS: if (arready) state <= DATA;
                DATA: if (rvalid) begin
                    araddr <= araddr + 32;
                    beat_index <= beat_index + 1'b1;
                    if (rlast) begin
                        if (beat_index == LAST_BEAT) begin
                            completed <= request_sync[1];
                            state <= WAIT_LINE;
                        end else state <= ADDRESS;
                    end
                end
                default: state <= WAIT_LINE;
            endcase
        end
    end

    // Simple dual-port RAM with independent clocks and synchronous read.
    reg [255:0] lines [0:63];
    reg [255:0] pixel_beat;
    // A word-aligned VRAM base may place pixel zero partway through a beat.
    wire [7:0] pixel_word_index = x[10:3] + {5'b0, VRAM_ADDRESS[4:2]};
    always @(posedge axi_clock)
        if (rvalid && rready)
            lines[{bank, beat_index}] <= rresp == 2'b00 ? rdata : 256'b0;
    always @(posedge pixel_clock)
        pixel_beat <= lines[{y[0], pixel_word_index[7:3]}];

    reg [5:0] nibble;
    reg pixel_valid;
    always @(posedge pixel_clock) begin
        hsync <= timing_hsync;
        vsync <= timing_vsync;
        den <= timing_den && !pix_reset;
        pixel_valid <= timing_den && show_line && !pix_reset;
        nibble <= {pixel_word_index[2:0], x[2:0]};
    end

    // Fixed EGA 16-colour palette. Index zero is also the underrun colour.
    wire [3:0] colour = pixel_valid ? pixel_beat[nibble*4 +: 4] : 4'h0;
    always @* begin
        case (colour)
            4'h0: rgb = 24'h000000;
            4'h1: rgb = 24'h0000aa;
            4'h2: rgb = 24'h00aa00;
            4'h3: rgb = 24'h00aaaa;
            4'h4: rgb = 24'haa0000;
            4'h5: rgb = 24'haa00aa;
            4'h6: rgb = 24'haa5500;
            4'h7: rgb = 24'haaaaaa;
            4'h8: rgb = 24'h555555;
            4'h9: rgb = 24'h5555ff;
            4'ha: rgb = 24'h55ff55;
            4'hb: rgb = 24'h55ffff;
            4'hc: rgb = 24'hff5555;
            4'hd: rgb = 24'hff55ff;
            4'he: rgb = 24'hffff55;
            default: rgb = 24'hffffff;
        endcase
    end
endmodule
