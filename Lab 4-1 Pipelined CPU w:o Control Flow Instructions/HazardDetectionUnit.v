module HazardDetectionUnit(input MemRead_EX,
                           input [4:0] rs1_ID,
                           input [4:0] rs2_ID,
                           input [4:0] rd_EX,
                           output reg IFIDWrite,
                           output reg PCWrite,
                           output reg stall_or_not);

    always @(*) begin
        IFIDWrite = 0;
        PCWrite = 0;
        stall_or_not = 0;

        if (((rs1_ID == rd_EX) || (rs2_ID == rd_EX)) && (MemRead_EX == 1)) begin
            stall_or_not = 1;
        end
        else begin
            IFIDWrite = 1;
            PCWrite = 1;
        end
    end

endmodule
