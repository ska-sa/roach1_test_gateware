`timescale 1ns/10ps
`include "memlayout.v"
module TB_from_controller();
  reg clk,reset;
  reg [7:0] from_data;
  wire [6:0] from_addr;
  wire from_clk;

  reg [15:0] lb_addr;
  reg lb_rd;
  wire [15:0] lb_data_out;
  wire lb_strb;
  
  from_controller from_controller(
    .reset(reset),
    .from_clk(from_clk),.from_addr(from_addr),.from_data(from_data),
    .lb_addr(lb_addr),.lb_data_in(16'b0),.lb_data_out(lb_data_out),
    .lb_rd(lb_rd),.lb_wr(1'b0),.lb_strb(lb_strb),.lb_clk(clk)
  );


  initial begin
    clk<=1'b0;
    reset<=1'b1;
`ifdef DEBUG
    $display("starting sim");
`endif
    #5 reset<=1'b0;
`ifdef DEBUG
    $display("clearing reset");
`endif
    #8000 $display("PASSED");
    $finish;

  end

  always begin
    #1 clk <=~clk;
  end

    /*from goodies*/
  always @(posedge from_clk) begin
    from_data<={1'b0,from_addr};
  end

`define STATE_STRB 0
`define STATE_WAIT 1
  reg state;

  reg [3:0] fault_countdown;

  always @ (posedge clk) begin
    if (reset) begin
      lb_addr<=16'hfff0;
      lb_rd<=1'b0;
      state<=1'b0;
      fault_countdown<=4'b0;
    end else begin
      case (state)
        `STATE_STRB:
	  begin
	    lb_rd<=1'b1;
	    lb_addr<=lb_addr + 16'b1;
	    state<=`STATE_WAIT;
	  end
	`STATE_WAIT:
	  begin
	    if (fault_countdown == 4'b1111) begin
	      state<=`STATE_STRB;
	      fault_countdown<=4'b0;
              if (lb_addr >= `FROM_A && lb_addr < `FROM_A + `FROM_L) begin
                  $display("FAILED: invalid timeout");
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
                if (lb_addr < `FROM_A || lb_addr >= `FROM_A + `FROM_L) begin
                  $display("FAILED: invalid reply");
	          $finish;
                end
	        state<=`STATE_STRB;
	        fault_countdown<=4'b0;
                if ( (lb_addr & 16'h007f) != lb_data_out) begin
                  $display("FAILED: test data failure -> data_in != data_out");
	          $finish;
                end 
	      end
	    end
	  end
      endcase
    end
  end

endmodule
