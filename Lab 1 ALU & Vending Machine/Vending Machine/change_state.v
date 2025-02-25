`include "vending_machine_def.v"


module change_state(clk, reset_n, current_total_nxt, return_total, current_total, wait_time, return_signal);

	input clk;
	input reset_n;
	input [`kTotalBits-1:0] current_total_nxt;
	input [`kTotalBits-1:0] return_total;
	output reg [`kTotalBits-1:0] current_total;
	output reg [31:0] wait_time;
	output reg return_signal;

	// Sequential circuit to reset or update the states
	always @(posedge clk) begin	
		if (!reset_n) begin
			current_total <= 0;
		end
		else begin
			current_total <= current_total_nxt;
			if ((current_total - return_total == 0) && (return_signal == 1)) begin
				return_signal <= 0;
				wait_time <= `kWaitTime;
			end
		end
	end
endmodule 
