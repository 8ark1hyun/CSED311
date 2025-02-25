module alu(input [3:0] alu_op,
           input [31:0] alu_in_1,
           input [31:0] alu_in_2,
           output reg [31:0] alu_result,
           output reg alu_bcond);

  always @(*) begin
    alu_bcond = 0;
    alu_result = 0;

    case(alu_op)
      4'b0000:
        alu_result = alu_in_1 + alu_in_2;
      4'b0001:
        alu_result = alu_in_1 - alu_in_2;
      4'b0010:
        alu_result = alu_in_1 << alu_in_2;
      4'b0011:
        alu_result = alu_in_1 ^ alu_in_2;
      4'b0100:
        alu_result = alu_in_1 | alu_in_2;
      4'b0101:
        alu_result = alu_in_1 & alu_in_2;
      4'b0110:
        alu_result = alu_in_1 >> alu_in_2;
      4'b0111: begin
        if (alu_in_1 == alu_in_2) begin
          alu_bcond = 1;
        end
      end
      4'b1000: begin
        if (alu_in_1 != alu_in_2) begin
          alu_bcond = 1;
        end
      end
      4'b1001: begin
        if (alu_in_1 < alu_in_2) begin
          alu_bcond = 1;
        end
      end
      4'b1010: begin
        if (alu_in_1 >= alu_in_2) begin
          alu_bcond = 1;
        end
      end
      default: begin
        alu_bcond = 0;
        alu_result = 0;
      end
    endcase
  end

endmodule
