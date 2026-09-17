// NISHIHARU

module PSC_RV32IS_LED #(
    parameter integer LED_NUMBER = 8,
    parameter integer ADDR_WIDTH = 32,
    parameter [ADDR_WIDTH-1:0] LED_ADDRESS = 32'h000F_4000
)(
    input  wire                          clock,
    input  wire                          reset_n,

    /* IO */
    output wire [LED_NUMBER-1:0]        LED_out,

    // CPU read IF (1clk パルス)
    input  wire                         cpu_rvalid,
    input  wire [ADDR_WIDTH-1:0]        cpu_raddr,
    output reg  [31:0]                  cpu_rdata,
    output reg                          cpu_rready,  // 1clk パルス

    // CPU write IF (1clk パルス)
    input  wire                         cpu_wvalid,
    input  wire [ADDR_WIDTH-1:0]        cpu_waddr,
    input  wire [31:0]                  cpu_wdata,
    output reg                          cpu_wready
);

    // アドレス
    wire [ADDR_WIDTH-1:0]     cpu_byte_waddr = cpu_waddr;   // byte address
    wire [ADDR_WIDTH-1:0]     cpu_byte_raddr = cpu_raddr;   // byte address

    // reg
    reg [31:0] MMIO_out_reg;
    assign LED_out = MMIO_out_reg[LED_NUMBER-1:0];

    // ---------------- cpu_valid latch ----------------
    reg     cpu_rvalid_latch;
    reg     cpu_wvalid_latch;
    
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            cpu_wvalid_latch    <= 1'b0;
            cpu_rvalid_latch    <= 1'b0;
        end else begin
            cpu_wvalid_latch    <= cpu_wvalid;
            cpu_rvalid_latch    <= cpu_rvalid;
        end
    end

    // ---------------- MMIO read/write  ----------------
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            MMIO_out_reg  <= 8'd0;
            cpu_rready    <= 1'b0;
            cpu_wready    <= 1'b0;
        end else begin
            cpu_rready    <= 1'b0;
            cpu_wready    <= 1'b0;

            if (cpu_wvalid_latch) begin
                case (cpu_byte_waddr)
                    LED_ADDRESS: begin
                        // enqueue は TX 制御 always が拾う
                        cpu_wready    <= 1'b1;
                        MMIO_out_reg  <= cpu_wdata[31:0];
                    end
                    default: begin
                        cpu_wready <= 1'b0;
                    end
                endcase
            end

            if (cpu_rvalid_latch) begin
                case (cpu_byte_raddr)
                    LED_ADDRESS: begin
                        // enqueue は TX 制御 always が拾う
                        cpu_rready    <= 1'b1;
                        cpu_rdata     <= 32'h0;
                    end
                    default: begin
                        cpu_rready <= 1'b0;
                    end
                endcase
            end
        end
    end

endmodule
