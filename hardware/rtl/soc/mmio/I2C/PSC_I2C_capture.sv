`timescale 1ns / 1ps
// Passive multi-transaction bus monitor. Inputs are already synchronized by the slave.
// 64 events, each {kind[2:0], nack, byte[7:0]}:
// 1 START, 2 repeated START, 3 STOP, 4 address byte, 5 data byte.
// arm clears the previous capture; abort freezes a partial capture.
// STOP count terminates capture; repeated START does not count as a STOP.
// Absolute clock budget also bounds idle/stuck buses. Both parameters must be >0.
module PSC_I2C_capture #(
    parameter integer TRANSACTION_LIMIT = 2,
    parameter integer TIMEOUT_CYCLES = 100000000
) (
    input wire clock, reset_n,
    input wire scl_rise, sda, start_event, stop_event,
    input wire arm, abort_capture, pop,
    output wire [31:0] status, count, data
);
    reg armed, active, done, overflow, aborted, timed_out, limit_reached;
    reg [31:0] elapsed, transactions;
    reg [6:0] used, rd_index;
    reg [11:0] events [0:63];
    reg [3:0] bits;
    reg [7:0] shift;
    reg address_byte;
    reg event_valid;
    reg [11:0] event_value;

    assign status = {16'd0, transactions[7:0], 1'b1, limit_reached,
                     timed_out, aborted, overflow, done, active, armed};
    assign count = {25'd0, used};
    assign data = (done && rd_index < used) ?
                  {20'd0, events[rd_index[5:0]]} : 32'd0;

    always @* begin
        event_valid = 1'b0;
        event_value = 12'd0;
        if (armed) begin
            if (start_event) begin
                event_valid = 1'b1;
                event_value = active ? 12'h400 : 12'h200;
            end else if (active && stop_event) begin
                event_valid = 1'b1;
                event_value = 12'h600;
            end else if (active && scl_rise && bits == 4'd8) begin
                event_valid = 1'b1;
                event_value = {address_byte ? 3'd4 : 3'd5, sda, shift};
            end
        end
    end

    // Memory is not reset; used/rd_index prevent access to stale entries.
    always @(posedge clock) begin
        if (reset_n && !arm && !abort_capture && event_valid && used < 7'd64)
            events[used[5:0]] <= event_value;
    end

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            armed <= 0; active <= 0; done <= 0;
            overflow <= 0; aborted <= 0; timed_out <= 0; limit_reached <= 0;
            elapsed <= 0; transactions <= 0;
            used <= 0; rd_index <= 0; bits <= 0; shift <= 0;
            address_byte <= 0;
        end else if (arm) begin
            armed <= 1; active <= 0; done <= 0;
            overflow <= 0; aborted <= 0; timed_out <= 0; limit_reached <= 0;
            elapsed <= 0; transactions <= 0;
            used <= 0; rd_index <= 0; bits <= 0; shift <= 0;
            address_byte <= 0;
        end else if (abort_capture && armed) begin
            armed <= 0; active <= 0; done <= 1; aborted <= 1;
        end else begin
            if (pop && done && rd_index < used) rd_index <= rd_index + 7'd1;
            if (armed) begin
                elapsed <= elapsed + 32'd1;
                if (start_event) begin
                    active <= 1; bits <= 0; shift <= 0; address_byte <= 1;
                end else if (active && stop_event) begin
                    active <= 0; bits <= 0;
                    transactions <= transactions + 32'd1;
                    if (transactions >= TRANSACTION_LIMIT - 1) begin
                        armed <= 0; done <= 1; limit_reached <= 1;
                    end
                end else if (active && scl_rise) begin
                    if (bits == 4'd8) begin
                        bits <= 0; address_byte <= 0;
                    end else begin
                        shift <= {shift[6:0], sda};
                        bits <= bits + 4'd1;
                    end
                end
                // Deadline applies even on an event cycle; retain that event.
                if (elapsed >= TIMEOUT_CYCLES - 1) begin
                    armed <= 0; active <= 0; done <= 1; timed_out <= 1;
                end
                if (event_valid) begin
                    if (used < 7'd64) used <= used + 7'd1;
                    if (used >= 7'd63) begin
                        armed <= 0; active <= 0; done <= 1; overflow <= 1;
                    end
                end
            end
        end
    end
endmodule
