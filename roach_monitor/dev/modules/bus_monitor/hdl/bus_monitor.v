`timescale 1ns/10ps

`include "memlayout.v"

module bus_monitor(
  reset, hard_reset,
  timeout, lb_strb_all,
  lb_addr,lb_data_in,lb_data_out,lb_rd,lb_wr,lb_strb,lb_clk
  );
  input reset,hard_reset;
  input timeout;
  input [15:0] lb_addr;
  input [15:0] lb_data_in;
  output [15:0] lb_data_out;
  input lb_rd,lb_wr;
  input lb_strb_all;
  output lb_strb;
  input lb_clk;

  reg lb_strb;
  reg [15:0] lb_data_out;
  wire addressed = (lb_addr >= (`BUSMON_A) && lb_addr < (`BUSMON_A) + (`BUSMON_L));

  reg [1:0] current_cmnd;
  reg [15:0] current_addr;
  reg [15:0] current_data;
  
  reg [1:0] error_cmnd;
  reg [15:0] error_addr;
  reg error_occurred;
  reg [15:0] error_count;
  reg [15:0] error_data;

  reg timeout_fresh;
  reg read_op;
  reg [15:0] op_count;
  reg strb_fresh;

  always @(posedge lb_clk) begin
    if (hard_reset) begin
      error_count<=16'd0;
      op_count<=16'd0;
    end else if (reset) begin
      strb_fresh<=1'b1;
      lb_strb<=1'b0;
      lb_data_out<=16'b0;
      error_occurred<=1'b0;
      error_data<=16'd0;
      timeout_fresh<=1'b1;
    end else begin
      if (addressed & (lb_rd | lb_wr)) begin
        case (lb_addr) 
         `BUSMON_CADDR_A: begin
           if (lb_rd) begin
             lb_data_out<=current_addr;
           end
         end
         `BUSMON_CCMND_A: begin
           if (lb_rd) begin
             lb_data_out<=current_cmnd;
           end
         end
         `BUSMON_CDATA_A: begin
           if (lb_rd) begin
             lb_data_out<=current_data;
           end
         end
	 `BUSMON_ADDR_A: begin
           if (lb_rd) begin
             lb_data_out<=error_addr;
           end
         end
         `BUSMON_DATA_A: begin
           if (lb_rd) begin
             lb_data_out<=error_data;
           end
         end
         `BUSMON_COUNT_A: begin
           if (lb_rd) begin
             lb_data_out<=error_count;
           end
         end
	 `BUSMON_OPCNT_A: begin
           if (lb_rd) begin
             lb_data_out<=op_count;
           end
	 end
         `BUSMON_CMND_A: begin
           if (lb_rd) begin
             lb_data_out<={error_occurred,13'b0,error_cmnd};
             error_occurred<=1'b0;
`ifdef DEBUG
          $display("bmon: got cmnd rd , data = %b",{error_occurred,13'b0,error_cmnd});
`endif
           end
         end
        endcase
        lb_strb<=1'b1;
      end else begin
        lb_strb<=1'b0;
        lb_data_out<=16'b0;
        if (lb_rd | lb_wr) begin
          current_cmnd<={lb_wr,lb_rd};
          current_addr<=lb_addr;
	  if (lb_wr) begin
            current_data<=lb_data_in;
	  end
	  read_op<=lb_rd;
        end
        if (lb_strb_all & read_op & ~lb_strb)
          current_data<=lb_data_in;
      end	
      if (timeout && timeout_fresh) begin
        error_count<=error_count + 16'd1;
        error_occurred<=1'b1;
        error_cmnd<=current_cmnd;
        error_addr<=current_addr;
        error_data<=current_data;
        timeout_fresh<=1'b0;
`ifdef DEBUG
        if (error_occurred == 1'b0)
        $display("bmon: got timeout, addr = %d, cmnd = %b",current_addr,current_cmnd);
`endif
      end else if (~timeout && ~timeout_fresh) begin
        timeout_fresh<=1'b1;
        
      end
      
      if (lb_strb_all && strb_fresh && !lb_strb) begin
        strb_fresh<=1'b0;
        op_count<=op_count + 1;
      end
      if (~lb_strb_all) begin
        strb_fresh<=1'b1;
      end
    end
  end
endmodule
