`timescale 1ns / 1ps
// ============================================================
// PSC_RV32I UART (8N1) + MMIO + RX割り込み（単一ドライバ徹底版）
// ============================================================
module PSC_RV32IS_UART #(
    parameter integer CLK_FREQ_MHz = 100,
    parameter integer BAUDRATE     = 115200,

    // MMIO base (word addressed)
    parameter integer ADDR_WIDTH            = 32,
    parameter [ADDR_WIDTH-1:0] UART_ADDR_TX = 32'h1000_0000, // BASE+0
    parameter [ADDR_WIDTH-1:0] UART_ADDR_RX = 32'h1000_0004, // BASE+1
    parameter [ADDR_WIDTH-1:0] UART_ADDR_ST = 32'h1000_0008, // BASE+2
    parameter [ADDR_WIDTH-1:0] UART_ADDR_CT = 32'h1000_000C  // BASE+3
)(
    input  wire                     clock,
    input  wire                     reset_n,

    // RS-232C pins
    input  wire                     uart_rx,
    output wire                     uart_tx,

    // CPU write IF (1clk パルス)
    input  wire                     cpu_wvalid,
    input  wire [ADDR_WIDTH-1:0]    cpu_waddr,
    input  wire [31:0]              cpu_wdata,
    output reg                      cpu_wready,  // 1clk パルス

    // CPU read IF (1clk パルス)
    input  wire                     cpu_rvalid,
    input  wire [ADDR_WIDTH-1:0]    cpu_raddr,
    output reg  [31:0]              cpu_rdata,
    output reg                      cpu_rready,  // 1clk パルス

    // Interrupt (level)
    output reg                      irq_rx
);

// 追加: VCD ダンプ用ブロック
`ifdef COCOTB_SIM
initial begin
    //$dumpfile("./wave/psc_uart.vcd");  // 出力するVCDファイル名
    //$dumpvars(1);     // 第1引数: 階層 (0 はこのモジュールを最上位として)
end
`endif

    // アドレス
    wire [ADDR_WIDTH+1:0]     cpu_byte_waddr = cpu_waddr;   // byte address
    wire [ADDR_WIDTH+1:0]     cpu_byte_raddr = cpu_raddr;   // byte address

    // ---------------- Const ----------------
    localparam integer CLKS_PER_BIT = (CLK_FREQ_MHz*1_000_000)/BAUDRATE;
    localparam integer CNTW         = (CLKS_PER_BIT <= 1) ? 1 : $clog2(CLKS_PER_BIT);

    // ---------------- cpu_valid latch ----------------
    reg     cpu_rvalid_latch;
    reg     cpu_wvalid_latch;
    
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            cpu_rvalid_latch    <= 1'b0;
            cpu_wvalid_latch    <= 1'b0;
        end else begin
            cpu_rvalid_latch    <= cpu_rvalid;
            cpu_wvalid_latch    <= cpu_wvalid;
        end
    end

    // ---------------- Addr decode ----------------
    wire w_tx_wr = cpu_wvalid_latch && (cpu_byte_waddr == UART_ADDR_TX);
    wire w_ct_wr = cpu_wvalid_latch && (cpu_byte_waddr == UART_ADDR_CT);

    wire r_rx_rd = cpu_rvalid_latch && (cpu_byte_raddr == UART_ADDR_RX);
    wire r_st_rd = cpu_rvalid_latch && (cpu_byte_raddr == UART_ADDR_ST);
    wire r_ct_rd = cpu_rvalid_latch && (cpu_byte_raddr == UART_ADDR_CT);
    wire r_tx_rd = cpu_rvalid_latch && (cpu_byte_raddr == UART_ADDR_TX);

    // TXDATA write event
    wire        tx_push      = w_tx_wr;
    wire [7:0]  tx_push_data = cpu_wdata[7:0];

    // ---------------- Internals ----------------
    // TX side (single always)
    reg         tx_start_i;
    reg  [7:0]  tx_data_i;
    wire        tx_busy;

    reg         tx_req_valid;  // next-shot slot
    reg  [7:0]  tx_req_data;

    reg         tx_buf_valid;  // one-byte buffer
    reg  [7:0]  tx_buf_data;

    // RX side
    wire [7:0]  rx_data_w;
    wire        rx_ready_pulse; // 1clk pulse from RX

    reg  [7:0]  rx_data_reg;

    // flags
    reg         rx_avail;       // SINGLE DRIVER (own always)
    reg         rx_overrun;     // SINGLE DRIVER (own always)
    reg         rx_irq_en;      // SINGLE DRIVER (MMIO write always)

    // ---------------- Submodules ----------------
    UART_TX #(
        .CLKS_PER_BIT(CLKS_PER_BIT),
        .CNTW        (CNTW)
    ) u_tx (
        .clock    (clock),
        .reset_n  (reset_n),
        .tx_start (tx_start_i),
        .tx_data  (tx_data_i),
        .tx_busy  (tx_busy),
        .uart_tx  (uart_tx)
    );

    UART_RX #(
        .CLKS_PER_BIT(CLKS_PER_BIT),
        .CNTW        (CNTW)
    ) u_rx (
        .clock    (clock),
        .reset_n  (reset_n),
        .uart_rx  (uart_rx),
        .rx_data  (rx_data_w),
        .rx_ready (rx_ready_pulse)
    );

    // ---------------- TX control (single always) ----------------
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            tx_start_i    <= 1'b0;
            tx_data_i     <= 8'h00;
            tx_req_valid  <= 1'b0;
            tx_req_data   <= 8'h00;
            tx_buf_valid  <= 1'b0;
            tx_buf_data   <= 8'h00;
        end else begin
            tx_start_i <= 1'b0;

            // consume
            if (!tx_busy) begin
                if (tx_req_valid) begin
                    tx_data_i    <= tx_req_data;
                    tx_start_i   <= 1'b1;
                    tx_req_valid <= 1'b0;
                end else if (tx_buf_valid) begin
                    tx_data_i    <= tx_buf_data;
                    tx_start_i   <= 1'b1;
                    tx_buf_valid <= 1'b0;
                end
            end

            // enqueue
            if (tx_push) begin
                if (!tx_busy && !tx_req_valid) begin
                    tx_req_data  <= tx_push_data;
                    tx_req_valid <= 1'b1;
                end else if (!tx_buf_valid) begin
                    tx_buf_data  <= tx_push_data;
                    tx_buf_valid <= 1'b1;
                end
                // both full -> drop
            end
        end
    end

    // ---------------- RX data latch (no flag/irq write here) ----------------
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            rx_data_reg <= 8'h00;
        end else if (rx_ready_pulse) begin
            if (!rx_avail) begin
                // 未読が無いときだけ取り込む（古いデータ優先）
                rx_data_reg <= rx_data_w;
            end
            // 未読がある場合は上書きしない → 新着は捨てる（overrunは別alwaysで立つ）
        end
    end

    // ---------------- IRQ / Overrun / Avail  (each single always) ----------------
    // set/clear conditions
    wire irq_set_from_rx    = rx_ready_pulse & rx_irq_en;
    wire irq_clr_from_read  = r_rx_rd;
    wire irq_clr_from_ctrl  = w_ct_wr && cpu_wdata[1]; // CTRL W1C[1]

    wire ov_set_from_rx     = rx_ready_pulse & rx_avail; // new byte while unread
    wire ov_clr_from_read   = r_rx_rd;
    wire ov_clr_from_ctrl   = w_ct_wr && cpu_wdata[2];   // CTRL W1C[2]

    wire avail_set_from_rx  = rx_ready_pulse;
    wire avail_clr_from_read= r_rx_rd;

    // irq_rx
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            irq_rx <= 1'b0;
        end else begin
            if (irq_clr_from_read || irq_clr_from_ctrl)      irq_rx <= 1'b0;
            else if (irq_set_from_rx)                         irq_rx <= 1'b1;
        end
    end

    // rx_overrun
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            rx_overrun <= 1'b0;
        end else begin
            if (ov_clr_from_read || ov_clr_from_ctrl)        rx_overrun <= 1'b0;
            else if (ov_set_from_rx)                         rx_overrun <= 1'b1;
        end
    end

    // rx_avail  ←★ ここが単一ドライバ
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            rx_avail <= 1'b0;
        end else begin
            if (avail_clr_from_read)                         rx_avail <= 1'b0;
            else if (avail_set_from_rx)                      rx_avail <= 1'b1;
        end
    end

    // ---------------- MMIO write  (rx_irq_en もここだけでドライブ) ----------------
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            cpu_wready <= 1'b0;
            rx_irq_en  <= 1'b1;   // default enable (変更可)
        end else begin
            cpu_wready <= 1'b0;

            if (cpu_wvalid_latch) begin
                case (cpu_byte_waddr)
                    UART_ADDR_TX: begin
                        // enqueue は TX 制御 always が拾う
                        cpu_wready <= 1'b1;
                    end
                    UART_ADDR_CT: begin
                        // CTRL: [0]=rx_irq_en, W1C:[1]=irq_clr, W1C:[2]=overrun_clr
                        rx_irq_en  <= cpu_wdata[0];
                        cpu_wready <= 1'b1;
                    end
                    default: begin
                        cpu_wready <= 1'b0;
                    end
                endcase
            end
        end
    end

    // ---------------- MMIO read ----------------
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            cpu_rdata  <= 32'h0;
            cpu_rready <= 1'b0;
        end else begin
            cpu_rready <= 1'b0;

            if (cpu_rvalid_latch) begin
                case (cpu_byte_raddr)
                    UART_ADDR_RX: begin
                        cpu_rdata  <= {24'h0, rx_data_reg};
                        cpu_rready <= 1'b1; // 実体クリアは上の単一 always 群
                    end
                    UART_ADDR_ST: begin
                        // [0]=tx_busy, [1]=rx_avail, [2]=irq_rx, [3]=rx_overrun, [4]=tx_buf_valid
                        cpu_rdata  <= {27'h0, tx_buf_valid, rx_overrun, irq_rx, rx_avail, tx_busy};
                        cpu_rready <= 1'b1;
                    end
                    UART_ADDR_CT: begin
                        cpu_rdata  <= {31'h0, rx_irq_en};
                        cpu_rready <= 1'b1;
                    end
                    UART_ADDR_TX: begin
                        cpu_rdata  <= 32'h0;
                        cpu_rready <= 1'b1;
                    end
                    default: begin
                        cpu_rdata  <= 32'h0;
                        cpu_rready <= 1'b0;
                    end
                endcase
            end
        end
    end

endmodule

// ---------------- UART_TX ----------------
module UART_TX #(
    parameter integer CLKS_PER_BIT = 868,
    parameter integer CNTW         = 10
)(
    input  wire       clock,
    input  wire       reset_n,
    input  wire       tx_start,      // 1clk
    input  wire [7:0] tx_data,
    output reg        tx_busy,
    output reg        uart_tx
);
    localparam [1:0] IDLE=0, START=1, DATA=2, STOP=3;
    reg [1:0]       state;
    reg [CNTW-1:0]  clk_cnt;
    reg [2:0]       bit_idx;
    reg [7:0]       shift_reg;

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            state     <= IDLE;
            uart_tx   <= 1'b1;
            tx_busy   <= 1'b0;
            clk_cnt   <= {CNTW{1'b0}};
            bit_idx   <= 3'd0;
            shift_reg <= 8'd0;
        end else begin
            case (state)
                IDLE: begin
                    uart_tx <= 1'b1;
                    tx_busy <= 1'b0;
                    if (tx_start) begin
                        tx_busy   <= 1'b1;
                        shift_reg <= tx_data;
                        clk_cnt   <= {CNTW{1'b0}};
                        state     <= START;
                    end
                end
                START: begin
                    uart_tx <= 1'b0;
                    if (clk_cnt < CLKS_PER_BIT-1) clk_cnt <= clk_cnt + 1'b1;
                    else begin
                        clk_cnt <= {CNTW{1'b0}};
                        state   <= DATA;
                        bit_idx <= 3'd0;
                    end
                end
                DATA: begin
                    uart_tx <= shift_reg[bit_idx];
                    if (clk_cnt < CLKS_PER_BIT-1) clk_cnt <= clk_cnt + 1'b1;
                    else begin
                        clk_cnt <= {CNTW{1'b0}};
                        if (bit_idx < 3'd7) bit_idx <= bit_idx + 1'b1;
                        else                 state   <= STOP;
                    end
                end
                STOP: begin
                    uart_tx <= 1'b1;
                    if (clk_cnt < CLKS_PER_BIT-1) clk_cnt <= clk_cnt + 1'b1;
                    else begin
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule

// ---------------- UART_RX ----------------
module UART_RX #(
    parameter integer CLKS_PER_BIT = 868,
    parameter integer CNTW         = 10
)(
    input  wire       clock,
    input  wire       reset_n,
    input  wire       uart_rx,
    output reg [7:0]  rx_data,
    output reg        rx_ready     // 1clk
);
    localparam [1:0] IDLE=0, START=1, DATA=2, STOP=3;
    localparam integer HALF_CLKS = CLKS_PER_BIT/2;

    reg [1:0]       state;
    reg [CNTW-1:0]  clk_cnt;
    reg [2:0]       bit_idx;
    reg [7:0]       shift_reg;

    // 2-stage sync
    reg rx_sync1, rx_sync2;
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;
        end else begin
            rx_sync1 <= uart_rx;
            rx_sync2 <= rx_sync1;
        end
    end
    wire rx_s = rx_sync2;

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            state    <= IDLE;
            clk_cnt  <= {CNTW{1'b0}};
            bit_idx  <= 3'd0;
            shift_reg<= 8'd0;
            rx_data  <= 8'd0;
            rx_ready <= 1'b0;
        end else begin
            rx_ready <= 1'b0;
            case (state)
                IDLE: begin
                    if (rx_s == 1'b0) begin
                        state   <= START;
                        clk_cnt <= HALF_CLKS[CNTW-1:0]; // wait half bit to sample mid
                    end
                end
                START: begin
                    if (clk_cnt != {CNTW{1'b0}}) clk_cnt <= clk_cnt - 1'b1;
                    else begin
                        if (rx_s == 1'b0) begin
                            state   <= DATA;
                            clk_cnt <= CLKS_PER_BIT-1;
                            bit_idx <= 3'd0;
                        end else begin
                            state <= IDLE; // false start
                        end
                    end
                end
                DATA: begin
                    if (clk_cnt != {CNTW{1'b0}}) clk_cnt <= clk_cnt - 1'b1;
                    else begin
                        shift_reg[bit_idx] <= rx_s;
                        clk_cnt <= CLKS_PER_BIT-1;
                        if (bit_idx < 3'd7) bit_idx <= bit_idx + 1'b1;
                        else                 state   <= STOP;
                    end
                end
                STOP: begin
                    if (clk_cnt != {CNTW{1'b0}}) clk_cnt <= clk_cnt - 1'b1;
                    else begin
                        if (rx_s == 1'b1) begin
                            rx_data  <= shift_reg;
                            rx_ready <= 1'b1;
                        end
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule