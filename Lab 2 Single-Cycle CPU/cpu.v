// Submit this file with other files you created.
// Do not touch port declarations of the module 'cpu'.

// Guidelines
// 1. It is highly recommened to `define opcodes and something useful.
// 2. You can modify the module.
// (e.g., port declarations, remove modules, define new modules, ...)
// 3. You might need to describe combinational logics to drive them into the module (e.g., mux, and, or, ...)
// 4. `include files if required

module cpu(input reset,                     // positive reset signal
           input clk,                       // clock signal
           output is_halted,                // Whehther to finish simulation
           output [31:0] print_reg [0:31]); // TO PRINT REGISTER VALUES IN TESTBENCH (YOU SHOULD NOT USE THIS)
  /***** Wire declarations *****/
  wire [31:0] next_pc;
  wire [31:0] current_pc;
  wire [31:0] instruction;
  wire [31:0] write_data;
  wire [31:0] rs1_dout;
  wire [31:0] rs2_dout;
  wire JAL;
  wire JALR;
  wire Branch;
  wire MemRead;
  wire MemtoReg;
  wire MemWrite;
  wire ALUSrc;
  wire RegWrite;
  wire PCtoReg;
  wire is_ecall;
  wire [31:0] imm_gen_out;
  wire [3:0] alu_op;
  wire [31:0] alu_in;
  wire [31:0] alu_result;
  wire bcond;
  wire [31:0] dout;
  wire [31:0] adder_result1;
  wire [31:0] adder_result2;
  wire [31:0] mux_result1;
  wire [31:0] mux_result2;

  /***** Register declarations *****/

  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  pc pc(
    .reset(reset),            // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),                // input
    .next_pc(next_pc),        // input
    .current_pc(current_pc)   // output
  );
  
  // ---------- Instruction Memory ----------
  instruction_memory imem(
    .reset(reset),       // input
    .clk(clk),           // input
    .addr(current_pc),   // input
    .dout(instruction)   // output
  );

  // ---------- Register File ----------
  register_file reg_file(
    .reset(reset),              // input
    .clk(clk),                  // input
    .rs1(instruction[19:15]),   // input
    .rs2(instruction[24:20]),   // input
    .rd(instruction[11:7]),     // input
    .rd_din(write_data),        // input
    .write_enable(RegWrite),    // input
    .is_ecall(is_ecall),        // input
    .rs1_dout(rs1_dout),        // output
    .rs2_dout(rs2_dout),        // output
    .is_halted(is_halted),      // output
    .print_reg(print_reg)       //DO NOT TOUCH THIS
  );

  // ---------- Control Unit ----------
  control_unit ctrl_unit(
    .part_of_inst(instruction[6:0]),   // input
    .is_jal(JAL),                      // output
    .is_jalr(JALR),                    // output
    .branch(Branch),                   // output
    .mem_read(MemRead),                // output
    .mem_to_reg(MemtoReg),             // output
    .mem_write(MemWrite),              // output
    .alu_src(ALUSrc),                  // output
    .write_enable(RegWrite),           // output
    .pc_to_reg(PCtoReg),               // output
    .is_ecall(is_ecall)                // output (ecall inst)
  );

  // ---------- Immediate Generator ----------
  immediate_generator imm_gen(
    .part_of_inst(instruction),   // input
    .imm_gen_out(imm_gen_out)     // output
  );

  // ---------- ALU Control Unit ----------
  alu_control_unit alu_ctrl_unit(
    .sub_or_not(instruction[30]),   // input
    .funct3(instruction[14:12]),    // input
    .opcode(instruction[6:0]),      // input
    .alu_op(alu_op)                 // output
  );

  // ---------- ALU ----------
  alu alu(
    .alu_op(alu_op),           // input
    .alu_in_1(rs1_dout),       // input  
    .alu_in_2(alu_in),         // input
    .alu_result(alu_result),   // output
    .alu_bcond(bcond)          // output
  );

  // ---------- Data Memory ----------
  data_memory dmem(
    .reset(reset),          // input
    .clk(clk),              // input
    .addr(alu_result),      // input
    .din(rs2_dout),         // input
    .mem_read(MemRead),     // input
    .mem_write(MemWrite),   // input
    .dout(dout)             // output
  );

  // ---------- Adder ----------
  adder adder1(
    .adder_input1(current_pc),     //input
    .adder_input2(4),              //input
    .adder_output(adder_result1)   //output
  );

  adder adder2(
    .adder_input1(current_pc),     //input
    .adder_input2(imm_gen_out),    //input
    .adder_output(adder_result2)   //output
  );

  // ---------- 2to1 Multiplexer ----------
  mux mux_register_file(
    .mux_input1(mux_result1),     //input
    .mux_input2(adder_result1),   //input
    .mux_select(PCtoReg),         //input
    .mux_output(write_data)       //output
  );

  mux mux_alu(
    .mux_input1(rs2_dout),      //input
    .mux_input2(imm_gen_out),   //input
    .mux_select(ALUSrc),        //input
    .mux_output(alu_in)         //output
  );

  mux mux_data_memory(
    .mux_input1(alu_result),   //input
    .mux_input2(dout),         //input
    .mux_select(MemtoReg),     //input
    .mux_output(mux_result1)   //output
  );

  mux mux_adder1(
    .mux_input1(adder_result1),            //input
    .mux_input2(adder_result2),            //input
    .mux_select((Branch & bcond) | JAL),   //input
    .mux_output(mux_result2)               //output
  );

  mux mux_adder2(
    .mux_input1(mux_result2),   //input
    .mux_input2(alu_result),    //input
    .mux_select(JALR),          //input
    .mux_output(next_pc)        //output
  );

endmodule
