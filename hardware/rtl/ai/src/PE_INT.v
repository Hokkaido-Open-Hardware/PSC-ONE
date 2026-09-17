`timescale 1ns/1ps

module PE_INT #(
    parameter integer DW       = 8,
    parameter integer PW       = 32,
    parameter integer SW       = 32,
    parameter integer THREADS  = 4
)(
    input  wire                         clock,
    input  wire                         reset_n,

    input  wire                         data_clear,
    input  wire                         start,
    input  wire                         en_b_shift_bottom,
    input  wire                         en_shift_right,

    input  wire [THREADS*DW-1:0]        b_in,
    input  wire [THREADS*DW-1:0]        a_in,

    output reg  [THREADS-1:0]           data_out_valid,
    input  wire [THREADS-1:0]           data_in_ready,

    output reg  [THREADS*DW-1:0]        data_A,
    output reg  [THREADS*DW-1:0]        data_B,
    input  wire [THREADS*PW-1:0]        result_C,

    output reg                          busy,
    output reg                          done,

    output wire [THREADS*DW-1:0]        a_shift_to_right,
    output wire [THREADS*DW-1:0]        b_shift_to_bottom,
    output reg  [THREADS*SW-1:0]        ps_acc
);

    localparam [THREADS-1:0] ALL_THREADS = {THREADS{1'b1}};

    localparam [2:0]
        S_INIT        = 3'd0,
        S_MUL         = 3'd1,
        S_MUL_WAIT    = 3'd2,
        S_PARTIAL_SUM = 3'd3;

    reg [2:0] state;

    reg [THREADS-1:0]    mul_done;
    reg [THREADS*PW-1:0] product;

    wire [THREADS-1:0] mul_complete_next;
    wire               all_mul_done;

    integer i;

    assign a_shift_to_right  = data_A;
    assign b_shift_to_bottom = data_B;

    assign mul_complete_next = mul_done | data_in_ready;
    assign all_mul_done      = (mul_complete_next == ALL_THREADS);

    /*
     * A shift registers
     */
    always @(posedge clock or negedge reset_n) begin
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
    always @(posedge clock or negedge reset_n) begin
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
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            state          <= S_INIT;
            mul_done       <= {THREADS{1'b0}};
            data_out_valid <= {THREADS{1'b0}};

            product        <= {(THREADS*PW){1'b0}};
            ps_acc         <= {(THREADS*SW){1'b0}};

            busy           <= 1'b0;
            done           <= 1'b0;

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
                        busy  <= 1'b1;
                        state <= S_MUL;
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
                        if (data_in_ready[i] && !mul_done[i]) begin
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
                        ps_acc[i*SW +: SW]
                            <= ps_acc[i*SW +: SW]
                             + {{(SW-PW){1'b0}},
                                product[i*PW +: PW]};
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