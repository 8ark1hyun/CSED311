// Submit this file with other files you created.
// Do not touch port declarations of the module 'CPU'.

// Guidelines
// 1. It is highly recommened to `define opcodes and something useful.
// 2. You can modify modules (except InstMemory, DataMemory, and RegisterFile)
// (e.g., port declarations, remove modules, define new modules, ...)
// 3. You might need to describe combinational logics to drive them into the module (e.g., mux, and, or, ...)
// 4. `include files if required

module cpu(input reset,       // positive reset signal
           input clk,         // clock signal
           output is_halted, // Whehther to finish simulation
           output [31:0] print_reg [0:31]); // Whehther to finish simulation
  integer i;
  
  /***** Wire declarations *****/
  wire [31:0] next_pc;
  wire [31:0] predict_pc;
  wire [31:0] current_pc;
  wire [31:0] pc_4;
  wire [31:0] pc_imm;
  wire [31:0] reg_imm;
  wire [31:0] target_addr;
  wire [31:0] instruction;
  wire [31:0] immediate;
  wire [4:0] rs1_input;
  wire [31:0] rs1_dout;
  wire [31:0] rs2_dout;
  wire halt_signal;
  wire stall_or_not;
  wire pc_write;
  wire alu_src;
  wire mem_write;
  wire mem_read;
  wire mem_to_reg;
  wire pc_to_reg;
  wire reg_write;
  wire is_branch;
  wire is_jal;
  wire is_jalr;
  wire taken_or_not;
  wire is_taken;
  wire is_ecall;
  wire [3:0] alu_select;
  wire [31:0] alu_input1;
  wire [31:0] alu_input2;
  wire [31:0] alu_result;
  wire alu_bcond;
  wire [1:0] forward_A;
  wire [1:0] forward_B;
  wire [31:0] forward_1;
  wire [31:0] forward_2;
  wire [31:0] mux_ForwardB_result;
  wire [31:0] mux_MemtoReg_result;
  wire [31:0] dmem_dout;
  wire [31:0] write_data;
  wire [4:0] BHSR;

  /***** Register declarations *****/
  // You need to modify the width of registers
  // In addition, 
  // 1. You might need other pipeline registers that are not described below
  // 2. You might not need registers described below
  reg flush_or_not;
  reg [31:0] real_pc;

  /***** IF/ID pipeline registers *****/
  reg IF_ID_write;          // will be used in IF stage
  reg IF_ID_flush_or_not;
  reg [31:0] IF_ID_inst;    // will be used in ID stage
  reg [31:0] IF_ID_PC;
  reg [4:0] IF_ID_BHSR;

  /***** ID/EX pipeline registers *****/
  // From the control unit
  reg ID_EX_alu_src;        // will be used in EX stage
  reg ID_EX_mem_write;      // will be used in MEM stage
  reg ID_EX_mem_read;       // will be used in MEM stage
  reg ID_EX_mem_to_reg;     // will be used in WB stage
  reg ID_EX_pc_to_reg;
  reg ID_EX_reg_write;      // will be used in WB stage
  reg ID_EX_is_branch;
  reg ID_EX_is_jal;
  reg ID_EX_is_jalr;
  reg ID_EX_halt_signal;    // will be used in WB stage
  // From others
  reg [31:0] ID_EX_rs1_data;
  reg [31:0] ID_EX_rs2_data;
  reg [31:0] ID_EX_imm;
  reg [31:0] ID_EX_inst;
  reg [31:0] ID_EX_PC;
  reg [10:0] ID_EX_ALU_ctrl_unit_input;
  reg [4:0] ID_EX_rd;
  reg [4:0] ID_EX_BHSR;

  /***** EX/MEM pipeline registers *****/
  // From the control unit
  reg EX_MEM_mem_write;     // will be used in MEM stage
  reg EX_MEM_mem_read;      // will be used in MEM stage
  reg EX_MEM_mem_to_reg;    // will be used in WB stage
  reg EX_MEM_pc_to_reg;
  reg EX_MEM_reg_write;     // will be used in WB stage
  reg EX_MEM_halt_signal;   // will be used in WB stage
  // From others
  reg [31:0] EX_MEM_PC;
  reg [31:0] EX_MEM_pc_4;
  reg [31:0] EX_MEM_alu_out;
  reg [31:0] EX_MEM_dmem_data;
  reg [4:0] EX_MEM_rd;

  /***** MEM/WB pipeline registers *****/
  // From the control unit
  reg MEM_WB_mem_to_reg;    // will be used in WB stage
  reg MEM_WB_pc_to_reg;
  reg MEM_WB_reg_write;     // will be used in WB stage
  reg MEM_WB_halt_signal;   // will be used in WB stage
  // From others
  reg [31:0] MEM_WB_PC;
  reg [31:0] MEM_WB_pc_4;
  reg [31:0] MEM_WB_mem_to_reg_src_1;
  reg [31:0] MEM_WB_mem_to_reg_src_2;
  reg [4:0] MEM_WB_rd;

  assign rs1_input = (is_ecall == 1) ? 5'b10001 : IF_ID_inst[19:15];
  assign halt_signal = ((is_ecall == 1) && (ID_EX_rd == 5'b10001) && (alu_result == 10)) ? 1 : 0;

  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  PC pc(
    .reset(reset),            // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),                // input
    .next_pc(next_pc),        // input
    .pc_write(pc_write),      // output
    .current_pc(current_pc)   // output
  );
  
  // ---------- Instruction Memory ----------
  InstMemory imem(
    .reset(reset),       // input
    .clk(clk),           // input
    .addr(current_pc),   // input
    .dout(instruction)   // output
  );

  // ---------- BTB ----------
  Branch_Predictor branch_predictor(
    .reset(reset),                 // input
    .clk(clk),                     // input
    .current_pc(current_pc),       // input
    .ID_EX_PC(ID_EX_PC),           // input
    .taken_or_not(taken_or_not),   // input
    .is_taken(is_taken),           // input
    .target_addr(target_addr),     // input
    .ID_EX_BHSR(ID_EX_BHSR),       // input
    .BHSR(BHSR),                   // output
    .predict_pc(predict_pc)        // output
  );

  // ---------- 2to1 Multiplexer ----------
  mux2to1 mux_PCSrc(
    .mux_input1(predict_pc),     // input
    .mux_input2(real_pc),        // input
    .mux_select(flush_or_not),   // input
    .mux_output(next_pc)         // output
  );

  // ---------- 2to1 Multiplexer ----------
  mux2to1 mux_target(
    .mux_input1(pc_imm),          // input
    .mux_input2(reg_imm),         // input
    .mux_select(ID_EX_is_jalr),   // input
    .mux_output(target_addr)      // output
  );

  // Update IF/ID pipeline registers here
  always @(posedge clk) begin
    if (reset | flush_or_not) begin
      IF_ID_flush_or_not <= 0;
      IF_ID_inst <= 0;
      IF_ID_PC <= 0;
      IF_ID_BHSR <= 0;
    end
    else begin
      if (IF_ID_write) begin
        IF_ID_flush_or_not <= flush_or_not;

        IF_ID_inst <= instruction;
        IF_ID_PC <= current_pc;
        IF_ID_BHSR <= BHSR;
      end
    end
  end

  // ---------- Register File ----------
  RegisterFile reg_file(
    .reset(reset),                     // input
    .clk(clk),                         // input
    .rs1(rs1_input),                   // input
    .rs2(IF_ID_inst[24:20]),           // input
    .rd(MEM_WB_rd),                    // input
    .rd_din(write_data),               // input
    .write_enable(MEM_WB_reg_write),   // input
    .rs1_dout(rs1_dout),               // output
    .rs2_dout(rs2_dout),               // output
    .print_reg(print_reg)
  );

  // ---------- Control Unit ----------
  ControlUnit ctrl_unit(
    .part_of_inst(IF_ID_inst[6:0]),   // input
    .alu_src(alu_src),                // output
    .mem_write(mem_write),            // output
    .mem_read(mem_read),              // output
    .mem_to_reg(mem_to_reg),          // output
    .pc_to_reg(pc_to_reg),            // output
    .write_enable(reg_write),         // output
    .is_branch(is_branch),            // output
    .is_jal(is_jal),                  // output
    .is_jalr(is_jalr),                // output
    .is_ecall(is_ecall)               // output (ecall inst)
  );

  // ---------- Immediate Generator ----------
  ImmediateGenerator imm_gen(
    .part_of_inst(IF_ID_inst),   // input
    .imm_gen_out(immediate)      // output
  );

  // ---------- Hazard detection unit ----------
  HazardDetectionUnit hazard_detection_unit(
    .MemRead_EX(ID_EX_mem_read),   // input
    .rs1_ID(IF_ID_inst[19:15]),    // input
    .rs2_ID(IF_ID_inst[24:20]),    // input
    .rd_EX(ID_EX_rd),              // input
    .IFIDWrite(IF_ID_write),       // output
    .PCWrite(pc_write),            // output
    .stall_or_not(stall_or_not)    // output
  );

  // ---------- 2to1 Multiplexer ----------
  mux2to1 mux_write_data(
    .mux_input1(mux_MemtoReg_result),   // input
    .mux_input2(MEM_WB_pc_4),         // input
    .mux_select(MEM_WB_pc_to_reg),      // input
    .mux_output(write_data)             // output
  );

  // Update ID/EX pipeline registers here
  always @(posedge clk) begin
    if (reset | stall_or_not | flush_or_not | IF_ID_flush_or_not) begin
      ID_EX_alu_src <= 0;
      ID_EX_mem_write <= 0;
      ID_EX_mem_read <= 0;
      ID_EX_mem_to_reg <= 0;
      ID_EX_pc_to_reg <= 0;
      ID_EX_reg_write <= 0;
      ID_EX_is_branch <= 0;
      ID_EX_is_jal <= 0;
      ID_EX_is_jalr <= 0;
      ID_EX_halt_signal <= 0;
      ID_EX_rs1_data <= 0;
      ID_EX_rs2_data <= 0;
      ID_EX_imm <= 0;
      ID_EX_inst <= 0;
      ID_EX_PC <= 0;
      ID_EX_ALU_ctrl_unit_input <= 0;
      ID_EX_rd <= 0;
      ID_EX_BHSR <= 0;
    end
    else begin
      ID_EX_alu_src <= alu_src;

      ID_EX_mem_write <= mem_write;
      ID_EX_mem_read <= mem_read;

      ID_EX_mem_to_reg <= mem_to_reg;
      ID_EX_pc_to_reg <= pc_to_reg;
      ID_EX_reg_write <= reg_write;

      ID_EX_is_branch <= is_branch;
      ID_EX_is_jal <= is_jal;
      ID_EX_is_jalr <= is_jalr;

      ID_EX_halt_signal <= halt_signal;

      ID_EX_rs1_data <= rs1_dout;
      ID_EX_rs2_data <= rs2_dout;
      ID_EX_imm <= immediate;
      ID_EX_inst <= IF_ID_inst;
      ID_EX_PC <= IF_ID_PC;
      ID_EX_ALU_ctrl_unit_input <= {IF_ID_inst[30], IF_ID_inst[14:12], IF_ID_inst[6:0]};
      ID_EX_rd <= IF_ID_inst[11:7];
      ID_EX_BHSR <= IF_ID_BHSR;
    end
  end

  // ---------- ALU Control Unit ----------
  ALUControlUnit alu_ctrl_unit(
    .part_of_inst(ID_EX_ALU_ctrl_unit_input),   // input
    .alu_select(alu_select)                     // output
  );

  // ---------- ALU ----------  
  ALU alu(
    .alu_select(alu_select),   // input
    .alu_in_1(alu_input1),     // input  
    .alu_in_2(alu_input2),     // input
    .alu_result(alu_result),   // output
    .alu_bcond(alu_bcond)      // output
  );

  // ---------- Forwarding unit ----------
  ForwardingUnit forwarding_unit(
    .rs1_EX(ID_EX_inst[19:15]),        // input
    .rs2_EX(ID_EX_inst[24:20]),        // input
    .rd_MEM(EX_MEM_rd),                // input
    .rd_WB(MEM_WB_rd),                 // input
    .RegWrite_MEM(EX_MEM_reg_write),   // input
    .RegWrite_WB(MEM_WB_reg_write),    // input
    .forwarding_A(forward_A),          // output
    .forwarding_B(forward_B)           // output
  );

  // ---------- 2to1 Multiplexer ----------
  mux2to1 mux_ALUSrc(
    .mux_input1(mux_ForwardB_result),   // input
    .mux_input2(ID_EX_imm),             // input
    .mux_select(ID_EX_alu_src),         // input
    .mux_output(alu_input2)             // output
  );

  // ---------- 3to1 Multiplexer ----------
  mux3to1 mux_ForwardA(
    .mux_input1(ID_EX_rs1_data),   // input
    .mux_input2(forward_1),        // input
    .mux_input3(forward_2),        // input
    .mux_select(forward_A),        // input
    .mux_output(alu_input1)        // output
  );

  // ---------- 3to1 Multiplexer ----------
  mux3to1 mux_ForwardB(
    .mux_input1(ID_EX_rs2_data),       // input
    .mux_input2(forward_1),            // input
    .mux_input3(forward_2),            // input
    .mux_select(forward_B),            // input
    .mux_output(mux_ForwardB_result)   // output
  );

  // ---------- 2to1 Multiplexer ----------
  mux2to1 mux_forward_1(
    .mux_input1(EX_MEM_alu_out),     // input
    .mux_input2(EX_MEM_pc_4),      // input
    .mux_select(EX_MEM_pc_to_reg),   // input
    .mux_output(forward_1)           // output
  );

  // ---------- 2to1 Multiplexer ----------
  mux2to1 mux_forward_2(
    .mux_input1(mux_MemtoReg_result),   // input
    .mux_input2(MEM_WB_pc_4),         // input
    .mux_select(MEM_WB_pc_to_reg),      // input
    .mux_output(forward_2)              // output
  );

  // ---------- Adder ----------
  Adder adder_pc_4(
    .adder_input1(ID_EX_PC),   //input
    .adder_input2(4),          //input
    .adder_output(pc_4)        //output
  );

  // ---------- Adder ----------
  Adder adder_pc_imm(
    .adder_input1(ID_EX_PC),    //input
    .adder_input2(ID_EX_imm),   //input
    .adder_output(pc_imm)       //output
  );

  assign reg_imm = alu_result;
  assign taken_or_not = ID_EX_is_branch | ID_EX_is_jal | ID_EX_is_jalr;
  assign is_taken = (ID_EX_is_branch & alu_bcond) | ID_EX_is_jal | ID_EX_is_jalr;

  always @(*) begin
    if (ID_EX_is_jal) begin
      real_pc = pc_imm;
    end
    else if (ID_EX_is_jalr) begin
      real_pc = reg_imm;
    end
    else if (ID_EX_is_branch & alu_bcond) begin
      real_pc = pc_imm;
    end
    else begin
      real_pc = pc_4;
    end
  end

  always @(*) begin
    flush_or_not = 0;
    if (ID_EX_PC != 0) begin
      if (IF_ID_PC != real_pc) begin
        flush_or_not = 1;
      end
    end
  end

  // Update EX/MEM pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      EX_MEM_mem_write <= 0;
      EX_MEM_mem_read <= 0;
      EX_MEM_mem_to_reg <= 0;
      EX_MEM_pc_to_reg <= 0;
      EX_MEM_reg_write <= 0;
      EX_MEM_halt_signal <= 0;
      EX_MEM_PC <= 0;
      EX_MEM_pc_4 <= 0;
      EX_MEM_alu_out <= 0;
      EX_MEM_dmem_data <= 0;
      EX_MEM_rd <= 0;
    end
    else begin
      EX_MEM_mem_write <= ID_EX_mem_write;
      EX_MEM_mem_read <= ID_EX_mem_read;

      EX_MEM_mem_to_reg <= ID_EX_mem_to_reg;
      EX_MEM_pc_to_reg <= ID_EX_pc_to_reg;
      EX_MEM_reg_write <= ID_EX_reg_write;

      EX_MEM_halt_signal <= ID_EX_halt_signal;

      EX_MEM_PC <= ID_EX_PC;
      EX_MEM_pc_4 <= pc_4;
      EX_MEM_alu_out <= alu_result;
      EX_MEM_dmem_data <= mux_ForwardB_result;
      EX_MEM_rd <= ID_EX_rd;
    end
  end

  // ---------- Data Memory ----------
  DataMemory dmem(
    .reset(reset),                  // input
    .clk(clk),                      // input
    .addr(EX_MEM_alu_out),          // input
    .din(EX_MEM_dmem_data),         // input
    .mem_read(EX_MEM_mem_read),     // input
    .mem_write(EX_MEM_mem_write),   // input
    .dout(dmem_dout)                // output
  );

  // Update MEM/WB pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      MEM_WB_mem_to_reg <= 0;
      MEM_WB_pc_to_reg <= 0;
      MEM_WB_reg_write <= 0;
      MEM_WB_halt_signal <= 0;
      MEM_WB_mem_to_reg_src_1 <= 0;
      MEM_WB_mem_to_reg_src_2 <= 0;
      MEM_WB_rd <= 0;
      MEM_WB_PC <= 0;
      MEM_WB_pc_4 <= 0;
    end
    else begin
      MEM_WB_mem_to_reg <= EX_MEM_mem_to_reg;
      MEM_WB_pc_to_reg <= EX_MEM_pc_to_reg;
      MEM_WB_reg_write <= EX_MEM_reg_write;

      MEM_WB_halt_signal <= EX_MEM_halt_signal;

      MEM_WB_PC <= EX_MEM_PC;
      MEM_WB_pc_4 <= EX_MEM_pc_4;
      MEM_WB_mem_to_reg_src_1 <= EX_MEM_alu_out;
      MEM_WB_mem_to_reg_src_2 <= dmem_dout;
      MEM_WB_rd <= EX_MEM_rd;
    end
  end

  // ---------- 2to1 Multiplexer ----------
  mux2to1 mux_MemtoReg(
    .mux_input1(MEM_WB_mem_to_reg_src_1),   // input
    .mux_input2(MEM_WB_mem_to_reg_src_2),   // input
    .mux_select(MEM_WB_mem_to_reg),         // input
    .mux_output(mux_MemtoReg_result)        // output
  );

  assign is_halted = (MEM_WB_halt_signal == 1) ? 1 : 0;

endmodule
