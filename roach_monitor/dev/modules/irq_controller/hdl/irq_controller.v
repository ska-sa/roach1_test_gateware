`timescale 1 ns/10 ps
`include "memlayout.v"
module irq_controller(
  reset,
  internal_event,
  irq,
  lb_addr,lb_data_in,lb_data_out,lb_rd,lb_wr,lb_strb,lb_clk
  );
  input reset;
  
  input [3:0] internal_event; 
  output irq;

  input lb_clk;
  input [15:0] lb_addr;
  input [15:0] lb_data_in;
  output [15:0] lb_data_out;
  input lb_rd,lb_wr;
  output lb_strb;
  
  reg lb_strb;
  reg [15:0] lb_data_out;
  wire addressed = (lb_addr >= `IRQC_A && lb_addr < `IRQC_A + `IRQC_L);

  reg [4:0] irq_mask;
  reg [4:0] irq_flag;

  assign irq=((irq_flag & irq_mask) != 5'b0);

  always @(posedge lb_clk) begin
    if (reset) begin
      irq_mask<=5'b11111;
      irq_flag<=5'b00000;
      lb_strb<=1'b0;
      lb_data_out<=16'b0;
`ifdef DEBUG
      $display("irqc: reset");
`endif 
    end else begin
      if (addressed & (lb_rd | lb_wr)) begin
        case (lb_addr)
          `IRQC_FLAG_A: begin
            if (lb_rd) begin
              lb_data_out<={11'b0,irq_flag};
            end else begin
`ifdef DEBUG
              $display("irqc: setting flags to %b -- events = %b",irq_flag & lb_data_in[4:0],internal_event);
`endif
              irq_flag<=irq_flag & lb_data_in[4:0]; /*leave zeros, clear ones*/
            end
          end
          `IRQC_USER_A: begin
            if (lb_wr && lb_data_in) begin
              irq_flag[4]<=1'b1;
            end 
          end
          `IRQC_MASK_A: begin
            if (lb_rd) begin
              lb_data_out<={11'b0,irq_mask};
            end else begin
              irq_mask<=lb_data_in[4:0];
            end
          end
        endcase
        lb_strb<=1'b1;
      end else begin
        irq_flag<=(irq_flag | {1'b0,internal_event}); /*leave ones, set zeros*/
`ifdef DEBUG
        if ( irq_flag != (irq_flag | {1'b0,internal_event})) begin
          $display("irqc: got irq -- events == %b",internal_event);
        end
`endif 
        lb_data_out<=16'b0;
        lb_strb<=1'b0;
      end 
    end 
  end
  
endmodule
