module PSC_I2S_MIC_MODEL #(
    parameter DATA_WIDTH = 32
)(
    input  wire         clock,
    input  wire         SCK_i,       // bit clock
    input  wire         WS_i,       
    input  wire         LR_i,        // left/right clock
    output reg          SD_o         // serial data
);

    // サンプルデータ（テスト用）
    reg [DATA_WIDTH-1:0] sample_l = (32'h8000_0000 | 32'h0034_4320) & ~32'h0000_0000;
    reg [DATA_WIDTH-1:0] sample_r = (32'h8000_0000 | 32'h57BA_ABCD) & ~32'h0000_0000;

    reg [DATA_WIDTH-1:0] shift_reg = 0;
    reg [5:0] bit_cnt = 32;
    reg LR_d;
    reg WS_d;
    reg SCK_d;

    // flame counter
    reg [23:0] flame_cnt = 0;

    initial SD_o = 1'b0;

    always @(posedge clock) begin
        LR_d  <= LR_i;
        WS_d  <= WS_i;
        SCK_d <= SCK_i;
        // LR select
        if (WS_d != WS_i) begin
            // チャンネルDATA選択
            if (WS_i == 0 && LR_i == 0)
                shift_reg <= sample_l + (flame_cnt<<8); // Left
                //shift_reg <= sample_l; // Left
            else if (WS_i == 1 && LR_i == 1)
                shift_reg <= sample_r + (flame_cnt<<8); // Right
        end
        // SD_o
        if (WS_i != WS_d) begin
            bit_cnt     <= DATA_WIDTH;
            SD_o        <= 1'b0;
            flame_cnt   <= flame_cnt + 1;
        end
        if (SCK_d && ~SCK_i) begin
            // 変化検出（フレーム開始）
            if (bit_cnt > 1) begin
                SD_o        <= shift_reg[bit_cnt-1]; // MSB first
                bit_cnt     <= bit_cnt - 1;
            end else begin
                SD_o        <= 0;
            end
        end
    end

endmodule
