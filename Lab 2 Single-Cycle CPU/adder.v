module adder(input [31:0] adder_input1,
             input [31:0] adder_input2,
             output reg [31:0] adder_output);

  always @(*) begin
    adder_output = adder_input1 + adder_input2;
  end

endmodule
