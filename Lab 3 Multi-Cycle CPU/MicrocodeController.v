`include "opcodes.v"
`include "states.v"

module MicrocodeController(input [3:0] microPC,
                           input [6:0] opcode,
                           input alu_bcond,
                           output reg [3:0] state);

    always @(*) begin
        case (microPC)
            `IF1:
                state = `IF2;
            `IF2:
                state = `IF3;
            `IF3:
                state = `IF4;
            `IF4: begin
                if (opcode == `JAL) begin
                    state = `EX1;
                end
                else if (opcode == `ECALL) begin
                    state = `IF1;
                end
                else begin
                    state = `ID;
                end
            end
            `ID:
                state = `EX1;
            `EX1: begin
                if ((opcode == `BRANCH) && (alu_bcond == 0)) begin
                    state = `IF1;
                end
                else begin
                    if ((opcode == `ARITHMETIC) || (opcode == `ARITHMETIC_IMM) || (opcode == `JALR) || (opcode == `JAL)) begin
                        state = `WB; 
                    end
                    else if ((opcode == `LOAD) || (opcode == `STORE)) begin
                        state = `MEM1;
                    end
                    else begin
                        state = `EX2;
                    end
                end
            end
            `EX2: begin
                state = `IF1;
            end
            `MEM1:
                state = `MEM2;
            `MEM2:
                state = `MEM3;
            `MEM3:
                state = `MEM4;
            `MEM4: begin
                if (opcode == `LOAD) begin
                    state = `WB;
                end
                else begin
                    state = `IF1;
                end
            end
            `WB:
                state = `IF1;
            default:
                state = `IF1;
        endcase
    end

endmodule
