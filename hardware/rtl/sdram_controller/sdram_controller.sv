/*
NISHIHARU
*/
`timescale 1ns / 1ps

module sdram_controller #(
    parameter int CLK_FREQ_MHz           = 80,
    // SDRAM ADDR
    parameter int COL_ADDR_BUS_WIDTH     = 8,
    parameter int ROW_ADDR_BUS_WIDTH     = 11,
    parameter int BNK_ADDR_BUS_WIDTH     = 2,
    // DQ, DQM
    parameter int DQ_BUS_WIDTH           = 16,
    parameter int DQM_BUS_WIDTH          = 2,
    parameter int SD_ADDR_BUS_WIDTH      = 11,
    parameter int SDRAM_INIT_CNT         = (64 * CLK_FREQ_MHz) / 10, // 64us
    parameter int clk_dly_ps             = 1, // Reserved for FPGA IODELAY implementation
    parameter int timing_CAS             = 3,
    parameter int timing_RCD             = 2,
    parameter int timing_RTP             = 2,
    parameter int timing_WR              = 2,
    parameter int timing_RP              = 3,
    parameter int timing_MD              = 3,
    parameter int timing_RFC             = 8,
    // INNER Param
    parameter int CW                     = COL_ADDR_BUS_WIDTH,
    parameter int RW                     = ROW_ADDR_BUS_WIDTH,
    parameter int BW                     = BNK_ADDR_BUS_WIDTH,
    parameter int SDAW                   = SD_ADDR_BUS_WIDTH
)(
    input  logic                     clock,
    input  logic                     reset_n,
    input  logic [3:0]               rw_length, // 1,4,8
    output logic                     req_ready,
    output logic                     sdram_init_fin,
    // ==== READ要求（Bank/Row/Col 分離）====
    input  logic                     read_valid,
    output logic                     read_ready,
    input  logic [BW-1:0]            read_addr_ba,
    input  logic [RW-1:0]            read_addr_row,
    input  logic [CW-1:0]            read_addr_col,
    output logic [DQ_BUS_WIDTH-1:0]  read_data,
    // ==== WRITE要求（Bank/Row/Col 分離）====
    input  logic                     write_valid,
    output logic                     write_ready,
    input  logic [BW-1:0]            write_addr_ba,
    input  logic [RW-1:0]            write_addr_row,
    input  logic [CW-1:0]            write_addr_col,
    input  logic [DQ_BUS_WIDTH-1:0]  write_data,
    // ============ SDRAM IF ============
    output logic                     sdram_clk,
    output logic                     sdram_cs,
    output logic                     sdram_ras,
    output logic                     sdram_cas,
    output logic                     sdram_we,
    output logic [SDAW-1:0]          sdram_adr,
    output logic [BW-1:0]            sdram_ba,
    output logic [DQM_BUS_WIDTH-1:0] sdram_dqm,
    inout  wire  [DQ_BUS_WIDTH-1:0]  sdram_dq
);

    // One sequencer drives the registered SDRAM command/address pins during
    // both initialization and normal operation. WAIT resumes at wait_next;
    // loading N holds N+1 NOP cycles before the destination state executes.
    // Explicit one-hot decode keeps the shared-return sequencer off a wide
    // binary-state decoder (the variable WAIT return prevents FSM extraction).
    localparam int POWERUP     = 0;
    localparam int INIT_PRE    = 1;
    localparam int INIT_REF1   = 2;
    localparam int INIT_REF2   = 3;
    localparam int INIT_MODE   = 4;
    localparam int INIT_FINISH = 5;
    localparam int IDLE        = 6;
    localparam int ACTIVATE    = 7;
    localparam int TRANSFER    = 8;
    localparam int REFRESH_PRE = 9;
    localparam int DONE        = 10;
    localparam int REFRESH     = 11;
    localparam int WAIT        = 12;
    localparam int ACCESS      = 13;
    logic [13:0] state, wait_next;

    localparam int INIT_TRP_TWAIT  = 6;
    localparam int INIT_TRFC_TWAIT = 24;
    localparam int INIT_TMRD_TWAIT = 14;
    localparam int INIT_FIN_TWAIT  = 60;
    // Initialization needs the longest delay. Include runtime parameters so
    // changing a supported timing does not silently truncate the countdown.
    function automatic integer max_delay(input integer a, input integer b);
        max_delay = (a > b) ? a : b;
    endfunction
    // Physical minima from the GW2AR model (ns), rounded up to clocks.
    // Serializing ACTIVATE/PRECHARGE behind the most recent ACTIVATE also
    // protects every older open bank, without four per-bank age counters.
    localparam int ACT_GUARD = max_delay((60 * CLK_FREQ_MHz + 999) / 1000,
                              max_delay((42 * CLK_FREQ_MHz + 999) / 1000,
                                        (14 * CLK_FREQ_MHz + 999) / 1000));
    localparam int GUARD_WIDTH = (ACT_GUARD < 1) ? 1 : $clog2(ACT_GUARD + 1);
    localparam int WRITE_WAIT = max_delay(timing_WR, (14 * CLK_FREQ_MHz + 999) / 1000);
    localparam int MAX_DELAY = max_delay(SDRAM_INIT_CNT,
        max_delay(INIT_TMRD_TWAIT + INIT_FIN_TWAIT,
        max_delay(timing_CAS + timing_RTP + 1,
        max_delay(timing_RCD, max_delay(WRITE_WAIT,
        max_delay(timing_RP, max_delay(timing_MD, timing_RFC)))))));
    localparam int DELAY_WIDTH = (MAX_DELAY < 1) ? 1 : $clog2(MAX_DELAY + 1);
    logic [DELAY_WIDTH-1:0] delay_left;
    logic [GUARD_WIDTH-1:0] activate_guard;
    logic [(1<<BW)-1:0] bank_open;
    logic [RW-1:0] open_row [0:(1<<BW)-1];
    logic is_write;

    // Keep separate collection buffers: read priority can interrupt a partly
    // collected write (and vice versa across transactions/refresh). Sharing
    // these would change the existing request protocol.
    logic [BW-1:0] read_ba_buf, write_ba_buf;
    logic [RW-1:0] read_row_buf, write_row_buf;
    logic [CW-1:0] read_col_buf [0:7];
    logic [CW-1:0] write_col_buf [0:7];
    logic [DQ_BUS_WIDTH-1:0] write_data_buf [0:7];
    logic [3:0] read_count, write_count, rw_index;
    // Four-bit lexicographic compare avoids a carry chain in read-priority
    // arbitration followed by the write transaction's last-beat decision.
    function automatic logic count_below_length(input logic [3:0] count,
                                                input logic [3:0] length);
        count_below_length = (!count[3] && length[3]) ||
            ((count[3] == length[3]) && !count[2] && length[2]) ||
            ((count[3:2] == length[3:2]) &&
             ((!count[1] && length[1]) ||
              ((count[1] == length[1]) && !count[0] && length[0])));
    endfunction
    wire accept_read = state[IDLE] && !refresh_req &&
                       read_valid && count_below_length(read_count, rw_length);
    wire accept_write = state[IDLE] && !refresh_req && !accept_read &&
                        write_valid && count_below_length(write_count, rw_length);

    logic [DQ_BUS_WIDTH-1:0] dq_out, dq_in, dq_d1;
    // Read capture counter. Keep the FPGA-validated window used by the stable version.
    logic [4:0] read_cnt;
    localparam int REF_COUNT = (71 * CLK_FREQ_MHz) / 10;
    logic [11:0] ref_timer;
    logic refresh_req;

    wire [BW-1:0] access_bank = is_write ? write_ba_buf : read_ba_buf;
    wire [RW-1:0] access_row = is_write ? write_row_buf : read_row_buf;
    wire row_hit = bank_open[access_bank] && open_row[access_bank] == access_row;
    wire access_go = state[ACCESS] && (row_hit || activate_guard == 0);
    wire activate_cmd = state[ACTIVATE] || (access_go && !bank_open[access_bank]);

    assign sdram_clk = clock;
    assign sdram_cs = 1'b0;
    assign sdram_dqm = {DQM_BUS_WIDTH{!sdram_init_fin}};
    // write_ready and the DQ output enable have the same lifetime: precisely
    // the registered WRITE beats, including the final beat before the NOP.
    assign sdram_dq = write_ready ? dq_out : {DQ_BUS_WIDTH{1'bz}};
    assign req_ready = sdram_init_fin && (state[IDLE] || state[DONE]) &&
                       !(ref_timer > REF_COUNT - 10);

    // Buffers intentionally have no reset, just as in the reference design.
    // Keep their writes in a clock-only process so synthesis can infer small
    // distributed RAMs instead of adding an enable mux to every data bit.
    always_ff @(posedge clock) begin
        if (reset_n && accept_read) begin
            if (read_count == 4'd0) begin
                read_ba_buf <= read_addr_ba;
                read_row_buf <= read_addr_row;
            end
            read_col_buf[read_count] <= read_addr_col;
        end
        if (reset_n && accept_write) begin
            if (write_count == 4'd0) begin
                write_ba_buf <= write_addr_ba;
                write_row_buf <= write_addr_row;
            end
            write_col_buf[write_count] <= write_addr_col;
            write_data_buf[write_count] <= write_data;
        end
        if (reset_n && activate_cmd)
            open_row[access_bank] <= access_row;
    end
    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            read_count <= 4'd0;
            write_count <= 4'd0;
        end else begin
            if (accept_read)
                read_count <= read_count + 4'd1;
            if (accept_write)
                write_count <= write_count + 4'd1;
            if (state[DONE]) begin
                if (is_write)
                    write_count <= 4'd0;
                else
                    read_count <= 4'd0;
            end
        end
    end

    // Separate one-hot next-state equations avoid a global state-register
    // clock enable whose cone would include every request and timing test.
    wire wait_done = state[WAIT] && delay_left == 0;
    wire start_read = state[IDLE] && !refresh_req && read_valid &&
                      rw_length != 0 && read_count == rw_length - 4'd1;
    wire start_write = state[IDLE] && !refresh_req && !accept_read && write_valid &&
                       rw_length != 0 && write_count == rw_length - 4'd1;
    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            state <= 14'b1 << POWERUP;
        end else begin
            state[POWERUP] <= state[POWERUP] && delay_left != 0;
            state[INIT_PRE] <= state[POWERUP] && delay_left == 0;
            state[INIT_REF1] <= wait_done && wait_next[INIT_REF1];
            state[INIT_REF2] <= wait_done && wait_next[INIT_REF2];
            state[INIT_MODE] <= wait_done && wait_next[INIT_MODE];
            state[INIT_FINISH] <= wait_done && wait_next[INIT_FINISH];
            state[IDLE] <= state[INIT_FINISH] || state[DONE] ||
                           (wait_done && wait_next[IDLE]) ||
                           (state[IDLE] && !refresh_req && !start_read && !start_write);
            state[ACCESS] <= start_read || start_write || (state[ACCESS] && !access_go);
            state[ACTIVATE] <= wait_done && wait_next[ACTIVATE];
            state[TRANSFER] <= (wait_done && wait_next[TRANSFER]) ||
                               (access_go && row_hit) ||
                               (state[TRANSFER] && rw_index != rw_length);
            state[DONE] <= wait_done && wait_next[DONE];
            state[REFRESH_PRE] <= (state[IDLE] && refresh_req && |bank_open) ||
                                 (state[REFRESH_PRE] && activate_guard != 0);
            state[REFRESH] <= wait_done && wait_next[REFRESH];
            state[WAIT] <= state[INIT_PRE] || state[INIT_REF1] || state[INIT_REF2] ||
                           state[INIT_MODE] || state[ACTIVATE] || state[REFRESH] ||
                           (state[IDLE] && refresh_req && !(|bank_open)) ||
                           (access_go && !row_hit) ||
                           (state[TRANSFER] && rw_index == rw_length) ||
                           (state[REFRESH_PRE] && activate_guard == 0) ||
                           (state[WAIT] && !wait_done);
        end
    end

    // Common countdown and return destination. N means N+1 waiting clocks;
    // the read drain combines the original CAS+1 and RTP+1 waiting periods.
    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            wait_next <= 14'b1 << IDLE;
            delay_left <= DELAY_WIDTH'(SDRAM_INIT_CNT);
            is_write <= 1'b0;
            rw_index <= 4'd0;
            sdram_init_fin <= 1'b0;
        end else begin
            if ((state[POWERUP] || state[WAIT]) && delay_left != 0)
                delay_left <= delay_left - 1'b1;
            if (state[INIT_FINISH])
                sdram_init_fin <= 1'b1;
            if (start_read || start_write) begin
                is_write <= start_write;
                rw_index <= 4'd0;
            end else if (state[TRANSFER] && rw_index != rw_length) begin
                rw_index <= rw_index + 4'd1;
            end
            // State is one-hot after reset and every transition above.
            case (1'b1)
                state[INIT_PRE]: begin
                    delay_left <= DELAY_WIDTH'(INIT_TRP_TWAIT - 1);
                    wait_next <= 14'b1 << INIT_REF1;
                end
                state[INIT_REF1]: begin
                    delay_left <= DELAY_WIDTH'(INIT_TRFC_TWAIT - 1);
                    wait_next <= 14'b1 << INIT_REF2;
                end
                state[INIT_REF2]: begin
                    delay_left <= DELAY_WIDTH'(INIT_TRFC_TWAIT - 1);
                    wait_next <= 14'b1 << INIT_MODE;
                end
                state[INIT_MODE]: begin
                    delay_left <= DELAY_WIDTH'(INIT_TMRD_TWAIT + INIT_FIN_TWAIT - 1);
                    wait_next <= 14'b1 << INIT_FINISH;
                end
                state[IDLE]: begin
                    if (refresh_req && !(|bank_open)) begin
                        delay_left <= DELAY_WIDTH'(timing_MD);
                        wait_next <= 14'b1 << REFRESH;
                    end
                end
                state[ACCESS]: begin
                    if (access_go && !row_hit) begin
                        delay_left <= bank_open[access_bank] ? DELAY_WIDTH'(timing_RP) :
                                                             DELAY_WIDTH'(timing_RCD);
                        wait_next <= bank_open[access_bank] ? (14'b1 << ACTIVATE) :
                                                            (14'b1 << TRANSFER);
                    end
                end
                state[ACTIVATE]: begin
                    delay_left <= DELAY_WIDTH'(timing_RCD);
                    wait_next <= 14'b1 << TRANSFER;
                end
                state[TRANSFER]: begin
                    if (rw_index == rw_length) begin
                        delay_left <= is_write ? DELAY_WIDTH'(WRITE_WAIT) :
                                      DELAY_WIDTH'(timing_CAS + timing_RTP + 1);
                        wait_next <= 14'b1 << DONE;
                    end
                end
                state[REFRESH_PRE]: begin
                    if (activate_guard == 0) begin
                        delay_left <= DELAY_WIDTH'(max_delay(timing_RP, timing_MD));
                        wait_next <= 14'b1 << REFRESH;
                    end
                end
                state[REFRESH]: begin
                    delay_left <= DELAY_WIDTH'(timing_RFC);
                    wait_next <= 14'b1 << IDLE;
                end
                default: begin end
            endcase
        end
    end

    // Registered command/datapath: small state decode and a two-way direction
    // select. Address and bank hold their values during NOPs, as before.
    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            {sdram_ras, sdram_cas, sdram_we} <= 3'b111;
            sdram_adr <= '0;
            sdram_ba <= '0;
            write_ready <= 1'b0;
            dq_out <= '0;
        end else begin
            {sdram_ras, sdram_cas, sdram_we} <= 3'b111;
            write_ready <= 1'b0;
            case (1'b1)
                state[INIT_PRE]: begin
                    {sdram_ras, sdram_cas, sdram_we} <= 3'b010;
                    sdram_adr <= SDAW'(11'h400);
                end
                state[INIT_REF1], state[INIT_REF2], state[REFRESH]:
                    {sdram_ras, sdram_cas, sdram_we} <= 3'b001;
                state[INIT_MODE]: begin
                    {sdram_ras, sdram_cas, sdram_we} <= 3'b000;
                    sdram_adr <= SDAW'(11'h130);
                end
                // The old initialization/normal mux selected the normal
                // address reset value on this exact completion edge.
                state[INIT_FINISH]: sdram_adr <= '0;
                state[ACCESS]: begin
                    if (access_go) begin
                        sdram_ba <= access_bank;
                        if (row_hit) begin
                            // NOP: this bank already has the requested row.
                        end else if (bank_open[access_bank]) begin
                            {sdram_ras, sdram_cas, sdram_we} <= 3'b010;
                            sdram_adr <= '0; // PRECHARGE this bank only
                        end else begin
                            {sdram_ras, sdram_cas, sdram_we} <= 3'b011;
                            sdram_adr <= access_row;
                        end
                    end
                end
                state[ACTIVATE]: begin
                    {sdram_ras, sdram_cas, sdram_we} <= 3'b011;
                    sdram_adr <= access_row;
                    sdram_ba <= access_bank;
                end
                state[TRANSFER]: begin
                    if (rw_index != rw_length) begin
                        {sdram_ras, sdram_cas, sdram_we} <= {2'b10, !is_write};
                        sdram_adr <= '0;
                        sdram_adr[CW-1:0] <= is_write ? write_col_buf[rw_index] :
                                                                     read_col_buf[rw_index];
                        sdram_adr[10] <= 1'b0; // Auto Precharge OFF
                        if (is_write) begin
                            dq_out <= write_data_buf[rw_index];
                            write_ready <= 1'b1;
                        end
                    end
                end
                state[REFRESH_PRE]: begin
                    if (activate_guard == 0) begin
                        {sdram_ras, sdram_cas, sdram_we} <= 3'b010;
                        sdram_adr <= SDAW'(11'h400); // PRECHARGE ALL before refresh
                    end
                end
                default: begin end
            endcase
        end
    end

    // Open-page tracking changes on exactly the command-register edge.
    // Uninitialized row tags are never consulted while bank_open is clear.
    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            bank_open <= '0;
            activate_guard <= '0;
        end else begin
            if (activate_guard != 0)
                activate_guard <= activate_guard - 1'b1;
            if (activate_cmd) begin
                bank_open[access_bank] <= 1'b1;
                activate_guard <= GUARD_WIDTH'(ACT_GUARD);
            end else if (access_go && !row_hit) begin
                bank_open[access_bank] <= 1'b0;
            end else if (state[REFRESH_PRE] && activate_guard == 0) begin
                bank_open <= '0;
            end
        end
    end

    // Preserve the two sampling flops and the FPGA-validated read window.
    // TRANSFER and its drain WAIT preserve the complete read window. DONE
    // retains the final capture cycle formerly provided by READ_PRECHARGE.
    always_ff @(posedge clock) begin
        dq_in <= sdram_dq;
        dq_d1 <= dq_in;
    end
    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            read_cnt <= 5'd0;
            read_ready <= 1'b0;
            read_data <= '0;
        end else if (state[IDLE]) begin
            read_cnt <= 5'd0;
            read_ready <= 1'b0;
        end else if (!is_write && (state[TRANSFER] || state[DONE] ||
                     (state[WAIT] && wait_next[DONE]))) begin
            read_cnt <= read_cnt + 5'd1;
            // Keep the FPGA-validated capture window from the stable version.
            if (read_cnt > timing_CAS + 5'd2 &&
                read_cnt < {1'b0, rw_length} + 5'd6) begin
                read_ready <= 1'b1;
                read_data <= dq_d1;
            end else begin
                read_ready <= 1'b0;
            end
        end
    end

    // Preserve the 12-bit timer, pre-refresh ready guard, and sticky request.
    // Acknowledge in the pre-refresh WAIT. If rows are open, PRECHARGE ALL
    // precedes this wait; both tRP and the original timing_MD are respected.
    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            ref_timer <= 12'd0;
            refresh_req <= 1'b0;
        end else if (sdram_init_fin) begin
            ref_timer <= ref_timer + 12'd1;
            if (ref_timer >= REF_COUNT) begin
                refresh_req <= 1'b1;
                if (state[WAIT] && wait_next[REFRESH]) begin
                    ref_timer <= 12'd0;
                    refresh_req <= 1'b0;
                end
            end
        end
    end

    `ifdef COCOTB_SIM
    always @(posedge clock) begin
        if (reset_n && sdram_init_fin && state[TRANSFER])
            assert (rw_length == 4'd1 || rw_length == 4'd4 || rw_length == 4'd8);
    end
    `endif
endmodule