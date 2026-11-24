module dvi_tx_tmds_enc(
    input wire          clock,
    input wire          reset,
    input wire          den,
    input wire [7:0]    data,
    input wire [1:0]    ctrl,
    output reg [9:0]    tmds
);
    function [2:0] ones4(input [3:0] bits);
        begin
            ones4 = {2'b0, bits[0]} + bits[1] + bits[2] + bits[3];
        end
    endfunction

    reg [7:0] data_reg;
    reg den_reg, den_qm, den_symbol;
    reg [1:0] ctrl_reg, ctrl_qm, ctrl_symbol;

    // Transition minimization. XNOR differs from prefix XOR at odd indices.
    wire [3:0] data_ones = {1'b0, ones4(data_reg[3:0])} + ones4(data_reg[7:4]);
    wire use_xnor = data_ones > 4 || (data_ones == 4 && !data_reg[0]);
    wire [7:0] prefix_xor;
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_prefix
            assign prefix_xor[i] = ^data_reg[i:0];
        end
    endgenerate
    reg [8:0] qm;
    wire [3:0] qm_ones = {1'b0, ones4(qm[3:0])} + ones4(qm[7:4]);

    // Precompute both possible changes in running disparity, in units of
    // two bits. Include the two TMDS header bits for each choice.
    reg [8:0] symbol;
    reg signed [4:0] delta_plain, delta_inverted;
    reg balanced, more_ones;
    reg signed [4:0] disparity;
    wire invert = (disparity == 0 || balanced) ? !symbol[8]
                                               : (more_ones == !disparity[4]);

    always @(posedge clock) begin
        if (reset) begin
            data_reg <= 0;
            den_reg <= 0;
            ctrl_reg <= 0;
            qm <= 0;
            den_qm <= 0;
            ctrl_qm <= 0;
            symbol <= 0;
            delta_plain <= 0;
            delta_inverted <= 0;
            balanced <= 0;
            more_ones <= 0;
            den_symbol <= 0;
            ctrl_symbol <= 0;
            disparity <= 0;
            tmds <= 0;
        end else begin
            data_reg <= data;
            den_reg <= den;
            ctrl_reg <= ctrl;

            qm <= {~use_xnor, prefix_xor ^ (use_xnor ? 8'haa : 8'h00)};
            den_qm <= den_reg;
            ctrl_qm <= ctrl_reg;

            symbol <= qm;
            delta_plain <= $signed({1'b0, qm_ones}) - 5'sd4 - $signed({4'b0, !qm[8]});
            delta_inverted <= 5'sd4 - $signed({1'b0, qm_ones}) + $signed({4'b0, qm[8]});
            balanced <= qm_ones == 4;
            more_ones <= qm_ones > 4;
            den_symbol <= den_qm;
            ctrl_symbol <= ctrl_qm;

            if (den_symbol) begin
                tmds <= {invert, symbol[8], symbol[7:0] ^ {8{invert}}};
                disparity <= disparity + (invert ? delta_inverted : delta_plain);
            end else begin
                disparity <= 0;
                case (ctrl_symbol)
                    2'b00: tmds <= 10'b1101010100;
                    2'b01: tmds <= 10'b0010101011;
                    2'b10: tmds <= 10'b0101010100;
                    2'b11: tmds <= 10'b1010101011;
                endcase
            end
        end
    end
endmodule
