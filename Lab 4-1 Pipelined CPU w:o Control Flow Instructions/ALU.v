module ALU(input [3:0] alu_select,
           input [31:0] alu_in_1,
           input [31:0] alu_in_2,
           output reg [31:0] alu_result);

    always @(*) begin
        alu_result = 0;

        case (alu_select)
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
            default: begin
                alu_result = 0;
            end
        endcase
    end

endmodule
