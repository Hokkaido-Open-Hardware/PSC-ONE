`timescale 1ns/1ps
// 2-path Fetch controller
// 分岐確定後に採用したFIFOだけをDecodeへ渡す。

module PSC_FetchPredict #(
    parameter logic BURST_MODE = 1'b1,
    parameter int   FIFO_DEPTH = 16
)(
    input  logic        clock,
    input  logic        reset_n,
    input  logic        cpu_stop,
    input  logic        fetch_valid,
    output logic        fetch_ready,
    input  logic        execute_task_busy,
    input  logic        fifo_flush,
    input  logic [63:0] pc,

    // Branch prediction / resolution
    input  logic        prediction_enable,
    input  logic        branch_resolve_valid,
    input  logic        branch_resolve_taken,
    input  logic [63:0] branch_resolve_pc,
    input  logic [63:0] branch_resolve_target,

    // Fetch
    output logic [63:0] fetch_pc,
    output logic        fetch_enb,
    input  logic        fetch_done,
    input  logic        fetch_busy,
    output logic        cpu_state_done,
    input  logic        in_valid,
    input  logic [31:0] in_data,
    input  logic [63:0] in_pc,

    // FIFO / Decode
    output logic        fifo_req_ready,
    output logic        fifo_full,
    input  logic        fifo_read_valid,
    output logic        fifo_read_ready,
    output logic        fifo_ready,
    output logic [31:0] out_data,
    output logic [63:0] out_pc
);

    // =====================================
    // Local constants / state
    // =====================================

    localparam int TARGET_DEPTH = 8;
    localparam int COUNT_BITS   = $clog2(FIFO_DEPTH) + 1;

    typedef enum logic [2:0] {
        READY,
        LAUNCH,
        WAIT_DATA,
        DRAIN,
        RECOVER
    } state_t;

    state_t state;

    logic [9:0]  wakeup;
    logic [63:0] normal_next_pc;
    logic [63:0] predicted_pc;
    logic [63:0] prediction_pc;
    logic        prediction_pending;
    logic        predicted_taken;
    logic        target_requested;
    logic        target_complete;
    logic        target_active;
    logic        request_target;
    logic        request_killed;

    logic [COUNT_BITS-1:0] normal_count;
    logic [3:0]  target_count;
    logic        normal_valid;
    logic        target_valid;
    logic [31:0] normal_data;
    logic [63:0] normal_pc;
    logic [31:0] target_data;
    logic [63:0] target_pc;
    logic        normal_flush;
    logic        target_flush;
    logic        redirect;
    logic        resolved;
    logic        promote;
    logic        pop;
    logic        predict;
    logic        head_branch;
    logic        head_jal;
    logic [63:0] head_offset;
    logic [31:0] candidate_data;
    logic [63:0] candidate_pc;
    logic        candidate_head;
    logic        candidate_valid;

    // A branch resolution uses the same 32-bit comparators on two edges.
    // Register the final match before it drives the FIFO control fanout.
    typedef enum logic [1:0] {CMP_IDLE, CMP_HIGH, CMP_DONE} compare_state_t;
    compare_state_t compare_state;
    logic compare_start, compare_block;
    logic [31:0] resolve_pc_high, resolve_target_high;
    logic resolve_pc_low_equal, resolve_target_low_equal;
    logic resolve_pc_match, resolve_target_match;
    logic resolve_taken, resolve_flush;
    wire [31:0] compare_pc_a = compare_state == CMP_HIGH
                            ? resolve_pc_high : branch_resolve_pc[31:0];
    wire [31:0] compare_pc_b = compare_state == CMP_HIGH
                            ? prediction_pc[63:32] : prediction_pc[31:0];
    wire [31:0] compare_target_a = compare_state == CMP_HIGH
                                ? resolve_target_high : branch_resolve_target[31:0];
    wire [31:0] compare_target_b = compare_state == CMP_HIGH
                                ? predicted_pc[63:32] : predicted_pc[31:0];
    (* keep = "true" *) wire [15:0] compare_pc_equal;
    (* keep = "true" *) wire [15:0] compare_target_equal;
    genvar eq_group;
    generate
        for (eq_group = 0; eq_group < 16; eq_group = eq_group + 1) begin : g_resolve_equal
            assign compare_pc_equal[eq_group] =
                ~|(compare_pc_a[eq_group*2 +: 2] ^ compare_pc_b[eq_group*2 +: 2]);
            assign compare_target_equal[eq_group] =
                ~|(compare_target_a[eq_group*2 +: 2] ^ compare_target_b[eq_group*2 +: 2]);
        end
    endgenerate

    assign compare_start = branch_resolve_valid && prediction_pending &&
                           compare_state == CMP_IDLE && !cpu_stop &&
                           state != DRAIN && state != RECOVER;
    assign compare_block = compare_start || compare_state != CMP_IDLE;

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            compare_state            <= CMP_IDLE;
            resolve_pc_high          <= '0;
            resolve_target_high      <= '0;
            resolve_pc_low_equal     <= 1'b0;
            resolve_target_low_equal <= 1'b0;
            resolve_pc_match         <= 1'b0;
            resolve_target_match     <= 1'b0;
            resolve_taken            <= 1'b0;
            resolve_flush            <= 1'b0;
        end else if (cpu_stop || (fifo_flush && !compare_start)) begin
            // A fresh exception/flush always takes priority over a saved hit.
            compare_state <= CMP_IDLE;
            resolve_flush <= 1'b0;
        end else begin
            case (compare_state)
                CMP_IDLE: if (compare_start) begin
                    resolve_pc_high          <= branch_resolve_pc[63:32];
                    resolve_target_high      <= branch_resolve_target[63:32];
                    resolve_pc_low_equal     <= &compare_pc_equal;
                    resolve_target_low_equal <= &compare_target_equal;
                    resolve_taken            <= branch_resolve_taken;
                    resolve_flush            <= fifo_flush;
                    compare_state            <= CMP_HIGH;
                end
                CMP_HIGH: begin
                    resolve_pc_match     <= resolve_pc_low_equal && (&compare_pc_equal);
                    resolve_target_match <= resolve_target_low_equal && (&compare_target_equal);
                    compare_state        <= CMP_DONE;
                end
                default: compare_state <= CMP_IDLE;
            endcase
        end
    end


    // =====================================
    // Prediction candidate
    // =====================================

    // FIFO先頭を優先し、先頭が分岐でない場合はFetch応答を先行デコードする。
    // Decode / ISSUEのstallとは独立して先読みを開始する。
    // redirect時は予測情報を破棄する。
    assign candidate_head = normal_valid &&
                            ((normal_data[6:0] == 7'b1100011) ||
                             (normal_data[6:0] == 7'b1101111));
    assign candidate_data = candidate_head ? normal_data : in_data;
    assign candidate_pc   = candidate_head ? normal_pc   : in_pc;
    assign candidate_valid = candidate_head ||
                             (in_valid && !request_target && !request_killed);

    // =====================================
    // FIFO output
    // =====================================

    assign out_data        = target_active ? target_data  : normal_data;
    assign out_pc          = target_active ? target_pc    : normal_pc;
    assign fifo_req_ready  = (target_active ? target_valid : normal_valid) &&
                             (state != DRAIN) && (state != RECOVER) && !cpu_stop &&
                             !compare_block;
    assign fifo_ready      = fifo_req_ready;
    assign fifo_full       = (normal_count == COUNT_BITS'(FIFO_DEPTH));
    assign pop             = fifo_read_valid && fifo_req_ready;
    assign fifo_read_ready = pop;

    // =====================================
    // Branch prediction / resolution
    // =====================================

    // BTFNT : 後方分岐Taken / 前方分岐Not Taken。履歴テーブルは持たない。
    // JALは即値からtargetを計算する。
    // JALRとアドレス変換時のFetchは既存のredirect経路を使用する。
    assign head_branch = (candidate_data[6:0] == 7'b1100011);
    assign head_jal    = (candidate_data[6:0] == 7'b1101111);
    assign head_offset = head_jal
                       ? {{43{candidate_data[31]}}, candidate_data[31],
                          candidate_data[19:12], candidate_data[20],
                          candidate_data[30:21], 1'b0}
                       : {{51{candidate_data[31]}}, candidate_data[31],
                          candidate_data[7], candidate_data[30:25],
                          candidate_data[11:8], 1'b0};

    assign predict = candidate_valid && prediction_enable && !prediction_pending &&
                     !target_active && !(request_target && state != READY) &&
                     (head_branch || head_jal) && !head_offset[1] &&
                     state != DRAIN && state != RECOVER && !compare_block;
    assign resolved = compare_state == CMP_DONE && prediction_pending &&
                      resolve_pc_match && !fifo_flush && !cpu_stop;
    assign promote  = resolved && resolve_taken && predicted_taken &&
                      resolve_target_match;

    // pipeline側のfifo_flushは、後続のID命令を従来どおり破棄する。
    // Fetch側では、確定したtargetと一致するFIFOだけを保持する。
    // The pipeline still flushes ID immediately. Defer only the fetch-side
    // branch flush until both halves match; unrelated flushes remain immediate.
    assign redirect     = (fifo_flush && !compare_start) ||
                          (compare_state == CMP_DONE && resolve_flush && !promote);
    assign normal_flush = cpu_stop || redirect || promote || state == DRAIN;
    assign target_flush = cpu_stop || redirect || state == DRAIN || predict ||
                          (resolved && !promote);

    // =====================================
    // Fetch FIFO 0 / Fetch FIFO 1
    // =====================================

    PSC_PathFifo #(
        .DEPTH          (FIFO_DEPTH)
    ) u_normal (
        .clock          (clock),
        .reset_n        (reset_n),
        .flush          (normal_flush),
        .push           (in_valid && !request_target && !request_killed),
        .data           (in_data),
        .pc             (in_pc),
        .pop            (pop && !target_active),
        .valid          (normal_valid),
        .out_data       (normal_data),
        .out_pc         (normal_pc),
        .count          (normal_count)
    );

    PSC_PathFifo #(
        .DEPTH          (TARGET_DEPTH)
    ) u_target (
        .clock          (clock),
        .reset_n        (reset_n),
        .flush          (target_flush),
        .push           (in_valid && request_target && !request_killed),
        .data           (in_data),
        .pc             (in_pc),
        .pop            (pop && target_active),
        .valid          (target_valid),
        .out_data       (target_data),
        .out_pc         (target_pc),
        .count          (target_count)
    );

    // =====================================
    // Fetch control
    // =====================================

    // Fetch開始前に、要求アドレスと応答の格納先をregisterへ保持する。
    assign fetch_enb      = state == LAUNCH && !redirect &&
                            !(promote && !request_target) && !cpu_stop && !compare_block;
    assign cpu_state_done = state == WAIT_DATA;

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            state              <= READY;
            wakeup             <= 10'd0;
            fetch_ready        <= 1'b0;
            fetch_pc           <= 64'd0;
            normal_next_pc     <= 64'd0;
            predicted_pc       <= 64'd0;
            prediction_pc      <= 64'd0;
            prediction_pending <= 1'b0;
            predicted_taken    <= 1'b0;
            target_requested   <= 1'b0;
            target_complete    <= 1'b0;
            target_active      <= 1'b0;
            request_target     <= 1'b0;
            request_killed     <= 1'b0;
        end else begin
            if (wakeup != 10'h3ff)
                wakeup <= wakeup + 1'b1;
            fetch_ready <= 1'b0;

            if (predict) begin
                prediction_pending <= 1'b1;
                prediction_pc      <= candidate_pc;
                predicted_pc       <= candidate_pc + head_offset;
                predicted_taken    <= head_jal || candidate_data[31];
                target_requested   <= 1'b0;
                target_complete    <= 1'b0;
            end

            if (resolved) begin
                prediction_pending <= 1'b0;
                if (promote) begin
                    target_active  <= 1'b1;
                    normal_next_pc <= BURST_MODE
                                    ? {predicted_pc[63:5], 5'b0} + 64'd32
                                    : predicted_pc + 64'd4;
                    if (!request_target)
                        request_killed <= 1'b1;
                end else begin
                    target_requested <= 1'b0;
                    target_complete  <= 1'b0;
                    if (request_target)
                        request_killed <= 1'b1;
                end
            end

            if (target_active && target_complete && !target_valid) begin
                target_active    <= 1'b0;
                target_requested <= 1'b0;
                target_complete  <= 1'b0;
            end

            case (state)
                READY:
                    if (fetch_valid && wakeup > 10'h300 && !resolved && !compare_block) begin
                        if (((prediction_pending && predicted_taken) || target_active) &&
                            !target_requested) begin
                            fetch_pc         <= predicted_pc;
                            request_target   <= 1'b1;
                            request_killed   <= 1'b0;
                            target_requested <= 1'b1;
                            state            <= LAUNCH;
                        end else if (normal_count <= COUNT_BITS'(FIFO_DEPTH - (BURST_MODE ? 8 : 1))) begin
                            fetch_pc       <= normal_next_pc;
                            normal_next_pc <= BURST_MODE
                                            ? {normal_next_pc[63:5], 5'b0} + 64'd32
                                            : normal_next_pc + 64'd4;
                            request_target <= 1'b0;
                            request_killed <= 1'b0;
                            state          <= LAUNCH;
                        end
                    end

                LAUNCH: begin
                    if (!compare_block)
                        state <= WAIT_DATA;
                    // 未発行の通常要求がTakenで取り消された場合、Fetchは
                    // fetch_enbを受けていないため、応答を待たない。
                    if (resolved && ((promote && !request_target) ||
                                     (!promote && request_target)))
                        state <= READY;
                end

                WAIT_DATA:
                    if (fetch_done) begin
                        state       <= READY;
                        fetch_ready <= 1'b1;
                        if (request_target && !request_killed && !(resolved && !promote))
                            target_complete <= 1'b1;
                    end

                DRAIN:
                    if (!fetch_busy && !execute_task_busy)
                        state <= RECOVER;

                RECOVER: begin
                    normal_next_pc <= pc;
                    state          <= READY;
                end

                default: state <= DRAIN;
            endcase

            if (cpu_stop || redirect) begin
                state              <= DRAIN;
                prediction_pending <= 1'b0;
                target_active      <= 1'b0;
                target_requested   <= 1'b0;
                target_complete    <= 1'b0;
                request_killed     <= 1'b1;
                if (cpu_stop)
                    wakeup <= 10'd0;
            end
        end
    end

`ifdef BRANCH_PREDICT_STATS
    // =====================================
    // Simulation counters
    // =====================================

    // 分岐確定時に計数する。途中で破棄された予測は含めない。
    // ENABLE_BRANCH_PREDICTだけではcounter回路を生成しない。
    integer prediction_count;
    integer prediction_hit;
    integer prediction_miss;
    integer flush_count;
    integer target_use;
    integer target_issued_early;
    integer target_ready_early;

    always @(posedge clock) begin
        if (!reset_n) begin
            prediction_count    <= 0;
            prediction_hit      <= 0;
            prediction_miss     <= 0;
            flush_count         <= 0;
            target_use          <= 0;
            target_issued_early <= 0;
            target_ready_early  <= 0;
        end else begin
            if (resolved) begin
                prediction_count <= prediction_count + 1;
                if (predicted_taken == resolve_taken &&
                    (!resolve_taken || resolve_target_match))
                    prediction_hit <= prediction_hit + 1;
                else
                    prediction_miss <= prediction_miss + 1;
            end
            if (redirect)
                flush_count <= flush_count + 1;
            if (promote) begin
                target_use <= target_use + 1;
                if (target_requested && state != LAUNCH)
                    target_issued_early <= target_issued_early + 1;
                if (target_valid)
                    target_ready_early <= target_ready_early + 1;
            end
        end
    end

    final $display("BRANCH_STATS count=%0d hit=%0d miss=%0d flush=%0d target_use=%0d issued_early=%0d ready_early=%0d",
                   prediction_count, prediction_hit, prediction_miss, flush_count,
                   target_use, target_issued_early, target_ready_early);
`endif

endmodule

// 連続する32bit命令列を保持するFIFO。
// PCは先頭分だけ保持し、popごとに+4する。
// flushではvalid情報を破棄し、命令データ自体はresetしない。
module PSC_PathFifo #(
    parameter int DEPTH = 16,
    parameter int BITS  = $clog2(DEPTH)
)(
    input  logic          clock,
    input  logic          reset_n,
    input  logic          flush,
    input  logic          push,
    input  logic          pop,
    input  logic [31:0]   data,
    input  logic [63:0]   pc,
    output logic          valid,
    output logic [31:0]   out_data,
    output logic [63:0]   out_pc,
    output logic [BITS:0] count
);

    logic [31:0]   words [0:DEPTH-1];
    logic [BITS-1:0] rd, wr;
    logic           put, take;

    assign valid    = count != 0;
    assign out_data = words[rd];
    assign put      = push && count < (BITS+1)'(DEPTH);
    assign take     = pop && valid;

    // =====================================
    // FIFO data
    // =====================================

    always_ff @(posedge clock) begin
        if (put && !flush)
            words[wr] <= data;
    end

    // =====================================
    // FIFO control / head PC
    // =====================================

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            rd     <= '0;
            wr     <= '0;
            count  <= '0;
            out_pc <= 64'd0;
        end else if (flush) begin
            rd    <= '0;
            wr    <= '0;
            count <= '0;
        end else begin
            if (put)
                wr <= wr == BITS'(DEPTH-1) ? '0 : wr + 1'b1;
            if (take)
                rd <= rd == BITS'(DEPTH-1) ? '0 : rd + 1'b1;

            case ({put, take})
                2'b10: count <= count + 1'b1;
                2'b01: count <= count - 1'b1;
                default: ;
            endcase

            if (put && !valid)
                out_pc <= pc;
            else if (take)
                out_pc <= out_pc + 64'd4;
        end
    end

endmodule
