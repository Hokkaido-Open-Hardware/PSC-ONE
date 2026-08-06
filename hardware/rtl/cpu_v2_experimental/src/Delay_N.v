`timescale 1ns/1ps
// ===============================================================
// delay_n
//   - 入力 din を N クロック後に dout で出力
//   - 幅 WIDTH 可変
//   - 同期リセット reset でパイプを RESET_VAL でクリア
//   - N=0 のときは dout=din（レイテンシ0）
// ===============================================================
module delay_n #(
    parameter integer N      = 1,    // 遅延クロック数
    parameter integer WIDTH  = 1,    // 信号幅
    parameter [WIDTH-1:0] RESET_VAL = {WIDTH{1'b0}}
)(
    input  wire                 clk,
    input  wire                 reset_n,   // 同期リセット（Lでクリア）
    input  wire [WIDTH-1:0]     din,
    output wire [WIDTH-1:0]     dout
);

generate
    if (N == 0) begin : g_passthrough
        // 遅延なし
        assign dout = din;
    end else begin : g_delay
        // シフトレジスタ（write-first 同期動作）
        reg [WIDTH-1:0] pipe [0:N-1];
        integer i;

        always @(posedge clk) begin
            if (~reset_n) begin
                for (i = 0; i < N; i = i + 1)
                    pipe[i] <= RESET_VAL;
            end else begin
                pipe[0] <= din;
                for (i = 1; i < N; i = i + 1)
                    pipe[i] <= pipe[i-1];
            end
        end

        assign dout = pipe[N-1];
    end
endgenerate

endmodule
