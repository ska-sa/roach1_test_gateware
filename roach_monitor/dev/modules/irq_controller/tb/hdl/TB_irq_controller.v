`timescale 1ns/10ps

`include "memlayout.v"

`define CLK_PERIOD      32'd100

`define STATE_START 3'd0
`define STATE_COMMAND 3'd1
`define STATE_WAITW 3'd2
`define STATE_WAITR 3'd3
`define STATE_CHECK 3'd4

`define COMMAND_USER_SET 3'd0
`define COMMAND_MASK_SET 3'd1
`define COMMAND_MASK_READ 3'd2
`define COMMAND_FLAG_SET 3'd3
`define COMMAND_FLAG_READ 3'd4

module TB_irq_controller();
  reg reset;
  reg [3:0] internal_event;
  wire irq;
  wire clk;
  reg [15:0] lb_addr;
  reg [15:0] lb_data_in;
  wire [15:0] lb_data_out;
  wire lb_strb;
  reg lb_rd,lb_wr;

  irq_controller irq_controller(
    .reset(reset),
    .internal_event(internal_event),
    .irq(irq),
    .lb_addr(lb_addr),.lb_data_in(lb_data_in),.lb_data_out(lb_data_out),
    .lb_rd(lb_rd),.lb_wr(lb_wr),.lb_strb(lb_strb),.lb_clk(clk)
  );

  reg [31:0] clk_counter;
  reg [4:0] irq_set;
  reg [4:0] irq_cleared;

  initial begin
`ifdef DEBUG
    $display("starting simulation");
`endif
   reset<=1'b1;
   clk_counter<=32'b0;
   #512
`ifdef DEBUG
    $display("clearing reset");
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

  reg [3:0] fault_countdown;

  reg [2:0] state;
  reg [3:0] sequence;
  reg [2:0] command;
  reg [4:0] my_flag;
  reg [4:0] my_mask;

  reg [15:0] lb_data_out_buff;


  always @(posedge clk) begin
    if (reset) begin
      state<=`STATE_START;
      fault_countdown<=4'b0;
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
              if (!(lb_data_out_buff[4:0] === 5'b0)) begin
                $display("FAILED: incorrect irq flags == %b  - seq == %d",lb_data_out_buff[4:0],sequence);
                $finish;
              end else if (irq) begin
                $display("FAILED: spurious irq - seq == %d",sequence);
                $finish;
              end
              command<=`COMMAND_FLAG_READ;
              internal_event<=4'b1111;
`ifdef DEBUG              
              $display("test: read flag - events = %b, flag = %b, irq = %b",internal_event,lb_data_out_buff[4:0],irq);
`endif
            end
            4'd2: begin
`ifdef DEBUG              
              $display("test: read flag - events = %b, flag = %b, irq = %b",internal_event,lb_data_out_buff[4:0],irq);
`endif
              if (!(lb_data_out_buff === {11'b0,5'b01111})) begin
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
              if (!(lb_data_out_buff === {11'b0,5'b00000})) begin
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
              $display("test: read flag - events = %b, flag = %b, irq = %d",internal_event,lb_data_out_buff[4:0],irq);
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
              if (!(lb_data_out_buff === {11'b0,5'b11100})) begin
                $display("FAILED: incorrect irq mask - seq == %d",sequence);
                $finish;
              end else if (!(irq === 1'b1)) begin
                $display("FAILED: spurious ~irq - seq == %d",sequence);
                $finish;
              end
              command<=`COMMAND_USER_SET;
`ifdef DEBUG              
              $display("test: read mask - events = %b, mask = %b, irq = %d",internal_event,lb_data_out_buff[4:0],irq);
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
          case (command)
            `COMMAND_USER_SET: begin
              state<=`STATE_WAITW;
              lb_data_in<=16'hffff;
              lb_wr<=1'b1;
              lb_addr<=`IRQC_USER_A;
            end
            `COMMAND_MASK_SET: begin
              state<=`STATE_WAITW;
              lb_data_in<={11'b0,my_mask};
              lb_wr<=1'b1;
              lb_addr<=`IRQC_MASK_A;
            end
            `COMMAND_MASK_READ: begin
              state<=`STATE_WAITR;
              lb_rd<=1'b1;
              lb_addr<=`IRQC_MASK_A;
            end
            `COMMAND_FLAG_SET: begin
              state<=`STATE_WAITW;
              lb_data_in<={11'b0,my_flag};
              lb_wr<=1'b1;
              lb_addr<=`IRQC_FLAG_A;
            end
            `COMMAND_FLAG_READ: begin
              state<=`STATE_WAITR;
              lb_rd<=1'b1;
              lb_addr<=`IRQC_FLAG_A;
            end
          endcase
        end
        `STATE_WAITW: begin
          if (fault_countdown == 4'b1111) begin
            state<=`STATE_COMMAND;
            fault_countdown<=4'b0;
            if (lb_addr >= `IRQC_A && lb_addr < `IRQC_A + `IRQC_L) begin
                $display("FAILED: invalid timeout on write: address %x",lb_addr);
                $finish;
            end
`ifdef DEBUG
            $display("bus timeout at address: %x", lb_addr);
`endif
          end else begin
            fault_countdown<=fault_countdown + 4'b1;
            if (lb_wr)
              lb_wr<=1'b0;

            if (lb_strb) begin
              if (lb_addr < `IRQC_A || lb_addr >= `IRQC_A + `IRQC_L) begin
                $display("FAILED: invalid reply on write: address %x",lb_addr);
                $finish;
              end
              state<=`STATE_CHECK;
              fault_countdown<=4'b0;
            end
          end
        end
        `STATE_WAITR: begin
          if (fault_countdown == 4'b1111) begin
            state<=`STATE_COMMAND;
            fault_countdown<=4'b0;
            if (lb_addr >= `IRQC_A && lb_addr < `IRQC_A + `IRQC_L) begin
                $display("FAILED: invalid timeout on read: address %x",lb_addr);
                $finish;
            end
`ifdef DEBUG
            $display("bus timeout at address: %x", lb_addr);
`endif
          end else begin
            fault_countdown<=fault_countdown + 4'b1;
            if (lb_rd)
              lb_rd<=1'b0;

            if (lb_strb) begin
              if (lb_addr < `IRQC_A || lb_addr >= `IRQC_A + `IRQC_L) begin
                $display("FAILED: invalid reply on read: address %x",lb_addr);
                $finish;
              end
              /*check data here*/
              state<=`STATE_CHECK;
              fault_countdown<=4'b0;
              lb_data_out_buff<=lb_data_out;
            end
          end
        end
        `STATE_CHECK: begin
          state<=`STATE_START;
          sequence<=sequence + 1'b1;
        end
      endcase
    end
  end


endmodule
