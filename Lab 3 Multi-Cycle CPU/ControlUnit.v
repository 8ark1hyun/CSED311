`include "opcodes.v"
`include "states.v"

module ControlUnit(input reset,
                   input clk,
                   input [6:0] part_of_inst,
                   input alu_bcond,
                   output reg PCSource,
                   output reg PCWriteNotCond,
                   output reg PCWrite,
                   output reg IorD,
                   output reg [1:0] ALUOp,
                   output reg ALUSrcA,
                   output reg [1:0] ALUSrcB,
                   output reg RegWrite,
                   output reg MemRead,
                   output reg MemWrite,
                   output reg MemtoReg,
                   output reg IRWrite,
                   output reg is_ecall);

    reg [3:0] microPC;
    reg [3:0] state;

    initial begin
        microPC = `IF1;
    end

    always @(posedge clk) begin
        if (reset) begin
            microPC <= `IF1;
        end
        else begin
            microPC <= state;
        end
    end

    MicrocodeController micro_controller(
        .microPC(microPC),
        .opcode(part_of_inst),
        .alu_bcond(alu_bcond),
        .state(state)
    );

    always @(*) begin
        PCSource = 0;
        PCWriteNotCond = 0;
        PCWrite = 0;
        IorD = 0;
        ALUOp = 2'b00;
        ALUSrcA = 0;
        ALUSrcB = 2'b00;
        RegWrite = 0;
        MemRead = 0;
        MemWrite = 0;
        MemtoReg = 0;
        IRWrite = 0;
        is_ecall = 0;

        case (microPC)
            `IF1: begin
                IorD = 0;
                MemRead = 1;
                IRWrite = 1;
            end
            `IF4: begin
                if (part_of_inst[6:0] == `ECALL) begin
                    ALUSrcA = 0;
                    ALUSrcB = 2'b01;
                    ALUOp = 2'b00;
                    PCWrite = 1;
                    PCSource = 0;
                    is_ecall = 1;
                end
            end
            `ID: begin
                ALUSrcA = 0;
                ALUSrcB = 2'b01;
                ALUOp = 2'b00;
            end
            `EX1: begin
                if (part_of_inst[6:0] == `ARITHMETIC) begin
                    ALUSrcA = 1;
                    ALUSrcB = 2'b00;
                    ALUOp = 2'b10;
                end
                else if (part_of_inst[6:0] == `ARITHMETIC_IMM) begin
                    ALUSrcA = 1;
                    ALUSrcB = 2'b10;
                    ALUOp = 2'b10;
                end
                else if ((part_of_inst[6:0] == `LOAD) || (part_of_inst[6:0] == `STORE)) begin
                    ALUSrcA = 1;
                    ALUSrcB = 2'b10;
                    ALUOp = 2'b00;
                end
                else if (part_of_inst[6:0] == `BRANCH) begin
                    PCWriteNotCond = 1;
                    ALUSrcA = 1;
                    ALUSrcB = 2'b00;
                    ALUOp = 2'b01;
                    PCSource = 1;
                end
                else if (part_of_inst[6:0] == `JALR) begin
                    ALUSrcA = 0;
                    ALUSrcB = 2'b01;
                    ALUOp = 2'b00;
                end
                else if (part_of_inst[6:0] == `JAL) begin
                    ALUSrcA = 0;
                    ALUSrcB = 2'b01;
                    ALUOp = 2'b00;
                end
            end
            `EX2: begin
                if (part_of_inst[6:0] == `BRANCH) begin
                    ALUSrcA = 0;
                    ALUSrcB = 2'b10;
                    ALUOp = 2'b00;
                    PCWrite = 1;
                    PCSource = 0;
                end
            end
            `MEM1: begin
                if (part_of_inst[6:0] == `LOAD) begin
                    MemRead = 1;
                    IorD = 1;
                end
                else if (part_of_inst[6:0] == `STORE) begin
                    MemWrite = 1;
                    IorD = 1;
                end
            end
            `MEM4: begin
                if (part_of_inst[6:0] == `STORE) begin
                    ALUSrcA = 0;
                    ALUSrcB = 2'b01;
                    ALUOp = 2'b00;
                    PCWrite = 1;
                    PCSource = 0;
                end
            end
            `WB: begin
                if ((part_of_inst[6:0] == `ARITHMETIC) || (part_of_inst[6:0] == `ARITHMETIC_IMM)) begin
                    RegWrite = 1;
                    ALUSrcA = 0;
                    ALUSrcB = 2'b01;
                    ALUOp = 2'b00;
                    PCWrite = 1;
                    PCSource = 0;
                end
                else if (part_of_inst[6:0] == `LOAD) begin
                    MemtoReg = 1;
                    RegWrite = 1;
                    ALUSrcA = 0;
                    ALUSrcB = 2'b01;
                    ALUOp = 2'b00;
                    PCWrite = 1;
                    PCSource = 0;
                end
                else if (part_of_inst[6:0] == `JALR) begin
                    RegWrite = 1;
                    ALUSrcA = 1;
                    ALUSrcB = 2'b10;
                    ALUOp = 2'b00;
                    PCWrite = 1;
                    PCSource = 0;
                end
                else if (part_of_inst[6:0] == `JAL) begin
                    RegWrite = 1;
                    ALUSrcA = 0;
                    ALUSrcB = 2'b10;
                    ALUOp = 2'b00;
                    PCWrite = 1;
                    PCSource = 0;
                end
            end
            default: begin
                PCSource = 0;
                PCWriteNotCond = 0;
                PCWrite = 0;
                IorD = 0;
                ALUOp = 2'b00;
                ALUSrcA = 0;
                ALUSrcB = 2'b00;
                RegWrite = 0;
                MemRead = 0;
                MemWrite = 0;
                MemtoReg = 0;
                IRWrite = 0;
                is_ecall = 0;
            end
        endcase
    end

endmodule
