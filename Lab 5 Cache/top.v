// Do not submit this file.
`include "cpu.v"

module top(input reset,
           input clk,
           output is_halted,
           output [31:0] total_num,
           output [31:0] hit_num,
           output [31:0] miss_num,
           output [31:0] print_reg [0:31]);

  cpu cpu(
    .reset(reset), 
    .clk(clk),
    .is_halted(is_halted),
    .total_num(total_num),
    .hit_num(hit_num),
    .miss_num(miss_num),
    .print_reg(print_reg)
  );

endmodule
