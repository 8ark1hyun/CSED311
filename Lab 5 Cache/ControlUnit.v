`include "opcodes.v"

module ControlUnit(input [6:0] part_of_inst,
                   output reg alu_src,
                   output reg mem_write,
                   output reg mem_read,
                   output reg mem_to_reg,
                   output reg pc_to_reg,
                   output reg write_enable,
                   output reg is_branch,
                   output reg is_jal,
                   output reg is_jalr,
                   output reg is_ecall);

    always @(*) begin
        alu_src = 0;
        mem_write = 0;
        mem_read = 0;
        mem_to_reg = 0;
        pc_to_reg = 0;
        write_enable = 0;
        is_branch = 0;
        is_jal = 0;
        is_jalr = 0;
        is_ecall = 0;

        if (part_of_inst[6:0] == `ARITHMETIC) begin
            write_enable = 1;
        end
        else if (part_of_inst[6:0] == `ARITHMETIC_IMM) begin
            alu_src = 1;
            write_enable = 1;
        end
        else if (part_of_inst[6:0] == `LOAD) begin
            alu_src = 1;
            mem_read = 1;
            mem_to_reg = 1;
            write_enable = 1;
        end
        else if (part_of_inst[6:0] == `STORE) begin
            alu_src = 1;
            mem_write = 1;
        end
        else if (part_of_inst[6:0] == `JAL) begin
            is_jal = 1;
            alu_src = 1;
            pc_to_reg = 1;
            write_enable = 1;
        end
        else if (part_of_inst[6:0] == `JALR) begin
            is_jalr = 1;
            alu_src = 1;
            pc_to_reg = 1;
            write_enable = 1;
        end
        else if (part_of_inst[6:0] == `BRANCH) begin
            is_branch = 1;
        end
        else if (part_of_inst[6:0] == `ECALL) begin
            is_ecall = 1;
        end
    end
endmodule
