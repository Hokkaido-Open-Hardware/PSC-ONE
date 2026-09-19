`timescale 1ns/1ps

module PSC_NPU_PE_INT #(
    parameter int DW       = 8,
    parameter int PW       = 32,
    parameter int SW       = 32,
    parameter int THREADS  = 4,
    // Set only when result_C retains every completed lane until the
    // next batch, as PSC_NPU_PE_Mult does. Standalone handshake users
    // keep the default capture registers.
    parameter int RESULT_HELD = 0
)(
    input  logic                         clock,
    input  logic                         reset_n,
    input  logic                         signed_mode,

    input  logic                         data_clear,
    input  logic                         start,
    input  logic                         en_b_shift_bottom,
    input  logic                         en_shift_right,

    input  logic [THREADS*DW-1:0]        b_in,
    input  logic [THREADS*DW-1:0]        a_in,

    output logic [THREADS-1:0]           data_out_valid,
    input  logic [THREADS-1:0]           data_in_ready,

    output logic [THREADS*DW-1:0]        data_A,
    output logic [THREADS*DW-1:0]        data_B,
    input  logic [THREADS*PW-1:0]        result_C,

    output logic                         busy,
    output logic                         done,

    output logic [THREADS*DW-1:0]        a_shift_to_right,
    output logic [THREADS*DW-1:0]        b_shift_to_bottom,
    output logic [THREADS*SW-1:0]        ps_acc
);

    localparam logic [THREADS-1:0] ALL_THREADS = {THREADS{1'b1}};

    localparam logic [2:0]
        S_INIT        = 3'd0,
        S_MUL         = 3'd1,
        S_MUL_WAIT    = 3'd2,
        S_PARTIAL_SUM = 3'd3;

    logic [2:0] state;

    logic [THREADS-1:0]    mul_done;
    logic [THREADS*PW-1:0] product;
    wire [THREADS*PW-1:0] accumulate_product =
        RESULT_HELD ? result_C : product;

    logic [THREADS-1:0] mul_complete_next;
    logic               all_mul_done;
    logic               signed_mode_latch;

    integer i;

    assign a_shift_to_right  = data_A;
    assign b_shift_to_bottom = data_B;

    assign mul_complete_next = mul_done | data_in_ready;
    assign all_mul_done      = (mul_complete_next == ALL_THREADS);

    /*
     * A shift registers
     */
    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            data_A <= {(THREADS*DW){1'b0}};
        end else if (data_clear) begin
            data_A <= {(THREADS*DW){1'b0}};
        end else if (en_shift_right) begin
            data_A <= a_in;
        end
    end

    /*
     * B shift registers
     */
    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            data_B <= {(THREADS*DW){1'b0}};
        end else if (data_clear) begin
            data_B <= {(THREADS*DW){1'b0}};
        end else if (en_b_shift_bottom) begin
            data_B <= b_in;
        end
    end

    /*
     * Shared state machine
     */
    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            state          <= S_INIT;
            mul_done       <= {THREADS{1'b0}};
            data_out_valid <= {THREADS{1'b0}};

            product        <= {(THREADS*PW){1'b0}};
            ps_acc         <= {(THREADS*SW){1'b0}};

            busy                <= 1'b0;
            done                <= 1'b0;
            signed_mode_latch   <= 1'b0;

        end else begin
            done <= 1'b0;

            case (state)

                S_INIT: begin
                    data_out_valid <= {THREADS{1'b0}};
                    mul_done       <= {THREADS{1'b0}};
                    busy           <= 1'b0;

                    if (data_clear) begin
                        product       <= {(THREADS*PW){1'b0}};
                        ps_acc        <= {(THREADS*SW){1'b0}};

                    end else if (start) begin
                        busy                <= 1'b1;
                        signed_mode_latch   <= signed_mode;
                        state               <= S_MUL;
                    end
                end

                S_MUL: begin
                    data_out_valid <= ALL_THREADS;
                    mul_done       <= {THREADS{1'b0}};
                    state          <= S_MUL_WAIT;
                end

                S_MUL_WAIT: begin
                    data_out_valid <= ALL_THREADS & ~mul_complete_next;

                    for (i = 0; i < THREADS; i = i + 1) begin
                        if (!RESULT_HELD && data_in_ready[i] && !mul_done[i]) begin
                            product[i*PW +: PW]
                                <= result_C[i*PW +: PW];
                        end
                    end

                    mul_done <= mul_complete_next;

                    if (all_mul_done) begin
                        data_out_valid <= {THREADS{1'b0}};
                        state          <= S_PARTIAL_SUM;
                    end
                end

                S_PARTIAL_SUM: begin
                    for (i = 0; i < THREADS; i = i + 1) begin
                        if (signed_mode_latch) begin
                            ps_acc[i*SW +: SW]
                                <= ps_acc[i*SW +: SW]
                                 + {{(SW-PW){accumulate_product[i*PW + PW - 1]}},
                                    accumulate_product[i*PW +: PW]};
                        end else begin
                            ps_acc[i*SW +: SW]
                                <= ps_acc[i*SW +: SW]
                                 + {{(SW-PW){1'b0}},
                                    accumulate_product[i*PW +: PW]};
                        end
                    end

                    busy  <= 1'b0;
                    done  <= 1'b1;
                    state <= S_INIT;
                end

                default: begin
                    state          <= S_INIT;
                    data_out_valid <= {THREADS{1'b0}};
                    mul_done       <= {THREADS{1'b0}};
                    busy           <= 1'b0;
                end

            endcase
        end
    end

endmodule