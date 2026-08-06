// ===============================================================
// tft_clock_divider
// ===============================================================
`timescale 1ns / 1ps

module tft_clock_divider #(
    parameter DIV = 2
)(
    input  wire clock,
    input  wire reset_n,
    output reg  clk_div
);

    reg [$clog2(DIV)-1:0] cnt;

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            cnt     <= 0;
            clk_div <= 1'b0;
        end else begin
            if (cnt == (DIV/2 - 1)) begin
                cnt     <= 0;
                clk_div <= ~clk_div;
            end else begin
                cnt <= cnt + 1'b1;
            end
        end
    end

endmodule
