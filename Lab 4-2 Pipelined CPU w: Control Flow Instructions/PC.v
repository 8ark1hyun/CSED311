module PC(input reset,
          input clk,
          input [31:0] next_pc,
          input pc_write,
          output reg [31:0] current_pc);

    always @(posedge clk) begin
        if (reset) begin
            current_pc <= 0;
        end
        else begin
            if (pc_write) begin
                current_pc <= next_pc;
            end
        end
    end
endmodule
