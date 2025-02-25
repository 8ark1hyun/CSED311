// Submit this file with other files you created.
// Do not touch port declarations of the module 'CPU'.

// Guidelines
// 1. It is highly recommened to `define opcodes and something useful.
// 2. You can modify the module.
// (e.g., port declarations, remove modules, define new modules, ...)
// 3. You might need to describe combinational logics to drive them into the module (e.g., mux, and, or, ...)
// 4. `include files if required

module cpu(input reset,       // positive reset signal
           input clk,         // clock signal
           output is_halted,
           output [31:0] print_reg [0:31]
           ); // Whehther to finish simulation
  /***** Wire declarations *****/
  wire [31:0] next_pc;
  wire [31:0] current_pc;
  wire pc_signal;
  wire [4:0] rs1;
  wire [31:0] rs1_dout;
  wire [31:0] rs2_dout;
  wire [31:0] mem_data;
  wire PCSource;
  wire PCWriteNotCond;
  wire PCWrite;
  wire IorD;
  wire [1:0] ALUOp;
  wire ALUSrcA;
  wire [1:0] ALUSrcB;
  wire RegWrite;
  wire MemRead;
  wire MemWrite;
  wire MemtoReg;
  wire IRWrite;
  wire is_ecall;
  wire [31:0] imm_gen_out;
  wire [31:0] alu_in1;
  wire [31:0] alu_in2;
  wire [3:0] alu_select;
  wire [31:0] alu_result;
  wire bcond;
  wire [31:0] mux_IorD_result;
  wire [31:0] mux_MemtoReg_result;

  /***** Register declarations *****/
  reg [31:0] IR;     // instruction register
  reg [31:0] MDR;    // memory data register
  reg [31:0] A;      // Read 1 data register
  reg [31:0] B;      // Read 2 data register
  reg [31:0] ALUOut; // ALU output register
  // Do not modify and use registers declared above.

  assign pc_signal = ((PCWriteNotCond && !bcond) || PCWrite) ? 1 : 0;
  assign rs1 = (is_ecall == 1) ? 5'b10001 : IR[19:15];
  assign is_halted = ((is_ecall == 1) && (rs1_dout == 10)) ? 1 : 0;

  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  PC pc(
    .reset(reset),            // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),                // input
    .next_pc(next_pc),        // input
    .pc_signal(pc_signal),    // input
    .current_pc(current_pc)   // output
  );

  // ---------- Register File ----------
  RegisterFile reg_file(
    .reset(reset),                     // input
    .clk(clk),                         // input
    .rs1(rs1),                         // input
    .rs2(IR[24:20]),                   // input
    .rd(IR[11:7]),                     // input
    .rd_din(mux_MemtoReg_result),      // input
    .write_enable(RegWrite),           // input
    .rs1_dout(rs1_dout),               // output
    .rs2_dout(rs2_dout),               // output
    .print_reg(print_reg)              // output (TO PRINT REGISTER VALUES IN TESTBENCH)
  );

  // ---------- Memory ----------
  Memory memory(
    .reset(reset),            // input
    .clk(clk),                // input
    .addr(mux_IorD_result),   // input
    .din(B),                  // input
    .mem_read(MemRead),       // input
    .mem_write(MemWrite),     // input
    .dout(mem_data)           // output
  );

  // ---------- Control Unit ----------
  ControlUnit ctrl_unit(
    .reset(reset), 
    .clk(clk),
    .part_of_inst(IR[6:0]),            // input
    .alu_bcond(bcond),                 // input
    .PCSource(PCSource),               // output
    .PCWriteNotCond(PCWriteNotCond),   // output
    .PCWrite(PCWrite),                 // output
    .IorD(IorD),                       // output
    .ALUOp(ALUOp),                     // output
    .ALUSrcA(ALUSrcA),                 // output
    .ALUSrcB(ALUSrcB),                 // output
    .RegWrite(RegWrite),               // output
    .MemRead(MemRead),                 // output
    .MemWrite(MemWrite),               // output
    .MemtoReg(MemtoReg),               // output
    .IRWrite(IRWrite),                 // output
    .is_ecall(is_ecall)                // output (ecall inst)
  );

  // ---------- Immediate Generator ----------
  ImmediateGenerator imm_gen(
    .part_of_inst(IR),          // input
    .imm_gen_out(imm_gen_out)   // output
  );

  // ---------- ALU Control Unit ----------
  ALUControlUnit alu_ctrl_unit(
    .sub_or_not(IR[30]),      // input
    .funct3(IR[14:12]),       // input
    .ALUOp(ALUOp),            // input
    .opcode(IR[6:0]),         // input
    .alu_select(alu_select)   // output
  );

  // ---------- ALU ----------
  ALU alu(
    .alu_select(alu_select),   // input
    .alu_in_1(alu_in1),        // input  
    .alu_in_2(alu_in2),        // input
    .alu_result(alu_result),   // output
    .alu_bcond(bcond)          // output
  );

  // ---------- 2to1 Multiplexer ----------
  mux2to1 mux_IorD(
    .mux_input1(current_pc),       // input
    .mux_input2(ALUOut),           // input
    .mux_select(IorD),             // input
    .mux_output(mux_IorD_result)   // output
  );

  mux2to1 mux_MemtoReg(
    .mux_input1(ALUOut),               // input
    .mux_input2(MDR),                  // input
    .mux_select(MemtoReg),             // input
    .mux_output(mux_MemtoReg_result)   // output
  );

  mux2to1 mux_ALUSrcA(
    .mux_input1(current_pc),   // input
    .mux_input2(A),            // input
    .mux_select(ALUSrcA),      // input
    .mux_output(alu_in1)       // output
  );

  mux2to1 mux_PCSource(
    .mux_input1(alu_result),   // input
    .mux_input2(ALUOut),       // input
    .mux_select(PCSource),     // input
    .mux_output(next_pc)       // output
  );

  // ---------- 3to1 Multiplexer ----------
  mux3to1 mux_ALUSrcB(
    .mux_input1(B),             // input
    .mux_input2(4),             // input
    .mux_input3(imm_gen_out),   // input
    .mux_select(ALUSrcB),       // input
    .mux_output(alu_in2)        // output
  );

  always @(posedge clk) begin
    if (reset) begin
      IR <= 0;
      MDR <= 0;
      A <= 0;
      B <= 0;
      ALUOut <= 0;
    end
    else begin
      if (IRWrite) begin
        IR <= mem_data;
      end
      if (IorD) begin
        MDR <= mem_data;
      end
      A <= rs1_dout;
      B <= rs2_dout;
      ALUOut <= alu_result;
    end
  end

endmodule
