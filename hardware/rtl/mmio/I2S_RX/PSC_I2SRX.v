`timescale 1ns/1ps

module PSC_I2SRX #(
    parameter ADDR_WIDTH    = 32,
    parameter CLK_FREQ_MHz  = 80,
    parameter FIFO_DEPTH    = 64,             // 64推奨
    parameter [ADDR_WIDTH-1:0] I2S_ADDR_RX = 32'h1000_7000, // BASE+0
    parameter [ADDR_WIDTH-1:0] I2S_ADDR_ST = 32'h1000_7004  // BASE+1
)(
    input  wire        clock,
    input  wire        reset_n,

    // ---------------- CPU BUS ----------------
    input  wire        cpu_rvalid,
    input  wire [31:0] cpu_raddr,
    output reg  [31:0] cpu_rdata,
    output reg         cpu_rready,

    input  wire        cpu_wvalid,
    input  wire [31:0] cpu_waddr,
    input  wire [31:0] cpu_wdata,
    output reg         cpu_wready,

    // ------------------ I2S ------------------
    output wire        I2S_SCK,
    output reg         I2S_WS,
    output wire        I2S_LR,
    input  wire        I2S_SD
);

    assign I2S_SCK   = ~I2S_SCK_reg;
    assign I2S_LR   = 0;

    // ============================================================
    // FIFO (byte)
    // ============================================================
    localparam integer FIFO_AW = 8;     // max 256
    localparam integer FIFO_CW = FIFO_AW + 1;   

    reg [23:0] fifo_R_mem [0:FIFO_DEPTH-1];
    reg [23:0] fifo_L_mem [0:FIFO_DEPTH-1];     // not used.
    reg [FIFO_AW-1:0] fifo_wr_ptr, fifo_rd_ptr;
    reg [FIFO_CW-1:0] fifo_count; // 0..FIFO_DEPTH

    wire fifo_empty = (fifo_count == 0);
    wire fifo_full  = (fifo_count == FIFO_DEPTH);

    wire [23:0] fifo_R_DATA = fifo_R_mem[fifo_rd_ptr];
    wire        fifo_R_SIG  = fifo_R_DATA[23];

    // ============================================================
    // CPU BUS (MMIO)
    // ============================================================
    reg     fifo_pop;
    reg     fifo_flush;
    
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

    // ---------------- CPU Bus ----------------
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            cpu_rready       <= 1'b0;
            cpu_wready       <= 1'b0;
            cpu_rdata        <= 32'h0;
            fifo_pop         <= 1'b0;
            fifo_flush       <= 1'b0;
        end else begin
            cpu_rready       <= 1'b0;
            cpu_wready       <= 1'b0;
            fifo_pop         <= 1'b0;
            fifo_flush       <= 1'b0;

            // ------------ CPU Bus ----------------
            // READ: DATA FIFO
            if (cpu_rvalid_latch) begin
                case (cpu_raddr)
                    I2S_ADDR_RX: begin
                        cpu_rready <= 1'b1;
                        if (!fifo_empty) begin
                            cpu_rdata <= {{8{fifo_R_SIG}}, fifo_R_DATA};
                            fifo_pop  <= 1'b1;
                        end else begin
                            cpu_rdata <= 32'h0000_00C0; // empty marker (好みで)
                        end
                    end
                    I2S_ADDR_ST: begin
                        cpu_rready <= 1'b1;
                        cpu_rdata <= {fifo_count[7:0], 16'd0, 6'h0, fifo_full, fifo_empty};
                    end
                endcase
            end
            // WRITE: 
            if (cpu_wvalid_latch) begin
                case (cpu_waddr)
                    I2S_ADDR_ST: begin
                        cpu_wready <= 1'b1;
                        fifo_flush <= cpu_wdata[0];
                    end
                endcase
            end
        end
    end

    // ============================================================
    // I2S SCK CLK 
    // ============================================================
    // 16KHz モノラル
    localparam I2S_SCK_DIV =
            (CLK_FREQ_MHz * 1_000_000) / (2 * 1_024_000);
            
    reg [15:0] divcnt;
    reg        I2S_SCK_reg;
    reg        I2S_SCK_d1;

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            divcnt  <= 16'd0;
            I2S_SCK_reg <= 1'b0;
            I2S_SCK_d1  <= 1'b0;
        end else begin
            // SCK
            I2S_SCK_d1 <= I2S_SCK_reg;
            if (divcnt == (I2S_SCK_DIV - 1)) begin
                divcnt      <= 16'd0;
                I2S_SCK_reg <= ~I2S_SCK_reg;
            end else begin
                divcnt      <= divcnt + 16'd1;
            end
        end
    end

    // ============================================================
    // I2S DATA CLK 
    // ============================================================
    reg I2S_SD_d;

    always @(posedge clock) begin
        I2S_SD_d <= I2S_SD;
    end

    // ============================================================
    // I2S DATA CLK 
    // ============================================================
    localparam I2S_DATA_DIV = 64;

    reg [7:0] i2s_data_divcnt;

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            i2s_data_divcnt  <= 8'd0;
            I2S_WS  <= 1'b0;
        end else begin
            if(~I2S_SCK_d1 & I2S_SCK_reg) begin
                if (i2s_data_divcnt == (I2S_DATA_DIV - 1)) begin
                    i2s_data_divcnt      <= 8'd0;
                end else begin
                    i2s_data_divcnt      <= i2s_data_divcnt + 8'd1;
                end
            end
            if(~I2S_SCK_d1 & I2S_SCK_reg) begin
                // WS
                if ((i2s_data_divcnt == 31) || (i2s_data_divcnt == 63)) begin
                    I2S_WS     <= ~I2S_WS;
                end
            end
        end
    end

    // ============================================================
    // I2S DATA RSV
    // ============================================================
    reg [31:0] i2s_rsv_data;
    wire  pos_SCK = ~I2S_SCK_d1 & I2S_SCK_reg;

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            i2s_rsv_data  <= 32'd0;
        end else begin
            if (pos_SCK) begin
                if (i2s_data_divcnt < 32)
                    i2s_rsv_data[32 - i2s_data_divcnt] <= I2S_SD_d;
            end
        end
    end

    // ============================================================
    // FIFO Write
    // ============================================================
    reg [23:0]  fifo_push_data;
    reg         fifo_push;

    // 32bit to 24bit mask funcition
    function [23:0] i2s_to_24bit;
        input [31:0] i2s_data;

        reg [31:0] masked;
        reg signed [23:0] data_24;

    begin
        // マスク（元コードと同じ）
        masked = i2s_data & 32'hFFFF_FF00;

        // 24bit切り出し（符号付きとして扱う）
        i2s_to_24bit = masked[31:8];

    end
    endfunction

    integer  i;

    wire fifo_push_sig = pos_SCK && (i2s_data_divcnt == 31) && !fifo_full;
    wire fifo_pop_sig  = fifo_pop && !fifo_empty;

    // FIFO Write/Read
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            fifo_rd_ptr <= {FIFO_AW{1'b0}};
            fifo_wr_ptr <= {FIFO_AW{1'b0}};
            fifo_count  <= {FIFO_CW{1'b0}};
            
            `ifdef COCOTB_SIM
            for (i=0; i<FIFO_DEPTH; i++) begin
                fifo_R_mem[i] <= 24'h0;
            end
            `endif

        end else begin
            // flush
            if (fifo_flush) begin
                fifo_wr_ptr <= {FIFO_AW{1'b0}};
                fifo_rd_ptr <= {FIFO_AW{1'b0}};
                fifo_count  <= {FIFO_CW{1'b0}};

            end else begin

                case ({fifo_push_sig, fifo_pop_sig})
                    // push
                    2'b10: begin
                        fifo_R_mem[fifo_wr_ptr] <= i2s_to_24bit(i2s_rsv_data);
                        fifo_wr_ptr <= (fifo_wr_ptr == FIFO_DEPTH-1) ? FIFO_AW'(0) : fifo_wr_ptr + FIFO_AW'(1);
                        fifo_count  <= fifo_count + FIFO_CW'(1);
                    end

                    // pop
                    2'b01: begin
                        fifo_rd_ptr <= (fifo_rd_ptr == FIFO_DEPTH-1) ? FIFO_AW'(0) : fifo_rd_ptr + FIFO_AW'(1);
                        fifo_count  <= fifo_count - FIFO_CW'(1);
                    end

                    // push & pop
                    2'b11: begin
                        fifo_R_mem[fifo_wr_ptr] <= i2s_to_24bit(i2s_rsv_data);
                        fifo_wr_ptr <= (fifo_wr_ptr == FIFO_DEPTH-1) ? FIFO_AW'(0) : fifo_wr_ptr + FIFO_AW'(1);
                        fifo_rd_ptr <= (fifo_rd_ptr == FIFO_DEPTH-1) ? FIFO_AW'(0) : fifo_rd_ptr + FIFO_AW'(1);
                        fifo_count  <= fifo_count;
                    end
                    default: begin
                        fifo_count  <= fifo_count;
                    end
                endcase
            end

        end
    end

    // debug
    `ifdef COCOTB_SIM
    wire [31:0] fifo_d0 = fifo_R_mem[0];
    wire [31:0] fifo_d1 = fifo_R_mem[1];
    wire [31:0] fifo_d2 = fifo_R_mem[2];
    wire [31:0] fifo_d3 = fifo_R_mem[3];
    `endif

endmodule