// 1080p60, packed 4-bpp VRAM. The leftmost pixel is bits [3:0] of a word.
// One AXI line request is in flight at a time. Each bank holds one scan line.
module dvi_vram_scanout #(
    parameter integer ADDR_WIDTH = 32,
    parameter [ADDR_WIDTH-1:0] VRAM_ADDRESS = 32'h0080_0000 // word aligned
)(
    input wire axi_clock,
    input wire pixel_clock,
    input wire reset,
    output reg [ADDR_WIDTH-1:0] araddr,
    output wire [7:0] arlen,
    output wire arvalid,
    input wire arready,
    input wire [31:0] rdata,
    input wire [1:0] rresp,
    input wire rlast,
    input wire rvalid,
    output wire rready,
    output reg hsync,
    output reg vsync,
    output reg den,
    output reg [23:0] rgb
);
    localparam WIDTH = 1920, HEIGHT = 1080;
    localparam [7:0] WORDS_PER_LINE = WIDTH[10:3]; // eight 4-bit pixels per word
    localparam STRIDE = WIDTH / 2;

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
    reg requested, show_line;
    // Bundled request payload stays stable until completion returns.
    reg [ADDR_WIDTH-1:0] request_addr, next_addr;
    reg request_bank;
    always @(posedge pixel_clock or posedge pix_reset) begin
        if (pix_reset) begin
            request <= 0;
            request_addr <= VRAM_ADDRESS;
            request_bank <= 0;
            next_addr <= VRAM_ADDRESS;
            requested <= 0;
            show_line <= 0;
        end else if (frame_start || line_start) begin
            // Sample readiness once. A late completion cannot expose a
            // partially written line or move pixels into a later scan line.
            show_line <= line_start && requested && idle;
            requested <= 0;
            if (frame_start || y != HEIGHT-1) begin
                next_addr <= frame_start ? VRAM_ADDRESS + STRIDE : next_addr + STRIDE;
                if (idle) begin
                    request_addr <= frame_start ? VRAM_ADDRESS : next_addr;
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
    reg [7:0] word_index;
    assign arvalid = state == ADDRESS;
    assign rready = state == DATA;
    // Naturally aligned bursts of up to 32 words fit the video port and never
    // cross 4 KiB. A word-aligned base may need short bursts at line edges.
    assign arlen = araddr[6:2] == 0 && word_index <= WORDS_PER_LINE - 8'd32 ? 8'd31 :
                   araddr[5:2] == 0 && word_index <= WORDS_PER_LINE - 8'd16 ? 8'd15 :
                   araddr[4:2] == 0 && word_index <= WORDS_PER_LINE - 8'd8 ? 8'd7 :
                   araddr[3:2] == 0 && word_index <= WORDS_PER_LINE - 8'd4 ? 8'd3 :
                   araddr[2]   == 0 && word_index <= WORDS_PER_LINE - 8'd2 ? 8'd1 : 8'd0;

    always @(posedge axi_clock or posedge axi_reset) begin
        if (axi_reset) begin
            state <= WAIT_LINE;
            completed <= 0;
            araddr <= VRAM_ADDRESS;
            bank <= 0;
            word_index <= 0;
        end else begin
            case (state)
                WAIT_LINE: if (request_sync[1] != completed) begin
                    araddr <= request_addr;
                    bank <= request_bank;
                    word_index <= 0;
                    state <= ADDRESS;
                end
                ADDRESS: if (arready) state <= DATA;
                DATA: if (rvalid) begin
                    araddr <= araddr + 4;
                    word_index <= word_index + 1'b1;
                    if (rlast) begin
                        if (word_index == WORDS_PER_LINE - 8'd1) begin
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
    reg [31:0] lines [0:511];
    reg [31:0] pixel_word;
    always @(posedge axi_clock)
        if (rvalid && rready)
            lines[{bank, word_index}] <= rresp == 2'b00 ? rdata : 32'b0;
    always @(posedge pixel_clock)
        pixel_word <= lines[{y[0], x[10:3]}];

    reg [2:0] nibble;
    reg pixel_valid;
    always @(posedge pixel_clock) begin
        hsync <= timing_hsync;
        vsync <= timing_vsync;
        den <= timing_den && !pix_reset;
        pixel_valid <= timing_den && show_line && !pix_reset;
        nibble <= x[2:0];
    end

    // Fixed EGA 16-colour palette. Index zero is also the underrun colour.
    wire [3:0] colour = pixel_valid ? pixel_word[nibble*4 +: 4] : 4'h0;
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
