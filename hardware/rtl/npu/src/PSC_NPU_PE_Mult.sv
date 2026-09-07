module PSC_NPU_PE_Mult #(
    parameter int DW      = 8,
    parameter int PW      = 32,
    parameter int SW      = PW,
    parameter int N       = 16,

    // 物理乗算器数
    parameter int MUL_NUM = 2
)(
    input  logic                     clock,
    input  logic                     reset_n,
    input  logic                     signed_mode,

    // 1バッチ分の入力
    input  logic [N-1:0]             data_in_valid,

    // 計算完了したレーンを1クロック通知
    output logic [N-1:0]             data_out_ready,

    input  logic [N*DW-1:0]          data_A,
    input  logic [N*DW-1:0]          data_B,

    // レーンごとの乗算結果
    output logic [N*SW-1:0]          result_C
);

    // ========================================================
    // Utility
    // ========================================================

    function automatic integer CLOG2(input integer value);
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

    localparam int PARALLEL_NUM =
        (MUL_NUM < 1) ? 1 :
        (MUL_NUM > N) ? N :
                        MUL_NUM;

    localparam int MW =
        2 * DW;

    localparam int GROUPS =
        (N + PARALLEL_NUM - 1) / PARALLEL_NUM;

    localparam int GROUP_W =
        CLOG2(GROUPS);

    // ========================================================
    // State machine
    // ========================================================

    localparam logic [1:0] STATE_IDLE       = 2'd0;
    localparam logic [1:0] STATE_ACTIVE     = 2'd1;
    localparam logic [1:0] STATE_WAIT_CLEAR = 2'd2;

    logic [1:0] state;

    logic active;

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
    logic [GROUP_W-1:0] group_index;

    // バッチ受付時のvalidを保持
    logic [N-1:0] valid_latch;
    logic         signed_mode_latch;

    // バッチ受付時のA/Bを保持
    logic [DW-1:0] data_A_latch [0:N-1];
    logic [DW-1:0] data_B_latch [0:N-1];

    // ========================================================
    // Physical multiplier input/output buses
    // ========================================================

    logic [PARALLEL_NUM*DW-1:0] mul_A_bus;
    logic [PARALLEL_NUM*DW-1:0] mul_B_bus;

    logic [PARALLEL_NUM*MW-1:0] mul_result_bus;

    logic [PARALLEL_NUM-1:0] mul_lane_valid;

    // ========================================================
    // Fixed lane selection
    // ========================================================

    integer comb_m;
    integer comb_lane;

    always_comb begin
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

            logic signed [DW-1:0] signed_mul_a;
            logic signed [DW-1:0] signed_mul_b;
            logic signed [MW-1:0] signed_mul_result;
            logic        [MW-1:0] unsigned_mul_result;

            assign signed_mul_a = $signed(mul_A_bus[g*DW +: DW]);
            assign signed_mul_b = $signed(mul_B_bus[g*DW +: DW]);

            assign signed_mul_result = signed_mul_a * signed_mul_b;
            assign unsigned_mul_result =
                mul_A_bus[g*DW +: DW] * mul_B_bus[g*DW +: DW];

            assign mul_result_bus[g*MW +: MW] =
                signed_mode_latch
                ? signed_mul_result
                : unsigned_mul_result;

        end
    endgenerate

    // ========================================================
    // Sequential control
    // ========================================================

    integer seq_i;
    integer seq_m;
    integer seq_lane;

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            state          <= STATE_IDLE;
            group_index    <= {GROUP_W{1'b0}};
            valid_latch         <= {N{1'b0}};
            signed_mode_latch   <= 1'b0;
            data_out_ready      <= {N{1'b0}};
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
                        valid_latch         <= data_in_valid;
                        signed_mode_latch   <= signed_mode;

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
                             * unsignedモードではSW bitへゼロ拡張、
                             * signedモードではSW bitへ符号拡張して格納する。
                             */
                            if (signed_mode_latch) begin
                                result_C[seq_lane*SW +: SW]
                                    <= {{(SW-MW){
                                            mul_result_bus[
                                                seq_m*MW + MW - 1
                                            ]
                                        }},
                                        mul_result_bus[
                                            seq_m*MW +: MW
                                        ]};
                            end else begin
                                result_C[seq_lane*SW +: SW]
                                    <= {{(SW-MW){1'b0}},
                                        mul_result_bus[
                                            seq_m*MW +: MW
                                        ]};
                            end

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