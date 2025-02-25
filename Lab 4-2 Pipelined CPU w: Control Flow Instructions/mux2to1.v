module mux2to1(input [31:0] mux_input1,
               input [31:0] mux_input2,
               input mux_select,
               output reg [31:0] mux_output);

  always @(*) begin
    mux_output = !mux_select ? mux_input1 : mux_input2;
  end
endmodule
