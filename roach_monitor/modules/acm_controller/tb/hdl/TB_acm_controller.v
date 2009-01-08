`timescale 1ns/1ns
`define CLK_PERIOD 25

`ifdef MODELSIM
`include "fusion.v"
`endif

module TB_acm_controller();
  wire clk;

  reg reset;

  wire [7:0] ACM_rdata;
  wire [7:0] ACM_wdata;
  wire [7:0] ACM_addr;
  wire ACM_wen;
  wire ACM_reset;
  wire ACM_clk;

  reg  wb_cyc_i, wb_stb_i, wb_we_i;
  reg  [15:0] wb_adr_i;
  reg  [15:0] wb_dat_i;
  wire [15:0] wb_dat_o;
  wire wb_ack_o;
  
  acm_controller acm_controller_inst(
    .wb_clk_i(clk), .wb_rst_i(reset),
    .wb_cyc_i(wb_cyc_i), .wb_stb_i(wb_stb_i), .wb_we_i(wb_we_i),
    .wb_adr_i(wb_adr_i), .wb_dat_i(wb_dat_i), .wb_dat_o(wb_dat_o),
    .wb_ack_o(wb_ack_o),
    .acm_wdata(ACM_wdata), .acm_rdata(ACM_rdata),
    .acm_addr(ACM_addr),
    .acm_wen(ACM_wen),
    .acm_clk(ACM_clk), .acm_reset(ACM_reset)
  );

  reg [7:0] clk_counter;

  initial begin
    $dumpvars();
    clk_counter<=8'b0;
    reset<=1'b1;
`ifdef DEBUG
    $display("sim: starting sim");
`endif
    #500
    reset<=1'b0;
`ifdef DEBUG
    $display("sim: clearing reset");
`endif
    #80000
    $display("FAILED: simulation timed out");
    $finish;
  end

  assign clk = clk_counter < ((`CLK_PERIOD) / 2);

  always begin
    #1 clk_counter <= (clk_counter == `CLK_PERIOD - 1 ? 32'b0 : clk_counter + 1);
  end

    /*ACM goodies*/
`ifdef MODELSIM
  AB AB_inst(.ACMADDR(ACM_addr),.ACMCLK(ACM_clk),.ACMRDATA(ACM_rdata),.ACMWDATA(ACM_wdata),.ACMRESET(~reset),.ACMWEN(ACM_wen));
`else
  reg [7:0] memdump [255:0];
  reg [7:0] temp;

  assign ACM_rdata = temp;
  reg [7:0] prev;
  always @(posedge ACM_clk) begin
    if (~ACM_reset) begin
      temp <= 8'b0;
    end else begin
      if (ACM_wen) begin
        memdump[ACM_addr]<=ACM_wdata;
`ifdef DEBUG
        $display("ACM: got data: %x", ACM_wdata);
`endif 
      end else begin
        prev <= ACM_addr; 
        temp<=memdump[ACM_addr];
`ifdef DESPERATE_DEBUG
        if (prev !== ACM_addr) begin
          $display("ACM: sent data: %x", memdump[ACM_addr]);
        end
`endif 
      end
    end
  end
`endif

  reg [1:0] state;
`define TB_STATE_WRITE 2'd0
`define TB_STATE_READ  2'd1
`define TB_STATE_WAIT  2'd2

  reg [15:0] counter;

  always @ (posedge clk) begin
    wb_cyc_i <= 1'b0;
    wb_stb_i <= 1'b0;
    if (reset) begin
      state<=`TB_STATE_WRITE;
      counter <= 16'b0;
    end else begin
      case (state)
        `TB_STATE_WRITE: begin
	  wb_we_i <= 1'b1;
	  wb_adr_i <= counter;
	  wb_dat_i <= counter;
          wb_cyc_i <= 1'b1;
          wb_stb_i <= 1'b1;
	  state <= `TB_STATE_WAIT;
`ifdef DEBUG
          $display("wbm: write cmnd, data = %d, adr = %d", counter, counter);
`endif
	end  
	`TB_STATE_READ: begin
	  wb_we_i <= 1'b0;
          wb_cyc_i <= 1'b1;
          wb_stb_i <= 1'b1;
	  wb_adr_i <= counter;
	  state <= `TB_STATE_WAIT;
`ifdef DEBUG
          $display("wbm: read cmnd, adr = %d", counter);
`endif
	end
	`TB_STATE_WAIT: begin
	  if (wb_ack_o & wb_we_i) begin
	    state<=`TB_STATE_READ;
`ifdef DEBUG
	    $display("wbm: write reply");
`endif
	  end
	  if (wb_ack_o & ~wb_we_i) begin
	    state<=`TB_STATE_WRITE;
            counter<=counter + 1;
            /*only check analogue quag reads*/
            if (counter > 16'b0 && counter <= 16'd40) begin
              if ((counter & 16'h00ff) !== wb_dat_o) begin
                $display("FAILED: data failure - got %x expected %x", wb_dat_o, counter & 16'h00ff);
	        $finish;
              end else if (counter == 16'd40) begin
                $display("PASSED");
	        $finish;
              end
            end
`ifdef DEBUG
	    $display("wbm: read reply, data = %d", wb_dat_o);
`endif
          end
	end
      endcase
    end
  end

endmodule
