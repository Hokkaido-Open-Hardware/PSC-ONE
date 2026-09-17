module PE_mult #(
    parameter integer DW      = 8,
    parameter integer PW      = 32,
    parameter integer SW      = PW,
    parameter integer N       = 16,

    // 物理乗算器数
    parameter integer MUL_NUM = 2
)(
    input  wire                     clock,
    input  wire                     reset_n,

    // 1バッチ分の入力
    input  wire [N-1:0]             data_in_valid,

    // 計算完了したレーンを1クロック通知
    output reg  [N-1:0]             data_out_ready,

    input  wire [N*DW-1:0]          data_A,
    input  wire [N*DW-1:0]          data_B,

    // レーンごとの乗算結果
    output reg  [N*SW-1:0]          result_C
);

    // ========================================================
    // Utility
    // ========================================================

    function integer CLOG2;
        input integer value;
        integer tmp;
        begin
            tmp   = value - 1;
            CLOG2 = 0;

            while (tmp > 0) begin
                CLOG2 = CLOG2 + 1;
                tmp   = tmp >> 1;
            end

            if (CLOG2 == 0)
                CLOG2 = 1;
        end
    endfunction

    // ========================================================
    // Parameters
    // ========================================================

    localparam integer PARALLEL_NUM =
        (MUL_NUM < 1) ? 1 :
        (MUL_NUM > N) ? N :
                        MUL_NUM;

    localparam integer MW =
        2 * DW;

    localparam integer GROUPS =
        (N + PARALLEL_NUM - 1) / PARALLEL_NUM;

    localparam integer GROUP_W =
        CLOG2(GROUPS);

    // ========================================================
    // State machine
    // ========================================================

    localparam [1:0] STATE_IDLE       = 2'd0;
    localparam [1:0] STATE_ACTIVE     = 2'd1;
    localparam [1:0] STATE_WAIT_CLEAR = 2'd2;

    reg [1:0] state;

    wire active;

    assign active = (state == STATE_ACTIVE);

    // ========================================================
    // Batch registers
    // ========================================================

    /*
     * MUL_NUM=2、N=16の場合:
     *
     * group_index=0 : lane 0,1
     * group_index=1 : lane 2,3
     * group_index=2 : lane 4,5
     * group_index=3 : lane 6,7
     * group_index=4 : lane 8,9
     * group_index=5 : lane 10,11
     * group_index=6 : lane 12,13
     * group_index=7 : lane 14,15
     */
    reg [GROUP_W-1:0] group_index;

    // バッチ受付時のvalidを保持
    reg [N-1:0] valid_latch;

    // バッチ受付時のA/Bを保持
    reg [DW-1:0] data_A_latch [0:N-1];
    reg [DW-1:0] data_B_latch [0:N-1];

    // ========================================================
    // Physical multiplier input/output buses
    // ========================================================

    reg  [PARALLEL_NUM*DW-1:0] mul_A_bus;
    reg  [PARALLEL_NUM*DW-1:0] mul_B_bus;

    wire [PARALLEL_NUM*MW-1:0] mul_result_bus;

    reg [PARALLEL_NUM-1:0] mul_lane_valid;

    // ========================================================
    // Fixed lane selection
    // ========================================================

    integer comb_m;
    integer comb_lane;

    always @(*) begin
        mul_A_bus      = {(PARALLEL_NUM*DW){1'b0}};
        mul_B_bus      = {(PARALLEL_NUM*DW){1'b0}};
        mul_lane_valid = {PARALLEL_NUM{1'b0}};

        for (
            comb_m = 0;
            comb_m < PARALLEL_NUM;
            comb_m = comb_m + 1
        ) begin
            comb_lane =
                group_index * PARALLEL_NUM + comb_m;

            if (
                active &&
                (comb_lane < N) &&
                valid_latch[comb_lane]
            ) begin
                mul_lane_valid[comb_m] = 1'b1;

                mul_A_bus[comb_m*DW +: DW]
                    = data_A_latch[comb_lane];

                mul_B_bus[comb_m*DW +: DW]
                    = data_B_latch[comb_lane];
            end
        end
    end

    // ========================================================
    // Physical multipliers
    //
    // PARALLEL_NUM=2なら乗算演算子は2個だけ生成される。
    // ========================================================

    genvar g;

    generate
        for (
            g = 0;
            g < PARALLEL_NUM;
            g = g + 1
        ) begin : GEN_MULT

            assign mul_result_bus[g*MW +: MW] =
                mul_A_bus[g*DW +: DW]
                *
                mul_B_bus[g*DW +: DW];

        end
    endgenerate

    // ========================================================
    // Sequential control
    // ========================================================

    integer seq_i;
    integer seq_m;
    integer seq_lane;

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            state          <= STATE_IDLE;
            group_index    <= {GROUP_W{1'b0}};
            valid_latch    <= {N{1'b0}};
            data_out_ready <= {N{1'b0}};
            result_C       <= {(N*SW){1'b0}};

            for (
                seq_i = 0;
                seq_i < N;
                seq_i = seq_i + 1
            ) begin
                data_A_latch[seq_i] <= {DW{1'b0}};
                data_B_latch[seq_i] <= {DW{1'b0}};
            end

        end else begin
            // readyは常に1クロックパルス
            data_out_ready <= {N{1'b0}};

            case (state)

                // =============================================
                // IDLE
                //
                // 新しいバッチを一括ラッチする。
                // =============================================

                STATE_IDLE: begin
                    if (|data_in_valid) begin
                        valid_latch <= data_in_valid;

                        for (
                            seq_i = 0;
                            seq_i < N;
                            seq_i = seq_i + 1
                        ) begin
                            if (data_in_valid[seq_i]) begin
                                data_A_latch[seq_i]
                                    <= data_A[seq_i*DW +: DW];

                                data_B_latch[seq_i]
                                    <= data_B[seq_i*DW +: DW];
                            end
                        end

                        group_index <= {GROUP_W{1'b0}};
                        state       <= STATE_ACTIVE;
                    end
                end

                // =============================================
                // ACTIVE
                //
                // lane 0から固定順にPARALLEL_NUM件ずつ処理。
                // =============================================

                STATE_ACTIVE: begin
                    for (
                        seq_m = 0;
                        seq_m < PARALLEL_NUM;
                        seq_m = seq_m + 1
                    ) begin
                        seq_lane =
                            group_index * PARALLEL_NUM
                            + seq_m;

                        if (
                            (seq_lane < N) &&
                            mul_lane_valid[seq_m]
                        ) begin
                            /*
                             * DW=8の場合、乗算結果は16bit。
                             * SW=32へゼロ拡張して格納する。
                             */
                            result_C[seq_lane*SW +: SW]
                                <= {{(SW-MW){1'b0}},
                                    mul_result_bus[
                                        seq_m*MW +: MW
                                    ]};

                            data_out_ready[seq_lane]
                                <= 1'b1;
                        end
                    end

                    // 最終グループを処理した
                    if (group_index == GROUPS - 1) begin
                        group_index <= {GROUP_W{1'b0}};
                        valid_latch <= {N{1'b0}};

                        /*
                         * data_in_validがまだHighの可能性がある。
                         * すぐIDLEへ戻すと、同じバッチを
                         * 再受付してしまうためWAIT_CLEARへ移る。
                         */
                        state <= STATE_WAIT_CLEAR;
                    end
                    else begin
                        group_index <= group_index + 1'b1;
                    end
                end

                // =============================================
                // WAIT_CLEAR
                //
                // PE_INT側がdata_in_validをすべて下げるまで待つ。
                // =============================================

                STATE_WAIT_CLEAR: begin
                    if (!(|data_in_valid)) begin
                        state <= STATE_IDLE;
                    end
                end

                default: begin
                    state       <= STATE_IDLE;
                    group_index <= {GROUP_W{1'b0}};
                    valid_latch <= {N{1'b0}};
                end

            endcase
        end
    end

endmodule