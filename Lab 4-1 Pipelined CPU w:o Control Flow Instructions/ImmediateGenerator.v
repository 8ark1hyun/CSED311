`include "opcodes.v"

module ImmediateGenerator(input [31:0] part_of_inst,
                           output reg [31:0] imm_gen_out);

  always @(*) begin
    imm_gen_out = 0;
    
    if (part_of_inst[6:0] == `ARITHMETIC_IMM || part_of_inst[6:0] == `LOAD || part_of_inst[6:0] == `JALR) begin
      imm_gen_out = {{21{part_of_inst[31]}}, part_of_inst[30:20]};
    end
    else if (part_of_inst[6:0] == `STORE) begin
      imm_gen_out = {{21{part_of_inst[31]}}, part_of_inst[30:25], part_of_inst[11:7]};
    end
    else if (part_of_inst[6:0] == `JAL) begin
      imm_gen_out = {{12{part_of_inst[31]}}, part_of_inst[19:12], part_of_inst[20], part_of_inst[30:21], 1'b0};
    end
    else if (part_of_inst[6:0] == `BRANCH) begin
      imm_gen_out = {{20{part_of_inst[31]}}, part_of_inst[7], part_of_inst[30:25], part_of_inst[11:8], 1'b0};
    end
  end

endmodule
