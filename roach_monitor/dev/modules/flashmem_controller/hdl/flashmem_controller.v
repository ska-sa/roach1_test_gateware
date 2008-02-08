`timescale 1ns/10ps
`include "memlayout.v"

`define FM_STATE_IDLE 3'd0
`define FM_STATE_READ 3'd1
`define FM_STATE_WRITE 3'd2
`define FM_STATE_PROGRAM 3'd3
`define FM_STATE_CLEAN 3'd4


module flashmem_controller(
  reset, hard_reset,
  FM_ADDR, FM_WD, FM_RD,
  FM_REN, FM_WEN, FM_PROGRAM,
  FM_BUSY, FM_STATUS, FM_PAGESTATUS,
  lb_addr,lb_data_in,lb_data_out,
  lb_rd,lb_wr,lb_strb,
  lb_clk
  );
  input reset, hard_reset;

  output [16:0] FM_ADDR;
  output [15:0] FM_WD;
  output FM_PAGESTATUS;
  output FM_REN, FM_WEN, FM_PROGRAM;
  input [15:0]  FM_RD;
  input FM_BUSY;
  input [1:0] FM_STATUS;

  input [15:0] lb_addr;
  input [15:0] lb_data_in;
  input lb_rd,lb_wr,lb_clk;
  output [15:0] lb_data_out;
  output lb_strb;
  
  reg [15:0] FM_WD;
  reg [16:0] FM_ADDR;
  reg FM_REN,FM_WEN,FM_PROGRAM;
  reg FM_PAGESTATUS;
  
  reg [15:0] lb_data_out;
  reg lb_strb;

  
  wire addressed = (lb_addr >= `FLASH_A && lb_addr <= (`FLASH_A + `FLASH_L - 1'b1));
  wire [15:0] fm_addr = (lb_addr - (`FLASH_DATA_A));
  wire [9:0] page_index=fm_addr[15:6];
  
  reg [2:0] state;
  reg lb_failure;

  reg dirty_page;
  reg [9:0] dirty_page_index;
  reg [15:0] temp_address; //needed in case of program 17bits

  reg program_state; //wr == 1, rd == 0
  reg wait_cycle;

  reg [15:0] status_address;

  reg [2:0] fm_status;

  reg [15:0] write_count;
  reg [15:0] read_count;
  reg [15:0] prog_count;
  reg [15:0] write_fail_count;
  reg [15:0] read_fail_count;
  reg [15:0] prog_fail_count;
  reg [15:0] read_transaction_count;
  reg [15:0] write_transaction_count;


  always @(posedge lb_clk) begin
    if (hard_reset) begin
      write_count<=16'b0;
      read_count<=16'b0;
      prog_count<=16'b0;
      write_fail_count<=16'b0;
      read_fail_count<=16'b0;
      prog_fail_count<=16'b0;
      read_transaction_count<=16'b0;
      write_transaction_count<=16'b0;
    end else if (reset) begin
      state<=`FM_STATE_IDLE;
      lb_data_out<=16'b0;
      lb_strb<=1'b0;
      dirty_page<=1'b0;
      dirty_page_index<=10'b0;
      FM_REN<=1'b0;
      FM_WEN<=1'b0;
      FM_PROGRAM<=1'b0;
      lb_failure<=1'b0;
      FM_PAGESTATUS<=1'b0;
      fm_status<=3'b111;
    end else begin
      case (state)
        `FM_STATE_IDLE: begin
           lb_failure<=1'b0;
           wait_cycle<=1'b0;
	   if (lb_addr == `FLASH_DEBUG_WRITE_COUNT_A && lb_rd) begin
	     state<=`FM_STATE_CLEAN;
	     lb_data_out<=write_count;
	     lb_strb<=1'b1;
	   end else if (lb_addr == `FLASH_DEBUG_READ_COUNT_A && lb_rd) begin
	     state<=`FM_STATE_CLEAN;
	     lb_data_out<=read_count;
	     lb_strb<=1'b1;
	   end else if (lb_addr == `FLASH_DEBUG_PROG_COUNT_A && lb_rd) begin
	     state<=`FM_STATE_CLEAN;
	     lb_data_out<=prog_count;
	     lb_strb<=1'b1;
	   end else if (lb_addr == `FLASH_DEBUG_WRITE_FAIL_COUNT_A && lb_rd) begin
	     state<=`FM_STATE_CLEAN;
	     lb_data_out<=write_fail_count;
	     lb_strb<=1'b1;
	   end else if (lb_addr == `FLASH_DEBUG_READ_FAIL_COUNT_A && lb_rd) begin
	     state<=`FM_STATE_CLEAN;
	     lb_data_out<=read_fail_count;
	     lb_strb<=1'b1;
	   end else if (lb_addr == `FLASH_DEBUG_PROG_FAIL_COUNT_A && lb_rd) begin
	     state<=`FM_STATE_CLEAN;
	     lb_data_out<=prog_fail_count;
	     lb_strb<=1'b1;
	   end else if (lb_addr == `FLASH_DEBUG_READ_TRANS_COUNT_A && lb_rd) begin
	     state<=`FM_STATE_CLEAN;
	     lb_data_out<=read_transaction_count;
	     lb_strb<=1'b1;
	   end else if (lb_addr == `FLASH_DEBUG_WRITE_TRANS_COUNT_A && lb_rd) begin
	     state<=`FM_STATE_CLEAN;
	     lb_data_out<=write_transaction_count;
	     lb_strb<=1'b1;
	   end else if (lb_addr == `FLASH_PAGE_STATUS_A && !FM_BUSY) begin
	       if (lb_rd) begin
                 state<=`FM_STATE_READ;
                 FM_REN<=1'b1;
                 FM_ADDR<={1'b0,status_address};
                 FM_PAGESTATUS<=1'b1;
`ifdef DEBUG
               $display("fc: performing page status read");
`endif
	       end else if (lb_wr) begin
	         state<=`FM_STATE_CLEAN;
		 status_address<=lb_data_in;
		 lb_strb<=1'b1;
	       end
	   end else if (lb_addr == `FLASH_DIRTY_PAGE_A) begin
	       if (lb_rd) begin
	         state<=`FM_STATE_CLEAN;
		 lb_data_out<=(dirty_page ? {6'b0, dirty_page_index} : 16'hffff);
		 lb_strb<=1'b1;
`ifdef DEBUG
               $display("fc: performing dirty page read");
`endif
	       end
	   end else if (lb_addr == `FLASH_STATUS_A) begin
	       if (lb_rd) begin
	         state<=`FM_STATE_CLEAN;
		 lb_data_out<={FM_BUSY,12'd0,fm_status};
		 lb_strb<=1'b1;
`ifdef DEBUG
               $display("fc: performing op status read");
`endif
	       end
           end else if (addressed && lb_rd && !FM_BUSY) begin
             read_transaction_count<=read_transaction_count + 16'b1;
             if (dirty_page && (dirty_page_index != page_index)) begin
`ifdef DEBUG
               $display("fc: performing read - addr = %d",{1'b0,fm_addr});
               $display("... buffer page mismatch - program necessary");
               $display("... current buffer index = %d, new buffer index = %d",
                        dirty_page_index,page_index);
`endif
               state<=`FM_STATE_PROGRAM;
               program_state<=1'b0;
               FM_PROGRAM<=1'b1;
               FM_ADDR<={dirty_page_index,6'b0}; //the dirty page's address
               temp_address<=fm_addr;
             end else begin
               state<=`FM_STATE_READ;
               FM_REN<=1'b1;
               FM_ADDR<={1'b0,fm_addr};
`ifdef DEBUG
               $display("fc: performing read - addr = %d",{1'b0,fm_addr});
`endif
             end
           end else if (addressed && lb_wr && !FM_BUSY) begin
             write_transaction_count<=write_transaction_count + 16'b1;
             FM_WD<=lb_data_in;
             if (dirty_page && (dirty_page_index != page_index)) begin
`ifdef DEBUG
               $display("fc: performing write - data = %d, addr = %d",lb_data_in,{1'b0,fm_addr});
               $display("... buffer page mismatch - program necessary");
               $display("... current buffer index = %d, new buffer index = %d",
                        dirty_page_index,page_index);
`endif
               state<=`FM_STATE_PROGRAM;
               program_state<=1'b1;
               FM_PROGRAM<=1'b1;
               FM_ADDR<={dirty_page_index,6'b0}; //the dirty page's address
               temp_address<=fm_addr;
               FM_WD<=lb_data_in;
             end else begin
`ifdef DEBUG
               $display("fc: performing write - data = %d, addr = %d",lb_data_in,{1'b0,fm_addr});
`endif
               state<=`FM_STATE_WRITE;
               FM_WEN<=1'b1;
               FM_ADDR<={1'b0,fm_addr};
               FM_WD<=lb_data_in;
             end
           end
        end
        `FM_STATE_PROGRAM: begin
          FM_PROGRAM<=1'b0;
          wait_cycle<=1'b1;
          if (lb_wr || lb_rd)
            lb_failure<=1'b1;
          if (~FM_BUSY & wait_cycle) begin
            FM_ADDR<={1'b0,temp_address};
            if (program_state) begin
              state<=`FM_STATE_WRITE;
              wait_cycle<=1'b0;
              FM_WEN<=1'b1;
            end else begin
              state<=`FM_STATE_READ;
              wait_cycle<=1'b0;
              FM_REN<=1'b1;
            end
            fm_status<=FM_STATUS;
            if (FM_STATUS == 2'b00) begin
              prog_count<=prog_count + 16'd1;
              dirty_page<=1'b0;
              dirty_page_index<={1'b0,temp_address[15:6]};
`ifdef DEBUG
              $display("fc: program completed - program state = %d",program_state);
`endif
            end else begin
              prog_fail_count<=prog_fail_count + 16'd1;
`ifdef SIMULATION
              $display("fc: warning - apparent error during program command");
`endif
            end
          end
        end
        `FM_STATE_WRITE: begin
          FM_WEN<=1'b0;
          wait_cycle<=1'b1;
          if (lb_wr || lb_rd)
            lb_failure<=1'b1;
          if (~FM_BUSY & wait_cycle) begin
            if (~lb_failure) //if bus has done something it is unsafe to assert strb
              lb_strb<=1'b1;
            state<=`FM_STATE_CLEAN;
            fm_status<=FM_STATUS;

            if (FM_STATUS == 2'b00) begin
              write_count<=write_count + 16'b1;
              dirty_page<=1'b1;
              dirty_page_index<=FM_ADDR[15:6];
`ifdef DEBUG
              $display("fc: write completed -- data = %d, addr = %d", FM_WD,FM_ADDR);
`endif
            end else begin
              write_fail_count<=write_fail_count + 16'b1;
`ifdef DEBUG
              $display("fc: warning, apparent error during program - status = %b",FM_STATUS);
`endif
            end
          end
        end
        `FM_STATE_READ: begin
	  FM_PAGESTATUS<=1'b0;
          FM_REN<=1'b0;
          wait_cycle<=1'b1;
          if (lb_wr || lb_rd)
            lb_failure<=1'b1;
          if (~FM_BUSY & wait_cycle) begin
            fm_status<=FM_STATUS;
            if (FM_STATUS == 2'b00) begin
              read_count<=read_count + 16'b1;
              dirty_page_index<=FM_ADDR[15:6];
`ifdef DEBUG
              $display("fc: read completed");
`endif
            end else begin
              read_fail_count<=read_fail_count + 16'b1;
`ifdef DEBUG
              $display("fc: warning, apparent error during program - status = %b",FM_STATUS);
`endif
            end
             state<=`FM_STATE_CLEAN;
             if (~lb_failure) begin
               lb_data_out<=FM_RD;
               lb_strb<=1'b1;
             end
          end
        end
        `FM_STATE_CLEAN: begin
          lb_data_out<=16'b0;
          lb_strb<=1'b0;
          state<=`FM_STATE_IDLE;
        end
      endcase
    end
  end
endmodule
