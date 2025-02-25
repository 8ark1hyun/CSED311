`include "vending_machine_def.v"
	

module check_time_and_coin(clk, reset_n, i_trigger_return, coin_value, current_total, input_total, output_total, o_return_coin, return_total, wait_time, return_signal);

	input clk;
	input reset_n;
	input i_trigger_return;
	input [31:0] coin_value [`kNumCoins-1:0];	
	input [`kTotalBits-1:0] current_total, input_total, output_total;
	output reg [`kNumCoins-1:0] o_return_coin;
	output reg [`kTotalBits-1:0] return_total;
	output reg [31:0] wait_time;
	output reg return_signal;

	integer k;
	integer total;

	initial begin
		wait_time = `kWaitTime;
		return_signal = 0;
	end

	always @(*) begin
		o_return_coin = 0;
		return_total = 0;
		total = current_total;

		if ((return_signal == 1) && (wait_time == 0)) begin
			for (k = `kNumCoins - 1; k >= 0; k--) begin
				if (total >= coin_value[k]) begin
					o_return_coin[k] = 1;
					total = total - coin_value[k];
					return_total = return_total + coin_value[k];
				end
			end
		end
	end

	always @(posedge clk) begin
		if ((i_trigger_return == 1) || (wait_time == 0)) begin
				return_signal <= 1;
				if (i_trigger_return == 1)
					wait_time <= 1;
		end
		
		if (!reset_n) begin
			wait_time <= `kWaitTime;
		end
		else begin
			if (input_total != 0 || output_total != 0) begin
				wait_time <= `kWaitTime;
			end
			else begin
				if (wait_time > 1) begin
					wait_time <= wait_time - 1;
				end
				else if (wait_time == 1) begin
					wait_time <= 0;
				end
			end
		end
	end
endmodule 
