// NISHIHARU

module MemoryStore #(
    parameter UART_MMIO_ADDR    = 32'h0000_FFF0,
    parameter UART_MMIO_FLAG    = 32'h0000_FFF4,
    parameter COUNTER_MMIO_ADDR = 32'h0000_FFF8
)(
    input wire              clock,
    input  wire             reset_n,
    input  wire             store_enb,
    input  wire             mem_rw,            // 1: store, 0: load
    input  wire [1:0]       wb_sel,
    input  wire             pc_sel2,
    input  wire [31:0]      alu_data,
    input  wire [2:0]       mem_val,           // funct3
    input  wire [31:0]      mem_read_data,     // 常に32bitで返る
    input  wire [31:0]      r_data2,
    input  wire [31:0]      in_pc,
    input  wire [31:0]      counter,
    input  wire [1:0]       ld_low2,           // ★ 追加：ロード時のアドレス下位2bit
    input  wire [31:0]      csr_rdata,
    input wire [31:0]       d_paddr,
    // memory 
    output wire [31:0]      data_mem_write_address,
    output reg              data_mem_write_valid,
    output reg  [31:0]      data_mem_write_data,
    input wire              data_mem_write_ready,
    input wire              data_mem_req_ready,
    // output 
    output reg  [8:0]       uart,
    output wire [31:0]      w_data,
    output reg              store_done,
    // pc
    output reg [31:0]       out_pc
);

    assign  data_mem_write_address = d_paddr;

    // ------------------------------------------------------------
    // アドレス/基本信号
    // ------------------------------------------------------------
    wire [31:0] mem_addr = alu_data;

    // ------------------------------------------------------------
    // LOAD データ整形（addr[1:0] でバイト/ハーフ抽出）
    // ------------------------------------------------------------
    // Little Endian: byte0= [7:0], byte1=[15:8], byte2=[23:16], byte3=[31:24]
    wire [7:0]  rbyte  = (ld_low2==2'd0) ? mem_read_data[7:0]   :
                         (ld_low2==2'd1) ? mem_read_data[15:8]  :
                         (ld_low2==2'd2) ? mem_read_data[23:16] :
                                           mem_read_data[31:24];

    // halfword は addr[0]==0 を前提（RISC-V仕様）。addr[1]で下位/上位ハーフを選択
    wire [15:0] rhword = (ld_low2[1]==1'b0) ? mem_read_data[15:0]
                                            : mem_read_data[31:16];

    // funct3 判定
    wire is_LB  = (mem_val == 3'b000);
    wire is_LH  = (mem_val == 3'b001);
    wire is_LW  = (mem_val == 3'b010);
    wire is_LBU = (mem_val == 3'b100);
    wire is_LHU = (mem_val == 3'b101);

    wire [31:0] ld_result =     is_LB  ? {{24{rbyte[7]}},   rbyte}  :
                                is_LBU ? {24'b0,            rbyte}  :
                                is_LH  ? {{16{rhword[15]}}, rhword} :
                                is_LHU ? {16'b0,            rhword} :
                                        mem_read_data; // LW

    // ------------------------------------------------------------
    // MMIO 読み取りの特例（従来優先度を維持）
    // ------------------------------------------------------------
    wire is_mmio_counter   = (is_LW && (mem_addr == COUNTER_MMIO_ADDR));
    wire is_mmio_uart_flag = ((mem_val[1:0]==2'b00) && (mem_addr == UART_MMIO_FLAG)); // LB/LBU想定

    // ------------------------------------------------------------
    // MEMORY READ 出力（wb_sel=01 のとき w_data に使われる）
    // ------------------------------------------------------------
    wire [31:0] mem_data =  (mem_rw == 1'b1) ? 32'b0 :
                            is_mmio_counter   ? counter :
                            is_mmio_uart_flag ? 32'h0000_0001 :
                                                ld_result;

    // ------------------------------------------------------------
    // MEMORY WRITE + UART
    //   ※ 既存IF（mem_write_sel=000:SB, 001:SH, 010:SW）を維持
    //   ※ バイトレーン位置を下位モジュールで解釈する場合は、
    //      mem_addr[1:0] を併せて伝搬/利用してください。
    // ------------------------------------------------------------

    localparam IDLE             = 4'd0;
    localparam STORE            = 4'd1;
    localparam STORE_WAIT       = 4'd2;
    localparam STORE_DONE       = 4'd3;
    localparam STORE_DONE_WAIT  = 4'd4;

    reg [3:0]  state;
    
    always @(posedge clock or negedge reset_n) begin
        if(!reset_n) begin
            data_mem_write_valid  <= 1'b0;
            data_mem_write_data   <= 32'h00;
            out_pc           <= 32'h0;
            uart             <= 9'b0;
            store_done       <= 1'b0;
            state            <= 4'd0;
        end else begin
            data_mem_write_valid  <= 1'b0;
            store_done       <= 1'b0;

            case (state)
                IDLE: begin
                    if (store_enb)
                        state <= STORE;
                end
                STORE: begin
                    if (data_mem_req_ready) begin
                        // word
                        if (mem_rw) begin
                            data_mem_write_valid  <= 1'b1;
                            data_mem_write_data   <= r_data2;
                            state            <= STORE_WAIT;
                        end else begin
                            state            <= IDLE;
                        end
                        // uart (TBD)
                        if ((mem_rw == 1'b1) && (mem_addr == UART_MMIO_ADDR)) begin
                            uart <= {1'b1, r_data2[7:0]};
                        end else begin
                            uart <= 9'b0;
                        end
                    end
                end
                STORE_WAIT: begin
                    if (data_mem_write_ready) begin
                        store_done  <= 1'b1;
                        state       <= STORE_DONE_WAIT;
                    end
                end
                STORE_DONE_WAIT: begin
                    state <= IDLE;
                end
                default: begin
                    data_mem_write_valid  <= 1'b0;
                end

            endcase

            // pc
            if (store_enb) begin
                out_pc           <= in_pc;
            end
        end
    end

    // ------------------------------------------------------------
    // REGISTER WRITE BACK
    // 00: ALU, 01: MEM, 10: PC+4, 11: CSR(old)
    // ------------------------------------------------------------
    assign w_data = (wb_sel == 2'b00) ? alu_data :
                    (wb_sel == 2'b01) ? mem_data :
                    (wb_sel == 2'b10) ? (in_pc + 32'd4) :
                                        csr_rdata;   // 2'b11

endmodule
