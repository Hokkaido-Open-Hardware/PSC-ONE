`timescale 1ns/1ps

module PSC_PFE #(
    parameter ADDR_WIDTH        = 32,
    parameter QUBO_NUM_VARS     = 8,
    parameter PFE_IF_DATA       = 32'h1000_8000,
    parameter PFE_IF_CTRL       = 32'h1000_8004
)(
    input  wire        clock,
    input  wire        reset_n,

    input  wire        cpu_rvalid,
    input  wire [31:0] cpu_raddr,
    output reg  [31:0] cpu_rdata,
    output reg         cpu_rready,

    input  wire        cpu_wvalid,
    input  wire [31:0] cpu_waddr,
    input  wire [31:0] cpu_wdata,
    output reg         cpu_wready
);

    localparam CMD_START     = 3'd1;
    localparam CMD_CLEAR     = 3'd2;
    localparam CMD_WRITE_Q   = 3'd3;
    localparam CMD_WRITE_X   = 3'd4;

    localparam READ_ENERGY   = 4'd1;
    localparam READ_STATUS   = 4'd2;
    localparam READ_CUR_X    = 4'd3;

    localparam ST_IDLE       = 4'd0;
    localparam ST_READ_Q     = 4'd1;
    localparam ST_WAIT_Q     = 4'd2;
    localparam ST_CALC       = 4'd3;
    localparam ST_DONE       = 4'd4;

    localparam QMEM_DEPTH    = QUBO_NUM_VARS * QUBO_NUM_VARS;
    localparam QMEM_AW       = $clog2(QMEM_DEPTH);

    reg [3:0] state;

    reg signed [7:0] qmem [0:QMEM_DEPTH-1];

    reg [31:0] data_reg;
    reg [3:0]  read_sel;

    reg [QUBO_NUM_VARS-1:0] cur_x;
    reg signed [63:0] cur_energy;

    reg [$clog2(QUBO_NUM_VARS)-1:0] i_idx;
    reg [$clog2(QUBO_NUM_VARS)-1:0] j_idx;

    reg [QMEM_AW-1:0] q_addr;
    reg signed [7:0]  q_val_reg;

    wire cur_bit_i = cur_x[i_idx];
    wire cur_bit_j = cur_x[j_idx];

    // ---------------- QMEM : single driver for BSRAM inference ----------------
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            q_val_reg  <= 8'sd0;
        end else begin
            q_val_reg <= qmem[q_addr];

            if (cpu_wvalid &&
                cpu_waddr == PFE_IF_CTRL &&
                cpu_wdata[2:0] == CMD_WRITE_Q) begin
                qmem[cpu_wdata[15:8]] <= data_reg[7:0];
            end
        end
    end

    // ---------------- CPU IF ----------------
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            cpu_rdata  <= 32'd0;
            cpu_rready <= 1'b0;
            cpu_wready <= 1'b0;
            data_reg   <= 32'd0;
            read_sel   <= READ_ENERGY;
        end else begin
            cpu_rready <= 1'b0;
            cpu_wready <= 1'b0;

            if (cpu_wvalid) begin
                if (cpu_waddr == PFE_IF_DATA) begin
                    cpu_wready <= 1'b1;
                    data_reg   <= cpu_wdata;
                end else if (cpu_waddr == PFE_IF_CTRL) begin
                    cpu_wready <= 1'b1;
                    read_sel   <= cpu_wdata[19:16];
                end
            end

            if (cpu_rvalid) begin
                if (cpu_raddr == PFE_IF_DATA) begin
                    cpu_rready <= 1'b1;

                    case (read_sel)
                        READ_ENERGY: begin
                            cpu_rdata <= cur_energy[31:0];
                        end

                        READ_STATUS: begin
                            cpu_rdata <= {
                                30'd0,
                                state == ST_DONE,
                                state != ST_IDLE && state != ST_DONE
                            };
                        end

                        READ_CUR_X: begin
                            cpu_rdata <= {{(32-QUBO_NUM_VARS){1'b0}}, cur_x};
                        end

                        default: begin
                            cpu_rdata <= 32'd0;
                        end
                    endcase

                end else if (cpu_raddr == PFE_IF_CTRL) begin
                    cpu_rready <= 1'b1;
                    cpu_rdata  <= {
                        30'd0,
                        state == ST_DONE,
                        state != ST_IDLE && state != ST_DONE
                    };
                end else begin
                    cpu_rdata  <= 32'd0;
                end
            end
        end
    end

    // ---------------- QUBO Engine ----------------
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            state      <= ST_IDLE;
            cur_x      <= {QUBO_NUM_VARS{1'b0}};
            cur_energy <= 64'sd0;
            i_idx      <= 0;
            j_idx      <= 0;
            q_addr     <= 0;
        end else begin

            if (cpu_wvalid && cpu_waddr == PFE_IF_CTRL) begin
                case (cpu_wdata[2:0])
                    CMD_CLEAR: begin
                        state      <= ST_IDLE;
                        cur_x      <= {QUBO_NUM_VARS{1'b0}};
                        cur_energy <= 64'sd0;
                        i_idx      <= 0;
                        j_idx      <= 0;
                        q_addr     <= 0;
                    end

                    CMD_WRITE_X: begin
                        state      <= ST_IDLE;
                        cur_x      <= cpu_wdata[QUBO_NUM_VARS+7:8];
                        cur_energy <= 64'sd0;
                        i_idx      <= 0;
                        j_idx      <= 0;
                        q_addr     <= 0;
                    end

                    CMD_START: begin
                        state      <= ST_READ_Q;
                        cur_energy <= 64'sd0;
                        i_idx      <= 0;
                        j_idx      <= 0;
                        q_addr     <= 0;
                    end

                    default: begin
                    end
                endcase

            end else begin
                case (state)
                    ST_IDLE: begin
                    end

                    ST_READ_Q: begin
                        q_addr <= i_idx * QUBO_NUM_VARS + j_idx;
                        state  <= ST_WAIT_Q;
                    end

                    ST_WAIT_Q: begin
                        // qmem[q_addr] が q_val_reg に入るのを1クロック待つ
                        state <= ST_CALC;
                    end

                    ST_CALC: begin
                        if (cur_bit_i && cur_bit_j) begin
                            cur_energy <= cur_energy + {{56{q_val_reg[7]}}, q_val_reg};
                        end

                        if (j_idx == QUBO_NUM_VARS-1) begin
                            j_idx <= 0;

                            if (i_idx == QUBO_NUM_VARS-1) begin
                                i_idx <= 0;
                                state <= ST_DONE;
                            end else begin
                                i_idx <= i_idx + 1'b1;
                                state <= ST_READ_Q;
                            end
                        end else begin
                            j_idx <= j_idx + 1'b1;
                            state <= ST_READ_Q;
                        end
                    end

                    ST_DONE: begin
                    end

                    default: begin
                        state <= ST_IDLE;
                    end
                endcase
            end
        end
    end

endmodule