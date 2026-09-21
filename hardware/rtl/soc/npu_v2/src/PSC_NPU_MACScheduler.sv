`timescale 1ns/1ps

// Sixteen contexts, two sequential terms per weight.
// E0 start; E2 capture; 32/LANES WB edges; drain; done E(4+32/LANES).
module PSC_NPU_MACScheduler #(parameter integer LANES = 8) (
    input  wire       clock,
    input  wire       reset_n,
    input  wire       start,
    input  wire       data_clear,
    input  wire       signed_mode,
    output wire       capture,
    output wire       issue,
    output reg        phase,
    output reg  [1:0] group_index,
    output reg        signed_mode_latched,
    output wire       acc_clear,
    output wire       busy,
    output reg        done
);
    localparam [2:0] S_IDLE    = 3'd0,
                     S_ALIGN   = 3'd1,
                     S_CAPTURE = 3'd2,
                     S_ISSUE   = 3'd3,
                     S_DRAIN   = 3'd4,
                     S_FINISH  = 3'd5;
    reg [2:0] state;

    assign capture   = state == S_CAPTURE;
    assign issue     = state == S_ISSUE;
    assign acc_clear = state == S_IDLE && data_clear;
    assign busy      = state != S_IDLE;

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            state               <= S_IDLE;
            phase               <= 1'b0;
            group_index         <= 2'd0;
            signed_mode_latched <= 1'b0;
            done                <= 1'b0;
        end else begin
            done <= 1'b0;
            case (state)
                S_IDLE: begin
                    if (start && !data_clear)
                        state <= S_ALIGN;
                end
                S_ALIGN: state <= S_CAPTURE;
                S_CAPTURE: begin
                    // Match the former shared multiplier's batch capture,
                    // including mode changes between start and capture.
                    signed_mode_latched <= signed_mode;
                    group_index <= 2'd0;
                    phase <= 1'b0;
                    state <= S_ISSUE;
                end
                S_ISSUE: begin
                    phase <= ~phase;
                    if (phase) begin
                        if (group_index == (16/LANES)-1)
                            state <= S_DRAIN;
                        else
                            group_index <= group_index + 2'd1;
                    end
                end
                // The ACC bank consumes the last registered WB on this edge.
                S_DRAIN: state <= S_FINISH;
                // Done follows the final ACC update, with the same drain contract.
                S_FINISH: begin
                    done <= 1'b1;
                    state <= S_IDLE;
                end
                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
