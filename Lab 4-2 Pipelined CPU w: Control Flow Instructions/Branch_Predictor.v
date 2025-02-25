`include "opcodes.v"

module Branch_Predictor(input reset,
                  input clk,
                  input [31:0] current_pc,
                  input [31:0] ID_EX_PC,
                  input taken_or_not,
                  input is_taken,
                  input [31:0] target_addr,
                  input [4:0] ID_EX_BHSR,
                  output reg [4:0] BHSR,
                  output reg [31:0] predict_pc);

    integer i;

    wire [24:0] tag;
    wire [4:0] index;
    wire [24:0] _tag;
    wire [4:0] _index;
    reg [24:0] tag_table [0:31];
    reg [31:0] BTB [0:31];
    reg [1:0] PHT [0:31];

    assign tag = current_pc[31:7];
    assign index = current_pc[6:2];
    assign _tag = ID_EX_PC[31:7];
    assign _index = ID_EX_PC[6:2];

    always @(posedge clk) begin
        if (reset) begin
            for(i = 0; i < 32; i++) begin
                tag_table[i] <= {25{1'b1}};
                BTB[i] <= 32'b0;
                PHT[i] <= 2'b11;
            end
            BHSR <= 5'b0;
        end
        else begin
            if (taken_or_not) begin
                if (is_taken) begin
                    BTB[_index] <= target_addr;
                    tag_table[_index] <= _tag;
                    case (PHT[ID_EX_BHSR ^ _index]) 
                        2'b00 : PHT[ID_EX_BHSR ^ _index] <= 2'b01;
                        2'b01 : PHT[ID_EX_BHSR ^ _index] <= 2'b10;
                        2'b10 : PHT[ID_EX_BHSR ^ _index] <= 2'b11;
                        2'b11 : PHT[ID_EX_BHSR ^ _index] <= 2'b11;
                    endcase
                    BHSR <= {BHSR[3:0], 1'b1};
                end
                else begin
                    case (PHT[ID_EX_BHSR ^ _index]) 
                        2'b00 : PHT[ID_EX_BHSR ^ _index] <= 2'b00;
                        2'b01 : PHT[ID_EX_BHSR ^ _index] <= 2'b00;
                        2'b10 : PHT[ID_EX_BHSR ^ _index] <= 2'b01;
                        2'b11 : PHT[ID_EX_BHSR ^ _index] <= 2'b10;
                    endcase
                    BHSR <= {BHSR[3:0], 1'b0};
                end
            end
        end
    end

    always @(*) begin
        if ((tag_table[index] == tag) && ((PHT[BHSR ^ index] == 2'b11) || (PHT[BHSR ^ index] == 2'b10))) begin
            predict_pc = BTB[index];
        end 
        else begin
            predict_pc = current_pc + 4;
        end
    end
endmodule
