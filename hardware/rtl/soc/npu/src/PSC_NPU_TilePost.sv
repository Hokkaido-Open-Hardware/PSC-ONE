`timescale 1ns/1ps

module PSC_NPU_TilePost (
    input  wire             clock,
    input  wire             reset_n,

    // Parameter load / INT8 output control
    input  wire             init_start,
    input  wire             output_start,
    input  wire [31:0]      base,
    input  wire [7:0]       rows,

    // Memory handshake
    input  wire             req_ready,
    input  wire             read_ready,
    input  wire             write_ready,
    input  wire [31:0]      read_data,

    output reg  [31:0]      read_addr,
    output reg              read_valid,
    output reg  [31:0]      write_addr,
    output reg  [31:0]      write_data,
    output reg              write_valid,

    // Accumulator select / initial value
    input  wire [31:0]      acc_data,
    output wire             seed_valid,
    output wire [3:0]       acc_index,
    output wire [31:0]      seed_data,

    output reg              done,
    output reg              error
);

    //======================================================
    // Parameter block / output buffer
    //
    // base +  0: initial[4]
    // base + 16: multiplier[4]
    // base + 32: shift[4]
    // base + 48: output zero-point, minimum, maximum, reserved
    // base + 64: INT8 output scratch, four allocated bytes per row
    //
    // チャネル端数も専用scratch内へ書き込む。
    // ソフトウェアは有効チャネルのみTensorへコピーする。
    //======================================================
    reg [31:0] params [0:15];
    reg [31:0] packed_word;
    reg [4:0]  index;

    //--------------------------------------------
    // Requantization signals
    //--------------------------------------------
    reg                    qstart;
    wire                   qdone;
    wire                   qbusy;
    wire signed [31:0]     qresult;

    // INT32加算は参照実装と同じ下位32bitを保持する。
    wire signed [31:0] offset_result = qresult + params[12];
    wire signed [31:0] clipped =
        (offset_result < $signed(params[13])) ? $signed(params[13]) :
        (offset_result > $signed(params[14])) ? $signed(params[14]) :
                                               offset_result;

    assign seed_valid = (state == S_SEED);
    assign acc_index  = index[3:0];
    assign seed_data  = params[{2'b00, index[1:0]}];

    //======================================================
    // Requantization instance
    //======================================================
    PSC_NPU_Requantize u_quant (
        .clock       (clock),
        .reset_n     (reset_n),
        .start       (qstart),
        .value       (acc_data),
        .multiplier  (params[4 + {2'b00, index[1:0]}]),
        .shift       (params[8 + {2'b00, index[1:0]}]),
        .busy        (qbusy),
        .done        (qdone),
        .result      (qresult)
    );

    //--------------------------------------------
    // FSM
    //--------------------------------------------
    localparam [3:0]
        S_IDLE       = 4'd0,
        S_READ_REQ   = 4'd1,
        S_READ_WAIT  = 4'd2,
        S_SEED       = 4'd3,
        S_Q_START    = 4'd4,
        S_Q_WAIT     = 4'd5,
        S_PACK       = 4'd6,
        S_WRITE_REQ  = 4'd7,
        S_WRITE_WAIT = 4'd8;

    reg [3:0] state;

    //--------------------------------------------
    // Main FSM
    //--------------------------------------------
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            state       <= S_IDLE;
            index       <= 5'd0;
            packed_word <= 32'd0;
            qstart      <= 1'b0;

            read_addr   <= 32'd0;
            read_valid  <= 1'b0;
            write_addr  <= 32'd0;
            write_data  <= 32'd0;
            write_valid <= 1'b0;

            done        <= 1'b0;
            error       <= 1'b0;
        end else begin
            // Default one-cycle pulses
            done        <= 1'b0;
            read_valid  <= 1'b0;
            write_valid <= 1'b0;
            qstart      <= 1'b0;

            case (state)
                //--------------------------------------------
                // FIRST loads parameters. LAST starts output.
                //--------------------------------------------
                S_IDLE: begin
                    if (init_start) begin
                        index     <= 5'd0;
                        error     <= 1'b0;
                        read_addr <= base;
                        state     <= S_READ_REQ;
                    end else if (output_start) begin
                        index       <= 5'd0;
                        packed_word <= 32'd0;
                        write_addr  <= base + 32'd64;
                        state       <= S_Q_START;
                    end
                end

                //--------------------------------------------
                // Read one parameter word.
                //--------------------------------------------
                S_READ_REQ: begin
                    if (req_ready) begin
                        read_valid <= 1'b1;
                        state      <= S_READ_WAIT;
                    end
                end

                S_READ_WAIT: begin
                    if (read_ready) begin
                        params[index[3:0]] <= read_data;

                        if ((index >= 8) && (index < 12)
                            && (($signed(read_data) < -31)
                                || ($signed(read_data) > 30)))
                            error <= 1'b1;

                        if ((index == 12)
                            && (($signed(read_data) < -128)
                                || ($signed(read_data) > 127)))
                            error <= 1'b1;

                        if (((index == 13) || (index == 14))
                            && (($signed(read_data) < -128)
                                || ($signed(read_data) > 127)))
                            error <= 1'b1;

                        if ((index == 14)
                            && ($signed(read_data) < $signed(params[13])))
                            error <= 1'b1;

                        if (index == 15) begin
                            index <= 5'd0;

                            if (error || (read_data != 0)) begin
                                error <= 1'b1;
                                done  <= 1'b1;
                                state <= S_IDLE;
                            end else begin
                                state <= S_SEED;
                            end
                        end else begin
                            index     <= index + 5'd1;
                            read_addr <= read_addr + 32'd4;
                            state     <= S_READ_REQ;
                        end
                    end
                end

                //--------------------------------------------
                // Initialize the existing sixteen accumulators.
                //--------------------------------------------
                S_SEED: begin
                    if (index == 15) begin
                        state <= S_IDLE;
                        done  <= 1'b1;
                    end else begin
                        index <= index + 5'd1;
                    end
                end

                //--------------------------------------------
                // Requantize one output element.
                //--------------------------------------------
                S_Q_START: begin
                    qstart <= 1'b1;
                    state  <= S_Q_WAIT;
                end

                S_Q_WAIT: begin
                    if (qdone) begin
                        packed_word[index[1:0]*8 +: 8] <= clipped[7:0];
                        state                         <= S_PACK;
                    end
                end

                //--------------------------------------------
                // Pack four INT8 channels into one word.
                //--------------------------------------------
                S_PACK: begin
                    if (index[1:0] == 3) begin
                        state <= S_WRITE_REQ;
                    end else begin
                        index <= index + 5'd1;
                        state <= S_Q_START;
                    end
                end

                //--------------------------------------------
                // Write one output row.
                //--------------------------------------------
                S_WRITE_REQ: begin
                    if (req_ready) begin
                        write_valid <= 1'b1;
                        write_data  <= packed_word;
                        state       <= S_WRITE_WAIT;
                    end
                end

                //--------------------------------------------
                // 最終書込みの応答を受けてからdoneを通知する。
                //--------------------------------------------
                S_WRITE_WAIT: begin
                    if (write_ready) begin
                        if (index[3:2] == rows[1:0] - 2'd1) begin
                            done  <= 1'b1;
                            state <= S_IDLE;
                        end else begin
                            index      <= index + 5'd1;
                            write_addr <= write_addr + 32'd4;
                            state      <= S_Q_START;
                        end
                    end
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule
