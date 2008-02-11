`include "irq_controller.vh"

`define CLK_PERIOD 32'd2

`define STATE_START   2'd0
`define STATE_COMMAND 2'd1
`define STATE_WAIT    2'd2

`define COMMAND_USER_SET  3'd0
`define COMMAND_MASK_SET  3'd1
`define COMMAND_MASK_READ 3'd2
`define COMMAND_FLAG_SET  3'd3
`define COMMAND_FLAG_READ 3'd4

module TB_irq_controller();
  reg  reset;
  wire clk;
  reg  [3:0] internal_event;
  wire irq;
  reg  wb_cyc_i, wb_stb_i, wb_we_i;
  reg  [15:0] wb_adr_i;
  reg  [15:0] wb_dat_i;
  wire [15:0] wb_dat_o;
  wire wb_ack_o;

  irq_controller #(
    .NUM_SOURCES(4)
  ) irq_controller_inst (
    .wb_rst_i(reset), .wb_clk_i(clk),
    .wb_cyc_i(wb_cyc_i), .wb_stb_i(wb_stb_i), .wb_we_i(wb_we_i),
    .wb_adr_i(wb_adr_i), .wb_dat_i(wb_dat_i), .wb_dat_o(wb_dat_o),
    .wb_ack_o(wb_ack_o),
    .irq_i(internal_event), .irq_o(irq)
  );

  reg [31:0] clk_counter;
  reg [4:0] irq_set;
  reg [4:0] irq_cleared;

  initial begin
`ifdef DEBUG
    $display("sim: starting simulation");
`endif
   reset<=1'b1;
   clk_counter<=32'b0;
   #512
`ifdef DEBUG
    $display("sim: clearing reset");
`endif
   reset<=1'b0;
   #999999
   $display("FAILED: simulation timed out");
   $finish;
  end
  
  assign clk = (clk_counter > (`CLK_PERIOD >> 1));
  always begin
    #1 clk_counter<=(clk_counter < `CLK_PERIOD ? clk_counter + 32'b1 : 32'b0);
  end

  reg [1:0] state;
  reg [3:0] sequence;
  reg [2:0] command;
  reg [4:0] my_flag;
  reg [4:0] my_mask;

  reg [15:0] wb_dat_o_buf;

  always @(posedge clk) begin
    wb_cyc_i <= 1'b0;
    wb_stb_i <= 1'b0;
    if (reset) begin
      state<=`STATE_START;
      sequence<=4'd0;
      my_mask<=4'b0;
      my_flag<=4'b0;
      internal_event<=4'b0000;
    end else begin
      case (state)
        `STATE_START: begin
          state<=`STATE_COMMAND;
          case (sequence)
            4'd0: begin
              internal_event<=4'b0000;
              command<=`COMMAND_FLAG_READ;
            end
            4'd1: begin
              if (!(wb_dat_o_buf[4:0] === 5'b0)) begin
                $display("FAILED: incorrect irq flags == %b  - seq == %d",wb_dat_o_buf[4:0],sequence);
                $finish;
              end else if (irq) begin
                $display("FAILED: spurious irq - seq == %d",sequence);
                $finish;
              end
              command<=`COMMAND_FLAG_READ;
              internal_event<=4'b1111;
`ifdef DEBUG              
              $display("test: read flag - events = %b, flag = %b, irq = %b",internal_event,wb_dat_o_buf[4:0],irq);
`endif
            end
            4'd2: begin
`ifdef DEBUG              
              $display("test: read flag - events = %b, flag = %b, irq = %b",internal_event,wb_dat_o_buf[4:0],irq);
`endif
              if (!(wb_dat_o_buf === {11'b0,5'b01111})) begin
                $display("FAILED: incorrect irq flags - seq == %d",sequence);
                $finish;
              end else if (~irq) begin
                $display("FAILED: spurious ~irq - seq == %d",sequence);
                $finish;
              end
              command<=`COMMAND_FLAG_SET;
              my_flag<=5'b00000;
              internal_event<=4'b0;
            end
            4'd3: begin
`ifdef DEBUG              
              $display("test: cleared flag - events = %b, flag = %b, irq = %d",internal_event,my_flag,irq);
`endif
              if (irq) begin
                $display("FAILED: irq flag clear failed - seq == %d",sequence);
                $finish;
              end
              command<=`COMMAND_FLAG_READ;
            end
            4'd4: begin
              if (!(wb_dat_o_buf === {11'b0,5'b00000})) begin
                $display("FAILED: incorrect irq flags - seq == %d",sequence);
                $finish;
              end else if (irq) begin
                $display("FAILED: spurious irq - seq == %d",sequence);
                $finish;
              end
              command<=`COMMAND_MASK_SET;
              my_mask<=5'b11100;
              internal_event<=4'b0011;
`ifdef DEBUG              
              $display("test: read flag - events = %b, flag = %b, irq = %d",internal_event,wb_dat_o_buf[4:0],irq);
`endif
            end
            4'd5: begin
              if (!(irq === 1'b0)) begin
                $display("FAILED: mask clearing failed - seq == %d",sequence);
                $finish;
              end
              internal_event<=4'b0111;
              command<=`COMMAND_MASK_READ;
`ifdef DEBUG              
              $display("test: set mask - events = %b, mask = %b, irq = %d",internal_event,my_mask,irq);
`endif
            end
            4'd6: begin
              if (!(wb_dat_o_buf === {11'b0,5'b11100})) begin
                $display("FAILED: incorrect irq mask - seq == %d",sequence);
                $finish;
              end else if (!(irq === 1'b1)) begin
                $display("FAILED: spurious ~irq - seq == %d",sequence);
                $finish;
              end
              command<=`COMMAND_USER_SET;
`ifdef DEBUG              
              $display("test: read mask - events = %b, mask = %b, irq = %d",internal_event,wb_dat_o_buf[4:0],irq);
`endif
            end
            4'd7: begin
              if (!(irq === 1'b1)) begin
                $display("FAILED: no user irq - seq == %d",sequence);
                $finish;
              end
              command<=`COMMAND_FLAG_SET;
              my_flag<=5'b01011; /*only clear flags that should be set*/
              internal_event<=4'b0011;
`ifdef DEBUG              
              $display("test: user irq - events = %b, mask = %b, irq = %d",internal_event,my_mask,irq);
`endif
            end
            4'd8: begin
              if (!(irq === 1'b0)) begin
                $display("FAILED: flag clearing failed - seq == %d",sequence);
                $finish;
              end
`ifdef DEBUG              
              $display("test: clear flag - events = %b, flag = %b, irq = %d",internal_event,my_flag,irq);
`endif
              $display("PASSED");
              $finish;
            end
          endcase
        end
        `STATE_COMMAND: begin
          wb_stb_i <= 1'b1;
          wb_cyc_i <= 1'b1;
          case (command)
            `COMMAND_USER_SET: begin
              state<=`STATE_WAIT;
              wb_dat_i<=16'hffff;
              wb_we_i <=1'b1;
              wb_adr_i<=`REG_IRQC_USER;
            end
            `COMMAND_MASK_SET: begin
              state<=`STATE_WAIT;
              wb_dat_i<={11'b0,my_mask};
              wb_we_i<=1'b1;
              wb_adr_i<=`REG_IRQC_MASK;
            end
            `COMMAND_MASK_READ: begin
              state<=`STATE_WAIT;
              wb_we_i<=1'b0;
              wb_adr_i<=`REG_IRQC_MASK;
            end
            `COMMAND_FLAG_SET: begin
              state<=`STATE_WAIT;
              wb_dat_i<={11'b0,my_flag};
              wb_we_i<=1'b1;
              wb_adr_i<=`REG_IRQC_FLAG;
            end
            `COMMAND_FLAG_READ: begin
              state<=`STATE_WAIT;
              wb_we_i<=1'b0;
              wb_adr_i<=`REG_IRQC_FLAG;
            end
          endcase
        end
        `STATE_WAIT: begin
          wb_dat_o_buf<=wb_dat_o;
          if (wb_ack_o) begin
            state<=`STATE_START;
            sequence<=sequence + 1'b1;
          end
        end
      endcase
    end
  end


endmodule
