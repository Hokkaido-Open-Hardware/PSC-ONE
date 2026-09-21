`timescale 1ns/1ps
module CoreTop #(parameter integer LANES=8)(
    input wire clock,reset_n,start,data_clear,signed_mode,
    input wire [127:0] data_A,data_B,
    output wire [511:0] ps_acc,
    output wire busy,done
);
    wire capture,issue,phase,mode,acc_clear;
    wire [1:0] group_index;
    wire [LANES-1:0] wb_valid;
    wire [LANES*4-1:0] wb_id;
    wire [LANES*32-1:0] wb_data;
    PSC_NPU_MACScheduler #(.LANES(LANES)) scheduler (
        .clock(clock),.reset_n(reset_n),.start(start),.data_clear(data_clear),
        .signed_mode(signed_mode),.capture(capture),.issue(issue),.phase(phase),
        .group_index(group_index),.signed_mode_latched(mode),.acc_clear(acc_clear),.busy(busy),.done(done));
    PSC_NPU_PotLanes #(.LANES(LANES)) lanes (
        .clock(clock),.reset_n(reset_n),.capture(capture),.issue(issue),.phase(phase),
        .group_index(group_index),.signed_mode(mode),.data_A(data_A),.data_B(data_B),
        .wb_valid(wb_valid),.wb_id(wb_id),.wb_data(wb_data));
    PSC_NPU_AccBank #(.LANES(LANES)) bank (
        .clock(clock),.reset_n(reset_n),.clear(acc_clear),.wb_valid(wb_valid),
        .wb_id(wb_id),.wb_data(wb_data),.ps_acc(ps_acc));
endmodule
