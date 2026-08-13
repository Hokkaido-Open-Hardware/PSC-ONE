/*
NISHIHARU
*/
`timescale 1ns / 1ps

module sim_sdram_controller #(
    parameter CLK_FREQ_MHz       = 80,

    parameter COL_ADDR_BUS_WIDTH = 8,
    parameter ROW_ADDR_BUS_WIDTH = 11,
    parameter BNK_ADDR_BUS_WIDTH = 2,

    parameter DQ_BUS_WIDTH       = 16,
    parameter DQM_BUS_WIDTH      = 2,
    parameter SD_ADDR_BUS_WIDTH  = 11,

    parameter CW   = COL_ADDR_BUS_WIDTH,
    parameter RW   = ROW_ADDR_BUS_WIDTH,
    parameter BW   = BNK_ADDR_BUS_WIDTH,
    parameter SDAW = SD_ADDR_BUS_WIDTH
)(
    input  wire                     clock,
    input  wire                     reset_n,
    // ==== READ要求 ====

    input  wire [3:0]               rw_length,           // 1,4,8

    input  wire                     read_valid,
    output wire                     read_ready,
    input  wire [BW-1:0]            read_addr_ba,
    input  wire [RW-1:0]            read_addr_row,
    input  wire [CW-1:0]            read_addr_col,
    output wire [DQ_BUS_WIDTH-1:0]  read_data,

    // ==== WRITE要求 ====
    input  wire                     write_valid,
    output wire                     write_ready,
    input  wire [BW-1:0]            write_addr_ba,
    input  wire [RW-1:0]            write_addr_row,
    input  wire [CW-1:0]            write_addr_col,
    input  wire [DQ_BUS_WIDTH-1:0]  write_data
);


    `ifdef COCOTB_SIM
    `ifdef SDRAM_CNT_SIM
    initial begin
        `ifdef DUMP_VCD
        $display("COCOTB_SIM DUMP_VCD ENABLE");
        $dumpfile("./wave/PSC_SDRAM_test.vcd");  // 出力するVCDファイル名
        $dumpvars(0);     // 第1引数: 階層 (0 はこのモジュールを最上位として)
        `else
        $display("COCOTB_SIM verilator FST ENABLE");
        $dumpfile("./wave/PSC_SDRAM_test.fst");  // 出力するVCDファイル名
        $dumpvars(0);     // 第1引数: 階層 (0 はこのモジュールを最上位として)
        `endif
    end
    `endif
    `endif

    // ============================================================
    // controller control
    // ============================================================

    wire       req_ready;
    wire       sdram_init_fin;


    // ============================================================
    // SDRAM signals
    // ============================================================

    wire                    O_sdram_clk;
    wire                    O_sdram_cke = 1'b1;

    wire                    O_sdram_cs_n;
    wire                    O_sdram_ras_n;
    wire                    O_sdram_cas_n;
    wire                    O_sdram_wen_n;

    wire [SDAW-1:0]         O_sdram_addr;
    wire [1:0]              O_sdram_ba;

    wire [DQM_BUS_WIDTH-1:0] O_sdram_dqm;
    wire [DQ_BUS_WIDTH-1:0]  IO_sdram_dq;

    assign sdram_cke = 1'b1;


    // ============================================================
    // SDRAM controller
    // ============================================================

    sdram_controller #(
        .CLK_FREQ_MHz          (CLK_FREQ_MHz),

        .COL_ADDR_BUS_WIDTH    (COL_ADDR_BUS_WIDTH),
        .ROW_ADDR_BUS_WIDTH    (ROW_ADDR_BUS_WIDTH),
        .BNK_ADDR_BUS_WIDTH    (BNK_ADDR_BUS_WIDTH),

        .DQ_BUS_WIDTH          (DQ_BUS_WIDTH),
        .DQM_BUS_WIDTH         (DQM_BUS_WIDTH),
        .SD_ADDR_BUS_WIDTH     (SD_ADDR_BUS_WIDTH),

        .SDRAM_INIT_CNT        ((64 * CLK_FREQ_MHz) / 10),

        .clk_dly_ps            (1),

        .timing_CAS            (3),
        .timing_RCD            (2),
        .timing_RP             (3),
        .timing_MD             (3),
        .timing_RFC            (8),

        .CW                    (CW),
        .RW                    (RW),
        .BW                    (BW),
        .SDAW                  (SDAW)
    ) u_sdram_controller (
        .clock                 (clock),
        .reset_n               (reset_n),

        .rw_length             (rw_length),
        .req_ready             (req_ready),
        .sdram_init_fin        (sdram_init_fin),

        // READ
        .read_valid            (read_valid),
        .read_ready            (read_ready),
        .read_addr_ba          (read_addr_ba),
        .read_addr_row         (read_addr_row),
        .read_addr_col         (read_addr_col),
        .read_data             (read_data),

        // WRITE
        .write_valid           (write_valid),
        .write_ready           (write_ready),
        .write_addr_ba         (write_addr_ba),
        .write_addr_row        (write_addr_row),
        .write_addr_col        (write_addr_col),
        .write_data            (write_data),

        // SDRAM IF
        .sdram_clk             (O_sdram_clk),
        .sdram_cs              (O_sdram_cs_n),
        .sdram_ras             (O_sdram_ras_n),
        .sdram_cas             (O_sdram_cas_n),
        .sdram_we              (O_sdram_wen_n),

        .sdram_adr             (O_sdram_addr),
        .sdram_ba              (O_sdram_ba),
        .sdram_dqm             (O_sdram_dqm),
        .sdram_dq              (IO_sdram_dq)
    );


    // ============================================================
    // SDRAM model
    // ============================================================

    // ------------------------------
    // SDRAM モデル（GW2AR SDRAM）
    //   - CKEは常時High
    // ------------------------------
    // SDRAMモデル（GW2AR SDRAM）
    GW2AR_sdram u_sdram_model (
        .Dq         (IO_sdram_dq),
        .Addr       (O_sdram_addr),
        .Ba         (O_sdram_ba),
        .Clk        (O_sdram_clk),
        .Cke        (1'b1),
        .Cs_n       (O_sdram_cs_n),
        .Ras_n      (O_sdram_ras_n),
        .Cas_n      (O_sdram_cas_n),
        .We_n       (O_sdram_wen_n),
        .Dqm        (O_sdram_dqm)
    );

endmodule