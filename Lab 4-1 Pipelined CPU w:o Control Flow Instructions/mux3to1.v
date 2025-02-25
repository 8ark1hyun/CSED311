module mux3to1(input [31:0] mux_input1,
               input [31:0] mux_input2,
               input [31:0] mux_input3,
               input [1:0] mux_select,
               output reg [31:0] mux_output);

    always @(*) begin
        case (mux_select)
            2'b00:
                mux_output = mux_input1;
            2'b01:
                mux_output = mux_input2;
            2'b10:
                mux_output = mux_input3;
            default:
                mux_output = mux_input1;
        endcase
    end
    
endmodule
