`include "opcodes.v"

module ALUControlUnit(input sub_or_not,
                      input [2:0] funct3,
                      input [1:0] ALUOp,
                      input [6:0] opcode,
                      output reg [3:0] alu_select);

    always @(*) begin
        alu_select = 4'b1111;

        if (ALUOp == 2'b10) begin
            if (funct3 == `FUNCT3_ADD || funct3 == `FUNCT3_SUB) begin
                if ((opcode == `ARITHMETIC) && (sub_or_not == 1)) begin
                    alu_select = 4'b0001;
                end
                else begin
                    alu_select = 4'b0000;
                end
            end
            else if (funct3 == `FUNCT3_SLL) begin
                alu_select = 4'b0010;
            end
            else if (funct3 == `FUNCT3_XOR) begin
                alu_select = 4'b0011;
            end
            else if (funct3 == `FUNCT3_OR) begin
                alu_select = 4'b0100;
            end
            else if (funct3 == `FUNCT3_AND) begin
                alu_select = 4'b0101;
            end
            else if (funct3 == `FUNCT3_SRL) begin
                alu_select = 4'b0110;
            end
        end
        else if (ALUOp == 2'b00) begin
            alu_select = 4'b0000;
        end
        else if (ALUOp == 2'b01) begin
            if (funct3 == `FUNCT3_BEQ) begin
                alu_select = 4'b0111;
            end
            else if (funct3 == `FUNCT3_BNE) begin
                alu_select = 4'b1000;
            end
            else if (funct3 == `FUNCT3_BLT) begin
                alu_select = 4'b1001;
            end
            else if (funct3 == `FUNCT3_BGE) begin
                alu_select = 4'b1010;
            end
        end
    end

endmodule
