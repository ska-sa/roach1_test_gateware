`timescale 1ns/10ps

`include "memlayout.v"
`ifdef MODELSIM
`include "fusion.v"
`endif

module TB_abconf_controller();
  
  reg clk,reset;

  wire [7:0] ACM_rdata;
  wire [7:0] ACM_wdata;
  wire [7:0] ACM_addr;
  wire ACM_wen;
  wire ACM_reset;
  wire ACM_clk;

  reg [15:0] lb_addr;
  reg lb_rd;
  reg lb_wr;
  wire [15:0] lb_data_out;
  reg [15:0] lb_data_in;
  wire lb_strb;
  
  abconf_controller abconf_controller(
    .reset(reset),
    .ACM_addr(ACM_addr),.ACM_rdata(ACM_rdata),.ACM_wdata(ACM_wdata),
    .ACM_wen(ACM_wen),.ACM_reset(ACM_reset),.ACM_clk(ACM_clk),
    .lb_addr(lb_addr),.lb_data_in(lb_data_in),.lb_data_out(lb_data_out),
    .lb_rd(lb_rd),.lb_wr(lb_wr),.lb_strb(lb_strb),.lb_clk(clk)
  );

  reg got_something;

  reg [7:0] counter;
  initial begin
    clk<=1'b0;
    counter<=8'b0;
    reset<=1'b1;
    got_something<=1'b0;
`ifdef DEBUG
    $display("starting sim");
`endif
    #500 reset<=1'b0;
`ifdef DEBUG
    $display("clearing reset");
`endif
    #800000 
    if (got_something)
    $display("PASSED");
    else begin
    $display("FAILED: got nothing");
    end
    $finish;

  end


  always begin
    #1 counter<=counter+1'b1;
    clk<=counter[7];
  end


  reg [7:0] memdump [255:0];
  reg [7:0] temp;

    /*ACM goodies*/
`ifdef MODELSIM
  AB AB_inst(.ACMADDR(ACM_addr),.ACMCLK(ACM_clk),.ACMRDATA(ACM_rdata),.ACMWDATA(ACM_wdata),.ACMRESET(~reset),.ACMWEN(ACM_wen));
`else
  assign ACM_rdata=temp;
  always @(posedge ACM_clk) begin
    if (ACM_wen) begin
`ifdef DEBUG
      $display("ACM got data: %x", ACM_wdata);
`endif 
      memdump[ACM_addr]<=ACM_wdata;
    end else begin
`ifdef DEBUG
      $display("ACM sent data: %x", memdump[ACM_addr]);
`endif 
      temp<=memdump[ACM_addr];
    end
  end
`endif

`define TB_STATE_WRITE 2'd0
`define TB_STATE_WAITW 2'd1
`define TB_STATE_READ 2'd2
`define TB_STATE_WAITR 2'd3
  reg [1:0] state;

  reg [3:0] fault_countdown;

  always @ (posedge clk) begin
    if (reset) begin
      lb_addr<=`ACM_A;
      lb_rd<=1'b0;
      lb_wr<=1'b0;
      state<=`TB_STATE_WRITE;
      fault_countdown<=4'b0;
    end else begin
      case (state)
        `TB_STATE_WRITE:
	  begin
	    lb_wr<=1'b1;
	    lb_addr<=lb_addr + 16'b1;
	    lb_data_in<=lb_addr + 16'b1;
            //lb_data_in<=16'h008c;
	    state<=`TB_STATE_WAITW;
		  `ifdef DEBUG
		   $display("lb_wrote_data = %d, ",lb_addr + 16'b1);
		  `endif
	  end  
	`TB_STATE_READ:
	  begin
	    lb_rd<=1'b1;
	    state<=`TB_STATE_WAITR;
	  end
	`TB_STATE_WAITR:
	  begin
	    if (fault_countdown == 4'b1111) begin
	      state<=`TB_STATE_WRITE;
	      fault_countdown<=4'b0;
              if (lb_addr >= `ACM_A && lb_addr < `ACM_A + `ACM_L) begin
                  $display("FAILED: invalid timeout on write: address %x",lb_addr);
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
                if (lb_addr < `ACM_A || lb_addr >= `ACM_A + `ACM_L) begin
                  $display("FAILED: invalid reply on write: address %x",lb_addr);
	          $finish;
                end
	        state<=`TB_STATE_WRITE;
	        fault_countdown<=4'b0;
                /*only check analogue quag reads*/
                if (lb_addr - (`ACM_A) > 16'b0 && lb_addr - (`ACM_A) <= 16'd40)
                if (lb_data_out[7:0]===8'hxx)begin 
                  $display("FAILED: test data failure -> lb_data_out === X, addr %x",lb_addr - (`ACM_A));
	          //$finish;
                end else if ((lb_addr & 16'h00ff) != lb_data_out) begin
                  $display("FAILED: test data failure -> data_in,%x != data_out%x,,,addr %x",lb_addr & 16'h00ff,lb_data_out, lb_addr - (`ACM_A));
	          //$finish;
                end else begin
		  `ifdef DEBUG
		   $display("lb_got_data = %d, ",lb_data_out);
		  `endif
		  got_something<=1'b1;
		end
	      end
	    end
	  end
	`TB_STATE_WAITW:
	  begin
	    if (fault_countdown == 4'b1111) begin
	      state<=`TB_STATE_WRITE;
	      fault_countdown<=4'b0;
              if (lb_addr >= `ACM_A && lb_addr < `ACM_A + `ACM_L) begin
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
                if (lb_addr < `ACM_A || lb_addr >= `ACM_A + `ACM_L) begin
                  $display("FAILED: invalid reply on write: address %x",lb_addr);
	          $finish;
                end
	        state<=`TB_STATE_READ;
	        fault_countdown<=4'b0;
	      end
	    end
	  end
      endcase
    end
  end

endmodule
