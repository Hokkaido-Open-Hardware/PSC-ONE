`timescale 1ns / 1ps
// ============================================================
// PSC_RV32IS TIMER
// ============================================================
module PSC_RV32IS_TIMER #(
    parameter integer CLK_FREQ_MHz = 100,
    // 1tick = 1 / FRAC [us]
    // FRAC=4なら1tick=0.25us
    parameter integer FRAC         = 1,     
    parameter integer TIMER_BITS   = 16,

    // MMIO base (word addressed)
    parameter integer ADDR_WIDTH                 = 32,
    parameter [ADDR_WIDTH-1:0] TIMER_WRITE_ADDR  = 32'h1000_2000, // BASE+0 (W)
    parameter [ADDR_WIDTH-1:0] TIMER_READ_ADDR   = 32'h1000_2004, // BASE+4 (R: counter)
    parameter [ADDR_WIDTH-1:0] TIMER_ST_ADDR     = 32'h1000_2008  // BASE+8 (R: status)
)(
    input  wire                     clock,
    input  wire                     reset_n,

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
    output reg                      irq_tx
);

    // アドレス
    wire [ADDR_WIDTH+1:0]     cpu_byte_waddr = cpu_waddr;   // byte address
    wire [ADDR_WIDTH+1:0]     cpu_byte_raddr = cpu_raddr;   // byte address

    // ------------------------------------------------------------
    // 分周：1tick = (FRAC / CLK_FREQ_MHz) [us]
    // ------------------------------------------------------------
    localparam integer PRESC_DIV  = (CLK_FREQ_MHz / FRAC);
    localparam integer PRESC_MAX  = (PRESC_DIV > 0) ? (PRESC_DIV - 1) : 0;
    localparam integer PRESC_W    = (PRESC_MAX < 1) ? 1 : $clog2(PRESC_MAX+1);

    // synopsys translate_off
    initial begin
        if (CLK_FREQ_MHz % FRAC != 0)
            $display("WARNING: TIMER tick quantization: %0d MHz %% %0d != 0", CLK_FREQ_MHz, FRAC);
    end
    // synopsys translate_on

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

    // ------------------------------------------------------------
    // レジスタ群
    // ------------------------------------------------------------
    reg [TIMER_BITS-1:0] reload_val;
    reg [TIMER_BITS-1:0] counter;
    reg                  running;
    reg                  autoreload;
    reg                  irq_enable;
    reg                  irq_pending;

    reg [PRESC_W-1:0]    presc;

    wire tick_en = (presc == PRESC_MAX[PRESC_W-1:0]);

    // 分周器
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            presc <= {PRESC_W{1'b0}};
        end else if (running) begin
            if (tick_en) presc <= {PRESC_W{1'b0}};
            else         presc <= presc + {{(PRESC_W-1){1'b0}},1'b1};
        end else begin
            presc <= {PRESC_W{1'b0}};
        end
    end

    // カウンタ＆IRQ
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            reload_val  <= {TIMER_BITS{1'b0}};
            counter     <= {TIMER_BITS{1'b0}};
            running     <= 1'b0;
            autoreload  <= 1'b0;
            irq_enable  <= 1'b0;
            irq_pending <= 1'b0;
            irq_tx      <= 1'b0;
            cpu_wready  <= 1'b0;
        end else begin
            // 割り込みレベル出力
            irq_tx <= (irq_enable && irq_pending);

            // Writeデコード（1clkパルス）
            cpu_wready <= 1'b0;
            if (cpu_wvalid_latch && (cpu_byte_waddr == TIMER_WRITE_ADDR)) begin
                cpu_wready  <= 1'b1;

                // 書式:
                // [15:0] : reload_val
                // [16]   : start (1でロード&開始)
                // [17]   : autoreload
                // [18]   : irq_enable
                // [19]   : stop (1で停止)
                // [20]   : clear_irq (W1C)
                reload_val <= cpu_wdata[TIMER_BITS-1:0];
                autoreload <= cpu_wdata[17];
                irq_enable <= cpu_wdata[18];

                if (cpu_wdata[20]) begin // W1C
                    irq_pending <= 1'b0;
                end

                if (cpu_wdata[19]) begin // stop
                    running <= 1'b0;
                end

                if (cpu_wdata[16]) begin // start+load
                    counter <= (cpu_wdata[TIMER_BITS-1:0] == {TIMER_BITS{1'b0}})
                               ? {{(TIMER_BITS-1){1'b0}},1'b1}
                               : cpu_wdata[TIMER_BITS-1:0];
                    running <= 1'b1;
                    irq_pending <= 1'b0; // 起動時にクリア
                end
            end

            // カウントダウン
            if (running && tick_en) begin
                if (counter > {{(TIMER_BITS-1){1'b0}},1'b0}) begin
                    counter <= counter - {{(TIMER_BITS-1){1'b0}},1'b1};
                end else begin
                    // 0到達
                    irq_pending <= 1'b1;
                    if (autoreload) begin
                        counter <= (reload_val == {TIMER_BITS{1'b0}})
                                   ? {{(TIMER_BITS-1){1'b0}},1'b1}
                                   : reload_val;
                    end else begin
                        running <= 1'b0;  // ワンショット終了
                    end
                end
            end
        end
    end

    // Readパス（counter / status を別アドレスで返す）
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            cpu_rdata  <= 32'd0;
            cpu_rready <= 1'b0;
        end else begin
            cpu_rready <= 1'b0;
            if (cpu_rvalid_latch) begin
                if (cpu_byte_raddr == TIMER_READ_ADDR) begin
                    cpu_rready <= 1'b1;
                    cpu_rdata  <= { 16'd0, counter };
                end else if (cpu_byte_raddr == TIMER_WRITE_ADDR) begin
                    cpu_rready <= 1'b1;
                    cpu_rdata  <= 32'h0;
                end else if (cpu_byte_raddr == TIMER_ST_ADDR) begin
                    cpu_rready <= 1'b1;
                    cpu_rdata  <= {
                        11'd0,               // 31:21 予約
                        (PRESC_MAX[9:0]),    // 20:11 分周値(下位10bit目安表示) ※任意
                        irq_pending,         // 10
                        irq_enable,          // 9
                        autoreload,          // 8
                        running,             // 7
                        7'd0                 // 6:0 予約
                    };
                    // 必要に応じてSTビット配置は調整してください
                end
            end
        end
    end

endmodule
