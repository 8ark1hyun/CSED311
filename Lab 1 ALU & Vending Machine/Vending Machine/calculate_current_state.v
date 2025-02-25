`include "vending_machine_def.v"
	

module calculate_current_state(i_input_coin, i_select_item, item_price, coin_value, current_total, return_total, wait_time, return_signal, o_available_item, o_output_item, input_total, output_total, current_total_nxt);

	input [`kNumCoins-1:0] i_input_coin;
	input [`kNumItems-1:0]	i_select_item;			
	input [31:0] item_price [`kNumItems-1:0];
	input [31:0] coin_value [`kNumCoins-1:0];	
	input [`kTotalBits-1:0] current_total, return_total;
	input [31:0] wait_time;
	input return_signal;
	output reg [`kNumItems-1:0] o_available_item, o_output_item;
	output reg [`kTotalBits-1:0] input_total, output_total, current_total_nxt;

	integer i;	

	// Combinational logic for the next states
	always @(*) begin
		input_total = 0;
		output_total = 0;
		current_total_nxt = 0;

		for (i = 0; i < `kNumCoins; i++) begin
			if (i_input_coin[i] && (wait_time != 0))
				input_total = input_total + coin_value[i];
		end

		for (i = 0; i < `kNumItems; i++) begin
			if (o_output_item[i])
				output_total = output_total + item_price[i];
		end

		if (return_signal == 0) begin
			current_total_nxt = current_total + input_total - output_total;
		end
		else begin
			current_total_nxt = current_total - return_total;
		end
	end

	// Combinational logic for the outputs
	always @(*) begin
		o_available_item = 0;
		o_output_item = 0;

		for (i = 0; i < `kNumItems; i++) begin
			if (item_price[i] <= current_total) begin
				o_available_item[i] = 1;
				if (i_select_item[i] && (wait_time != 0))
					o_output_item[i] = 1;
			end
		end
	end
endmodule 
