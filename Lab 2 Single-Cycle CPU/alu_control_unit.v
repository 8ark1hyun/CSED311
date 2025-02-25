`include "opcodes.v"

module alu_control_unit(input sub_or_not,
                        input [2:0] funct3,
                        input [6:0] opcode,
                        output reg [3:0] alu_op);

  always @(*) begin
    alu_op = 4'b1111;

    if (opcode == `ARITHMETIC) begin
        if (sub_or_not == 1) begin
            if (funct3 == `FUNCT3_SUB) begin
                alu_op = 4'b0001;
            end
        end
        else if (sub_or_not == 0) begin
            if (funct3 == `FUNCT3_ADD) begin
                alu_op = 4'b0000;
            end
            else if (funct3 == `FUNCT3_SLL) begin
                alu_op = 4'b0010;
            end
            else if (funct3 == `FUNCT3_XOR) begin
                alu_op = 4'b0011;
            end
            else if (funct3 == `FUNCT3_OR) begin
                alu_op = 4'b0100;
            end
            else if (funct3 == `FUNCT3_AND) begin
                alu_op = 4'b0101;
            end
            else if (funct3 == `FUNCT3_SRL) begin
                alu_op = 4'b0110;
            end
        end
    end
    else if (opcode == `ARITHMETIC_IMM) begin
        if (funct3 == `FUNCT3_ADD) begin
            alu_op = 4'b0000;
        end
        else if (funct3 == `FUNCT3_SLL) begin
            alu_op = 4'b0010;
        end
        else if (funct3 == `FUNCT3_XOR) begin
            alu_op = 4'b0011;
        end
        else if (funct3 == `FUNCT3_OR) begin
            alu_op = 4'b0100;
        end
        else if (funct3 == `FUNCT3_AND) begin
            alu_op = 4'b0101;
        end
        else if (funct3 == `FUNCT3_SRL) begin
            alu_op = 4'b0110;
        end
    end
    else if ((opcode == `LOAD) || (opcode == `STORE) || (opcode == `JALR) || (opcode == `JAL)) begin
        alu_op = 4'b0000;
    end
    else if (opcode == `BRANCH) begin
        if (funct3 == `FUNCT3_BEQ) begin
            alu_op = 4'b0111;
        end
        else if (funct3 == `FUNCT3_BNE) begin
            alu_op = 4'b1000;
        end
        else if (funct3 == `FUNCT3_BLT) begin
            alu_op = 4'b1001;
        end
        else if (funct3 == `FUNCT3_BGE) begin
            alu_op = 4'b1010;
        end
    end
  end

endmodule
