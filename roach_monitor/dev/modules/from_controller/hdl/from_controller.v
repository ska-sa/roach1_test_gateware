`timescale 1ns/10ps
`include "../include/memlayout.v"

`define FROM_STATE_IDLE 0
`define FROM_STATE_WAIT 1
`define FROM_STATE_DATA 2
`define FROM_STATE_CLEAN 3

module from_controller(
  reset,
  from_clk,from_addr,from_data,
  lb_addr,lb_data_in,lb_data_out,lb_rd,lb_wr,lb_strb,lb_clk
);
  input reset;
  output from_clk;
  output [6:0] from_addr;
  input [7:0] from_data;

  input [15:0] lb_addr;
  input [15:0] lb_data_in;
  output [15:0] lb_data_out;
  input lb_rd,lb_wr,lb_clk;
  output lb_strb;

  wire addressed=(lb_addr >= `FROM_A && lb_addr < `FROM_A + `FROM_L);
  wire [7:0] temp_addr=(lb_addr - (`FROM_A));
  
  reg clk_mask;
  assign from_clk=lb_clk & clk_mask;
  
  reg [6:0] from_addr;
  reg [15:0] lb_data_out;
  reg lb_strb;
  reg [2:0] from_state;

  always @(posedge lb_clk) begin
    if (reset) begin
      clk_mask<=1'b0;
      from_state<=2'b0;
      lb_data_out<=16'b0;
      lb_strb<=1'b0;
      from_addr<=7'b0;
    end else begin
      case (from_state) 
        `FROM_STATE_IDLE: 
	  begin
	    if (lb_rd & addressed) begin
              clk_mask<=1'b1;
`ifdef DEBUG
              $display("from: got rd strb");
`endif
	      from_addr<=temp_addr[6:0];
	      from_state<=`FROM_STATE_WAIT;
	    end
	  end
	`FROM_STATE_WAIT: 
	  begin
	    /* wait cycle */
	    from_state<=`FROM_STATE_DATA;
`ifdef DEBUG
              $display("from: waiting");
`endif
	  end
	`FROM_STATE_DATA: 
	  begin
	    if (addressed) begin
	      lb_data_out<={8'b0,from_data};
	      lb_strb<=1'b1;
`ifdef DEBUG
              $display("from: assert output strobe");
`endif
	    end else begin
`ifdef DEBUG
              $display("from: not addressed?");
`endif
            end
	    from_state<=`FROM_STATE_CLEAN;
	  end
	`FROM_STATE_CLEAN: 
	  begin
`ifdef DEBUG
              $display("from: finished operation");
`endif
	    lb_strb<=1'b0;
	    clk_mask<=1'b0;
	    lb_data_out<=16'b0;
	    from_state<=`FROM_STATE_IDLE;
	  end
      endcase
    end
  end

endmodule
