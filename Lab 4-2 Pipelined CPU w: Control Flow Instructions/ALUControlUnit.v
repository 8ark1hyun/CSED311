`include "opcodes.v"

module ALUControlUnit(input [10:0] part_of_inst,
                      output reg [3:0] alu_select);

    always @(*) begin
        alu_select = 4'b1111;

        if (part_of_inst[6:0] == `ARITHMETIC) begin
            if (part_of_inst[10] == 1) begin
                if (part_of_inst[9:7] == `FUNCT3_SUB) begin
                    alu_select = 4'b0001;
                end
            end
            else if (part_of_inst[10] == 0) begin
                if (part_of_inst[9:7] == `FUNCT3_ADD) begin
                    alu_select = 4'b0000;
                end
                else if (part_of_inst[9:7] == `FUNCT3_SLL) begin
                    alu_select = 4'b0010;
                end
                else if (part_of_inst[9:7] == `FUNCT3_XOR) begin
                    alu_select = 4'b0011;
                end
                else if (part_of_inst[9:7] == `FUNCT3_OR) begin
                    alu_select = 4'b0100;
                end
                else if (part_of_inst[9:7] == `FUNCT3_AND) begin
                    alu_select = 4'b0101;
                end
                else if (part_of_inst[9:7] == `FUNCT3_SRL) begin
                    alu_select = 4'b0110;
                end
            end
        end
        else if (part_of_inst[6:0] == `ARITHMETIC_IMM) begin
            if (part_of_inst[9:7] == `FUNCT3_ADD) begin
                alu_select = 4'b0000;
            end
            else if (part_of_inst[9:7] == `FUNCT3_SLL) begin
                alu_select = 4'b0010;
            end
            else if (part_of_inst[9:7] == `FUNCT3_XOR) begin
                alu_select = 4'b0011;
            end
            else if (part_of_inst[9:7] == `FUNCT3_OR) begin
                alu_select = 4'b0100;
            end
            else if (part_of_inst[9:7] == `FUNCT3_AND) begin
                alu_select = 4'b0101;
            end
            else if (part_of_inst[9:7] == `FUNCT3_SRL) begin
                alu_select = 4'b0110;
            end
        end
        else if ((part_of_inst[6:0] == `LOAD) || (part_of_inst[6:0] == `STORE) || (part_of_inst[6:0] == `JALR) || (part_of_inst[6:0] == `JAL)) begin
            alu_select = 4'b0000;
        end
        else if (part_of_inst[6:0] == `BRANCH) begin
            if (part_of_inst[9:7] == `FUNCT3_BEQ) begin
                alu_select = 4'b0111;
            end
            else if (part_of_inst[9:7] == `FUNCT3_BNE) begin
                alu_select = 4'b1000;
            end
            else if (part_of_inst[9:7] == `FUNCT3_BLT) begin
                alu_select = 4'b1001;
            end
            else if (part_of_inst[9:7] == `FUNCT3_BGE) begin
                alu_select = 4'b1010;
            end
        end
    end
endmodule
