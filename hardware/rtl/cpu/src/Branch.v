// nishiharu

module Branch(
    input wire              clock,
    input wire              reset_n,
    input wire              branch_enb,
    input wire              is_load_store,
    input wire [2:0]        funct3,
    input wire [31:0]       r_data1,
    input wire [31:0]       r_data2,
    input wire [1:0]        pc_sel,
    input wire [31:0]       in_pc,
    input wire [31:0]       d_paddr,
    // memory
    output wire [31:0]      data_mem_read_address,
    output reg              data_mem_read_valid,
    input wire              data_mem_req_ready,
    input wire              data_mem_read_ready,
    // output 
    output reg              pc_sel2,
    // pc
    output reg  [31:0]      out_pc,
    output reg              branch_done
);

    assign  data_mem_read_address = d_paddr;
    
    function BRANCH_EXEC(
        input [2:0] branch_op,
        input [31:0] data1,
        input [31:0] data2,
        input [1:0] pc_sel
    );
        case (pc_sel)
            2'b00: // PC + 4
                BRANCH_EXEC = 1'b0;
            2'b01: begin // BRANCH
                case (branch_op)
                    3'b000: // BEQ
                        BRANCH_EXEC = (data1 == data2) ? 1'b1 : 1'b0;
                    3'b001: // BNE
                        BRANCH_EXEC = (data1 != data2) ? 1'b1 : 1'b0;
                    3'b100: // BLT (SIGNED)
                        BRANCH_EXEC = ($signed(data1) < $signed(data2)) ? 1'b1 : 1'b0;
                    3'b101: // BGE (SIGNED)
                        BRANCH_EXEC = ($signed(data1) >= $signed(data2)) ? 1'b1 : 1'b0;
                    3'b110: // BLTU (UNSIGNED)
                        BRANCH_EXEC = (data1 < data2) ? 1'b1 : 1'b0;
                    3'b111: // BGEU (UNSIGNED)
                        BRANCH_EXEC = (data1 >= data2) ? 1'b1 : 1'b0;
                    default: // ILLEGAL
                        BRANCH_EXEC = 1'b0;
                endcase
            end
            2'b10: // JAL / JALR
                BRANCH_EXEC = 1'b1;
            default: // ILLEGAL
                BRANCH_EXEC = 1'b0;
        endcase
    endfunction

    localparam IDLE             = 4'd0;
    localparam BRANCH           = 4'd1;
    localparam BRANCH_WAIT      = 4'd2;
    localparam BRANCH_DONE      = 4'd3;
    localparam BRANCH_DONE_WAIT = 4'd4;

    reg [3:0]  state;

    always @(posedge clock or negedge reset_n) begin
        if(!reset_n) begin
            state               <= 4'd0;
            pc_sel2             <= 1'b0;
            out_pc              <= 32'h0;
            data_mem_read_valid <= 1'b0;
            branch_done         <= 1'b0;
        end else begin
            // default
            data_mem_read_valid <= 1'b0;
            branch_done         <= 1'b0;

            case (state)
                IDLE: begin
                    // メモリREADあり
                    if (branch_enb) begin
                        if (is_load_store)      // casheバグ対応の名残
                            state <= BRANCH;
                        else
                            state <= BRANCH_DONE;
                    end
                    // メモリアクセスなし
                    pc_sel2     <= BRANCH_EXEC(funct3, r_data1, r_data2, pc_sel);
                    out_pc      <= in_pc;
                end
                BRANCH: begin
                    if (data_mem_req_ready) begin
                        data_mem_read_valid <= 1'b1;
                        state <= BRANCH_WAIT;
                    end
                end
                BRANCH_WAIT: begin
                    if (data_mem_read_ready)
                        state <= BRANCH_DONE;
                end
                BRANCH_DONE: begin
                    branch_done <= 1'b1;
                    state <= BRANCH_DONE_WAIT;
                end
                BRANCH_DONE_WAIT: begin
                    state <= IDLE;
                end
                default: begin
                    data_mem_read_valid <= 1'b0;
                end
            endcase
        end
    end

endmodule