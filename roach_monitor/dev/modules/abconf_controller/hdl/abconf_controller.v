`timescale 1ns/10ps
`include "memlayout.v"

`define STATE_IDLE 0
`define STATE_WAIT 1
`define STATE_DATA 2
`define STATE_WRITE 3
`define STATE_CLEAN 4

module abconf_controller(
  reset,
  ACM_wdata,ACM_rdata,ACM_addr,ACM_wen,ACM_clk,ACM_reset,
  lb_addr,lb_data_out,lb_data_in,lb_rd,lb_wr,lb_strb,lb_clk
);
  input reset;

  output [7:0] ACM_wdata;
  input [7:0] ACM_rdata;
  output [7:0] ACM_addr;
  output ACM_wen;
  output ACM_clk;
  output ACM_reset;

  input [15:0] lb_addr;
  output [15:0] lb_data_out;
  input [15:0] lb_data_in;
  input lb_rd,lb_wr,lb_clk;
  output lb_strb;

  assign ACM_clk = lb_clk;
  assign ACM_reset = ~reset;
  wire addressed=(lb_addr >= `ACM_A && lb_addr < `ACM_A + `ACM_L);
  wire [7:0] temp_addr=(lb_addr - (`ACM_A));
  
  reg [15:0] lb_data_out;
  reg lb_strb;
  
  reg [7:0] ACM_wdata;
  reg [7:0] ACM_addr;
  reg ACM_wen;
  reg [3:0] state;

  always @(posedge lb_clk) begin
    if (reset) begin
      state<=`STATE_IDLE;
      lb_data_out<=16'b0;
      lb_strb<=1'b0;
      ACM_wen<=1'b0;
    end else begin
      case (state) 
        `STATE_IDLE: 
	  begin
	    if (lb_rd & addressed) begin
`ifdef DEBUG
              $display("ACM: got rd strb, ACM_addr %d",temp_addr[7:0]);
`endif
	      ACM_addr<=temp_addr[7:0];
	      state<=`STATE_WAIT;
	    end else if (lb_wr & addressed) begin
`ifdef DEBUG
              $display("ACM: got wr strb, data %d -- ACM_addr %d",lb_data_in[7:0],temp_addr[7:0]);
`endif
	      ACM_addr<=temp_addr[7:0];
	      ACM_wdata<=lb_data_in[7:0];
	      ACM_wen<=1'b1;
	      state<=`STATE_WRITE;	      	      
	    end
	  end
	`STATE_WRITE:
	  begin
	    lb_strb<=1'b1;	    
`ifdef DEBUG
              $display("ACM: assert ack strobe");
`endif
	    ACM_wen<=1'b0;
	    state<=`STATE_CLEAN;
	  end
	`STATE_WAIT: 
	  begin
	    /* wait cycle */
	    state<=`STATE_DATA;
`ifdef DEBUG
              $display("waiting");
`endif
	  end
	`STATE_DATA: 
	  begin
	    if (addressed) begin
	      lb_data_out<={8'b0,ACM_rdata};
	      lb_strb<=1'b1;
`ifdef DEBUG
              $display("ACM: assert output strobe with data = %d",{8'b0,ACM_rdata});
`endif
	    end
            else begin
`ifdef DEBUG
              $display("ACM: not addressed?");
`endif
            end
	    state<=`STATE_CLEAN;
	  end
	`STATE_CLEAN: 
	  begin
`ifdef DEBUG
              $display("ACM: finished operation");
`endif
	    lb_strb<=1'b0;
	    lb_data_out<=16'b0;
	    state<=`STATE_IDLE;
	  end
      endcase
    end
  end

endmodule
