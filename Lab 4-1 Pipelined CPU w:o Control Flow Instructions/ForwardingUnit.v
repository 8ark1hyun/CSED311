module ForwardingUnit(input [4:0] rs1_EX,
                      input [4:0] rs2_EX,
                      input [4:0] rd_MEM,
                      input [4:0] rd_WB,
                      input RegWrite_MEM,
                      input RegWrite_WB,
                      output reg [1:0] forwarding_A,
                      output reg [1:0] forwarding_B);

    always @(*) begin
        forwarding_A = 2'b00;
        forwarding_B = 2'b00;

        if ((rs1_EX != 0) && (rs1_EX == rd_MEM) && (RegWrite_MEM == 1)) begin
            forwarding_A = 2'b01;
        end
        else if ((rs1_EX != 0) && (rs1_EX == rd_WB) && (RegWrite_WB == 1)) begin
            forwarding_A = 2'b10;
        end
        else begin
            forwarding_A = 2'b00;
        end

        if ((rs2_EX != 0) && (rs2_EX == rd_MEM) && (RegWrite_MEM == 1)) begin
            forwarding_B = 2'b01;
        end
        else if ((rs2_EX != 0) && (rs2_EX == rd_WB) && (RegWrite_WB == 1)) begin
            forwarding_B = 2'b10;
        end
        else begin
            forwarding_B = 2'b00;
        end
    end

endmodule
