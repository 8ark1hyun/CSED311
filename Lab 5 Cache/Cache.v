`include "CLOG2.v"

module Cache #(parameter LINE_SIZE = 16,
               parameter NUM_SETS = 4,
               parameter NUM_WAYS = 4) (input reset,
                                        input clk,

                                        input is_input_valid,
                                        input [31:0] addr,
                                        input mem_rw,
                                        input [31:0] din,

                                        output is_ready,
                                        output is_output_valid,
                                        output [31:0] dout,
                                        output is_hit,
                                        output [31:0] total_num,
                                        output [31:0] hit_num,
                                        output [31:0] miss_num);

  integer i;
  integer j;

  // Wire declarations
  wire [31:0] clog2;

  wire is_data_mem_ready;
  wire dmem_is_output_valid;

  wire [25:0] tag;
  wire [1:0] index;
  wire [1:0] offset;

  // Reg declarations
  reg dmem_is_input_valid;

  reg [25:0] tag_write;
  reg [127:0] data_write;
  reg valid_bit_write;
  reg dirty_bit_write;
  reg clean_bit_write;

  reg [31:0] dmem_addr;
  reg dmem_read;
  reg dmem_write;
  reg [127:0] dmem_din;
  reg [127:0] dmem_dout;

  reg [1:0] bank;
  reg [1:0] replacement;

  reg [25:0] tag_bank [0:3][0:3];
  reg [127:0] data_bank [0:3][0:3];
  reg valid_bit [0:3][0:3];
  reg dirty_bit [0:3][0:3];
  reg [31:0] LRU [0:3][0:3];

  reg [31:0] LRU_bank;

  reg cache_write;
  reg cache_valid;
  reg cache_ready;
  reg [31:0] cache_dout;
  reg cache_hit;
  reg cache_miss;

  // You might need registers to keep the status.
  reg [1:0] current_state;
  reg [1:0] next_state;

  reg [31:0] total;
  reg [31:0] hit;
  reg [31:0] miss;

  assign clog2 = `CLOG2(LINE_SIZE);

  assign is_ready = cache_ready;
  assign dout = cache_dout;
  assign is_hit = cache_hit;
  assign is_output_valid = cache_valid;

  assign tag = addr[31:6];
  assign index = addr[5:4];
  assign offset = addr[3:2];

  assign total_num = total;
  assign hit_num = hit;
  assign miss_num = miss;

  always @(posedge clk) begin
    if (reset) begin
      for (i = 0; i < NUM_SETS; i++) begin
        for (j = 0; j < NUM_WAYS; j++) begin
          tag_bank[i][j] <= 26'b0;
          data_bank[i][j] <= 128'b0;
          valid_bit[i][j] <= 0;
          dirty_bit[i][j] <= 0;
          LRU[i][j] <= 3;
        end
      end

      current_state <= 2'b0;
      replacement <= 2'b0;

      total <= 32'b0;
      hit <= 32'b0;
      miss <= 32'b0;
    end
    else begin
      current_state <= next_state;
      replacement <= bank;


      if (cache_hit) begin
        total <= total + 1;
        hit <= hit + 1;
      end
      else if (cache_miss) begin
        total <= total + 1;
        miss <= miss + 1;
      end

      if (cache_write) begin
          tag_bank[index][bank] <= tag_write;
          data_bank[index][bank] <= data_write;
          valid_bit[index][bank] <= valid_bit_write;
          dirty_bit[index][bank] <= (clean_bit_write == 1) ? 0 : (dirty_bit_write | dirty_bit[index][bank]);
          case (bank)
            2'b00: begin
              LRU[index][0] <= 0;
              LRU[index][1] <= LRU[index][1] + 1;
              LRU[index][2] <= LRU[index][2] + 1;
              LRU[index][3] <= LRU[index][3] + 1;
            end
            2'b01: begin
              LRU[index][0] <= LRU[index][0] + 1;
              LRU[index][1] <= 0;
              LRU[index][2] <= LRU[index][2] + 1;
              LRU[index][3] <= LRU[index][3] + 1;
            end
            2'b10: begin
              LRU[index][0] <= LRU[index][0] + 1;
              LRU[index][1] <= LRU[index][1] + 1;
              LRU[index][2] <= 0;
              LRU[index][3] <= LRU[index][3] + 1;
            end
            2'b11: begin
              LRU[index][0] <= LRU[index][0] + 1;
              LRU[index][1] <= LRU[index][1] + 1;
              LRU[index][2] <= LRU[index][2] + 1;
              LRU[index][3] <= 0;
            end
          endcase
      end
    end
  end

  always @(*) begin
    dmem_is_input_valid = 0;
    tag_write = 26'b0;
    data_write = 128'b0;
    valid_bit_write = 0;
    dirty_bit_write = 0;
    clean_bit_write = 0;
    dmem_addr = 32'b0;
    dmem_read = 0;
    dmem_write = 0;
    dmem_din = 128'b0;
    bank = replacement;
    LRU_bank = 32'b0;
    cache_write = 0;
    cache_valid = 0;
    cache_ready = 0;
    cache_dout = 32'b0;
    cache_hit = 0;
    cache_miss = 0;
    next_state = 2'b0;

    case (current_state)
      2'b00: begin
        if (is_input_valid) begin
          next_state = 2'b01;
        end
        else begin
          next_state = 2'b00;
          cache_valid = 1;
          cache_ready = 1;
        end
      end
      2'b01: begin
        if ((tag == tag_bank[index][0]) & valid_bit[index][0]) begin //cache hit
          cache_hit = 1;
          cache_valid = 1;
          cache_ready = 1;
          cache_write = 1;
          next_state = 2'b00;

          if (mem_rw == 0) begin //mem read
            bank = 2'b00;
            tag_write = tag;
            data_write = data_bank[index][0];
            valid_bit_write = 1;
            dirty_bit_write = 0;
            case (offset)
              2'b00: cache_dout = data_bank[index][0][31:0];
              2'b01: cache_dout = data_bank[index][0][63:32];
              2'b10: cache_dout = data_bank[index][0][95:64];
              2'b11: cache_dout = data_bank[index][0][127:96];
            endcase
          end
          else if (mem_rw == 1) begin //mem write
            bank = 2'b00;
            tag_write = tag;
            case (offset)
              2'b00: begin
                data_write = {data_bank[index][0][127:32], din};
              end
              2'b01: begin
                data_write = {data_bank[index][0][127:64], din, data_bank[index][0][31:0]};
              end
              2'b10: begin
                data_write = {data_bank[index][0][127:96], din, data_bank[index][0][63:0]};
              end
              2'b11: begin
                data_write = {din, data_bank[index][0][95:0]};
              end
            endcase
            valid_bit_write = 1;
            dirty_bit_write = 1;
          end
        end
        else if ((tag == tag_bank[index][1]) & valid_bit[index][1]) begin //cache hit
          cache_hit = 1;
          cache_valid = 1;
          cache_ready = 1;
          cache_write = 1;
          next_state = 2'b00;

          if (mem_rw == 0) begin //mem read
            bank = 2'b01;
            tag_write = tag;
            data_write = data_bank[index][1];
            valid_bit_write = 1;
            dirty_bit_write = 0;
            case (offset)
              2'b00: cache_dout = data_bank[index][1][31:0];
              2'b01: cache_dout = data_bank[index][1][63:32];
              2'b10: cache_dout = data_bank[index][1][95:64];
              2'b11: cache_dout = data_bank[index][1][127:96];
            endcase
          end
          else if (mem_rw == 1) begin //mem write
            bank = 2'b01;
            tag_write = tag;
            case (offset)
              2'b00: begin
                data_write = {data_bank[index][1][127:32], din};
              end
              2'b01: begin
                data_write = {data_bank[index][1][127:64], din, data_bank[index][1][31:0]};
              end
              2'b10: begin
                data_write = {data_bank[index][1][127:96], din, data_bank[index][1][63:0]};
              end
              2'b11: begin
                data_write = {din, data_bank[index][1][95:0]};
              end
            endcase
            valid_bit_write = 1;
            dirty_bit_write = 1;
          end
        end
        else if ((tag == tag_bank[index][2]) & valid_bit[index][2]) begin //cache hit
          cache_hit = 1;
          cache_valid = 1;
          cache_ready = 1;
          cache_write = 1;
          next_state = 2'b00;

          if (mem_rw == 0) begin //mem read
            bank = 2'b10;
            tag_write = tag;
            data_write = data_bank[index][2];
            valid_bit_write = 1;
            dirty_bit_write = 0;
            case (offset)
              2'b00: cache_dout = data_bank[index][2][31:0];
              2'b01: cache_dout = data_bank[index][2][63:32];
              2'b10: cache_dout = data_bank[index][2][95:64];
              2'b11: cache_dout = data_bank[index][2][127:96];
            endcase
          end
          else if (mem_rw == 1) begin //mem write
            bank = 2'b10;
            tag_write = tag;
            case (offset)
              2'b00: begin
                data_write = {data_bank[index][2][127:32], din};
              end
              2'b01: begin
                data_write = {data_bank[index][2][127:64], din, data_bank[index][2][31:0]};
              end
              2'b10: begin
                data_write = {data_bank[index][2][127:96], din, data_bank[index][2][63:0]};
              end
              2'b11: begin
                data_write = {din, data_bank[index][2][95:0]};
              end
            endcase
            valid_bit_write = 1;
            dirty_bit_write = 1;
          end
        end
        else if ((tag == tag_bank[index][3]) & valid_bit[index][3]) begin //cache hit
          cache_hit = 1;
          cache_valid = 1;
          cache_ready = 1;
          cache_write = 1;
          next_state = 2'b00;

          if (mem_rw == 0) begin //mem read
            bank = 2'b11;
            tag_write = tag;
            data_write = data_bank[index][3];
            valid_bit_write = 1;
            dirty_bit_write = 0;
            case (offset)
              2'b00: cache_dout = data_bank[index][3][31:0];
              2'b01: cache_dout = data_bank[index][3][63:32];
              2'b10: cache_dout = data_bank[index][3][95:64];
              2'b11: cache_dout = data_bank[index][3][127:96];
            endcase
          end
          else if (mem_rw == 1) begin //mem write
            bank = 2'b11;
            tag_write = tag;
            case (offset)
              2'b00: begin
                data_write = {data_bank[index][3][127:32], din};
              end
              2'b01: begin
                data_write = {data_bank[index][3][127:64], din, data_bank[index][3][31:0]};
              end
              2'b10: begin
                data_write = {data_bank[index][3][127:96], din, data_bank[index][3][63:0]};
              end
              2'b11: begin
                data_write = {din, data_bank[index][3][95:0]};
              end
            endcase
            valid_bit_write = 1;
            dirty_bit_write = 1;
          end
        end
        else begin //cache miss
          cache_miss = 1;
          cache_valid = 0;
          cache_ready = 0;

          for (j = 0; j < NUM_WAYS; j++) begin
            if (LRU_bank < LRU[index][j]) begin
              LRU_bank = LRU[index][j];
              bank[1] = j[1];
              bank[0] = j[0];
            end
          end

          if(dirty_bit[index][bank] == 1'b1) begin
            next_state = 2'b11;

            dmem_is_input_valid = 1;
            dmem_addr = {tag_bank[index][bank], index, 4'b0} >> clog2;
            dmem_write = 1;
            dmem_din = data_bank[index][bank];
          end
          else begin
            next_state = 2'b10;

            dmem_is_input_valid = 1;
            dmem_addr = addr >> clog2;
            dmem_read = 1;
          end
        end
      end
      2'b10: begin //write allocate
        if (dmem_is_output_valid & is_data_mem_ready) begin
          cache_write = 1;
          cache_valid = 1;
          cache_ready = 1;
          next_state = 2'b00;

          if (mem_rw == 0) begin //mem read
            tag_write = tag;
            data_write = dmem_dout;
            valid_bit_write = 1;
            clean_bit_write = 1;
            case (offset)
              2'b00: cache_dout = dmem_dout[31:0];
              2'b01: cache_dout = dmem_dout[63:32];
              2'b10: cache_dout = dmem_dout[95:64];
              2'b11: cache_dout = dmem_dout[127:96];
            endcase
          end
          else if (mem_rw == 1) begin //mem write
            tag_write = tag;
            case (offset)
                2'b00: begin
                  data_write = {dmem_dout[127:32], din};
                end
                2'b01: begin
                  data_write = {dmem_dout[127:64], din, dmem_dout[31:0]};
                end
                2'b10: begin
                  data_write = {dmem_dout[127:96], din, dmem_dout[63:0]};
                end
                2'b11: begin
                  data_write = {din, dmem_dout[95:0]};
                end
            endcase
            valid_bit_write = 1;
            dirty_bit_write = 1;
          end
        end
        else begin
          next_state = 2'b10;
        end
      end
      2'b11: begin //write back
        if (is_data_mem_ready) begin
          next_state = 2'b10;

          dmem_is_input_valid = 1;
          dmem_addr = addr >> clog2;
          dmem_read = 1;
        end
        else begin
          next_state = 2'b11;
        end
      end
    endcase
  end

  // Instantiate data memory
  DataMemory #(.BLOCK_SIZE(LINE_SIZE)) data_mem(
    .reset(reset),
    .clk(clk),

    .is_input_valid(dmem_is_input_valid),
    .addr(dmem_addr),        // NOTE: address must be shifted by CLOG2(LINE_SIZE)
    .mem_read(dmem_read),
    .mem_write(dmem_write),
    .din(dmem_din),

    // is output from the data memory valid?
    .is_output_valid(dmem_is_output_valid),
    .dout(dmem_dout),
    // is data memory ready to accept request?
    .mem_ready(is_data_mem_ready)
  );
endmodule
