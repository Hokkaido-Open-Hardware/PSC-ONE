// NISHIHARU
`timescale 1ns/1ps

// ROM_SKCKP_MODEのときはRom_Data=32'h00の時の書き込みをスキップ. 
//`define ROM_SKIP_MODE

// kernel.mem, user.memをBSRAMに置く場合にONする.
//`define FPGA_PSC_OS_MODE

// SD Cardからブートする場合にONする.
// Boot Loader モード
//`define FPGA_BOOT_LOADER_MODE

`ifdef FPGA_PSC_OS_MODE
  `define OS_SIM
`endif

module PSC_ONE_Boot_axi #(
    parameter integer ADDR_WIDTH     = 32,
    parameter integer ID_WIDTH       = 1,
    parameter integer DATA_WIDTH     = 32,                  // fixed 32. tang 20k.
    parameter integer FENCE_CYCLES   = 4,                   // B 後の保護バブル (0で無効)
    // ROM ADDR
    parameter [ADDR_WIDTH-1:0] BOOT_BASE_ADDR        = 32'h0000_0000,
    parameter [ADDR_WIDTH-1:0] BOOT_LOADER_BASE_ADDR = 32'h0010_0000,
    parameter [ADDR_WIDTH-1:0] KERNEL_BASE_ADDR      = 32'h0020_0000, 
    parameter [ADDR_WIDTH-1:0] USER_BASE_ADDR        = 32'h0040_0000,  
    // ROM WORD NUMBER
`ifdef OS_SIM
    parameter integer ROM_WORD         = 128,
    parameter integer BOOT_LOADER_WORD = 4500,
    parameter integer KERNEL_ROM_WORD  = 200000,
    parameter integer USER_ROM_WORD    = 150000
`elsif FPGA_BOOT_LOADER_MODE
    parameter integer ROM_WORD         = 128,
    parameter integer BOOT_LOADER_WORD = 4500,
    parameter integer KERNEL_ROM_WORD  = 200000,
    parameter integer USER_ROM_WORD    = 150000
`else
    parameter integer ROM_WORD         = 4096,
    parameter integer BOOT_LOADER_WORD = ROM_WORD,
    parameter integer KERNEL_ROM_WORD  = ROM_WORD,
    parameter integer USER_ROM_WORD    = ROM_WORD
`endif
)(
    input  wire                     clock,
    input  wire                     reset_n,

    input  wire                     sdram_init_fin,
    output reg                      done,

    // ===== AXI4 Master (16-bit) : Write only =====
    // Write Address
    output reg  [ID_WIDTH-1:0]      bt_axi_awid,
    output reg  [ADDR_WIDTH-1:0]    bt_axi_awaddr,
    output reg  [7:0]               bt_axi_awlen,         // 0 (=1beat)
    output reg  [2:0]               bt_axi_awsize,        // 1 (2B)
    output reg  [1:0]               bt_axi_awburst,       // INCR=01
    output reg                      bt_axi_awvalid,
    input  wire                     bt_axi_awready,

    // Write Data
    output reg  [DATA_WIDTH-1:0]    bt_axi_wdata,
    output reg  [(DATA_WIDTH/8)-1:0]bt_axi_wstrb,         // 2'b11
    output reg                      bt_axi_wlast,
    output reg                      bt_axi_wvalid,
    input  wire                     bt_axi_wready,

    // Write Response
    input  wire [ID_WIDTH-1:0]      bt_axi_bid,
    input  wire [1:0]               bt_axi_bresp,
    input  wire                     bt_axi_bvalid,
    output reg                      bt_axi_bready,

    // ===== (Unused) Read Channel : tie-off safely =====
    output reg  [ID_WIDTH-1:0]      bt_axi_arid,
    output reg  [ADDR_WIDTH-1:0]    bt_axi_araddr,
    output reg  [7:0]               bt_axi_arlen,
    output reg  [2:0]               bt_axi_arsize,
    output reg  [1:0]               bt_axi_arburst,
    output reg                      bt_axi_arvalid,
    input  wire                     bt_axi_arready,

    input  wire [ID_WIDTH-1:0]      bt_axi_rid,
    input  wire [DATA_WIDTH-1:0]    bt_axi_rdata,
    input  wire [1:0]               bt_axi_rresp,
    input  wire                     bt_axi_rlast,
    input  wire                     bt_axi_rvalid,
    output reg                      bt_axi_rready
);

    // --------- 幅ユーティリティ（Verilog-2001向け） ---------
    function integer CLOG2;
        input integer value;
        integer i;
        begin
            i = 0;
            value = value - 1;
            for (i = 0; value > 0; i = i + 1)
                value = value >> 1;
            CLOG2 = (i == 0) ? 1 : i;
        end
    endfunction

`ifdef FPGA_PSC_OS_MODE
    localparam integer ERAZE_ROM_WORD   = 32'h0000_1000;  
    localparam integer MAX_ROM_WORD     = 32'h0040_0000;  
    localparam integer ROMIDX_W         = CLOG2(MAX_ROM_WORD+1);
`elsif FPGA_BOOT_LOADER_MODE
    `ifdef COCOTB_SIM
    localparam integer ERAZE_ROM_WORD   = 32'h0000_1000;    // simlationの場合sim時間短縮
    `else
    localparam integer ERAZE_ROM_WORD   = 32'h0040_0000;    // bootloader.cppのメモリテストの結果消去
    `endif
    localparam integer MAX_ROM_WORD     = 32'h0040_0000;  
    localparam integer ROMIDX_W         = CLOG2(MAX_ROM_WORD+1);
`else
    localparam integer ERAZE_ROM_WORD   = 32'h0000_0000;  
    localparam integer MAX_ROM_WORD     = 32'h0000_1000;  
    localparam integer ROMIDX_W         = CLOG2(KERNEL_BASE_ADDR+1);
`endif
    localparam integer FENCE_CNT_W = (FENCE_CYCLES < 1) ? 1 : CLOG2(FENCE_CYCLES+1);


    // --------- ROM (16bit幅, 1clk read 可) ---------
    reg [ROMIDX_W-1:0]      rom_idx;       // 0 .. MAX_WORDS-1
    wire [DATA_WIDTH-1:0]   test_rom_data_out;
    wire [DATA_WIDTH-1:0]   boot_loader_data_out;
    wire [DATA_WIDTH-1:0]   boot_rom_data_out;
    wire [DATA_WIDTH-1:0]   kernel_rom_data_out;
    wire [DATA_WIDTH-1:0]   user_rom_data_out;

    // --- Test ---
    test_rom # (.ADDR_WIDTH(ROMIDX_W), .ROM_WORD(ROM_WORD))
        u_test_rom(.clock(clock), .addr(rom_idx), .dout(test_rom_data_out));

    // --- BOOT LOADER ---
    boot_loader_rom # (.ADDR_WIDTH(ROMIDX_W))
        u_boot_loader_rom(.clock(clock), .addr(rom_idx), .dout(boot_loader_data_out));

    // --- OS ---
    boot_rom # (.ADDR_WIDTH(ROMIDX_W))
        u_boot_rom(.clock(clock), .addr(rom_idx), .dout(boot_rom_data_out));
    kernel_rom # (.ADDR_WIDTH(ROMIDX_W))
        u_kernel_rom(.clock(clock), .addr(rom_idx), .dout(kernel_rom_data_out));
    user_rom # (.ADDR_WIDTH(ROMIDX_W))
        u_user_rom(.clock(clock), .addr(rom_idx), .dout(user_rom_data_out));
    
    // --------- STAGE ---------
    localparam [3:0] ERAZE_STAGE        = 4'd0,
                     BOOT_STAGE         = 4'd1,
                     KERNEL_STAGE       = 4'd2, 
                     USER_STAGE         = 4'd3, 
                     BOOTLOADER_STAGE   = 4'd4;

    reg [3:0]        write_st;

    // --------- FSM ---------
    localparam [3:0] ST_IDLE        = 4'd0,
                     ST_ROM_DATA_IN = 4'd1,
                     ST_ROM_CHK     = 4'd2,  // ROM Data == 16'h00はスキップ
                     ST_W_AW        = 4'd3,  // AW VALID保持
                     ST_PW          = 4'd4,
                     ST_W_W         = 4'd5,  // W 送出（1beat固定）
                     ST_W_B         = 4'd6,  // B 応答待ち
                     ST_FENCE       = 4'd7,  // B後の保護バブル
                     ST_DONE        = 4'd8;  // 全転送完了

    reg [3:0]        st;

    reg [DATA_WIDTH-1:0]    rom_data_0, rom_data_1;
    reg [FENCE_CNT_W-1:0]   fence_cnt;
    reg [ROMIDX_W-1:0]      max_word; 

    // ハンドシェイク
    wire aw_fire = bt_axi_awvalid & bt_axi_awready;
    wire w_fire  = bt_axi_wvalid  & bt_axi_wready;
    wire b_fire  = bt_axi_bvalid  & bt_axi_bready;

    // ===== 本体 =====
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
        `ifdef FPGA_PSC_OS_MODE
            write_st        <= ERAZE_STAGE;
        `elsif FPGA_BOOT_LOADER_MODE
            write_st        <= ERAZE_STAGE;
        `else
            write_st        <= BOOT_STAGE;
        `endif
            st              <= ST_IDLE;
            rom_idx         <= {ROMIDX_W{1'b0}};
            rom_data_0      <= {DATA_WIDTH{1'b0}};
            rom_data_1      <= {DATA_WIDTH{1'b0}};
            fence_cnt       <= {FENCE_CNT_W{1'b0}};
            max_word        <= {ROMIDX_W{1'b0}};
            done            <= 1'b0;

            // AXI 初期値（Write）
            bt_axi_awid     <= {ID_WIDTH{1'b0}};
            bt_axi_awaddr   <= {ADDR_WIDTH{1'b0}};
            bt_axi_awlen    <= 8'd0;          // 1 beat 固定
            bt_axi_awsize   <= 3'd1;          // 2B
            bt_axi_awburst  <= 2'b01;         // INCR
            bt_axi_awvalid  <= 1'b0;

            bt_axi_wdata    <= {DATA_WIDTH{1'b0}};
            bt_axi_wstrb    <= {(DATA_WIDTH/8){1'b1}};
            bt_axi_wlast    <= 1'b0;
            bt_axi_wvalid   <= 1'b0;

            bt_axi_bready   <= 1'b0;

            // AXI Read (未使用) を安全値へ
            bt_axi_arid     <= {ID_WIDTH{1'b0}};
            bt_axi_araddr   <= {ADDR_WIDTH{1'b0}};
            bt_axi_arlen    <= 8'd0;
            bt_axi_arsize   <= 3'd1;
            bt_axi_arburst  <= 2'b01;
            bt_axi_arvalid  <= 1'b0;
            bt_axi_rready   <= 1'b0;

        end else begin
            // 送信中は常に WSTRB=全ビット1（未定義化防止）
            if (bt_axi_wvalid) begin
                bt_axi_wstrb <= {(DATA_WIDTH/8){1'b1}};
            end

            case (st)
                // ---------------- IDLE ----------------
                ST_IDLE: begin
                    bt_axi_awvalid <= 1'b0;
                    bt_axi_wvalid  <= 1'b0;
                    bt_axi_wlast   <= 1'b0;
                    bt_axi_bready  <= 1'b0;
                    st <= ST_ROM_DATA_IN;
                end

                // ---------------- ROM DATA INPUT ----------------
                ST_ROM_DATA_IN: begin
                    `ifdef FPGA_BOOT_LOADER_MODE
                        // FPGA_BOOT_LOADER_MODE mode.
                        case (write_st)
                            ERAZE_STAGE: begin
                                rom_data_0 <= {DATA_WIDTH{1'b0}};
                                max_word   <= ERAZE_ROM_WORD[ROMIDX_W-1:0];
                            end
                            BOOT_STAGE: begin
                                rom_data_0 <= boot_rom_data_out;
                                max_word   <= ROM_WORD[ROMIDX_W-1:0];
                            end
                            BOOTLOADER_STAGE: begin
                                rom_data_0 <= boot_loader_data_out;
                                max_word   <= BOOT_LOADER_WORD[ROMIDX_W-1:0];
                            end
                            default: begin
                                rom_data_0 <= {DATA_WIDTH{1'b0}};
                                max_word   <= ROM_WORD[ROMIDX_W-1:0];
                            end
                        endcase
                    `elsif OS_SIM
                        // OS_SIM mode.
                        case (write_st)
                            ERAZE_STAGE: begin
                                rom_data_0 <= {DATA_WIDTH{1'b0}};
                                max_word   <= MAX_ROM_WORD[ROMIDX_W-1:0];
                            end
                            BOOT_STAGE: begin
                                rom_data_0 <= boot_rom_data_out;
                                max_word   <= ROM_WORD[ROMIDX_W-1:0];
                            end
                            KERNEL_STAGE: begin
                                rom_data_0 <= kernel_rom_data_out;
                                max_word   <= KERNEL_ROM_WORD[ROMIDX_W-1:0];
                            end
                            USER_STAGE: begin
                                rom_data_0 <= user_rom_data_out;
                                max_word   <= USER_ROM_WORD[ROMIDX_W-1:0];
                            end
                            default: begin
                                rom_data_0 <= {DATA_WIDTH{1'b0}};
                                max_word   <= ROM_WORD[ROMIDX_W-1:0];
                            end
                        endcase
                    `else
                        rom_data_0 <= test_rom_data_out;
                        max_word   <= ROM_WORD[ROMIDX_W-1:0];
                    `endif

                    if(sdram_init_fin) begin
                      // ROM_SKCKP_MODEのときはRom_Data=32'h00の時の書き込みをスキップ. （テスト時使用モード）
                      `ifdef ROM_SKIP_MODE
                        rom_data_1 <= boot_rom_data_out;    // TBD
                        st <= ST_ROM_CHK;   // ROM_Data == 32'h00チェック
                      `else
                        st <= ST_PW;
                      `endif
                    end
                end

                // ---------------- ST_ROM_CHK ----------------
                ST_ROM_CHK: begin
                    if (rom_idx >= max_word) begin
                        st <= ST_DONE; // 全転送完了
                    end else begin
                        if (rom_idx[0]==1'b0 && rom_data_0 == 16'h0000 && rom_data_1 == 16'h0000) begin
                            // ROM Data H & L == 16'h00ならばスキップ.
                            rom_idx  <= rom_idx + ROMIDX_W'(2);  // rom_idx + 2
                            st <= ST_IDLE;
                        end else begin
                            st <= ST_PW;
                        end
                    end
                end

                // ---------------- PRE WRITE ----------------
                ST_PW: begin
                    if (fence_cnt != {FENCE_CNT_W{1'b0}}) begin
                        st <= ST_FENCE;
                    end else if (rom_idx < max_word) begin
                        case (write_st) 
                            ERAZE_STAGE: begin
                                bt_axi_awid    <= {ID_WIDTH{1'b0}};
                                bt_axi_awaddr  <= ({{(ADDR_WIDTH-ROMIDX_W){1'b0}}, rom_idx} << 2);
                            end
                            BOOT_STAGE: begin
                                // 次の 1語を書き出す（アドレスは 0x0000 + rom_idx*2 に固定）
                                bt_axi_awid    <= {ID_WIDTH{1'b0}};
                                bt_axi_awaddr  <= ({{(ADDR_WIDTH-ROMIDX_W){1'b0}}, rom_idx} << 2);
                            end
                            KERNEL_STAGE: begin
                                bt_axi_awid    <= {ID_WIDTH{1'b0}};
                                bt_axi_awaddr  <= ({{(ADDR_WIDTH-ROMIDX_W){1'b0}}, rom_idx} << 2) + KERNEL_BASE_ADDR;
                            end
                            USER_STAGE: begin
                                bt_axi_awid    <= {ID_WIDTH{1'b0}};
                                bt_axi_awaddr  <= ({{(ADDR_WIDTH-ROMIDX_W){1'b0}}, rom_idx} << 2) + USER_BASE_ADDR;
                            end
                            BOOTLOADER_STAGE: begin
                                bt_axi_awid    <= {ID_WIDTH{1'b0}};
                                bt_axi_awaddr  <= ({{(ADDR_WIDTH-ROMIDX_W){1'b0}}, rom_idx} << 2) + BOOT_LOADER_BASE_ADDR;
                            end
                            default: begin
                                bt_axi_awid    <= {ID_WIDTH{1'b0}};
                                bt_axi_awaddr  <= {ADDR_WIDTH{1'b0}};
                            end
                        endcase
                        bt_axi_awlen   <= 8'd0;      // 1 beat 固定
                        bt_axi_awsize  <= 3'd1;      // 2B
                        bt_axi_awburst <= 2'b01;     // INCR
                        bt_axi_awvalid <= 1'b1;
                        st <= ST_W_AW;
                    end else if (rom_idx >= max_word) begin
                        st <= ST_DONE; // 全転送完了
                    end
                end

                // ---------------- WRITE: AW ----------------
                ST_W_AW: begin
                    if (aw_fire) begin
                        bt_axi_awvalid <= 1'b0;   // 下げる

                        // 直ちに W を出し始める（1beat）
                        bt_axi_wdata   <= rom_data_0;
                        bt_axi_wlast   <= 1'b1;   // 1beat 固定
                        bt_axi_wvalid  <= 1'b1;

                        st <= ST_W_W;
                    end
                end

                // ---------------- WRITE: W (1 beat) ----------------
                ST_W_W: begin
                    if (w_fire) begin
                        bt_axi_wvalid <= 1'b0;
                        bt_axi_wlast  <= 1'b0;

                        bt_axi_bready <= 1'b1; // B 応答待ちへ
                        st            <= ST_W_B;
                    end
                end

                // ---------------- WRITE: B 応答待ち ----------------
                ST_W_B: begin
                    if (b_fire) begin
                        bt_axi_bready <= 1'b0;

                        // 次ワードへ（アドレスは都度生成）
                        rom_idx  <= rom_idx + {{(ROMIDX_W-1){1'b0}}, 1'b1};

                        // フェンス
                        if (FENCE_CYCLES != 0) begin
                            fence_cnt <= FENCE_CYCLES[FENCE_CNT_W-1:0];
                            st        <= ST_FENCE;
                        end else begin
                            st        <= ST_IDLE;
                        end
                    end
                end

                // ---------------- FENCE ----------------
                // WRITE後のWait
                ST_FENCE: begin
                    if (fence_cnt != {FENCE_CNT_W{1'b0}}) begin
                        fence_cnt <= fence_cnt - {{(FENCE_CNT_W-1){1'b0}}, 1'b1};
                    end
                    if (fence_cnt == {{(FENCE_CNT_W-1){1'b0}}, 1'b1}) begin
                        st <= ST_IDLE;
                    end
                end

                // ---------------- 完了 ----------------
                ST_DONE: begin
                    // FPGA_BOOT_LOADER_MODE優先
                    `ifdef FPGA_BOOT_LOADER_MODE
                    if (write_st == ERAZE_STAGE) begin
                        write_st <= BOOT_STAGE;
                        rom_idx  <= {ROMIDX_W{1'b0}};
                        st <= ST_IDLE;
                    end else if (write_st == BOOT_STAGE) begin
                        write_st <= BOOTLOADER_STAGE;
                        rom_idx  <= {ROMIDX_W{1'b0}};
                        st <= ST_IDLE;
                    end else if (write_st == BOOTLOADER_STAGE) begin
                        done           <= 1'b1;
                    end
                    `elsif OS_SIM
                    if (write_st != USER_STAGE) begin
                        write_st <= write_st + 4'd1;
                        rom_idx  <= {ROMIDX_W{1'b0}};
                        st <= ST_IDLE;
                    end else begin
                        done           <= 1'b1;
                    end
                    `else
                    // 以後は何もしない（必要なら done 出力を追加可能）
                    bt_axi_awvalid <= 1'b0;
                    bt_axi_wvalid  <= 1'b0;
                    bt_axi_bready  <= 1'b0;
                    // done
                    done           <= 1'b1;
                    `endif
                end

                default: begin
                    st <= ST_IDLE;
                end
            endcase
        end
    end

endmodule

//------- Test ROM module -------
// test.mem
module test_rom #(
    parameter integer ADDR_WIDTH = 13,
    parameter integer ROM_WORD   = 4096
)(
    input  wire                  clock,
    input  wire [ADDR_WIDTH-1:0] addr,
    output reg  [31:0]           dout
);
    reg [31:0] Test_rom [0:ROM_WORD-1];
    
    `ifndef OS_SIM
    initial $readmemh("../sim/mem/test_program.mem", Test_rom);
    `endif

    always @(posedge clock) begin
        if (addr > ROM_WORD)
            dout <= 32'd0;
        else
            dout <= Test_rom[addr];
    end
endmodule

//------- BootLoader ROM module -------
// bootloader.mem
module boot_loader_rom #(
    parameter integer ADDR_WIDTH = 13
)(
    input  wire                  clock,
    input  wire [ADDR_WIDTH-1:0] addr,
    output reg  [31:0]           dout
);
    localparam integer ROM_WORD = 4500;  // 固定値にしないとFPGA内でROMと認識されない.
    reg [31:0] Boot_Loader_rom [0:ROM_WORD-1];
    initial $readmemh("mem/bootloader.mem", Boot_Loader_rom);

    always @(posedge clock) begin
        if (addr > ROM_WORD)
            dout <= 32'd0;
        else
            dout <= Boot_Loader_rom[addr];
    end
endmodule

//------- PSC_OS ROM module -------
// boot.mem
module boot_rom #(
    parameter integer ADDR_WIDTH = 13
)(
    input  wire                  clock,
    input  wire [ADDR_WIDTH-1:0] addr,
    output reg  [31:0]           dout
);
    localparam integer ROM_WORD = 128;  // 固定値にしないとFPGA内でROMと認識されない.
    reg [31:0] Boot_rom [0:ROM_WORD-1];
    initial $readmemh("mem/bootrom.mem", Boot_rom);

    always @(posedge clock) begin
        if (addr > ROM_WORD)
            dout <= 32'd0;
        else
            dout <= Boot_rom[addr];
    end
endmodule

// kernel.mem
module kernel_rom #(
    parameter integer ADDR_WIDTH = 20
)(
    input  wire                  clock,
    input  wire [ADDR_WIDTH-1:0] addr,
    output reg  [31:0]           dout
);
    localparam integer ROM_WORD = 200000;
    reg [31:0] mem [0:ROM_WORD-1];
    initial $readmemh("mem/kernel.mem", mem);

    always @(posedge clock) begin
        if (addr > ROM_WORD)
            dout <= 32'd0;
        else
            dout <= mem[addr];
    end
endmodule

// user.mem
module user_rom #(
    parameter integer ADDR_WIDTH = 20
)(
    input  wire                  clock,
    input  wire [ADDR_WIDTH-1:0] addr,
    output reg  [31:0]           dout
);
    localparam integer ROM_WORD = 150000;
    reg [31:0] mem [0:ROM_WORD-1];
    initial $readmemh("mem/user.mem", mem);

    always @(posedge clock) begin
        if (addr > ROM_WORD)
            dout <= 32'd0;
        else
            dout <= mem[addr];
    end
endmodule